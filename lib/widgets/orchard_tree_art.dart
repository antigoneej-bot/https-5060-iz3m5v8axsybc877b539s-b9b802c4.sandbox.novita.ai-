import '../l10n/app_language.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/orchard.dart';

class OrchardTreeArt extends StatefulWidget {
  final OrchardKind kind;
  final int stage, fruitCount;
  final bool ripe, grown;
  const OrchardTreeArt({
    super.key,
    required this.kind,
    this.stage = 4,
    this.fruitCount = 10,
    this.ripe = true,
    this.grown = false,
  });
  @override
  State<OrchardTreeArt> createState() => _OrchardTreeArtState();
}

class _OrchardTreeArtState extends State<OrchardTreeArt>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void sync() {
    if (foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context)) {
      if (!clock.isAnimating) clock.repeat();
    } else {
      clock.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (mounted) sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${widget.kind.name}, ${widget.stage < 3 ? tr("성장 중") : tr("열매 {0}개", [widget.fruitCount])}',
    child: AnimatedBuilder(
      animation: clock,
      builder: (_, __) => CustomPaint(
        painter: _TreePainter(
          widget.kind.id,
          widget.stage,
          widget.fruitCount,
          widget.ripe,
          widget.grown,
          math.sin(clock.value * math.pi * 2),
        ),
        size: const Size(300, 270),
      ),
    ),
  );
}

class _TreePainter extends CustomPainter {
  final String kind;
  final int stage, count;
  final bool ripe, grown;
  final double sway;
  _TreePainter(
    this.kind,
    this.stage,
    this.count,
    this.ripe,
    this.grown,
    this.sway,
  );
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 270);
    final ground = Paint()..color = const Color(0xffd6e9ca);
    canvas.drawOval(const Rect.fromLTWH(45, 228, 210, 24), ground);
    canvas.drawOval(
      const Rect.fromLTWH(90, 230, 125, 14),
      Paint()..color = const Color(0xffaacba1).withValues(alpha: .4),
    );
    canvas.translate(150, 235);
    canvas.rotate(sway * .018);
    final growth = grown ? 1.0 : [.36, .57, .82, 1.0, 1.0][stage.clamp(0, 4)];
    canvas.scale(growth);
    canvas.translate(-150, -235);
    final trunk = Path()
      ..moveTo(133, 238)
      ..quadraticBezierTo(148, 190, 135, 127)
      ..lineTo(162, 125)
      ..quadraticBezierTo(157, 188, 171, 238)
      ..close();
    canvas.drawPath(
      trunk,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffba8661), Color(0xffe6b98a)],
        ).createShader(const Rect.fromLTWH(130, 125, 45, 113)),
    );
    final branch = Paint()
      ..color = const Color(0xffbf906b)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(150, 178), const Offset(106, 137), branch);
    canvas.drawLine(const Offset(153, 160), const Offset(196, 115), branch);
    final leaves = [
      const Offset(89, 118),
      const Offset(113, 76),
      const Offset(161, 61),
      const Offset(205, 91),
      const Offset(216, 133),
      const Offset(164, 127),
      const Offset(124, 129),
    ];
    for (var i = 0; i < leaves.length; i++) {
      final p = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.5),
          colors: [
            const Color(0xffd5ed9f),
            i.isEven ? const Color(0xff80b68c) : const Color(0xff97c596),
          ],
        ).createShader(Rect.fromCircle(center: leaves[i], radius: 47));
      canvas.drawCircle(leaves[i], 43, p);
    }
    for (var i = 0; i < 14; i++) {
      final a = i * 2.399;
      final r = 18 + math.sqrt(i / 14) * 64;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(151 + math.cos(a) * r, 104 + math.sin(a) * r * .65),
          width: 12,
          height: 6,
        ),
        Paint()..color = const Color(0xfff5f8cd).withValues(alpha: .45),
      );
    }
    if (stage >= 2) {
      final n = stage == 2 ? 12 : count.clamp(10, 30);
      for (var i = 0; i < n; i++) {
        final a = i * 2.39996, r = math.sqrt((i + .5) / n) * 77;
        final point = Offset(
          151 + math.cos(a) * r,
          105 + math.sin(a) * r * .78,
        );
        canvas.save();
        canvas.translate(point.dx, point.dy);
        if (stage == 2) {
          for (var j = 0; j < 5; j++) {
            final a = j * math.pi * 2 / 5;
            canvas.drawCircle(
              Offset(math.cos(a) * 4, math.sin(a) * 4),
              3.5,
              Paint()..color = const Color(0xffffe5e8),
            );
          }
          canvas.drawCircle(
            Offset.zero,
            2,
            Paint()..color = const Color(0xffedcb78),
          );
        } else {
          canvas.scale(ripe ? 1 : .7);
          fruit(canvas, kind);
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  static void fruit(Canvas c, String kind) {
    final colors = {
      'apple': const Color(0xffed747e),
      'persimmon': const Color(0xfff5a25d),
      'tuna': const Color(0xff85c6e4),
      'chicken': const Color(0xfff4cd79),
      'kibble': const Color(0xffc9a2d5),
    };
    final p = Paint()..color = colors[kind]!;
    c.drawOval(
      const Rect.fromLTWH(-9, 6, 18, 5),
      Paint()..color = const Color(0xff426e53).withValues(alpha: .18),
    );
    if (kind == 'tuna') {
      c.drawOval(const Rect.fromLTWH(-10, -6, 17, 12), p);
      c.drawPath(
        Path()
          ..moveTo(5, 0)
          ..lineTo(13, -7)
          ..lineTo(13, 7)
          ..close(),
        p,
      );
      c.drawCircle(
        const Offset(-5, -1),
        1.4,
        Paint()..color = const Color(0xff476f88),
      );
    } else if (kind == 'chicken') {
      c.drawLine(
        const Offset(0, 0),
        const Offset(10, 8),
        Paint()
          ..color = const Color(0xfffff6df)
          ..strokeWidth = 5,
      );
      c.drawCircle(
        const Offset(10, 8),
        3,
        Paint()..color = const Color(0xfffff6df),
      );
      c.drawOval(const Rect.fromLTWH(-10, -9, 17, 17), p);
    } else if (kind == 'kibble') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -9, 18, 20),
          const Radius.circular(5),
        ),
        p,
      );
      c.drawOval(
        const Rect.fromLTWH(-4, 0, 8, 6),
        Paint()..color = const Color(0xfffff4df),
      );
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
          Offset(-4 + i * 4, -3),
          2,
          Paint()..color = const Color(0xfffff4df),
        );
      }
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -7, 18, 17),
          Radius.circular(kind == 'apple' ? 8 : 6),
        ),
        p,
      );
      c.drawLine(
        const Offset(0, -6),
        const Offset(1, -12),
        Paint()
          ..color = const Color(0xff8c7154)
          ..strokeWidth = 2,
      );
      c.drawOval(
        const Rect.fromLTWH(1, -12, 8, 4),
        Paint()..color = const Color(0xff6d9d65),
      );
    }
    c.drawCircle(
      const Offset(-4, -4),
      2,
      Paint()..color = Colors.white.withValues(alpha: .6),
    );
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.kind != kind ||
      old.stage != stage ||
      old.count != count ||
      old.ripe != ripe ||
      old.grown != grown ||
      old.sway != sway;
}
