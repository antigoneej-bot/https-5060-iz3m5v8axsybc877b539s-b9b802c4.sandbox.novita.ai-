import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/mongi/integration/plant_memory.dart';
import 'package:flutter_app/mongi/integration/garden_story_catalog.dart';
import 'package:flutter_app/mongi/integration/postcard_link.dart';
import 'package:flutter_app/services/backup_service.dart';

void main() {
  test('old garden version migrates without losing earned items', () {
    final old = {
      'version': 1,
      'stage': 4,
      'seedTokens': 2,
      'essence': 90,
      'seeds': {'pine': 2},
      'owned': ['bench'],
      'placed': ['bench'],
    };
    final data = MongiGardenData.fromJson(old);
    expect(data.seeds['pine'], 2);
    expect(data.seedTokens, 2);
    expect(data.placed, {'bench'});
    expect(data.recordDays, isEmpty);
    expect(data.toJson()['version'], 2);
  });
  test('multiple records on one day cannot grant multiple daily seeds', () {
    final date = DateTime(2026, 9, 13);
    final data = MongiGardenData().claimRecordDay(date).claimRecordDay(date);
    expect(data.seedTokens, 1);
    expect(data.claimRecordDay(DateTime(2026, 9, 12)).seedTokens, 2);
    expect(data.claimRecordDay(DateTime(2026, 9, 14)).seedTokens, 2);
    expect(
      data.clearStage(1).seedTokens,
      2,
    ); // the game is a separate optional reward
  });
  test('invalid dates cannot enter a restored reward snapshot', () {
    for (final day in ['2026-02-30', '2026-13-01', 'not-a-date']) {
      final json = MongiGardenData().toJson()..['recordDays'] = [day];
      expect(() => MongiGardenData.fromJson(json), throwsFormatException);
    }
  });
  test('plant memory validates species and preserves Unicode', () {
    final memory = PlantMemory(
      plantId: 'pine',
      name: '🌳' * 40,
      note: '기다려 준 자리',
      updatedAt: DateTime(2026, 9, 13),
    );
    expect(PlantMemory.fromJson(memory.toJson()).name, memory.name);
    expect(
      () => PlantMemory.fromJson(memory.toJson()..['plantId'] = 'unknown'),
      throwsFormatException,
    );
    expect(
      () => PlantMemory.fromJson(memory.toJson()..['note'] = '가' * 301),
      throwsFormatException,
    );
  });
  test(
    'stories need publication, entitlement, record days and prior chapter',
    () {
      final pack = gardenStories.first;
      final now = DateTime(2026, 9, 20);
      final data = MongiGardenData(
        recordDays: {'2026-09-13', '2026-09-15', '2026-09-18'},
        storyProgress: {'2026-09': 1},
      );
      expect(pack.canOpen(data, 0, false, now), isTrue);
      expect(pack.canOpen(data, 1, false, now), isFalse);
      expect(pack.canOpen(data, 1, true, now), isTrue);
      expect(pack.canOpen(data, 2, true, now), isFalse);
      expect(pack.canOpen(data, 0, true, DateTime(2026, 8, 31)), isFalse);
      expect(pack.canOpen(data.copy(storyProgress: {}), 1, true, now), isFalse);
      expect(
        pack.canOpen(data.copy(storyProgress: {'2026-09': 3}), 2, false, now),
        isTrue,
      );
    },
  );
  test(
    'archived stories remain unlockable by later nonconsecutive records',
    () {
      final data = MongiGardenData(
        recordDays: {
          '2026-10-01',
          '2026-10-03',
          '2026-10-05',
          '2026-10-07',
          '2026-10-10',
        },
        storyProgress: {'2026-09': 2},
      );
      expect(
        gardenStories.first.canOpen(data, 2, true, DateTime(2026, 10, 11)),
        isTrue,
      );
      expect(
        MongiGardenData.fromJson(data.toJson()).storyProgress,
        data.storyProgress,
      );
    },
  );
  test(
    'referral link must target the configured real app and carries only campaign fields',
    () {
      for (final input in [
        '',
        'http://play.google.com/store/apps/details?id=com.mysticcat.journal',
        'https://evil.example/store/apps/details?id=com.mysticcat.journal',
        'https://play.google.com/store/apps/details?id=another.app',
      ]) {
        expect(gardenPostcardLink(input), isNull);
      }
      final link = gardenPostcardLink(
        'https://play.google.com/store/apps/details?id=com.mysticcat.journal&private=secret',
      )!;
      expect(link.queryParameters.keys.toSet(), {'id', 'referrer'});
      final campaign = Uri.splitQueryString(link.queryParameters['referrer']!);
      expect(campaign, {
        'utm_source': 'garden_postcard',
        'utm_medium': 'share',
        'utm_campaign': 'garden_v1',
      });
      expect(link.toString(), isNot(contains('secret')));
    },
  );
  test(
    'private plant memory backup validates the key and never includes attribution marker',
    () {
      Map<String, dynamic> snapshot(String key) => {
        'schema': 1,
        'createdAt': '2026-09-13T00:00:00.000Z',
        'boxes': {
          'garden_memories': [
            {
              'key': key,
              'value': PlantMemory(
                plantId: 'pine',
                name: '나의 나무',
                note: '한 장면',
                updatedAt: DateTime(2026, 9, 13),
              ).toJson(),
            },
          ],
        },
        'settings': {},
      };
      BackupService.validate(snapshot('pine'));
      expect(
        () => BackupService.validate(snapshot('love')),
        throwsFormatException,
      );
      expect(
        BackupService.allowedPref('garden_postcard_attribution_checked_v1'),
        isFalse,
      );
    },
  );
}
