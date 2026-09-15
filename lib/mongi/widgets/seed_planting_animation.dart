import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/seed.dart';

/// 씨앗을 고른 직후 재생되는 "심기" 애니메이션.
///
/// 연출 순서:
///  1) 아무것도 없는 흙 (빈 정원 자리)
///  2) 물뿌리개가 위에서 살짝 기울어지며 등장해 물을 뿌린다 (물방울 낙하)
///  3) 흙 사이로 작은 새싹이 통통 튀듯 돋아난다 + 주변에 반짝임
///
/// 완전히 자체 [AnimationController] 하나로 구성되어 있고, 끝나면
/// [onFinished] 콜백으로 알려준다 (호출부에서 "다음" 버튼을 보여주는 등 사용).
class SeedPlantingAnimation extends StatefulWidget {
  final SeedType seed;
  final VoidCallback? onFinished;

  const SeedPlantingAnimation({super.key, required this.seed, this.onFinished});

  @override
  State<SeedPlantingAnimation> createState() => _SeedPlantingAnimationState();
}

class _SeedPlantingAnimationState extends State<SeedPlantingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished?.call();
        }
      });

  @override
  void initState() {
    super.initState();
    // 화면에 뜨자마자 자동으로 한 번 재생된다.
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        // 물뿌리개: 오른쪽 위에서 슬쩍 내려와 기울어짐 (0.00~0.30 등장, 0.30~0.55 붓기, 0.55~0.75 원위치)
        final canEnter = Curves.easeOutBack.transform(_phase(0.0, 0.28, t));
        final canTiltT = Curves.easeInOut.transform(_phase(0.24, 0.55, t));
        final canReturnT = _phase(0.60, 0.78, t);
        final canTilt = canTiltT * (1 - canReturnT); // 0 -> 최대 기울기 -> 다시 0

        // 물줄기/물방울: 0.30~0.62 구간 동안 떨어짐
        final waterT = _phase(0.30, 0.62, t);
        final showWater = t > 0.28 && t < 0.66;

        // 새싹: 0.62~1.0 구간에서 통통 튀며 자라남
        final sproutT = Curves.elasticOut.transform(_phase(0.62, 0.95, t));
        final showSprout = t > 0.60;

        // 반짝임: 새싹이 다 자란 뒤(0.85~1.0) 주변에 살짝
        final sparkleT = _phase(0.85, 1.0, t);

        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // 빈 흙 (항상 보임)
              Positioned(
                bottom: 0,
                child: Image.asset('assets/mongi/images/empty_soil.png', height: 96),
              ),

              // 새싹 (씨앗 색상에 맞춘 이모지, growthStages[1] = 새싹 단계 사용)
              if (showSprout)
                Positioned(
                  bottom: 46,
                  child: Transform.scale(
                    scale: sproutT.clamp(0.0, 1.4),
                    child: Text(
                      widget.seed.growthStages.length > 1
                          ? widget.seed.growthStages[1]
                          : '🌱',
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                ),

              // 새싹 주변 반짝임
              if (sparkleT > 0)
                Positioned(
                  bottom: 90,
                  child: Opacity(
                    opacity: (1 - sparkleT).clamp(0.0, 1.0) < 1
                        ? (sparkleT < 1 ? sparkleT : 0)
                        : 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('✨', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 28),
                        Text('✨', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),

              // 물방울들 (여러 개가 살짝 시간차를 두고 떨어짐)
              if (showWater)
                ...List.generate(4, (i) {
                  final dropStart = i * 0.12;
                  final dropT = ((waterT - dropStart) / (1 - dropStart)).clamp(
                    0.0,
                    1.0,
                  );
                  if (dropT <= 0 || dropT >= 1) return const SizedBox.shrink();
                  final top = 40 + dropT * 90; // 위에서 아래로 낙하
                  final opacity = dropT < 0.85 ? 1.0 : (1 - dropT) / 0.15;
                  return Positioned(
                    top: top,
                    right: 78 - i * 6.0,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: const Text('💧', style: TextStyle(fontSize: 14)),
                    ),
                  );
                }),

              // 물뿌리개 (오른쪽 위에서 등장 -> 기울여 붓기 -> 제자리)
              Positioned(
                top: 4 - canEnter * 4,
                right: 24 - canEnter * 40,
                child: Opacity(
                  opacity: canEnter,
                  child: Transform.rotate(
                    angle: -0.55 * canTilt,
                    alignment: Alignment.bottomLeft,
                    child: Image.asset(
                      'assets/mongi/images/watering_can.png',
                      height: 76,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 애니메이션이 끝난 뒤 은은하게 반짝이는 배경 효과가 필요할 때 쓰는 작은 헬퍼.
/// (현재는 [SeedPlantingAnimation] 내부에서만 별을 그리므로 보조용으로 남겨둠)
class SparklePainter extends CustomPainter {
  final double t;
  SparklePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final rnd = math.Random(7);
    for (int i = 0; i < 6; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.5 + rnd.nextDouble() * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) =>
      oldDelegate.t != t;
}
