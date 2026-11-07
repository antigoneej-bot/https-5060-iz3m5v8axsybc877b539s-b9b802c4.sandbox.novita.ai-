import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/providers/promise_provider.dart';
import 'package:flutter_app/screens/premium_screen.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_app/services/cloud_service.dart';

class _Billing extends PremiumScreenBilling {
  String? owner = 'account-a';
  bool premium = false;
  SubscriptionPlan plan = SubscriptionPlan.monthly;
  Future<bool> Function()? readPremium;
  Future<SubscriptionPlan?> Function()? readPlan;
  Future<String> Function()? readStatus;
  Future<bool> Function()? signIn;
  final purchaseResult = Completer<bool>();
  final restoreResult = Completer<SubscriptionRestoreResult>();
  final analyticsResult = Completer<void>();
  final purchasedPlans = <SubscriptionPlan>[];
  final loggedPlans = <SubscriptionPlan>[];
  int restoreCalls = 0;
  int managementCalls = 0, statusRefreshCalls = 0;
  Future<void> Function()? openManagement;
  Future<void> Function()? refreshServer;
  @override
  Future<void> cancel() async {
    managementCalls++;
    await openManagement?.call();
  }

  @override
  Future<void> refreshStatus(String owner) async {
    statusRefreshCalls++;
    await refreshServer?.call();
  }

  @override
  String? get currentUid => owner;
  @override
  bool get backendEnabled => true;
  @override
  bool get supportedStore => true;
  @override
  bool hasProduct(SubscriptionPlan plan) => true;
  @override
  Future<void> refreshProducts() async {}
  @override
  Future<bool> isPremium() => readPremium?.call() ?? Future.value(premium);
  @override
  Future<SubscriptionPlan?> currentPlan() =>
      readPlan?.call() ?? Future.value(plan);
  @override
  Future<String> statusLabel() =>
      readStatus?.call() ?? Future.value(premium ? '구독 이용 중' : '무료 이용 중');
  @override
  Future<bool> ensureSignedIn(BuildContext context) =>
      signIn?.call() ?? Future.value(true);
  @override
  Future<bool> purchase(SubscriptionPlan plan) {
    purchasedPlans.add(plan);
    return purchaseResult.future;
  }

  @override
  Future<SubscriptionRestoreResult> restore() {
    restoreCalls++;
    return restoreResult.future;
  }

  @override
  Future<void> logPurchase(SubscriptionPlan plan) {
    loggedPlans.add(plan);
    return analyticsResult.future;
  }
}

