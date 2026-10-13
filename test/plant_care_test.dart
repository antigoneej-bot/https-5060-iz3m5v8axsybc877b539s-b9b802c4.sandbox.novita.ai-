import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/models/seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 10, 13);
  MongiGardenData start() => MongiGardenData(seedTokens: 2).plant('pine', now: day);

  test('one seed plants one tree and saves its real planting date', () {
    final first = start();
    expect(first.seedTokens, 1);
    expect(first.seeds['pine'], 1);
    expect(first.plantedOn['pine'], '2026-10-13');
    final duplicate = first.plant('pine', now: day.add(const Duration(days: 1)));
    expect(duplicate.seedTokens, 1);
    expect(duplicate.plantedOn['pine'], '2026-10-13');
    expect(duplicate.seeds['pine'], 1);
  });
  test('watering grows once a day without spending a seed or essence', () {
    final first = start().waterPlant('pine', day);
    final duplicate = first.waterPlant('pine', day.add(const Duration(hours: 3)));
    expect(duplicate.seeds['pine'], 2);
    expect(duplicate.seedTokens, 1);
    expect(duplicate.essence, 0);
    final next = duplicate.waterPlant('pine', day.add(const Duration(days: 1)));
    expect(next.seeds['pine'], 3);
    expect(SeedType.byId('pine').tierForCount(3), 2);
  });
  test('missed days do not shrink plants or award automatic growth', () {
    final plant = start().waterPlant('pine', day);
    final returned = plant.waterPlant('pine', day.add(const Duration(days: 30)));
    expect(returned.seeds['pine'], 3);
  });
  test('old trees retain growth and do not invent a planting date', () {
    final old = MongiGardenData(seeds: {'pine': 8}).toJson()
      ..remove('plantedOn')..remove('wateredOn');
    final restored = MongiGardenData.fromJson(old);
    expect(restored.seeds['pine'], 8);
    expect(restored.plantedOn, isEmpty);
    expect(restored.waterPlant('pine', day).seeds['pine'], 9);
  });
  test('each plant has its own daily care receipt', () {
    final two = start().plant('love', now: day)
      .waterPlant('pine', day).waterPlant('love', day);
    expect(two.seeds, {'pine': 2, 'love': 2});
    expect(two.wateredOn.length, 2);
  });
  test('clock rollback and backup round trip do not duplicate daily growth', () {
    final first = start().waterPlant('pine', day.add(const Duration(days: 1)));
    final restored = MongiGardenData.fromJson(first.toJson());
    expect(restored.waterPlant('pine', day).seeds['pine'], 2);
    expect(restored.waterPlant('pine', day.add(const Duration(days: 1))).seeds['pine'], 2);
  });
  test('mature trees retain old progress and can still receive daily care', () {
    for (final count in [10, 25]) {
      final cared = MongiGardenData(seeds: {'pine': count}).waterPlant('pine', day);
      expect(cared.seeds['pine'], count);
      expect(cared.wateredToday('pine', day), isTrue);
    }
  });
  test('repeated game seed reward becomes an inventory seed, not forced growth', () {
    final result = start().plantReward('pine', now: day);
    expect(result.seeds['pine'], 1);
    expect(result.seedTokens, 2);
    expect(result.plantedOn['pine'], '2026-10-13');
  });
  test('invalid dates and watering an unplanted species are rejected', () {
    expect(() => MongiGardenData().waterPlant('pine', day), throwsStateError);
    final invalid = start().toJson()..['wateredOn'] = {'pine': '2026-02-30'};
    expect(() => MongiGardenData.fromJson(invalid), throwsFormatException);
  });
  test('concurrent watering saves growth and daily receipt once', () async {
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(start().toJson()),
    });
    final store = MongiGardenStore.instance;
    final attempts = await Future.wait([
      store.waterPlant('pine', now: day), store.waterPlant('pine', now: day),
    ]);
    expect(attempts.where((v) => v).length, 1);
    await store.reload();
    expect(store.value.seeds['pine'], 2);
    expect(store.value.wateredOn['pine'], '2026-10-13');
  });
}
