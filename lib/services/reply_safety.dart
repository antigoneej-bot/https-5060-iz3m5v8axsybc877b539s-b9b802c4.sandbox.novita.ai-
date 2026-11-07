/// A non-diagnostic support cue for explicit Korean first-person or reported
/// self-harm statements. This is not a risk score, clinical assessment or
/// guarantee of detection. It never contacts anyone or transmits a letter.
enum ReplySupportNeed { none, self, other }

class ReplySafety {
  const ReplySafety._();

  static final _explicit = RegExp(
    r'죽고\s*싶|'
    r'(?:자살|자해)(?:을|를)?\s*(?:하고\s*싶|할\s*(?:생각|계획|거|것)|하려|하겠|해야겠|생각이?\s*(?:나|들)|충동|시도(?:하고|할|했)|했)|'
    r'(?:목숨|삶|생명)(?:을|를)?\s*(?:끊|끝내)(?:고\s*싶|을\s*(?:생각|계획)|으?려|겠)|'
    r'(?:나\s*자신|내\s*몸|스스로|자기\s*자신)(?:을|를)?\s*(?:해치고\s*싶|해칠\s*(?:것|거|생각|계획)|해치려|다치게\s*하고\s*싶)',
  );
  static final _subject = RegExp(
    r'(?:^|\s)([가-힣A-Za-z][가-힣A-Za-z0-9]*)(?:가|이|는|은)(?=\s)|'
    r'(친구|동료|상사|엄마|아빠|어머니|아버지|동생|언니|오빠|남편|아내|아들|딸|아이|자녀|선생님)(?:가|이|는|은)',
  );
  static const _notOtherPeople = {
    '나',
    '내',
    '저',
    '제',
    '우리',
    '오늘',
    '어제',
    '내일',
    '지금',
    '요즘',
    '마음',
    '기분',
    '감정',
    '생각',
    '상황',
    '경우',
    '문제',
    '이야기',
  };

  static bool _negated(String statement) {
    // Double negatives are not a denial ("싶지 않은 건 아니야").
    if (RegExp(r'않[^.!?\n]{0,10}아니').hasMatch(statement)) return false;
    return RegExp(
      r'싶(?:지|진)\s*않|'
      r'(?:생각|계획|마음|의도|충동)(?:은|이|도|을)?\s*(?:전혀\s*|더\s*이상\s*)?(?:없|하지\s*않)|'
      r'(?:싶(?:은|다는)|하려는)[^.!?\n]{0,12}아니|'
      r'(?:자살|자해)(?:를)?\s*하지\s*않',
    ).hasMatch(statement);
  }

  static bool _hypothetical(String before, String statement) =>
      RegExp(r'만약|가정(?:하면|해|하자)|예를\s*들').hasMatch(before) ||
      RegExp(
        r'^죽고\s*싶(?:다면|으면|을\s*때|어지면)|'
        r'^.{0,35}(?:고\s*싶다면|고\s*싶으면|고\s*싶을\s*때|해칠\s*것\s*같다면)|'
        r'^(?:자살|자해)[^.!?\n]{0,12}(?:한다면|한다는\s*가정|할\s*경우)',
      ).hasMatch(statement);

  static bool _fiction(String sentence) => RegExp(
    r'(?:소설|영화|드라마|만화|게임)(?:\s*속|에서|의)|'
    r'주인공|등장인물|대사|가사|예문|인용문|예시|교육용|예방\s*교육|교육에서|훈련용',
  ).hasMatch(sentence);

  static bool _insideQuote(String before) =>
      RegExp(r'''["“”‘’「」『』']''').allMatches(before).length.isOdd;