void main() {
  late AppStateProvider app;
  late CatCareProvider care;
  late PromiseProvider promise;
  late GardenProvider garden;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    app = AppStateProvider();
    care = CatCareProvider();
    promise = PromiseProvider();
    garden = GardenProvider();
  });

  Future<void> open(WidgetTester tester, _Billing billing) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: care),
          ChangeNotifierProvider.value(value: promise),
          ChangeNotifierProvider.value(value: garden),
        ],
        child: MaterialApp(home: PremiumScreen(billing: billing)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pump();
  }

  void expectAccess(bool active) {
    expect(app.isPremiumUser, active);
    expect(care.isPremium, active);
    expect(promise.isPremium, active);
  }

  testWidgets(
    'return from Play shows cancelled-but-paid state without revoking access',
    (tester) async {
      final billing = _Billing()..premium = true;
      await open(tester, billing);
      await tap(tester, '멤버십 해지하기');
      expect(billing.managementCalls, 1);
      expect(billing.statusRefreshCalls, 0);
      billing.readStatus = () async => '해지 예약 · 남은 이용 기간까지 사용 가능';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(billing.statusRefreshCalls, 1);
      expect(find.text('해지 예약 · 남은 이용 기간까지 사용 가능'), findsOneWidget);
      expectAccess(true);
      // On eventual expiration, a verified refresh removes access.
      billing.premium = false;
      billing.readStatus = () async => '구독 만료 · 기록과 아이템은 보관돼요';
      await tap(tester, '구독 상태 다시 확인');
      await tester.pump();
      expectAccess(false);
      expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
    },
  );

  testWidgets(
    'failed management launch is visible and does not say cancelled',
    (tester) async {
      final billing = _Billing()..premium = true;
      billing.openManagement = () async => throw StateError('no browser');
      await open(tester, billing);
      await tap(tester, '멤버십 해지하기');
      await tester.pump();
      expect(find.textContaining('구독 관리 화면을 열지 못했어요.'), findsOneWidget);
      expect(find.text('현재 이용 중 ✓ (월간)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh failure preserves access and stale account result cannot grant it',
    (tester) async {
      final billing = _Billing()..premium = true;
      await open(tester, billing);
      app.setAccountPremium(true);
      care.setAccountPremium(true);
      promise.setAccountPremium(true);
      billing.refreshServer = () async => throw StateError('offline');
      await tap(tester, '구독 상태 다시 확인');
      await tester.pump();
      expectAccess(true);
      expect(find.textContaining('최신 구독 상태를 확인하지 못했어요.'), findsOneWidget);
      final refresh = Completer<void>();
      billing.refreshServer = () => refresh.future;
      await tap(tester, '구독 상태 다시 확인');
      billing.owner = 'account-b';
      billing.premium = false;
      app.setAccountPremium(false);
      care.setAccountPremium(false);
      promise.setAccountPremium(false);
      refresh.complete();
      await tester.pump();
      await tester.pump();
      expectAccess(false);
      expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
    },
  );

  testWidgets(
    'purchase locks account and plan; access does not await analytics',
    (tester) async {
      final billing = _Billing();
      await open(tester, billing);
      await tap(tester, '월간');
      await tap(tester, '마음냥 구독 시작하기');
      expect(billing.purchasedPlans, [SubscriptionPlan.monthly]);
      final account = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '간편 로그인 · 구매 계정 관리'),
      );
      final restore = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, '구매 복원'),
      );
      expect(account.onPressed, isNull);
      expect(restore.onPressed, isNull);
      await tap(tester, '연간');
      billing.premium = true;
      billing.purchaseResult.complete(true);
      await tester.pump();
      await tester.pump();
      expectAccess(true);
      expect(billing.loggedPlans, [SubscriptionPlan.monthly]);
      expect(billing.analyticsResult.isCompleted, isFalse);
      expect(find.text('현재 이용 중 ✓ (월간)'), findsOneWidget);
      // Optional analytics failing later must neither undo nor re-grant access.
      app.setAccountPremium(false);
      care.setAccountPremium(false);
      promise.setAccountPremium(false);
      billing.owner = 'account-b';
      billing.analyticsResult.completeError(
        StateError('analytics unavailable'),
      );
      await tester.pump();
      expectAccess(false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'already-active preflight reloads verified state without purchase success',
    (tester) async {
      final billing = _Billing();
      await open(tester, billing);
      await tap(tester, '마음냥 구독 시작하기');
      // Mimic the preflight writing the current server snapshot before refusing
      // to launch a duplicate store purchase.
      billing.premium = true;
      billing.plan = SubscriptionPlan.yearly;
      billing.purchaseResult.completeError(
        const CloudException('subscription-already-active'),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('현재 이용 중 ✓ (연간)'), findsOneWidget);
      expect(
        find.text(
          const CloudException('subscription-already-active').toString(),
        ),
        findsOneWidget,
      );
      expect(find.text('마음냥 구독 멤버십이 시작되었어요 🌷'), findsNothing);
      expect(billing.loggedPlans, isEmpty);
      expectAccess(false); // Exception alone did not call any provider grant.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unavailable preflight gives retry guidance without granting access',
    (tester) async {
      final billing = _Billing();
      await open(tester, billing);
      await tap(tester, '마음냥 구독 시작하기');
      billing.purchaseResult.completeError(
        const CloudException('subscription-check-unavailable'),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.text(
          const CloudException('subscription-check-unavailable').toString(),
        ),
        findsOneWidget,
      );
      expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
      expect(find.text('현재 이용 중 ✓ (월간)'), findsNothing);
      expect(billing.loggedPlans, isEmpty);
      expectAccess(false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('old account purchase result cannot grant the next account', (
    tester,
  ) async {
    final billing = _Billing();
    await open(tester, billing);
    await tap(tester, '마음냥 구독 시작하기');
    billing.owner = 'account-b';
    billing.purchaseResult.complete(true);
    await tester.pump();
    await tester.pump();
    expectAccess(false);
    expect(billing.loggedPlans, isEmpty);
    expect(find.text('현재 이용 중 ✓ (연간)'), findsNothing);
    expect(find.text('마음냥 구독 멤버십이 시작되었어요 🌷'), findsNothing);
    expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
  });

  testWidgets('account change during post-purchase status lookup is guarded', (
    tester,
  ) async {
    final billing = _Billing();
    await open(tester, billing);
    final status = Completer<String>();
    billing.readStatus = () => status.future;
    await tap(tester, '마음냥 구독 시작하기');
    billing.purchaseResult.complete(true);
    await tester.pump();
    billing.owner = 'account-b';
    billing.readStatus = () async => '무료 이용 중';
    status.complete('account-a paid yearly');
    await tester.pump();
    await tester.pump();
    expectAccess(false);
    expect(find.text('account-a paid yearly'), findsNothing);
    expect(billing.loggedPlans, isEmpty);
    expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
  });

  testWidgets(
    'cancelled new purchase does not revoke existing provider access',
    (tester) async {
      final billing = _Billing();
      await open(tester, billing);
      await tap(tester, '마음냥 구독 시작하기');
      // A verified entitlement can arrive through the account bridge while this
      // separate purchase is waiting for Play. Cancelling must leave it intact.
      app.setAccountPremium(true);
      care.setAccountPremium(true);
      promise.setAccountPremium(true);
      garden.setAccountPremium(true);
      billing.purchaseResult.complete(false);
      await tester.pump();
      expectAccess(true);
      expect(billing.loggedPlans, isEmpty);
      expect(find.text('구매가 완료되지 않았어요. 잠시 후 다시 확인해 주세요.'), findsOneWidget);
    },
  );

  testWidgets('restore stays locked and discards result after account switch', (
    tester,
  ) async {
    final billing = _Billing();
    await open(tester, billing);
    final plan = Completer<SubscriptionPlan>();
    billing.readPlan = () => plan.future;
    await tap(tester, '구매 복원');
    expect(billing.restoreCalls, 1);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, '간편 로그인 · 구매 계정 관리'),
          )
          .onPressed,
      isNull,
    );
    billing.restoreResult.complete(
      const SubscriptionRestoreResult(
        SubscriptionRestoreStatus.restored,
        active: true,
      ),
    );
    await tester.pump();
    billing.owner = 'account-b';
    billing.readPlan = () async => SubscriptionPlan.monthly;
    plan.complete(SubscriptionPlan.yearly);
    await tester.pump();
    await tester.pump();
    expectAccess(false);
    expect(find.text('구독을 복원했어요. 이용 권한을 다시 확인했어요.'), findsNothing);
    expect(find.text('현재 이용 중 ✓ (연간)'), findsNothing);
    expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
  });

  testWidgets('unavailable restore preserves access refreshed while waiting', (
    tester,
  ) async {
    final billing = _Billing();
    await open(tester, billing);
    await tap(tester, '구매 복원');
    app.setAccountPremium(true);
    care.setAccountPremium(true);
    promise.setAccountPremium(true);
    garden.setAccountPremium(true);
    billing.restoreResult.complete(
      const SubscriptionRestoreResult(SubscriptionRestoreStatus.unavailable),
    );
    await tester.pump();
    expectAccess(true);
    expect(find.text('구독을 복원했어요. 이용 권한을 다시 확인했어요.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late initial entitlement load never paints a switched account', (
    tester,
  ) async {
    final billing = _Billing();
    final oldPremium = Completer<bool>();
    billing.readPremium = () => oldPremium.future;
    await open(tester, billing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    billing.owner = 'account-b';
    billing.readPremium = () async => false;
    oldPremium.complete(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('현재 이용 중 ✓ (월간)'), findsNothing);
    expect(find.text('마음냥 구독 시작하기'), findsOneWidget);
    expectAccess(false);
  });

  testWidgets('premium with unknown plan does not claim a monthly purchase', (
    tester,
  ) async {
    final billing = _Billing()..premium = true;
    billing.readPlan = () async => null;
    await open(tester, billing);
    expect(find.text('현재 이용 중 ✓'), findsOneWidget);
    expect(find.text('현재 이용 중 ✓ (월간)'), findsNothing);
    expect(find.text('현재 이용 중 ✓ (연간)'), findsNothing);
  });

  testWidgets('sign-in cancellation unlocks controls without a store request', (
    tester,
  ) async {
    final billing = _Billing();
    final signIn = Completer<bool>();
    billing.signIn = () => signIn.future;
    await open(tester, billing);
    await tap(tester, '마음냥 구독 시작하기');
    expect(billing.purchasedPlans, isEmpty);
    signIn.complete(false);
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, '간편 로그인 · 구매 계정 관리'),
          )
          .onPressed,
      isNotNull,
    );
    expect(billing.purchasedPlans, isEmpty);
    expectAccess(false);
  });
}
