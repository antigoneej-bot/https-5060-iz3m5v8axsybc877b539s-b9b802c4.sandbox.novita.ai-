import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/reply_situation.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  final cases = <String, String?>{
    '상사가 내 말을 무시해서 화났어.': 'dismissed_angry',
    '오늘 상사가 내 말을 무시했어. 화가 났어.': 'dismissed_angry',
    '상사에게 화냈는데 계속 마음에 걸려.': 'anger_regret',
    '내가 상사에게 화를 냈어. 후회돼.': 'anger_regret',
    '상사가 칭찬했는데 부담스러워.': 'praise_pressure',
    '칭찬받았지만 부담이 커.': 'praise_pressure',
    '면접 떨어졌어. 엄마는 괜찮다고 하는데 더 미안해.': 'interview_guilt',
    '오늘 면접에서 떨어졌어. 어머니는 괜찮다고 하시는데 미안해.': 'interview_guilt',
    '상사가 내 말을 무시했지만 화나지 않았어.': null,
    '상사가 내 말을 무시한 건 아니야. 화났던 건 다른 일이야.': null,
    '친구가 상사에게 화냈는데 후회한대.': null,
    '상사가 나에게 화냈는데 마음에 걸려.': null,
    '상사에게 화냈다면 후회했을 거야.': null,
    '상사에게 화냈다고 친구가 말했어. 후회한대.': null,
    '칭찬받았지만 부담스럽지 않아.': null,
    '칭찬받았는데 부담이 없어.': null,
    '친구가 칭찬받았는데 부담스럽대.': null,
    '면접 떨어졌어. 엄마가 미안해.': null,
    '친구가 면접 떨어졌어. 엄마는 괜찮다고 하는데 더 미안해.': null,
    '면접에 떨어졌다면 엄마는 괜찮다고 했을까. 미안해.': null,
    '“상사가 칭찬했는데 부담스러워.” 소설의 대사야.': null,
    '「상사에게 화냈는데 마음에 걸려」라고 친구가 말했어.': null,
    '엄마가 상사에게 화냈는데 마음에 걸린대.': null,
    '면접 합격했어. 엄마가 좋아해.': null,
    '오늘은 기뻐.': null,
    '피곤하지 않아.': null,
    '나는 괜찮아. 엄마가 슬퍼해.': null,
    '돈이 걱정돼. 친구에게 고마워.': null,
    '아무것도 쓰고 싶지 않아.': null,
    '조언하지 말아줘.': null,
    '고마워.': null,
    ' ': null,
    '😀': null,
    '오늘 병원에 다녀왔어.': null,
    '친구와 화해했어.': null,
    '상사에게 칭찬했는데 부담스러워.': null,
    '상사가 화났어. 나는 미안해.': null,
    '내가 엄마에게 화냈는데 후회돼.': null,
    '시험에 떨어져서 속상해.': null,
    '합격했지만 불안해.': null,
    '너무 잘됐네. 또 야근이라니.': null,
    '소설에서 상사가 내 말을 무시해서 화났어.': null,
    '예를 들어 상사가 칭찬했는데 부담스럽다면.': null,
    '동료가 칭찬받았지만 부담스러워.': null,
    '언니가 상사에게 화냈는데 마음에 걸려.': null,
    '오빠가 상사에게 화냈는데 후회돼.': null,
    '동생이 면접 떨어졌어. 엄마는 괜찮다고 하시는데 미안해.': null,
    '칭찬받았지만 부담스럽다고 했대.': null,
    '상사가 내 말을 무시했다고 하더라고. 화났대.': null,
    '면접 떨어졌어. 엄마는 괜찮다고 하는데 미안한 건 아니야.': null,
  };
  test('50 direct, ambiguous and negated accounts', () {
    expect(cases.length, 50);
    for (final entry in cases.entries) {
      expect(
        ReplySituation.detect(entry.key)?.id,
        entry.value,
        reason: entry.key,
      );
    }
  });
  test('reply modes honor listening, reflection and one suggestion', () {
    for (final entry in cases.entries.where((e) => e.value != null)) {
      for (final style in ReplyStyle.values) {
        final result = PersonalReplyEngine(
          random: Random(1),
        ).compose(letterText: entry.key, style: style, catName: '몽이');
        final situation = ReplySituation.detect(entry.key)!;
        expect(result.parts.any(situation.listening.contains), isTrue);
        expect(
          result.parts.any(situation.suggestions.contains),
          style == ReplyStyle.suggest,
        );
        expect(
          result.parts.any(situation.reflections.contains),
          style == ReplyStyle.reflect,
        );
        if (style != ReplyStyle.suggest)
          expect(result.text.contains('?'), isFalse);
      }
    }
    final result = PersonalReplyEngine(random: Random(1)).compose(
      letterText: '상사가 칭찬했는데 부담스러워. 그냥 들어줘.',
      style: ReplyStyle.suggest,
      catName: '몽이',
    );
    expect(result.parts.length, 3);
  });
}
