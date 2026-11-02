import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small, scalable garden objects. No new texture atlases or save format.
class GardenBasicItemArt extends StatelessWidget {
  const GardenBasicItemArt({super.key, required this.id, this.night = false});
  final String id;
  final bool night;
  static const ids = {
    'daisy_pot',
    'tulip_pot',
    'sunflower_pot',
    'cat_cushion',
    'moon_lamp',
    'bird_house',
  };
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ItemPainter(id, night), size: const Size(104, 104));
}

class _ItemPainter extends CustomPainter {
  const _ItemPainter(this.id, this.night);
  final String id;
  final bool night;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 104, size.height / 104);
    Paint color(int value) => Paint()..color = Color(value);
    final shadow = Paint()..color = const Color(0x353A503A);
    c.drawOval(const Rect.fromLTWH(17, 86, 70, 12), shadow);
    if (id.endsWith('_pot')) {
      final stalk = color(0xFF658B64)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(52, 76), const Offset(52, 31), stalk);
      c.drawOval(const Rect.fromLTWH(33, 51, 20, 10), color(0xFF8CA777));
      c.drawOval(const Rect.fromLTWH(52, 43, 20, 10), color(0xFF658B64));
      final pot = Path()
        ..moveTo(31, 66)
        ..lineTo(73, 66)
        ..lineTo(66, 92)
        ..lineTo(38, 92)
        ..close();
      c.drawPath(pot, color(0xFFC58D75));
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 62, 48, 9),
          const Radius.circular(3),
        ),
        color(0xFFE4AF8C),
      );
      if (id == 'tulip_pot') {
        c.drawPath(
          Path()
            ..moveTo(35, 22)
            ..lineTo(44, 29)
            ..lineTo(52, 18)
            ..lineTo(60, 29)
            ..lineTo(69, 22)
            ..quadraticBezierTo(69, 49, 52, 48)
            ..quadraticBezierTo(35, 48, 35, 22)
            ..close(),
          color(0xFFE3A0B5),
        );
      } else {
        for (var i = 0; i < 10; i++) {
          c.save();
          c.translate(52, 31);
          c.rotate(i * math.pi / 5);
          c.drawOval(
            const Rect.fromLTWH(-6, -24, 12, 22),
            color(id == 'daisy_pot' ? 0xFFFFF8DF : 0xFFECC765),
          );
          c.restore();
        }
        c.drawCircle(
          const Offset(52, 31),
          10,
          color(id == 'daisy_pot' ? 0xFFE4BF63 : 0xFF987153),
        );
      }
    } else if (id == 'cat_cushion') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(13, 55, 78, 36),
          const Radius.circular(18),
        ),
        color(0xFFC6B3DA),
      );
      c.drawOval(const Rect.fromLTWH(21, 58, 62, 23), color(0xFFE7DCEE));
      c.drawOval(const Rect.fromLTWH(45, 67, 14, 10), color(0xFFC6B3DA));
      for (final x in [40.0, 48.0, 56.0, 64.0]) {
        c.drawCircle(Offset(x, 63), 3, color(0xFFC6B3DA));
      }
    } else if (id == 'moon_lamp') {
      c.drawLine(
        const Offset(52, 55),
        const Offset(52, 90),
        color(0xFFAE9167)..strokeWidth = 5,
      );
      c.drawOval(const Rect.fromLTWH(32, 84, 40, 9), color(0xFFAE9167));
      if (night) c.drawCircle(const Offset(52, 34), 30, color(0x25FFE6A0));
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(const Rect.fromLTWH(28, 9, 48, 48)),
        Path()..addOval(const Rect.fromLTWH(43, 1, 43, 43)),
      );
      c.drawPath(moon, color(0xFFFFDF92));
    } else {
      c.drawLine(
        const Offset(52, 65),
        const Offset(52, 92),
        color(0xFFAF8D6D)..strokeWidth = 7,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, 34, 50, 42),
          const Radius.circular(4),
        ),
        color(0xFFE2BD8B),
      );
      c.drawPath(
        Path()
          ..moveTo(18, 38)
          ..lineTo(52, 12)
          ..lineTo(86, 38)
          ..close(),
        color(0xFF91A99C),
      );
      c.drawCircle(const Offset(52, 50), 10, color(0xFF806A53));
      c.drawLine(
        const Offset(43, 65),
        const Offset(61, 65),
        color(0xFFAF8D6D)..strokeWidth = 4,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _ItemPainter old) =>
      old.id != id || old.night != night;
}
