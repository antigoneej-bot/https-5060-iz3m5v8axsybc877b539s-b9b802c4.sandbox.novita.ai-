import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'local_record_transaction.dart';

/// 앱 전체의 핵심 행동(편지 작성, 공유, 구독, 리텐션 마일스톤 등)을
/// 한 곳에서 기록하는 계측 계층입니다.
///
/// ⚠️ 개발자 인수인계 안내 ⚠️
/// Firebase Analytics(Web + Android)가 연결되어 있습니다. 모든 이벤트는
/// [_log]에서 디버그 콘솔 출력 + 로컬 카운터 저장 + Firebase 전송을 함께
/// 처리합니다.
///
/// 결제 이벤트도 실연동 이후 Firebase로 전송합니다.
class AnalyticsService with WidgetsBindingObserver {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  static const String _eventCountPrefix = 'analytics_count_';
  static const String _milestoneKeyPrefix = 'analytics_milestone_';

  /// (과거 가짜 결제 오염 방지용 — 실 IAP 연동 후 비움)
  static const Set<String> _excludedFromFirebase = <String>{};

  static final sharingEnabled = ValueNotifier<bool>(false);
  static final optOutPending = ValueNotifier<bool>(false);
  final _changes = LocalRecordQueue();
  int _generation = 0;
  bool _observing = false;

  void _observe() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && optOutPending.value) {
      unawaited(retryOptOut().catchError((Object _) {}));
    }
  }

  Future<void> loadConsent() => _changes.run(() async {
    _observe();
    final generation = _generation;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('analytics_sharing_v1') ?? false;
    try {
      if (optOutPending.value || !enabled) {
        await _applyOff(prefs);
      } else {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        if (generation == _generation) sharingEnabled.value = true;
      }
    } catch (_) {
      sharingEnabled.value = false;
    }
  });

  Future<void> _saveConsent(SharedPreferences prefs, bool enabled) async {
    if (!await prefs.setBool('analytics_sharing_v1', enabled)) {
      throw StateError('통계 설정을 저장하지 못했어요.');
    }
  }

  Future<void> _applyOff(SharedPreferences prefs) async {
    sharingEnabled.value = false;
    optOutPending.value = true;
    Object? failure;
    StackTrace? failureStack;
    // Try both operations, even if physical storage or the native SDK fails.
    for (final action in <Future<void> Function()>[
      () => _saveConsent(prefs, false),
      () => FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false),
    ]) {
      try {
        await action();
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }
    if (failure != null) Error.throwWithStackTrace(failure, failureStack!);
    optOutPending.value = false;
  }

  Future<void> setSharing(bool enabled) {
    final generation = ++_generation;
    // Block new app events immediately, including while an older ON is pending.
    sharingEnabled.value = false;
    return _changes.run(() async {
      _observe();
      if (generation != _generation) return;
      final prefs = await SharedPreferences.getInstance();
      await _applyOff(prefs);
      if (!enabled || generation != _generation) return;
      try {
        await _saveConsent(prefs, true);
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        if (generation == _generation) sharingEnabled.value = true;
      } catch (error, stack) {
        try {
          await _applyOff(prefs);
        } catch (_) {}
        Error.throwWithStackTrace(error, stack);
      }
    });
  }

  Future<void> retryOptOut() => _changes.run(() async {
    if (!optOutPending.value) return;
    await _applyOff(await SharedPreferences.getInstance());
  });

  /// 이벤트를 기록합니다. [name]은 스네이크케이스 권장(예: letter_sent).
  /// [params]는 선택적 부가 정보(예: {'cat_id': 'sad'}).
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async {
    await _log(name, params);
    await _incrementLocalCount(name);
  }

  Future<void> _log(String name, Map<String, Object?>? params) async {
    if (kDebugMode) {
      debugPrint('Analytics event: $name');
    }
    if (!sharingEnabled.value || _excludedFromFirebase.contains(name)) {
      if (kDebugMode) {
        debugPrint('📊 [Analytics] $name → Firebase 전송 제외(가짜 결제 방지)');
      }
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        // Only bounded operational fields; omit emotion/cat IDs and written text.
        parameters: params == null
            ? null
            : <String, Object>{
                for (final key in ['day', 'plan', 'has_text'])
                  if (params[key] is num || params[key] is String)
                    key: params[key]!,
              },
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
      'garden_postcard_share_requested',
      'garden_postcard_share_target',
      'garden_postcard_install_open',
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
      AnalyticsEvents.letterClosingSaved,
      AnalyticsEvents.careCollectionViewed,
      AnalyticsEvents.careActionPlanned,
      AnalyticsEvents.careActionCompleted,
      AnalyticsEvents.careActionReviewed,
      AnalyticsEvents.gardenBookCreated,
      AnalyticsEvents.gardenBookOpened,
      AnalyticsEvents.gardenBookShareRequested,
      AnalyticsEvents.sharedTreeCreated,
      AnalyticsEvents.sharedTreeJoined,
      AnalyticsEvents.sharedTreeWatered,
      AnalyticsEvents.sharedTreeNoteSaved,
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
  static const String letterClosingSaved = 'letter_closing_saved';
  static const String careCollectionViewed = 'care_collection_viewed';
  static const String careActionPlanned = 'care_action_planned';
  static const String careActionCompleted = 'care_action_completed';
  static const String careActionReviewed = 'care_action_reviewed';
  static const String gardenBookCreated = 'garden_book_created';
  static const String gardenBookOpened = 'garden_book_opened';
  static const String gardenBookShareRequested = 'garden_book_share_requested';
  static const String sharedTreeCreated = 'shared_tree_created';
  static const String sharedTreeJoined = 'shared_tree_joined';
  static const String sharedTreeWatered = 'shared_tree_watered';
  static const String sharedTreeNoteSaved = 'shared_tree_note_saved';
}
