import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/feature_flags.dart';
import 'package:flutter_app/widgets/premium_test_access.dart';
import 'package:flutter_app/services/subscription_service.dart';

void main() {
  final original = FeatureFlags.debugUnlockAllPremium;
  tearDown(() => FeatureFlags.debugUnlockAllPremium = original);
  test('test build grants feature access without purchase', () async {
    FeatureFlags.debugUnlockAllPremium = true;
    expect(await SubscriptionService().isPremium(), true);
  });
  testWidgets('test banner is visible only in test mode', (tester) async {
    FeatureFlags.debugUnlockAllPremium = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: PremiumTestFrame(child: Scaffold(body: Text('정원'))),
      ),
    );
    expect(find.text(MembershipFeatures.testLabel), findsOneWidget);
    expect(find.text('정원'), findsOneWidget);
    FeatureFlags.debugUnlockAllPremium = false;
    await tester.pumpWidget(
      const MaterialApp(
        home: PremiumTestFrame(child: Scaffold(body: Text('정원'))),
      ),
    );
    await tester.pump();
    expect(find.text(MembershipFeatures.testLabel), findsNothing);
  });
  testWidgets(
    'membership guide distinguishes basic cat and premium pets without checkout',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MembershipTestScreen()));
      expect(find.text('무료 이용'), findsOneWidget);
      expect(find.text('동반 고양이 외형 6종 선택·변경'), findsOneWidget);
      expect(find.text('구매하기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
