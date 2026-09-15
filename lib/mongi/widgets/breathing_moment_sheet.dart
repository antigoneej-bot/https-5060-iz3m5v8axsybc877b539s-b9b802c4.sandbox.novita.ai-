import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// 6번(호흡 미니게임): 러너 게임 도중 "숨결 구슬"에 닿았을 때 뜨는, 아주 짧은
/// 인터랙티브 호흡 맞추기.
///
/// 지금까지 몽이의 조작은 전부 "빠르게 반응하기"(주먹 타이밍/점프)였다.
/// 이 미니게임은 정반대로 "잠깐 멈춰서 느리게 머무르기"를 요구하는 세 번째
/// 성격의 입력이다 - 화면이 커지는(들이쉬는) 동안은 화면을 꾹 누르고,
/// 작아지는(내쉬는) 동안은 손을 떼며 몽이와 숨을 맞춘다.
///
/// [BreathingInterstitial](매 판이 끝난 뒤 나오는, 순전히 보기만 하는 4~5회
/// 호흡)과는 역할이 다르다 - 여기는 플레이 도중 아주 짧게(2회, 약 9초)만
/// 등장하고, 실제로 손으로 맞춰야 하는 판정이 있으며, 잘 맞추면 보상이
/// 따라온다. 못 맞추거나 건너뛰어도 페널티는 전혀 없다 - 힐링 게임 톤을
/// 지키기 위해 이 미니게임은 오직 "보너스"로만 작동한다.
class BreathingMomentSheet extends StatefulWidget {
  const BreathingMomentSheet({super.key});

  /// 미니게임을 띄우고, 호흡을 얼마나 잘 맞췄는지에 따라 성공(true)/그냥
  /// 지나감(false)을 반환한다. 건너뛰기를 눌러도 항상 false(페널티 없음).
  static Future<bool> show(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'breathing-moment',
      barrierColor: Colors.black.withValues(alpha: 0.0),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const BreathingMomentSheet();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ).then((value) => value ?? false);
  }

  @override
  State<BreathingMomentSheet> createState() => _BreathingMomentSheetState();
}

class _BreathingMomentSheetState extends State<BreathingMomentSheet>
    with SingleTickerProviderStateMixin {
  // 종료 후 결과(post-run) 인터스티셜(4초+4초, 3회)보다 훨씬 짧게 -
  // 게임 플레이 도중 잠깐 끼어드는 순간이라 너무 길면 흐름을 방해한다.
  static const Duration _inhale = Duration(milliseconds: 2200);
  static const Duration _exhale = Duration(milliseconds: 2200);
  static const int _totalCycles = 2;

  /// 전체 프레임 중 "지금 위상(들이쉬기/내쉬기)에 맞게 누르거나 뗀" 비율이
  /// 이 값 이상이면 성공으로 판정한다. 100% 정밀함을 요구하면 오히려
  /// 스트레스를 주므로, 절반을 살짝 넘는 정도로 관대하게 잡았다.
  static const double _successThreshold = 0.55;

  late final AnimationController _controller;
  bool _closed = false;
  int _cycleIndex = 0;
  bool _isHeld = false;
  int _totalTicks = 0;
  int _matchedTicks = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _inhale + _exhale);
    _controller.addListener(_onTick);
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (_cycleIndex + 1 >= _totalCycles) {
        _finish();
        return;
      }
      setState(() => _cycleIndex++);
      _controller.forward(from: 0);
    });
    _controller.forward();
  }

  /// 매 애니메이션 프레임마다 "지금 위상(들이쉬기 중이면 눌러야 함/내쉬기
  /// 중이면 떼야 함)"과 실제 손가락 상태가 일치하는지 샘플링한다. 프레임
  /// 간격이 거의 균일(60fps)하므로 단순히 틱 개수로 비율을 계산해도
  /// 충분히 정확하다.
  void _onTick() {
    final totalMs = (_inhale + _exhale).inMilliseconds;
    final elapsedMs = _controller.value * totalMs;
    final isInhalePhase = elapsedMs <= _inhale.inMilliseconds;
    _totalTicks++;
    if (isInhalePhase == _isHeld) {
      _matchedTicks++;
    }
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
    final ratio = _totalTicks == 0 ? 0.0 : _matchedTicks / _totalTicks;
    if (mounted) Navigator.of(context).pop(ratio >= _successThreshold);
  }

  void _skip() {
    if (_closed) return;
    _closed = true;
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SizedBox.expand(
        child: Material(
          color: const Color(0xFF3E7C74),
          child: SafeArea(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => setState(() => _isHeld = true),
              onPointerUp: (_) => setState(() => _isHeld = false),
              onPointerCancel: (_) => setState(() => _isHeld = false),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌬', style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context).breathingMomentTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _buildBreathCircle(context),
                      ),
                      const SizedBox(height: 26),
                      _buildCycleDots(),
                      const SizedBox(height: 22),
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: Text(
                          AppLocalizations.of(context).onboardingSkip,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalCycles, (i) {
        final isPast = i < _cycleIndex;
        final isCurrent = i == _cycleIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 10 : 8,
          height: isCurrent ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isPast || isCurrent)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  /// 원이 커지는 동안 "들이쉬며 꾹 눌러요", 작아지는 동안 "내쉬며 손을
  /// 떼요"를 안내한다. 지금 손가락을 누르고 있는지에 따라 테두리 색이
  /// 살짝 밝아져, 입력이 실제로 인식되고 있다는 손맛을 준다.
  Widget _buildBreathCircle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalMs = (_inhale + _exhale).inMilliseconds;
    final elapsedMs = _controller.value * totalMs;
    final inhaleMs = _inhale.inMilliseconds;

    late double scale;
    late String label;
    if (elapsedMs <= inhaleMs) {
      final p = (elapsedMs / inhaleMs).clamp(0.0, 1.0);
      scale = 0.55 + 0.45 * Curves.easeInOut.transform(p);
      label = l10n.breathingMomentInhaleLabel;
    } else {
      final p = ((elapsedMs - inhaleMs) / (totalMs - inhaleMs)).clamp(0.0, 1.0);
      scale = 1.0 - 0.45 * Curves.easeInOut.transform(p);
      label = l10n.breathingMomentExhaleLabel;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFE8FFF7), Color(0xFF6FE0C6)],
              ),
              border: Border.all(
                color: _isHeld
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                width: _isHeld ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: _isHeld ? 0.55 : 0.3),
                  blurRadius: 26,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
