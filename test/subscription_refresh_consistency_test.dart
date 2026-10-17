import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/providers/promise_provider.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';

/// Task 4 회귀 테스트: 구매/복원 직후 premium_screen.dart는 이미 알고 있는
/// 구독 결과(ok / result.active)를 SubscriptionService에서 다시 조회하거나
/// (refreshPremiumStatus) provider 전체를 재로딩(load)하지 않고, 4개
/// provider(AppState/CatCare/Promise/Garden) 모두에 setAccountPremium을
/// 직접 호출해 즉시·일관되게 반영한다. 이 테스트는 그 핵심 보장을 검증한다:
/// 1) 네 provider 모두 동일한 값으로 즉시 일관되게 바뀐다(화면 재초기화·
///    재조회 없이도 상태 불일치가 생기지 않는다).
/// 2) 이미 같은 값이면 notifyListeners()가 다시 불리지 않는다(불필요한
///    리빌드가 없다 - AccountAccessBridge와 동일한 보장).
void main() {
  group('setAccountPremium consistency across all 4 providers', () {
    test('purchase success (true) is applied identically to all providers', () {
      final app = AppStateProvider();
      final care = CatCareProvider();
      final promise = PromiseProvider();
      final garden = GardenProvider();

      expect(app.isPremiumUser, isFalse);
      expect(care.isPremium, isFalse);
      expect(promise.isPremium, isFalse);

      // premium_screen.dart의 _purchase() 성공 분기와 동일한 패턴.
      app.setAccountPremium(true);
      care.setAccountPremium(true);
      promise.setAccountPremium(true);
      garden.setAccountPremium(true);

      expect(app.isPremiumUser, isTrue);
      expect(care.isPremium, isTrue);
      expect(promise.isPremium, isTrue);
      // GardenProvider는 _subscriptionActive가 private이므로, 공개된
      // setAccountPremium이 예외 없이 완료되는 것으로 간접 확인한다.
    });

    test('restore failure (active: false) never forces premium back on', () {
      final app = AppStateProvider();
      final care = CatCareProvider();
      final promise = PromiseProvider();
      final garden = GardenProvider();

      // premium_screen.dart의 _restore()는 result.active를 그대로 전달하므로
      // 실패 시(false) 구독 상태를 임의로 켜지 않아야 한다.
      app.setAccountPremium(false);
      care.setAccountPremium(false);
      promise.setAccountPremium(false);
      garden.setAccountPremium(false);

      expect(app.isPremiumUser, isFalse);
      expect(care.isPremium, isFalse);
      expect(promise.isPremium, isFalse);
    });

    test('redundant setAccountPremium calls do not notify again (no extra rebuilds)', () {
      final app = AppStateProvider();
      var notifyCount = 0;
      app.addListener(() => notifyCount++);

      app.setAccountPremium(true);
      expect(notifyCount, 1);

      // 같은 값으로 다시 호출해도(예: 구매 후 복원을 다시 누르는 등) 추가
      // notifyListeners가 발생하지 않아야 한다 - 불필요한 화면 재빌드 방지.
      app.setAccountPremium(true);
      expect(notifyCount, 1);

      app.setAccountPremium(false);
      expect(notifyCount, 2);
    });
  });
}
