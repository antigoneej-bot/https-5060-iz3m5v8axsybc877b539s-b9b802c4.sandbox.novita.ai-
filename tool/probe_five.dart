// Debug probe: for each failing-test input, show AcceptanceReplyMatcher.detect()
// result and what compose() actually returns, to distinguish "acceptance pack
// correctly claims this text" from "acceptance pack wrongly claims this text".
import '../lib/services/acceptance_reply_matcher.dart';
import '../lib/services/personal_reply_engine.dart';
import '../lib/models/reply_style.dart';
import 'dart:math';

void show(String label, String text, {ReplyStyle style = ReplyStyle.listen}) {
  final cat = AcceptanceReplyMatcher.detect(text);
  final reply = PersonalReplyEngine(random: Random(1))
      .compose(letterText: text, style: style, catName: '테스트');
  print('$label\n  text: $text\n  acceptance-category: $cat\n  situation: ${reply.situation}\n  parts.length: ${reply.parts.length}\n  text-out: ${reply.text.replaceAll('\n', ' / ')}\n');
}

void main() {
  print('--- care_reply_upgrade_test.dart contexts ---');
  for (final t in ['월세와 대출 때문에 계산을 하고 있어.', '과제를 마쳤어.', '남자친구와 헤어졌어.', '오늘 너무 피곤해.']) {
    show('context', t);
  }
  print('--- check_personal_replies.dart diary ---');
  show('diary', '친구가 약속을 취소했어. 기다린 시간이 아까워서 서운해.');
  print('--- reply_tone_test.dart gratitude screenshot ---');
  show('gratitude', '오늘도 무사히 일을 마쳤습니다. 함께한 모든 이들에게 감사합니다.');
  print('--- reply_tone_test.dart explicit listening request ---');
  show('listen-req', '너무 속상해. 조언하지 말고 그냥 들어줘.', style: ReplyStyle.suggest);
  print('--- reply_tone_test.dart negative feedback ---');
  show('gratitude-short', '고마워.');
}
