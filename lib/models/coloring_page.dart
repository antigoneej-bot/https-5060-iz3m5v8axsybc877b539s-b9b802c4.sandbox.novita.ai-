import 'package:flutter/material.dart';

const coloringTitles = ['꽃밭의 고양이', '달빛 정원', '사과와 낮잠'];

/// The same closed paths drive painting and hit testing; topmost region wins.
List<Path> coloringRegions(int design) {
  Path oval(double x, double y, double w, double h) =>
      Path()..addOval(Rect.fromLTWH(x, y, w, h));
  Path leaf(double x, double y) => Path()
    ..moveTo(x, y)
    ..quadraticBezierTo(x - 50, y - 80, x + 5, y - 65)
    ..quadraticBezierTo(x + 55, y - 40, x, y)
    ..close();
  return [
    Path()..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 8, 384, 384),
        const Radius.circular(28),
      ),
    ),
    oval(20, 275, 360, 105),
    design == 1 ? oval(285, 35, 65, 65) : oval(35, 40, 65, 65),
    leaf(65, 275),
    leaf(335, 275),
    oval(260, 240, 85, 65),
    oval(125, 195, 150, 135),
    Path()
      ..moveTo(122, 150)
      ..lineTo(120, 75)
      ..lineTo(175, 111)
      ..quadraticBezierTo(200, 97, 225, 111)
      ..lineTo(280, 75)
      ..lineTo(278, 150)
      ..quadraticBezierTo(300, 225, 200, 232)
      ..quadraticBezierTo(100, 225, 122, 150)
      ..close(),
    oval(120, 290, 70, 38),
    oval(210, 290, 70, 38),
    design == 2 ? oval(60, 225, 62, 58) : oval(45, 225, 55, 55),
    design == 1 ? oval(302, 140, 40, 40) : oval(300, 240, 55, 55),
  ];
}

class ColoringPainter extends CustomPainter {
  final List<int?> colors;
  final int design;
  ColoringPainter(this.colors, this.design);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 400);
    final paths = coloringRegions(design),
        line = Paint()
          ..color = const Color(0xFF706573)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(
        paths[i],
        Paint()..color = colors[i] == null ? Colors.white : Color(colors[i]!),
      );
      canvas.drawPath(paths[i], line);
    }
    // A gentle smile and whiskers remain visible above every fill.
    canvas.drawArc(
      const Rect.fromLTWH(150, 150, 28, 22),
      3.14,
      3.14,
      false,
      line,
    );
    canvas.drawArc(
      const Rect.fromLTWH(222, 150, 28, 22),
      3.14,
      3.14,
      false,
      line,
    );
    canvas.drawOval(
      const Rect.fromLTWH(194, 176, 12, 8),
      Paint()..color = const Color(0xFFB37C85),
    );
    canvas.drawPath(
      Path()
        ..moveTo(200, 184)
        ..quadraticBezierTo(185, 204, 178, 187)
        ..moveTo(200, 184)
        ..quadraticBezierTo(215, 204, 222, 187),
      line,
    );
    for (final y in [178.0, 189.0]) {
      canvas.drawLine(Offset(128, y), Offset(157, y + 2), line);
      canvas.drawLine(Offset(243, y + 2), Offset(272, y), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ColoringPainter old) =>
      old.colors != colors || old.design != design;
}
