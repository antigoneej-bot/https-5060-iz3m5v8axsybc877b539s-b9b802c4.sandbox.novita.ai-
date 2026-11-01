import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Layered artwork uses the same 2400x800 world as saved garden coordinates.
/// These layers are decorative: they never receive taps or mutate growth.
class StorybookBackdrop extends StatelessWidget {
  final bool night;
  const StorybookBackdrop({super.key, required this.night});
  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: ColorFilter.matrix(
      night
          ? const [
              .38,
              0,
              0,
              0,
              0,
              0,
              .44,
              0,
              0,
              3,
              0,
              0,
              .64,
              0,
              12,
              0,
              0,
              0,
              1,
              0,
            ]
          : const [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    ),
    child: Image.asset(
      'assets/storybook_garden/panorama.png',
      key: const Key('storybook-backdrop'),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
  );
}

class StorybookForeground extends StatelessWidget {
  final Animation<double> clock;
  final TransformationController camera;
  final bool night;
  const StorybookForeground({
    super.key,
    required this.clock,
    required this.camera,
    required this.night,
  });
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([clock, camera]),
        child: Image.asset(
          'assets/storybook_garden/foreground.png',
          key: const Key('storybook-foreground'),
          fit: BoxFit.fill,
          color: night ? const Color(0xFF65749B) : null,
          colorBlendMode: BlendMode.modulate,
          excludeFromSemantics: true,
        ),
        builder: (_, child) {
          final scale = camera.value.getMaxScaleOnAxis();
          final pan = scale == 0 ? 0.0 : camera.value.storage[12] / scale;
          return Transform.translate(
            offset: Offset(
              (pan * .016).clamp(-20.0, 20.0) +
                  math.sin(clock.value * math.pi * 2) * 5,
              0,
            ),
            child: Transform.scale(scale: 1.025, child: child),
          );
        },
      ),
    ),
  );
}

class StorybookAtmosphere extends CustomPainter {
  final Animation<double> clock;
  final bool night;
  StorybookAtmosphere(this.clock, this.night) : super(repaint: clock);
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 2400, s.height / 800);
    final t = clock.value * 2 * math.pi;
    // Ripples remain attached to the illustrated pond while the camera moves.
    c.save();
    c.clipPath(Path()..addOval(const Rect.fromLTWH(345, 565, 680, 155)));
    for (int i = 0; i < 12; i++) {
      final x = 380.0 + (i * 113) % 610;
      final y = 580.0 + (i * 43) % 130;
      final p = Paint()
        ..color = Colors.white.withValues(
          alpha: (night ? .09 : .24) * (.6 + .4 * math.sin(t * 3 + i)),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 30 + 12 * math.sin(t * 2 + i),
          height: 5,
        ),
        p,
      );
    }
    c.restore();
    // Golden tree and cottage lanterns keep a soft glow at night.
    for (int i = 0; i < 24; i++) {
      final x = 1770.0 + math.sin(i * 2.4) * 150;
      final y = 170.0 + (i * 37) % 230;
      final a = .14 + .36 * (.5 + .5 * math.sin(t * 2 + i));
      c.drawCircle(
        Offset(x, y),
        2.2,
        Paint()..color = const Color(0xFFFFE9A5).withValues(alpha: a),
      );
    }
    if (night) {
      for (final p in [
        const Offset(1395, 260),
        const Offset(1294, 323),
        const Offset(1570, 434),
      ]) {
        c.drawCircle(
          p,
          22,
          Paint()
            ..color = const Color(0xFFFFDA8F).withValues(alpha: .23)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
      }
      c.drawCircle(
        const Offset(1090, 65),
        23,
        Paint()..color = const Color(0xFFFAF4D6).withValues(alpha: .7),
      );
    }
    // Sparse glass bubbles: highlights, not a layer that hides the garden.
    for (int i = 0; i < 7; i++) {
      final x = 550.0 + i * 206 + math.sin(t + i) * 18;
      final y = 620.0 - ((clock.value * 250 + i * 61) % 370);
      final r = 5.0 + i % 3 * 3;
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = Colors.white.withValues(alpha: .34),
      );
      c.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: r * .72),
        3.5,
        1.1,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..color = Colors.white.withValues(alpha: .6),
      );
    }
    for (int i = 0; i < 12; i++) {
      final x = (i * 213.0 + math.sin(t + i) * 35) % 2400;
      final y = (clock.value * 800 + i * 79) % 800;
      c.save();
      c.translate(x, y);
      c.rotate(t + i);
      c.drawOval(
        const Rect.fromLTWH(-4, -2.5, 8, 5),
        Paint()
          ..color = Color(
            i.isEven ? 0xFFDDA65F : 0xFFE6C476,
          ).withValues(alpha: .58),
      );
      c.restore();
    }
    // Tiny pale-yellow butterflies hover above the open lawn.
    for (int i = 0; i < 4; i++) {
      final x = 850.0 + i * 195 + math.sin(t + i) * 22;
      final y = 400.0 + i % 2 * 125 + math.cos(t * 2 + i) * 14;
      final wing = 3 + math.sin(t * 14 + i).abs() * 5;
      final p = Paint()
        ..color = const Color(0xFFFFE8A3).withValues(alpha: night ? .25 : .85);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x - wing * .5, y),
          width: wing,
          height: 10,
        ),
        p,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + wing * .5, y),
          width: wing,
          height: 10,
        ),
        p,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant StorybookAtmosphere old) =>
      old.night != night || old.clock != clock;
}
