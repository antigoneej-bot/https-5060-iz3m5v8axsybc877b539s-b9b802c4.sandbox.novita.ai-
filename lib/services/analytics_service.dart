import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// 앱 전체의 핵심 행동(편지 작성, 공유, 구독, 리텐션 마일스톤 등)을
/// 한 곳에서 기록하는 계측 계층입니다.
///
/// ⚠️ 개발자 인수인계 안내 ⚠️
/// Firebase Analytics(Web + Android)가 연결되어 있습니다. 모든 이벤트는
/// [_log]에서 디버그 콘솔 출력 + 로컬 카운터 저장 + Firebase 전송을 함께
/// 처리합니다.
///
/// 단, [AnalyticsEvents.premiumPurchase] / [AnalyticsEvents.premiumCancel]
/// 두 이벤트는 **의도적으로 Firebase 전송에서 제외**하고 있습니다. 지금
/// 구독 기능은 실제 결제 연동 전 임시 구현(SubscriptionService 참고)이라,
/// 이 이벤트를 그대로 Firebase에 흘리면 나중에 실제 결제가 붙었을 때
/// 테스트/가짜 구매 데이터와 실 구매 데이터가 섞여 매출·전환율 지표가
/// 왜곡됩니다. 실제 인앱결제 연동이 끝난 뒤 아래 [_excludedFromFirebase]
/// 목록에서 해당 이벤트명을 제거하면 그대로 Firebase 전송이 시작됩니다.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  static const String _eventCountPrefix = 'analytics_count_';
  static const String _milestoneKeyPrefix = 'analytics_milestone_';

  /// 실제 결제 연동 전까지 Firebase로 전송하지 않는 이벤트 목록.
  /// (가짜 구매/취소 데이터가 실 매출 지표를 오염시키는 것을 방지)
  static const Set<String> _excludedFromFirebase = {
    AnalyticsEvents.premiumPurchase,
    AnalyticsEvents.premiumCancel,
  };

  /// 이벤트를 기록합니다. [name]은 스네이크케이스 권장(예: letter_sent).
  /// [params]는 선택적 부가 정보(예: {'cat_id': 'sad'}).
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async {
    await _log(name, params);
    await _incrementLocalCount(name);
  }

  Future<void> _log(String name, Map<String, Object?>? params) async {
    if (kDebugMode) {
      debugPrint('📊 [Analytics] $name ${params ?? ''}');
    }
    if (_excludedFromFirebase.contains(name)) {
      if (kDebugMode) {
        debugPrint('📊 [Analytics] $name → Firebase 전송 제외(가짜 결제 방지)');
      }
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: params?.map((k, v) => MapEntry(k, v ?? '')),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📊 [Analytics] Firebase 전송 실패: $e');
      }
    }
  }

  Future<void> _incrementLocalCount(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_eventCountPrefix$name';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// 로컬에 누적된 이벤트 발생 횟수(디버그/자가 점검용).
  Future<int> getLocalEventCount(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_eventCountPrefix$name') ?? 0;
  }

  /// 자주 쓰는 이벤트들의 로컬 카운트를 한 번에 조회합니다(디버그 화면용).
  Future<Map<String, int>> getAllKnownEventCounts() async {
    final names = [
      AnalyticsEvents.letterSent,
      AnalyticsEvents.meditationCompleted,
      AnalyticsEvents.shareCard,
      AnalyticsEvents.saveCardToGallery,
      AnalyticsEvents.premiumPurchase,
      AnalyticsEvents.premiumScreenView,
      AnalyticsEvents.bondCodeGenerated,
      AnalyticsEvents.bondCodeRedeemed,
      AnalyticsEvents.weeklyReflectionView,
      AnalyticsEvents.monthlyReflectionView,
    ];
    final result = <String, int>{};
    for (final n in names) {
      result[n] = await getLocalEventCount(n);
    }
    return result;
  }

  /// 앱을 열 때마다 호출합니다. 설치 후 경과일을 기준으로 D1/D7/D30
  /// 재방문 마일스톤을 "처음 그 날짜에 도달한 순간" 한 번만 기록합니다.
  ///
  /// 이건 진짜 리텐션 지표(코호트별 %)는 아니고, "이 기기가 실제로 1일째/
  /// 7일째/30일째 되는 날 다시 앱을 열었는가"라는 이벤트입니다. Firebase
  /// 연결 전까지 이 앱이 최소한 재방문을 만들어내고 있는지 감을 잡는
  /// 용도로 씁니다.
  Future<void> logRetentionMilestoneIfNeeded() async {
    final days = await StorageService.daysSinceInstall();
    final milestones = [1, 3, 7, 14, 30];
    if (!milestones.contains(days)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_milestoneKeyPrefix$days';
    if (prefs.getBool(key) == true) return; // 이미 기록됨

    await prefs.setBool(key, true);
    await logEvent(AnalyticsEvents.retentionMilestone, {'day': days});
  }

  /// 디버그 화면에서 "이미 도달한 리텐션 마일스톤" 목록을 보여주기 위한 조회.
  Future<List<int>> getReachedRetentionMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final milestones = [1, 3, 7, 14, 30];
    return milestones
        .where((d) => prefs.getBool('$_milestoneKeyPrefix$d') == true)
        .toList();
  }
}

/// 앱 전역에서 공통으로 쓰는 이벤트 이름 상수 모음.
/// 오타로 인한 이벤트 이름 불일치를 막기 위해 문자열을 여기 한 곳에 모읍니다.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const String letterSent = 'letter_sent';
  static const String meditationCompleted = 'meditation_completed';
  static const String shareCard = 'share_card';
  static const String saveCardToGallery = 'save_card_to_gallery';
  static const String premiumScreenView = 'premium_screen_view';
  static const String premiumPurchase = 'premium_purchase';
  static const String premiumCancel = 'premium_cancel';
  static const String bondCodeGenerated = 'bond_code_generated';
  static const String bondCodeRedeemed = 'bond_code_redeemed';
  static const String bondCodeInvalid = 'bond_code_invalid';
  static const String weeklyReflectionView = 'weekly_reflection_view';
  static const String monthlyReflectionView = 'monthly_reflection_view';
  static const String retentionMilestone = 'retention_milestone';
}
