import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/meditation_course_store.dart';
import 'package:flutter_app/services/meditation_library_store.dart';

Map<String, dynamic> backup(Map<String, Object> values) => {
  'schema': 1,
  'createdAt': '2026-10-16T12:00:00Z',
  'boxes': <String, dynamic>{},
  'settings': {
    for (final entry in values.entries)
      entry.key: {
        'type': entry.value is List ? 'strings' : 'string',
        'value': entry.value,
      },
  },
};

Map<String, Object> checkIn(String session, {String feeling = 'better'}) => {
  'session': session,
  'guide': 'forestRest',
  'feeling': feeling,
  'at': '2026-10-16T09:12:13.123',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('meditation-backup-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'store-produced favorites check-ins and course progress round-trip',
    () async {
      final library = MeditationLibraryStore();
      await library.toggleFavorite('forestRest');
      await library.toggleFavorite('sleepMeditation');
      await library.played('forestRest');
      await library.checkIn('backup-session', 'forestRest', 'same');
      final course = MeditationCourseStore();
      await course.activate('first7');
      await course.begin('forestRest');
      await course.complete('forestRest', now: DateTime(2026, 10, 16));

      final data = await BackupService.snapshot();
      BackupService.validate(data);
      expect(
        (data['settings'] as Map).keys,
        containsAll([
          'meditation.favorites',
          'meditation.recent',
          'meditation.checkins',
          'meditation.courses',
        ]),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await BackupService.restore(data);
      final restored = MeditationLibraryStore();
      final restoredCourse = MeditationCourseStore();
      await restored.load();
      await restoredCourse.load();
      expect(restored.favorites, {'forestRest', 'sleepMeditation'});
      expect(restored.recent, ['forestRest']);
      expect(restored.checkIns, library.checkIns);
      expect(restoredCourse.active, 'first7');
      expect(restoredCourse.progress, {'first7': 1});
      expect(restoredCourse.lastDays, {'first7': '2026-10-16'});
    },
  );

  test(
    'additive restore preserves current sessions courses and recent ordering',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('meditation.favorites', ['forestRest']);
      await prefs.setStringList('meditation.recent', ['forestRest']);
      await prefs.setString(
        'meditation.checkins',
        jsonEncode([checkIn('same-id', feeling: 'worse')]),
      );
      await prefs.setString(
        'meditation.courses',
        jsonEncode({
          'active': 'first7',
          'progress': {'first7': 2},
          'days': {'first7': '2026-10-16'},
        }),
      );
      await prefs.setString('companion_name', '현재 이름');
      final imported = backup({
        'meditation.favorites': ['forestRest', 'sleepMeditation'],
        'meditation.recent': ['sleepMeditation', 'forestRest'],
        'meditation.checkins': jsonEncode([
          checkIn('same-id'),
          checkIn('new-id'),
        ]),
        'meditation.courses': jsonEncode({
          'active': 'bedtime3',
          'progress': {'first7': 5, 'bedtime3': 1},
          'days': {'first7': '2026-10-10', 'bedtime3': '2026-10-10'},
        }),
        'companion_name': '백업 이름',
      });
      expect(await BackupService.hasLocalRecords(), isTrue);
      await BackupService.restore(imported);
      await BackupService.restore(
        imported,
      ); // Retry remains additive/idempotent.
      final library = MeditationLibraryStore();
      final course = MeditationCourseStore();
      await library.load();
      await course.load();
      expect(library.favorites, {'forestRest', 'sleepMeditation'});
      expect(library.recent, ['forestRest', 'sleepMeditation']);
      expect(library.checkIns.map((row) => row['session']), [
        'same-id',
        'new-id',
      ]);
      expect(library.checkIns.first['feeling'], 'worse');
      expect(course.active, 'first7');
      expect(course.progress, {'first7': 2, 'bedtime3': 1});
      expect(course.lastDays, {
        'first7': '2026-10-16',
        'bedtime3': '2026-10-10',
      });
      expect(prefs.getString('companion_name'), '현재 이름');
    },
  );

  test(
    'malformed meditation payloads reject the entire restore before any write',
    () async {
      final invalid = <Map<String, Object>>[
        {
          'meditation.favorites': ['forestRest', 'unknownGuide'],
        },
        {
          'meditation.recent': ['forestRest', 'forestRest'],
        },
        {'meditation.checkins': '['},
        {
          'meditation.checkins': jsonEncode(
            List.generate(91, (i) => checkIn('$i')),
          ),
        },
        {
          'meditation.checkins': jsonEncode([
            checkIn('duplicate'),
            checkIn('duplicate'),
          ]),
        },
        {
          'meditation.checkins': jsonEncode([
            {...checkIn('bad-date'), 'at': '2026-02-30T12:00:00'},
          ]),
        },
        {
          'meditation.checkins': jsonEncode([
            {...checkIn('bad-time'), 'at': '2026-10-16T25:00:00'},
          ]),
        },
        {
          'meditation.checkins': jsonEncode([
            {...checkIn('bad-field'), 'premium': true},
          ]),
        },
        {
          'meditation.checkins': jsonEncode([
            checkIn('bad-feeling', feeling: 'diagnosed'),
          ]),
        },
        {'meditation.checkins': ' ' * 50001},
        {
          'meditation.courses': jsonEncode({
            'active': 'paid-course',
            'progress': {},
            'days': {},
          }),
        },
        {
          'meditation.courses': jsonEncode({
            'active': null,
            'progress': {'first7': 8},
            'days': {},
          }),
        },
        {
          'meditation.courses': jsonEncode({
            'active': null,
            'progress': {'first7': 1.5},
            'days': {},
          }),
        },
        {
          'meditation.courses': jsonEncode({
            'active': null,
            'progress': {'first7': 1},
            'days': {'first7': '2026-02-30'},
          }),
        },
        {
          'meditation.courses': jsonEncode({
            'active': null,
            'progress': {},
            'days': {},
            'premium': true,
          }),
        },
      ];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('companion_name', '유지');
      for (final values in invalid) {
        final data = backup({'companion_name': '바뀌면 안 됨', ...values});
        (data['boxes'] as Map)['drafts'] = [
          {'key': 'must-not-write', 'value': '검증 전 쓰기 금지'},
        ];
        await expectLater(BackupService.restore(data), throwsFormatException);
        expect(prefs.getString('companion_name'), '유지');
        expect(await Hive.boxExists('restore_journal__enc'), isFalse);
        expect(await Hive.boxExists('drafts_local_user__enc'), isFalse);
      }
    },
  );

  test(
    'auth entitlement and permission preferences stay outside backup',
    () async {
      final forbidden = [
        'meditation.premium',
        'meditation.accessToken',
        'local_user_premium',
        'firebase_uid',
        'notification_permission',
      ];
      final prefs = await SharedPreferences.getInstance();
      for (final key in forbidden) {
        await prefs.setString(key, 'local-only');
      }
      await prefs.setStringList('meditation.favorites', ['forestRest']);
      final exported = await BackupService.snapshot();
      for (final key in forbidden) {
        expect(BackupService.allowedPref(key), isFalse);
        expect((exported['settings'] as Map).containsKey(key), isFalse);
        await expectLater(
          BackupService.restore(backup({key: 'imported'})),
          throwsFormatException,
        );
        expect(prefs.getString(key), 'local-only');
      }
    },
  );

  test(
    'bounded merge retains local check-ins and fills only remaining history slots',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'meditation.checkins',
        jsonEncode(List.generate(89, (i) => checkIn('local-$i'))),
      );
      await BackupService.restore(
        backup({
          'meditation.checkins': jsonEncode([
            checkIn('import-1'),
            checkIn('import-2'),
          ]),
        }),
      );
      final rows = jsonDecode(prefs.getString('meditation.checkins')!) as List;
      expect(rows.length, 90);
      expect(rows.first['session'], 'local-0');
      expect(rows[88]['session'], 'local-88');
      expect(rows.last['session'], 'import-1');
    },
  );

  test(
    'unreadable existing meditation values are preserved rather than overwritten',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('meditation.courses', true);
      await prefs.setString('meditation.checkins', 'broken local history');
      await BackupService.restore(
        backup({
          'meditation.courses': jsonEncode({
            'active': null,
            'progress': {},
            'days': {},
          }),
          'meditation.checkins': jsonEncode([checkIn('new')]),
        }),
      );
      expect(prefs.get('meditation.courses'), isTrue);
      expect(prefs.getString('meditation.checkins'), 'broken local history');
    },
  );
}
