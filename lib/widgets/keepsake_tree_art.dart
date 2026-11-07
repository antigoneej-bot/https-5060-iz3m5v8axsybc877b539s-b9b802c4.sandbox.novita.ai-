import '../l10n/app_language.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/keepsake_tree.dart';

class KeepsakeTreeArt extends StatefulWidget {
  final KeepsakeKind kind;
  final KeepsakeMetal metal;
  final int stage;
  final bool animate;
  const KeepsakeTreeArt({
    super.key,
    required this.kind,
    required this.metal,
    required this.stage,
    this.animate = true,
  });
  @override
  State<KeepsakeTreeArt> createState() => _KeepsakeTreeArtState();
}

class _KeepsakeTreeArtState extends State<KeepsakeTreeArt>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController air = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  bool active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void sync() {
    if (widget.animate &&
        active &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!air.isAnimating) air.repeat();
    } else {
      air.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(KeepsakeTreeArt old) {
    super.didUpdateWidget(old);
    sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    air.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        '${widget.metal.label} ${widget.kind.label} ${[tr("씨앗"), tr("새싹"), tr("어린 나무"), tr("빛나는 나무"), tr("보석나무")][widget.stage.clamp(0, 4)]}',
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: air,
        builder: (ctx, _) => CustomPaint(
          painter: KeepsakeTreePainter(
            widget.kind,
            widget.metal,
            widget.stage,
            air.value,
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class KeepsakeTreePainter extends CustomPainter {
  final KeepsakeKind kind;
  final KeepsakeMetal metal;
  final int stage;
  final double phase;
  KeepsakeTreePainter(this.kind, this.metal, this.stage, this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 400, size.height / 400);
    canvas.save();
    canvas.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 400 * scale) / 2,
    );
    canvas.scale(scale);
    final base = Color(metal.color),
        bright = metal == KeepsakeMetal.silver
            ? const Color(0xFFFAFDFF)
            : const Color(0xFFFFF3CF),
        deep = metal == KeepsakeMetal.silver
            ? const Color(0xFF687C96)
            : metal == KeepsakeMetal.rose
            ? const Color(0xFFAA617A)
            : const Color(0xFF99702B);
    final p = Paint();
    canvas.drawCircle(
      const Offset(200, 180),
      155,
      p
        ..shader = RadialGradient(
          colors: [base.withValues(alpha: .24), base.withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(45, 25, 310, 310)),
    );
    p.shader = null;
    canvas.drawOval(
      const Rect.fromLTWH(72, 337, 256, 34),
      p..color = base.withValues(alpha: .16),
    );
    canvas.drawOval(
      const Rect.fromLTWH(93, 334, 214, 22),
      p..color = const Color(0xFFEAE0D2),
    );
    canvas.drawOval(
      const Rect.fromLTWH(85, 329, 230, 30),
      Paint()
        ..color = base.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    void jewel(
      Offset at,
      double width,
      double height,
      double angle, {
      bool heart = false,
    }) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      final path = heart
          ? (Path()
              ..moveTo(0, height * .5)
              ..cubicTo(
                -width,
                -height * .05,
                -width * .45,
                -height,
                0,
                -height * .27,
              )
              ..cubicTo(
                width * .45,
                -height,
                width,
                -height * .05,
                0,
                height * .5,
              )
              ..close())
          : (Path()
              ..moveTo(0, -height * .5)
              ..cubicTo(
                width * .65,
                -height * .2,
                width * .6,
                height * .2,
                0,
                height * .5,
              )
              ..cubicTo(
                -width * .6,
                height * .2,
                -width * .65,
                -height * .2,
                0,
                -height * .5,
              )
              ..close());
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: width * 1.4,
        height: height * 1.5,
      );
      canvas.drawShadow(path, deep.withValues(alpha: .23), 3, false);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bright, base, deep, bright],
            stops: const [0, .48, .78, 1],
          ).createShader(rect),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = bright.withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      canvas.drawLine(
        Offset(0, -height * .32),
        Offset(0, height * .33),
        Paint()
          ..color = bright.withValues(alpha: .65)
          ..strokeWidth = .8,
      );
      canvas.restore();
    }

    if (stage == 0) {
      canvas.save();
      canvas.translate(200, 298 + math.sin(phase * math.pi * 2) * 3);
      canvas.rotate(-.24);
      jewel(Offset.zero, 43, 69, 0);
      canvas.restore();
      canvas.drawOval(
        const Rect.fromLTWH(155, 329, 90, 11),
        p..color = deep.withValues(alpha: .1),
      );
    } else {
      canvas.save();
      canvas.translate(200, 340);
      canvas.rotate(math.sin(phase * math.pi * 2) * .012);
      canvas.translate(-200, -340);
      final height = <double>[0, 90, 165, 230, 260][stage.clamp(0, 4)],
          top = 340 - height;
      final trunk = Path()
        ..moveTo(190, 342)
        ..cubicTo(197, 300, 190, top + 40, 202, top)
        ..cubicTo(199, top + 70, 209, 300, 211, 342)
        ..close();
      canvas.drawPath(
        trunk,
        Paint()
          ..shader = LinearGradient(
            colors: [deep, bright, base, deep],
          ).createShader(const Rect.fromLTWH(188, 70, 26, 275)),
      );
      if (stage == 1) {
        jewel(const Offset(182, 275), 23, 45, -.95);
        jewel(const Offset(221, 259), 23, 48, .9);
        jewel(const Offset(200, 242), 13, 27, 0);
      } else {
        final rows = stage == 2
            ? 3
            : stage == 3
            ? 4
            : 5;
        for (var row = 0; row < rows; row++) {
          final y = top + 25 + row * (height - 65) / rows;
          final span = (45 + row * 16) * (stage == 2 ? .72 : 1.0);
          for (final side in [-1.0, 1.0]) {
            final end = Offset(200 + side * span, y - 15);
            final branch = Path()
              ..moveTo(201, y + 42)
              ..quadraticBezierTo(
                200 + side * span * .4,
                y + 20,
                end.dx,
                end.dy,
              );
            canvas.drawPath(
              branch,
              Paint()
                ..shader = LinearGradient(colors: [deep, base, bright])
                    .createShader(
                      Rect.fromPoints(Offset(190, y - 20), Offset(310, y + 50)),
                    )
                ..style = PaintingStyle.stroke
                ..strokeWidth = (stage == 4 ? 4 : 3)
                ..strokeCap = StrokeCap.round,
            );
            for (var leaf = 0; leaf < 4; leaf++) {
              final t = (leaf + 1) / 4;
              final at = Offset(200 + side * span * t, y + 35 - t * 47);
              jewel(
                at,
                stage == 2 ? 13 : 18,
                stage == 2 ? 27 : 38,
                side * (.55 + leaf * .13),
                heart: kind == KeepsakeKind.love && leaf % 2 == 0,
              );
              if (leaf > 0)
                jewel(Offset(at.dx - side * 7, at.dy + 19), 12, 26, side * 2.0);
            }
            if (stage == 4) {
              jewel(
                Offset(end.dx, end.dy - 8),
                16,
                27,
                side * .4,
                heart: kind == KeepsakeKind.love,
              );
            }
          }
        }
        jewel(Offset(201, top - 1), 20, 37, 0);
        if (stage == 4) {
          for (var i = 0; i < 7; i++) {
            final x = 110 + i * 30.0, y = 150 + (i % 3) * 37.0;
            canvas.drawCircle(
              Offset(x, y),
              4,
              Paint()
                ..shader = RadialGradient(colors: [Colors.white, bright, base])
                    .createShader(
                      Rect.fromCircle(center: Offset(x, y), radius: 5),
                    ),
            );
          }
        }
      }
      canvas.restore();
    }
    for (var i = 0; i < 14; i++) {
      final x = 47 + (i * 71 % 307).toDouble(),
          y = 45 + (i * 47 % 270).toDouble(),
          r = (i % 3 + 1) * 1.2;
      final alpha = .25 + .55 * (.5 + .5 * math.sin(phase * math.pi * 2 + i));
      final shine = Paint()
        ..color = Color.lerp(base, Colors.white, .5)!.withValues(alpha: alpha)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x - r, y), Offset(x + r, y), shine);
      canvas.drawLine(Offset(x, y - r), Offset(x, y + r), shine);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(KeepsakeTreePainter old) =>
      old.phase != phase ||
      old.stage != stage ||
      old.metal != metal ||
      old.kind != kind;
}
