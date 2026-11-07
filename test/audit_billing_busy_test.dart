import 'dart:async';

import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a busy status lease delays receipt verification without duplicate grants',
    () async {
      var attempts = 0;
      var grants = 0;
      final delays = <Duration>[];
      final result = await CloudService.retryAccountBusy(
        owner: 'purchase-owner',
        currentOwner: () => 'purchase-owner',
        wait: (duration) async => delays.add(duration),
        action: () async {
          attempts++;
          if (attempts < 3) throw const CloudException('account-busy');
          grants++;
          return {'active': true, 'productId': 'garden_plus_yearly'};
        },
      );
      expect(result['active'], isTrue);
      expect(attempts, 3);
      expect(grants, 1);
      expect(delays, const [
        Duration(milliseconds: 200),
        Duration(milliseconds: 500),
      ]);
    },
  );

  test(
    'a receipt with an uncertain response is never automatically replayed',
    () async {
      var calls = 0;
      await expectLater(
        CloudService.retryAccountBusy(
          owner: 'purchase-owner',
          currentOwner: () => 'purchase-owner',
          wait: (_) async => fail('A timeout must not schedule a retry.'),
          action: () async {
            calls++;
            // The server may have committed before the response was lost.
            throw TimeoutException('response unavailable');
          },
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(calls, 1);
    },
  );

  test(
    'switching accounts during a busy wait stops the old receipt retry',
    () async {
      var owner = 'purchase-owner';
      var calls = 0;
      await expectLater(
        CloudService.retryAccountBusy(
          owner: 'purchase-owner',
          currentOwner: () => owner,
          wait: (_) async => owner = 'different-account',
          action: () async {
            calls++;
            throw const CloudException('account-busy');
          },
        ),
        throwsA(
          isA<CloudException>().having(
            (error) => error.code,
            'code',
            'account-changed',
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test(
    'a busy server has a bounded number of subscription retry attempts',
    () async {
      var calls = 0;
      final delays = <Duration>[];
      await expectLater(
        CloudService.retryAccountBusy(
          owner: 'purchase-owner',
          currentOwner: () => 'purchase-owner',
          wait: (duration) async => delays.add(duration),
          action: () async {
            calls++;
            throw const CloudException('account-busy');
          },
        ),
        throwsA(
          isA<CloudException>().having(
            (error) => error.code,
            'code',
            'account-busy',
          ),
        ),
      );
      expect(calls, 4);
      expect(delays, const [
        Duration(milliseconds: 200),
        Duration(milliseconds: 500),
        Duration(milliseconds: 1000),
      ]);
    },
  );

  test(
    'a purchase ownership rejection is final for this verification attempt',
    () async {
      var calls = 0;
      await expectLater(
        CloudService.retryAccountBusy(
          owner: 'purchase-owner',
          currentOwner: () => 'purchase-owner',
          wait: (_) async => fail('Ownership errors must not be retried.'),
          action: () async {
            calls++;
            throw const CloudException('purchase-owner-mismatch');
          },
        ),
        throwsA(
          isA<CloudException>().having(
            (error) => error.code,
            'code',
            'purchase-owner-mismatch',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
}
