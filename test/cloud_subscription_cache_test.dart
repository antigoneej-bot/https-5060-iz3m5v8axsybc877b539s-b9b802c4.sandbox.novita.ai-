// The platform interfaces are installed transitively by the Firebase plugins.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Only the plugin boundaries are replaced. Tests below call the real cache
// methods, including their asynchronous storage read and current-user checks.
class _Firebase extends FirebasePlatform {
  bool initialized = true;
  final defaultApp = FirebaseAppPlatform(
    '[DEFAULT]',
    const FirebaseOptions(
      apiKey: 'test-only',
      appId: 'test-only',
      messagingSenderId: 'test-only',
      projectId: 'subscription-cache-test',
    ),
  );

  @override
  List<FirebaseAppPlatform> get apps => initialized ? [defaultApp] : [];

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) => defaultApp;
}

class _Auth extends FirebaseAuthPlatform {
  UserPlatform? user;

  void signIn(String? uid) => user = uid == null ? null : _User(this, uid);

  @override
  UserPlatform? get currentUser => user;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;
}

class _MultiFactor extends MultiFactorPlatform {
  _MultiFactor(super.auth);
}

class _User extends UserPlatform {
  _User(FirebaseAuthPlatform auth, String uid)
    : super(
        auth,
        _MultiFactor(auth),
        PigeonUserDetails(
          userInfo: PigeonUserInfo(
            uid: uid,
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: [],
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final firebase = _Firebase();
  final auth = _Auth();
  final records = <String, String>{};
  final readKeys = <String>[];
  late FirebasePlatform originalFirebase;
  late FirebaseAuthPlatform originalAuth;
  Completer<void>? readStarted;
  Completer<void>? releaseRead;

  Map<String, Object?> entitlement({String sku = 'garden_plus_monthly'}) {
    final now = DateTime.now().toUtc();
    return {
      'active': true,
      'productId': sku,
      'checkedAt': now.subtract(const Duration(minutes: 1)).toIso8601String(),
      'expiresAt': now.add(const Duration(days: 5)).toIso8601String(),
    };
  }

  final accountChanged = throwsA(
    isA<CloudException>().having(
      (error) => error.code,
      'code',
      'account-changed',
    ),
  );

  setUpAll(() {
    originalFirebase = FirebasePlatform.instance;
    originalAuth = FirebaseAuthPlatform.instance;
    FirebasePlatform.instance = firebase;
    FirebaseAuthPlatform.instance = auth;
  });

  setUp(() {
    firebase.initialized = true;
    auth.signIn('account-a');
    records.clear();
    readKeys.clear();
    readStarted = null;
    releaseRead = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (call) async {
          // A cache read must never mutate storage or silently clear another
          // account's entitlement.
          expect(call.method, 'read');
          final key = (call.arguments as Map)['key'] as String;
          readKeys.add(key);
          final savedValue = records[key];
          readStarted?.complete();
          await releaseRead?.future;
          return savedValue;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null);
  });

  tearDownAll(() {
    FirebasePlatform.instance = originalFirebase;
    FirebaseAuthPlatform.instance = originalAuth;
  });

  test(
    'ads distinguish verified free from missing, expired-active and stale cache',
    () async {
      expect(await CloudService.cachedAdFreeEntitlement(), isNull);
      records['entitlement_account-a'] = 'broken';
      expect(await CloudService.cachedAdFreeEntitlement(), isNull);
      records['entitlement_account-a'] = jsonEncode(entitlement());
      expect(await CloudService.cachedAdFreeEntitlement(), isTrue);
      final expiredActive = entitlement()
        ..['expiresAt'] = DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String();
      records['entitlement_account-a'] = jsonEncode(expiredActive);
      expect(await CloudService.cachedAdFreeEntitlement(), isNull);
      final free = entitlement()
        ..['active'] = false
        ..['state'] = 'free';
      records['entitlement_account-a'] = jsonEncode(free);
      expect(await CloudService.cachedAdFreeEntitlement(), isFalse);
      free['checkedAt'] = DateTime.now()
          .subtract(const Duration(hours: 49))
          .toIso8601String();
      records['entitlement_account-a'] = jsonEncode(free);
      expect(await CloudService.cachedAdFreeEntitlement(), isNull);
    },
  );

  test(
    'ad eligibility cannot accept a cache read from a previous account',
    () async {
      records['entitlement_account-a'] = jsonEncode(
        entitlement()..['active'] = false,
      );
      readStarted = Completer<void>();
      releaseRead = Completer<void>();
      final pending = CloudService.cachedAdFreeEntitlement();
      await readStarted!.future;
      auth.signIn('account-b');
      releaseRead!.complete();
      expect(await pending, isNull);
    },
  );

  test(
    'cancellation shows paid-through deadline and preserves current access',
    () async {
      if (!CloudService.enabled) return;
      final entry = entitlement()..['state'] = 'cancelScheduled';
      records['entitlement_account-a'] = jsonEncode(entry);
      expect(await CloudService.cachedPremium(), isTrue);
      final expiry = DateTime.parse(entry['expiresAt']! as String).toLocal();
      final label = await CloudService.subscriptionStatusLabel();
      expect(label, contains('해지 예약'));
      expect(label, contains('${expiry.year}.${expiry.month}.${expiry.day}'));
      expect(label, contains('까지 이용 가능'));
    },
  );

  test(
    'monthly and yearly caches follow the signed-in UID on each read',
    () async {
      records['entitlement_account-a'] = jsonEncode(entitlement());
      records['entitlement_account-b'] = jsonEncode(
        entitlement(sku: 'garden_plus_yearly'),
      );

      expect(
        await CloudService.cachedSubscriptionProductId(),
        'garden_plus_monthly',
      );
      expect(await CloudService.cachedPremium(), isTrue);
      auth.signIn('account-b');
      expect(
        await CloudService.cachedSubscriptionProductId(),
        'garden_plus_yearly',
      );
      expect(await CloudService.cachedPremium(), isTrue);
      expect(readKeys, [
        'entitlement_account-a',
        'entitlement_account-a',
        'entitlement_account-b',
        'entitlement_account-b',
      ]);
    },
  );

  test(
    'an account without cache cannot inherit the previous account plan',
    () async {
      records['entitlement_account-a'] = jsonEncode(entitlement());
      expect(await CloudService.cachedPremium(), isTrue);
      auth.signIn('account-b');
      expect(await CloudService.cachedSubscriptionProductId(), isNull);
      expect(await CloudService.cachedPremium(), isFalse);
      expect(records.containsKey('entitlement_account-a'), isTrue);
    },
  );

  test(
    'signed-out user reads no entitlement even when old cache exists',
    () async {
      records['entitlement_account-a'] = jsonEncode(entitlement());
      auth.signIn(null);
      expect(await CloudService.cachedSubscriptionProductId(), isNull);
      expect(await CloudService.cachedPremium(), isFalse);
      expect(readKeys, isEmpty);
    },
  );

  test(
    'Firebase not initialized returns no plan without storage access',
    () async {
      firebase.initialized = false;
      expect(await CloudService.cachedSubscriptionProductId(), isNull);
      expect(await CloudService.cachedPremium(), isFalse);
      expect(readKeys, isEmpty);
    },
  );

  test(
    'explicit owner mismatch is rejected before reading either cache',
    () async {
      records['entitlement_account-b'] = jsonEncode(entitlement());
      await expectLater(
        CloudService.cachedSubscriptionProductId(expectedUid: 'account-b'),
        accountChanged,
      );
      expect(readKeys, isEmpty);
    },
  );

  for (final kind in [
    'missing',
    'invalid JSON',
    'JSON list',
    'JSON null',
    'inactive',
    'non-boolean active',
    'missing check time',
    'invalid check time',
    'missing expiry',
    'invalid expiry',
    'expired',
    'stale',
    'future check time',
  ]) {
    test('$kind entitlement cannot enable premium or select a plan', () async {
      final record = entitlement();
      switch (kind) {
        case 'inactive':
          record['active'] = false;
        case 'non-boolean active':
          record['active'] = 'true';
        case 'missing check time':
          record.remove('checkedAt');
        case 'invalid check time':
          record['checkedAt'] = 'not-a-date';
        case 'missing expiry':
          record.remove('expiresAt');
        case 'invalid expiry':
          record['expiresAt'] = 'not-a-date';
        case 'expired':
          record['expiresAt'] = DateTime.now()
              .subtract(const Duration(minutes: 1))
              .toIso8601String();
        case 'stale':
          record['checkedAt'] = DateTime.now()
              .subtract(const Duration(hours: 49))
              .toIso8601String();
        case 'future check time':
          record['checkedAt'] = DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String();
      }
      if (kind != 'missing') {
        records['entitlement_account-a'] = switch (kind) {
          'invalid JSON' => '{',
          'JSON list' => '[]',
          'JSON null' => 'null',
          _ => jsonEncode(record),
        };
      }
      expect(await CloudService.cachedSubscriptionProductId(), isNull);
      expect(await CloudService.cachedPremium(), isFalse);
    });
  }

  test('unrecognized or absent SKU cannot select a purchasable plan', () async {
    for (final sku in ['garden_premium_legacy', '', null, 123]) {
      records['entitlement_account-a'] = jsonEncode({
        ...entitlement(),
        'productId': sku,
      });
      expect(await CloudService.cachedSubscriptionProductId(), isNull);
    }
  });

  for (final useExpectedUid in [false, true]) {
    test(
      'plan read rejects an in-flight account switch (explicit owner: $useExpectedUid)',
      () async {
        records['entitlement_account-a'] = jsonEncode(entitlement());
        readStarted = Completer<void>();
        releaseRead = Completer<void>();
        final result = CloudService.cachedSubscriptionProductId(
          expectedUid: useExpectedUid ? 'account-a' : null,
        );
        final assertion = expectLater(result, accountChanged);
        await readStarted!.future;
        auth.signIn('account-b');
        releaseRead!.complete();
        await assertion;
        expect(readKeys, ['entitlement_account-a']);
      },
    );
  }

  for (final nextUid in ['account-b', null]) {
    test(
      'premium stays false when account changes to $nextUid during storage read',
      () async {
        records['entitlement_account-a'] = jsonEncode(entitlement());
        readStarted = Completer<void>();
        releaseRead = Completer<void>();
        final result = CloudService.cachedPremium();
        await readStarted!.future;
        auth.signIn(nextUid);
        releaseRead!.complete();
        expect(await result, isFalse);
        expect(readKeys, ['entitlement_account-a']);
      },
    );
  }
}
