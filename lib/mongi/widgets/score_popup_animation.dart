import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';

/// 스테이지를 완료했을 때 얻은 점수를 "+N점 ✨" 형태로 통통 튀듯 보여주는
/// 짧은 팝업 애니메이션. [SeedPlantingAnimation]과 마찬가지로 자체
/// [AnimationController] 하나로 구성되어, 화면에 뜨자마자 자동으로 재생된다.
class ScorePopupAnimation extends StatefulWidget {
  final int score;
  final int totalScore;

  const ScorePopupAnimation({
    super.key,
    required this.score,
    required this.totalScore,
  });

  @override
  State<ScorePopupAnimation> createState() => _ScorePopupAnimationState();
}

class _ScorePopupAnimationState extends State<ScorePopupAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end, double t) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        // 0.0~0.55: 팅! 하고 튀어 오르며 등장 (elasticOut)
        final popT = Curves.elasticOut.transform(_phase(0.0, 0.55, t));
        // 0.55~1.0: 살짝 위로 떠오르며 자리를 잡는다
        final floatT = _phase(0.55, 1.0, t);
        final floatOffset = -6.0 * floatT;
        // 반짝임: 0.35~0.9 구간 동안 좌우에서 살짝
        final sparkleT = _phase(0.35, 0.9, t);
        final sparkleOpacity = sparkleT < 1
            ? (sparkleT < 0.7 ? sparkleT / 0.7 : (1 - sparkleT) / 0.3)
            : 0.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: popT.clamp(0.0, 1.3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE29A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5C244).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: sparkleOpacity.clamp(0.0, 1.0),
                    child: const Text('✨', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.scorePopupGainedLabel(widget.score),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF8A5A00),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.scorePopupTotalLabel(widget.totalScore),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFFAD8A3E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Opacity(
                    opacity: sparkleOpacity.clamp(0.0, 1.0),
                    child: const Text('✨', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
