import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/widgets/companion_care_panel.dart';
import 'package:flutter_app/mongi/screens/settings_screen.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/widgets/living_garden_entry.dart';
import 'package:flutter_app/mongi/widgets/living_garden_scene.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';

class _LocalGarden extends GardenProvider {
  @override
  Future<void> ensureInitialized() async {}
}

void main() {
  testWidgets(
    'settings and care switches share the same persisted motion setting',
    (t) async {
      final care = CatCareProvider();
      final garden = _LocalGarden();
      await care.loadJourney();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CatCareProvider>.value(value: care),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
          ],
          child: MaterialApp(
            navigatorKey: nav,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      final setting = find.byKey(const Key('settings-companion-motion'));
      await t.ensureVisible(setting);
      await t.pump();
      expect(t.widget<SwitchListTile>(setting).value, true);
      await t.tap(setting);
      await t.pumpAndSettle();
      expect(
        (await CompanionJourneyStore.load('local_user')).automaticBehavior,
        false,
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: CompanionCarePanel(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final control = find.byKey(const Key('companion-automatic'));
      await t.ensureVisible(control);
      await t.pump();
      expect(t.widget<SwitchListTile>(control).value, false);
      await t.tap(control);
      await t.pumpAndSettle();
      expect(
        (await CompanionJourneyStore.load('local_user')).automaticBehavior,
        true,
      );
      nav.currentState!.pop();
      await t.pumpAndSettle();
      expect(t.widget<SwitchListTile>(setting).value, true);
      final prefs = await SharedPreferences.getInstance();
      final saved = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
      await t.pumpWidget(const SizedBox());
      care.dispose();
      garden.dispose();
      SharedPreferences.setMockInitialValues(saved);
      final restarted = CatCareProvider();
      await restarted.loadJourney();
      expect(restarted.journey.automaticBehavior, true);
      restarted.dispose();
      expect(t.takeException(), isNull);
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
    SoundService().sfxEnabled = false;
  });
  testWidgets(
    'garden opens the same companion; care and motion persist across both screens',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'local_user_companion_journey_v1': const CompanionJourney(
          previousCareDays: 7,
        ).encode(),
      });
      final care = CatCareProvider()..companionName = '햇살';
      final garden = _LocalGarden();
      await care.loadJourney();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CatCareProvider>.value(value: care),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: LivingGardenEntry()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      LivingGardenScene scene() =>
          tester.widget<LivingGardenScene>(find.byType(LivingGardenScene));
      expect(scene().companionName, '햇살');
      expect(scene().companionScale, .88);
      expect(scene().companionAutomaticBehavior, true);
      await tester.tap(find.byKey(const Key('living-cat')));
      await tester.pumpAndSettle();
      expect(find.byType(CompanionCarePanel), findsOneWidget);
      expect(find.text('햇살'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('companion-rest')));
      await tester.tap(find.byKey(const ValueKey('companion-rest')));
      await tester.pumpAndSettle();
      expect(care.journey.growthDays, 8);
      await tester.ensureVisible(find.byKey(const Key('companion-automatic')));
      await tester.tap(find.byKey(const Key('companion-automatic')));
      await tester.pumpAndSettle();
      expect(care.journey.automaticBehavior, false);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(scene().companionAutomaticBehavior, false);
      expect(scene().companionName, '햇살');
      final reopened = await CompanionJourneyStore.load('local_user');
      expect(reopened.automaticBehavior, false);
      expect(reopened.growthDays, 8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      care.dispose();
      garden.dispose();
    },
  );
  for (final width in [360.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('care is reachable at width $width text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final care = CatCareProvider()..companionName = '햇살';
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: care,
            child: MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: CompanionCarePanel(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('햇살'), findsOneWidget);
        expect(care.journeyReady, true, reason: care.journeyError);
        final pet = find.byKey(const ValueKey('companion-pet'));
        await tester.ensureVisible(pet);
        await tester.tap(pet);
        await tester.pumpAndSettle();
        expect(care.journey.growthDays, 1, reason: care.journeyError);
        expect(
          care.journey.firstMoments.containsKey(CompanionMoment.pet),
          true,
        );
        await tester.tap(pet);
        await tester.pumpAndSettle();
        expect(care.journey.growthDays, 1);
        final brush = find.byKey(const ValueKey('companion-brush'));
        await tester.ensureVisible(brush);
        // The added care buttons can wrap onto a new row. Lay out the scroll
        // before hit-testing its new on-screen position.
        await tester.pump();
        expect(
          tester.widget<OutlinedButton>(brush).onPressed,
          isNotNull,
          reason: 'brush must become available after pet completes',
        );
        await tester.tap(brush);
        // Storage and reminder refresh are asynchronous even with reduced
        // motion. Wait for the saved action, not just for rendered frames.
        for (
          var i = 0;
          i < 40 &&
              !care.journey.didToday(CompanionMoment.brush, DateTime.now());
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();
        expect(
          care.journey.didToday(CompanionMoment.brush, DateTime.now()),
          true,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        care.dispose();
      });
    }
  }
  testWidgets('unreadable history disables care and offers retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'local_user_companion_journey_v1': 'invalid',
    });
    final care = CatCareProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: care,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CompanionCarePanel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('companion-pet')))
          .onPressed,
      isNull,
    );
    expect(find.text('함께한 기록 불러오기'), findsOneWidget);
    expect(care.journey.growthDays, 0);
    await tester.pumpWidget(const SizedBox());
    care.dispose();
  });
}
