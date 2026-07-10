import 'package:flutter/material.dart';

/// 월간 리포트 전용 - '밤의 정원' 무드 배경 (짙은 남색 그라데이션 + 은은한 별빛)
class MoonlitReportBackground extends StatelessWidget {
  final Widget child;
  const MoonlitReportBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.85),
          radius: 1.4,
          colors: [Color(0xFF2E3652), Color(0xFF1B2138), Color(0xFF14182B)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _MoonGlow()),
          const Positioned.fill(child: _NightStars()),
          child,
        ],
      ),
    );
  }
}

class _MoonGlow extends StatelessWidget {
  const _MoonGlow();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0.7, -0.95),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFF4EBD0).withValues(alpha: 0.35),
              const Color(0xFFF4EBD0).withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// 잔잔하게 반짝이는 밤하늘 별 (StarsBackground의 꽃잎 파티클과는 다른, 고정된 점 별빛)
class _NightStars extends StatelessWidget {
  const _NightStars();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: Size.infinite, painter: _StarDotsPainter()),
    );
  }
}

class _StarDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = List.generate(46, (i) => i);
    for (final i in rng) {
      final seed = i * 37.13;
      final dx = (seed * 12.9898) % 1.0 * size.width;
      final dy = (seed * 78.233) % 1.0 * size.height;
      final r = ((seed * 3.14) % 1.0) * 1.3 + 0.4;
      final opacity = ((seed * 5.77) % 1.0) * 0.5 + 0.25;
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
