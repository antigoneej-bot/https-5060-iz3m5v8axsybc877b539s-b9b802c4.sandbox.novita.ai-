import 'reply_safety.dart';

/// Routes explicit, first-person emotion wording to one of the 24 categories
/// in `mind_cat_acceptance_replies_72` (see tool/acceptance_reply_content.json
/// and 02_적용_원칙.txt / 03_개발자_적용_요청.txt for the source pack and its
/// application principles).
///
/// This is deliberately conservative and lexical, not semantic understanding:
/// - A single emotion word is never enough on its own; negation, quoted/
///   reported speech, hypotheticals, tense shifts ("예전에는 ~ 지금은") and
///   another person's stated feeling are excluded the same way [ReplyTone]
///   and [ReplySituation] already exclude them.
/// - use_when text in the source pack is guidance for a human reader, not a
///   keyword list; this matcher only fires on the same kind of explicit,
///   first-person wording the pack's own example_input lines use.
/// - When more than one broad feeling-family is present, this matcher only
///   picks a category for the one explicitly-authored combination (joy +
///   worry, category 21) or explicit "mixed" wording (category 22). Any
///   other combination returns null so the caller falls back to the
///   existing general engine, instead of silently discarding one feeling.
/// - Ambiguous or unmatched input returns null.
class AcceptanceReplyMatcher {
  const AcceptanceReplyMatcher._();

  // Match the emotion word, not the same syllables inside 영화나/동화나라.
  // Common intensifiers may be attached without a space in diary writing.
  static const angerPattern =
      r'(?:^|[^가-힣A-Za-z0-9])(?:너무|정말|진짜|엄청|완전|아주|몹시|많이|좀|더|또)?\s*(?:화가\s*나|화가\s*났|화났|화나)|짜증';

  static bool _negatedOrHedged(String after) {
    if (RegExp(r'^[^.!?\n,]{0,8}(?:않|아니|없)').hasMatch(after)) return true;
    if (RegExp(r'^지\s*못').hasMatch(after)) return true;
    if (RegExp(r'^(?:은|는|이|가|도)?\s*없').hasMatch(after)) return true;
    return false;
  }

  static bool _affirmed(String text, String pattern) {
    for (final match in RegExp(pattern).allMatches(text)) {
      final before = text.substring(0, match.start);
      final after = text.substring(match.end);
      if (RegExp(r'(?:^|\s)안\s*$').hasMatch(before)) continue;
      if (_negatedOrHedged(after)) continue;
      return true;
    }
    return false;
  }

  // Keep someone else's stated emotion separate even if the letter also
  // contains "나는" in another sentence. Causal wording such as "친구가
  // 약속을 취소해서 서운해" still describes the writer's reaction.
  static bool _statedAsOtherIntransitive(String text) {
    const subjects =
        r'(?:친구|동료|상사|엄마|아빠|어머니|아버지|동생|언니|오빠|남편|아내|아들|딸|아이|자녀|부모님|선생님|그녀|그\s*사람)(?:가|이|는|은)';
    const states =
        r'슬퍼|슬프|기뻐|기쁘|외로워|외롭|피곤|지쳤|행복|그리워|그리운|그립|'
        r'불안|걱정|두려|무서|서운|화가\s*나|화가\s*났|화났|화나|짜증|후회|미안|창피|민망|부럽|질투|자책|실망';
    // A fixed list of relatives cannot cover names or new roles (민수가,
    // 상담사가). Subject particles provide a conservative second guard.
    // State/event nouns and first-person subjects can describe my reaction,
    // so they must not be treated as another person merely for having 이/가.
    const nonPersonSubjects = {
      '나',
      '내',
      '저',
      '제',
      '우리',
      '마음',
      '기분',
      '감정',
      '몸',
      '오늘',
      '어제',
      '내일',
      '요즘',
      '지금',
      '하루',
      '일',
      '행동',
      '말',
      '태도',
      '결과',
      '소식',
      '기억',
      '생각',
      '이야기',
      '상황',
      '약속',
      '사건',
      '문제',
      '모습',
      '표정',
      '느낌',
      '월세',
      '생활비',
      '돈',
      '대출',
      '시험',
      '면접',
      '미래',
      '앞날',
      '앞으로',
      '한편으로',
      '한편',
      '자신',
      '스스로',
    };
    final namedSubject = RegExp(
      r'(?:^|\s)([가-힣A-Za-z][가-힣A-Za-z0-9]*)(?:가|이|는|은)(?=\s)',
    );
    for (final sentence in text.split(RegExp(r'[.!?\n]'))) {
      final candidates = <RegExpMatch>[
        ...RegExp(subjects).allMatches(sentence),
        ...namedSubject
            .allMatches(sentence)
            .where((m) => !nonPersonSubjects.contains(m.group(1))),
      ];
      for (final subject in candidates) {
        final tail = sentence.substring(subject.end);
        final feeling = RegExp(states).firstMatch(tail);
        if (feeling == null) continue;
        final between = tail.substring(0, feeling.start);
        // A clearly stated new first-person subject owns the following feeling.
        if (RegExp(r'(?:나는|내가|난\s|저는|제가)').hasMatch(between)) continue;
        // Distinguish a person's own state from their action causing my feeling.
        if (RegExp(
          r'(?:(?:해|아|어|여|겨|려|워|와|라|이|줘|켜|져|가|나|서|보|돼|되)서|해서는|때문에|덕분에|로\s*인해)\s*$',
        ).hasMatch(between))
          continue;
        return true;
      }
    }
    return false;
  }

