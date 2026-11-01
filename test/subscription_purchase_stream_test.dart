import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const monthly = SubscriptionService.monthlyProductId;
const yearly = SubscriptionService.yearlyProductId;

ProductDetails product(
  String id, {
  int? annualPrice,
  String? annualPeriod,
  bool trial = false,
}) {
  final isYearly = id == yearly;
  return GooglePlayProductDetails.fromProductDetails(
    ProductDetailsWrapper(
      description: id,
      name: id,
      productId: id,
      productType: ProductType.subs,
      title: id,
      subscriptionOfferDetails: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: isYearly ? 'annual' : 'monthly',
          offerTags: const [],
          offerIdToken: 'offer-$id',
          pricingPhases: [
            if (trial)
              const PricingPhaseWrapper(
                billingCycleCount: 1,
                billingPeriod: 'P7D',
                formattedPrice: '₩0',
                priceAmountMicros: 0,
                priceCurrencyCode: 'KRW',
                recurrenceMode: RecurrenceMode.finiteRecurring,
              ),
            PricingPhaseWrapper(
              billingCycleCount: 0,
              billingPeriod: isYearly ? (annualPeriod ?? 'P1Y') : 'P1M',
              formattedPrice: isYearly ? '₩${annualPrice ?? 29000}' : '₩4,900',
              priceAmountMicros:
                  (isYearly ? (annualPrice ?? 29000) : 4900) * 1000000,
              priceCurrencyCode: 'KRW',
              recurrenceMode: RecurrenceMode.infiniteRecurring,
            ),
          ],
        ),
      ],
    ),
  ).single;
}

class _StreamStore extends InAppPurchasePlatform {
  final updates = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  final buys = <PurchaseParam>[];
  List<ProductDetails>? offeredProducts;
  int queries = 0;
  final completed = <String>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queries++;
    return ProductDetailsResponse(
      productDetails: offeredProducts ?? [product(monthly), product(yearly)],
      notFoundIDs: const [],
    );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buys.add(purchaseParam);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase.verificationData.serverVerificationData);
  }
}

