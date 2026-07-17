import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// '정원 플러스' 구독(프리미엄) 상태를 관리하는 서비스.
///
/// ⚠️ 개발자 인수인계 안내 ⚠️
/// 현재는 실제 결제(Google Play 인앱결제)가 연결되어 있지 않습니다.
/// 이 파일은 구독 상태를 로컬(SharedPreferences)에만 저장하는 임시 구현이며,
/// [purchasePremium]이 바로 그 자리입니다. 실제 결제를 붙일 때는:
///   1. pubspec.yaml에 `in_app_purchase` 패키지를 추가합니다.
///   2. Google Play Console에 앱을 등록하고, 구독 상품(예: garden_plus_monthly)을
///      만듭니다.
///   3. [purchasePremium]의 내부 구현을 in_app_purchase의 실제 구매 플로우로
///      교체하고, 구매 성공 콜백에서 [setPremium](true)를 호출합니다.
///   4. 앱 시작 시 in_app_purchase의 `queryPastPurchases`(또는 restore)로
///      기존 구독 여부를 서버가 아닌 로컬이 아닌 스토어에서 재확인하도록
///      [restorePurchases]를 교체합니다.
/// 그 외의 앱 코드(PremiumScreen, MonthlyShadowReflectionScreen 등)는 이 서비스의
/// 퍼블릭 API(isPremium/purchasePremium/cancelPremium)만 사용하므로,
/// 내부 구현만 교체하면 나머지 화면은 수정할 필요가 없습니다.

/// 정원 플러스 구독 플랜 종류.
enum SubscriptionPlan { monthly, yearly }

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;

  static const String _premiumKey = 'is_premium_subscriber';
  static const String _premiumSinceKey = 'premium_since';
  static const String _planKey = 'premium_plan_type';

  /// 정원 플러스 월 구독 가격(표시용).
  ///
  /// ⚠️ MVP 출시 기념 얼리버드 특가입니다(출시 후 약 6개월간 유지 예정).
  /// 반응이 좋으면 이후 정가로 인상할 계획이며, 그때는 [earlybirdLabel] 노출을
  /// 중단하고 이 상수들만 새 가격으로 교체하면 됩니다. 실제 가격은 스토어
  /// 등록 후 스토어 상품 정보에서 가져오는 것으로 교체해야 합니다.
  static const String displayPrice = '월 2,500원';

  /// 정원 플러스 연 구독 가격(표시용, 월 요금 대비 50% 할인가).
  /// 2,500원 × 12개월 = 30,000원 → 50% 할인 → 15,000원.
  static const String displayYearlyPrice = '연 15,000원';

  /// 연 구독을 월 단위로 환산했을 때의 가격(안내용).
  static const String displayYearlyMonthlyEquivalent = '월 1,250원 상당';

  /// 연 구독 할인율 안내 라벨.
  static const String yearlyDiscountLabel = '50% 할인';

  /// 출시 기념 얼리버드 특가 안내 라벨. 6개월 한정 프로모션이 끝나면
  /// 이 라벨과 [displayPrice]/[displayYearlyPrice]를 함께 정리하세요.
  static const String earlybirdLabel = '출시 기념 얼리버드가';

  /// 얼리버드 특가에 대한 부연 설명(화면 하단 안내용).
  static const String earlybirdCaption = '한정 특가 · 이후 정가로 조정될 수 있어요';

  /// 선택한 플랜에 맞는 표시용 가격 문자열을 반환합니다.
  String priceLabelFor(SubscriptionPlan plan) {
    return plan == SubscriptionPlan.yearly ? displayYearlyPrice : displayPrice;
  }

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// 현재 저장된(또는 마지막으로 선택된) 구독 플랜을 반환합니다.
  Future<SubscriptionPlan> currentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_planKey);
    return v == 'yearly' ? SubscriptionPlan.yearly : SubscriptionPlan.monthly;
  }

  Future<void> setPlan(SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _planKey,
      plan == SubscriptionPlan.yearly ? 'yearly' : 'monthly',
    );
  }

  Future<DateTime?> premiumSince() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_premiumSinceKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> setPremium(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, v);
    if (v) {
      await prefs.setString(_premiumSinceKey, DateTime.now().toIso8601String());
    } else {
      await prefs.remove(_premiumSinceKey);
    }
  }

  /// 구독 구매를 시도합니다. [plan]으로 월간/연간 중 선택한 플랜을 전달하면
  /// 함께 저장되어, 이후 [PremiumScreen]에서 현재 이용 중인 플랜을 보여줄 때
  /// 사용됩니다.
  ///
  /// TODO(developer): 실제 결제 연동 시 아래 임시 구현을 in_app_purchase
  /// 패키지의 구매 플로우로 교체하세요. 지금은 실제 결제창 없이
  /// [PremiumScreen]에서 사용자 확인을 받은 뒤 바로 로컬 상태만
  /// 프리미엄으로 전환합니다(데모/체험용).
  Future<bool> purchasePremium({
    SubscriptionPlan plan = SubscriptionPlan.monthly,
  }) async {
    try {
      await setPremium(true);
      await setPlan(plan);
      // TODO(developer): 얼리버드 특가로 가입한 사용자는 이후 정가 인상 시에도
      // 가입 당시 가격을 유지시켜주는 것이 좋습니다(그랜드파더링). 실제 결제
      // 연동 시, 가입 시점의 plan/price를 함께 저장해두고 갱신 결제 시 그
      // 가격을 그대로 사용하도록 처리하세요.
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('SubscriptionService 구매 처리 실패: $e');
      return false;
    }
  }

  /// 구독을 해지합니다. 실제 연동 시에는 스토어의 구독 관리 페이지로
  /// 안내하는 방식이 일반적이며, 로컬 상태는 스토어 상태와 동기화되어야 합니다.
  Future<void> cancelPremium() async {
    await setPremium(false);
  }

  /// TODO(developer): 실제 결제 연동 시, 기기에 이미 구매 기록이 있는지
  /// 스토어에 문의해서 복원하는 로직으로 교체하세요.
  Future<bool> restorePurchases() async {
    return isPremium();
  }
}
