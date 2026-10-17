import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../data/shadow_cats_data.dart';
import '../utils/feature_flags.dart';
import 'storage_service.dart';
import 'special_letter_service.dart';
import '../models/special_letter_entry.dart';
import 'reply_notification_plan.dart';

/// 로컬 알림 리마인더 서비스.
/// 서버/네트워크 없이 기기 안에서만 예약 · 반복되며, 사용자가 마이 탭에서
/// 알림 종류별로 언제든 켜고 끌 수 있습니다.
///
/// 지원하는 알림 종류:
/// - 아침 알림: 매일 정해진 시각(기본 오전 9시)에 오늘의 감정 체크를 유도
/// - 저녁 알림: 매일 정해진 시각(기본 오후 8시)에 하루 닫기를 유도
/// - 방문 알림: 3일 이상 앱을 열지 않았을 때만 조건부로 한 번 발송
/// - 스트릭 임박 알림: 오늘 아직 미션을 완수하지 않았을 때만 저녁 늦게 발송
///
/// 알림을 탭하면 [pendingDeepLink]에 종류별 payload가 기록되고, 앱은 이를
/// 읽어 알맞은 화면으로 이동합니다(딥링크).
class NotificationService with WidgetsBindingObserver {
  NotificationService._() : _now = DateTime.now;
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  @visibleForTesting
  NotificationService.forTesting({required DateTime Function() now})
    : _now = now;

  final DateTime Function() _now;

  // 알림 종류별 고유 ID. 레거시(v1) 단일 알림은 마이그레이션 시 취소됩니다.
  static const int _legacyDailyReminderId = 1001;
  static const int _morningId = 1002;
  static const int _eveningId = 1003;
  static const int _crisisId = 1004;
  static const int _streakId = 1005;
  static const int _catReplyId = 1006;
  static const int _heartLetterReplyId = 1007;

  static const int _crisisAbsenceDays = 3;
  static const int _streakHour = 21;
  static const int _streakMinute = 30;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _observingLifecycle = false;
  Future<void> _conditionalChanges = Future<void>.value();

