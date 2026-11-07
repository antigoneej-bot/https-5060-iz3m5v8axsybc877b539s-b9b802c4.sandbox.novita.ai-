import 'dart:async';

import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/models/public_garden_status.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> profile() => {
    'inviteCode': 'CAT12345',
    'visibility': 'private',
    'discoveryOptIn': false,
    'receiveGifts': true,
    'nickname': '나무',
  };

  test(
    'legacy currency-bearing gifts cannot enter the transferable flower picker',
    () {
      final legacy = ReceivedCheer.fromJson({
        'id': 'currency-gift',
        'flowerKind': 'daisy',
        'giftLightEssence': 5,
      });
      expect(legacy.hasFlower, isTrue);
      expect(legacy.canGift, isFalse);
    },
  );

  test(
    'garden RPC retry commits once after lease rejection without replaying success',
    () async {
      var attempts = 0;
      var writes = 0;
      final result = await CloudService.retryAccountBusy(
        owner: 'a',
        currentOwner: () => 'a',
        wait: (_) async {},
        action: () async {
          attempts++;
          if (attempts < 3) throw const CloudException('account-busy');
          writes++;
          return {'published': true};
        },
      );
      expect(result, {'published': true});
      expect(attempts, 3);
      expect(writes, 1);
    },
  );

  test(
    'garden RPC retry never starts after its expected owner changed',
    () async {
      var calls = 0;
      await expectLater(
        CloudService.retryAccountBusy(
          owner: 'a',
          currentOwner: () => 'b',
          action: () async {
            calls++;
            return true;
          },
        ),
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
      expect(calls, 0);
    },
  );

  test(
    'busy rejection retries only before action with bounded delay',
    () async {
      var calls = 0;
      final delays = <Duration>[];
      final service = GardenVillageService(
        currentOwner: () => 'a',
        retryDelay: (delay) async {
          delays.add(delay);
        },
        transport: (action, params, owner) async {
          calls++;
          if (calls < 3) throw const CloudException('account-busy');
          return profile();
        },
      );
      expect((await service.getProfile()).nickname, '나무');
      expect(calls, 3);
      expect(delays, [
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 500),
      ]);
    },
  );

  test('busy retry stops before touching another account after wait', () async {
    var calls = 0;
    String? owner = 'a';
    final service = GardenVillageService(
      currentOwner: () => owner,
      retryDelay: (_) async {
        owner = 'b';
      },
      transport: (action, params, expectedOwner) async {
        calls++;
        throw const CloudException('account-busy');
      },
    );
    await expectLater(
      service.getProfile(),
      throwsA(
        isA<CloudException>().having(
          (error) => error.code,
          'code',
          'account-changed',
        ),
      ),
    );
    expect(calls, 1);
  });

  test('busy retries are finite and other failures are not retried', () async {
    var calls = 0;
    final service = GardenVillageService(
      currentOwner: () => 'a',
      retryDelay: (_) async {},
      transport: (action, params, owner) async {
        calls++;
        throw const CloudException('account-busy');
      },
    );
    await expectLater(service.getProfile(), throwsA(isA<CloudException>()));
    expect(calls, 4);
    calls = 0;
    final failed = GardenVillageService(
      currentOwner: () => 'a',
      retryDelay: (_) async {
        fail('must not retry network failure');
      },
      transport: (action, params, owner) async {
        calls++;
        throw TimeoutException('not known whether mutation committed');
      },
    );
    await expectLater(
      failed.requestNeighbor(gardenId: 'b'),
      throwsA(isA<TimeoutException>()),
    );
    expect(calls, 1);
  });

  test(
    'publication status preserves neighbor scope and clears it on account change',
    () {
      final state = PublicGardenStatus();
      final request = state.begin('a');
      final response = PublicGardenStatusSnapshot.fromJson({
        'published': true,
        'nickname': '나무',
        'visibility': 'neighbors',
        'discoveryOptIn': false,
        'receiveGifts': true,
      });
      expect(state.apply(request, 'a', response), isTrue);
      expect(state.published, isTrue);
      expect(state.visibility, GardenVisibility.neighbors);
      expect(state.discoveryOptIn, isFalse);
      state.selectOwner('b');
      expect(state.published, isNull);
      expect(state.visibility, isNull);
      expect(state.apply(request, 'a', response), isFalse);
      expect(
        () => PublicGardenStatusSnapshot.fromJson({
          'published': true,
          'visibility': 'private',
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'profile cannot treat unavailable or unknown server settings as private',
    () {
      expect(() => GardenVillageProfile.fromJson({}), throwsFormatException);
      expect(
        () => GardenVillageProfile.fromJson({
          ...profile(),
          'visibility': 'friends-of-friends',
        }),
        throwsFormatException,
      );
      final value = GardenVillageProfile.fromJson(profile());
      expect(value.visibility, GardenVisibility.private);
      expect(value.discoveryOptIn, isFalse);
    },
  );

  test(
    'logout or account switch discards an in-flight village response',
    () async {
      String? owner = 'owner-a';
      final response = Completer<Map<String, dynamic>>();
      final service = GardenVillageService(
        currentOwner: () => owner,
        transport: (action, params, expectedOwner) {
          expect(expectedOwner, 'owner-a');
          return response.future;
        },
      );
      final request = service.getProfile();
      owner = 'owner-b';
      response.complete(profile());
      await expectLater(
        request,
        throwsA(
          isA<CloudException>().having(
            (error) => error.code,
            'code',
            'account-changed',
          ),
        ),
      );
      await expectLater(
        service.getProfile(),
        throwsA(
          isA<CloudException>().having(
            (error) => error.code,
            'code',
            'account-changed',
          ),
        ),
      );
    },
  );

  test('logged-out access never sends an authenticated action', () async {
    var calls = 0;
    final service = GardenVillageService(
      currentOwner: () => null,
      transport: (action, params, owner) async {
        calls++;
        return profile();
      },
    );
    await expectLater(
      service.listNeighbors(),
      throwsA(
        isA<CloudException>().having(
          (error) => error.code,
          'code',
          'authentication-required',
        ),
      ),
    );
    expect(calls, 0);
  });

  test(
    'private or neighbor scope always disables discovery in outgoing settings',
    () async {
      final payloads = <Map<String, dynamic>>[];
      final service = GardenVillageService(
        currentOwner: () => 'a',
        transport: (action, params, owner) async {
          expect(action, 'updateVillageProfile');
          payloads.add(params);
          return {...profile(), ...params};
        },
      );
      for (final visibility in [
        GardenVisibility.private,
        GardenVisibility.neighbors,
      ]) {
        await service.updateProfile(
          visibility: visibility,
          discoveryOptIn: true,
          receiveGifts: false,
        );
      }
      expect(payloads.every((p) => p['discoveryOptIn'] == false), isTrue);
      expect(payloads.every((p) => p['receiveGifts'] == false), isTrue);
      expect(payloads.every((p) => !p.containsKey('snapshot')), isTrue);
    },
  );

  test(
    'invite request has exactly one target, normalized code and no private data',
    () async {
      final payloads = <Map<String, dynamic>>[];
      final service = GardenVillageService(
        currentOwner: () => 'a',
        transport: (action, params, owner) async {
          payloads.add(params);
          return {'requested': true};
        },
      );
      await service.requestNeighbor(inviteCode: ' abcd-1234 5678 ');
      expect(payloads.single, {'inviteCode': 'ABCD12345678'});
      await expectLater(service.requestNeighbor(), throwsArgumentError);
      await expectLater(
        service.requestNeighbor(inviteCode: 'CAT12345', gardenId: 'b'),
        throwsArgumentError,
      );
      expect(payloads, hasLength(1));
    },
  );

  test('individual garden read rejects a mismatched owner response', () async {
    final service = GardenVillageService(
      currentOwner: () => 'a',
      transport: (action, params, owner) async => {
        'garden': {'gardenId': 'wrong-owner'},
      },
    );
    await expectLater(service.getGarden('b'), throwsFormatException);
  });

  test(
    'emoji-only support and flower gifts are distinct zero-currency actions',
    () async {
      final payloads = <Map<String, dynamic>>[];
      final service = GardenVillageService(
        currentOwner: () => 'a',
        transport: (action, params, owner) async {
          expect(action, 'sendPublicCheer');
          payloads.add(params);
          return {'sent': true};
        },
      );
      await service.sendCheer(
        gardenId: 'b',
        messageIndex: 0,
        reaction: 'heart',
      );
      await service.sendCheer(
        gardenId: 'b',
        messageIndex: 1,
        deliveryKind: 'gift',
        flowerKind: 'lavender',
      );
      expect(payloads[0]['deliveryKind'], 'cheer');
      expect(payloads[0]['flowerKind'], isNull);
      expect(payloads[1]['flowerKind'], 'lavender');
      expect(payloads.every((p) => p['giftLightEssence'] == 0), isTrue);
    },
  );

  test(
    'gift transfer retries reuse caller request ID and verify server receipt',
    () async {
      final requestId = GardenVillageService.createGiftRequestId();
      final payloads = <Map<String, dynamic>>[];
      var failFirst = true;
      final service = GardenVillageService(
        currentOwner: () => 'a',
        transport: (action, params, owner) async {
          expect(action, 'sendGardenGift');
          payloads.add(params);
          if (failFirst) {
            failFirst = false;
            throw TimeoutException('response lost');
          }
          return {
            'sent': true,
            'id': 'received-b',
            'sourceCheerId': 'received-a',
          };
        },
      );
      await expectLater(
        service.sendGift(
          gardenId: 'b',
          sourceCheerId: 'received-a',
          requestId: requestId,
        ),
        throwsA(isA<TimeoutException>()),
      );
      await service.sendGift(
        gardenId: 'b',
        sourceCheerId: 'received-a',
        requestId: requestId,
      );
      expect(payloads[0], payloads[1]);
      expect(
        payloads[1].keys,
        unorderedEquals(['gardenId', 'sourceCheerId', 'requestId']),
      );
    },
  );

  test('gift transfer never treats a missing receipt as confirmed', () async {
    final service = GardenVillageService(
      currentOwner: () => 'a',
      transport: (action, params, owner) async => {'sent': true},
    );
    await expectLater(
      service.sendGift(
        gardenId: 'b',
        sourceCheerId: 'source',
        requestId: GardenVillageService.createGiftRequestId(),
      ),
      throwsA(
        isA<CloudException>().having(
          (e) => e.code,
          'code',
          'invalid-delivery-receipt',
        ),
      ),
    );
  });

  test(
    'received metadata preserves sender/date and explicit retirement independently of list limits',
    () {
      final value = ReceivedCheerBatch.fromJson({
        'cheers': [
          {
            'id': 'received',
            'messageIndex': 2,
            'createdAt': '2026-10-16T11:00:00.000Z',
            'senderGardenId': 'friend',
            'senderNickname': '초롱',
            'flowerKind': 'tulip',
            'deliveryKind': 'gift',
            'bloomConfirmed': true,
            'plantedFlowerKind': 'hydrangea',
            'claimed': true,
          },
        ],
        'retiredIds': ['transferred'],
      });
      expect(value.cheers.single.senderNickname, '초롱');
      expect(value.cheers.single.createdAt, DateTime.utc(2026, 10, 16, 11));
      expect(value.cheers.single.canGift, isFalse);
      expect(value.cheers.single.plantedFlowerKind, 'hydrangea');
      expect(value.retiredIds, ['transferred']);
      expect(() => value.retiredIds.add('extra'), throwsUnsupportedError);
    },
  );

  test(
    'pure emoji does not mint a plantable flower; legacy flower remains compatible',
    () {
      final emoji = ReceivedCheer.fromJson({
        'id': 'emoji',
        'deliveryKind': 'cheer',
        'flowerKind': null,
      });
      expect(emoji.hasFlower, isFalse);
      expect(emoji.canGift, isFalse);
      final legacy = ReceivedCheer.fromJson({
        'id': 'legacy',
        'flowerKind': 'daisy',
      });
      expect(legacy.hasFlower, isTrue);
      expect(legacy.canGift, isTrue);
    },
  );

  test(
    'malformed retired IDs fail rather than deleting unrelated local records',
    () {
      expect(
        () => ReceivedCheerBatch.fromJson({
          'cheers': [],
          'retiredIds': [null],
        }),
        throwsFormatException,
      );
      expect(
        () => GardenNeighborLists.fromJson({'neighbors': []}),
        throwsFormatException,
      );
    },
  );
}
