import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/replies/acceptance_reply_content.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/services/acceptance_reply_matcher.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';

void main() {
  PersonalReply compose(
    String text, {
    String? emotionId,
    Set<String> avoidedTopics = const {},
    Set<String> avoidedSituations = const {},
  }) => PersonalReplyEngine(random: Random(7)).compose(
    letterText: text,
    emotionId: emotionId,
    style: ReplyStyle.listen,
    catName: '밤이',
    avoidedTopics: avoidedTopics,
    avoidedSituations: avoidedSituations,
  );

  test(
    'authored complete emotion replies take priority over legacy situations',
    () {
      const cases = {
        '나는 오늘 외로워.': '04',
        '나는 오늘 너무 지쳤어.': '11',
        '오늘은 지쳐서 아무것도 하기 싫어.': '11',
        '친구가 잘돼서 부럽고 질투도 나.': '06',
        '오늘 월세가 걱정돼.': '05',
        '나는 앞으로의 일이 불안해.': '05',
        '상사가 내 말을 무시해서 화났어.': '01',
        '나는 일을 완성해서 기뻐.': '15',
        '나는 일을 끝내서 뿌듯해.': '16',
        '나는 기쁘지만 불안해.': '21',
        '내가 상사에게 화를 냈어. 후회돼.': '08',
      };
      for (final item in cases.entries) {
        final reply = compose(item.key);
        expect(reply.situation, 'accept:${item.value}', reason: item.key);
        expect(reply.parts, hasLength(1));
        expect(
          acceptanceReplyContent[item.value]!.receive.map((r) => r.text),
          contains(reply.parts.single),
        );
        expect(reply.text, '${reply.parts.single}\n\n— 밤이');
      }
    },
  );

  test(
    'selected emotion is a fallback only for otherwise neutral diary text',
    () {
      const cases = {
        'sad': '03',
        'angry': '01',
        'lonely': '04',
        'anxious': '05',
        'jealous': '06',
        'guilty': '08',
        'selfCritical': '09',
        'weary': '11',
        'joyful': '15',
        'grateful': '17',
        'sulky': '02',
        'ashamed': '10',
      };
      for (final item in cases.entries) {
        expect(
          compose('오늘 있었던 일을 여기에 적어둘게.', emotionId: item.key).situation,
          'accept:${item.value}',
          reason: item.key,
        );
      }
      expect(compose('오늘은 정말 기뻐.', emotionId: 'sad').situation, 'accept:15');
      expect(
        compose('오늘 마음이 복잡해.', emotionId: 'joyful').situation,
        'accept:22',
      );
      expect(
        compose('기분이 어떤지 모르겠어.', emotionId: 'angry').situation,
        'accept:13',
      );
      expect(
        compose('상사가 칭찬했는데 부담스러워.', emotionId: 'joyful').situation,
        'praise_pressure',
      );
      expect(
        compose('오늘 있었던 일을 적어둘게.', emotionId: 'not-a-cat').situation,
        'tone:neutral',
      );
    },
  );

  test(
    'selection cannot undo negation, quotation, other speaker or tense guards',
    () {
      for (final text in [
        '오늘은 슬프지 않아.',
        '기쁘지 않아.',
        '나는 괜찮아. 엄마가 슬퍼해.',
        '나는 괜찮아. 친구가 불안해.',
        '친구가 외롭다고 했어.',
        '“나는 외로워.”라는 소설의 대사야.',
        '기쁘다면 좋겠어.',
        '어제는 슬펐지만 지금은 괜찮아.',
        '그저 우울해.',
        '오늘은 기쁘지 않고 슬프지도 않아.',
        '',
      ]) {
        expect(
          AcceptanceReplyMatcher.detect(text, emotionId: 'joyful'),
          isNull,
          reason: text,
        );
        expect(
          compose(text, emotionId: 'joyful').situation,
          isNot('accept:15'),
          reason: text,
        );
      }
      expect(compose('친구가 약속을 취소해서 서운해.').situation, 'accept:02');
      expect(compose('친구가 내 이야기를 넘겨서 서운했어.').situation, 'accept:02');
      expect(compose('그 사람이 미워.').situation, 'accept:07');
      expect(
        compose('나는 괜찮아. 엄마가 슬퍼해.', emotionId: 'joyful').situation,
        'tone:neutral',
      );
      expect(
        compose('나는 괜찮아. 친구가 불안해.', emotionId: 'joyful').situation,
        'tone:neutral',
      );
    },
  );

  test('explicit listening and real questions win over cat choice', () {
    expect(compose('그냥 들어줘.', emotionId: 'angry').situation, 'accept:23');
    expect(
      compose('답장 오류 해결된 거야?', emotionId: 'sad').situation,
      'question_resolution_named',
    );
  });

  test('negative topic feedback is scoped to this letter topic', () {
    expect(compose('고마워.', avoidedTopics: {'work'}).situation, 'accept:17');
    expect(
      compose('오늘 월세가 걱정돼.', avoidedTopics: {'work'}).situation,
      'accept:05',
    );
    expect(
      compose('상사가 내 말을 무시해서 화났어.', avoidedTopics: {'work'}).situation,
      'tone:neutral',
    );
    expect(
      compose('고마워.', avoidedSituations: {'accept:17'}).situation,
      'tone:neutral',
    );
    expect(
      compose('나는 오늘 외로워.', avoidedSituations: {'lonely'}).situation,
      'tone:neutral',
    );
    expect(
      compose(
        '고마워.',
        avoidedTopics: {'work'},
        avoidedSituations: {'accept:01'},
      ).situation,
      'accept:17',
    );
  });
}
