import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

class _PendingPurchasePlatform extends InAppPurchasePlatform {
  _PendingPurchasePlatform() {
    updates = StreamController<List<PurchaseDetails>>.broadcast(
      onListen: () => listeners++,
    );
  }

  final availability = Completer<bool>();
  final products = Completer<ProductDetailsResponse>();
  late final StreamController<List<PurchaseDetails>> updates;
  int availabilityChecks = 0;
  int productQueries = 0;
  int listeners = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() {
    availabilityChecks++;
    return availability.future;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    productQueries++;
    expect(identifiers, {
      SubscriptionService.monthlyProductId,
      SubscriptionService.yearlyProductId,
    });
    return products.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = SubscriptionService();
  late _PendingPurchasePlatform platform;

  setUp(() async {
    // The facade's first access must not replace the fake with a mobile plugin.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchase.instance;
    await service.dispose();
    platform = _PendingPurchasePlatform();
    InAppPurchasePlatform.instance = platform;
  });

  tearDown(() async {
    await service.dispose();
    await platform.updates.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'concurrent initialization waits for one connection and product query',
    () async {
      var completed = 0;
      final first = service.init().then((_) => completed++);
      final second = service.init().then((_) => completed++);
      await Future<void>.delayed(Duration.zero);
      expect(completed, 0);
      expect(platform.availabilityChecks, 1);
      expect(platform.productQueries, 0);

      platform.availability.complete(true);
      await Future<void>.delayed(Duration.zero);
      final third = service.init().then((_) => completed++);
      expect(completed, 0);
      expect(platform.listeners, 1);
      expect(platform.productQueries, 1);

      platform.products.complete(
        ProductDetailsResponse(productDetails: const [], notFoundIDs: const []),
      );
      await Future.wait([first, second, third]);
      expect(completed, 3);
      await service.init();
      expect(platform.availabilityChecks, 1);
      expect(platform.listeners, 1);
      expect(platform.productQueries, 1);
    },
  );

  test(
    'an unavailable store can be checked again on a later initialization',
    () async {
      platform.availability.complete(false);
      await service.init();
      await service.init();
      expect(platform.availabilityChecks, 2);
      expect(platform.listeners, 0);
      expect(platform.productQueries, 0);
    },
  );
}
