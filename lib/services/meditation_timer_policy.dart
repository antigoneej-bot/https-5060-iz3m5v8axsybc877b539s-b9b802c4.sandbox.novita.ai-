/// Optional stop times; a recording's duration and default playback are unchanged.
class MeditationTimerPolicy {
  static const minutes = [3, 5, 10, 15, 30, 60];
  static bool allows(int? value) => value == null || minutes.contains(value);
  static double fadeFactor(Duration remaining) =>
      (remaining.inMilliseconds / 10000).clamp(0.0, 1.0);
}
