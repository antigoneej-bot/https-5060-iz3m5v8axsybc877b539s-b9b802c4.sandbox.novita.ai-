import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/meditation_course_store.dart';
import 'package:flutter_app/data/solutions_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('courses only contain published media', () {
    for (final c in meditationCourses) {
      expect(c.guides.every(publishedMeditationKeys.contains), true);
    }
  });
  test(
    'completion only advances the armed step; missed days never reset',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = MeditationCourseStore();
      final c = meditationCourses.first;
      await s.activate(c.id);
      await s.begin('rainThunderRest');
      await s.complete('rainThunderRest', now: DateTime(2026, 9, 15));
      expect(s.step(c), 0);
      await s.begin(c.guides[0]);
      await s.complete(c.guides[0], now: DateTime(2026, 9, 15));
      expect(s.step(c), 1);
      await s.begin(c.guides[1]);
      await s.complete(c.guides[1], now: DateTime(2026, 9, 15));
      expect(s.step(c), 1);
      await s.begin(c.guides[1]);
      await s.complete(c.guides[1], now: DateTime(2026, 9, 21));
      expect(s.step(c), 2);
      final restored = MeditationCourseStore();
      await restored.load();
      expect(restored.step(c), 2);
      expect(restored.active, c.id);
    },
  );
  test('changing course discards an unfinished armed step', () async {
    SharedPreferences.setMockInitialValues({});
    final s = MeditationCourseStore();
    await s.activate('first7');
    await s.begin('forestRest');
    await s.activate('bedtime3');
    await s.complete('forestRest');
    expect(s.progress, isEmpty);
  });
}
