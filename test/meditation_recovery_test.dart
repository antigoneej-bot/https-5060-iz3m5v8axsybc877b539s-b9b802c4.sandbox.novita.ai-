import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Installed platform-interface fake is used only for disk fault injection.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_app/services/meditation_checkin_store.dart';
import 'package:flutter_app/services/meditation_library_store.dart';
import 'package:flutter_app/services/meditation_course_store.dart';
import 'package:flutter_app/services/meditation_completion_service.dart';
import 'package:flutter_app/services/meditation_completion_journal.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'support/encrypted_meditation_storage.dart';

class FailingPreferences extends InMemorySharedPreferencesStore {
  FailingPreferences() : super.empty();
  bool failSave = false, failRemove = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      failSave ? false : super.setValue(type, key, value);
  @override
  Future<bool> remove(String key) async =>
      failRemove ? false : super.remove(key);
}

void main() {
  useEncryptedMeditationStorage();
  test(
    'new check-ins are encrypted on disk and absent from preferences',
    () async {
      final store = MeditationLibraryStore();
      await store.checkIn('unique-private-session', 'forestRest', 'worse');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(MeditationCheckInStore.key), isFalse);
      final box = Hive.box('${MeditationCheckInStore.boxName}__enc');
      await box.flush();
      final bytes = await File(box.path!).readAsBytes();
      expect(latin1.decode(bytes), isNot(contains('unique-private-session')));
      await box.close();
      final reloaded = MeditationLibraryStore();
      await reloaded.load();
      expect(reloaded.checkIns.single['feeling'], 'worse');
    },
  );
  test(
    'failed plaintext removal keeps both sources and retries without duplicates',
    () async {
      final disk = FailingPreferences();
      SharedPreferencesStorePlatform.instance = disk;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        MeditationCheckInStore.key,
        jsonEncode([
          {
            'session': 'old',
            'guide': 'forestRest',
            'feeling': 'same',
            'at': '2026-10-24T09:00:00',
          },
        ]),
      );
      disk.failRemove = true;
      await expectLater(MeditationCheckInStore.read(), throwsStateError);
      expect(prefs.containsKey(MeditationCheckInStore.key), isTrue);
      disk.failRemove = false;
      final rows = jsonDecode((await MeditationCheckInStore.read())!) as List;
      expect(rows, hasLength(1));
      expect(prefs.containsKey(MeditationCheckInStore.key), isFalse);
    },
  );
  test(
    'course disk failure recovers once after closing all boxes and recreating store',
    () async {
      final disk = FailingPreferences();
      SharedPreferencesStorePlatform.instance = disk;
      final course = MeditationCourseStore();
      await course.activate('first7');
      await course.begin('forestRest');
      disk.failSave = true;
      await expectLater(course.complete('forestRest'), throwsStateError);
      expect(Hive.box('${MeditationCompletionJournal.boxName}__enc').length, 1);
      await Hive.close();
      disk.failSave = false;
      await (await SharedPreferences.getInstance()).reload();
      final restarted = MeditationCourseStore();
      await restarted.retry();
      await restarted.retry();
      expect(restarted.progress['first7'], 1);
      expect(
        Hive.box('${MeditationCompletionJournal.boxName}__enc').isEmpty,
        isTrue,
      );
    },
  );
  test(
    'course and reward recover after reward committed but acknowledgement failed',
    () async {
      final course = MeditationCourseStore();
      await course.activate('first7');
      final garden = MongiGardenStore.instance;
      await garden.reload();
      final before = garden.value.seedTokens;
      final service = MeditationCompletionService(
        courses: course,
        claimReward: (day) async {
          await garden.claimCompletedCare(now: day, meditation: true);
          throw StateError('after-persist-before-ack');
        },
      );
      await service.begin('forestRest');
      await service.complete(guideKey: 'forestRest');
      expect(service.saveProblem.value, isNotNull);
      expect(course.progress['first7'], 1);
      expect(garden.value.seedTokens, before + 1);
      await Hive.close();
      final restartedCourse = MeditationCourseStore();
      final restarted = MeditationCompletionService(courses: restartedCourse);
      await restarted.retry();
      await restarted.retry();
      expect(restarted.saveProblem.value, isNull);
      expect(restartedCourse.progress['first7'], 1);
      expect(garden.value.seedTokens, before + 1);
    },
  );
}
