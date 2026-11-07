import 'dart:io';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/session_transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final store = MongiGardenStore.instance;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('greeting80-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
    SessionTransaction.fault = null;
    await store.reload();
  });
  tearDown(() async {
    SessionTransaction.fault = null;
    await Hive.close();
    await directory.delete(recursive: true);
    CatCareService.clearCurrentUser();
  });
  test(
    'existing79 attendance receipt preserves today growth and temperature',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final today = MongiGardenData.dayKey(DateTime.now());
      await prefs.setInt('local_user_care_growth_days', 7);
      await prefs.setInt('local_user_care_temperature', 8);
      await prefs.setString('local_user_care_last_date', today);
      await prefs.setString('local_user_care_attendance_counted_date', today);
      for (final count in [false, true, true]) {
        final state = await CatCareService.loadAndApplyDailyDecay(
          defaultCompanionCatId: 'ginger',
          isPremium: false,
          countAttendance: count,
        );
        expect(state.growthDays, 7);
        expect(state.temperature, 8);
        expect(
          prefs.getString('local_user_care_attendance_counted_date'),
          today,
        );
      }
    },
  );
  test(
    'queued attendance stays with its original account after switching',
    () async {
      CatCareService.setCurrentUser('account_a');
      final pending = List.generate(
        3,
        (_) => CatCareService.loadAndApplyDailyDecay(
          defaultCompanionCatId: 'ginger',
          isPremium: false,
          countAttendance: true,
        ),
      );
      CatCareService.setCurrentUser('account_b');
      final results = await Future.wait(pending);
      expect(results.map((r) => r.growthDays), everyElement(1));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('account_a_care_growth_days'), 1);
      expect(prefs.getInt('account_b_care_growth_days'), isNull);
      final b = await CatCareService.loadAndApplyDailyDecay(
        defaultCompanionCatId: 'ginger',
        isPremium: false,
        countAttendance: false,
      );
      expect(b.growthDays, 0);
    },
  );
  test(
    'opening does not count attendance; repeated greeting counts once',
    () async {
      CatCareService.setCurrentUser('local_user');
      Future<dynamic> load(bool attendance) =>
          CatCareService.loadAndApplyDailyDecay(
            defaultCompanionCatId: 'ginger',
            isPremium: false,
            countAttendance: attendance,
          );
      expect((await load(false)).growthDays, 0);
      expect((await load(true)).growthDays, 1);
      expect((await load(true)).growthDays, 1);
      expect((await load(false)).growthDays, 1);
    },
  );
  test(
    'rapid taps award once; reopening preserves receipt; next day awards once',
    () async {
      final today = DateTime(2026, 11, 3);
      final results = await Future.wait(
        List.generate(8, (_) => store.greetCompanion(now: today)),
      );
      expect(results.where((r) => r['fresh'] == true).length, 1);
      final first = results.first;
      expect(store.value.essence, first['light']);
      expect(
        store.value.walkStock['churu_tuna'] ?? 0,
        first['kind'] == 'churu' ? 1 : 0,
      );
      final balance = store.value.essence;
      await store.reload();
      expect((await store.greetCompanion(now: today))['fresh'], false);
      expect(store.value.essence, balance);
      final tomorrow = await store.greetCompanion(now: DateTime(2026, 11, 4));
      expect(tomorrow['fresh'], true);
      expect(store.value.essence, balance + (tomorrow['light'] as int));
    },
  );
  test(
    'failure after durable journal replays award without a second bonus',
    () async {
      final today = DateTime(2026, 11, 3);
      SessionTransaction.fault = (point) async {
        if (point == 'journal_flushed') throw StateError('interruption');
      };
      await expectLater(store.greetCompanion(now: today), throwsStateError);
      SessionTransaction.fault = null;
      final retry = await store.greetCompanion(now: today);
      expect(retry['fresh'], false);
      expect(store.value.essence, retry['light']);
      expect(store.value.claimedGiftReceipts, contains('greeting_2026-11-03'));
    },
  );
  test(
    'backup receipt blocks a second award even without session journal history',
    () async {
      final today = DateTime(2026, 11, 3);
      await store.greetCompanion(now: today);
      final balance = store.value.essence;
      final box = await HiveEncryption.openBox(SessionTransaction.boxName);
      await box.delete(SessionTransaction.receiptsKey);
      expect((await store.greetCompanion(now: today))['fresh'], false);
      expect(store.value.essence, balance);
    },
  );
}
