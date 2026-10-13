import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ground footprint shared by every normalized GardenCatPose.
/// Pose artwork aligns its physical feet with the bottom of this canvas.
class GardenCatShadowPainter extends CustomPainter {
  final bool walking, faceLeft, night, onBench;
  final double lift;

  const GardenCatShadowPainter({
    required this.walking,
    required this.faceLeft,
    required this.night,
    required this.lift,
    this.onBench = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final unit = size.width;
    final baseline = size.height;
    final centerX = walking ? (faceLeft ? .51 : .49) : .49;
    final center = Offset(unit * centerX, baseline + lift - unit * .008);
    final heightAboveGround = (lift / unit).clamp(0.0, .35).toDouble();
    final softness = 1 + heightAboveGround * 3;
    final density = night ? 1.35 : 1.0;

    void ellipse(double width, double height, double blur, double opacity,
        {double dy = 0}) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, unit * dy),
          width: unit * width,
          height: unit * height,
        ),
        Paint()
          ..color = const Color(0xFF292B20).withValues(alpha: opacity * density)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, unit * blur),
      );
    }

    // drawOval gives a real elliptical footprint, unlike a radial gradient
    // whose radius is limited by the shortest side of a shallow container.
    if (!onBench) {
      ellipse((walking ? .62 : .48) * softness, .085 * softness,
          .024 * softness, .15 / softness);
    }
    // Contact is close and darker; it fades during a hop while the broad
    // footprint stays on the ground. No new motion is applied to the cat.
    final contact = (1 - heightAboveGround * 8).clamp(0.0, 1.0).toDouble();
    if (contact > 0) {
      ellipse(walking ? .54 : .34, .028, .009, .25 * contact, dy: -.003);
    }
  }

  @override
  bool shouldRepaint(covariant GardenCatShadowPainter oldDelegate) =>
      onBench != oldDelegate.onBench ||
      walking != oldDelegate.walking ||
      faceLeft != oldDelegate.faceLeft ||
      night != oldDelegate.night ||
      lift != oldDelegate.lift;
}
