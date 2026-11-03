import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/companion_behavior.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/widgets/companion_presence.dart';
import 'package:flutter_app/widgets/companion_cat_mesh.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'idle poses are continuous and preserve paw geometry throughout a day',
    () {
      for (final night in [false, true]) {
        var previous = CompanionBehaviorFrame.at(0, bondStage: 3, night: night);
        for (var i = 0; i <= 14400; i++) {
          final frame = CompanionBehaviorFrame.at(
            i / 100,
            bondStage: 3,
            night: night,
          );
          expect(frame.headTilt.abs(), lessThanOrEqualTo(.045));
          expect(frame.eyeClosure, inInclusiveRange(0, 1));
          expect((frame.headTilt - previous.headTilt).abs(), lessThan(.001));
          expect((frame.breath - previous.breath).abs(), lessThan(.0001));
          for (final paw in [
            const Offset(.39, .967),
            const Offset(.57, .967),
            const Offset(.5, .8),
          ]) {
            expect(
              (CompanionCatMeshPainter.warp(
                        paw,
                        frame.headTilt,
                        breath: frame.breath,
                      ) -
                      paw)
                  .distance,
              lessThan(1e-12),
            );
          }
          previous = frame;
        }
      }
    },
  );
  test(
    'old saves default to motion; preference survives care, growth and reload',
    () async {
      final old = jsonDecode(const CompanionJourney().encode()) as Map;
      old.remove('automaticBehavior');
      expect(CompanionJourney.decode(jsonEncode(old)).automaticBehavior, true);
      SharedPreferences.setMockInitialValues({
        'local_user_companion_journey_v1': jsonEncode(old),
      });
      await CompanionJourneyStore.setAutomaticBehavior('local_user', false);
      await CompanionJourneyStore.setBaby('local_user', true);
      await CompanionJourneyStore.record('local_user', CompanionMoment.rest);
      final saved = await CompanionJourneyStore.load('local_user');
      expect(saved.automaticBehavior, false);
      expect(saved.keepBaby, true);
      expect(saved.growthDays, 1);
      old['automaticBehavior'] = 'true';
      expect(
        () => CompanionJourney.decode(jsonEncode(old)),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'greets without a tap; rest, preference and reduced motion stop the clock',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      Future<void> show({
        bool enabled = true,
        bool reduced = false,
        bool resting = false,
        bool ticker = true,
      }) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: ticker,
              child: Center(
                child: SizedBox.square(
                  dimension: 170,
                  child: CompanionPresence(enabled: enabled, resting: resting),
                ),
              ),
            ),
          ),
        ),
      );
      GardenCatArt art() =>
          tester.widget<GardenCatArt>(find.byType(GardenCatArt));
      await show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(art().eyeClosure, greaterThan(.9));
      expect(art().headTilt, greaterThan(0));
      // An autonomous greeting does not create a care record or points.
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      await show(resting: true);
      expect(art().eyeClosure, 1);
      final clock = art().animation, stopped = art().animation.value;
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, stopped);
      await show();
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, isNot(stopped));
      for (final option in ['off', 'reduced', 'ticker']) {
        await show(
          enabled: option != 'off',
          reduced: option == 'reduced',
          ticker: option != 'ticker',
        );
        final paused = clock.value;
        await tester.pump(const Duration(seconds: 2));
        expect(clock.value, paused);
        expect(tester.binding.transientCallbackCount, 0);
      }
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'background and a covering route pause; returning starts a fresh greeting',
    (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: const Scaffold(
            body: SizedBox.square(dimension: 170, child: CompanionPresence()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final clock = tester
          .widget<GardenCatArt>(find.byType(GardenCatArt))
          .animation;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = clock.value;
      await tester.pump(const Duration(seconds: 20));
      expect(clock.value, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(clock.value, closeTo(0, .002));
      await tester.pump(const Duration(seconds: 2));
      expect(clock.value, closeTo(2 / 72, .002));
      expect(tester.widget<GardenCatArt>(find.byType(GardenCatArt)).eyeClosure, greaterThan(.9));
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('다른 화면')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final covered = clock.value;
      await tester.pump(const Duration(seconds: 20));
      expect(clock.value, covered);
      nav.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, lessThan(5 / 72), reason: 'Returning begins the greeting instead of resuming an old pose');
      expect(clock.value, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
