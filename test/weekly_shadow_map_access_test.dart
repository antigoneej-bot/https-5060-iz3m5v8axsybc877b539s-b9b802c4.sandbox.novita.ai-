import 'package:flutter/material.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/weekly_shadow_map_screen.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_app/widgets/subscription_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SubscriptionService.debugIsPremiumOverride = null);

  testWidgets('weekly detail stays gated without reading private records', (
    tester,
  ) async {
    SubscriptionService.debugIsPremiumOverride = false;
    // No record provider: protected content must never be built for free access.
    await tester.pumpWidget(const MaterialApp(home: WeeklyShadowMapScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionNotice), findsOneWidget);
    expect(find.text('아직 이번 주 기록이 없어요'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weekly detail opens for granted access with its existing empty state',
    (tester) async {
      SubscriptionService.debugIsPremiumOverride = true;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: const MaterialApp(
            // This regression checks access, not the repeating garden background.
            home: TickerMode(enabled: false, child: WeeklyShadowMapScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionNotice), findsNothing);
      expect(find.text('아직 이번 주 기록이 없어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
