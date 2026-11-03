import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/garden_layout_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/garden_decoration.dart';
import 'package:flutter_app/mongi/models/plant_care.dart';
import 'package:flutter_app/mongi/services/garden_storage.dart';
import 'package:flutter_app/services/garden_style_store.dart';
import 'package:flutter_app/services/private_letter_memory_source.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Directory directory;
  setUp(() async {
    SharedPreferences.setMockInitialValues({}); CatCareService.setCurrentUser('remaining-test');
    directory = await Directory.systemTemp.createTemp('remaining-proposals-'); Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secure, (call) async => call.method == 'read' ? base64Encode(List<int>.filled(32, 7)) : null);
  });
  tearDown(() async {
    await Hive.close(); await directory.delete(recursive: true); CatCareService.clearCurrentUser();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secure, null);
  });
  Future<void> seed(MongiGardenData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(MongiGardenStore.storageKey, jsonEncode(data.toJson())); await MongiGardenStore.instance.reload();
  }
  test('only successful planting and actual growth create dated events', () {
    final day = DateTime(2026, 11, 2);
    final planted = MongiGardenData(seedTokens: 1).plant('pine', now: day);
    expect(planted.lifeEvents.single, {'kind': 'plant', 'plant': 'pine', 'at': '2026-11-02', 'level': 1});
    expect(planted.plant('pine', now: day).lifeEvents, planted.lifeEvents);
    final grown = planted.carePlant('pine', PlantCare.water, day);
    expect(grown.lifeEvents.last['kind'], 'growth');
    expect(grown.carePlant('pine', PlantCare.water, day).lifeEvents, grown.lifeEvents);
    expect(MongiGardenData.fromJson(grown.toJson()).lifeEvents, grown.lifeEvents);
    expect(MongiGardenData.fromJson(planted.toJson()..remove('lifeEvents')).lifeEvents, isEmpty);
    final bad = grown.toJson()..['lifeEvents'] = [{'kind': 'growth', 'plant': 'pine', 'at': '2026-02-30', 'level': 2}];
    expect(() => MongiGardenData.fromJson(bad), throwsFormatException);
  });
  test('all five additions purchase onto open land without overlap or duplicate charge', () async {
    await seed(MongiGardenData(essence: GardenDecoration.newPlacementIds.length * 60));
    final store = MongiGardenStore.instance;
    var remaining = GardenDecoration.newPlacementIds.length * 60;
    for (final id in GardenDecoration.newPlacementIds) {
      final item = GardenDecoration.byId(id);
      await Future.wait([store.obtain(item), store.obtain(item)]);
      remaining -= 60;
      expect(store.value.essence, remaining, reason: id);
      final layout = GardenLayoutStore.instance.value;
      final visible = store.value.placed.map((id) => 'decor:$id').toList();
      for (final placed in visible) {
        expect(layout.placementError(placed, layout.position(placed), visible),
            isNull, reason: placed);
      }
    }
    expect(store.value.placed, containsAll(GardenDecoration.newPlacementIds));
  });
  test('purchase places on open land and replay does not charge twice', () async {
    await seed(MongiGardenData(essence: 200)); final store = MongiGardenStore.instance;
    final item = GardenDecoration.byId('summer_parasol');
    await Future.wait([store.obtain(item), store.obtain(item)]);
    expect(store.value.essence, 140);
    final layout = GardenLayoutStore.instance.value;
    expect(layout.isOpen(GardenLayout.spaceFor(layout.position('decor:summer_parasol').dx)), isTrue);
    expect(layout.placementError('decor:summer_parasol', layout.position('decor:summer_parasol'), ['decor:summer_parasol']), isNull);
    await store.toggle(item.id); await store.toggle(item.id);
    expect(store.value.essence, 140); expect(store.value.placed, contains(item.id));
  });
  test('style save includes defaults and restoration preserves growth and money', () async {
    await seed(MongiGardenData(seeds: const {'pine': 5}, essence: 87));
    final style = GardenStyleStore.instance; await style.save('나의 봄'); await style.setSeason('spring');
    final original = GardenLayoutStore.instance.value.position('seed:pine');
    await GardenLayoutStore.instance.update((v) => v.move('seed:pine', const Offset(.5, .7), ['seed:pine']));
    await style.apply('나의 봄');
    expect(GardenLayoutStore.instance.value.position('seed:pine'), original);
    expect(MongiGardenStore.instance.value.seeds['pine'], 5); expect(MongiGardenStore.instance.value.essence, 87);
    final backup = await BackupService.snapshot(); BackupService.validate(backup);
    expect((backup['boxes'] as Map)['garden_styles'], isNotEmpty);
    await style.delete('나의 봄'); expect(style.value['layouts'], isEmpty); expect(style.season, 'spring');
  });
  test('legacy duplicate notes receive distinct stable IDs and link to original diary', () async {
    final box = await HiveEncryption.openBox('mongi_progress_local_user');
    final row = {'date': '2026-11-01', 'emotionType': 'joy', 'note': '작은 기쁨'};
    await box.put('diary_entries', [row, {...row}]); await seed(MongiGardenData(seeds: const {'pine': 3}));
    final storage = GardenStorage(); await storage.init(); final entries = storage.diaryEntries;
    expect(entries, hasLength(2)); expect(entries[0]['id'], isNot(entries[1]['id']));
    expect(entries.map((e) => e['note']), ['작은 기쁨', '작은 기쁨']);
    final id = 'garden-diary:${entries[0]['id']}';
    expect((await PrivateLetterMemorySource.find(id))!.text, '작은 기쁨');
    await PlantMemoryStore.instance.attachLetterQuote(plantId: 'pine', sourceLetterId: id, quote: '작은 기쁨');
    expect(PlantMemoryStore.instance.value['pine']!.timeline.single.sourceLetterId, id);
    await box.put('diary_entries', [entries[1]]); await PlantMemoryStore.instance.reload();
    expect(PlantMemoryStore.instance.value['pine']!.timeline, isEmpty);
    await storage.init(); expect(storage.diaryEntries.single['id'], entries[1]['id']);
  });
  test('original catalog stays in central land and additions fit expanded land', () {
    final oldIds = GardenLayout.itemIds.where((id) => !GardenDecoration.newPlacementIds.contains(id.replaceFirst('decor:', ''))).toList();
    final original = GardenLayout();
    for (final id in oldIds) expect(original.placementError(id, original.position(id), oldIds), isNull, reason: id);
    final expanded = GardenLayout(spaces: 3);
    for (final id in GardenLayout.itemIds) expect(expanded.placementError(id, expanded.position(id), GardenLayout.itemIds), isNull, reason: id);
  });
}
