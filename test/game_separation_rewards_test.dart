import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/models/garden_decoration.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = MongiGardenStore.instance;
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Directory directory;
  late GardenProvider garden;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('garden-without-game-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    final secrets = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          if (call.method == 'read') return secrets[args['key']];
          if (call.method == 'write') secrets[args['key']] = args['value'];
          return null;
        });
    SubscriptionService.debugIsPremiumOverride = false;
    garden = GardenProvider();
  });

  tearDown(() async {
    garden.dispose();
    SubscriptionService.debugIsPremiumOverride = null;
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, null);
  });

  test(
    'meditation alone earns seeds, grows trees and obtains decorations',
    () async {
      await garden.ensureInitialized();
      for (var day = 1; day <= 3; day++) {
        await store.claimCompletedCare(
          now: DateTime(2026, 10, day),
          meditation: true,
        );
        await store.claimCompletedCare(
          now: DateTime(2026, 10, day),
          meditation: true,
        );
      }
      expect(store.value.stage, 1);
      expect(garden.score, 0);
      expect(store.value.seedTokens, 3);
      expect(store.value.essence, 60);
      expect(store.value.careLeaves, 3);
      expect(store.value.careTreeTier, 2);

      final bench = GardenDecoration.byId('bench');
      expect(garden.isDecorationUnlocked(bench), isFalse);
      await garden.obtainDecoration(bench);
      expect(store.value.essence, 0);
      expect(garden.isDecorationUnlocked(bench), isTrue);
      expect(garden.equippedDecorationIds, contains('bench'));
      await store.plant('pine', now: DateTime(2026, 10, 3));
      await store.waterPlant('pine', now: DateTime(2026, 10, 3));
      await store.waterPlant('pine', now: DateTime(2026, 10, 3));
      expect(store.value.seeds['pine'], 2);
      expect(store.value.seedTokens, 2);
      expect(store.value.essence, 0);
      expect(store.value.stage, 1);
      expect(store.value.meditationDays.length, 3);
    },
  );

  test(
    'record and meditation keep one daily reward and separate growth receipts',
    () async {
      final day = DateTime(2026, 10, 1);
      final recorded = MongiGardenData().claimRecordDay(day);
      SharedPreferences.setMockInitialValues({
        MongiGardenStore.storageKey: jsonEncode(recorded.toJson()),
      });
      await garden.ensureInitialized();
      await store.claimCompletedCare(now: day, meditation: true);
      expect(store.value.seedTokens, 1);
      expect(store.value.essence, 20);
      expect(store.value.recordDays, {'2026-10-01'});
      expect(store.value.meditationDays, {'2026-10-01'});
      expect(store.value.careLeaves, 2);
      final before = store.value.toJson();
      await expectLater(
        garden.obtainDecoration(GardenDecoration.byId('bench')),
        throwsStateError,
      );
      expect(store.value.toJson(), before);
    },
  );

  test('concurrent acquisition charges one item only once', () async {
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(
        MongiGardenData(essence: 100).toJson(),
      ),
    });
    await garden.ensureInitialized();
    final bench = GardenDecoration.byId('bench');
    await Future.wait([
      garden.obtainDecoration(bench),
      garden.obtainDecoration(bench),
    ]);
    await garden.obtainDecoration(bench);
    expect(store.value.essence, 40);
    expect(store.value.owned, {'bench'});
    expect(store.value.placed, {'bench'});
  });

  test(
    'legacy unlocked decoration remains available without spending',
    () async {
      final box = await HiveEncryption.openBox('mongi_progress_local_user');
      await box.putAll({'streak_days': 3, 'has_bloomed_once': true});
      await garden.ensureInitialized();
      for (final id in ['bench', 'path']) {
        final item = GardenDecoration.byId(id);
        expect(garden.isDecorationUnlocked(item), isTrue);
        await garden.obtainDecoration(item);
      }
      expect(store.value.essence, 0);
      expect(store.value.owned, {'bench', 'path'});
      expect(store.value.placed, {'bench', 'path'});
    },
  );

  test('premium decoration still requires paid entitlement', () async {
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(
        MongiGardenData(essence: 120).toJson(),
      ),
    });
    await garden.ensureInitialized();
    final lantern = GardenDecoration.byId('lantern');
    expect(garden.isDecorationUnlocked(lantern), isFalse);
    await expectLater(garden.obtainDecoration(lantern), throwsStateError);
    expect(store.value.essence, 120);
    expect(store.value.owned, isEmpty);

    SubscriptionService.debugIsPremiumOverride = true;
    await garden.obtainDecoration(lantern);
    SubscriptionService.debugIsPremiumOverride = false;
    await garden.refreshSubscription();
    expect(store.value.essence, 120);
    expect(garden.isDecorationUnlocked(lantern), isTrue);
    await garden.toggleDecorationEquipped(lantern);
    expect(store.value.owned, contains('lantern'));
    expect(store.value.placed, isEmpty);
  });

  test('legacy paid decoration pack retains access', () async {
    final box = await HiveEncryption.openBox('mongi_progress_local_user');
    await box.put('decoration_pack_unlocked', true);
    await garden.ensureInitialized();
    await garden.obtainDecoration(GardenDecoration.byId('lantern'));
    expect(store.value.owned, contains('lantern'));
    expect(store.value.essence, 0);
  });

  test(
    'existing earned assets, dates and receipts survive initialization and backup',
    () async {
      final saved = MongiGardenData(
        stage: 9,
        essence: 123,
        seedTokens: 7,
        seeds: {'pine': 8},
        plantedOn: {'pine': '2026-09-01'},
        wateredOn: {'pine': '2026-09-08'},
        owned: {'bench', 'lantern'},
        placed: {'bench'},
        recordDays: {'2026-09-02'},
        careDays: {'2026-09-02', '2026-09-03'},
        meditationDays: {'2026-09-03'},
        claimedGiftReceipts: {'received-gift'},
      );
      SharedPreferences.setMockInitialValues({
        MongiGardenStore.storageKey: jsonEncode(saved.toJson()),
      });
      await garden.ensureInitialized();
      expect(store.value.toJson(), saved.toJson());
      final backup = await BackupService.snapshot();
      BackupService.validate(backup);
      final raw =
          backup['settings'][MongiGardenStore.storageKey]['value'] as String;
      expect(jsonDecode(raw), saved.toJson());
      expect(store.value.careLeaves, saved.careLeaves);
    },
  );
}
