import 'meditation_course_store.dart';
import 'package:flutter/foundation.dart';
import '../mongi/integration/mongi_garden_store.dart';

/// Both players use the same persisted once-per-day care reward.
class MeditationCompletionService {
  static final instance = MeditationCompletionService();
  final Set<DateTime> _pending = {};
  Future<void> _tail = Future.value();
  final completed = ValueNotifier<({String session, String key})?>(null);
  int _sequence = 0;
  Future<void> begin(String guideKey) async {
    if (completed.value?.key == guideKey) completed.value = null;
    try {
      await MeditationCourseStore.instance.begin(guideKey);
    } catch (_) {}
  }

  Future<void> complete({String? guideKey}) async {
    if (guideKey != null)
      completed.value = (
        session: '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
        key: guideKey,
      );
    if (guideKey != null) {
      try {
        await MeditationCourseStore.instance.complete(guideKey);
      } catch (_) {}
    }
    final now = DateTime.now();
    _pending.add(DateTime(now.year, now.month, now.day));
    return retry();
  }

  Future<void> retry() {
    final result = _tail.then((_) async {
      try {
        await MeditationCourseStore.instance.retry();
      } catch (_) {}
      for (final day in _pending.toList()) {
        try {
          await MongiGardenStore.instance.claimCompletedCare(
            now: day,
            meditation: true,
          );
          _pending.remove(day);
        } catch (_) {
          /* Retry on the next playback interaction. */
        }
      }
    });
    _tail = result.catchError((Object _) {});
    return result;
  }
}
