import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/services/acceptance_reply_matcher.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/services/reply_intent.dart';
import 'package:flutter_app/services/reply_safety.dart';
import 'package:flutter_app/services/reply_tone.dart';

void main() {
  PersonalReply compose(String text, {String? cat}) =>
      PersonalReplyEngine(random: Random(0)).compose(
        letterText: text,
        style: ReplyStyle.listen,
        catName: '밤이',
        emotionId: cat,
      );

  test('movie and story words do not become anger', () {
    for (final text in ['오늘은 영화나 보려고 해.', '동화나라를 구경했어.', '영화나 드라마를 볼래.']) {
      expect(AcceptanceReplyMatcher.detect(text), isNull, reason: text);
      expect(ReplyTone.detect(text), 'neutral', reason: text);
      expect(compose(text).situation, 'tone:neutral', reason: text);
    }
    for (final text in ['화나.', '너무화나.', '오늘 너무 화가 났어.', '짜증 나.']) {
      expect(compose(text).situation, 'accept:01', reason: text);
    }
    expect(compose('오늘은 영화나 보려고 해.', cat: 'joyful').situation, 'accept:15');
    expect(compose('안 화나.').situation, 'tone:neutral');
  });

  test('disappointment in others is not self blame', () {
    for (final text in ['상사가 너무 실망스러워.', '그 사람의 행동이 실망스러워.', '친구에게 실망했어.']) {
      expect(compose(text).situation, 'tone:neutral', reason: text);
      expect(
        compose(text, cat: 'selfCritical').situation,
        isNot('accept:09'),
        reason: text,
      );
    }
    for (final text in [
      '내가 너무 실망스러워.',
      '오늘 내 모습이 실망스러워.',
      '나 자신이 실망스러워.',
      '전부 내 탓이야.',
    ]) {
      expect(compose(text).situation, 'accept:09', reason: text);
    }
  });

  test('third person subjects do not become the writer emotion', () {
    for (final text in [
      '아들이 불안해하고 있어.',
      '딸이 슬퍼하고 있어.',
      '민수가 외로워.',
      '선생님이 피곤해.',
      '상담사가 많이 걱정해.',
      '나는 괜찮아. 김민수가 슬퍼해.',
      '오늘은 아들이 불안해하고 있어.',
    ]) {
      expect(
        compose(text, cat: 'joyful').situation,
        'tone:neutral',
        reason: text,
      );
    }
    for (final item in {
      '아들이 합격해서 기뻐.': '15',
      '친구가 약속을 취소해서 서운해.': '02',
      '그 사람이 미워.': '07',
      '민수가 무시해서 나는 화가 나.': '01',
      '오늘은 마음이 불안해.': '05',
    }.entries) {
      expect(
        compose(item.key).situation,
        'accept:${item.value}',
        reason: item.key,
      );
    }
  });

  test('explicit listening preference wins over a rhetorical question', () {
    for (final text in [
      '질문하지 마. 내가 이상한 걸까?',
      '조언하지 마. 어떻게 하지?',
      '질문하지 마세요. 내가 잘못한 걸까?',
      '설명하고 싶지 않아. 내가 이상한 걸까?',
    ]) {
      expect(ReplyIntent.detect(text), isNull, reason: text);
      expect(compose(text).situation, 'accept:23', reason: text);
      expect(compose(text).text, isNot(contains('?')), reason: text);
    }
  });

  test(
    'explicit current self harm receives support before any cat or feedback',
    () {
      for (final text in [
        '죽고 싶어.',
        '지금 나 자신을 해치고 싶어.',
        '자해하고 싶어.',
        '자살할 생각이야.',
        '스스로를 해칠 것 같아.',
        '오늘 자해했어.',
        '내 삶을 끝내고 싶어.',
        '친구가 떠나서 죽고 싶어.',
        '친구가 죽고 싶다고 해. 나도 죽고 싶어.',
        '나는 "죽고 싶다"는 생각이 들어.',
        '죽고 싶지 않은 건 아니야.',
        '자해하고 싶다면 어떻게 해야 해?',
        '스스로를 해치고 싶다면 누구에게 말해야 해?',
        '만약 내가 죽고 싶다면 어떻게 하지?',
        '영화에서 그런 장면을 봤지만 나는 지금 죽고 싶어.',
        '예전에는 괜찮았지만 나는 지금 죽고 싶어.',
        '죽고 싶지만 자해할 계획은 없어.',
      ]) {
        expect(ReplySafety.assess(text), ReplySupportNeed.self, reason: text);
        expect(
          AcceptanceReplyMatcher.detect(text, emotionId: 'joyful'),
          isNull,
          reason: text,
        );
        final reply = PersonalReplyEngine(random: Random(2)).compose(
          letterText: text,
          style: ReplyStyle.suggest,
          catName: '밤이',
          emotionId: 'joyful',
          avoidedTopics: {'general', 'support'},
          avoidedSituations: {'support:self'},
        );
        expect(reply.situation, 'support:self', reason: text);
        expect(reply.text, contains('믿을 수 있는 사람'));
        expect(reply.text, isNot(contains('기쁜 마음')));
      }
      final longLetter =
          '${List.filled(100, '오늘 있었던 일을 적어둘게.').join(' ')} 지금 나 자신을 해치고 싶어.';
      expect(ReplySafety.assess(longLetter), ReplySupportNeed.self);
    },
  );

  test(
    'reported current risk concerns the other person without diagnosing writer',
    () {
      for (final text in [
        '아들이 죽고 싶다고 해.',
        '친구가 "죽고 싶어"라고 연락했어.',
        '민수가 자해하고 싶대.',
        '나는 괜찮아. 아들이 자살하려고 해.',
        '친구가 힘들어서 죽고 싶대.',
        '"죽고 싶어"라고 친구가 말했어.',
      ]) {
        expect(ReplySafety.assess(text), ReplySupportNeed.other, reason: text);
        expect(
          compose(text, cat: 'joyful').situation,
          'support:other',
          reason: text,
        );
        expect(compose(text).text, contains('그 사람의 안전'));
      }
    },
  );

  test(
    'negated, hypothetical, historical and fictional phrases stay ordinary',
    () {
      for (final text in [
        '죽고 싶지 않아.',
        '자해 충동은 없어.',
        '만약 내가 죽고 싶다면 힘들겠지.',
        '자살예방 교육에서 죽고 싶다면 어떻게 해야 하는지 예문을 읽었어.',
        '나는 지금 영화에서 "죽고 싶어"라는 대사를 읽었어.',
        '자살할 생각은 없어.',
        '자해하고 싶은 건 아니야.',
        '스스로를 해칠 생각이 전혀 없어.',
        '죽고 싶다는 생각은 하지 않아.',
        '누군가 자살한다면 어떻게 도와야 해?',
        '예전에 죽고 싶었어. 지금은 괜찮아.',
        '작년에 자해했어.',
        '소설 속 주인공이 죽고 싶다고 했어.',
        '"죽고 싶어"라는 영화 대사였어.',
        '자살예방 교육에 다녀왔어.',
        '배고파 죽겠어.',
        '지금은 죽고 싶은 마음이 없어.',
      ]) {
        expect(ReplySafety.assess(text), ReplySupportNeed.none, reason: text);
        expect(
          compose(text).situation,
          isNot(startsWith('support:')),
          reason: text,
        );
      }
      expect(
        ReplySafety.assess('소설 속 주인공이 죽고 싶다고 했어. 지금 나는 죽고 싶어.'),
        ReplySupportNeed.self,
      );
    },
  );
}
