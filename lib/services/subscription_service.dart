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
/// 그 외의 앱 코드(PremiumScreen, MonthlyReportScreen 등)는 이 서비스의
/// 퍼블릭 API(isPremium/purchasePremium/cancelPremium)만 사용하므로,
/// 내부 구현만 교체하면 나머지 화면은 수정할 필요가 없습니다.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;

  static const String _premiumKey = 'is_premium_subscriber';
  static const String _premiumSinceKey = 'premium_since';

  /// 정원 플러스 월 구독 가격(표시용). 실제 가격은 스토어 등록 후
  /// 스토어 상품 정보에서 가져오는 것으로 교체해야 합니다.
  static const String displayPrice = '월 4,900원';

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
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

  /// 구독 구매를 시도합니다.
  ///
  /// TODO(developer): 실제 결제 연동 시 아래 임시 구현을 in_app_purchase
  /// 패키지의 구매 플로우로 교체하세요. 지금은 실제 결제창 없이
  /// [PremiumScreen]에서 사용자 확인을 받은 뒤 바로 로컬 상태만
  /// 프리미엄으로 전환합니다(데모/체험용).
  Future<bool> purchasePremium() async {
    try {
      await setPremium(true);
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