  Future<T> _serializeConditional<T>(Future<T> Function() action) {
    final next = _conditionalChanges.then((_) => action());
    _conditionalChanges = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshForForegroundVisit());
    }
  }

  /// A background isolate or a paused app must not postpone the absence reminder.
  /// This never asks for permission; only an explicit settings action does that.
  Future<void> refreshForForegroundVisit() => _serializeConditional(() async {
    if (kIsWeb ||
        !_initialized ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    await _refreshCrisisReminder();
    await _refreshStreakReminder();
  });

  @visibleForTesting
  void dispose() {
    if (_observingLifecycle) WidgetsBinding.instance.removeObserver(this);
    _observingLifecycle = false;
  }

  /// 알림을 탭해서 앱이 열렸을 때, 이동해야 할 화면을 알려주는 딱지값입니다.
  /// 'morning' | 'evening' | 'crisis' | 'streak' 중 하나이며, 소비하면
  /// [consumePendingDeepLink]로 비웁니다.
  String? pendingDeepLink;

  /// 앱이 이미 실행 중(warm)일 때 알림을 탭하면, 콜드 스타트처럼
  /// [pendingDeepLink]를 나중에 소비하는 방식만으로는 화면 전환이 즉시
  /// 일어나지 않을 수 있습니다. 이 알림을 구독해두면 그 순간 즉시 반응할
  /// 수 있습니다.
  final deepLinkChanges = _DeepLinkNotifier();

  static const List<String> _morningMessages = [
    '오늘 아침, 마음은 어떤가요? 🌤️',
    '잠깐, 지금 기분을 골라볼까요? 🐾',
    '오늘도 그림자 고양이들이 정원에서 기다리고 있어요',
    '하루를 시작하기 전, 마음 한 번 들여다볼까요?',
    '오늘의 감정과 닮은 고양이를 만나러 가볼까요? 🌱',
  ];

  static const List<String> _morningMessagesWithName = [
    '{name}가 오늘 하루도 함께하고 싶어해요',
    '{name}와 함께 오늘의 감정을 나눠보세요',
    '{name}가 아침 인사를 건네고 있어요 🐾',
  ];

  static const List<String> _eveningMessages = [
    '오늘 하루를 조용히 닫아볼까요? 🌙',
    '잠들기 전, 오늘 남긴 약속들을 살펴볼까요?',
    '하루의 끝, 정원에 잠깐 들러주세요',
    '오늘도 애썼어요. 마음을 가만히 정리해볼까요?',
    '오늘 하루는 어땠나요? 잠깐 돌아봐요',
  ];

  static const List<String> _eveningMessagesWithName = [
    '{name}가 오늘 하루 얘기를 듣고 싶어해요',
    '{name}와 함께 하루를 마무리해보세요 🌛',
  ];

  /// 앱 실행 시 1회 초기화합니다. 알림 권한은 이 시점에는 요청하지 않고,
  /// 사용자가 설정에서 알림을 켤 때 명시적으로 요청합니다(불필요한 권한
  /// 팝업으로 첫 인상을 해치지 않기 위함).
  Future<void> init() async {
    if (_initialized) return;
    await StorageService.migrateLegacyReminderIfNeeded();
    if (kIsWeb) {
      // 웹 플랫폼은 로컬 알림 예약을 지원하지 않으므로, 웹 프리뷰에서는
      // 초기화만 완료 처리하고 실제 알림 기능은 비활성 상태로 둡니다.
      _initialized = true;
      return;
    }
    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      // 알림을 탭해서 앱이 완전히 종료된 상태에서 새로 실행된 경우(cold start)도
      // 잡아둡니다.
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        pendingDeepLink = launchDetails?.notificationResponse?.payload;
      }
      // 레거시(v1) 단일 알림이 남아있다면 정리합니다.
      await _plugin.cancel(_legacyDailyReminderId);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService init 실패: $e');
    }
    _initialized = true;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
  }

  /// 기기 로컬 타임존을 timezone 패키지에 연결합니다.
  /// 설정하지 않으면 tz.local이 UTC라 아침/저녁 알림 시각이 어긋납니다.
  /// (한국 앱 기준으로 Asia/Seoul을 사용. UTC+9 외 기기에서도 KST 스케줄.)
  Future<void> _configureLocalTimezone() async {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      if (kDebugMode) {
        debugPrint('NotificationService timezone: Asia/Seoul');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService timezone set failed: $e');
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    pendingDeepLink = response.payload;
    deepLinkChanges.fire();
  }

  /// 대기 중인 딥링크 payload를 읽고 비웁니다. 홈 화면 진입 시 1회 소비합니다.
  String? consumePendingDeepLink() {
    final v = pendingDeepLink;
    pendingDeepLink = null;
    return v;
  }

  // ───────────────────────── 아침 알림 ─────────────────────────
  Future<bool> isMorningEnabled() => StorageService.getMorningEnabled();
  Future<(int, int)> getMorningTime() => StorageService.getMorningTime();

  Future<bool> enableMorning({int hour = 9, int minute = 0}) async {
    await init();
    final granted = await _requestPermission();
    if (!granted) {
      await StorageService.setMorningEnabled(false);
      return false;
    }
    await StorageService.setMorningEnabled(true);
    await StorageService.setMorningTime(hour, minute);
    if (!kIsWeb) await _scheduleMorning(hour, minute);
    return true;
  }

  Future<void> disableMorning() async {
    await StorageService.setMorningEnabled(false);
    if (kIsWeb) return;
    await _plugin.cancel(_morningId);
  }

  Future<void> updateMorningTime(int hour, int minute) async {
    await StorageService.setMorningTime(hour, minute);
    final enabled = await StorageService.getMorningEnabled();
    if (enabled && !kIsWeb) await _scheduleMorning(hour, minute);
  }

  // ───────────────────────── 저녁 알림 ─────────────────────────
  Future<bool> isEveningEnabled() => StorageService.getEveningEnabled();
  Future<(int, int)> getEveningTime() => StorageService.getEveningTime();

  Future<bool> enableEvening({int hour = 20, int minute = 0}) async {
    await init();
    final granted = await _requestPermission();
    if (!granted) {
      await StorageService.setEveningEnabled(false);
      return false;
    }
    await StorageService.setEveningEnabled(true);
    await StorageService.setEveningTime(hour, minute);
    if (!kIsWeb) await _scheduleEvening(hour, minute);
    return true;
  }

  Future<void> disableEvening() async {
    await StorageService.setEveningEnabled(false);
    if (kIsWeb) return;
    await _plugin.cancel(_eveningId);
  }

  Future<void> updateEveningTime(int hour, int minute) async {
    await StorageService.setEveningTime(hour, minute);
    final enabled = await StorageService.getEveningEnabled();
    if (enabled && !kIsWeb) await _scheduleEvening(hour, minute);
  }

  // ───────────────────────── 방문 / 스트릭 알림 on/off ─────────────────────────
  Future<bool> isCrisisEnabled() => StorageService.getCrisisEnabled();
  Future<bool> setCrisisEnabled(bool v) => _setConditionalEnabled(
    v,
    id: _crisisId,
    save: StorageService.setCrisisEnabled,
    refresh: _refreshCrisisReminder,
  );

  Future<bool> isStreakEnabled() => StorageService.getStreakEnabled();
  Future<bool> setStreakEnabled(bool v) => _setConditionalEnabled(
    v,
    id: _streakId,
    save: StorageService.setStreakEnabled,
    refresh: _refreshStreakReminder,
  );

  Future<bool> _setConditionalEnabled(
    bool enabled, {
    required int id,
    required Future<void> Function(bool) save,
    required Future<bool> Function() refresh,
  }) => _serializeConditional(() async {
    try {
      await init();
      if (enabled && (kIsWeb || !await _requestPermission())) {
        await save(false);
        if (!kIsWeb) await _plugin.cancel(id);
        return false;
      }
      await save(enabled);
      if (kIsWeb) return true; // Turning off remains available in web preview.
      if (!enabled) {
        await _plugin.cancel(id);
        return true;
      }
      if (await refresh()) return true;
      await save(false);
      await _plugin.cancel(id);
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 알림 설정 실패: $e');
      // Do not leave a successful-looking opt-in after scheduling failed.
      if (enabled) await save(false);
      return false;
    }
  });

  /// 온보딩 「알림 받기」 선택 결과를 실제 스케줄에 반영합니다.
  /// 동의하면 아침(9:00)·저녁(20:00) 리마인더를 켜고 권한을 요청하며,
  /// 거절이면 둘 다 끕니다. (플래그만 남기고 스케줄하지 않던 구멍 해소)
  Future<void> applyOnboardingOptIn(bool optIn) async {
    await StorageService.setNotificationOptIn(optIn);
    if (optIn) {
      await enableMorning(hour: 9, minute: 0);
      await enableEvening(hour: 20, minute: 0);
    } else {
      await disableMorning();
      await disableEvening();
    }
  }

  /// 앱 시작 시, 이미 켜져 있는 설정이 있다면 모든 종류의 알림을 다시
  /// 계산 · 재예약합니다(기기 재부팅, 알림 문구 가변화, 조건부 발송 갱신 등에 대응).
  Future<void> restoreIfEnabled() async {
    await init();
    if (kIsWeb) return;

    if (await StorageService.getMorningEnabled()) {
      final (h, m) = await StorageService.getMorningTime();
      await _scheduleMorning(h, m);
    }
    if (await StorageService.getEveningEnabled()) {
      final (h, m) = await StorageService.getEveningTime();
      await _scheduleEvening(h, m);
    }
    await refreshForForegroundVisit();
    await restoreReplyNotification();
  }

  /// 오늘의 미션(편지 쓰기 등)을 완수했을 때 호출합니다. 오늘 예약된
  /// '스트릭 임박' 알림이 있다면 더 이상 필요 없으므로 취소합니다.
  Future<void> notifyMissionCompletedToday() async {
    if (kIsWeb) return;
    await _plugin.cancel(_streakId);
  }

  Future<bool> _requestPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? true;
      }
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      return !kIsWeb;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 권한 요청 실패: $e');
      return false;
    }
  }

  String _pickMessage(List<String> base, List<String> withName, String? name) {
    final rng = Random();
    if (name != null && name.trim().isNotEmpty && rng.nextBool()) {
      final msg = withName[rng.nextInt(withName.length)];
      return msg.replaceAll('{name}', name.trim());
    }
    return base[rng.nextInt(base.length)];
  }

  /// 가장 최근에 만난 그림자 고양이의 한글 이름을 반환합니다(없으면 null).
  /// 알림 문구 개인화(예: "OO가 기다리고 있어요")에 사용됩니다.
  String? _lastMetCatName() {
    try {
      final catId = StorageService.getLastMetCatId();
      if (catId == null) return null;
      return shadowCatById(catId).nameKr;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 마지막 고양이 조회 실패: $e');
      return null;
    }
  }

  Future<void> _scheduleMorning(int hour, int minute) async {
    try {
      final name = await StorageService.getCompanionName();
      final body = _pickMessage(
        _morningMessages,
        _morningMessagesWithName,
        name,
      );
      final scheduled = _nextInstanceOf(hour, minute);
      await _plugin.zonedSchedule(
        _morningId,
        '마음냥 정원 🌤️',
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_reminder',
            '아침 감정 체크 알림',
            channelDescription: '매일 아침 오늘의 감정 고양이를 만나보도록 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'morning',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 아침 알림 예약 실패: $e');
    }
  }

  Future<void> _scheduleEvening(int hour, int minute) async {
    try {
      final name = await StorageService.getCompanionName();
      final body = _pickMessage(
        _eveningMessages,
        _eveningMessagesWithName,
        name,
      );
      final scheduled = _nextInstanceOf(hour, minute);
      await _plugin.zonedSchedule(
        _eveningId,
        '마음냥 정원 🌙',
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'evening_reminder',
            '저녁 하루 닫기 알림',
            channelDescription: '매일 저녁 하루를 조용히 닫아보도록 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'evening',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 저녁 알림 예약 실패: $e');
    }
  }

  /// 실제 방문 또는 명시적으로 알림을 켠 시점부터 3일 뒤에 한 번 예약합니다.
  /// 잠깐 화면을 떠났다가 다시 들어온 방문도 반영하고, 백그라운드 처리로는
  /// 방문 시각을 갱신하지 않습니다. 기존 ID/설정 키는 업데이트 호환용입니다.
  Future<bool> _refreshCrisisReminder() async {
    try {
      await _plugin.cancel(_crisisId);
      final enabled = await StorageService.getCrisisEnabled();
      if (!enabled) return true;

      final name = await StorageService.getCompanionName();
      final lastCatName = _lastMetCatName();
      final rng = Random();
      final String body;
      if (name != null && name.trim().isNotEmpty) {
        body = '${name.trim()}와 정원에서 잠깐 쉬어가도 좋아요';
      } else if (lastCatName != null && lastCatName.isNotEmpty) {
        body = rng.nextBool()
            ? '$lastCatName와 만났던 정원에 잠깐 들러볼까요?'
            : '오늘 마음은 어떤가요? 편할 때 정원에서 쉬어가세요';
      } else {
        body = '편할 때 정원에 들러 잠깐 쉬어가세요';
      }

      final now = tz.TZDateTime.from(_now(), tz.local);
      final scheduled = now.add(const Duration(days: _crisisAbsenceDays));

      await _plugin.zonedSchedule(
        _crisisId,
        '마음냥 정원 🐈‍⬛',
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'crisis_reminder',
            '정원 방문 알림',
            channelDescription: '며칠간 방문이 없을 때 한 번 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'crisis',
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 방문 알림 예약 실패: $e');
      return false;
    }
  }

  /// 오늘 아직 미션을 완수하지 않았다면, 오늘 저녁 늦게(기본 21:30) '스트릭
  /// 임박' 알림을 한 번 예약합니다. 이미 오늘 완수했거나 그 시각이 이미
  /// 지났다면 예약하지 않습니다. 완수 시점에는 [notifyMissionCompletedToday]
  /// 에서 즉시 취소됩니다.
  Future<bool> _refreshStreakReminder() async {
    try {
      await _plugin.cancel(_streakId);
      final enabled = await StorageService.getStreakEnabled();
      if (!enabled) return true;

      final completedToday = await StorageService.hasCompletedGrowthToday();
      if (completedToday) return true;

      final now = tz.TZDateTime.from(_now(), tz.local);
      final todayTarget = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        _streakHour,
        _streakMinute,
      );
      if (!todayTarget.isAfter(now)) return true; // 오늘 그 시각이 이미 지났으면 스킵

      final streak = await StorageService.getCurrentStreakCount();
      final lastCatName = _lastMetCatName();
      final String body;
      if (streak > 0 && lastCatName != null && lastCatName.isNotEmpty) {
        body = '$streak일째 함께하고 있어요, $lastCatName도 오늘을 기다리고 있어요 🐾';
      } else if (streak > 0) {
        body = '$streak일째 함께하고 있어요, 오늘도 잠깐 들러줄까요? 🐾';
      } else {
        body = '오늘 아직 마음을 돌보지 않았어요. 잠깐 들러줄까요? 🐾';
      }

      await _plugin.zonedSchedule(
        _streakId,
        '마음냥 정원 🔥',
        body,
        todayTarget,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminder',
            '스트릭 임박 알림',
            channelDescription: '오늘 아직 미션을 완수하지 않았을 때만 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'streak',
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 스트릭 알림 예약 실패: $e');
      return false;
    }
  }

  // ───────────────────────── 답장 도착 알림 on/off ─────────────────────────
  /// 그림자 고양이/마음편지 답장 도착 알림이 켜져 있는지 여부. 사용자가
  /// 마이 탭에서 명시적으로 설정한 값이 있으면 그 값을 따르고, 아직
  /// 설정한 적이 없다면 온보딩에서 알림에 동의했는지(notification_opt_in)를
  /// 기본값으로 사용합니다.
  Future<bool> replyNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final explicit = prefs.getBool('cat_reply_notifications');
    if (explicit != null) return explicit;
    return prefs.getBool('notification_opt_in') ?? false;
  }

  /// 답장 도착 알림을 켜거나 끕니다. 켤 때는 알림 권한을 요청하고, 거부되면
  /// 설정도 켜지지 않은 채 false를 반환합니다. 끌 때는 이미 예약된 답장
  /// 알림을 모두 취소합니다.
  Future<bool> setReplyNotificationsEnabled(bool enabled) async {
    await init();
    if (kIsWeb) return false;
    if (enabled) {
      final granted = await _requestPermission();
      if (!granted) return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cat_reply_notifications', enabled);
    if (enabled) {
      await restoreReplyNotification();
    } else {
      await _plugin.cancel(_catReplyId);
      await _plugin.cancel(_heartLetterReplyId);
    }
    return true;
  }

  /// 앱 시작/설정 변경 시, 아직 도착하지 않은 미확인 답장을 다시 예약합니다.
  /// 그림자 고양이와 마음편지는 각각 가장 가까운 알림을 하나씩 유지합니다.
  Future<void> restoreReplyNotification() async {
    if (kIsWeb || !await replyNotificationsEnabled()) return;
    await init();
    try {
      final next = nextScheduledReply(
        StorageService.getAllLetters(),
        now: DateTime.now(),
        isSeen: (entry) => entry.replySeen,
        availableAt: (entry) => entry.replyAvailableAt,
      );
      if (next == null) {
        await _plugin.cancel(_catReplyId);
      } else {
        await scheduleCatReplyNotification(
          catName: shadowCatById(next.catId).nameKr,
          scheduledAt: next.replyAvailableAt,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 답장 알림 복원 실패: $e');
    }
    // A separate channel/ID preserves both kinds of replies after re-enabling.
    try {
      final next = nextScheduledReply(
        SpecialLetterService.getAllEntries(),
        now: DateTime.now(),
        isSeen: (entry) => entry.replySeen,
        availableAt: (entry) => entry.replyAvailableAt,
      );
      if (next == null) {
        await _plugin.cancel(_heartLetterReplyId);
      } else {
        await scheduleHeartLetterReplyNotification(
          typeLabel: next.type.label,
          scheduledAt: next.replyAvailableAt,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('마음편지 알림 복원 실패: $e');
    }
  }

  /// 오늘 편지를 쓰면, 다음날 아침 그 고양이에게서 답장이 도착했다는
  /// 알림을 예약합니다. [scheduledAt]은 [LetterEntry.replyAvailableAt]
  /// (다음날 오전 6시)을 그대로 전달받습니다. 같은 날 편지를 여러 번 써도
  /// 알림은 하나만 남도록, 예약 전에 이전 답장 알림을 취소합니다.
  ///
  /// ⚠️ [FeatureFlags.debugInstantReply]가 true인 동안에는 실제
  /// [scheduledAt] 대신 지금부터 몇 초 뒤로 당겨서 예약합니다(테스트 전용,
  /// 알림 배너/사운드를 실기기에서 빠르게 확인하기 위함).
  Future<void> scheduleCatReplyNotification({
    required String catName,
    required DateTime scheduledAt,
  }) async {
    if (kIsWeb || !await replyNotificationsEnabled()) return;
    await init();
    try {
      final effectiveAt = FeatureFlags.debugInstantReply
          ? DateTime.now().add(
              const Duration(
                seconds: FeatureFlags.debugInstantReplyNotificationDelaySeconds,
              ),
            )
          : scheduledAt;
      if (effectiveAt.isBefore(DateTime.now())) return;
      await _plugin.cancel(_catReplyId);
      final scheduled = tz.TZDateTime.from(effectiveAt, tz.local);
      await _plugin.zonedSchedule(
        _catReplyId,
        '마음냥 정원 💌',
        '$catName에게서 답장이 도착했어요',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cat_reply',
            '고양이 답장 알림',
            channelDescription: '어제 쓴 편지에 대한 고양이의 답장이 도착했음을 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'catReply',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 답장 알림 예약 실패: $e');
    }
  }

  /// 마음편지(감사·용서·미안함·사랑)를 쓰면, 다음날 아침 답장이 도착했다는
  /// 알림을 예약합니다. 그림자 고양이 답장 알림과는 별개의 ID를 사용해
  /// 같은 날 두 종류의 답장이 겹쳐도 서로 취소되지 않습니다.
  ///
  /// ⚠️ [FeatureFlags.debugInstantReply]가 true인 동안에는 실제
  /// [scheduledAt] 대신 지금부터 몇 초 뒤로 당겨서 예약합니다(테스트 전용).
  Future<void> scheduleHeartLetterReplyNotification({
    required String typeLabel,
    required DateTime scheduledAt,
  }) async {
    if (kIsWeb || !await replyNotificationsEnabled()) return;
    await init();
    try {
      final effectiveAt = FeatureFlags.debugInstantReply
          ? DateTime.now().add(
              const Duration(
                seconds: FeatureFlags.debugInstantReplyNotificationDelaySeconds,
              ),
            )
          : scheduledAt;
      if (effectiveAt.isBefore(DateTime.now())) return;
      await _plugin.cancel(_heartLetterReplyId);
      final scheduled = tz.TZDateTime.from(effectiveAt, tz.local);
      await _plugin.zonedSchedule(
        _heartLetterReplyId,
        '마음냥 정원 💌',
        '$typeLabel의 답장이 도착했어요',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'heart_letter_reply',
            '마음편지 답장 알림',
            channelDescription: '어제 쓴 마음편지에 대한 답장이 도착했음을 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'heartLetterReply',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 마음편지 답장 알림 예약 실패: $e');
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// [ChangeNotifier.notifyListeners]는 protected라 외부에서 바로 호출할 수
/// 없으므로, 공개 메서드 [fire]로 감싸 딥링크 발생을 알립니다.
class _DeepLinkNotifier extends ChangeNotifier {
  void fire() => notifyListeners();
}
