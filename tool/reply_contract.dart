import 'package:flutter_app/data/replies/acceptance_reply_content.dart';
import 'package:flutter_app/data/replies/reply_tone_content.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/models/reply_style.dart';

/// Checks content membership as well as storage shape. One acceptance part is
/// a complete authored reply, not a license to drop listening-mode guarantees.
bool followsReplyContract(PersonalReply reply, ReplyStyle effectiveStyle) {
  final id = reply.situation;
  if (id != null && id.startsWith('accept:')) {
    final category = acceptanceReplyContent[id.substring(7)];
    if (category == null || reply.parts.length != 1) return false;
    final allowed = effectiveStyle == ReplyStyle.listen
        ? category.receive : category.replies;
    return allowed.any((entry) => entry.text == reply.parts.single) &&
        reply.text.startsWith('${reply.parts.single}\n\n— ');
  }
  return reply.parts.length == (effectiveStyle == ReplyStyle.listen ? 3 : 4);
}

bool containsNoExtraModule(PersonalReply reply) {
  final extras = <String>{
    for (final tone in replyToneContent.values)
      ...tone['reflections']!,
    for (final tone in replyToneContent.values)
      ...tone['suggestions']!,
  };
  return !reply.parts.any(extras.contains);
}