Future<void> flush() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _StreamStore store;
  late SubscriptionService service;
  late String? owner;
  late DateTime now;
  late Future<Map<String, dynamic>> Function(String, String) verify;
  late Future<String?> Function(String) cachedProduct;
  late Future<Map<String, dynamic>> Function(String) preflight;
  final verified = <String>[];

  PurchaseDetails receipt({
    String id = monthly,
    String token = 'new-receipt',
    PurchaseStatus status = PurchaseStatus.purchased,
    DateTime? time,
  }) => PurchaseDetails(
    productID: id,
    purchaseID: 'order-$token',
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: token,
      source: 'google_play',
    ),
    transactionDate: (time ?? now).millisecondsSinceEpoch.toString(),
    status: status,
  )..pendingCompletePurchase = true;

  SubscriptionService createService({
    Duration? timeout,
    Future<List<GooglePlayPurchaseDetails>> Function()? past,
  }) => SubscriptionService.forTesting(
    currentUid: () => owner,
    pastPurchases: past,
    accountId: (uid) async => 'hashed-$uid',
    verifyReceipt: (token, uid) {
      verified.add('$uid:$token');
      return verify(token, uid);
    },
    subscriptionProductId: (uid) => cachedProduct(uid),
    refreshEntitlement: (uid) => preflight(uid),
    purchaseTimeout: timeout ?? const Duration(seconds: 5),
  );

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchase.instance;
    store = _StreamStore();
    InAppPurchasePlatform.instance = store;
    SharedPreferences.setMockInitialValues({'premium_plan_type': 'yearly'});
    owner = 'alice';
    now = DateTime.utc(2026, 10, 18, 5);
    verified.clear();
    verify = (token, uid) async => {'active': true, 'productId': monthly};
    cachedProduct = (uid) async => uid == 'alice' ? monthly : yearly;
    preflight = (uid) async => {
      'active': false,
      'checkedAt': now.toIso8601String(),
    };
    service = createService();
    await service.init();
  });

  GooglePlayPurchaseDetails oldMonthly() =>
      GooglePlayPurchaseDetails.fromPurchase(
        PurchaseWrapper(
          orderId: 'old-order',
          packageName: 'com.mysticcat.journal',
          purchaseTime: now
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
          purchaseToken: 'old-monthly-token',
          signature: '',
          products: [monthly],
          isAutoRenewing: true,
          originalJson: '{}',
          isAcknowledged: true,
          purchaseState: PurchaseStateWrapper.purchased,
        ),
      ).single;

  test(
    'annual replacement verifies old owner and sends Play replacement parameters',
    () async {
      await service.dispose();
      service = createService(past: () async => [oldMonthly()]);
      await service.init();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      preflight = (_) async => {
        'active': true,
        'productId': monthly,
        'checkedAt': now.toIso8601String(),
      };
      verify = (token, _) async => {
        'active': true,
        'productId': token == 'old-monthly-token' ? monthly : yearly,
      };
      final future = service.purchasePremium(
        plan: SubscriptionPlan.yearly,
        replaceMonthly: true,
      );
      await flush();
      final param = store.buys.single as GooglePlayPurchaseParam;
      expect(
        param
            .changeSubscriptionParam!
            .oldPurchaseDetails
            .verificationData
            .serverVerificationData,
        'old-monthly-token',
      );
      expect(
        param.changeSubscriptionParam!.replacementMode,
        ReplacementMode.chargeFullPrice,
      );
      store.updates.add([receipt(id: yearly)]);
      expect(await future, true);
      expect(verified, contains('alice:old-monthly-token'));
    },
  );
  test(
    'replacement never purchases when old receipt belongs to another account',
    () async {
      await service.dispose();
      service = createService(past: () async => [oldMonthly()]);
      await service.init();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      preflight = (_) async => {
        'active': true,
        'productId': monthly,
        'checkedAt': now.toIso8601String(),
      };
      verify = (_, __) async =>
          throw const CloudException('purchase-owner-mismatch');
      await expectLater(
        service.purchasePremium(
          plan: SubscriptionPlan.yearly,
          replaceMonthly: true,
        ),
        throwsA(isA<CloudException>()),
      );
      expect(store.buys, isEmpty);
    },
  );
  test(
    'replacement does not report annual success when server still confirms only monthly',
    () async {
      await service.dispose();
      service = createService(past: () async => [oldMonthly()]);
      await service.init();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      preflight = (_) async => {
        'active': true,
        'productId': monthly,
        'checkedAt': now.toIso8601String(),
      };
      final future = service.purchasePremium(
        plan: SubscriptionPlan.yearly,
        replaceMonthly: true,
      );
      await flush();
      store.updates.add([receipt(id: yearly)]);
      expect(await future, false);
    },
  );

  tearDown(() async {
    await service.dispose();
    await store.updates.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'annual price changes and a seven-day trial remain purchasable',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      store.offeredProducts = [
        product(monthly),
        product(yearly, annualPrice: 55000, annualPeriod: 'P12M', trial: true),
      ];
      await service.refreshProducts();
      expect(service.hasProduct(SubscriptionPlan.yearly), isTrue);
      expect(service.priceLabelFor(SubscriptionPlan.yearly), contains('55000'));
      expect(
        service.offerLabelFor(SubscriptionPlan.yearly),
        contains('7일 무료체험'),
      );
      expect(
        service.offerLabelFor(SubscriptionPlan.yearly),
        isNot(contains('15일')),
      );
      verify = (token, uid) async => {'active': true, 'productId': yearly};
      final result = service.purchasePremium(plan: SubscriptionPlan.yearly);
      await flush();
      expect(store.buys.single.productDetails.id, yearly);
      expect(
        (store.buys.single as GooglePlayPurchaseParam).offerToken,
        'offer-$yearly',
      );
      store.updates.add([receipt(id: yearly)]);
      expect(await result, isTrue);
      expect(verified, ['alice:new-receipt']);
    },
  );

  test(
    'missing annual product is queried again even when monthly is loaded',
    () async {
      store.offeredProducts = [product(monthly)];
      await service.refreshProducts();
      expect(service.hasProduct(SubscriptionPlan.yearly), isFalse);
      final before = store.queries;
      store.offeredProducts = [product(monthly), product(yearly)];
      final result = service.purchasePremium(plan: SubscriptionPlan.yearly);
      await flush();
      expect(store.queries, before + 1);
      expect(store.buys.single.productDetails.id, yearly);
      store.updates.add([receipt(id: yearly, status: PurchaseStatus.canceled)]);
      expect(await result, isFalse);
    },
  );

  test(
    'management opens directly, falls back to the list, and reports total failure',
    () async {
      final opened = <Uri>[];
      var succeed = true;
      final management = SubscriptionService.forTesting(
        currentUid: () => owner,
        
        accountId: (uid) async => uid,
        verifyReceipt: (token, uid) => verify(token, uid),
        subscriptionProductId: (uid) => cachedProduct(uid),
        refreshEntitlement: (uid) => preflight(uid),
        openManagementUrl: (uri) async {
          opened.add(uri);
          return succeed && !uri.hasQuery;
        },
      );
      await management.cancelPremium();
      expect(opened, hasLength(2));
      expect(opened.first.queryParameters['sku'], monthly);
      expect(opened.last.queryParameters, isEmpty);
      succeed = false;
      await expectLater(management.cancelPremium(), throwsStateError);
      opened.clear();
      owner = null;
      await expectLater(
        management.cancelPremium(),
        throwsA(isA<CloudException>()),
      );
      expect(opened, isEmpty);
      await management.dispose();
    },
  );

  test(
    'new purchase is verified for its owner before acknowledgement and success',
    () async {
      final server = Completer<Map<String, dynamic>>();
      verify = (_, __) => server.future;
      bool? result;
      final buying = service.purchasePremium().then((v) => result = v);
      await flush();
      expect(store.buys.single.applicationUserName, 'hashed-alice');
      store.updates.add([receipt()]);
      await flush();
      expect(verified, ['alice:new-receipt']);
      expect(store.completed, isEmpty);
      expect(result, isNull);
      server.complete({'active': true, 'productId': monthly});
      await buying;
      expect(result, isTrue);
      expect(store.completed, ['new-receipt']);
    },
  );

  test(
    'unrelated product, restored receipt and old purchase cannot finish a new buy',
    () async {
      bool? result;
      final buying = service.purchasePremium().then((v) => result = v);
      await flush();
      store.updates.add([
        receipt(id: yearly, token: 'yearly-other'),
        receipt(token: 'restored', status: PurchaseStatus.restored),
        receipt(token: 'old', time: now.subtract(const Duration(days: 1))),
      ]);
      await flush();
      expect(verified.length, 3);
      expect(result, isNull);
      store.updates.add([receipt()]);
      await buying;
      expect(result, isTrue);
    },
  );

  test(
    'a previously observed token cannot masquerade as a new receipt',
    () async {
      store.updates.add([
        receipt(token: 'existing', status: PurchaseStatus.restored),
      ]);
      await flush();
      bool? result;
      final buying = service.purchasePremium().then((v) => result = v);
      await flush();
      store.updates.add([receipt(token: 'existing')]);
      await flush();
      expect(result, isNull);
      store.updates.add([receipt(token: 'genuinely-new')]);
      await buying;
      expect(result, isTrue);
    },
  );

  test(
    'account change while verification is in flight does not acknowledge or succeed',
    () async {
      final server = Completer<Map<String, dynamic>>();
      verify = (_, __) => server.future;
      final buying = service.purchasePremium();
      await flush();
      store.updates.add([receipt()]);
      await flush();
      owner = 'bob';
      server.complete({'active': true, 'productId': monthly});
      expect(await buying, isFalse);
      expect(store.completed, isEmpty);
    },
  );

  test(
    'a queued event from a timed-out attempt cannot complete a newer attempt',
    () async {
      await service.dispose();
      service = createService(timeout: const Duration(milliseconds: 100));
      await service.init();
      final firstVerification = Completer<Map<String, dynamic>>();
      verify = (token, _) => token == 'first'
          ? firstVerification.future
          : Future.value({'active': true, 'productId': monthly});
      final first = service.purchasePremium();
      await flush();
      store.updates.add([receipt(token: 'first')]);
      store.updates.add([
        receipt(token: 'old-cancel', status: PurchaseStatus.canceled),
      ]);
      expect(await first, isFalse);
      now = now.add(const Duration(seconds: 5));
      bool? result;
      final second = service.purchasePremium().then((v) => result = v);
      await flush();
      firstVerification.complete({'active': true, 'productId': monthly});
      await flush();
      expect(result, isNull);
      store.updates.add([receipt(token: 'second')]);
      await second;
      expect(result, isTrue);
    },
  );

  test(
    'inactive server result is not acknowledged as a delivered purchase',
    () async {
      verify = (_, __) async => {'active': false, 'productId': monthly};
      final buying = service.purchasePremium();
      await flush();
      store.updates.add([receipt()]);
      expect(await buying, isFalse);
      expect(store.completed, isEmpty);
    },
  );

  test(
    'verification error leaves receipt incomplete for a later retry',
    () async {
      verify = (_, __) async =>
          throw const CloudException('temporarily-unavailable');
      final buying = service.purchasePremium();
      await flush();
      store.updates.add([receipt()]);
      expect(await buying, isFalse);
      expect(store.completed, isEmpty);
    },
  );

  test(
    'Play cancellation without product metadata ends the captured flow without granting',
    () async {
      final buying = service.purchasePremium();
      await flush();
      store.updates.add([
        PurchaseDetails(
          productID: '',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'google_play',
          ),
          transactionDate: null,
          status: PurchaseStatus.canceled,
        ),
      ]);
      expect(await buying, isFalse);
      expect(verified, isEmpty);
      expect(store.completed, isEmpty);
    },
  );

  test('repeated purchase taps launch only one store flow', () async {
    final first = service.purchasePremium();
    final second = service.purchasePremium();
    await flush();
    expect(store.buys, hasLength(1));
    store.updates.add([receipt()]);
    expect(await first, isTrue);
    expect(await second, isFalse);
  });

  test(
    'plan and management URL follow current account rather than legacy preference',
    () async {
      expect(await service.currentPlanIfKnown(), SubscriptionPlan.monthly);
      expect(
        (await service.subscriptionManagementUri()).queryParameters['sku'],
        monthly,
      );
      owner = 'bob';
      expect(await service.currentPlanIfKnown(), SubscriptionPlan.yearly);
      expect(
        (await service.subscriptionManagementUri()).queryParameters['sku'],
        yearly,
      );
      cachedProduct = (_) async => null;
      expect(await service.currentPlanIfKnown(), isNull);
      expect(
        (await service.subscriptionManagementUri()).queryParameters,
        isEmpty,
      );
    },
  );

  test(
    'account switching during plan read rejects the previous account result',
    () async {
      final pending = Completer<String?>();
      cachedProduct = (_) => pending.future;
      final plan = service.currentPlanIfKnown();
      owner = 'bob';
      pending.complete(yearly);
      await expectLater(
        plan,
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
    },
  );

  for (final offset in [-60, 60]) {
    test(
      'server receipt completes with phone clock offset ${-offset} seconds',
      () async {
        // The actual device wall clock differs from both trusted server time and
        // Play's purchaseTime. Matching must use the fresh server response.
        final serverTime = DateTime.now().toUtc().add(
          Duration(seconds: offset),
        );
        preflight = (uid) async => {
          'active': false,
          'checkedAt': serverTime.toIso8601String(),
        };
        final buying = service.purchasePremium();
        await flush();
        store.updates.add([
          receipt(time: serverTime.add(const Duration(seconds: 2))),
        ]);
        expect(await buying, isTrue);
        expect(store.completed, ['new-receipt']);
      },
    );
  }

  test(
    'missing or invalid trusted server time fails before Play launch',
    () async {
      for (final value in [null, 'not-a-time', '2026-10-18T05:00:00']) {
        preflight = (uid) async => {'active': false, 'checkedAt': value};
        await expectLater(
          service.purchasePremium(),
          throwsA(
            isA<CloudException>().having(
              (e) => e.code,
              'code',
              'subscription-check-unavailable',
            ),
          ),
        );
      }
      expect(store.buys, isEmpty);
    },
  );

  test('account change during preflight prevents store launch', () async {
    final pending = Completer<Map<String, dynamic>>();
    preflight = (uid) {
      expect(uid, 'alice');
      return pending.future;
    };
    final buying = service.purchasePremium();
    await flush();
    owner = 'bob';
    pending.complete({'active': false, 'checkedAt': now.toIso8601String()});
    await expectLater(
      buying,
      throwsA(
        isA<CloudException>().having((e) => e.code, 'code', 'account-changed'),
      ),
    );
    expect(store.buys, isEmpty);
  });

  test(
    'fresh active entitlement blocks a second subscription purchase',
    () async {
      preflight = (uid) async => {
        'active': true,
        'productId': yearly,
        'checkedAt': now.toIso8601String(),
      };
      await expectLater(
        service.purchasePremium(),
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'subscription-already-active',
          ),
        ),
      );
      expect(store.buys, isEmpty);
    },
  );
}
