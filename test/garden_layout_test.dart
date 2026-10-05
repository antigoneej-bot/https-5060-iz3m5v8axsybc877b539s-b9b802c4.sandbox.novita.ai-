import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/integration/garden_layout_store.dart';
import 'package:flutter_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('spaces unlock at 3 and 8 plantings and never shrink', () {
    expect(GardenLayout().grow(2).spaces, 1);
    expect(GardenLayout().grow(3).spaces, 2);
    expect(GardenLayout().grow(8).spaces, 3);
    expect(GardenLayout(spaces: 3).grow(0).spaces, 3);
  });
  test('coordinates survive encoding without depending on viewport size', () {
    final layout = GardenLayout(
      spaces: 3,
    ).move('seed:love', const Offset(.15, .8), ['seed:love']);
    expect(
      GardenLayout.fromJson(
        jsonDecode(jsonEncode(layout.toJson())),
      ).position('seed:love'),
      const Offset(.15, .8),
    );
  });
  test('closed spaces, sky, unknown and unowned objects cannot be placed', () {
    final layout = GardenLayout();
    expect(
      () => layout.move('seed:love', const Offset(.1, .7), ['seed:love']),
      throwsStateError,
    );
    expect(
      () => layout.move('seed:love', const Offset(.5, .2), ['seed:love']),
      throwsStateError,
    );
    expect(
      () => layout.move('seed:love', const Offset(.5, .7), []),
      throwsStateError,
    );
    expect(
      () => layout.move('unknown', const Offset(.5, .7), ['unknown']),
      throwsStateError,
    );
  });
  test('all default catalog items fit and overlap is rejected', () {
    final layout = GardenLayout();
    for (final id in GardenLayout.itemIds) {
      expect(
        layout.placementError(id, layout.position(id), GardenLayout.itemIds),
        isNull,
      );
    }
    expect(
      () => layout.move('seed:love', layout.position('seed:pine'), [
        'seed:love',
        'seed:pine',
      ]),
      throwsStateError,
    );
  });
  test(
    'corrupt positions and nonfinite coordinates are not silently reset',
    () {
      for (final p in [
        [double.nan, .6],
        [.5, double.infinity],
        [1.2, .6],
        [.1, .6],
      ]) {
        expect(
          () => GardenLayout.fromJson({
            'version': 1,
            'spaces': 1,
            'positions': {'seed:love': p},
          }),
          throwsFormatException,
        );
      }
    },
  );
  test('garden layout is included and validated in backups', () {
    final backup = {
      'schema': 1,
      'createdAt': '2026-10-04T00:00:00Z',
      'settings': <String, dynamic>{},
      'boxes': {
        'garden_layout': [
          {'key': 'layout', 'value': GardenLayout(spaces: 3).toJson()},
        ],
      },
    };
    BackupService.validate(backup);
    final boxes = backup['boxes'] as Map;
    boxes['garden_layout'] = [
      {'key': 'wrong', 'value': GardenLayout().toJson()},
    ];
    expect(() => BackupService.validate(backup), throwsFormatException);
  });
  test(
    'encrypted positions persist after closing storage; queued writes retain both moves',
    () async {
      final dir = await Directory.systemTemp.createTemp('garden-layout-test-');
      Hive.init(dir.path);
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'read'
                ? base64Encode(List<int>.filled(32, 4))
                : null,
          );
      try {
        final store = GardenLayoutStore.instance;
        await store.reload();
        await store.update((v) => v.grow(8));
        await Future.wait([
          store.update(
            (v) => v.move('seed:love', const Offset(.15, .7), [
              'seed:love',
              'seed:peace',
            ]),
          ),
          store.update(
            (v) => v.move('seed:peace', const Offset(.85, .8), [
              'seed:love',
              'seed:peace',
            ]),
          ),
        ]);
        await Hive.close();
        await store.reload();
        expect(store.value.position('seed:love'), const Offset(.15, .7));
        expect(store.value.position('seed:peace'), const Offset(.85, .8));
        expect(store.value.spaces, 3);
      } finally {
        await Hive.close();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await dir.delete(recursive: true);
      }
    },
  );
}
