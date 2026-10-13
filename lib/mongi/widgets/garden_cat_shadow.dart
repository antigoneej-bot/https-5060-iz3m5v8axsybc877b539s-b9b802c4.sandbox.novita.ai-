import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ground footprint shared by every normalized GardenCatPose.
/// Pose artwork aligns its physical feet with the bottom of this canvas.
class GardenCatShadowPainter extends CustomPainter {
  final bool walking, faceLeft, night, onBench;
  final bool facingDepth;
  final int frame;
  final double lift;

  const GardenCatShadowPainter({
    required this.walking,
    required this.faceLeft,
    required this.night,
    required this.lift,
    this.onBench = false,
    this.frame = 0,
    this.facingDepth = false,
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
      ellipse((walking ? (facingDepth ? .35 : .66) : .48) * softness, .085 * softness,
          .024 * softness, .15 / softness);
    }
    // Contact is close and darker; it fades during a hop while the broad
    // footprint stays on the ground. No new motion is applied to the cat.
    final contact = (1 - heightAboveGround * 8).clamp(0.0, 1.0).toDouble();
    if (contact > 0) {
      ellipse(walking ? (facingDepth ? .26 : .51) : .34, .025, .011, .18 * contact, dy: -.003);
      if (walking && !onBench) {
        // Grounded paws take weight in alternate phases. The broad shadow
        // remains fixed; only these close contact patches shift with the step.
        final phase = frame % 8;
        final spread = facingDepth ? .095 : .22;
        final shift = (phase < 4 ? .018 : -.018) * (faceLeft ? -1 : 1);
        for (final x in [-spread + shift, spread - shift]) {
          canvas.drawOval(Rect.fromCenter(
            center: center + Offset(unit * x, -unit * .007),
            width: unit * (facingDepth ? .09 : .13), height: unit * .025),
            Paint()..color = const Color(0xFF222B20).withValues(alpha: .30 * contact)
              ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, unit * .007));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GardenCatShadowPainter oldDelegate) =>
      frame != oldDelegate.frame || facingDepth != oldDelegate.facingDepth ||
      onBench != oldDelegate.onBench ||
      walking != oldDelegate.walking ||
      faceLeft != oldDelegate.faceLeft ||
      night != oldDelegate.night ||
      lift != oldDelegate.lift;
}
