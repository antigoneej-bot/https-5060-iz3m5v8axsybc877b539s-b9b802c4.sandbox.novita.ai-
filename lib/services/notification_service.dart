import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

/// 하루 한 번, 정해진 시간에 "고양이를 아직 돌보지 않았어요" 리마인더를
/// 보내는 로컬 알림 서비스입니다. 서버/네트워크 없이 기기 안에서만
/// 예약 · 반복되며, 사용자가 마이 탭에서 언제든 켜고 끌 수 있습니다.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const int _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 앱 실행 시 1회 초기화합니다. 알림 권한은 이 시점에는 요청하지 않고,
  /// 사용자가 설정에서 알림을 켤 때 [requestPermissionAndSchedule]에서
  /// 명시적으로 요청합니다(불필요한 권한 팝업으로 첫 인상을 해치지 않기 위함).
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      // 웹 플랫폼은 로컬 알림 예약을 지원하지 않으므로, 웹 프리뷰에서는
      // 초기화만 완료 처리하고 실제 알림 기능은 비활성 상태로 둡니다.
      _initialized = true;
      return;
    }
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    try {
      await _plugin.initialize(initSettings);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService init 실패: $e');
    }
    _initialized = true;
  }

  /// 현재 알림 리마인더가 켜져 있는지 여부 (사용자 설정값, 기기 전체 공통).
  Future<bool> isEnabled() => StorageService.getReminderEnabled();

  /// 리마인더 시각(시, 분) - 기본 오후 8시.
  Future<(int, int)> getReminderTime() => StorageService.getReminderTime();

  /// 사용자가 마이 탭에서 리마인더를 켤 때 호출합니다.
  /// 권한을 요청하고, 승인되면 매일 반복 알림을 예약합니다.
  Future<bool> enableReminder({int hour = 20, int minute = 0}) async {
    await init();
    if (kIsWeb) {
      // 웹 프리뷰에서는 설정값만 저장하고 실제 알림은 예약하지 않습니다
      // (모바일 앱(APK)에서 정상 동작합니다).
      await StorageService.setReminderEnabled(true);
      await StorageService.setReminderTime(hour, minute);
      return true;
    }
    final granted = await _requestPermission();
    if (!granted) {
      await StorageService.setReminderEnabled(false);
      return false;
    }
    await StorageService.setReminderEnabled(true);
    await StorageService.setReminderTime(hour, minute);
    await _scheduleDaily(hour, minute);
    return true;
  }

  /// 사용자가 리마인더를 끌 때 호출합니다.
  Future<void> disableReminder() async {
    await StorageService.setReminderEnabled(false);
    if (kIsWeb) return;
    await _plugin.cancel(_dailyReminderId);
  }

  /// 리마인더 시각을 변경합니다(이미 켜져 있는 경우에만 재예약).
  Future<void> updateReminderTime(int hour, int minute) async {
    await StorageService.setReminderTime(hour, minute);
    final enabled = await StorageService.getReminderEnabled();
    if (enabled && !kIsWeb) {
      await _scheduleDaily(hour, minute);
    }
  }

  /// 앱 시작 시, 이미 켜져 있는 설정이 있다면 알림을 재예약합니다
  /// (기기 재부팅 등으로 예약이 날아갔을 가능성에 대비).
  Future<void> restoreIfEnabled() async {
    await init();
    if (kIsWeb) return;
    final enabled = await StorageService.getReminderEnabled();
    if (!enabled) return;
    final (hour, minute) = await StorageService.getReminderTime();
    await _scheduleDaily(hour, minute);
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
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 권한 요청 실패: $e');
      return true;
    }
  }

  Future<void> _scheduleDaily(int hour, int minute) async {
    try {
      final scheduled = _nextInstanceOf(hour, minute);
      await _plugin.zonedSchedule(
        _dailyReminderId,
        '고양이가 기다리고 있어요 🐈',
        '오늘 아직 마음을 돌보지 않았어요. 잠깐 들러서 밥과 물을 챙겨줄까요?',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_care_reminder',
            '데일리 돌보기 리마인더',
            channelDescription: '매일 정해진 시간에 고양이 돌보기를 잊지 않도록 알려드립니다.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 예약 실패: $e');
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
