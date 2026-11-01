import 'dart:convert';
import 'companion_journey.dart';

/// Device-local consent, deliberately excluded from record backups.
class CompanionReminderSettings {
  final bool enabled;
  final int hour, minute;
  const CompanionReminderSettings({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
  });

  bool get validTime => hour >= 8 && hour <= 21 && minute >= 0 && minute < 60;

  String encode() => jsonEncode({
    'version': 1,
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
  });

  static CompanionReminderSettings decode(String? source) {
    if (source == null) return const CompanionReminderSettings();
    final raw = jsonDecode(source);
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['enabled'] is! bool ||
        raw['hour'] is! int ||
        raw['minute'] is! int) {
      throw const FormatException('고양이 소식 설정을 읽지 못했어요.');
    }
    final result = CompanionReminderSettings(
      enabled: raw['enabled'],
      hour: raw['hour'],
      minute: raw['minute'],
    );
    if (!result.validTime) throw const FormatException('알림 시간을 확인해 주세요.');
    return result;
  }
}

class CompanionInvitation {
  static const actions = [
    CompanionMoment.feed,
    CompanionMoment.play,
    CompanionMoment.pet,
    CompanionMoment.rest,
  ];
  final CompanionMoment action;
  final String day;
  const CompanionInvitation(this.action, this.day);

  String get payload => 'companionCare:v1:${action.name}:$day';

  static CompanionInvitation? parse(String? payload) {
    if (payload == null) return null;
    final parts = payload.split(':');
    if (parts.length != 4 || parts[0] != 'companionCare' || parts[1] != 'v1') {
      return null;
    }
    final matching = actions.where((a) => a.name == parts[2]);
    final date = DateTime.tryParse(parts[3]);
    if (matching.isEmpty || date == null || companionDay(date) != parts[3]) {
      return null;
    }
    return CompanionInvitation(matching.first, parts[3]);
  }

  static String message(CompanionMoment action) => switch (action) {
    CompanionMoment.feed => '조금 출출해졌어. 밥 먹고 같이 쉴까? 🐾',
    CompanionMoment.play => '나랑 잠깐 놀아 줄래? 장난감을 찾았어!',
    CompanionMoment.pet => '오늘은 네 손길이 좋아. 살짝 쓰다듬어 줄래?',
    _ => '내 옆에서 잠깐 쉬어 갈래? 오늘도 함께 있고 싶어.',
  };

  static String label(CompanionMoment action) => switch (action) {
    CompanionMoment.feed => '밥 주기',
    CompanionMoment.play => '놀아주기',
    CompanionMoment.pet => '쓰다듬기',
    _ => '같이 쉬기',
  };
}

class CompanionReminderSlot {
  final DateTime when;
  final CompanionInvitation invitation;
  const CompanionReminderSlot(this.when, this.invitation);
  int get id =>
      2200 +
      DateTime.utc(
            when.year,
            when.month,
            when.day,
          ).difference(DateTime.utc(2020)).inDays %
          8;
  Map<String, String> toLedger() => {
    'day': invitation.day,
    'when': when.toUtc().toIso8601String(),
  };
}

/// One gentle invitation per date, with no repeating OS schedule. After a
/// week away the invitations stop until the next foreground visit.
List<CompanionReminderSlot> planCompanionReminders({
  required DateTime now,
  required CompanionReminderSettings settings,
  required CompanionJourney journey,
  String? consumedDay,
}) {
  if (!settings.enabled || !settings.validTime) return const [];
  final today = companionDay(now);
  final caredToday = [
    ...CompanionInvitation.actions,
    CompanionMoment.brush,
    CompanionMoment.care,
  ].any((action) => journey.didToday(action, now));
  final result = <CompanionReminderSlot>[];
  for (var offset = 0; offset <= 7 && result.length < 7; offset++) {
    // Calendar construction, not 24-hour addition: daylight-saving safe.
    final when = DateTime(
      now.year,
      now.month,
      now.day + offset,
      settings.hour,
      settings.minute,
    );
    final day = companionDay(when);
    if (!when.isAfter(now.add(const Duration(minutes: 1))) ||
        day == consumedDay ||
        (day == today && caredToday))
      continue;
    final ordinal = DateTime.utc(
      when.year,
      when.month,
      when.day,
    ).difference(DateTime.utc(2020)).inDays;
    final action = CompanionInvitation.actions[ordinal % 4];
    result.add(CompanionReminderSlot(when, CompanionInvitation(action, day)));
  }
  return List.unmodifiable(result);
}
