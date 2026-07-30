import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../data/shadow_cats_data.dart';
import 'storage_service.dart';

/// 로컬 알림 리마인더 서비스.
/// 서버/네트워크 없이 기기 안에서만 예약 · 반복되며, 사용자가 마이 탭에서
/// 알림 종류별로 언제든 켜고 끌 수 있습니다.
///
/// 지원하는 알림 종류:
/// - 아침 알림: 매일 정해진 시각(기본 오전 9시)에 오늘의 감정 체크를 유도
/// - 저녁 알림: 매일 정해진 시각(기본 오후 8시)에 하루 닫기를 유도
/// - 위기 알림: 3일 이상 앱을 열지 않았을 때만 조건부로 한 번 발송
/// - 스트릭 임박 알림: 오늘 아직 미션을 완수하지 않았을 때만 저녁 늦게 발송
///
/// 알림을 탭하면 [pendingDeepLink]에 종류별 payload가 기록되고, 앱은 이를
/// 읽어 알맞은 화면으로 이동합니다(딥링크).
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  // 알림 종류별 고유 ID. 레거시(v1) 단일 알림은 마이그레이션 시 취소됩니다.
  static const int _legacyDailyReminderId = 1001;
  static const int _morningId = 1002;
  static const int _eveningId = 1003;
  static const int _crisisId = 1004;
  static const int _streakId = 1005;
  static const int _catReplyId = 1006;

  static const int _crisisAbsenceDays = 3;
  static const int _streakHour = 21;
  static const int _streakMinute = 30;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 알림을 탭해서 앱이 열렸을 때, 이동해야 할 화면을 알려주는 딱지값입니다.
  /// 'morning' | 'evening' | 'crisis' | 'streak' 중 하나이며, 소비하면
  /// [consumePendingDeepLink]로 비웁니다.
  String? pendingDeepLink;

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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
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
  }

  void _onNotificationTap(NotificationResponse response) {
    pendingDeepLink = response.payload;
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

  // ───────────────────────── 위기 / 스트릭 알림 on/off ─────────────────────────
  Future<bool> isCrisisEnabled() => StorageService.getCrisisEnabled();
  Future<void> setCrisisEnabled(bool v) async {
    await StorageService.setCrisisEnabled(v);
    if (!v && !kIsWeb) await _plugin.cancel(_crisisId);
  }

  Future<bool> isStreakEnabled() => StorageService.getStreakEnabled();
  Future<void> setStreakEnabled(bool v) async {
    await StorageService.setStreakEnabled(v);
    if (!v && !kIsWeb) await _plugin.cancel(_streakId);
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
    await _refreshCrisisReminder();
    await _refreshStreakReminder();
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
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 권한 요청 실패: $e');
      return true;
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

  /// 마지막 방문일로부터 3일 이상 지났다면(또는 앞으로 3일 뒤에 지나게 된다면)
  /// '고양이가 외로워하고 있어요' 알림을 한 번 예약합니다. 앱을 열 때마다
  /// 호출되어, 사용자가 이 기간 안에 재방문하면 다음 호출에서 자동으로
  /// 다시 미래로 재예약되므로 실제로는 '앱을 3일 이상 열지 않았을 때만'
  /// 발송되는 효과를 냅니다.
  Future<void> _refreshCrisisReminder() async {
    try {
      await _plugin.cancel(_crisisId);
      final enabled = await StorageService.getCrisisEnabled();
      if (!enabled) return;

      final name = await StorageService.getCompanionName();
      final lastCatName = _lastMetCatName();
      final rng = Random();
      final String body;
      if (name != null && name.trim().isNotEmpty) {
        body = '${name.trim()}가 조금 외로워하고 있어요';
      } else if (lastCatName != null && lastCatName.isNotEmpty) {
        body = rng.nextBool()
            ? '$lastCatName가 다시 만나길 기다리고 있어요'
            : '마지막으로 만난 $lastCatName, 요즘 어떻게 지내나요?';
      } else {
        body = '그림자 고양이들이 조금 외로워하고 있어요';
      }

      final now = tz.TZDateTime.now(tz.local);
      final scheduled = now.add(const Duration(days: _crisisAbsenceDays));

      await _plugin.zonedSchedule(
        _crisisId,
        '마음냥 정원 🐈‍⬛',
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'crisis_reminder',
            '위기 리마인더',
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
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 위기 알림 예약 실패: $e');
    }
  }

  /// 오늘 아직 미션을 완수하지 않았다면, 오늘 저녁 늦게(기본 21:30) '스트릭
  /// 임박' 알림을 한 번 예약합니다. 이미 오늘 완수했거나 그 시각이 이미
  /// 지났다면 예약하지 않습니다. 완수 시점에는 [notifyMissionCompletedToday]
  /// 에서 즉시 취소됩니다.
  Future<void> _refreshStreakReminder() async {
    try {
      await _plugin.cancel(_streakId);
      final enabled = await StorageService.getStreakEnabled();
      if (!enabled) return;

      final completedToday = await StorageService.hasCompletedGrowthToday();
      if (completedToday) return;

      final now = tz.TZDateTime.now(tz.local);
      final todayTarget = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        _streakHour,
        _streakMinute,
      );
      if (todayTarget.isBefore(now)) return; // 오늘 그 시각이 이미 지났으면 스킵

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
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService 스트릭 알림 예약 실패: $e');
    }
  }

  /// 오늘 편지를 쓰면, 다음날 아침 그 고양이에게서 답장이 도착했다는
  /// 알림을 예약합니다. [scheduledAt]은 [LetterEntry.replyAvailableAt]
  /// (다음날 오전 6시)을 그대로 전달받습니다. 같은 날 편지를 여러 번 써도
  /// 알림은 하나만 남도록, 예약 전에 이전 답장 알림을 취소합니다.
  Future<void> scheduleCatReplyNotification({
    required String catName,
    required DateTime scheduledAt,
  }) async {
    if (kIsWeb) return;
    await init();
    try {
      await _plugin.cancel(_catReplyId);
      if (scheduledAt.isBefore(DateTime.now())) return;
      final scheduled = tz.TZDateTime.from(scheduledAt, tz.local);
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
