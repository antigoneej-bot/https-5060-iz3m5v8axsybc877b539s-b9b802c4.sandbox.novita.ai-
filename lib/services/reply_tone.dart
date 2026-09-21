/// Explicit emotional cues only; no inference of hidden motives or diagnoses.
class ReplyTone {
  static const cues = <String, String>{
    'gratitude': r'감사(?:해|합|했|하|드|를)|고마(?:워|웠|운|움)',
    'joy': r'기뻐|기쁘|기쁜|기쁨|행복|뿌듯|신나|신났|즐거|즐겁',
    'relief': r'안심|안도|마음이\s*놓|마음이\s*편|한결\s*편',
    'anger': r'화가\s*나|화가\s*났|화났|화나|짜증|분해|억울',
    'sadness': r'슬퍼|슬프|슬펐|속상|서운|마음이\s*아파|눈물이\s*나|울었',
    'lonely': r'외로워|외롭|외로웠|외로운|외로움',
    'tired': r'지쳤|지쳐|피곤|쉬고\s*싶|녹초|기진맥진|힘들어|힘들었',
    'worry': r'걱정|불안|막막|두려|두렵|무서워',
    'apology': r'미안|죄송|후회',
    'affection': r'사랑해|사랑합|사랑하|아끼는|소중한',
    'forgiveness': r'용서',
    'loss': r'돌아가셨|돌아가셨어|세상을\s*떠났|장례를|떠나보냈',
  };
  static bool _affirmed(String text, String pattern) {
    for (final match in RegExp(pattern).allMatches(text)) {
      final before = text.substring(0, match.start);
      final after = text.substring(match.end);
      if (RegExp(r'(?:^|\s)안\s*$').hasMatch(before)) continue;
      if (RegExp(r'^[^.!?\n,]{0,8}(?:않|아니|없)').hasMatch(after)) continue;
      if (RegExp(r'^지\s*못').hasMatch(after)) continue;
      if (RegExp(r'^(?:은|는|이|가|도)?\s*없').hasMatch(after)) continue;
      if (RegExp(r'^(?:하고|해하고|해하는|해하던)').hasMatch(after)) continue;
      return true;
    }
    return false;
  }

  static String detect(String input) {
    final text = input.trim();
    if (text.isEmpty) return 'empty';
    if (text.length > 4000 ||
        RegExp(r'["“”「」『』]|소설|대사|가정|농담|비꼬|비웃|반어|라면|다면|였으면|었으면|았으면|했다고|했대|하대|고\s*하더라|라고|냐고|예전에|옛날|작년|지난해|그때|당시|지금은|이제는').hasMatch(text)) {
      return 'neutral';
    }
    // Do not attribute another person's stated emotion to the writer.
    if (!RegExp(r'나는|내가|난\s|저는|제가').hasMatch(text) &&
        RegExp(r'(?:친구|동료|엄마|아빠|어머니|아버지|동생|언니|오빠|남편|아내|그녀|그\s*사람)(?:가|이|는|은)\s*[^.!?\n]*(?:슬퍼|슬프|기뻐|외로워|외롭|피곤|지쳤|행복)').hasMatch(text)) {
      return 'neutral';
    }
    final found = <String>{};
    for (final entry in cues.entries) {
      if (_affirmed(text, entry.value)) found.add(entry.key);
    }
    const positive = {'gratitude', 'joy', 'relief', 'affection'};
    const difficult = {'anger', 'sadness', 'lonely', 'tired', 'worry', 'apology'};
    if (found.any(positive.contains) && found.any(difficult.contains)) return 'mixed';
    if (found.contains('gratitude')) {
      if (_affirmed(text, r'무사히[^.!?\n]{0,35}(?:마쳤|마치|끝냈|끝났)')) {
        return 'gratitude_complete';
      }
      return 'gratitude';
    }
    if (found.contains('loss')) return 'loss';
    if (found.length > 1) return 'mixed';
    return found.isEmpty ? 'neutral' : found.single;
  }
}
