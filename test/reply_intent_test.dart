import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/services/reply_intent.dart';

void main() {
  test('actual reported question gets a short clarification in every mode', () {
    const letter = '결국 문제였던 걸 해결 한건가?';
    expect(ReplyIntent.detect(letter)?.id, 'question_resolution');
    for (final style in ReplyStyle.values) {
      final reply = PersonalReplyEngine(random: Random(2)).compose(
        letterText: letter, style: style, catName: '지적인 고양이');
      expect(reply.text, contains('어떤'));
      expect(reply.text, isNot(contains('잠시 뒤로')));
      expect(reply.text, isNot(contains('네 편지에서')));
      expect(reply.text, isNot(contains(letter)));
      expect(reply.text, isNot(contains('고마워')));
      expect(reply.text.length, lessThan(180));
      expect(reply.text, endsWith('— 지적인 고양이'));
    }
  });
  test('named issue, self judgment, other mind and next step differ', () {
    const cases = {
      '앱 답장 오류가 해결된 건가?': 'question_resolution_named',
      '결국 해결 한건가': 'question_resolution',
      '내가 잘못한 걸까?': 'question_self_judgment',
      '그 사람이 나를 싫어하는 걸까?': 'question_other_mind',
      '어떻게 해야 할까?': 'question_next_step',
      '그럼 이게 맞는 건가?': 'question_context',
    };
    for (final entry in cases.entries) {
      expect(ReplyIntent.detect(entry.key)?.id, entry.value, reason: entry.key);
    }
    final named = ReplyIntent.detect('앱 답장 오류가 해결된 건가?')!;
    for (final response in named.responses) {
      expect(response, isNot(contains('어떤 문제였는지')));
      expect(response, isNot(contains('해결됐어')));
    }
  });
  test('quotes, listening requests, negations and statements are not questions', () {
    for (final text in [
      '친구가 "해결한 건가?"라고 물었어.',
      '그냥 들어줘. 결국 해결한 건가?',
      '조언은 하지 말아줘. 어떻게 해야 할까?',
      '질문하지 말아줘. 내가 잘못한 걸까?',
      '해결했어! 기뻐.',
      '해결한 건가? 아직은 모르겠어.',
      '나는 내가 잘못했다고 생각하지 않아.',
      '나는 오늘 외로워.',
      '나는 합격해서 기쁘지만 앞으로가 불안해.',
      '',
    ]) {
      expect(ReplyIntent.detect(text), isNull, reason: text);
    }
  });
  test('authored alternatives avoid exact repeats while alternatives remain', () {
    final texts = <String>[];
    final parts = <List<String>>[];
    for (var i = 0; i < 3; i++) {
      final reply = PersonalReplyEngine(random: Random(i)).compose(
        letterText: '결국 문제였던 걸 해결 한건가?',
        style: ReplyStyle.listen, catName: '지적인 고양이',
        recentTexts: texts, recentParts: parts);
      expect(texts, isNot(contains(reply.text)));
      texts.add(reply.text);
      parts.add(reply.parts);
    }
  });
}
