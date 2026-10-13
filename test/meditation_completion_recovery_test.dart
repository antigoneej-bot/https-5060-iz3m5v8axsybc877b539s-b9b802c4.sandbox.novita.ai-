import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/models/meditation_completion_record.dart';
import 'package:flutter_app/services/meditation_completion_journal.dart';
import 'package:flutter_app/services/meditation_completion_service.dart';
import 'package:flutter_app/services/meditation_course_store.dart';
import 'package:flutter_app/services/meditation_library_store.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/widgets/meditation_check_in.dart';
import 'support/private_storage_test_setup.dart';

void main() {
  usePrivateStorageForTests('meditation-recovery-');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    await (await HiveEncryption.openBox(
      MeditationCompletionJournal.boxName,
    )).clear();
    await MeditationCourseStore.instance.reload();
    await MongiGardenStore.instance.reload();
  });

  test(
    'persisted completion survives recreation and replay grants only once',
    () async {
      final courses = MeditationCourseStore.instance;
      await courses.activate('first7');
      await courses.begin('forestRest');
      final at = DateTime(2026, 10, 14, 12);
      final event = courses.captureCompletion(
        'forestRest',
        id: 'crash-before-apply',
        now: at,
        reward: true,
      )!;
      await MeditationCompletionJournal.instance.save(event);
      // Simulate losing all armed in-memory course state before the two writes.
      await courses.reload();
      final service = MeditationCompletionService();
      await service.retry();
      expect(courses.progress['first7'], 1);
      expect(MongiGardenStore.instance.value.seedTokens, 1);
      expect(await MeditationCompletionJournal.instance.load(), isEmpty);
      // Simulate the journal deletion failing after successful course/reward writes.
      await MeditationCompletionJournal.instance.save(event);
      await MeditationCompletionService().retry();
      expect(courses.progress['first7'], 1);
      expect(MongiGardenStore.instance.value.seedTokens, 1);
      expect(await MeditationCompletionJournal.instance.load(), isEmpty);
    },
  );

  test('journal retains actual completion day across a later retry', () async {
    final event = MeditationCompletionRecord(
      id: 'yesterday',
      completedAt: DateTime(2026, 10, 13, 23, 59),
      guide: 'forestRest',
      reward: true,
    );
    await MeditationCompletionJournal.instance.save(event);
    await MeditationCompletionService().retry();
    expect(
      MongiGardenStore.instance.value.meditationDays,
      contains('2026-10-13'),
    );
  });

  test(
    'duplicate feedback returns the persisted feeling rather than new input',
    () async {
      final store = MeditationLibraryStore();
      final first = await store.checkIn(
        'already-saved',
        'forestRest',
        'better',
      );
      final retry = await store.checkIn('already-saved', 'forestRest', 'worse');
      expect(first.feeling, 'better');
      expect(retry.feeling, 'better');
      expect((await store.findCheckIn('already-saved'))!.feeling, 'better');
    },
  );

  testWidgets(
    'recreated feedback widget shows saved choice and does not offer a duplicate',
    (tester) async {
      await tester.runAsync(
        () => MeditationLibraryStore.instance.checkIn(
          'reentry',
          'forestRest',
          'same',
        ),
      );
      MeditationCompletionService.instance.completed.value = (
        session: 'reentry',
        key: 'forestRest',
      );
      Widget app() => const MaterialApp(
        home: Scaffold(body: MeditationCheckIn(guideKey: 'forestRest')),
      );
      for (var i = 0; i < 2; i++) {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        // The session check-in reload performs real (encrypted) Hive I/O,
        // which can take longer than a single fixed delay under load. Poll
        // until the saved choice actually renders instead of racing it.
        for (
          var attempt = 0;
          attempt < 50 &&
              find
                  .text('이 명상에 남긴 마음: 비슷해요')
                  .evaluate()
                  .isEmpty;
          attempt++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pumpAndSettle();
        }
        expect(find.text('이 명상에 남긴 마음: 비슷해요'), findsOneWidget);
        expect(find.byType(ActionChip), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
