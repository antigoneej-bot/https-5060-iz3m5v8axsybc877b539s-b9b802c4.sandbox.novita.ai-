import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Decorative motion never changes saved positions or intercepts garden taps.
class GardenSway extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double>? pulse;
  final Widget child;
  final bool cat;
  final double phase;
  const GardenSway({
    super.key,
    required this.animation,
    required this.child,
    this.pulse,
    this.cat = false,
    this.phase = 0,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([animation, if (pulse != null) pulse!]),
    child: child,
    builder: (context, child) {
      final t = animation.value * math.pi * 2;
      return Transform.translate(
        offset: Offset(0, cat ? math.sin(t * 6) * 2 : 0),
        child: Transform.rotate(
          angle: math.sin(t * (cat ? 5 : 3) + phase) * (cat ? .024 : .025),
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scaleY: cat
                ? 1 + math.sin(t * 6) * .018
                : 1 + math.sin((pulse?.value ?? 0) * math.pi) * .07,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );
    },
  );
}

/// Seamless 24-second ambient cycle. Clouds, light, leaves and water are painted
/// together, avoiding dozens of animation controllers and layout passes.
class GardenAtmosphere extends CustomPainter {
  final double phase;
  final Animation<double>? animation;
  final Animation<double>? daylight;
  final bool night, panoramic;
  GardenAtmosphere(this.phase, this.night, {this.panoramic = true})
    : animation = null,
      daylight = null;
  GardenAtmosphere.animated(
    Animation<double> clock,
    this.night, {
    this.panoramic = true,
    this.daylight,
  }) : animation = clock,
       phase = 0,
       super(
         repaint: Listenable.merge([clock, if (daylight != null) daylight]),
       );
  @override
  void paint(Canvas canvas, Size size) {
    final t = animation == null ? phase : animation!.value * math.pi * 2;
    // A common normalized canvas keeps effects anchored while zooming/panning.
    canvas.save();
    canvas.scale(size.width / (panoramic ? 2400 : 600), size.height / 800);
    final w = panoramic ? 2400.0 : 600.0;
    canvas.clipRect(Rect.fromLTWH(0, 0, w, 800));
    _clouds(canvas, w, t);
    _light(canvas, w, t);
    _moonlight(canvas, w, t);
    _passingDaylight(
      canvas,
      w,
      daylight == null ? t / (math.pi * 2) * 24 : daylight!.value * 10,
    );
    _water(canvas, t);
    _leaves(canvas, w, t);
    _sparkles(canvas, w, t);
    _visitors(canvas, w, t);
    canvas.restore();
  }

  void _clouds(Canvas c, double w, double t) {
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, w, panoramic ? 113 : 155));
    final gap = panoramic ? 470.0 : 270.0;
    for (var i = -1; i < (w / gap).ceil() + 2; i++) {
      final x = i * gap + t / (2 * math.pi) * gap;
      final y = 37 + math.sin(t * 2) * 9;
      for (var j = 0; j < 5; j++) {
        final r = 32.0 + (j % 3) * 9;
        final center = Offset(x + j * 30, y + math.sin(j * 1.8) * 12);
        c.drawOval(
          Rect.fromCenter(center: center, width: r * 2.6, height: r),
          Paint()
            ..color = (night ? const Color(0xFFB3BFDD) : Colors.white)
                .withValues(alpha: night ? .055 : .15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }
    }
    c.restore();
  }

  void _moonlight(Canvas c, double w, double t) {
    if (!night) return;
    final center = Offset(w * .73, 60);
    c.drawCircle(
      center,
      w * .42,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFCCDFFC).withValues(alpha: .10),
            const Color(0x00CCDFFC),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: w * .42)),
    );
    // Quiet pool of reflected moonlight; no flashing or extra clock.
    final pool = Rect.fromCenter(
      center: Offset(w * .52, 545),
      width: w * .45,
      height: 370,
    );
    c.drawOval(
      pool,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFFAFC9F0,
            ).withValues(alpha: .055 + .008 * math.sin(t)),
            const Color(0x00AFC9F0),
          ],
        ).createShader(pool),
    );
  }

  void _light(Canvas c, double w, double t) {
    if (night) return;
    final sun = Offset(w * .76, -35);
    final pulse = .20 + .055 * math.sin(t * 3);
    c.drawCircle(
      sun,
      w * .65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFEDAC).withValues(alpha: pulse),
            const Color(0xFFFFF8D6).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: w * .65)),
    );
  }

  /// Six seconds of soft diagonal sunshine, followed by four quiet seconds.
  void _passingDaylight(Canvas c, double w, double seconds) {
    if (night) return;
    final p = (seconds % 10) / 6;
    if (p >= 1) return;
    final opacity = math.pow(math.sin(p * math.pi), 2).toDouble();
    c.save();
    // Parallel rays from the upper right, spanning sky to garden floor.
    c.transform(
      Float64List.fromList([
        1,
        0,
        0,
        0,
        -.65,
        1,
        0,
        0,
        0,
        0,
        1,
        0,
        (p - .5) * 80,
        0,
        0,
        1,
      ]),
    );
    for (var i = 0; i < 4; i++) {
      final x = w * (.35 + i * .22);
      final width = w * (i.isEven ? .105 : .075);
      final rect = Rect.fromLTWH(x - width / 2, -30, width, 860);
      c.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFF3CF).withValues(alpha: 0),
              const Color(0xFFFFF3CF).withValues(alpha: .12 * opacity),
              const Color(0xFFFFFBEA).withValues(alpha: .30 * opacity),
              const Color(0xFFFFF3CF).withValues(alpha: .12 * opacity),
              const Color(0xFFFFF3CF).withValues(alpha: 0),
            ],
            stops: const [0, .25, .5, .75, 1],
          ).createShader(rect),
      );
    }
    c.restore();
  }

  void _water(Canvas c, double t) {
    c.save();
    if (panoramic) {
      c.clipPath(
        Path()
          ..moveTo(236, 222)
          ..lineTo(302, 222)
          ..lineTo(333, 278)
          ..lineTo(466, 322)
          ..lineTo(390, 351)
          ..lineTo(284, 296)
          ..close(),
      );
    } else {
      c.translate(58, 260);
      c.scale(.45, .8);
      c.translate(-233, -222);
      c.clipRect(const Rect.fromLTWH(233, 222, 233, 130));
    }
    for (var i = 0; i < 26; i++) {
      final q = (t / (2 * math.pi) * 16 + i / 26) % 1;
      final x = 247 + q * 188 + math.sin(i * 8.1) * 22;
      final y = 222 + q * 113;
      c.drawLine(
        Offset(x, y),
        Offset(x + 12 + q * 9, y + 3),
        Paint()
          ..color = Colors.white.withValues(
            alpha: math.sin(q * math.pi) * (night ? .3 : .7),
          )
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
    c.restore();
  }

  void _leaves(Canvas c, double w, double t) {
    final count = panoramic ? 30 : 12;
    for (var i = 0; i < count; i++) {
      final q = (t / (2 * math.pi) * 3 + i * .618034) % 1;
      final x = (i * 137.4 % w) + math.sin(q * math.pi * 2 + i) * 55;
      c.save();
      c.translate(x, q * 870 - 35);
      c.rotate(t * 4 + i);
      c.scale(.45 + .55 * (math.cos(t * 6 + i)).abs(), 1);
      final leaf = Path()
        ..moveTo(-6, 0)
        ..quadraticBezierTo(0, -8, 9, 0)
        ..quadraticBezierTo(0, 8, -6, 0);
      c.drawPath(
        leaf,
        Paint()
          ..color =
              [
                const Color(0xFFE6A84C),
                const Color(0xFFC87842),
                const Color(0xFFE8C77A),
              ][i % 3].withValues(
                alpha: math.sin(q * math.pi) * (night ? .4 : .85),
              ),
      );
      c.restore();
    }
  }

  void _visitors(Canvas c, double w, double t) {
    final count = night ? (panoramic ? 20 : 9) : (panoramic ? 9 : 4);
    for (var i = 0; i < count; i++) {
      final x =
          w * (.10 + (i * .381966 % .8)) +
          math.sin(t * 2 + i * 1.9) * (night ? 55 : 85);
      final y = 310 + i * 89 % 265 + math.sin(t * 3 + i) * (night ? 30 : 43);
      c.save();
      c.translate(x, y);
      if (night) {
        final a = .3 + .7 * math.pow((math.sin(t * 4 + i * 2.3) + 1) / 2, 2);
        final glow = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFD88D).withValues(alpha: a * .48),
              const Color(0xFFFFD88D).withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(-12, -12, 24, 24));
        c.drawCircle(Offset.zero, 12, glow);
        c.drawOval(
          const Rect.fromLTWH(-2, -3, 4, 6),
          Paint()..color = const Color(0xFF536444),
        );
        c.drawCircle(
          const Offset(0, 2),
          2.5,
          Paint()..color = const Color(0xFFFFE9B8).withValues(alpha: a),
        );
        final wing = Paint()
          ..color = const Color(0xFFDEEED3).withValues(alpha: .24);
        c.drawOval(const Rect.fromLTWH(-6, -3, 5, 3), wing);
        c.drawOval(const Rect.fromLTWH(1, -3, 5, 3), wing);
      } else {
        c.rotate(math.sin(t * 2 + i) * .3);
        final flutter = .38 + .62 * math.sin(t * 32 + i).abs();
        c.save();
        c.scale(flutter, 1);
        final wing = Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.3),
            colors: [Color(0xFFFFFCE8), Color(0xFFFFF1AD), Color(0xFFF0D982)],
            stops: [0, .72, 1],
          ).createShader(const Rect.fromLTWH(-17, -17, 34, 34));
        final veins = Paint()
          ..color = const Color(0x66C5AC5B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .55;
        for (final side in [-1.0, 1.0]) {
          c.save();
          c.scale(side, 1);
          final upper = Path()
            ..moveTo(1, 1)
            ..cubicTo(3, -9, 11, -18, 15, -15)
            ..cubicTo(20, -10, 14, 0, 7, 3)
            ..quadraticBezierTo(3, 5, 1, 1)
            ..close();
          final lower = Path()
            ..moveTo(1, 2)
            ..cubicTo(9, 0, 15, 4, 11, 10)
            ..cubicTo(8, 17, 2, 12, 1, 2)
            ..close();
          c.drawPath(upper, wing);
          c.drawPath(lower, wing);
          c.drawPath(
            Path()
              ..moveTo(2, 1)
              ..quadraticBezierTo(8, -5, 13, -12)
              ..moveTo(2, 3)
              ..quadraticBezierTo(6, 6, 8, 11),
            veins,
          );
          c.drawCircle(
            const Offset(11, -7),
            1.7,
            Paint()..color = const Color(0xAAFFFDE8),
          );
          c.restore();
        }
        c.restore();
        c.drawOval(
          const Rect.fromLTWH(-1.1, -6, 2.2, 15),
          Paint()..color = const Color(0xFF9D824B),
        );
        c.drawCircle(
          const Offset(0, -6),
          1.5,
          Paint()..color = const Color(0xFF8B7347),
        );
        c.drawPath(
          Path()
            ..moveTo(-.5, -7)
            ..quadraticBezierTo(-2, -12, -4, -11)
            ..moveTo(.5, -7)
            ..quadraticBezierTo(2, -12, 4, -11),
          Paint()
            ..color = const Color(0xFF9D824B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65,
        );
      }
      c.restore();
    }
  }

  void _sparkles(Canvas c, double w, double t) {
    for (
      var i = 0;
      i < (night ? (panoramic ? 24 : 12) : (panoramic ? 55 : 24));
      i++
    ) {
      final x = (i * .618034 % 1) * w + math.sin(t * 2 + i) * 9;
      final y = night && i.isEven ? 25 + i * 11 % 120 : 320 + i * 83 % 450;
      final a = math.pow((math.sin(t * 4 + i * 2.399) + 1) / 2, 5).toDouble();
      final p = Paint()
        ..color = (night ? const Color(0xFFFFDEA0) : const Color(0xFFFFF9D3))
            .withValues(alpha: a * .9);
      c.drawCircle(
        Offset(x, y.toDouble()),
        8,
        Paint()
          ..color = p.color.withValues(alpha: a * .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      c.drawCircle(Offset(x, y.toDouble()), 1.7, p);
      if (!night) {
        p.strokeWidth = 1;
        c.drawLine(
          Offset(x - 5 * a, y.toDouble()),
          Offset(x + 5 * a, y.toDouble()),
          p,
        );
        c.drawLine(Offset(x, y - 5 * a), Offset(x, y + 5 * a), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GardenAtmosphere old) =>
      old.phase != phase ||
      old.night != night ||
      old.panoramic != panoramic ||
      old.animation != animation;
}

/// Short, user-triggered watering feedback; it spends no seeds or growth points.
class GardenWaterDrops extends CustomPainter {
  final Animation<double> progress;
  GardenWaterDrops(this.progress) : super(repaint: progress);
  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final fade = math.sin(t * math.pi);
    final paint = Paint()
      ..color = const Color(0xFFB4ECFF).withValues(alpha: fade);
    for (var i = 0; i < 20; i++) {
      final p = (t * 3 + i / 20) % 1;
      final x = size.width * (.36 + (i % 5) * .075) + p * 9;
      final y = 12 + p * (size.height - 27);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 7),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10),
        width: 55 + t * 50,
        height: 10 + t * 10,
      ),
      paint..strokeWidth = 1.7,
    );
  }

  @override
  bool shouldRepaint(covariant GardenWaterDrops oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Irregular short blinks in the shared 24-second clock; no extra ticker.
double gardenBlinkOpacity(double seconds) {
  final t = seconds % 24;
  var opacity = 0.0;
  for (final center in [3.2, 7.9, 12.4, 12.85, 18.6, 23.0]) {
    opacity = math.max(
      opacity,
      ((.16 - (t - center).abs()) / .06).clamp(0.0, 1.0),
    );
  }
  return opacity;
}

class GardenCatArt extends StatelessWidget {
  final Animation<double> animation;
  final bool blinking;
  final bool resting;
  const GardenCatArt({
    super.key,
    required this.animation,
    this.blinking = true,
    this.resting = false,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/living_garden/cat_idle_front.webp',
          excludeFromSemantics: true,
        ),
        Opacity(
          opacity: resting
              ? 1
              : (blinking ? gardenBlinkOpacity(animation.value * 24) : 0),
          child: ClipPath(
            clipper: _CatEyes(),
            child: Image.asset(
              'assets/living_garden/cat_idle_front_blink.webp',
              excludeFromSemantics: true,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CatEyes extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromLTRB(
        size.width * .303,
        size.height * .320,
        size.width * .465,
        size.height * .438,
      ),
    )
    ..addOval(
      Rect.fromLTRB(
        size.width * .523,
        size.height * .320,
        size.width * .676,
        size.height * .438,
      ),
    );
  @override
  bool shouldReclip(covariant _CatEyes oldClipper) => false;
}
