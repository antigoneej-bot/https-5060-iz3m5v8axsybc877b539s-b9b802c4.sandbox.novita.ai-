import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'growth counts local active days, not taps, positive moods or absences',
    () {
      var journey = const CompanionJourney();
      for (var day = 1; day <= 7; day++) {
        for (final action in CompanionMoment.values) {
          journey = journey.record(action, DateTime(2026, 10, day, 23, 59));
        }
      }
      expect(journey.growthDays, 7);
      expect(journey.stage, 1);
      expect(journey.firstMoments[CompanionMoment.pet], '2026-10-01');
      journey = journey.record(CompanionMoment.pet, DateTime(2027, 1, 1));
      expect(journey.growthDays, 8);
      expect(journey.stage, 1);
      expect(
        journey.didToday(CompanionMoment.brush, DateTime(2027, 1, 1)),
        false,
      );
      expect(
        journey.didToday(CompanionMoment.pet, DateTime(2027, 1, 2)),
        false,
      );
    },
  );

  test('thresholds and baby preference preserve accumulated memories', () {
    var journey = const CompanionJourney();
    for (var i = 0; i < 90; i++) {
      journey = journey.record(
        CompanionMoment.rest,
        DateTime(2026, 1, 1).add(Duration(days: i)),
      );
      if ([7, 30, 90].contains(i + 1)) {
        expect(journey.stage, {7: 1, 30: 2, 90: 3}[i + 1]);
      }
    }
    expect(journey.daysToNext, null);
    expect(journey.visualScale, 1);
    final baby = CompanionJourney.decode(journey.withBaby(true).encode());
    expect(baby.stage, 3);
    expect(baby.visualScale, .82);
    expect(baby.growthDays, 90);
    expect(baby.firstMoments, journey.firstMoments);
    expect(baby.withBaby(false).visualScale, 1);
  });

  test(
    'parallel writes, reopen and owner isolation do not lose or duplicate a day',
    () async {
      await Future.wait([
        for (final action in CompanionMoment.values)
          CompanionJourneyStore.record(
            'local_user',
            action,
            now: DateTime(2026, 10, 25),
          ),
      ]);
      final reopened = await CompanionJourneyStore.load('local_user');
      expect(reopened.growthDays, 1);
      expect(reopened.firstMoments.length, CompanionMoment.values.length);
      expect((await CompanionJourneyStore.load('other')).growthDays, 0);
      await CompanionJourneyStore.setBaby('local_user', true);
      expect((await CompanionJourneyStore.load('local_user')).keepBaby, true);
    },
  );

  test('migration retains known days once without fabricating dates', () async {
    SharedPreferences.setMockInitialValues({
      'local_user_care_total_full_care_days': 14,
    });
    final first = await CompanionJourneyStore.load('local_user');
    expect(first.growthDays, 14);
    expect(first.firstMoments, isEmpty);
    await CompanionJourneyStore.record(
      'local_user',
      CompanionMoment.pet,
      now: DateTime(2026, 10, 25),
    );
    expect((await CompanionJourneyStore.load('local_user')).growthDays, 15);
  });

  test(
    'migration never counts the already completed current day twice',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'local_user_care_total_full_care_days': 7,
        'local_user_care_bonus_given_${companionDay(now)}': true,
      });
      await CompanionJourneyStore.load('local_user');
      await CompanionJourneyStore.record(
        'local_user',
        CompanionMoment.pet,
        now: now,
      );
      expect((await CompanionJourneyStore.load('local_user')).growthDays, 7);
    },
  );

  test(
    'opening an empty companion does not prevent restoring an old profile',
    () async {
      await CompanionJourneyStore.load('local_user');
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'local_user_companion_journey_v1',
        ),
        false,
      );
    },
  );

  test(
    'invalid saved data is preserved, not replaced with an empty cat',
    () async {
      SharedPreferences.setMockInitialValues({
        'local_user_companion_journey_v1': 'broken',
      });
      await expectLater(
        CompanionJourneyStore.record('local_user', CompanionMoment.pet),
        throwsFormatException,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'local_user_companion_journey_v1',
        ),
        'broken',
      );
      final raw = jsonDecode(const CompanionJourney().encode()) as Map;
      raw['careDays'] = ['2026-02-30'];
      expect(
        () => CompanionJourney.decode(jsonEncode(raw)),
        throwsFormatException,
      );
    },
  );

  test(
    'backup restores the journey and never overwrites a newer local journey',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'companion-backup-',
      );
      Hive.init(directory.path);
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async =>
                call.method == 'read' ? base64Encode(List.filled(32, 7)) : null,
          );
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      await CompanionJourneyStore.record(
        'local_user',
        CompanionMoment.pet,
        now: DateTime(2026, 10, 25),
      );
      final backup = await BackupService.snapshot();
      BackupService.validate(backup);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await BackupService.restore(backup);
      expect((await CompanionJourneyStore.load('local_user')).growthDays, 1);
      await CompanionJourneyStore.record(
        'local_user',
        CompanionMoment.brush,
        now: DateTime(2026, 10, 26),
      );
      await BackupService.restore(backup);
      expect((await CompanionJourneyStore.load('local_user')).growthDays, 2);
    },
  );
}
