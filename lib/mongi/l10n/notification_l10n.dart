import 'gen/app_localizations.dart';

/// [NotificationService.scheduleDaily]에 전달할, 언어별로 지역화된 알림
/// 콘텐츠를 한곳에 모아 담는 값 객체.
///
/// [NotificationService] 자체는 [AppLocalizations]/[BuildContext]에
/// 접근할 수 없는 순수 서비스 클래스이므로, 지역화는 항상
/// [BuildContext]를 가진 호출부(main.dart의 부트스트랩, settings_screen.dart)
/// 에서 이 헬퍼로 만들어 넘겨준다. 넘겨주지 않으면(null) 서비스는 기존
/// 한국어 기본값을 그대로 사용한다(하위 호환).
class NotificationContent {
  final String title;
  final String channelName;
  final String channelDescription;
  final List<String> reminderMessages;

  const NotificationContent({
    required this.title,
    required this.channelName,
    required this.channelDescription,
    required this.reminderMessages,
  });
}

NotificationContent notificationContent(AppLocalizations l10n) {
  return NotificationContent(
    title: l10n.notificationTitle,
    channelName: l10n.notificationChannelName,
    channelDescription: l10n.notificationChannelDescription,
    reminderMessages: [
      l10n.notificationReminderMessage1,
      l10n.notificationReminderMessage2,
      l10n.notificationReminderMessage3,
      l10n.notificationReminderMessage4,
      l10n.notificationReminderMessage5,
    ],
  );
}
