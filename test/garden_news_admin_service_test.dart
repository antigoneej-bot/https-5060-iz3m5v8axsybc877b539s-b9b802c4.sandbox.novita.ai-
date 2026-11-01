import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/garden_news_admin_service.dart';

void main() {
  test(
    'news claim supports Kakao without granting access to plain accounts',
    () {
      expect(hasGardenNewsAdminClaim({'garden_news_admin': true}), isTrue);
      expect(
        hasGardenNewsAdminClaim({
          'garden_social_verified': true,
          'garden_social_provider': 'kakao',
        }),
        isFalse,
      );
      expect(hasGardenNewsAdminClaim({'garden_news_admin': 'true'}), isFalse);
      expect(hasGardenNewsAdminClaim({'garden_news_admin': 1}), isFalse);
    },
  );

  test('legacy admin email requires verified identity', () {
    expect(
      hasGardenNewsAdminClaim({
        'email': 'ANTIGONE.EJ@GMAIL.COM',
        'email_verified': true,
      }),
      isTrue,
    );
    expect(
      hasGardenNewsAdminClaim({
        'email': 'antigone.ej@gmail.com',
        'email_verified': false,
      }),
      isFalse,
    );
    expect(
      hasGardenNewsAdminClaim({
        'email': 'someone@example.com',
        'email_verified': true,
      }),
      isFalse,
    );
  });

  test(
    'entry and manual refresh get fresh claims; revocation clears access',
    () async {
      var calls = 0;
      var granted = true;
      final service = GardenNewsAdminService(
        readAccount: () => const GardenNewsAdminAccount('kakao-owner'),
        refreshClaims: (uid) async {
          expect(uid, 'kakao-owner');
          calls++;
          return {'garden_news_admin': granted};
        },
        accountChanges: const Stream.empty(),
        backendEnabled: () => true,
      );
      addTearDown(service.dispose);
      expect(service.canManage, isFalse);
      await service.refresh();
      expect(service.canManage, isTrue);
      granted = false;
      await service.refresh();
      expect(service.canManage, isFalse);
      expect(calls, 2);
    },
  );

  test(
    'token refresh failure does not keep a previously granted role',
    () async {
      var fail = false;
      final service = GardenNewsAdminService(
        readAccount: () => const GardenNewsAdminAccount('owner'),
        refreshClaims: (_) async {
          if (fail) throw StateError('offline');
          return {'garden_news_admin': true};
        },
        accountChanges: const Stream.empty(),
        backendEnabled: () => true,
      );
      addTearDown(service.dispose);
      await service.refresh();
      expect(service.canManage, isTrue);
      fail = true;
      await service.refresh();
      expect(service.canManage, isFalse);
    },
  );

  test(
    'anonymous users and disabled backend never request or expose role',
    () async {
      var account = const GardenNewsAdminAccount(
        'anonymous',
        isAnonymous: true,
      );
      var enabled = true;
      var requests = 0;
      final service = GardenNewsAdminService(
        readAccount: () => account,
        refreshClaims: (_) async {
          requests++;
          return {'garden_news_admin': true};
        },
        accountChanges: const Stream.empty(),
        backendEnabled: () => enabled,
      );
      addTearDown(service.dispose);
      await service.refresh();
      expect(service.canManage, isFalse);
      enabled = false;
      account = const GardenNewsAdminAccount('owner');
      await service.refresh();
      expect(service.canManage, isFalse);
      expect(requests, 0);
    },
  );

  test(
    'auth switch refreshes role and a late old token cannot grant access',
    () async {
      final changes = StreamController<String?>.broadcast(sync: true);
      GardenNewsAdminAccount? account = const GardenNewsAdminAccount(
        'old-owner',
      );
      final oldToken = Completer<Map<String, dynamic>>();
      final newToken = Completer<Map<String, dynamic>>();
      final service = GardenNewsAdminService(
        readAccount: () => account,
        refreshClaims: (uid) =>
            uid == 'old-owner' ? oldToken.future : newToken.future,
        accountChanges: changes.stream,
        backendEnabled: () => true,
      );
      addTearDown(() async {
        service.dispose();
        await changes.close();
      });
      final oldRequest = service.refresh();
      account = const GardenNewsAdminAccount('new-member');
      changes.add(account.uid);
      newToken.complete({});
      await Future<void>.delayed(Duration.zero);
      oldToken.complete({'garden_news_admin': true});
      await oldRequest;
      expect(service.canManage, isFalse);
    },
  );

  test(
    'signout immediately hides role and a newly signed in owner refreshes it',
    () async {
      final changes = StreamController<String?>.broadcast(sync: true);
      GardenNewsAdminAccount? account = const GardenNewsAdminAccount('owner');
      var calls = 0;
      final service = GardenNewsAdminService(
        readAccount: () => account,
        refreshClaims: (_) async {
          calls++;
          return {'garden_news_admin': true};
        },
        accountChanges: changes.stream,
        backendEnabled: () => true,
      );
      addTearDown(() async {
        service.dispose();
        await changes.close();
      });
      await service.refresh();
      expect(service.canManage, isTrue);
      account = null;
      expect(service.canManage, isFalse); // Safe even before stream delivery.
      changes.add(null);
      account = const GardenNewsAdminAccount('owner');
      changes.add(account.uid);
      expect(service.canManage, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(service.canManage, isTrue);
      expect(calls, 2);
    },
  );

  test('overlapping refreshes cannot revive revoked permissions', () async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    var calls = 0;
    final service = GardenNewsAdminService(
      readAccount: () => const GardenNewsAdminAccount('owner'),
      refreshClaims: (_) => ++calls == 1 ? first.future : second.future,
      accountChanges: const Stream.empty(),
      backendEnabled: () => true,
    );
    addTearDown(service.dispose);
    final firstRequest = service.refresh();
    final secondRequest = service.refresh();
    second.complete({'garden_news_admin': false});
    await secondRequest;
    first.complete({'garden_news_admin': true});
    await firstRequest;
    expect(service.canManage, isFalse);
  });
}
