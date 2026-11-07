import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/garden_layout_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/integration/planting_mind.dart';
import 'package:flutter_app/mongi/integration/session_transaction.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/public_garden_appearance.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/cat_care_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final ownedDirectories = <Directory>[];
  final store = MongiGardenStore.instance;
  final memories = PlantMemoryStore.instance;
  final layouts = GardenLayoutStore.instance;
  final old = MongiGardenData(
    seedTokens: 2,
    essence: 80,
    seeds: {'pine': 4},
    wateredOn: {'pine': '2026-10-30'},
    careRemainders: {'pine': 1},
    owned: {'bench'},
    placed: {'bench'},
  );
  const point = Offset(.82, .77);
  const mind = PlantingMind(
    id: 'mind-test',
    emotionCatId: 'weary',
    note: '많이 지쳤지만, 오늘도 하루를 보냈다.',
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mind-planting-97-');
    ownedDirectories.add(directory);
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
    PlantMemoryStore.mindSaveFault = null;
    CatCareService.setCurrentUser('local_user');
    await StorageService.setCurrentUser('local_user');
    await store.reload();
    await layouts.update(
      (_) => GardenLayout(
        spaces: 3,
        positions: {
          'seed:pine': const Offset(.15, .72),
          'decor:bench': const Offset(.51, .8),
        },
      ),
    );
    await memories.save('pine', '기존 이름', '원래의 기록');
  });
  tearDown(() async {
    PlantMemoryStore.mindSaveFault = null;
    CatCareService.setCurrentUser('local_user');
    SessionTransaction.fault = null;
    await StorageService.clearCurrentUser();
    await Hive.close();
    for (final owned in ownedDirectories) {
      final files = await owned.list(followLinks: false).toList();
      for (final file in files) {
        expect(file, isA<File>());
        await file.delete();
      }
      await owned.delete();
    }
    ownedDirectories.clear();
  });
  Future<void> verify() async {
    await SessionTransaction.initialize();
    await store.reload();
    await layouts.reload();
    await memories.reload();
    expect(store.value.seedTokens, 1);
    expect(store.value.essence, 80);
    expect(store.value.seeds, {'pine': 4, 'cherry': 1});
    expect(store.value.wateredOn, old.wateredOn);
    expect(store.value.careRemainders, old.careRemainders);
    expect(layouts.value.position('seed:cherry'), point);
    expect(layouts.value.positions['seed:pine'], const Offset(.15, .72));
    expect(memories.value['pine']!.note, '원래의 기록');
    final planted = memories.value['cherry']!.timeline.single;
    expect(planted.emotionCatId, 'weary');
    expect(planted.note, mind.note);
    expect(planted.id, mind.id);
  }

  test(
    'atomic private mind, balance and layout survive concurrent retry and restart',
    () async {
      await Future.wait([
        store.plantAt('cherry', point, mind: mind),
        store.plantAt('cherry', point, mind: mind),
      ]);
      await Hive.close();
      await verify();
      final snapshot = await BackupService.snapshot();
      BackupService.validate(snapshot);
      expect(jsonEncode(snapshot), contains(mind.note));
      expect(jsonEncode(snapshot), contains('emotionCatId'));
      await StorageService.clearCurrentUser();
      await Hive.close();
      final restoredDirectory = await Directory.systemTemp.createTemp(
        'mind-restored-97-',
      );
      ownedDirectories.add(restoredDirectory);
      Hive.init(restoredDirectory.path);
      SharedPreferences.setMockInitialValues({});
      await StorageService.setCurrentUser('local_user');
      await BackupService.restore(snapshot);
      await Hive.close();
      await verify();
      // Public appearance stays identical regardless of private emotional content.
      final appearance = {
        'seedCounts': store.value.seeds,
        'layout': layouts.value.toJson(),
      };
      expect(
        PublicGardenAppearance.fingerprint({
          ...appearance,
          'emotionCatId': 'weary',
          'plantMemory': memories.value['cherry']!.toJson(),
        }),
        PublicGardenAppearance.fingerprint(appearance),
      );
    },
  );
  for (final boundary in [
    'before_journal',
    'journal_flushed',
    'hive_flushed',
    'plant_memory_written',
    'layout_written',
    'garden_written',
    'commit_finished',
  ]) {
    test(
      'interrupted $boundary recovers private mind and plant together',
      () async {
        var failed = false;
        SessionTransaction.fault = (stage) async {
          if (!failed && stage == boundary) {
            failed = true;
            throw FileSystemException('injected failure');
          }
        };
        await expectLater(
          store.plantAt('cherry', point, mind: mind),
          throwsA(isA<FileSystemException>()),
        );
        SessionTransaction.fault = null;
        await Hive.close();
        await SessionTransaction.initialize();
        await store.reload();
        await memories.reload();
        if (boundary == 'before_journal') {
          expect(store.value.toJson(), old.toJson());
          expect(memories.value.containsKey('cherry'), false);
        } else {
          await verify();
        }
        await store.plantAt('cherry', point, mind: mind);
        await verify();
      },
    );
  }
  test(
    'emotion-only planting is valid; no fabricated note, letter or extra reward',
    () async {
      await store.plantAt(
        'cherry',
        point,
        mind: const PlantingMind(id: 'mind-empty', emotionCatId: 'sad'),
      );
      await memories.reload();
      final entry = memories.value['cherry']!.timeline.single;
      expect(entry.note, isEmpty);
      expect(entry.emotionCatId, 'sad');
      expect(StorageService.getAllLetters(), isEmpty);
      expect(store.value.recordDays, old.recordDays);
      expect(store.value.essence, old.essence);
      BackupService.validate(await BackupService.snapshot());
    },
  );
  test(
    'existing species, invalid emotions, and invalid positions cannot lose or replace records',
    () async {
      await expectLater(
        store.plantAt('pine', const Offset(.15, .72), mind: mind),
        throwsStateError,
      );
      await expectLater(
        store.plantAt('cherry', const Offset(.82, .12), mind: mind),
        throwsStateError,
      );
      await expectLater(
        store.plantAt(
          'cherry',
          point,
          mind: const PlantingMind(id: 'mind-bad', emotionCatId: 'not-a-cat'),
        ),
        throwsFormatException,
      );
      await store.reload();
      await memories.reload();
      expect(store.value.toJson(), old.toJson());
      expect(memories.value.keys, ['pine']);
      expect(memories.value['pine']!.note, '원래의 기록');
    },
  );

  test(
    'existing plant appends once after duplicate taps, reload and backup restore',
    () async {
      final layout = layouts.value.toJson();
      final original = memories.value['pine']!;
      await Future.wait([
        memories.appendMind('pine', mind, owner: 'local_user'),
        memories.appendMind('pine', mind, owner: 'local_user'),
      ]);
      await Hive.close();
      await memories.reload();
      await memories.appendMind('pine', mind, owner: 'local_user');
      expect(memories.value['pine']!.timeline.length, 2);
      expect(
        memories.value['pine']!.timeline.first.toJson(),
        original.timeline.first.toJson(),
      );
      expect(memories.value['pine']!.name, original.name);
      expect(
        memories.value['pine']!.timeline.last.emotionCatId,
        mind.emotionCatId,
      );
      expect(store.value.toJson(), old.toJson());
      expect(layouts.value.toJson(), layout);
      final snapshot = await BackupService.snapshot();
      BackupService.validate(snapshot);
      await StorageService.clearCurrentUser();
      await Hive.close();
      final restored = await Directory.systemTemp.createTemp(
        'mind-existing-restored-98-',
      );
      ownedDirectories.add(restored);
      Hive.init(restored.path);
      SharedPreferences.setMockInitialValues({});
      await StorageService.setCurrentUser('local_user');
      await BackupService.restore(snapshot);
      await memories.reload();
      await store.reload();
      await layouts.reload();
      expect(memories.value['pine']!.timeline.length, 2);
      expect(memories.value['pine']!.timeline.last.note, mind.note);
      expect(store.value.toJson(), old.toJson());
      expect(layouts.value.toJson(), layout);
    },
  );
  for (final boundary in ['before_write', 'after_write']) {
    test(
      'existing memory write failure at $boundary preserves original and retries once',
      () async {
        final original = memories.value['pine']!.toJson();
        PlantMemoryStore.mindSaveFault = (at) {
          if (at == boundary) throw StateError('test storage failure');
        };
        await expectLater(
          memories.appendMind('pine', mind, owner: 'local_user'),
          throwsStateError,
        );
        PlantMemoryStore.mindSaveFault = null;
        await memories.reload();
        expect(memories.value['pine']!.toJson(), original);
        expect(store.value.toJson(), old.toJson());
        await memories.appendMind('pine', mind, owner: 'local_user');
        await memories.appendMind('pine', mind, owner: 'local_user');
        expect(memories.value['pine']!.timeline.length, 2);
      },
    );
  }
  test(
    'different concurrent private feelings are both kept without currency changes',
    () async {
      await Future.wait([
        memories.appendMind('pine', mind, owner: 'local_user'),
        memories.appendMind(
          'pine',
          const PlantingMind(id: 'second-mind', emotionCatId: 'joyful'),
          owner: 'local_user',
        ),
      ]);
      expect(memories.value['pine']!.timeline.length, 3);
      expect(memories.value['pine']!.timeline.last.note, isEmpty);
      expect(store.value.toJson(), old.toJson());
    },
  );
  test(
    'missing plant, invalid emotion, stale owner and reused draft cannot replace memories',
    () async {
      await expectLater(
        memories.appendMind('cherry', mind, owner: 'local_user'),
        throwsStateError,
      );
      await expectLater(
        memories.appendMind('pine', mind, owner: 'another-owner'),
        throwsStateError,
      );
      await expectLater(
        memories.appendMind(
          'pine',
          const PlantingMind(id: 'bad-mind', emotionCatId: 'not-a-cat'),
          owner: 'local_user',
        ),
        throwsFormatException,
      );
      await memories.appendMind('pine', mind, owner: 'local_user');
      await expectLater(
        memories.appendMind(
          'pine',
          PlantingMind(id: mind.id, emotionCatId: 'joyful'),
          owner: 'local_user',
        ),
        throwsStateError,
      );
      expect(memories.value['pine']!.timeline.length, 2);
      expect(memories.value['pine']!.timeline.last.note, mind.note);
      expect(store.value.toJson(), old.toJson());
    },
  );
  test(
    'account change during a write rolls back only the new private memory',
    () async {
      final original = memories.value['pine']!.toJson();
      PlantMemoryStore.mindSaveFault = (at) {
        if (at == 'after_write') CatCareService.setCurrentUser('other');
      };
      await expectLater(
        memories.appendMind('pine', mind, owner: 'local_user'),
        throwsStateError,
      );
      PlantMemoryStore.mindSaveFault = null;
      CatCareService.setCurrentUser('local_user');
      await memories.reload();
      expect(memories.value['pine']!.toJson(), original);
      expect(store.value.toJson(), old.toJson());
    },
  );
  test(
    'full memory capacity rejects new drafts without deleting older entries',
    () async {
      final entries = List.generate(
        60,
        (i) => PlantMemoryEntry(
          id: 'entry-$i',
          on: '2026-11-07',
          note: '기존 기록 $i',
        ),
      );
      final original = PlantMemory(
        plantId: 'pine',
        name: '원래 이름',
        note: entries.last.note,
        updatedAt: DateTime(2026, 11, 7),
        anniversaryOn: '2026-10-01',
        entries: entries,
      );
      await memories.saveMemory(original);
      await expectLater(
        memories.appendMind('pine', mind, owner: 'local_user'),
        throwsA(isA<PlantMemoryCapacityException>()),
      );
      expect(memories.value['pine']!.toJson(), original.toJson());
      expect(store.value.toJson(), old.toJson());
    },
  );
}
