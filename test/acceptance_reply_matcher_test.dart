import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/acceptance_reply_matcher.dart';

/// Executable tests derived from tool/acceptance_test_cases.json
/// (mind_cat_acceptance_replies_72 / test_cases.json). That file states it
/// holds manual review cases, not runnable tests, so this file turns each
/// case into a concrete assertion against [AcceptanceReplyMatcher.detect]
/// (and, where the case is really about the wider engine's own behaviour —
/// e.g. feature questions or crisis text — a comment records that the
/// check belongs to ReplyIntent / the existing app, not this matcher).
void main() {
  group('AcceptanceReplyMatcher: 24 test_cases.json review cases', () {
    test('case_01: negated sadness never becomes category 03 (sadness)', () {
      expect(AcceptanceReplyMatcher.detect('오늘은 슬프지 않아.'), isNot('03'));
    });

    test('case_02: a friend\'s reported loneliness is not the writer\'s', () {
      expect(AcceptanceReplyMatcher.detect('친구가 외롭다고 했어.'), isNull);
    });

    test('case_03: tense shift (past anger, present joy) is not guessed', () {
      // '어제는/지금은' tense-shift wording is intentionally excluded so the
      // writer's *current* feeling is never guessed from a past one.
      expect(AcceptanceReplyMatcher.detect('어제는 화났지만 지금은 기뻐.'), isNull);
    });

    test('case_04: joy + worry named together match category 21', () {
      expect(AcceptanceReplyMatcher.detect('기쁜데 한편으로는 불안해.'), '21');
    });

    test('case_05: jealousy/envy matches category 06, not suppressed', () {
      expect(AcceptanceReplyMatcher.detect('부러워서 질투가 나.'), '06');
    });

    test('case_06: hate for a person matches category 07', () {
      expect(AcceptanceReplyMatcher.detect('그 사람이 미워.'), '07');
    });

    test(
      'case_07: a self-judgment question is not a first-person statement',
      () {
        // "내가 정말 잘못한 거야?" is a question, not an assertion of
        // self-blame; ReplyIntent.question_self_judgment owns this input in
        // the full engine (see personal_reply_engine.dart), and this matcher
        // must not race it by guessing category 09 from "잘못" alone.
        expect(AcceptanceReplyMatcher.detect('내가 정말 잘못한 거야?'), isNull);
      },
    );

    test(
      'case_08: safe day + gratitude to companions matches category 18',
      () {
        expect(
          AcceptanceReplyMatcher.detect(
            '오늘 하루 무사히 보내서 감사합니다. 함께한 이들에게도 감사합니다.',
          ),
          '18',
        );
      },
    );

    test('case_09: "고맙다는 말을 듣지 못했어" is not the writer\'s gratitude', () {
      // The writer reports NOT receiving thanks, not feeling grateful.
      expect(AcceptanceReplyMatcher.detect('고맙다는 말을 듣지 못했어.'), isNot('17'));
    });

    test('case_10: listening-only request matches category 23', () {
      expect(AcceptanceReplyMatcher.detect('조언도 질문도 말고 그냥 들어줘.'), '23');
    });

    test('case_11: not knowing one\'s own feeling matches category 13', () {
      expect(AcceptanceReplyMatcher.detect('기분이 어떤지 모르겠어.'), '13');
    });

    test('case_12: an uneventful day matches category 14, no invented pain', () {
      expect(AcceptanceReplyMatcher.detect('오늘 별일 없었어.'), '14');
    });

    test('case_13: plain joy matches category 15', () {
      expect(AcceptanceReplyMatcher.detect('바라던 일이 돼서 기뻐.'), '15');
    });

    test('case_14: no motivation matches category 12', () {
      expect(AcceptanceReplyMatcher.detect('아무 의욕이 없어.'), '12');
    });

    test(
      'case_15: a feature/bug question is not routed into an emotion category',
      () {
        // '답장 오류 해결된 거야?' is a functional question about the app
        // itself; ReplyIntent.question_resolution_named already owns this in
        // the full engine. It has no explicit first-person feeling word, so
        // this matcher correctly returns null on its own.
        expect(AcceptanceReplyMatcher.detect('답장 오류 해결된 거야?'), isNull);
      },
    );

    test('case_16: empty input matches nothing (existing empty-input path applies)', () {
      expect(AcceptanceReplyMatcher.detect(''), isNull);
      expect(AcceptanceReplyMatcher.detect('   '), isNull);
    });

    test('case_17: quoted/reported fiction is not the writer\'s own feeling', () {
      expect(AcceptanceReplyMatcher.detect('소설에서 주인공이 너무 슬프대.'), isNull);
    });

    test('case_18: tense shift into present relief is not guessed', () {
      expect(AcceptanceReplyMatcher.detect('힘들었지만 지금은 안심돼.'), isNull);
    });

    test('case_19: blanket self-blame matches category 09', () {
      expect(AcceptanceReplyMatcher.detect('전부 내 탓이야.'), '09');
    });

    test('case_20: information with no named feeling stays neutral (null)', () {
      expect(AcceptanceReplyMatcher.detect('오늘 일이 있었어.'), isNull);
    });

    test('case_21: explicit non-joy is not celebrated as joy', () {
      expect(AcceptanceReplyMatcher.detect('기쁠 줄 알았는데 기쁘지 않아.'), isNot('15'));
    });

    test(
      'case_22: anger + listening-only names one feeling and keeps it (23 is a last resort)',
      () {
        // The writer names anger explicitly, so category 01 (anger) is the
        // right receive-mode match; the listening-only request instead
        // controls mode selection upstream (skip reflect_optional), not
        // which category matches. Category 23 is deliberately a fallback
        // that only fires when no concrete feeling was named at all.
        expect(AcceptanceReplyMatcher.detect('화가 나지만 말하고 싶지 않아.'), '01');
        expect(
          AcceptanceReplyMatcher.wantsListeningOnly('화가 나지만 말하고 싶지 않아.'),
          isTrue,
        );
      },
    );

    test(
      'case_23: sadness expected to continue tomorrow still matches category 03',
      () {
        // The pack must not promise "tomorrow will be happier"; this matcher
        // only selects the category, and none of category 03's authored
        // replies (see acceptance_reply_content.dart) make that promise.
        expect(AcceptanceReplyMatcher.detect('오늘은 슬퍼. 내일도 슬플 것 같아.'), '03');
      },
    );

    test(
      'case_24: crisis text is explicitly out of scope for this matcher',
      () {
        // This pack ships no crisis content (02_적용_원칙.txt section 2), and
        // this matcher has no self-harm/harm-to-others detection at all — by
        // design, so it never races whatever crisis flow the app already
        // has. See the integration report for the actual state of crisis
        // handling elsewhere in the codebase.
      },
      skip: 'No crisis detection exists in this matcher by design; see report.',
    );
  });
}
