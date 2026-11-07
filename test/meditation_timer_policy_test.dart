import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/meditation_timer_policy.dart';

/// Regression guard: the sleep timer must keep offering all six original
/// durations. A 1.0.15+18 refactor silently narrowed this to [15, 30, 60];
/// this test fails loudly if that regression is reintroduced.
void main() {
  test('policy exposes all six original durations in order', () {
    expect(MeditationTimerPolicy.minutes, [3, 5, 10, 15, 30, 60]);
  });

  test('allows() accepts null (timer off) and every listed duration', () {
    expect(MeditationTimerPolicy.allows(null), isTrue);
    for (final m in MeditationTimerPolicy.minutes) {
      expect(MeditationTimerPolicy.allows(m), isTrue, reason: '$m분 허용되어야 함');
    }
  });

  test('allows() rejects durations outside the policy', () {
    for (final m in [0, 1, 2, 4, 7, 20, 45, 90, -5]) {
      expect(MeditationTimerPolicy.allows(m), isFalse, reason: '$m분은 거부되어야 함');
    }
  });

  test('fadeFactor clamps to [0,1] over the final 10 seconds', () {
    expect(
      MeditationTimerPolicy.fadeFactor(const Duration(seconds: 20)),
      1.0,
    );
    expect(
      MeditationTimerPolicy.fadeFactor(const Duration(seconds: 5)),
      .5,
    );
    expect(MeditationTimerPolicy.fadeFactor(Duration.zero), 0.0);
    expect(
      MeditationTimerPolicy.fadeFactor(const Duration(seconds: -5)),
      0.0,
    );
  });
}
