import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/providers/promise_provider.dart';
import 'package:flutter_app/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => SubscriptionService.debugIsPremiumOverride = null);

  test(
    'app access refresh leaves letters and the current flow untouched',
    () async {
      final provider = AppStateProvider();
      final history = provider.history;
      provider.selectedMeditationKey = 'current-guide';
      var changes = 0;
      provider.addListener(() => changes++);
      SubscriptionService.debugIsPremiumOverride = true;
      await provider.refreshSubscription();
      expect(provider.isPremiumUser, isTrue);
      expect(changes, 1);
      SubscriptionService.debugIsPremiumOverride = false;
      await provider.refreshPremiumStatus();
      expect(provider.isPremiumUser, isFalse);
      expect(changes, 2);
      expect(identical(history, provider.history), isTrue);
      expect(provider.selectedMeditationKey, 'current-guide');
      provider.dispose();
    },
  );

  test(
    'care access refresh leaves state points and inventory untouched',
    () async {
      final provider = CatCareProvider();
      final state = provider.state;
      provider.ownedAccessoryIds = ['already-owned'];
      SubscriptionService.debugIsPremiumOverride = true;
      await provider.refreshSubscription();
      expect(provider.isPremium, isTrue);
      SubscriptionService.debugIsPremiumOverride = false;
      await provider.refreshSubscription();
      expect(provider.isPremium, isFalse);
      expect(identical(state, provider.state), isTrue);
      expect(provider.ownedAccessoryIds, ['already-owned']);
      provider.dispose();
    },
  );

  test(
    'promise access refresh leaves entries and reactions untouched',
    () async {
      final provider = PromiseProvider();
      final entries = provider.entries;
      provider.lastReaction = 'keep this reaction';
      SubscriptionService.debugIsPremiumOverride = true;
      await provider.refreshSubscription();
      expect(provider.isPremium, isTrue);
      SubscriptionService.debugIsPremiumOverride = false;
      await provider.refreshSubscription();
      expect(provider.isPremium, isFalse);
      expect(identical(entries, provider.entries), isTrue);
      expect(provider.lastReaction, 'keep this reaction');
      provider.dispose();
    },
  );

  test(
    'app refresh finishing after disposal does not notify or mutate',
    () async {
      final provider = AppStateProvider();
      SubscriptionService.debugIsPremiumOverride = true;
      final refreshing = provider.refreshSubscription();
      provider.dispose();
      await refreshing;
      expect(provider.isPremiumUser, isFalse);
    },
  );

  test(
    'care refresh finishing after disposal does not notify or mutate',
    () async {
      final provider = CatCareProvider();
      SubscriptionService.debugIsPremiumOverride = true;
      final refreshing = provider.refreshSubscription();
      provider.dispose();
      await refreshing;
      expect(provider.isPremium, isFalse);
    },
  );

  test(
    'promise refresh finishing after disposal does not notify or mutate',
    () async {
      final provider = PromiseProvider();
      SubscriptionService.debugIsPremiumOverride = true;
      final refreshing = provider.refreshSubscription();
      provider.dispose();
      await refreshing;
      expect(provider.isPremium, isFalse);
    },
  );
}
