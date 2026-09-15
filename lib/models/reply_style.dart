/// Stored by name; absent/unknown values from older backups default to listening.
enum ReplyStyle { listen, reflect, suggest }

ReplyStyle parseReplyStyle(Object? value) => ReplyStyle.values.firstWhere(
  (style) => style.name == value,
  orElse: () => ReplyStyle.listen,
);

extension ReplyStyleLabel on ReplyStyle {
  String get label => switch (this) {
    ReplyStyle.listen => '그냥 들어줘',
    ReplyStyle.reflect => '같이 정리해줘',
    ReplyStyle.suggest => '작은 방법을 알려줘',
  };
}
