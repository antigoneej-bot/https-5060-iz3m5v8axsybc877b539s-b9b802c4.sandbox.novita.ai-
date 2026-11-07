import 'gen/app_localizations.dart';

/// [NotificationService.scheduleDaily]에 전달할, 언어별로 지역화된 알림
/// 콘텐츠를 한곳에 모아 담는 값 객체.
///
/// 화면에서 명시적으로 전달하거나, 서비스가 현재 앱 언어로 생성한다.
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
