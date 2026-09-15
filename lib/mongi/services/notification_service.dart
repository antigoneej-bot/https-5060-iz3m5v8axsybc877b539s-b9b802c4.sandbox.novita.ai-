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
/// - 앱은 한국어 전용이므로 타임존은 'Asia/Seoul'로 고정한다(단순함 우선 - MVP 원칙).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 21001;
  static const String _channelId = 'mongi_daily_reminder_channel';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 매번 같은 문구면 지루하니, 예약할 때마다 랜덤으로 하나를 골라 보여준다.
  /// [NotificationContent]가 주어지지 않은 호출부(과거 코드/테스트 등)를 위한
  /// 한국어 기본값 - 실제 앱은 [scheduleDaily]의 [content] 인자로 사용자
  /// 언어에 맞는 [NotificationContent]를 넘겨준다(main.dart/settings_screen.dart).
  static const String _defaultTitle = '몽이 🐱';
  static const String _defaultChannelName = '오늘의 마음 리마인더';
  static const String _defaultChannelDescription =
      '매일 정해진 시각에 몽이가 마음을 나누자고 알려줘요.';
  static const List<String> _defaultMessages = [
    '몽이가 오늘 하루는 어땠는지 궁금해하고 있어요 🐾',
    '마음속에 쌓인 감정이 있다면, 몽이에게 나눠주세요 🐱',
    '오늘도 몽이와 함께 마음정원을 가꿔볼까요? 🌱',
    '잠깐, 오늘의 감정을 몽이에게 들려주지 않을래요? 🌸',
    '몽이가 작은 정원에서 당신을 기다리고 있어요 🌷',
  ];

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
  /// 기존 한국어 기본값을 그대로 사용한다(하위 호환).
  Future<bool> scheduleDaily(
    int hour,
    int minute, {
    String? personalizedMessage,
    NotificationContent? content,
  }) async {
    if (kIsWeb) return false;
    await init();
    if (!_initialized) return false;
    final granted = await requestPermission();
    if (!granted) return false;

    final title = content?.title ?? _defaultTitle;
    final channelName = content?.channelName ?? _defaultChannelName;
    final channelDescription =
        content?.channelDescription ?? _defaultChannelDescription;
    final messages = content?.reminderMessages ?? _defaultMessages;
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
