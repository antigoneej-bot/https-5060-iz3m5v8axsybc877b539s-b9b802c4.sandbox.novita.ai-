import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/reply_situation.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  test('past feelings and another person are not treated as current self', () {
    for (final text in [
      '나는 엄마가 외로워 보이는 게 걱정돼.',
      '엄마가 많이 피곤해.',
      '나는 작년에 너무 지쳤어.',
      '예전에 상사가 내 말을 무시해서 화났어. 지금은 풀렸어.',
      '나는 그때는 외로웠어. 이제는 편안해.',
    ]) {
      expect(ReplySituation.detect(text), isNull, reason: text);
      final reply = PersonalReplyEngine(
        random: Random(3),
      ).compose(letterText: text, style: ReplyStyle.listen, catName: '몽이');
      expect(
        reply.topic,
        text.startsWith('나는 엄마가') ? 'family' : 'general',
        reason: text,
      );
      expect(reply.text, contains(text));
    }
  });
  test('explicit mixed feelings retain both sides', () {
    final s = ReplySituation.detect('나는 합격해서 기쁘지만 앞으로가 불안해.')!;
    expect(s.id, 'joy_and_worry');
    final reply = PersonalReplyEngine(random: Random(3)).compose(
      letterText: '나는 합격해서 기쁘지만 앞으로가 불안해.',
      style: ReplyStyle.listen,
      catName: '몽이',
    );
    expect(reply.parts.any(s.listening.contains), isTrue);
    expect(ReplySituation.detect('나는 기쁘지만 불안하지 않아.'), isNull);
    expect(ReplySituation.detect('친구가 기쁘지만 불안하대.'), isNull);
  });
  test(
    'reflection and suggestion do not repeat the preceding three extras',
    () {
      for (final style in [ReplyStyle.reflect, ReplyStyle.suggest]) {
        final history = <List<String>>[];
        for (var i = 0; i < 12; i++) {
          final reply = PersonalReplyEngine(random: Random(i)).compose(
            letterText: '나는 오늘 외로워.',
            style: style,
            catName: '몽이',
            recentParts: history.reversed.toList(),
          );
          expect(
            history.reversed.take(3).map((p) => p[2]),
            isNot(contains(reply.parts[2])),
          );
          history.add(reply.parts);
        }
      }
    },
  );
}
