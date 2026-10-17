import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/models/garden_decoration.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/widgets/emotion_share_sheet.dart';
import 'package:flutter_app/mongi/widgets/garden_decoration_sheet.dart';
import 'package:flutter_app/screens/account_screen.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_app/utils/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _RestoreGarden extends GardenProvider {
  int restores = 0;
  Future<SubscriptionRestoreResult> result = Future.value(
    const SubscriptionRestoreResult(SubscriptionRestoreStatus.noActivePurchase),
  );

  @override
  bool isDecorationUnlocked(GardenDecoration decoration) => false;

  @override
  bool isDecorationEquipped(GardenDecoration decoration) => false;

  @override
  Future<SubscriptionRestoreResult> restoreDecorationPackPurchase() {
    restores++;
    return result;
  }

  @override
  Future<SubscriptionRestoreResult> restorePremiumFramesPurchase() {
    restores++;
    return result;
  }
}

Future<bool> _authenticated(BuildContext context) async => true;

Future<void> _showSheet(
  WidgetTester tester,
  _RestoreGarden garden, {
  required bool frames,
  Future<bool> Function(BuildContext) ensureSignedIn = _authenticated,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GardenProvider>.value(
      value: garden,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: frames
              ? SingleChildScrollView(
                  child: EmotionShareSheet(
                    emotion: Emotion.all.first,
                    targetName: null,
                    eatenCount: 0,
                    maxCombo: 0,
                    choseLove: false,
                    note: '',
                    ensureSignedIn: ensureSignedIn,
                  ),
                )
              : GardenDecorationSheet(ensureSignedIn: ensureSignedIn),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (frames) {
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('구독 복원하기'));
  } else {
    await tester.scrollUntilVisible(
      find.text('구독 복원하기'),
      300,
      scrollable: find.byType(Scrollable),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final frames in [false, true]) {
    final name = frames ? 'share frames' : 'garden decorations';

    testWidgets(
      '$name opens login and does not restore if sign-in is canceled',
      (tester) async {
        final garden = _RestoreGarden();
        addTearDown(garden.dispose);
        await _showSheet(
          tester,
          garden,
          frames: frames,
          ensureSignedIn: AccountScreen.ensureSignedIn,
        );
        await tester.tap(find.text('구독 복원하기'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(garden.restores, 0);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(garden.restores, 0);
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, '구독 복원하기'),
        );
        expect(button.onPressed, isNotNull);
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      '$name distinguishes unavailable, missing purchase and restored',
      (tester) async {
        final garden = _RestoreGarden();
        addTearDown(garden.dispose);
        for (final result in [
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.unavailable,
            active: true,
          ),
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.noActivePurchase,
          ),
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.signInRequired,
          ),
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.restored,
            active: true,
          ),
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          garden.result = Future.value(result);
          await _showSheet(tester, garden, frames: frames);
          await tester.tap(find.text('구독 복원하기'));
          await tester.pumpAndSettle();
          expect(find.text(result.message), findsOneWidget);
          expect(find.text('구매 내역을 확인했어요. 이미 구매하셨다면 잠시 후 반영돼요.'), findsNothing);
          expect(tester.takeException(), isNull);
        }
        expect(garden.restores, 4);
      },
    );

    testWidgets('$name blocks repeated taps and offers retry after failure', (
      tester,
    ) async {
      final garden = _RestoreGarden();
      addTearDown(garden.dispose);
      final pending = Completer<SubscriptionRestoreResult>();
      garden.result = pending.future;
      await _showSheet(tester, garden, frames: frames);
      await tester.tap(find.text('구독 복원하기'));
      await tester.pump();
      expect(garden.restores, 1);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '구독 복원하기'),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.text('구독 복원하기'));
      await tester.pump();
      expect(garden.restores, 1);
      pending.completeError(StateError('connection failed'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.unavailable,
          ).message,
        ),
        findsOneWidget,
      );
      garden.result = Future.value(
        const SubscriptionRestoreResult(
          SubscriptionRestoreStatus.restored,
          active: true,
        ),
      );
      await tester.tap(find.text('구독 복원하기'));
      await tester.pump();
      expect(garden.restores, 2);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'restore result and legacy API share a single unavailable attempt',
    () async {
      FeatureFlags.debugUnlockAllPremium = false;
      final service = SubscriptionService();
      final first = service.restorePurchasesWithResult();
      final second = service.restorePurchasesWithResult();
      final legacy = service.restorePurchases();
      expect(identical(first, second), isTrue);
      final result = await first;
      expect(result.status, SubscriptionRestoreStatus.unavailable);
      expect(result.active, isFalse);
      expect(await legacy, isFalse);
      expect(service.restoreUnavailable, isTrue);
    },
  );
}
