import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/mongi/integration/cheer_flower_store.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = CheerFlowerStore.instance;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('village-flower-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 17))
              : null,
        );
    await store.reload();
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  ReceivedCheer gift({bool planted = false}) => ReceivedCheer.fromJson({
    'id': 'gift-1',
    'messageIndex': 1,
    'giftLightEssence': 0,
    'createdAt': '2026-10-16T11:00:00Z',
    'flowerKind': 'tulip',
    'senderGardenId': 'sender-a',
    'senderNickname': '초롱',
    'deliveryKind': 'gift',
    'claimed': true,
    'bloomConfirmed': planted,
  });

  test(
    'sender and received date persist and remote planting restores on another device',
    () async {
      await store.remember('owner-a', [gift(planted: true)]);
      await store.reload();
      final flower = store.forOwner('owner-a').single;
      expect(flower.senderNickname, '초롱');
      expect(flower.senderGardenId, 'sender-a');
      expect(flower.createdAt, DateTime.utc(2026, 10, 16, 11));
      expect(flower.planted, isTrue);
      expect(flower.bloomPending, isFalse);
      expect(store.forOwner('owner-b'), isEmpty);
    },
  );

  test(
    'a pure reaction is shown as a reaction but cannot create a flower',
    () async {
      final cheer = ReceivedCheer.fromJson({
        'id': 'reaction-1',
        'messageIndex': 0,
        'deliveryKind': 'cheer',
        'flowerKind': null,
        'reaction': {'kind': 'heart', 'expiresAt': '2026-10-17T11:00:00Z'},
      });
      await store.remember('owner-a', [cheer]);
      final saved = store.forOwner('owner-a').single;
      expect(saved.hasFlower, isFalse);
      expect(saved.reaction?.kind, 'heart');
      await expectLater(store.plant('owner-a', cheer.id), throwsStateError);
    },
  );

  test(
    'transferred flowers cannot return through stale responses or restart',
    () async {
      await store.remember('owner-a', [gift()]);
      await store.remember('owner-b', [gift()]);
      await store.retire('owner-a', 'gift-1');
      await store.remember('owner-a', [gift()]);
      await store.reload();
      expect(store.forOwner('owner-a'), isEmpty);
      expect(store.forOwner('owner-b'), hasLength(1));
      expect(store.value['owner-a:gift-1']!.transferred, isTrue);
      await expectLater(store.plant('owner-a', 'gift-1'), throwsStateError);
    },
  );

  test(
    'retirement received before first local copy still blocks late copies',
    () async {
      await store.remember('owner-a', const [], retiredIds: ['gift-1']);
      await store.remember('owner-a', [gift()]);
      expect(store.forOwner('owner-a'), isEmpty);
    },
  );

  test(
    'fresh server anonymity removes a previously saved sender identity',
    () async {
      await store.remember('owner-a', [gift()]);
      await store.remember('owner-a', [
        ReceivedCheer.fromJson({
          'id': 'gift-1',
          'messageIndex': 1,
          'deliveryKind': 'gift',
          'flowerKind': 'tulip',
          'createdAt': '2026-10-16T11:00:00Z',
          'senderGardenId': null,
          'senderNickname': null,
        }),
      ]);
      await store.reload();
      final flower = store.forOwner('owner-a').single;
      expect(flower.senderGardenId, isNull);
      expect(flower.senderNickname, isNull);
      expect(flower.flowerKind, 'tulip');
    },
  );

  test('old keepsakes remain readable without village metadata', () {
    final legacy = CheerFlower.fromJson({
      'owner': 'owner-a',
      'id': 'legacy',
      'messageIndex': 0,
      'createdAt': null,
      'planted': true,
      'flowerKind': 'hydrangea',
    });
    expect(legacy.hasFlower, isTrue);
    expect(legacy.transferred, isFalse);
    expect(legacy.senderNickname, isNull);
    expect(CheerFlower.fromJson(legacy.toJson()).flowerKind, 'hydrangea');
  });
}
