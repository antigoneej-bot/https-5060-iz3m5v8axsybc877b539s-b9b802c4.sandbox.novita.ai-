import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/garden_layout_store.dart';
import 'package:flutter_app/mongi/integration/session_transaction.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final store = MongiGardenStore.instance, layouts = GardenLayoutStore.instance;
  final old = MongiGardenData(
    seedTokens: 2,
    seeds: const {'pine': 4},
    wateredOn: const {'pine': '2026-10-30'},
    careRemainders: const {'pine': 1},
    owned: const {'bench'},
    placed: const {'bench'},
  );
  const point = Offset(.82, .77);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('plant-atomic-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(old.toJson()),
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async =>
              call.method == 'read' ? base64Encode(List.filled(32, 37)) : null,
        );
    SessionTransaction.fault = null;
    await store.reload();
    await layouts.update(
      (_) => GardenLayout(
        spaces: 3,
        positions: const {
          'seed:pine': Offset(.15, .72),
          'decor:bench': Offset(.51, .8),
        },
      ),
    );
  });
  tearDown(() async {
    SessionTransaction.fault = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<void> verifySaved() async {
    await SessionTransaction.initialize();
    await store.reload();
    await layouts.reload();
    expect(store.value.seedTokens, 1);
    expect(store.value.seeds, {'pine': 4, 'cherry': 1});
    expect(store.value.wateredOn['pine'], '2026-10-30');
    expect(store.value.careRemainders['pine'], 1);
    expect(store.value.placed, {'bench'});
    expect(layouts.value.positions['seed:pine'], const Offset(.15, .72));
    expect(layouts.value.positions['decor:bench'], const Offset(.51, .8));
    expect(layouts.value.positions['seed:cherry'], point);
    expect(layouts.value.spaces, 3);
  }

  test(
    'planting and coordinates survive reload and concurrent retry only charges once',
    () async {
      await Future.wait([
        store.plantAt('cherry', point),
        store.plantAt('cherry', point),
      ]);
      await Hive.close();
      await verifySaved();
    },
  );
  for (final stage in [
    'before_journal',
    'journal_flushed',
    'hive_flushed',
    'layout_written',
    'garden_written',
    'commit_finished',
  ]) {
    test(
      'failure at $stage recovers final values without double seed charge',
      () async {
        var failed = false;
        SessionTransaction.fault = (at) async {
          if (!failed && at == stage) {
            failed = true;
            throw FileSystemException('injected write failure');
          }
        };
        await expectLater(
          store.plantAt('cherry', point),
          throwsA(isA<FileSystemException>()),
        );
        SessionTransaction.fault = null;
        await Hive.close();
        await SessionTransaction.initialize();
        await store.reload();
        await layouts.reload();
        if (stage == 'before_journal') {
          expect(store.value.seedTokens, 2);
          expect(store.value.seeds.containsKey('cherry'), isFalse);
          expect(layouts.value.positions.containsKey('seed:cherry'), isFalse);
        } else {
          await verifySaved();
        }
        await store.plantAt('cherry', point);
        await verifySaved();
      },
    );
  }
  test(
    'invalid, locked, occupied locations and existing species preserve data',
    () async {
      await layouts.update(
        (_) => GardenLayout(positions: const {'seed:pine': Offset(.5, .7)}),
      );
      for (final p in [
        const Offset(.1, .7),
        const Offset(.5, .1),
        const Offset(.5, .7),
      ]) {
        await expectLater(store.plantAt('cherry', p), throwsStateError);
      }
      await expectLater(
        store.plantAt('pine', const Offset(.6, .8)),
        throwsStateError,
      );
      await store.reload();
      expect(store.value.toJson(), old.toJson());
    },
  );
}
