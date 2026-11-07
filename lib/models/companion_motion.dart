import 'dart:math' as math;

/// Sprite poses carry no state and never modify growth or care history.
class CompanionMotionPose {
  final int frame, nextFrame;
  final double mix;
  final double tailSwing;
  final bool mirror;
  const CompanionMotionPose(
    this.frame, {
    int? nextFrame,
    this.mix = 0,
    this.tailSwing = 0,
    this.mirror = false,
  }) : nextFrame = nextFrame ?? frame;
  bool get walking => frame >= 6;
  static const still = CompanionMotionPose(0);
  static CompanionMotionPose walk(int step, {bool faceLeft = false}) =>
      CompanionMotionPose(
        const [6, 7, 8, 8, 9, 10, 11, 11][step % 8],
        mirror: faceLeft,
      );
  static CompanionMotionPose idle(
    double seconds, {
    double eyeClosure = 0,
    bool smile = false,
    bool resting = false,
    bool animate = true,
  }) {
    if (!animate) return resting ? const CompanionMotionPose(2) : still;
    final swing = math.sin(seconds * math.pi * 2 / 4.8);
    if (smile) return CompanionMotionPose(3, tailSwing: swing);
    if (resting || eyeClosure >= .65)
      return CompanionMotionPose(2, tailSwing: resting ? 0 : swing);
    if (eyeClosure >= .18) return CompanionMotionPose(1, tailSwing: swing);
    // Deform the tail of one complete sprite continuously, without crossfading
    // between opposite tails or creating two translucent tails in mid-swing.
    return CompanionMotionPose(0, tailSwing: swing);
  }

  static CompanionMotionPose preview(double seconds) {
    final t = seconds % 12;
    var closed = 0.0;
    for (final at in [2.0, 7.5]) {
      closed = math.max(closed, (1 - (t - at).abs() / .22).clamp(0.0, 1.0));
    }
    return idle(t, eyeClosure: closed, smile: t >= 9 && t < 10.2);
  }
}
