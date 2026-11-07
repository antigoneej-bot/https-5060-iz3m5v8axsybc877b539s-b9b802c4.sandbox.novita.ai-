import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/services/request_stage.dart';

void main() {
  final profile = {
    'inviteCode': 'ABCD12345678',
    'visibility': 'private',
    'discoveryOptIn': false,
    'receiveGifts': true,
  };
  final lists = <String, dynamic>{
    'neighbors': [],
    'incoming': [],
    'outgoing': [],
    'blocked': [],
  };
  test('entry uses one request and pins returned account', () async {
    final calls = <String>[];
    final service = GardenVillageService(
      currentOwner: () => 'a',
      transport: (action, body, owner) async {
        calls.add(action);
        return {'profile': profile, 'neighbors': lists};
      },
    );
    final result = await service.loadEntry();
    expect(result.profile.inviteCode, 'ABCD12345678');
    expect(calls, ['getVillageEntry']);
  });
  test(
    'old server fallback is sequential and capability rejection is remembered',
    () async {
      final calls = <String>[];
      var active = 0;
      final service = GardenVillageService(
        currentOwner: () => 'a',
        transport: (action, body, owner) async {
          expect(active, 0);
          active++;
          await Future<void>.value();
          calls.add(action);
          active--;
          if (action == 'getVillageEntry')
            throw const CloudException('unknown-action');
          return action == 'getVillageProfile' ? profile : lists;
        },
      );
      await service.loadEntry();
      await service.loadEntry();
      expect(calls, [
        'getVillageEntry',
        'getVillageProfile',
        'listNeighbors',
        'getVillageProfile',
        'listNeighbors',
      ]);
    },
  );
  test('permission failure does not fallback', () async {
    var calls = 0;
    final service = GardenVillageService(
      currentOwner: () => 'a',
      transport: (a, b, c) async {
        calls++;
        throw const CloudException('community-suspended');
      },
    );
    await expectLater(service.loadEntry(), throwsA(isA<CloudException>()));
    expect(calls, 1);
  });
  test('late previous account response is rejected', () async {
    var owner = 'a';
    final pending = Completer<Map<String, dynamic>>();
    final service = GardenVillageService(
      currentOwner: () => owner,
      transport: (a, b, c) => pending.future,
    );
    final request = service.loadEntry();
    final assertion = expectLater(
      request,
      throwsA(
        isA<CloudException>().having((e) => e.code, 'code', 'account-changed'),
      ),
    );
    owner = 'b';
    pending.complete({'profile': profile, 'neighbors': lists});
    await assertion;
  });
  test('authentication deadline reports a safe code without retry', () async {
    final pending = Completer<bool>();
    await expectLater(
      awaitRequestStage(
        pending.future,
        'authentication-timeout',
        timeout: Duration.zero,
      ),
      throwsA(
        isA<CloudException>().having(
          (e) => e.code,
          'code',
          'authentication-timeout',
        ),
      ),
    );
    pending.complete(true);
  });
}
