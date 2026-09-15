import '../../theme.dart' show AppColors;
import '../integration/session_transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/choice_narrative_l10n.dart';
import '../l10n/emotion_insight_l10n.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/emotion_trigger_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/season_milestone_l10n.dart';
import '../l10n/seed_l10n.dart';
import '../l10n/tree_growth_l10n.dart';
import '../models/emotion.dart';
import '../models/emotion_trigger.dart';
import '../models/seed.dart';
import '../models/tree_growth.dart';
import '../providers/garden_provider.dart';
import '../services/ad_service.dart';
import '../services/emotion_insight_service.dart';
import '../widgets/emotion_share_sheet.dart';
import '../widgets/garden_growth_share_sheet.dart';
import '../widgets/score_popup_animation.dart';
import '../widgets/seed_planting_animation.dart';
import '../widgets/tree_growth_animation.dart';
import 'emotion_input_screen.dart';
import 'garden_screen.dart';
import 'growth_milestone_screen.dart';

enum _Stage { stageClear, asking, seedSelect, planting, treeGrowth, result }

/// 러너 게임 클리어 후 나오는 선택 화면.
/// "마음을 심으시겠습니까?" -> 예/아니오 둘 다 정답이다 (강요하지 않는다).
/// "네"를 고르면 용서/사랑/평안 중 어떤 씨앗을 심을지 한 번 더 고른다.
class ChoiceScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final String? targetName;
  final Map<EmotionType, int> eatenByType;
  final int maxCombo;

  /// 목표 개수를 다 채우지 못하고(목숨을 다 써서) 부드럽게 마무리된 경우 true.
  /// 실패로 취급하지 않고, 그동안 함께한 만큼을 존중하는 문구로 안내한다.
  final bool earlyStop;

  /// 이번 판의 감정 목표 개수 (스테이지별로 6/10/20/30... 다르다).
  /// 점수/진행도 계산에 쓰인다.
  final int? target;
  final int? playedStage;

  const ChoiceScreen({
    super.key,
    required this.emotions,
    required this.targetName,
    required this.eatenByType,
    this.maxCombo = 0,
    this.earlyStop = false,
    this.target,
    this.playedStage,
  });

  /// 이번 판에서 먹은 총 개수 (감정 타입 합산).
  int get eatenCount => eatenByType.values.fold(0, (sum, c) => sum + c);

  /// 카드/일기/공유 등 대표로 표시할 감정 하나 (여러 개를 골랐다면 첫 번째).
  Emotion get primaryEmotion => emotions.first;

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen>
    with SingleTickerProviderStateMixin {
  late _Stage _stage;
  bool _choseLove = false;
  bool _justBloomed = false;
  bool _leveledUp = false;
  int _newStageNumber = 1;
  String? _chosenSeedId;
  final TextEditingController _noteController = TextEditingController();

  // 감정 강도(1~5, 선택) - 기본값 3(보통)에서 시작해 유저가 슬라이더로 조절.
  // 한 번도 슬라이더를 건드리지 않으면 그냥 "보통" 강도로 저장된다.
  double _intensity = 3;

  // 이번 세션에서 선택한 트리거 태그 id들(선택, 여러 개 가능).
  final Set<String> _selectedTriggers = {};

  /// 이번 판에서 목표를 실제로 다 채웠는지(목숨이 남아 있었는지와 무관하게,
  /// "먹은 개수가 목표 이상이면서 earlyStop이 아닌" 경우) - 스테이지 상승을
  /// "마음을 심을래요" 선택과 완전히 분리하기 위한 판정. [GardenProvider.
  /// recordSession]의 fullyCompleted 판정과 동일한 기준을 쓴다.
  bool get _stageFullyCleared {
    if (widget.earlyStop) return false;
    final target = widget.target;
    if (target == null || target <= 0) return true;
    return widget.eatenCount >= target;
  }

  /// 다음 단계로 넘어가기 확인 화면에서 사용자가 이미 "넘어갈래요"/"여기서
  /// 머물래요" 중 하나를 골랐는지 여부 - 한 번 고르면 [_buildAsking]으로
  /// 넘어가고 다시 돌아오지 않는다.
  bool _stageAdvanceDecided = false;
  final String _sessionId = SessionTransaction.newId();
  String? _saveError;
  Future<void> Function()? _retrySave;
  bool _retrying = false;

  Future<void> _retryFailedSave() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await _retrySave?.call();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  // 몽이의 성장나무(C.2) - 이번 판으로 나무가 다음 단계로 자랐는지 여부.
  int? _treeStageBefore;
  int _treeStageAfter = -1;
  int _earnedScore = 0;
  int _earnedLightEssence = 0;
  int _treeMilestoneBonusLight = 0;

  // 감정 데이터 되돌려주기(1단계: 즉시 피드백) - 결과 화면에 표시할 한 줄
  // 관찰 문구. 아직 이번 세션이 일기에 저장되기 전 시점의 과거 기록만 보고
  // 계산하므로, 화면이 처음 만들어질 때 딱 한 번만 계산해서 고정해둔다.
  // 다국어 지원을 위해 문구 대신 "종류 + 값"만 들고 있고, 실제 문구는
  // build 시점에 sessionInsightText()로 완성한다.
  SessionInsightResult? _sessionInsight;

  // 다음 판을 기대하게 만드는 "오픈 루프" 한 줄. _sessionInsight와 같은
  // 시점(이번 세션 저장 전)에 함께 계산해서 고정해둔다.
  NextGoalHintResult? _nextGoalHint;

  // 감정 도감 레어도 시스템 - 이번 세션에서 새로 "황금 프레임"을 획득한
  // 감정(있으면). recordSession 직후 GardenProvider가 채워준다.
  Emotion? _goldenFrameEmotion;

  // 6번: 이번 세션에서 처음으로 "초월"(100번째 마주침, 히든 4단계)에 도달한
  // 감정(있으면). recordSession 직후 GardenProvider가 채워준다. 예고 없이
  // 조용히 채워지다 우연히 발견되는 히든 마일스톤이라, 이 필드가 null이 아닐
  // 때만 결과 화면에 깜짝 축하 카드가 나타난다.
  Emotion? _transcendedEmotion;

  // "1번 개선": 이번 세션으로 시즌 패스의 "마음 마일스톤"(5의 배수 레벨)에
  // 새로 도달했다면 그 레벨(5/10/15/20)이 담긴다. recordSession 직후
  // GardenProvider.lastSeasonMilestoneLevel에서 읽어온다. 실제 문구는
  // build 시점에 seasonMilestoneText()로 완성한다.
  int? _seasonMilestoneLevel;

  // Bloom burst animation: plays right when the user chooses to plant love.
  late final AnimationController _bloomController;

  // Scattered spots (fractional alignment) across the whole screen where flowers pop in.
  static const List<Alignment> _bloomSpots = [
    Alignment(-0.8, -0.85),
    Alignment(0.75, -0.7),
    Alignment(-0.95, -0.15),
    Alignment(0.9, -0.1),
    Alignment(-0.65, 0.35),
    Alignment(0.7, 0.3),
    Alignment(0.0, -0.9),
    Alignment(-0.35, 0.75),
    Alignment(0.4, 0.8),
    Alignment(0.05, -0.35),
  ];

  @override
  void initState() {
    super.initState();
    _bloomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // 스테이지를 실제로 클리어했을 때만(목숨을 다 써서 끝난 게 아니라 목표를
    // 다 채웠을 때만) "다음 단계로 넘어갈까요?" 확인 화면을 먼저 보여준다.
    // 목숨이 다 돼서 끝난 경우(earlyStop)는 곧바로 기존 마음 심기 화면으로.
    _stage = _stageFullyCleared ? _Stage.stageClear : _Stage.asking;
    // 이번 세션은 아직 diaryEntries에 저장되기 전이므로, 지금 시점의 과거
    // 기록만으로 "이번 세션을 포함하면 어떤 의미가 있는지" 미리 계산해둔다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final garden = context.read<GardenProvider>();
      setState(() {
        _sessionInsight = EmotionInsightService.buildSessionInsightKind(
          diaryEntries: garden.diaryEntries,
          primaryEmotion: widget.primaryEmotion,
          selectedEmotions: widget.emotions,
        );
        _nextGoalHint = EmotionInsightService.buildNextGoalHintKind(
          diaryEntries: garden.diaryEntries,
          pointsToNextTreeStage: garden.pointsToNextTreeStage,
        );
      });
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _bloomController.dispose();
    super.dispose();
  }

  /// "다음 단계로 넘어갈까요?" 확인 화면에서 버튼을 눌렀을 때 호출된다.
  /// [advance]=true면 실제로 [GardenProvider.advanceToNextStage]를 호출해
  /// 스테이지를 한 단계 올린 뒤, [advance]=false면 그대로 머무른 채 다음
  /// (마음 심기) 화면으로 넘어간다. 스테이지 상승 여부는 오직 이 버튼
  /// 선택으로만 결정되며, "마음을 심을래요" 선택과는 완전히 독립적이다.
  Future<void> _decideStageAdvance(bool advance) async {
    if (_stageAdvanceDecided) return;
    _stageAdvanceDecided = true;
    try {
      final garden = context.read<GardenProvider>();
      if (advance)
        await garden.advanceToNextStage(sessionId: '$_sessionId:advance');
      if (!mounted) return;
      setState(() {
        _saveError = null;
        _leveledUp = advance;
        _newStageNumber = garden.stage;
        _stage = _Stage.asking;
      });
    } catch (_) {
      _stageAdvanceDecided = false;
      if (mounted)
        setState(() {
          _saveError = '단계 이동을 저장하지 못했어요. 다시 시도하면 이어서 저장해요.';
          _retrySave = () => _decideStageAdvance(advance);
        });
    }
  }

  bool _recording = false, _recorded = false;
  Future<void> _choose(bool love, {String? seedType}) async {
    if (_recording || _recorded) return;
    _recording = true;
    final garden = context.read<GardenProvider>();
    final treeStageBefore = garden.treeStageIndex;
    late bool bloomed;
    try {
      bloomed = await garden.recordSession(
        widget.eatenByType,
        choseLove: love,
        seedType: seedType,
        earlyStop: widget.earlyStop,
        target: widget.target,
        playedStage: widget.playedStage,
        sessionId: '$_sessionId:result',
      );
    } catch (_) {
      if (mounted)
        setState(() {
          _saveError = '결과 저장을 완료하지 못했어요. 다시 시도하면 중복 없이 이어서 저장해요.';
          _retrySave = () => _choose(love, seedType: seedType);
        });
      return;
    } finally {
      _recording = false;
    }
    _recorded = true;
    _recording = false;
    if (!mounted) return;
    final treeStageAfter = garden.treeStageIndex;
    final treeGrew = treeStageAfter > treeStageBefore;
    setState(() {
      _saveError = null;
      _choseLove = love;
      _justBloomed = bloomed;
      _chosenSeedId = seedType;
      _earnedScore = garden.lastEarnedScore;
      _earnedLightEssence = garden.lastEarnedLightEssence;
      _treeMilestoneBonusLight = garden.lastTreeMilestoneBonusLight;
      _treeStageBefore = treeStageBefore;
      _treeStageAfter = treeStageAfter;
      _goldenFrameEmotion = garden.lastGoldenFrameUnlocked;
      _transcendedEmotion = garden.lastTranscendedEmotion;
      _seasonMilestoneLevel = garden.lastSeasonMilestoneLevel;
      // 나무가 자랐으면 결과 화면 전에 성장 애니메이션을 먼저 보여준다.
      _stage = treeGrew ? _Stage.treeGrowth : _Stage.result;
    });
    if (love) {
      _bloomController.forward(from: 0);
    }
  }

  void _onTreeGrowthFinished() {
    if (!mounted) return;
    final garden = context.read<GardenProvider>();
    // 나무가 처음으로 마지막 단계(열매)까지 자란 바로 그 순간이라면, 결과 화면
    // 대신 "성장 마일스톤 회고"(감정 성장 다큐멘터리)를 먼저 보여준다.
    final justFullyGrown =
        _treeStageAfter >= TreeGrowth.maxStageIndex &&
        !garden.hasSeenGrowthMilestone;
    if (justFullyGrown) {
      garden.markGrowthMilestoneSeen();
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (_) => const GrowthMilestoneScreen()),
          )
          .then((_) {
            if (mounted) setState(() => _stage = _Stage.result);
          });
      return;
    }
    setState(() => _stage = _Stage.result);
  }

  /// "네, 심을래요"를 누르면 곧바로 심어지는 것이 아니라, 어떤 씨앗(용서/사랑/평안)을
  /// 심을지 한 번 더 고르는 중간 단계로 넘어간다.
  void _goToSeedSelect() {
    setState(() => _stage = _Stage.seedSelect);
  }

  /// 씨앗을 고르면 결과 화면으로 곧장 넘어가지 않고, 먼저 물뿌리개로 물을 주고
  /// 새싹이 돋아나는 짧은 애니메이션([SeedPlantingAnimation])을 보여준다.
  /// 실제 데이터 기록(recordSession)은 애니메이션이 끝난 뒤에 한다.
  void _chooseSeed(SeedType seed) {
    setState(() {
      _chosenSeedId = seed.id;
      _stage = _Stage.planting;
    });
  }

  Future<void> _onPlantingFinished() async {
    if (_chosenSeedId == null) return;
    await _choose(true, seedType: _chosenSeedId);
  }

  void _openGarden() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GardenScreen()));
  }

  void _openShareSheet() {
    EmotionShareSheet.show(
      context,
      emotion: widget.primaryEmotion,
      targetName: widget.targetName,
      eatenCount: widget.eatenCount,
      maxCombo: widget.maxCombo,
      choseLove: _choseLove,
      note: _noteController.text,
    );
  }

  /// 나무가 새 단계로 자라난 순간, "정원 공유 카드"를 바로 보여준다
  /// (무한의 계단의 "기록 자랑" + Finch의 "감성 공유"를 결합한 아이디어).
  void _openGrowthShareSheet() {
    final garden = context.read<GardenProvider>();
    GardenGrowthShareSheet.show(
      context,
      stageIndex: _treeStageAfter,
      score: garden.score,
      streakDays: garden.streakDays,
      totalFlowersPlanted: garden.totalFlowersPlanted,
    );
  }

  bool _leaving = false;
  Future<void> _goHome() async {
    if (_leaving) return;
    _leaving = true;
    try {
      final garden = context.read<GardenProvider>();
      await garden.addDiaryEntry(
        emotionType: widget.primaryEmotion.type,
        targetName: widget.targetName,
        eatenCount: widget.eatenCount,
        note: _noteController.text,
        intensity: _intensity.round(),
        triggers: _selectedTriggers.toList(),
        sessionId: '$_sessionId:diary',
      );
      // 스테이지 결과를 다 보고 홈으로 돌아가려는, 세션이 자연스럽게 끝나는
      // 순간에만 전면 광고를 고려한다(내부적으로 N판마다 한 번만 실제로 노출됨).
      // 보상/애니메이션 화면 위에는 절대 끼어들지 않도록 이 시점에서만 호출한다.
      await AdService.instance.maybeShowInterstitialAfterStage();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EmotionInputScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted)
        setState(() {
          _saveError = '기록을 저장하지 못했어요. 다시 시도해 주세요.';
          _retrySave = _goHome;
        });
    } finally {
      _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saveError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 42),
                  const SizedBox(height: 20),
                  Text(_saveError!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _retrying ? null : _retryFailedSave,
                    child: Text(_retrying ? '저장 중…' : '다시 저장하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final showBright = _stage == _Stage.result && _choseLove;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.asset(
              showBright
                  ? 'assets/mongi/images/garden_bright.png'
                  : 'assets/mongi/images/garden_dark.png',
              key: ValueKey(showBright),
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: showBright ? 0.10 : 0.32),
          ),
          SafeArea(
            // "처음으로" 버튼이 화면 아래로 넘쳐서 안 보인다는 피드백 - 결과
            // 카드 내용(점수/황금 프레임/성장 메시지/메모 입력창 등)이 많을
            // 때는 화면 높이를 넘어서는데, 예전에는 스크롤 없는 Column이라
            // 넘친 부분이 그대로 잘려서 맨 아래 "처음으로" 버튼이 화면 밖으로
            // 밀려나 있었다. SingleChildScrollView로 감싸 내용이 길어도 끝까지
            // 스크롤해서 버튼을 볼 수 있게 한다.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: switch (_stage) {
                _Stage.stageClear => _buildStageClear(),
                _Stage.asking => _buildAsking(),
                _Stage.seedSelect => _buildSeedSelect(),
                _Stage.planting => _buildPlanting(),
                _Stage.treeGrowth => _buildTreeGrowth(),
                _Stage.result => _buildResult(),
              },
            ),
          ),
          if (showBright) IgnorePointer(child: _buildBloomBurst()),
        ],
      ),
    );
  }

  // Emotion's garden icon(s) + sparkles popping across the whole screen like confetti.
  Widget _buildBloomBurst() {
    final emotionIcons = widget.emotions.map((e) => e.gardenIcon).toList();
    String iconAt(int i) => emotionIcons[i % emotionIcons.length];
    final icons = [
      iconAt(0),
      '✨',
      iconAt(1),
      '🌟',
      iconAt(2),
      '💫',
      iconAt(3),
      '✨',
      iconAt(4),
      '🌟',
    ];
    return AnimatedBuilder(
      animation: _bloomController,
      builder: (context, _) {
        final t = _bloomController.value;
        return Stack(
          children: List.generate(_bloomSpots.length, (i) {
            // Slightly stagger each flower's start time so they pop in one after another.
            final start = (i * 0.05).clamp(0.0, 0.6);
            const spanIn = 0.35;
            final localT = ((t - start) / spanIn).clamp(0.0, 1.0);
            final scale = Curves.elasticOut.transform(localT);
            final fadeT = (localT * 3).clamp(0.0, 1.0);
            final fadeOutStart = 0.75;
            final opacity = t < fadeOutStart
                ? fadeT
                : (1.0 -
                          ((t - fadeOutStart) / (1.0 - fadeOutStart)).clamp(
                            0.0,
                            1.0,
                          )) *
                      fadeT;
            return Align(
              alignment: _bloomSpots[i],
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: (i.isEven ? 1 : -1) * 0.3,
                    child: Text(
                      icons[i % icons.length],
                      style: TextStyle(fontSize: i.isEven ? 36 : 26),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// 스테이지를 실제로 클리어했을 때(목숨을 다 쓰지 않고 목표를 다 채웠을
  /// 때)만 보여지는 확인 화면. "다음 단계로 넘어갈까요?"를 명시적으로 물어,
  /// 방금 스테이지가 끝난 게 죽어서인지 클리어해서인지 헷갈리지 않게 하고
  /// (StageClearBanner와 이어지는 확실한 후속 신호), 스테이지 상승을 "마음을
  /// 심을래요" 선택과 완전히 분리된 별도의 명시적 행동으로 만든다.
  Widget _buildStageClear() {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final currentStage = garden.stage;
    final nextStage = currentStage + 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              const Text(
                'STAGE CLEAR!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE8871E),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.choiceStageClearBody(currentStage, nextStage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.choiceStageClearHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decideStageAdvance(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFBBB0A6)),
                      ),
                      child: Text(
                        l10n.choiceStageClearStayButton,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _decideStageAdvance(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8871E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.choiceStageClearAdvanceButton,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAsking() {
    final l10n = AppLocalizations.of(context);
    final emotionsLabel = widget.emotions
        .map((e) => emotionLabel(l10n, e.type))
        .join(', ');
    final nameLabel =
        (widget.targetName != null && widget.targetName!.isNotEmpty)
        ? l10n.choiceAskingTargetLabel(widget.targetName!, emotionsLabel)
        : emotionsLabel;
    final headline = widget.eatenCount > 0
        ? l10n.choiceAskingHeadlineWithCount(nameLabel, widget.eatenCount)
        : l10n.choiceAskingHeadlineNoCount(nameLabel);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              Text(
                widget.earlyStop ? '🤍' : '🎉',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
              // 3번: 몽이를 실황중계자로 - 방금 먹은 감정에 대해 몽이가
              // 직접 알아챈 것처럼 말을 거는 대사. 통계(먹은 개수/콤보)와
              // 감성 반응을 분리된 카드로 나열하는 대신, 몽이 한 캐릭터의
              // 말풍선 안에 녹인다.
              if (widget.eatenCount > 0 && !widget.earlyStop) ...[
                const SizedBox(height: 10),
                _catSpeechBubble(
                  emotionCatQuestion(l10n, widget.primaryEmotion.type),
                ),
              ],
              if (widget.earlyStop) ...[
                const SizedBox(height: 10),
                Text(
                  // 2번: 실패(목숨 소진)를 "괜찮아요"로만 덮지 않고, 아직
                  // 만나지 못한 감정이 있다면 다음 판을 당기는 게임 후크로
                  // 전환한다("도망친 감정 N개, 다음에 마저 잡아줄래요?").
                  earlyStopHookText(
                    l10n,
                    eatenCount: widget.eatenCount,
                    remaining: widget.target == null
                        ? null
                        : (widget.target! - widget.eatenCount),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    height: 1.5,
                  ),
                ),
              ],
              if (widget.maxCombo >= 3) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseStrong.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    // 1번: "최고 콤보 x5" 같은 순수 게임 수치 대신, 감정을
                    // 마주하면서도 흔들리지 않았다는 회복력의 증거로 읽히도록
                    // 재해석한다.
                    '🔥 ${comboNarrativeText(l10n, widget.maxCombo)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFFE8628A),
                    ),
                  ),
                ),
              ],
              // 4번: 힐링 임팩트 강화 - 예전에는 이번 세션에 대한 관찰
              // ([_sessionInsight])이 씨앗을 다 심고 난 뒤 결과 화면에서만
              // 보였다. 하지만 유저가 가장 마음을 열고 있는 순간은 게임이
              // 막 끝난 "바로 지금"이기 때문에, 씨앗을 심을지 고르기도 전인
              // 이 시점에 곧바로 보여주고, 일반 말풍선과 다른 은은한 카드로
              // 눈에 띄게 강조한다(페이드인 애니메이션 포함).
              if (_sessionInsight != null) ...[
                const SizedBox(height: 12),
                _insightHighlightCard(
                  sessionInsightText(l10n, _sessionInsight!),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                l10n.choiceAskingPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _choose(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFBBB0A6)),
                      ),
                      child: Text(
                        l10n.choiceAskingNotYetButton,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToSeedSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseStrong,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.choiceAskingPlantButton,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "네, 심을래요"를 고른 뒤 나오는 씨앗 선택 단계. 용서/사랑/평안 중 하나를 고르면
  /// 그 씨앗에 물을 한 번 주는 셈으로 몽이의 작은 정원에서 눈에 보이게 자라난다.
  Widget _buildSeedSelect() {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                l10n.choiceSeedSelectTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.choiceSeedSelectSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ...SeedType.all.map((seed) {
                final count = garden.seedCounts[seed.id] ?? 0;
                final emoji = seed.emojiForCount(count);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _chooseSeed(seed),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: seed.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: seed.color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seedLabel(l10n, seed),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: seed.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    count > 0
                                        ? l10n.choiceSeedWateredCount(count)
                                        : seedDescription(l10n, seed),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.inkSoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => setState(() => _stage = _Stage.asking),
                child: Text(
                  l10n.choiceBackButton,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 씨앗을 고른 직후: 빈 흙에 물을 주고 새싹이 돋아나는 애니메이션을 보여준다.
  /// 애니메이션이 끝나면 자동으로 결과 화면([_buildResult])으로 넘어간다.
  Widget _buildPlanting() {
    final l10n = AppLocalizations.of(context);
    final seed = SeedType.byId(_chosenSeedId!);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              Text(
                l10n.choicePlantingTitle(seedLabel(l10n, seed)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SeedPlantingAnimation(
                seed: seed,
                onFinished: _onPlantingFinished,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.choicePlantingSubtitle(seedLabel(l10n, seed)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 몽이의 성장나무([TreeGrowth])가 이번 판의 점수로 다음 단계까지 자랐을 때
  /// 보여주는 성장 전환 애니메이션. 끝나면 자동으로 결과 화면으로 넘어간다.
  Widget _buildTreeGrowth() {
    final l10n = AppLocalizations.of(context);
    final label = treeStageLabel(l10n, _treeStageAfter);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              const Text('🌳', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                l10n.choiceTreeGrowthTitle(label),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              TreeGrowthAnimation(
                fromStageIndex:
                    _treeStageBefore != null && _treeStageBefore! >= 0
                    ? _treeStageBefore
                    : null,
                toStageIndex: _treeStageAfter,
                onFinished: _onTreeGrowthFinished,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.choiceTreeGrowthHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
              // 성장 마일스톤 보너스 - 나무가 새 단계로 자란 바로 이 순간에만
              // 보여주는 특별 보상. 단계가 오를수록 보너스도 커지는 "보상
              // 차등형" 설계를 여기서 직접 체감할 수 있게 강조한다.
              if (_treeMilestoneBonusLight > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE1A8), Color(0xFFFFF3D6)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE0A72E).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        l10n.choiceTreeGrowthBonus(_treeMilestoneBonusLight),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8A6D1F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openGrowthShareSheet,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(
                    l10n.choiceTreeGrowthShareButton,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B8A54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFAFCBA0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final l10n = AppLocalizations.of(context);
    final chosenSeed = _chosenSeedId != null
        ? SeedType.byId(_chosenSeedId!)
        : null;
    final title = _justBloomed
        ? l10n.choiceResultTitleBloomed
        : (chosenSeed != null
              ? l10n.choiceResultTitleSeedPlanted(seedLabel(l10n, chosenSeed))
              : (_choseLove
                    ? l10n.choiceResultTitlePlanted
                    : l10n.choiceResultTitleGentle));
    final baseMessage = _choseLove
        ? l10n.choiceResultMessageLove
        : l10n.choiceResultMessageNoLove;
    final message = !_leveledUp
        ? baseMessage
        : (_newStageNumber == 2
              ? '$baseMessage\n\n${l10n.choiceResultLevelUpStage2}'
              : '$baseMessage\n\n${l10n.choiceResultLevelUpOther(_newStageNumber)}');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          _choseLove
              ? 'assets/mongi/images/cat_happy.png'
              : 'assets/mongi/images/cat_idle.png',
          height: 140,
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (_earnedScore > 0) ...[
                const SizedBox(height: 10),
                ScorePopupAnimation(
                  score: _earnedScore,
                  totalScore: context.watch<GardenProvider>().score,
                ),
              ],
              if (_earnedLightEssence > 0) ...[
                const SizedBox(height: 8),
                _currencyEarnedChip(
                  l10n.choiceResultLightEarned(
                    _earnedLightEssence,
                    context.watch<GardenProvider>().lightEssence,
                  ),
                ),
              ],
              if (_goldenFrameEmotion != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0A72E), Color(0xFFF5C244)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE0A72E).withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('🏆✨', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(
                        l10n.choiceResultGoldenFrameTitle(
                          emotionLabel(l10n, _goldenFrameEmotion!.type),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.choiceResultGoldenFrameDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_transcendedEmotion != null) ...[
                const SizedBox(height: 12),
                _TranscendenceRevealCard(emotion: _transcendedEmotion!),
              ],
              // "1번 개선": 시즌 패스가 재화를 위해 굴리는 트랙이 아니라
              // "마음이 자란 여정"임을 체감시키는 지점 - 마일스톤 레벨에
              // 도달한 바로 이 순간, 재화 알림과는 다른 톤(격려 문구)으로
              // 조용히 보여준다.
              if (_seasonMilestoneLevel != null) ...[
                const SizedBox(height: 12),
                _SeasonMilestoneCard(level: _seasonMilestoneLevel!),
              ],
              if (chosenSeed != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: chosenSeed.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chosenSeed.emojiForCount(
                          context
                                  .read<GardenProvider>()
                                  .seedCounts[chosenSeed.id] ??
                              1,
                        ),
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.choiceResultSeedGrown(seedLabel(l10n, chosenSeed)),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: chosenSeed.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              // 4번: 힐링 임팩트 강화 - [_sessionInsight]는 이제 게임이 끝난
              // 직후([_buildAsking])에 이미 강조 카드로 보여줬으므로, 여기
              // (씨앗까지 다 심은 결과 화면)에서 똑같은 문장을 또 반복하지
              // 않는다. 대신 다음 판을 기대하게 만드는 [_nextGoalHint]만
              // 남겨 "이미 들은 말을 또 듣는" 느낌 없이 자연스럽게 마무리한다.
              if (_nextGoalHint != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F5E6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌱', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nextGoalHintText(l10n, _nextGoalHint!),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5B8A54),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_choseLove) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openGarden,
                    icon: const Text('🌷', style: TextStyle(fontSize: 18)),
                    label: Text(
                      l10n.choiceResultGardenButton,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FB37A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.choiceResultNoteLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                maxLength: 60,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.choiceResultNoteHint,
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bg0,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildIntensitySlider(),
              const SizedBox(height: 18),
              _buildTriggerTags(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openShareSheet,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(
                    l10n.choiceResultShareButton,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkSoft,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFBBB0A6)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roseStrong,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.choiceResultHomeButton,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 감정 강도(1~5)를 슬라이더로 남길 수 있는 UI. 안 건드려도 기본값(3=보통)
  /// 그대로 저장되므로 부담 없이 넘어갈 수 있다.
  Widget _buildIntensitySlider() {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.choiceIntensityVeryWeak,
      l10n.choiceIntensityWeak,
      l10n.choiceIntensityNormal,
      l10n.choiceIntensityStrong,
      l10n.choiceIntensityVeryStrong,
    ];
    final index = _intensity.round().clamp(1, 5) - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.choiceIntensityLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.roseStrong,
            inactiveTrackColor: const Color(0xFFF0E6DF),
            thumbColor: AppColors.roseStrong,
            overlayColor: const Color(0x22FF8FAB),
            trackHeight: 4,
          ),
          child: Slider(
            value: _intensity,
            min: 1,
            max: 5,
            divisions: 4,
            label: labels[index],
            onChanged: (v) => setState(() => _intensity = v),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            labels[index],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }

  /// "오늘 이 감정, 무엇 때문이었을까요?" 트리거 태그 선택 UI. 여러 개
  /// 선택 가능하며 전부 선택하지 않아도 된다(선택 사항).
  Widget _buildTriggerTags() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.choiceTriggerLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionTrigger.all.map((trigger) {
            final selected = _selectedTriggers.contains(trigger.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedTriggers.remove(trigger.id);
                  } else {
                    _selectedTriggers.add(trigger.id);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.roseStrong : AppColors.bg0,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.roseStrong
                        : const Color(0xFFE5DBD0),
                  ),
                ),
                child: Text(
                  emotionTriggerDisplay(l10n, trigger),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 4번: 힐링 임팩트 강화 - [_sessionInsight]를 일반 몽이 말풍선보다
  /// 눈에 띄는 카드로 감싸고, 처음 나타날 때 부드럽게 페이드인 + 살짝
  /// 떠오르는 애니메이션을 줘서 "몽이가 방금 알아챈 것"이라는 느낌을 준다.
  Widget _insightHighlightCard(String text) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE3EC)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFFC7D9).withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐱💭', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B4B3E),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 몽이가 직접 말을 거는 것처럼 보이는 작은 말풍선 - 실황중계자 컨셉의
  /// 핵심 UI. 통계/감성 카드를 따로 나열하지 않고, 이 말풍선 하나에 몽이의
  /// 반응을 담아서 게임 진행 상황과 힐링 언어를 한 캐릭터 안에서 잇는다.
  Widget _catSpeechBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🐱', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 이번 판에서 얻은 빛의 정수를 보여주는 작은 칩 (엔드리스 결과 화면의
  /// _currencyEarnedChip과 동일한 톤을 스테이지 결과 화면에도 맞춰준다).
  Widget _currencyEarnedChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Color(0xFF8A6D1F),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 6번: 감정 마스터(50번) 이후 아무 예고도 없다가, 100번째 마주침에 딱 한 번
/// "짠!" 하고 나타나는 히든 발견 카드. 다른 보상 카드들(황금 프레임/점수 등)과
/// 구분되도록 별빛이 감도는 짙은 남색 그라데이션을 쓰고, 등장할 때 살짝
/// 확대되며 페이드인해서 "우연히 뭔가 특별한 걸 발견했다"는 느낌을 준다.
class _TranscendenceRevealCard extends StatelessWidget {
  final Emotion emotion;

  const _TranscendenceRevealCard({required this.emotion});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + t * 0.15, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2F63), Color(0xFF6B4FA0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8D9FF).withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4FA0).withValues(alpha: 0.55),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🌌✨', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              l10n.choiceTranscendenceBadge,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8D9FF),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.choiceTranscendenceTitle(emotionLabel(l10n, emotion.type)),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.choiceTranscendenceDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: Color(0xFFE8D9FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1번 개선": 시즌 패스 "마음 마일스톤"(5의 배수 레벨) 도달 축하 카드.
/// 재화 지급 알림([_currencyEarnedChip])이나 황금 프레임 카드와는 다르게,
/// 오직 격려 문구만 보여준다 - "결제를 유도하는 소비 트랙"이 아니라
/// "꾸준함 자체를 인정해주는 여정"이라는 톤을 전달하는 것이 목적이다.
class _SeasonMilestoneCard extends StatelessWidget {
  final int level;

  const _SeasonMilestoneCard({required this.level});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = seasonMilestoneText(l10n, level);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.9 + t * 0.1, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7FB37A), Color(0xFFAFCBA0)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7FB37A).withValues(alpha: 0.4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🌿', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              l10n.choiceSeasonMilestoneBadge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