  // Only exact feeling equivalents are mapped. E.g. depressed is not sadness,
  // proud alone does not establish an achievement, and serene is not relief.
  // Missing IDs keep the neutral path instead of inventing a story to fit a cat.
  static const selectedEmotionCategories = <String, String>{
    'angry': '01',
    'sulky': '02',
    'hurtFeelings': '02',
    'sad': '03',
    'lonely': '04',
    'anxious': '05',
    'dread': '05',
    'jealous': '06',
    'guilty': '08',
    'selfCritical': '09',
    'ashamed': '10',
    'weary': '11',
    'joyful': '15',
    'grateful': '17',
  };

  static String? _selectedEmotionFallback(String value, String? emotionId) {
    final category = selectedEmotionCategories[emotionId];
    if (category == null || RegExp(angerPattern).hasMatch(value)) return null;
    // Named feelings (including negated, unsupported, or mixed ones) must not
    // be overridden by the cat choice. Unknown facts/questions stay neutral too.
    if (RegExp(
      r'슬프|슬퍼|슬픔|속상|서운|외로|짜증|기쁘|기뻐|기쁨|행복|'
      r'불안|걱정|두려|두렵|무서|피곤|지쳤|지쳐|힘들|의욕|부럽|부러|질투|미워|밉|'
      r'미안|후회|죄송|자책|내\s*탓|창피|민망|감사|고마|고맙|안심|안도|뿌듯|'
      r'사랑|그리|보고\s*싶|소중|복잡|우울|허무|공허|억울|초조|초라|위축|실망|'
      r'평온|편안|만족|설레|신나|신났|즐거|즐겁|부담|용서|돌아가셨|장례|'
      r'않|아니|(?:^|\s)안\s|없|[?？]|(?:걸까|일까|건가|나요|어쩌지)[.!\s]*$',
    ).hasMatch(value))
      return null;
    if (RegExp(
      r'(?:친구|동료|상사|엄마|아빠|어머니|아버지|동생|언니|오빠|남편|아내|그녀|그\s*사람)(?:가|이|는|은)',
    ).hasMatch(value))
      return null;
    return category;
  }

  static bool _globalAmbiguous(String text) {
    if (text.length > 500) return true;
    return RegExp(
      r'["“”「」『』]|소설|대사|가정|농담|비꼬|비웃|반어|라면|다면|였으면|었으면|았으면|했다고|했대|하대|고\s*하더라|라고|냐고',
    ).hasMatch(text);
  }

  /// Exposed to the engine as well: falling back from this matcher must not
  /// reintroduce a feeling that belongs to someone else through ReplyTone.
  static bool uncertainPerspective(String text) =>
      _globalAmbiguous(text) ||
      RegExp(r'예전에|옛날|지난해|작년|그때는|당시에는|지금은|이제는|더\s*이상').hasMatch(text) ||
      _statedAsOtherIntransitive(text);

  /// True when the writer has asked, in any of the ways the existing engine
  /// already recognises, to be listened to without advice, questions, or a
  /// reflection prompt. Category 23 always uses this pool, and every other
  /// matched category must skip its reflect_optional line when this is true.
  static bool wantsListeningOnly(String text) => RegExp(
    r'묻지\s*마|그냥\s*들어|'
    // "질문/조언/해결책 ~" followed by either the "말고/말아/말다" family or
    // the short imperative "마(요/세요)?" ending (previously only "말…" was
    // matched, so "질문하지 마." / "조언하지 마." without "고" fell through).
    r'(?:질문|조언|해결책)[^.!?\n]{0,10}(?:말고|말아|마(?:요|세요)?(?=[.!?\s]|$)|싫|필요\s*없)|'
    r'말하고\s*싶지\s*않|얘기하고\s*싶지\s*않|이야기하고\s*싶지\s*않|설명하고\s*싶지\s*않',
  ).hasMatch(text);

