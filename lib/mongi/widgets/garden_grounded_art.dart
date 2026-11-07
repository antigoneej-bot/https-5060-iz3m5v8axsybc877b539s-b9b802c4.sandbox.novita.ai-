import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Static contact lighting and a few foreground blades join art to the lawn.
/// Does not alter saved placement, growth, or hit targets.
class GardenGroundedArt extends StatelessWidget {
  final Widget child;
  final bool night, bench;
  const GardenGroundedArt({
    super.key,
    required this.child,
    this.night = false,
    this.bench = false,
  });
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GroundContact(night, bench, false),
    foregroundPainter: _GroundContact(night, bench, true),
    child: GardenNightLight(
      night: night,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          night ? Colors.white : const Color(0xFFFFF7E5),
          BlendMode.modulate,
        ),
        child: child,
      ),
    ),
  );
}

class _GroundContact extends CustomPainter {
  final bool night, bench, foreground;
  const _GroundContact(this.night, this.bench, this.foreground);
  @override
  void paint(Canvas c, Size s) {
    final y = s.height * .90;
    if (!foreground) {
      final rect = Rect.fromCenter(
        center: Offset(s.width * .43, y + s.height * .015),
        width: s.width * (bench ? .85 : .64),
        height: s.height * (night ? .18 : .13),
      );
      c.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (night ? const Color(0xFF26354B) : const Color(0xFF394127))
                  .withValues(alpha: night ? .18 : .30),
              const Color(0x00394127),
            ],
          ).createShader(rect),
      );
      return;
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 19; i++) {
      final u = i / 18;
      // Keep the space between bench legs open.
      if (bench && u > .22 && u < .78) continue;
      final x = s.width * (.25 + u * .5);
      final base = y + math.sin(i * 2.1) * s.height * .012;
      final h = s.height * (.022 + (i % 4) * .006);
      paint.color = (night
          ? const [Color(0xFF354A55), Color(0xFF4C6265), Color(0xFF63777A)]
          : const [
              Color(0xFF7C8742),
              Color(0xFFA4A753),
              Color(0xFFC7BC6B),
            ])[i % 3];
      paint.strokeWidth = math.max(.65, s.width * .004);
      c.drawPath(
        Path()
          ..moveTo(x, base)
          ..quadraticBezierTo(
            x - h * .25,
            base - h * .65,
            x + h * (i.isEven ? .25 : -.35),
            base - h,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroundContact old) =>
      old.night != night || old.bench != bench || old.foreground != foreground;
}

/// Shared moonlight for every pose and garden item; alpha stays unchanged.
class GardenNightLight extends StatelessWidget {
  final Widget child;
  final bool night;
  const GardenNightLight({super.key, required this.child, required this.night});
  @override
  Widget build(BuildContext context) => !night
      ? child
      : ShaderMask(
          blendMode: BlendMode.modulate,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFBACBE0), Color(0xFF879CB9), Color(0xFF687B99)],
            stops: [0, .45, 1],
          ).createShader(bounds),
          child: child,
        );
}

/// Local light only while Mongi is seated on the bench at night.
class GardenBenchMoonlight extends StatelessWidget {
  final Widget child;
  final bool night, seated, animate;
  const GardenBenchMoonlight({
    super.key,
    required this.child,
    required this.night,
    required this.seated,
    required this.animate,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: night && seated ? 1 : 0),
    duration: Duration(milliseconds: animate ? 1200 : 0),
    curve: Curves.easeInOut,
    child: child,
    builder: (context, value, child) => CustomPaint(
      painter: _BenchMoonGlow(night ? value : 0),
      child: !night
          ? child!
          : ShaderMask(
              blendMode: BlendMode.modulate,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.lerp(
                    const Color(0xFFBACBE0),
                    const Color(0xFFF0F1E5),
                    value,
                  )!,
                  Color.lerp(
                    const Color(0xFF879CB9),
                    const Color(0xFFBDCADA),
                    value,
                  )!,
                  Color.lerp(
                    const Color(0xFF687B99),
                    const Color(0xFF8396B0),
                    value,
                  )!,
                ],
                stops: const [0, .45, 1],
              ).createShader(bounds),
              child: child,
            ),
    ),
  );
}

class _BenchMoonGlow extends CustomPainter {
  final double strength;
  const _BenchMoonGlow(this.strength);
  @override
  void paint(Canvas c, Size s) {
    if (strength <= 0) return;
    c.save();
    c.translate(s.width * .68, s.height * .33);
    c.rotate(.42);
    final beam = Rect.fromCenter(
      center: Offset(0, -s.height * .22),
      width: s.width * 1.05,
      height: s.height * 2.3,
    );
    c.drawOval(
      beam,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFDCE8FF).withValues(alpha: strength * .14),
            const Color(0xFFDCE8FF).withValues(alpha: strength * .045),
            const Color(0x00DCE8FF),
          ],
          stops: const [0, .5, 1],
        ).createShader(beam),
    );
    c.restore();
    final seat = Rect.fromCenter(
      center: Offset(s.width * .5, s.height * .98),
      width: s.width * 1.6,
      height: s.height * .35,
    );
    c.drawOval(
      seat,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE2E9FC).withValues(alpha: strength * .12),
            const Color(0x00E2E9FC),
          ],
        ).createShader(seat),
    );
  }

  @override
  bool shouldRepaint(covariant _BenchMoonGlow old) => old.strength != strength;
}
