/// "감사 한 줄 / 작은 성취 기록" 화면에서 남길 수 있는 두 가지 기록 종류.
///
/// 감사 일기(gratitude journaling)와 작은 성취 기록(small wins journal)은
/// 둘 다 널리 알려진 긍정심리학 기반 습관으로, 매일 부담 없이 한 줄만
/// 적어도 꾸준히 쌓이면 마음에 긍정적인 영향을 준다는 점에서 채택했다.
enum GratitudeEntryType {
  gratitude,
  achievement;

  String get id => name;

  String get emoji => switch (this) {
    GratitudeEntryType.gratitude => '🙏',
    GratitudeEntryType.achievement => '🌟',
  };

  String get label => switch (this) {
    GratitudeEntryType.gratitude => '감사한 일',
    GratitudeEntryType.achievement => '작은 성취',
  };

  String get hint => switch (this) {
    GratitudeEntryType.gratitude => '오늘, 어떤 것에 감사했나요?',
    GratitudeEntryType.achievement => '오늘, 스스로 해낸 작은 일이 있나요?',
  };

  String get placeholder => switch (this) {
    GratitudeEntryType.gratitude => '예: 오늘 햇살이 참 따뜻했어요',
    GratitudeEntryType.achievement => '예: 오늘은 늦지 않고 일어났어요',
  };

  static GratitudeEntryType fromId(String? id) {
    return GratitudeEntryType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => GratitudeEntryType.gratitude,
    );
  }
}
