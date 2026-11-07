import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/integration/garden_activity_menu.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/breathing_library_screen.dart';
import 'package:flutter_app/mongi/screens/garden_care_entry_screen.dart';
import 'package:flutter_app/mongi/screens/quiet_mode_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _LoadedGarden extends GardenProvider {
  @override
  bool get isInitialized => true;
}

void main() {
  testWidgets(
    'garden activities reach quiet reflection and breathing without a runner',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final garden = _LoadedGarden();
      addTearDown(garden.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<GardenProvider>.value(
          value: garden,
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(
              body: Center(child: GardenActivityMenuButton()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('기록·활동'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('정원에서 마음 돌보기'));
      await tester.pumpAndSettle();
      expect(find.byType(GardenCareEntryScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('garden-care-quiet')));
      await tester.pumpAndSettle();
      // Every emotion remains available without stage progression or unlocks.
      expect(find.byType(ChoiceChip), findsNWidgets(Emotion.all.length));
      final continueButton = find.byKey(
        const ValueKey('quiet-emotion-continue'),
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      final sadness = find.byKey(const ValueKey('quiet-emotion-sadness'));
      await tester.ensureVisible(sadness);
      await tester.tap(sadness);
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.byType(QuietModeScreen), findsOneWidget);
      expect(
        tester
            .widget<QuietModeScreen>(find.byType(QuietModeScreen))
            .emotions
            .single
            .type,
        EmotionType.sadness,
      );
      // Selecting a feeling or closing quiet mode must not invent a saved entry.
      expect(garden.diaryEntries, isEmpty);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(GardenCareEntryScreen), findsOneWidget);

      final breathing = find.byKey(const ValueKey('garden-care-breathing'));
      await tester.ensureVisible(breathing);
      await tester.tap(breathing);
      await tester.pumpAndSettle();
      expect(find.byType(BreathingLibraryScreen), findsOneWidget);
      expect(garden.diaryEntries, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
