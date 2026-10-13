import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/hive_encryption.dart';
import '../lib/services/legacy_record_migration.dart';
import '../lib/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('legacy-scope-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<Box> source() => HiveEncryption.openBox('letter_entries_guest');
  Future<Box> target() => HiveEncryption.openBox('letter_entries_local_user');

  test(
    'unfinished migration merges absent keys without replacing current records or preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        'guest_care_temperature': 8,
        'local_user_care_temperature': 12,
        'guest_care_growth_days': 4,
      });
      final old = await source();
      await old.putAll({'same': 'old body', 'missing': 'older record'});
      final current = await target();
      await current.putAll({'same': 'edited body', 'new': 'local only'});
      await StorageService.migrateGuestScopeIfNeeded('local_user');
      expect(current.toMap(), {
        'same': 'edited body',
        'missing': 'older record',
        'new': 'local only',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('local_user_care_temperature'), 12);
      expect(prefs.getInt('local_user_care_growth_days'), 4);
      expect(
        prefs.getBool(LegacyRecordMigration.completionKey('local_user')),
        isTrue,
      );
      expect(old.length, 2);
      expect(
        current.isOpen,
        isTrue,
      ); // A live service's box must not be closed.
    },
  );

  test(
    'old done flag exposes missing records but only explicit recovery restores them',
    () async {
      SharedPreferences.setMockInitialValues({
        'guest_scope_migrated_v1_to_local_user': true,
      });
      final old = await source();
      await old.putAll({'same': 'old body', 'missing': 'possibly deleted'});
      final current = await target();
      await current.put('same', 'edited body');
      await StorageService.migrateGuestScopeIfNeeded('local_user');
      expect(current.containsKey('missing'), isFalse);
      expect(await StorageService.getLegacyRecoverySummary(), {
        'letter_entries': 1,
      });
      expect(
        current.containsKey('missing'),
        isFalse,
      ); // Counting is not recovery.
      expect(await StorageService.restoreLegacyGuestData(), 1);
      expect(current.get('same'), 'edited body');
      expect(current.get('missing'), 'possibly deleted');
      expect(await StorageService.getLegacyRecoverySummary(), isEmpty);
      expect(await StorageService.restoreLegacyGuestData(), 0);
      expect(old.length, 2);
      await current.close();
      expect(
        (await target()).get('missing'),
        'possibly deleted',
      ); // Persisted after reopening.
    },
  );

  test(
    'completed v2 migration never resurrects a later deletion automatically',
    () async {
      await (await source()).put('removed', 'old record');
      await StorageService.migrateGuestScopeIfNeeded('local_user');
      final current = await target();
      await current.delete('removed');
      await current.flush();
      await StorageService.migrateGuestScopeIfNeeded('local_user');
      expect(current.containsKey('removed'), isFalse);
      expect(await StorageService.getLegacyRecoverySummary(), {
        'letter_entries': 1,
      });
    },
  );

  test(
    'recovery summary counts each private store without exposing bodies or creating targets',
    () async {
      await (await source()).put('letter', 'private text');
      final promises = await HiveEncryption.openBox('promise_entries_guest');
      await promises.put('promise', 'private promise');
      final summary = await StorageService.getLegacyRecoverySummary();
      expect(summary, {'letter_entries': 1, 'promise_entries': 1});
      expect(await Hive.boxExists('letter_entries_local_user__enc'), isFalse);
      expect(await Hive.boxExists('promise_entries_local_user__enc'), isFalse);
      expect(await StorageService.restoreLegacyGuestData(), 2);
      expect(await StorageService.getLegacyRecoverySummary(), isEmpty);
    },
  );
}
