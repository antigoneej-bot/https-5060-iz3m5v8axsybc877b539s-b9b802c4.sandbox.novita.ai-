import 'dart:convert';
import 'dart:io';
import 'package:flutter_app/mongi/models/garden_gifts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/mongi/models/garden_life.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/integration/cheer_flower_store.dart';
import 'package:flutter_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'reaction expires exactly at its stored deadline, including after parsing',
    () {
      final end = DateTime.utc(2026, 10, 6);
      final reaction = GardenReaction.fromJson({
        'kind': 'heart',
        'expiresAt': end.toIso8601String(),
      })!;
      expect(
        reaction.activeAt(end.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
      expect(reaction.activeAt(end), isFalse);
      expect(
        GardenReaction.fromJson({
          'kind': 'custom',
          'expiresAt': end.toIso8601String(),
        }),
        isNull,
      );
    },
  );
  test(
    'private letter list follows deletion independently of preserved tree growth',
    () {
      final letters = [
        LetterEntry(
          id: 'a',
          catId: 'cat',
          date: DateTime(2026, 10, 4, 8),
          letterText: '슬펐어',
        ),
        LetterEntry(
          id: 'b',
          catId: 'cat',
          date: DateTime(2026, 10, 4, 20),
          letterText: '기뻤어',
        ),
        LetterEntry(
          id: 'c',
          catId: 'cat',
          date: DateTime(2026, 10, 6),
          letterText: '',
          moodEmoji: '😔',
        ),
      ];
      expect(gardenMemoryDays(letters), [
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 4),
      ]);
      expect(gardenMemoryDays(letters.take(2)).length, 1);
      expect(gardenMemoryDays([]), isEmpty);
    },
  );
  test(
    'cat visits actual plant and bench placements, resting works without animation',
    () {
      const plant = Offset(1100, 500), bench = Offset(1550, 600);
      final poses = List.generate(
        1600,
        (i) => GardenCatMoment.at(i / 10, plant: plant, bench: bench),
      );
      expect(
        poses.any(
          (p) => (p.feet - (plant + const Offset(-66, -5))).distance < 1,
        ),
        isTrue,
      );
      expect(
        poses.any((p) => p.resting && p.feet == bench + const Offset(0, -58)),
        isTrue,
      );
      expect(poses.any((p) => p.walking && p.frame > 0), isTrue);
      for (var i = 1; i < poses.length; i++) {
        expect((poses[i].feet - poses[i - 1].feet).distance, lessThan(16));
      }
      expect(
        GardenCatMoment.at(
          1,
          bench: bench,
          quiet: true,
          animated: false,
        ).resting,
        isTrue,
      );
      expect(
        GardenCatMoment.at(18, animated: false).feet,
        const Offset(1200, 395),
      );
    },
  );
  test(
    'received flowers persist, stay unique and remain isolated by owner',
    () async {
      final dir = await Directory.systemTemp.createTemp('garden-flowers-');
      Hive.init(dir.path);
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'read'
                ? base64Encode(List<int>.filled(32, 5))
                : null,
          );
      try {
        final store = CheerFlowerStore.instance;
        const cheer = ReceivedCheer(
          id: 'real-cheer',
          messageIndex: 2,
          giftLightEssence: 0,
          createdAt: null,
          flowerKind: 'hydrangea',
        );
        await store.remember('owner-a', [cheer]);
        await Future.wait([
          store.plant('owner-a', cheer.id),
          store.remember('owner-a', [cheer]),
        ]);
        await Hive.close();
        Hive.init(dir.path);
        await store.reload();
        expect(store.forOwner('owner-a').length, 1);
        expect(store.forOwner('owner-a').single.planted, isTrue);
        expect(store.forOwner('owner-a').single.bloomPending, isTrue);
        await store.markBloomSynced('owner-a', cheer.id);
        expect(store.forOwner('owner-a').single.flowerKind, 'hydrangea');
        await store.plant('owner-a', cheer.id, flowerKind: 'tulip');
        await store.remember('owner-a', [cheer]);
        expect(store.forOwner('owner-a').single.flowerKind, 'tulip');
        expect(store.forOwner('owner-a').single.bloomPending, isFalse);
        expect(store.forOwner('owner-b'), isEmpty);
        expect(store.forOwner(null), isEmpty);
        await expectLater(store.plant('owner-b', cheer.id), throwsStateError);
        await expectLater(store.plant('owner-a', 'unknown'), throwsStateError);
        final flower = store.forOwner('owner-a').single;
        final data = {
          'schema': 1,
          'createdAt': '2026-10-04T00:00:00Z',
          'boxes': {for (final name in BackupService.boxes) name: <Object>[]},
          'settings': <String, Object>{},
        };
        (data['boxes'] as Map)['garden_cheer_flowers'] = [
          {'key': flower.key, 'value': flower.toJson()},
        ];
        BackupService.validate(data);
        (data['boxes'] as Map)['garden_cheer_flowers'] = [
          {'key': 'wrong-owner', 'value': flower.toJson()},
        ];
        expect(() => BackupService.validate(data), throwsFormatException);
        expect(
          () => CheerFlower.fromJson(flower.toJson()..['messageIndex'] = 99),
          throwsFormatException,
        );
      } finally {
        await Hive.close();
        await dir.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
}
