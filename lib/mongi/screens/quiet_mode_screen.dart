import '../../theme.dart' show AppColors;
import '../integration/session_transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/breathing_technique_l10n.dart';
import '../models/breathing_technique.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_breathing_service.dart';
import '../widgets/breathing_interstitial.dart';
import 'garden_screen.dart';

enum _QuietStage { greet, breathe, reflect, planting, done }

/// 3번(벤치마킹 제안: "고요 모드/활동 모드" 이원화) - 러너 게임(활동 모드)을
/// 전혀 거치지 않고, 고른 감정을 그대로 조용히 마주하고 정원에 심는 저자극
/// 흐름.
///
/// 활동 모드([RunnerGameScreen]/[EndlessModeScreen])와는 목적 자체가
/// 다르다 - 반응 속도/점수/콤보 같은 "게임" 요소가 전혀 없고, 오직
/// "감정 보여주기 -> (선택) 숨 고르기 -> (선택) 한 줄 기록하기 -> 마음에
/// 심기"만 조용히 이어진다. [GardenProvider.recordQuietSession]도 엔드리스
/// 모드보다 한 걸음 더 나아가 하루 한 번 공통 돌봄 보상을 지급하므로, 이 화면은
/// "빠르게 여러 번 돌릴" 유인이 전혀 없는 순수 웰니스 트랙이다.
class QuietModeScreen extends StatefulWidget {
  final List<Emotion> emotions;
  final String? targetName;

  const QuietModeScreen({super.key, required this.emotions, this.targetName});

  @override
  State<QuietModeScreen> createState() => _QuietModeScreenState();
}

class _QuietModeScreenState extends State<QuietModeScreen>
    with SingleTickerProviderStateMixin {
  _QuietStage _stage = _QuietStage.greet;
  final TextEditingController _noteController = TextEditingController();
  double _intensity = 3;
  bool _saved = false;
  bool _saveFailed = false;
  final String _sessionId = SessionTransaction.newId();

  late final BreathingTechniqueDef _technique =
      EmotionBreathingService.suggestFor(widget.emotions);

  late final AnimationController _plantController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finishPlanting();
      });

  Emotion get _primaryEmotion => widget.emotions.first;

  @override
  void dispose() {
    _noteController.dispose();
    _plantController.dispose();
    super.dispose();
  }

  void _goTo(_QuietStage stage) {
    if (!mounted) return;
    setState(() => _stage = stage);
  }

  Future<void> _startBreathing() async {
    final completed = await BreathingInterstitial.show(
      context,
      technique: _technique,
    );
    if (!mounted) return;
    if (completed) {
      await context.read<GardenProvider>().completeBreathingTechnique(
        _technique,
      );
    }
    if (!mounted) return;
    _goTo(_QuietStage.reflect);
  }

  void _startPlanting() {
    _goTo(_QuietStage.planting);
    _plantController.forward(from: 0);
  }

  Future<void> _finishPlanting() async {
    if (_saved) return;
    _saved = true;
    if (mounted) setState(() => _saveFailed = false);
    final name = widget.targetName?.trim();
    try {
      await context.read<GardenProvider>().recordQuietSession(
        widget.emotions.map((e) => e.type).toList(),
        targetName: (name == null || name.isEmpty) ? null : name,
        note: _noteController.text,
        intensity: _intensity.round(),
        sessionId: _sessionId,
      );
      if (mounted) _goTo(_QuietStage.done);
    } catch (_) {
      _saved = false;
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  void _goHome() {
    Navigator.of(context).pop();
  }

  void _openGarden() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const GardenScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF3FF), Color(0xFFF6F0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: switch (_stage) {
                      _QuietStage.greet => _buildGreet(),
                      _QuietStage.breathe => _buildBreathe(),
                      _QuietStage.reflect => _buildReflect(),
                      _QuietStage.planting => _buildPlanting(),
                      _QuietStage.done => _buildDone(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final showBack = _stage == _QuietStage.greet || _stage == _QuietStage.done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              showBack ? Icons.close : Icons.arrow_back,
              color: AppColors.ink,
            ),
            onPressed: _goHome,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.quietModeAppBarTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      key: ValueKey(_stage),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── 1단계: 감정 보여주기 ─────────────────────────
  Widget _buildGreet() {
    final l10n = AppLocalizations.of(context);
    return _card(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: widget.emotions
                .map(
                  (e) => Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(e.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.quietModeGreetTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            emotionCatQuestion(l10n, _primaryEmotion.type),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quietModeGreetSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _goTo(_QuietStage.breathe),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B8FE0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.quietModeGreetNextButton,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2단계: 숨 고르기(선택) ─────────────────────────
  Widget _buildBreathe() {
    final l10n = AppLocalizations.of(context);
    return _card(
      child: Column(
        children: [
          Text(_technique.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text(
            l10n.quietModeBreatheTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            breathingTechniqueName(l10n, _technique),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6FA8A0),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            breathingTechniqueDescription(l10n, _technique),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _startBreathing,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FA8A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.quietModeBreatheStartButton,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _goTo(_QuietStage.reflect),
            child: Text(
              l10n.quietModeBreatheSkipButton,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3단계: 한 줄 기록(선택) + 강도 ─────────────────────────
  Widget _buildReflect() {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.choiceIntensityVeryWeak,
      l10n.choiceIntensityWeak,
      l10n.choiceIntensityNormal,
      l10n.choiceIntensityStrong,
      l10n.choiceIntensityVeryStrong,
    ];
    final index = _intensity.round().clamp(1, 5) - 1;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quietModeReflectTitle,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: l10n.quietModeReflectHint,
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: AppColors.bg0,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.choiceIntensityLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF9B8FE0),
              inactiveTrackColor: const Color(0xFFEDE7FA),
              thumbColor: const Color(0xFF9B8FE0),
              overlayColor: const Color(0x229B8FE0),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _startPlanting,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7FB37A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.quietModePlantButton,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4단계: 마음 심기 애니메이션 ─────────────────────────
  Widget _buildPlanting() {
    if (_saveFailed)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('마음을 저장하지 못했어요. 다시 시도해 주세요.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _finishPlanting,
            child: const Text('다시 저장하기'),
          ),
        ],
      );
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      key: const ValueKey(_QuietStage.planting),
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _plantController,
            builder: (context, _) {
              final t = _plantController.value;
              return SizedBox(
                height: 140,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 12)),
                    ...List.generate(widget.emotions.length, (i) {
                      final start = i * 0.18;
                      final localT = ((t - start) / 0.5).clamp(0.0, 1.0);
                      final scale = Curves.elasticOut.transform(localT);
                      final dx = (i - (widget.emotions.length - 1) / 2) * 46.0;
                      return Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Transform.translate(
                            offset: Offset(dx, 0),
                            child: Opacity(
                              opacity: localT.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: scale.clamp(0.0, 1.3),
                                child: Text(
                                  widget.emotions[i].gardenIcon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            l10n.quietModePlantingMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── 5단계: 완료 ─────────────────────────
  Widget _buildDone() {
    final l10n = AppLocalizations.of(context);
    return _card(
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: widget.emotions
                .map(
                  (e) =>
                      Text(e.gardenIcon, style: const TextStyle(fontSize: 30)),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.quietModeDoneTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.quietModeDoneBody(widget.emotions.length),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goHome,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFBBB0A6)),
                  ),
                  child: Text(
                    l10n.quietModeDoneHomeButton,
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
                  onPressed: _openGarden,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7FB37A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.quietModeDoneGardenButton,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
