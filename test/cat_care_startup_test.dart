import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => SubscriptionService.debugIsPremiumOverride = null);

  test(
    'standalone care callers retain their explicit subscription policy',
    () async {
      CatCareService.setCurrentUser('standalone');
      SharedPreferences.setMockInitialValues({
        'standalone_care_temperature': 99,
      });
      final result = await CatCareService.adjustBonusTemperature(
        1,
        isPremium: true,
      );
      expect(result, (0, 1));
    },
  );

  test(
    'saved care displays immediately but paid attendance waits for startup',
    () async {
      CatCareService.setCurrentUser('startup');
      SharedPreferences.setMockInitialValues({'startup_care_temperature': 99});
      final prefs = await SharedPreferences.getInstance();
      final gate = Completer<void>();
      SubscriptionService.debugIsPremiumOverride = false;
      final startup = SubscriptionService().startStartupCheck(
        prepareCloud: () => gate.future,
      );
      var completed = false;
      final loading =
          CatCareService.loadAndApplyDailyDecay(
            defaultCompanionCatId: 'cat',
            isPremium: false,
            countAttendance: true,
          ).then((state) {
            completed = true;
            return state;
          });
      await Future<void>.delayed(Duration.zero);
      final cached = await CatCareService.readSnapshot(
        defaultCompanionCatId: 'cat',
      );
      expect(cached.temperature, 99);
      expect(cached.points, 0);
      expect(completed, isFalse);
      expect(prefs.getKeys(), {'startup_care_temperature'});

      // Store plugins are unavailable in this unit environment; the completed
      // startup attempt falls back to the explicit simulated verified entitlement.
      SubscriptionService.debugIsPremiumOverride = true;
      gate.complete();
      await startup;
      final state = await loading;
      expect(state.temperature, 0);
      expect(state.points, 1);
      expect(state.growthDays, 1);
      final again = await CatCareService.loadAndApplyDailyDecay(
        defaultCompanionCatId: 'cat',
        isPremium: false,
        countAttendance: true,
      );
      expect(again.temperature, 0);
      expect(again.points, 1);
      expect(again.growthDays, 1);
    },
  );
  test(
    'care tapped before initial attendance load survives day rollover',
    () async {
      CatCareService.setCurrentUser('early_tap');
      SubscriptionService.debugIsPremiumOverride = true;
      SharedPreferences.setMockInitialValues({
        'early_tap_care_temperature': 99,
        'early_tap_care_last_date': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'early_tap_care_watered_today': true,
      });
      final tapped = await CatCareService.completeTask(
        CareTask.feed,
        isPremium: true,
      );
      expect(tapped.fedToday, isTrue);
      expect(tapped.wateredToday, isFalse);
      final loaded = await CatCareService.loadAndApplyDailyDecay(
        defaultCompanionCatId: 'cat',
        isPremium: true,
        countAttendance: true,
      );
      expect(loaded.fedToday, isTrue);
      expect(loaded.wateredToday, isFalse);
      expect(loaded.temperature, 1);
      expect(loaded.points, 1);
    },
  );
}
