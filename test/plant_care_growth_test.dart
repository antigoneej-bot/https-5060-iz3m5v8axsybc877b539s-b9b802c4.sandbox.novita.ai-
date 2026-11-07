import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/models/plant_care.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/models/garden_life.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime(2026, 10, 23);
  MongiGardenData planted() =>
      MongiGardenData(seedTokens: 2, essence: 40).plant('pine', now: today);

  test('optional care makes gradual progress without consuming currency', () {
    var data = planted();
    for (final care in PlantCare.values) {
      final before = data.growthFor('pine');
      data = data.carePlant('pine', care, today);
      expect(data.growthFor('pine'), greaterThan(before));
      expect(identical(data.carePlant('pine', care, today), data), isTrue);
    }
    expect(data.growthFor('pine'), closeTo(2 + 2 / 3, .00001));
    expect(data.seedTokens, 1);
    expect(data.essence, 40);
    expect(data.claimedGiftReceipts, isEmpty);
  });

  test('water alone takes nine care days and all three take six', () {
    for (final all in [false, true]) {
      var data = planted();
      final days = all ? 6 : 9;
      for (var i = 0; i < days; i++) {
        for (final care in all ? PlantCare.values : [PlantCare.water]) {
          data = data.carePlant('pine', care, today.add(Duration(days: i * 2)));
        }
        if (i < days - 1) expect(data.growthFor('pine'), lessThan(10));
      }
      expect(data.seeds['pine'], 10);
      expect(data.careRemainders['pine'], 0);
      expect(data.growthProgress('pine'), 1);
    }
  });

  test(
    'old versions keep their trees and new receipts survive serialization',
    () {
      for (final version in [1, 2]) {
        final old = MongiGardenData(seeds: {'pine': 8, 'cherry': 25}).toJson()
          ..['version'] = version
          ..remove('fertilizedOn')
          ..remove('sunlightOn')
          ..remove('careRemainders');
        final migrated = MongiGardenData.fromJson(old);
        expect(migrated.seeds, {'pine': 8, 'cherry': 25});
        expect(migrated.plantedOn, isEmpty);
        final cared = migrated.carePlant('pine', PlantCare.sunlight, today);
        final restored = MongiGardenData.fromJson(
          jsonDecode(jsonEncode(cared.toJson())),
        );
        expect(restored.toJson(), cared.toJson());
        expect(
          restored.carePlant('pine', PlantCare.sunlight, today),
          same(restored),
        );
        expect(restored.growthFor('pine'), closeTo(8 + 1 / 3, .00001));
      }
    },
  );

  test('clock rollback cannot collect a different care type in the past', () {
    final future = planted().carePlant(
      'pine',
      PlantCare.fertilizer,
      today.add(const Duration(days: 1)),
    );
    for (final care in PlantCare.values) {
      expect(future.carePlant('pine', care, today), same(future));
    }
    expect(
      () => future.carePlant('cherry', PlantCare.sunlight, today),
      throwsStateError,
    );
  });

  test('bad care dates and fractional records are rejected during restore', () {
    for (final invalid in [
      planted().toJson()..['fertilizedOn'] = {'pine': '2026-02-30'},
      planted().toJson()..['sunlightOn'] = {'pine': '2026-10-22'},
      planted().toJson()..['sunlightOn'] = {'cherry': '2026-10-23'},
      planted().toJson()..['careRemainders'] = {'pine': 3},
      planted().toJson()..['careRemainders'] = {'pine': -1},
      planted().toJson()..['careRemainders'] = {'pine': .5},
      planted().toJson()..['careRemainders'] = {'cherry': 1},
    ]) {
      expect(() => MongiGardenData.fromJson(invalid), throwsFormatException);
    }
  });

  test(
    'concurrent different care saves once each with no lost remainder',
    () async {
      SharedPreferences.setMockInitialValues({
        MongiGardenStore.storageKey: jsonEncode(planted().toJson()),
      });
      final store = MongiGardenStore.instance;
      final results = await Future.wait([
        for (var i = 0; i < 4; i++)
          for (final care in PlantCare.values)
            store.carePlant('pine', care, now: today),
      ]);
      expect(results.where((saved) => saved).length, 3);
      await store.reload();
      expect(store.value.growthFor('pine'), closeTo(2 + 2 / 3, .00001));
      for (final care in PlantCare.values) {
        expect(store.value.caredToday('pine', care, today), isTrue);
      }
    },
  );

  test('mature trees exceed cats at every lawn depth and growth is capped', () {
    for (final seed in SeedType.all.where((s) => s.isTree)) {
      for (final y in [.52, .65, .8, .91]) {
        final depth = (.88 + (y - .52) * .55).clamp(.84, 1.10);
        final cat = GardenCatMoment.depthSize(y * 800);
        expect(seed.worldArtSize(1) * depth, lessThan(cat));
        expect(seed.worldArtSize(10) * depth * .8, greaterThan(cat * 1.5));
        expect(seed.worldArtSize(25), seed.worldArtSize(10));
      }
    }
  });
}