  /// Returns a category id like `'01'`..`'24'`, or null when the input is
  /// empty, ambiguous, reports someone else's feeling, matches none of the
  /// 24 authored situations, or names more feelings than the pack's own
  /// explicit combinations cover.
  static String? detect(String text, {String? emotionId}) {
    final value = text.trim();
    if (value.isEmpty || ReplySafety.assess(value) != ReplySupportNeed.none) {
      return null;
    }
    if (wantsListeningOnly(value)) return '23';
    if (_globalAmbiguous(value)) return null;
    // Same tense-shift/uncertain-perspective wording that makes ReplyTone
    // fall back to neutral keeps this matcher from guessing too; a plain
    // neutral reply is an accepted outcome for these inputs.
    if (RegExp(r'예전에|옛날|지난해|작년|그때는|당시에는|지금은|이제는|더\s*이상').hasMatch(value)) {
      return null;
    }
    if (_statedAsOtherIntransitive(value)) return null;

    // Explicit "여러 감정이 섞여 있다" wording always wins as category 22,
    // regardless of which individual cues also happen to be present, since
    // the writer has already named the mixed-ness themselves.
    if (RegExp(r'복잡하고|여러\s*감정.*섞|마음이\s*복잡|감정이\s*복잡').hasMatch(value)) {
      return '22';
    }

    final anger = _affirmed(value, angerPattern);
    final jealousy = _affirmed(value, r'질투|부럽|부러워');
    final hate = _affirmed(value, r'미워|밉다|미운');
    final sadness = _affirmed(value, r'슬퍼|슬프|슬펐|속상|눈물이\s*나|울었');
    final seoun = _affirmed(value, r'서운');
    final lonely = _affirmed(value, r'외로워|외롭|외로웠|외로운');
    final selfBlame = _affirmed(
      value,
      r'자신에게\s*실망|내가\s*싫|나\s*자신이\s*싫|스스로가?\s*싫|자책|나\s*자신을\s*탓|내\s*탓|'
      r'(?:나\s*자신(?:이|은)|내\s*(?:자신|모습|행동)|스스로(?:가|는)?|내가)[^.!?\n]{0,12}실망스러',
    );
    final apology = _affirmed(value, r'후회|미안');
    final shame = _affirmed(value, r'창피|민망');
    final tired = _affirmed(value, r'지쳤|지쳐|피곤|녹초|기진맥진');
    final unmotivated = _affirmed(
      value,
      r'의욕(?:이|도)?\s*(?:안|없)|하고\s*싶은\s*마음이?\s*(?:안|없)|아무것도\s*하기\s*싫',
    );
    final vague = RegExp(
      r'(?:기분|마음|감정).*모르겠|어떤\s*마음인지\s*모르겠|무슨\s*감정인지',
    ).hasMatch(value);
    final mundane = RegExp(
      r'별일\s*없|평범했|특별한\s*일\s*없|그저\s*그런\s*하루',
    ).hasMatch(value);
    final joy = _affirmed(value, r'기뻐|기쁘|기쁜|행복|신나|즐거');
    final achievementProud =
        RegExp(r'완성|끝내|해냈|합격|승진|이뤄|마쳤|끝냈').hasMatch(value) &&
        _affirmed(value, r'뿌듯');
    final safeReturnGratitude =
        RegExp(r'무사히').hasMatch(value) &&
        RegExp(r'함께한|이들|사람들|모두|다들').hasMatch(value) &&
        _affirmed(value, r'감사|고마(?:워|웠|운|움)');
    final gratitude = _affirmed(value, r'감사|고마(?:워|웠|운|움)');
    final relief = _affirmed(value, r'안심|안도|마음이\s*놓');
    final affection = _affirmed(value, r'사랑해|사랑합|사랑하|아끼는|소중한|보고\s*싶');
    final worry = _affirmed(value, r'불안|걱정|막막|두려|무서워');

    final families = <bool>[
      anger,
      jealousy,
      hate,
      sadness || seoun,
      lonely,
      selfBlame,
      apology,
      shame,
      tired,
      unmotivated,
      joy,
      achievementProud,
      gratitude,
      relief,
      affection,
      worry,
    ].where((present) => present).length;

    // The pack authors an explicit compound situation (joy + worry,
    // category 21). Any other combination of named feelings is ambiguous
    // for this 24-category pack; defer to the general engine's own
    // tone-based "mixed" handling instead of dropping one of the feelings.
    if (families > 1) {
      if (joy && worry && families == 2) return '21';
      // Category 11's authored example explicitly links lack of motivation
      // to exhaustion. Keep that causal statement in its authored category;
      // independent/mixed fatigue and motivation still remain ambiguous.
      if (tired &&
          unmotivated &&
          families == 2 &&
          RegExp(
            r'(?:지쳐서|피곤해서|지쳤기\s*때문에|피곤하기\s*때문에)[^.!?\n]*(?:하기\s*싫|의욕.*없)',
          ).hasMatch(value))
        return '11';
      return null;
    }

    if (anger) return '01';
    if (jealousy) return '06';
    if (hate) return '07';
    if (sadness) return '03';
    if (seoun) return '02';
    if (lonely) return '04';
    if (selfBlame) return '09';
    if (apology) return '08';
    if (shame) return '10';
    if (tired) return '11';
    if (unmotivated) return '12';
    if (worry) return '05';
    if (achievementProud) return '16';
    if (safeReturnGratitude) return '18';
    if (gratitude) return '17';
    if (relief) return '19';
    if (affection) return '20';
    if (joy) return '15';
    if (mundane) return '14';
    if (vague) return '13';
    // Explicit listening requests are handled before emotion matching.
    return _selectedEmotionFallback(value, emotionId);
  }
}
