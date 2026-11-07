import '../../l10n/app_language.dart';
import '../l10n/gen/app_localizations.dart';
import '../../services/notification_service.dart' as host;
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/notification_l10n.dart';

/// 매일 정해진 시각에 "몽이가 기다리고 있어요" 알림을 보내는 리텐션용 서비스.
///
/// - 결제와 무관하게, 3일차 이후 재방문율을 높이기 위한 가장 기본적인 장치.
/// - Android 전용 기능이며, 웹(kIsWeb)에서는 조용히 아무 것도 하지 않는다
///   (프리뷰/웹 데모에서 알림 권한 팝업이 뜨는 것을 방지).
/// - 알림은 호스트 서비스가 초기화한 기기 타임존을 사용한다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 21001;
  static const String _channelId = 'mongi_daily_reminder_channel';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 알림은 핵심 기능이 아니므로, 플랫폼 미지원/테스트 환경 등 어떤 이유로든
  /// 초기화에 실패해도 예외를 삼켜 앱 전체가 죽지 않도록 방어적으로 처리한다.
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      // Keep the unified app's notification response handler intact.
      await host.NotificationService().init();
      _initialized = true;
    } catch (_) {
      // 알림 플러그인을 쓸 수 없는 환경(위젯 테스트, 미지원 플랫폼 등) - 무시.
    }
  }

  /// Android 13+에서는 알림 권한을 명시적으로 요청해야 한다.
  /// 이미 허용됐거나(구버전 포함) 요청이 필요 없는 경우 true를 반환한다.
  Future<bool> requestPermission() async {
    if (kIsWeb || !_initialized) return false;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl == null) return true;
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  /// 매일 [hour]:[minute]에 반복되는 리마인더 알림을 예약한다.
  /// 이미 예약된 알림이 있다면 새 시각/문구로 덮어쓴다(cancel 불필요, 같은 id 재사용).
  ///
  /// [personalizedMessage]가 주어지면(유저의 스트릭/컬렉션/성장 상태 기반으로
  /// [EmotionInsightService.buildPersonalizedReminder]가 계산한 문구) 그걸
  /// 우선 사용하고, 없으면 [content]의 문구 목록 중 하나를 랜덤으로 고른다.
  ///
  /// [content]는 이 서비스가 직접 접근할 수 없는 [AppLocalizations]로부터
  /// 만들어진 지역화 콘텐츠(제목/채널명/채널설명/문구 목록)이며, 호출부가
  /// [BuildContext]를 가진 위치(main.dart 부트스트랩, settings_screen.dart)
  /// 에서 `notificationContent(l10n)`으로 만들어 넘겨준다. 넘기지 않으면
  /// 현재 앱 언어의 기본 알림 문구를 사용한다.
  Future<bool> scheduleDaily(
    int hour,
    int minute, {
    String? personalizedMessage,
    NotificationContent? content,
    bool requestPermissions = true,
  }) async {
    if (kIsWeb) return false;
    await init();
    if (!_initialized) return false;
    if (requestPermissions && !await requestPermission()) return false;

    content ??= notificationContent(
      lookupAppLocalizations(AppLanguage.instance.locale),
    );
    final title = content.title;
    final channelName = content.channelName;
    final channelDescription = content.channelDescription;
    final messages = content.reminderMessages;
    final message =
        personalizedMessage ?? messages[Random().nextInt(messages.length)];

    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        title,
        message,
        _nextInstanceOf(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelDaily() async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;
    try {
      await _plugin.cancel(_dailyReminderId);
    } catch (_) {
      // 무시 - 알림 취소 실패가 앱 흐름을 막으면 안 된다.
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
