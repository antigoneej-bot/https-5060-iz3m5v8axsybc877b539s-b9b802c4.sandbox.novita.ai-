import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/services/garden_return_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReceivedCheer cheer(String id, {bool claimed = false}) => ReceivedCheer(
  id: id,
  messageIndex: 0,
  giftLightEssence: 0,
  createdAt: DateTime(2026, 10, 16),
  claimed: claimed,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('read marker persists by owner and never claims server gifts', () async {
    final store = GardenReturnStore();
    await store.observe('alice', [cheer('new'), cheer('old', claimed: true)]);
    expect(store.hasUnseen('alice'), isTrue);
    expect(store.hasUnseen('bob'), isFalse);
    await store.markSeen('alice', ['new']);
    await store.observe('alice', [cheer('new')]);
    expect(store.hasUnseen('alice'), isFalse);
    final restored = GardenReturnStore();
    await restored.reload('alice');
    expect(restored.hasUnseen('alice'), isFalse);
    await restored.observe('bob', [cheer('new')]);
    expect(restored.hasUnseen('bob'), isTrue);
    expect(restored.hasUnseen('alice'), isFalse);
    await restored.observe('bob', [cheer('new', claimed: true)]);
    expect(restored.hasUnseen('bob'), isFalse);
  });
  test(
    'retired gifts and concurrent observe/read do not resurface a badge',
    () async {
      final store = GardenReturnStore();
      await Future.wait([
        store.observe('alice', [cheer('one')]),
        store.markSeen('alice', ['one']),
        store.observe('alice', [cheer('two')], retiredIds: ['two']),
      ]);
      expect(store.hasUnseen('alice'), isFalse);
      await store.observe('alice', [cheer('two')]);
      expect(store.hasUnseen('alice'), isFalse);
    },
  );
  test(
    'return recap compares actual snapshots, scopes owners and counts calendar days',
    () async {
      final store = GardenReturnStore();
      final first = await store.recordVisit(
        'alice',
        seeds: {'love': 2},
        recordDays: 4,
        now: DateTime(2026, 10, 1, 23),
      );
      expect(first.hasChanges, isFalse);
      final next = await store.recordVisit(
        'alice',
        seeds: {'love': 3, 'peace': 1},
        recordDays: 5,
        now: DateTime(2026, 10, 4, 1),
      );
      expect(next.daysAway, 3);
      expect(next.newPlants, 1);
      expect(next.grownPlants, 1);
      expect(next.newRecordDays, 1);
      final bob = await store.recordVisit(
        'bob',
        seeds: {'love': 3},
        recordDays: 5,
        now: DateTime(2026, 10, 4),
      );
      expect(bob.previousVisit, isNull);
      final resting = await store.recordVisit(
        'alice',
        seeds: {'love': 3, 'peace': 1},
        recordDays: 5,
        now: DateTime(2026, 10, 10),
      );
      expect(resting.hasChanges, isFalse);
      expect(resting.description, contains('그대로'));
    },
  );
}
