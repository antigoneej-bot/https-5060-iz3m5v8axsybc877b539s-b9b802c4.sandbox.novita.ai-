import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/widgets/revive_offer_sheet.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations_ko.dart';
import 'package:flutter_app/services/subscription_service.dart';

class FailingReviveGarden extends GardenProvider {
  final ids = <String?>[];
  FailingReviveGarden() {
    lightEssence = 80;
  }
  @override
  Future<bool> buyReviveWithLightEssence({String? sessionId}) async {
    ids.add(sessionId);
    if (ids.length == 1) {
      lightEssence = 30;
      notifyListeners();
      throw StateError('saved but confirmation failed');
    }
    return true;
  }
}

void main() {
  tearDown(() {
    SubscriptionService.debugIsPremiumOverride = null;
  });
  testWidgets(
    'failed revive releases controls and retries same ID even after debit',
    (tester) async {
      SubscriptionService.debugIsPremiumOverride = true;
      final garden = FailingReviveGarden();
      final l10n = AppLocalizationsKo();
      bool? continued;
      await tester.pumpWidget(
        ChangeNotifierProvider<GardenProvider>.value(
          value: garden,
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('offer'),
                  onPressed: () async {
                    continued = await ReviveOfferSheet.show(
                      context,
                      requiresAd: true,
                      reviveCountThisRun: 3,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('offer'));
      await tester.pumpAndSettle();
      final buy = find.text(l10n.reviveBuyWithLightEssenceButton(50));
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(find.textContaining('처리를 완료하지 못했어요'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, l10n.reviveDeclineButton),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(continued, isTrue);
      expect(garden.ids.length, 2);
      expect(garden.ids.first, garden.ids.last);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      garden.dispose();
    },
  );
}
