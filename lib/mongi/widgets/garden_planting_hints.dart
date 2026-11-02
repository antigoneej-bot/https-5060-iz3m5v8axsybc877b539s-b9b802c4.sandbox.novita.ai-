import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// World-space hints share the camera transform with plants and terrain.
/// The caller filters every point through the durable placement validator.
class GardenPlantingHints extends CustomPainter {
  final List<Offset> points;
  final Offset? selected;
  final bool validSelection, night;
  const GardenPlantingHints({
    required this.points,
    required this.selected,
    required this.validSelection,
    required this.night,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 2400, size.height / 800);
    final stroke = Paint()
      ..color = night ? const Color(0xD0B9EEDB) : const Color(0xD035836D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final point in points) {
      final center = Offset(point.dx * 2400, point.dy * 800);
      final rect = Rect.fromCenter(center: center, width: 78, height: 28);
      canvas.drawOval(rect, Paint()..color = const Color(0x25C5F0DC));
      for (var dash = 0; dash < 12; dash++) {
        canvas.drawArc(rect, dash * math.pi / 6, math.pi / 10, false, stroke);
      }
    }
    if (selected != null) {
      final center = Offset(selected!.dx * 2400, selected!.dy * 800);
      final rect = Rect.fromCenter(center: center, width: 86, height: 30);
      if (validSelection) {
        canvas.drawOval(rect, Paint()..color = const Color(0xBBA88B65));
      }
      canvas.drawOval(
        rect,
        Paint()
          ..color = validSelection
              ? const Color(0xFFE5FFF0)
              : const Color(0xFFDDA89A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      if (!validSelection) {
        final cross = Paint()
          ..color = const Color(0xFFDDA89A)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          center + const Offset(-6, -6),
          center + const Offset(6, 6),
          cross,
        );
        canvas.drawLine(
          center + const Offset(6, -6),
          center + const Offset(-6, 6),
          cross,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GardenPlantingHints old) =>
      !listEquals(old.points, points) ||
      old.selected != selected ||
      old.validSelection != validSelection ||
      old.night != night;
}
