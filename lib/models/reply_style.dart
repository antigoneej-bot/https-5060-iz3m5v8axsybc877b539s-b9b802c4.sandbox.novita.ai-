/// Stored by name; absent/unknown values from older backups default to listening.
enum ReplyStyle { listen, reflect, suggest }
ReplyStyle parseReplyStyle(Object? value) => ReplyStyle.values.firstWhere(
  (style) => style.name == value, orElse: () => ReplyStyle.listen);
extension ReplyStyleLabel on ReplyStyle {
  String get label => switch (this) {
    ReplyStyle.listen => '그냥 들어주기',
    ReplyStyle.reflect => '함께 정리하기',
    ReplyStyle.suggest => '작은 제안',
  };
}
