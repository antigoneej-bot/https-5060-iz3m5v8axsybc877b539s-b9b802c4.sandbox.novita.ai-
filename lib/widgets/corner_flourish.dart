import 'package:flutter/material.dart';
import '../theme.dart';

class CornerFlourish extends StatelessWidget {
  final Alignment alignment;
  const CornerFlourish({super.key, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment.y < 0 ? 8 : null,
      bottom: alignment.y > 0 ? 8 : null,
      left: alignment.x < 0 ? 8 : null,
      right: alignment.x > 0 ? 8 : null,
      child: Transform.scale(
        scaleX: alignment.x > 0 ? -1.0 : 1.0,
        scaleY: alignment.y > 0 ? -1.0 : 1.0,
        child: CustomPaint(
          size: const Size(20, 20),
          painter: _FlourishPainter(),
        ),
      ),
    );
  }
}

class _FlourishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(0, 0, size.width * 0.5, 0)
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(0, size.height * 0.25, size.width * 0.35, 0);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      const Offset(2, 2),
      1.4,
      Paint()..color = AppColors.gold.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
