import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/premium_screen.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

class _UnavailableStore extends InAppPurchasePlatform {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: const [],
    notFoundIDs: identifiers.toList(),
  );
}

void main() {
  setUpAll(() {
    // Set up the public billing adapter before selecting the UI platform.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchase.instance;
    InAppPurchasePlatform.instance = _UnavailableStore();
    debugDefaultTargetPlatformOverride = null;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SubscriptionService.debugIsPremiumOverride = false;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SubscriptionService.debugIsPremiumOverride = null;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(),
        child: const MaterialApp(home: PremiumScreen()),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
    'missing store product keeps Android purchase disabled with retry',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await open(tester);
      expect(
        SubscriptionService().hasProduct(SubscriptionPlan.yearly),
        isFalse,
      );
      final purchase = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '구독 상품 확인 필요'),
      );
      expect(purchase.onPressed, isNull);
      expect(find.text('구독 상품 다시 확인'), findsOneWidget);
      expect(find.text('광고 없이 편안하게'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('unsupported platform explains Android billing without restore', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await open(tester);
    final purchase = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Android 앱에서 이용'),
    );
    expect(purchase.onPressed, isNull);
    expect(
      find.text('구독 구매와 복원은 Google Play에서 설치한 Android 앱에서 이용할 수 있어요.'),
      findsOneWidget,
    );
    expect(find.text('구매 복원'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
