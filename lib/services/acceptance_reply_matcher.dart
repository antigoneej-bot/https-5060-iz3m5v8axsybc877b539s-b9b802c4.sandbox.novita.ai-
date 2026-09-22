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

  /// Mirrors [ReplyTone]'s own "don't attribute another person's stated
  /// emotion to the writer" guard, split into two cases:
  ///
  /// Guard A (unchanged from [ReplyTone]): bare state adjectives — 슬프다/
  /// 기쁘다/외롭다/피곤하다/행복하다 and 그립다 — where "그 사람이 X" almost always
  /// directly predicates X of that person, with no causal ambiguity.
  ///
  /// Guard B (new, and deliberately narrower): reaction verbs — 화나다/
  /// 후회하다/미안하다/서운하다/창피하다/밉다/부럽다/질투 — where "그 사람이 [행동]해서
  /// X" is at least as common as "그 사람이 X하대", and in that reading the
  /// OTHER person only caused the feeling; the writer is the one feeling it
  /// (e.g. "친구가 약속을 취소해서 서운해." is the writer's own 서운함). Guard B
  /// therefore only excludes when an explicit hearsay/report suffix
  /// (대/래/다고 해/하더라 등) immediately follows the emotion word, i.e. the
  /// text actually reports that person's own statement, not a plain reaction
  /// clause.
  static bool _statedAsOtherIntransitive(String text) {
    if (RegExp(r'나는|내가|난\s|저는|제가').hasMatch(text)) return false;
    const subjects =
        r'(?:친구|동료|엄마|아빠|어머니|아버지|동생|언니|오빠|남편|아내|그녀|그\s*사람)(?:가|이|는|은)';
    if (RegExp(
      '$subjects\\s*[^.!?\\n]*(?:슬퍼|슬프|기뻐|외로워|외롭|피곤|지쳤|행복|그리워|그리운|그립)',
    ).hasMatch(text)) {
      return true;
    }
    return RegExp(
      '$subjects\\s*[^.!?\\n]*(?:화가\\s*나|화가\\s*났|화났|화나|짜증|후회|미안|서운|창피|민망|'
      r'밉|미워|부럽|질투)(?:해했|해한대|하대|한대|했대|대\b|래\b|다고\s*(?:해|함|했어|하네)|'
      r'라고\s*(?:해|했어)|더라(?:고)?)',
    ).hasMatch(text);
  }

  static bool _globalAmbiguous(String text) {
    if (text.length > 500) return true;
    return RegExp(
      r'["“”「」『』]|소설|대사|가정|농담|비꼬|비웃|반어|라면|다면|였으면|었으면|았으면|했다고|했대|하대|고\s*하더라|라고|냐고',
    ).hasMatch(text);
  }

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
  static String? detect(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    if (wantsListeningOnly(value)) return '23';
    if (_globalAmbiguous(value)) return null;
    // Same tense-shift/uncertain-perspective wording that makes ReplyTone
    // fall back to neutral keeps this matcher from guessing too; a plain
    // neutral reply is an accepted outcome for these inputs.
    if (RegExp(
      r'예전에|옛날|지난해|작년|그때는|당시에는|지금은|이제는|더\s*이상',
    ).hasMatch(value)) {
      return null;
    }
    if (_statedAsOtherIntransitive(value)) return null;

    // Explicit "여러 감정이 섞여 있다" wording always wins as category 22,
    // regardless of which individual cues also happen to be present, since
    // the writer has already named the mixed-ness themselves.
    if (RegExp(r'복잡하고|여러\s*감정.*섞|마음이\s*복잡|감정이\s*복잡').hasMatch(value)) {
      return '22';
    }

    final anger = _affirmed(value, r'화가\s*나|화가\s*났|화났|화나|짜증');
    final jealousy = _affirmed(value, r'질투|부럽|부러워');
    final hate = _affirmed(value, r'미워|밉다|미운');
    final sadness = _affirmed(value, r'슬퍼|슬프|슬펐|속상|눈물이\s*나|울었');
    final seoun = _affirmed(value, r'서운');
    final lonely = _affirmed(value, r'외로워|외롭|외로웠|외로운');
    final selfBlame = _affirmed(
      value,
      r'자신에게\s*실망|내가\s*싫|나\s*자신이\s*싫|스스로가?\s*싫|자책|나\s*자신을\s*탓|내\s*탓|실망스러',
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

    // The pack authors only one explicit compound situation (joy + worry,
    // category 21). Any other combination of named feelings is ambiguous
    // for this 24-category pack; defer to the general engine's own
    // tone-based "mixed" handling instead of dropping one of the feelings.
    if (families > 1) {
      if (joy && worry && families == 2) return '21';
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
    return null;
  }
}
