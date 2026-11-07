import 'package:provider/provider.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/widgets/companion_coat_art.dart';
import 'package:flutter_app/widgets/companion_presence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/calm_letter_receipt.dart';

void main() {
  for (final coat in CompanionCoat.values) {
    testWidgets('saved-letter receipt keeps selected companion ' + coat.name, (
      t,
    ) async {
      final care = CatCareProvider();
      addTearDown(care.dispose);
      care.journey = CompanionJourney(coat: coat, automaticBehavior: false);
      care.journeyReady = true;
      await t.pumpWidget(
        ChangeNotifierProvider<CatCareProvider>.value(
          value: care,
          child: const MaterialApp(home: Scaffold(body: CalmLetterReceipt())),
        ),
      );
      await t.pump();
      expect(
        t.widget<CompanionCoatScope>(find.byType(CompanionCoatScope)).coat,
        coat,
      );
      expect(
        t.widget<CompanionPresence>(find.byType(CompanionPresence)).enabled,
        isFalse,
      );
      expect(care.journey.coat, coat);
      await t.pumpWidget(const SizedBox());
    });
  }
  Widget screen({required bool reduced}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: const Scaffold(body: CalmLetterReceipt()),
    ),
  );
  String frame(WidgetTester tester) =>
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

  testWidgets('reduced motion keeps one grounded frame and the saved receipt', (
    tester,
  ) async {
    await tester.pumpWidget(screen(reduced: true));
    final original = frame(tester);
    final originalBounds = tester.getRect(find.byType(Image));
    await tester.pump(const Duration(seconds: 5));
    expect(frame(tester), original);
    expect(find.text('편지를 조용히 담아두었어요'), findsOneWidget);
    expect(tester.getRect(find.byType(Image)), originalBounds);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'only eyes change frame; background lifecycle stops and resets blink',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(screen(reduced: false));
      final original = frame(tester);
      final originalBounds = tester.getRect(find.byType(Image));
      await tester.pump(const Duration(milliseconds: 4700));
      expect(frame(tester), contains('blink'));
      expect(tester.getRect(find.byType(Image)), originalBounds);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      // Paused applications do not render frames. The next visible frame on
      // resume must reset to open eyes before another blink is scheduled.
      final pausedFrame = frame(tester);
      await tester.pump(const Duration(seconds: 10));
      expect(frame(tester), pausedFrame);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(frame(tester), original);
      await tester.pump(const Duration(milliseconds: 4700));
      expect(frame(tester), contains('blink'));
      await tester.pump(const Duration(milliseconds: 145));
      expect(frame(tester), original);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
