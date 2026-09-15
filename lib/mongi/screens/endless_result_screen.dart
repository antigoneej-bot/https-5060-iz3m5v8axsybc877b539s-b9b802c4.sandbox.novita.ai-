import '../../theme.dart' show AppColors;
import '../integration/session_transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/choice_narrative_l10n.dart';
import '../l10n/emotion_insight_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_insight_service.dart';
import 'emotion_input_screen.dart';
import 'endless_mode_screen.dart';

/// "무한의 계단"식 엔드리스 모드가 끝난 뒤 나오는 결과 화면.
/// 목표는 단 하나: "오늘 내 최고 기록"을 세웠는지 보여주는 것.
/// 랭킹/경쟁은 "채찍"이 아니라 "가벼운 동기부여 게임"처럼 느껴지도록,
/// 힐링 게임의 다정한 톤을 그대로 유지한다.
class EndlessResultScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final String? targetName;
  final Map<EmotionType, int> eatenByType;
  final int survivedSeconds;
  final int maxCombo;

  const EndlessResultScreen({
    super.key,
    required this.emotions,
    required this.targetName,
    required this.eatenByType,
    required this.survivedSeconds,
    this.maxCombo = 0,
  });

  /// 이번 판에서 먹은 총 개수 (감정 타입 합산).
  int get eatenCount => eatenByType.values.fold(0, (sum, c) => sum + c);

  @override
  State<EndlessResultScreen> createState() => _EndlessResultScreenState();
}

class _EndlessResultScreenState extends State<EndlessResultScreen> {
  bool? _isNewRecord;
  bool _saving = false;
  bool _saveFailed = false;
  final _sessionId = SessionTransaction.newId();

  // 다음 판을 기대하게 만드는 "오픈 루프" 한 줄 - 이번 세션이 아직
  // diaryEntries에 저장되기 전 시점의 과거 기록만 보고 계산해서 고정해둔다.
  NextGoalHintResult? _nextGoalHint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final garden = context.read<GardenProvider>();
      setState(() {
        _nextGoalHint = EmotionInsightService.buildNextGoalHintKind(
          diaryEntries: garden.diaryEntries,
          pointsToNextTreeStage: garden.pointsToNextTreeStage,
        );
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  Future<void> _record() async {
    if (!mounted || _saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final garden = context.read<GardenProvider>();
      // 무한도전은 순수 재미 모드라 포인트/재화 적립이 없다 - "오늘 내
      // 최고기록" 갱신 여부만 돌려받는다.
      final isNewRecord = await garden.recordEndlessSession(
        widget.eatenByType,
        survivedSeconds: widget.survivedSeconds,
        sessionId: _sessionId,
      );
      if (!mounted) return;
      setState(() {
        _isNewRecord = isNewRecord;
      });
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatTime(AppLocalizations l10n, int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0
        ? l10n.endlessResultTimeMinSec(m, s)
        : l10n.endlessResultTimeSecOnly(s);
  }

  /// 다시 도전하기 - 3번(정체성 재정렬): 기력 시스템을 제거해 언제든
  /// 바로 재입장할 수 있다.
  Future<void> _retry() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EndlessModeScreen(
          emotions: widget.emotions,
          targetName: widget.targetName,
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmotionInputScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isNewRecord == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_saveFailed ? '도전 기록을 저장하지 못했어요.' : '도전 기록을 저장하고 있어요.'),
              const SizedBox(height: 20),
              if (_saveFailed)
                FilledButton(
                  onPressed: _saving ? null : _record,
                  child: const Text('다시 저장하기'),
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final isNewRecord = _isNewRecord ?? false;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8EE), Color(0xFFEAF6FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            child: Column(
              children: [
                Image.asset(
                  isNewRecord
                      ? 'assets/mongi/images/cat_happy.png'
                      : 'assets/mongi/images/cat_idle.png',
                  height: 130,
                ),
                const SizedBox(height: 16),
                if (isNewRecord)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE29A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.endlessResultNewRecordBadge,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF8A5A00),
                      ),
                    ),
                  ),
                Container(
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
                  child: Column(
                    children: [
                      Text(
                        l10n.endlessResultCardTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _statBox(
                              emoji: '🍬',
                              label: l10n.endlessResultEatenCountLabel,
                              value: l10n.endlessResultEatenCountValue(
                                widget.eatenCount,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statBox(
                              emoji: '⏱️',
                              label: l10n.endlessResultSurvivedTimeLabel,
                              value: _formatTime(l10n, widget.survivedSeconds),
                            ),
                          ),
                        ],
                      ),
                      if (widget.maxCombo >= 3) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF8FAB,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            // 1번: 순수 콤보 수치를 감정 회복력의 증거로 재해석.
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg0,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.endlessResultBestRecordLabel,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.endlessResultBestRecordValue(
                                garden.bestEndlessCount,
                                _formatTime(l10n, garden.bestEndlessSeconds),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.endlessResultRankingFooter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                      if (_nextGoalHint != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🐱', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nextGoalHintText(l10n, _nextGoalHint!),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8A6D1F),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.roseStrong,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.endlessResultRetryButton,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _goHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Color(0xFFBBB0A6)),
                          ),
                          child: Text(
                            l10n.choiceResultHomeButton,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox({
    required String emoji,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
