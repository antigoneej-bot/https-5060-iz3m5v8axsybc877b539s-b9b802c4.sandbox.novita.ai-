import 'dart:math' as math;

/// A small visual routine, not a mood assessment or a reward-producing action.
enum CompanionBehavior { greeting, watching, curious, inviting, resting }

enum CompanionInteraction { eating, playing, petting, resting }

class CompanionBehaviorFrame {
  final CompanionBehavior behavior;
  final double headTilt, eyeClosure, breath;
  const CompanionBehaviorFrame(
    this.behavior,
    this.headTilt,
    this.eyeClosure,
    this.breath,
  );

  static const still = CompanionBehaviorFrame(
    CompanionBehavior.watching,
    0,
    0,
    1,
  );

  static CompanionBehaviorFrame reacting(
    CompanionInteraction action,
    double progress,
  ) {
    final t = progress.clamp(0.0, 1.0);
    final envelope = math.sin(t * math.pi);
    final wave = math.sin(t * math.pi * 4) * envelope;
    return CompanionBehaviorFrame(
      CompanionBehavior.watching,
      switch (action) {
        CompanionInteraction.playing => .05 * wave,
        CompanionInteraction.eating => .025 * wave,
        _ => .012 * wave,
      },
      action == CompanionInteraction.playing ? .12 * envelope : .9 * envelope,
      1,
    );
  }

  static double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _blink(double t, double start, double hold) =>
      _ease((t - start) / .22) * (1 - _ease((t - start - .22 - hold) / .3));

  static CompanionBehaviorFrame at(
    double seconds, {
    int bondStage = 0,
    bool night = false,
  }) {
    final t = seconds.clamp(0.0, double.infinity) % 72;
    final familiarity = bondStage.clamp(0, 3) / 3;
    var behavior = CompanionBehavior.watching;
    var tilt = 0.0;
    var closed = 0.0;
    if (t < 5) {
      behavior = CompanionBehavior.greeting;
      tilt = .025 * math.pow(math.sin(t / 5 * math.pi), 2);
      closed = _blink(t, 1.5, .55);
    } else if (t >= 15 && t < 20) {
      behavior = CompanionBehavior.curious;
      tilt =
          -(.024 + familiarity * .012) *
          math.pow(math.sin((t - 15) / 5 * math.pi), 2);
    } else if (t >= 32 && t < 38) {
      behavior = CompanionBehavior.inviting;
      tilt =
          (.027 + familiarity * .015) *
          math.pow(math.sin((t - 32) / 6 * math.pi), 2);
      closed = _blink(t, 35, .6);
    } else if (t >= 51 && t < (night ? 61 : 57)) {
      behavior = CompanionBehavior.resting;
      closed =
          _ease((t - 51) / 1.2) *
          (1 - _ease((t - (night ? 59.8 : 55.8)) / 1.2));
    }
    for (final start in [8.3, 23.6, 43.2, 65.4]) {
      closed = math.max(closed, _blink(t, start, .05));
    }
    return CompanionBehaviorFrame(
      behavior,
      tilt,
      closed,
      1 + .003 * math.sin(t * math.pi * 2 / 6),
    );
  }
}