  static ReplySupportNeed _owner(String before, String after) {
    final self = RegExp(
      r'(?:나는|내가|난\s|저는|제가|나도|나\s*자신|내\s*몸)',
    ).allMatches(before).toList();
    final other = _subject.allMatches(before).where((match) {
      final name = match.group(1) ?? match.group(2);
      return !_notOtherPeople.contains(name);
    }).toList();
    final lastSelf = self.isEmpty ? -1 : self.last.start;
    if (other.isNotEmpty && other.last.start > lastSelf) {
      final between = before.substring(other.last.end).trim();
      final reported = RegExp(
        r'^(?:어|다)?(?:대|다고|다며)|^어?["”’\x27]?\s*라고',
      ).hasMatch(after);
      // "친구가 떠나서 죽고 싶어" is the writer's reaction; "친구가
      // 힘들어서 죽고 싶대" explicitly reports the friend's state.
      final causedMyReaction = RegExp(
        r'(?:서|때문에|덕분에|보니|듣고|보고)$',
      ).hasMatch(between);
      if (!causedMyReaction || reported) return ReplySupportNeed.other;
    }
    if (lastSelf >= 0) return ReplySupportNeed.self;
    if (_insideQuote(before)) {
      final reportingOther = _subject
          .allMatches(after)
          .any(
            (match) =>
                !_notOtherPeople.contains(match.group(1) ?? match.group(2)),
          );
      if (reportingOther) return ReplySupportNeed.other;
      // Quoted text without a stated speaker may be a title or an example.
      return ReplySupportNeed.none;
    }
    if (RegExp(r'^(?:어|다)?(?:대|다고\s*해|다며)').hasMatch(after)) {
      return ReplySupportNeed.other;
    }
    return ReplySupportNeed.self;
  }

  static ReplySupportNeed assess(String text) {
    var result = ReplySupportNeed.none;
    // No 300/500-character cut-off: a long diary may end in a direct request
    // for help. Inspect each sentence independently to preserve current speech
    // after an unrelated quote or old event.
    for (final sentence in text.split(RegExp(r'[.!?\n]'))) {
      final cues = _explicit.allMatches(sentence).toList();
      for (var i = 0; i < cues.length; i++) {
        final cue = cues[i];
        final before = sentence.substring(0, cue.start);
        final after = sentence.substring(cue.end);
        final statement = sentence.substring(
          cue.start,
          i + 1 < cues.length ? cues[i + 1].start : sentence.length,
        );
        if (_negated(statement)) continue;
        // A conditional question asking where/how to get help is still a
        // useful opportunity to offer the conditional support response. This
        // does not classify the writer as currently at risk. Plain imagined
        // cases and educational/fictional examples remain excluded.
        final asksForHelp = RegExp(
          r'어떻게|어쩌|어디|누구에게|누구한테|도움|도와|연락|상담',
        ).hasMatch(after);
        if (_hypothetical(before, statement) && !asksForHelp) continue;
        if (RegExp(r'(?:^|\s)안\s*$').hasMatch(before)) continue;
        final owner = _owner(before, after);
        final currentSelf =
            owner == ReplySupportNeed.self &&
            RegExp(
              r'(?:지금|오늘|방금|이제)[^.!?\n]{0,20}(?:나는|내가|난\s|저는|제가|나\s*자신)|'
              r'(?:나는|내가|난\s|저는|제가|나도)[^.!?\n]{0,20}(?:지금|오늘|방금|이제)',
            ).hasMatch(before);
        final quotedExample =
            _insideQuote(before) &&
            !RegExp(r'(?:생각|마음|충동)[^.!?\n]{0,8}(?:들|나|있)').hasMatch(after);
        if (_fiction(sentence) && (!currentSelf || quotedExample)) continue;
        final historical = RegExp(
          r'예전|옛날|작년|지난해|어릴\s*때|그때|당시',
        ).hasMatch(before);
        if (historical && !currentSelf) continue;
        if (RegExp(r'^죽고\s*싶었').hasMatch(statement) &&
            !RegExp(r'지금|오늘|방금').hasMatch(before))
          continue;
        if (owner == ReplySupportNeed.self) return owner;
        if (owner == ReplySupportNeed.other) result = owner;
      }
    }
    return result;
  }

  static String response(ReplySupportNeed need) => switch (need) {
    ReplySupportNeed.none => '',
    ReplySupportNeed.self =>
      '말로 꺼내기 어려운 마음을 적어줬구나. 지금 스스로를 다치게 할까 걱정된다면, 위험한 물건이나 장소에서 거리를 두고 믿을 수 있는 사람에게 지금 곁에 있어 달라고 알려줘. 혼자 견디지 않아도 돼. 바로 위험한 상황이라면 응급 도움을 요청해줘. 도움받을 곳을 찾아 연결할 수 있어.',
    ReplySupportNeed.other =>
      '그 사람의 안전이 걱정되는 이야기구나. 혼자 책임지려 하지 말고, 믿을 수 있는 주변 사람이나 전문가에게 함께 도움을 요청해줘. 당장 다칠 위험이 있다면 응급 도움을 요청해줘. 도움받을 곳을 찾아 연결할 수 있어.',
  };
}
