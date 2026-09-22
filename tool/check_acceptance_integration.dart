// Run on a machine with Dart: dart run tool/check_acceptance_integration.dart
// Tests the real engine, without Flutter, Hive or a translated implementation.
import 'dart:math';
import '../lib/services/personal_reply_engine.dart';
import '../lib/services/acceptance_reply_matcher.dart';
import '../lib/data/replies/acceptance_reply_content.dart';
import '../lib/models/reply_style.dart';
import 'reply_contract.dart';

void main() {
  var checks = 0;
  void verify(bool ok, String message) {
    if (!ok) throw StateError(message);
    checks++;
  }
  for (var seed = 0; seed < 40; seed++) {
    for (final style in ReplyStyle.values) {
      PersonalReply reply(String text, {Set<String> avoided = const {},
          List<List<String>> history = const [], List<String> texts = const [],
          List<String> disliked = const []}) =>
        PersonalReplyEngine(random: Random(seed)).compose(
          letterText: text, style: style, catName: '마음냥',
          avoidedSituations: avoided, recentParts: history,
          recentTexts: texts, dislikedTexts: disliked);
      for (final blocked in ['tone:gratitude', 'accept:17']) {
        final r = reply('고마워.', avoided: {blocked});
        verify(r.situation == 'tone:neutral', 'feedback bypass: $blocked');
        verify(r.topic == 'general', 'feedback must not retain a guessed topic');
        verify(followsReplyContract(r, style), 'neutral reply contract');
      }
      final oldSituation = reply('나는 오늘 외로워.', avoided: {'lonely'});
      verify(oldSituation.situation == 'tone:neutral', 'legacy rejection bypass');
      for (final text in [
        '너무 속상해. 조언하지 말고 그냥 들어줘.',
        '화가 나지만 말하고 싶지 않아.',
        '기뻐. 질문하지 마.',
        '서운해. 묻지 마.',
        '그냥 들어줘.',
      ]) {
        final r = reply(text);
        verify(r.situation == 'accept:23', 'explicit refusal routing: $text');
        verify(followsReplyContract(r, ReplyStyle.listen), 'receive-only content');
        verify(!r.text.contains('?'), 'no question under refusal');
      }
      final gratitude = reply('오늘도 무사히 일을 마쳤습니다. 함께한 모든 이들에게 감사합니다.');
      verify(gratitude.situation == 'accept:18', 'specific gratitude route');
      verify(followsReplyContract(gratitude, style), 'gratitude complete body');
      verify(gratitude.text.contains('무사히') && gratitude.text.contains('함께한'),
          'gratitude must retain both explicit details');
      final pool = acceptanceReplyContent['02']!.receive;
      final a = pool[0].text, b = pool[1].text;
      final next = reply('친구가 약속을 취소해서 서운해.',
          history: [[a]], texts: ['$a\n\n— 마음냥'], disliked: [b]);
      verify(next.parts.single != a, 'fresh candidate must outrank repeat');
    }
    final e = PersonalReplyEngine(random: Random(seed));
    final history = <List<String>>[];
    final texts = <String>[];
    final pool = acceptanceReplyContent['02']!.receive.map((r) => r.text).toSet();
    for (var n = 0; n < 10; n++) {
      final r = e.compose(letterText: '친구가 약속을 취소해서 서운해.',
          style: ReplyStyle.listen, catName: '마음냥',
          recentParts: history.reversed.toList(), recentTexts: texts.reversed.toList());
      final used = history.reversed.take(3).expand((p) => p).toSet();
      final available = pool.difference(used);
      verify(r.situation == 'accept:02', 'exhaustion never changes feeling');
      verify(followsReplyContract(r, ReplyStyle.listen), 'exhaustion remains bounded');
      if (available.isNotEmpty) verify(available.contains(r.parts.single), 'use fresh while available');
      history.add(r.parts); texts.add(r.text);
    }
  }
  verify(AcceptanceReplyMatcher.detect('오늘은 슬프지 않아.') != '03', 'negation');
  verify(AcceptanceReplyMatcher.detect('친구가 외롭다고 했어.') == null, 'other speaker');
  print('$checks real Dart engine integration checks passed. No UI/storage claim.');
}
