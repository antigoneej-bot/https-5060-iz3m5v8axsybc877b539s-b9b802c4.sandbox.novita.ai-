import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a stage grants a reward exactly once', () {
    final first = MongiGardenData().clearStage(1);
    expect(first.stage, 2);
    expect(first.seedTokens, 1);
    expect(first.essence, 30);
    final duplicate = first.clearStage(1);
    expect(duplicate.essence, 30);
    expect(duplicate.seedTokens, 1);
    expect(duplicate.clearStage(3).stage, 2);
  });
  test('planting consumes a seed and grows only its selected plant', () {
    final data = MongiGardenData().clearStage(1).plant('pine');
    expect(data.seedTokens, 0);
    expect(data.seeds['pine'], 1);
    expect(data.plant('pine').seeds['pine'], 1);
    expect(data.clearStage(2).plant('pine').seeds['pine'], 2);
  });
  test('unknown plant cannot consume a seed', () {
    final data = MongiGardenData().clearStage(1).plant('not-a-tree');
    expect(data.seedTokens, 1);
    expect(data.seeds, isEmpty);
  });
  test('snapshot round trip preserves rewards and placements', () {
    final data = MongiGardenData(
      stage: 4,
      essence: 30,
      seedTokens: 2,
      seeds: {'love': 1},
      owned: {'bench'},
      placed: {'bench'},
    );
    expect(MongiGardenData.fromJson(data.toJson()).toJson(), data.toJson());
  });
  test('malformed snapshot is rejected instead of silently reset', () {
    expect(
      () => MongiGardenData.fromJson({'version': 99}),
      throwsFormatException,
    );
    final json = MongiGardenData().toJson()..['placed'] = ['bench'];
    expect(() => MongiGardenData.fromJson(json), throwsFormatException);
  });
  test(
    'concurrent completion callbacks and reload cannot double rewards',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = MongiGardenStore.instance;
      await store.reload();
      await Future.wait([store.completeStage(1), store.completeStage(1)]);
      await store.reload();
      expect(store.value.stage, 2);
      expect(store.value.seedTokens, 1);
      expect(store.value.essence, 30);
      await store.plant('pine');
      await store.reload();
      expect(store.value.seedTokens, 0);
      expect(store.value.seeds['pine'], 1);
    },
  );
  test('the unified garden snapshot is included in the backup allowlist', () {
    expect(BackupService.prefType(MongiGardenStore.storageKey), 'string');
  });
}
