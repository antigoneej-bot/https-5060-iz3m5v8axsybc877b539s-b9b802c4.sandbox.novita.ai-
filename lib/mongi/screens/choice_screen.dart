import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/my_garden_screen.dart';
import '../../screens/self_care_entry_screen.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/feature_scaffold.dart';
import '../integration/session_transaction.dart';
import '../integration/garden_navigation.dart';
import '../models/emotion.dart';
import '../models/seed.dart';
import '../models/tree_growth.dart';
import '../providers/garden_provider.dart';
import '../services/ad_service.dart';
import '../widgets/emotion_share_sheet.dart';
import 'emotion_input_screen.dart';
import 'growth_milestone_screen.dart';

/// Play rewards save before any optional planting, reflection or navigation.
/// Game monsters are never recorded as the player's self-reported mood.
class ChoiceScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final String? targetName;
  final Map<EmotionType, int> eatenByType;
  final int maxCombo;
  final bool earlyStop;
  final int? target;
  final int? playedStage;
  final String? sessionId;
  const ChoiceScreen({
    super.key,
    required this.emotions,
    required this.targetName,
    required this.eatenByType,
    this.maxCombo = 0,
    this.earlyStop = false,
    this.target,
    this.playedStage,
    this.sessionId,
  });
  int get eatenCount => eatenByType.values.fold(0, (sum, n) => sum + n);
  Emotion get primaryEmotion => emotions.first;
  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen> {
  late final String _sessionId;
  bool _saved = false;
  bool _busy = false;
  bool _allowPop = false;
  bool _advanced = false;
  bool _planted = false;
  bool _storedSeed = false;
  String? _seedName;
  String? _error;
  Future<void> Function()? _retry;
  int _score = 0;
  int _light = 0;
  int _treeBonus = 0;
  bool _treeGrew = false;
  String? _golden;
  String? _transcended;
  int? _season;

  bool get _completed =>
      !widget.earlyStop &&
      (widget.target == null ||
          widget.target! <= 0 ||
          widget.eatenCount >= widget.target!);

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId ?? SessionTransaction.newId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveResult();
    });
  }

  Future<void> _perform(
    Future<void> Function() action,
    String message,
    Future<void> Function() retry,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted)
        setState(() {
          _error = message;
          _retry = retry;
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveResult() async {
    if (_saved || !mounted) return;
    await _perform(
      () async {
        final garden = context.read<GardenProvider>();
        final before = garden.treeStageIndex;
        await garden.recordSession(
          widget.eatenByType,
          choseLove: false,
          earlyStop: widget.earlyStop,
          target: widget.target,
          playedStage: widget.playedStage,
          sessionId: '$_sessionId:result',
        );
        if (!mounted) return;
        _score = garden.lastEarnedScore;
        _light = garden.lastEarnedLightEssence;
        _treeBonus = garden.lastTreeMilestoneBonusLight;
        _treeGrew = garden.treeStageIndex > before || _treeBonus > 0;
        _golden = garden.lastGoldenFrameUnlocked?.label;
        _transcended = garden.lastTranscendedEmotion?.label;
        _season = garden.lastSeasonMilestoneLevel;
        _saved = true;
      },
      '플레이 결과를 저장하지 못했어요. 다시 저장하면 보상이 중복되지 않아요.',
      _saveResult,
    );
  }

  Future<void> _advance() async {
    if (!_saved || !_completed || _advanced) return;
    await _perform(
      () async {
        await context.read<GardenProvider>().advanceToNextStage(
          sessionId: '$_sessionId:advance',
        );
        if (mounted) _advanced = true;
      },
      '다음 단계를 저장하지 못했어요. 다시 시도해 주세요.',
      _advance,
    );
  }

  Future<void> _plant(SeedType seed) async {
    if (!_saved || _planted) return;
    await _perform(
      () async {
        final garden = context.read<GardenProvider>();
        final stored = await garden.plantRunnerSeed(
          resultSessionId: '$_sessionId:result',
          seedId: seed.id,
        );
        if (!mounted) return;
        _planted = true;
        _storedSeed = stored;
        _seedName = seed.label;
      },
      '씨앗을 저장하지 못했어요. 플레이 보상은 저장돼 있어요.',
      () => _plant(seed),
    );
  }

  Future<void> _leave({bool toLobby = false}) async {
    if (_busy) return;
    if (!_saved) await _saveResult();
    if (!mounted || !_saved || _busy) return;
    setState(() => _busy = true);
    // An optional ad failure must never trap a saved result.
    if (toLobby) {
      try {
        await AdService.instance.maybeShowInterstitialAfterStage();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (!toLobby && navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EmotionInputScreen()),
        (route) => false,
      );
    }
  }

  void _openGarden() {
    if (!_saved || _busy) return;
    pushFullScreen(
      context,
      '나의 정원',
      MyGardenScreen(onGoMeetCat: gardenCatSelectionReturn(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final enabled = _saved && !_busy && _error == null;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5EC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      '🐈',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _completed ? '몽이와 한 바퀴 달렸어요' : '오늘은 여기까지 달렸어요',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '만난 몬스터 ${widget.eatenCount}개 · 최고 콤보 ${widget.maxCombo}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      FilledButton(
                        onPressed: _busy ? null : _retry,
                        child: const Text('다시 저장하기'),
                      ),
                    ],
                    if (_saved)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                '플레이 보상을 저장했어요',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text('성장 점수 +$_score · 빛의 정수 +$_light'),
                              if (_treeBonus > 0)
                                Text('나무 성장 축하 · 빛의 정수 +$_treeBonus'),
                              if (_treeGrew)
                                Text(
                                  '성장나무: ${TreeGrowth.labelForScore(garden.score)}',
                                ),
                              if (_golden != null)
                                Text('$_golden 황금 프레임을 만났어요'),
                              if (_transcended != null)
                                Text('$_transcended 도감의 새 단계에 도착했어요'),
                              if (_season != null) Text('시즌 마일스톤 $_season단계'),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('runner-result-garden'),
                      onPressed: enabled ? _openGarden : null,
                      icon: const Icon(Icons.park_outlined),
                      label: const Text('정원으로 돌아가기'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('runner-result-reflect'),
                      onPressed: enabled
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SelfCareEntryScreen(),
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('지금 마음 돌아보기 · 선택'),
                    ),
                    const Text(
                      '게임에서 고른 감정과 점수는 마음 상태 통계에 넣지 않아요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 14),
                    if (_planted)
                      Text(
                        _storedSeed
                            ? '$_seedName 씨앗을 보관함에 넣었어요. 이미 심은 식물은 물주기로 자라요.'
                            : '$_seedName 씨앗을 정원에 심었어요.',
                        textAlign: TextAlign.center,
                      )
                    else
                      ExpansionTile(
                        key: const ValueKey('runner-result-seeds'),
                        title: const Text('씨앗 선물 고르기 · 선택'),
                        subtitle: const Text('한 판에 하나 · 이미 심은 종류는 보관함으로'),
                        children: [
                          for (final seed in SeedType.all)
                            ListTile(
                              title: Text(seed.label),
                              subtitle: Text(seed.description),
                              trailing: const Icon(Icons.add),
                              onTap: enabled ? () => _plant(seed) : null,
                            ),
                        ],
                      ),
                    if (_completed)
                      TextButton(
                        key: const ValueKey('runner-result-advance'),
                        onPressed: enabled && !_advanced ? _advance : null,
                        child: Text(
                          _advanced
                              ? '다음에는 ${garden.stage}단계로 시작해요'
                              : '다음 단계로 올리기 · 선택',
                        ),
                      ),
                    if (garden.treeStageIndex >= TreeGrowth.maxStageIndex)
                      TextButton(
                        onPressed: enabled
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GrowthMilestoneScreen(),
                                ),
                              )
                            : null,
                        child: const Text('나무와 함께한 기록 돌아보기'),
                      ),
                    TextButton(
                      onPressed: enabled
                          ? () => EmotionShareSheet.show(
                              context,
                              emotion: widget.primaryEmotion,
                              targetName: widget.targetName,
                              eatenCount: widget.eatenCount,
                              maxCombo: widget.maxCombo,
                              choseLove: _planted,
                              note: '',
                            )
                          : null,
                      child: const Text('플레이 기록 공유하기'),
                    ),
                    TextButton(
                      onPressed: enabled ? () => _leave(toLobby: true) : null,
                      child: const Text('달려라 몽이 처음으로'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
