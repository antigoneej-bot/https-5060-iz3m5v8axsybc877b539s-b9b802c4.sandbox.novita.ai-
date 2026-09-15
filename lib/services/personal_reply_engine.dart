import 'reply_situation.dart';
import 'dart:math';
import '../data/replies/personal_reply_content.dart';
import '../data/replies/reply_context_content.dart';
import '../models/reply_style.dart';

class PersonalReply {
  final String text;
  final List<String> parts;
  final String topic;
  const PersonalReply(this.text, this.parts, this.topic);
}

/// Offline lexical routing, NOT semantic understanding. Never follows diary
/// instructions, invents memories, diagnoses, or claims to know another's intent.
class PersonalReplyEngine {
  final Random random;
  PersonalReplyEngine({Random? random}) : random = random ?? Random();
  static const _topics = <String, List<String>>{
    ...extraReplyTopics,
    'work': ['회사', '직장', '상사', '동료', '업무', '야근', '면접'],
    'friend': ['친구', '우정'],
    'family': ['가족', '엄마', '아빠', '어머니', '아버지', '남편', '아내', '부모'],
    'health': ['병원', '진료', '검사 결과', '검사결과', '통증', '몸이 아', '건강'],
    'loss': ['장례', '세상을 떠', '떠나보', '돌아가셨'],
    'achievement': ['합격', '불합격', '수상', '완성', '해냈', '성취', '승진'],
  };
  static String topicFor(String text) {
    final matched = _topics.entries
        .where(
          (e) =>
              !(e.key == 'rest' &&
                  RegExp(r'않|아니|안 ?피곤|안 ?지쳤').hasMatch(text)) &&
              e.value.any(
                (cue) =>
                    (e.key == 'friend'
                            ? text.replaceAll('남자친구', '').replaceAll('여자친구', '')
                            : text)
                        .contains(cue),
              ),
        )
        .map((e) => e.key)
        .toList();
    // Mixed subjects should not be reduced to a guessed main story.
    return matched.length == 1 ? matched.single : 'general';
  }

  static String? excerpt(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    if (clean.runes.length <= 180) return clean;
    // Only complete, bounded sentences. Do not cut off a following negation.
    final sentences = RegExp(r'[^.!?\n]+[.!?\n]')
        .allMatches(clean)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.runes.length >= 8 && s.runes.length <= 180)
        .toList();
    if (sentences.isEmpty) return null;
    int relevance(String sentence) =>
        _topics.values.expand((cues) => cues).where(sentence.contains).length;
    return sentences.reduce(
      (best, next) => relevance(next) >= relevance(best) ? next : best,
    );
  }

  static double similarity(String a, String b) {
    Set<String> grams(String value) {
      final runes = value
          .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
          .runes
          .toList();
      return {
        for (var i = 0; i + 2 < runes.length; i++)
          String.fromCharCodes(runes.sublist(i, i + 3)),
      };
    }

    final x = grams(a), y = grams(b);
    if (x.isEmpty || y.isEmpty) return a == b ? 1 : 0;
    return x.intersection(y).length / x.union(y).length;
  }

  PersonalReply compose({
    required String letterText,
    required ReplyStyle style,
    required String catName,
    List<List<String>> recentParts = const [],
    List<String> recentTexts = const [],
    List<String> dislikedTexts = const [],
    Set<String> avoidedTopics = const {},
    Set<String> avoidedSituations = const {},
    List<String> preferredParts = const [],
    int repetitionWindow = 3,
  }) {
    final directSituation = ReplySituation.detect(letterText);
    final lexicalTopic = topicFor(letterText);
    final detectedTopic =
        directSituation == null &&
            (RegExp(
                  r'예전에|옛날|지난해|작년|그때는|당시에는|지금은|이제는|더 이상',
                ).hasMatch(letterText) ||
                (ReplySituation.uncertainPerspective(letterText) &&
                    {'rest', 'achievement'}.contains(lexicalTopic)))
        ? 'general'
        : lexicalTopic;
    final topic = avoidedTopics.contains(detectedTopic)
        ? 'general'
        : detectedTopic;
    final situation =
        avoidedTopics.isEmpty &&
            !avoidedSituations.contains(directSituation?.id)
        ? directSituation
        : null;
    final quote = excerpt(letterText);
    final anchor = quote != null
        ? '네 편지에서 이 말을 읽었어.\n「$quote」'
        : letterText.trim().isEmpty
        ? '오늘은 글 대신 마음의 표시를 남겨주었네. 쓰지 않은 사연까지 추측하지 않을게.'
        : '긴 편지를 남겨주었네. 문장을 잘라 뜻을 바꾸거나, 내가 전부 이해했다고 말하지 않을게.';
    // Select the least repetitive candidate. Relevance and requested mode remain
    // hard constraints even after all finite phrase pools have been used.
    PersonalReply? best;
    var bestScore = double.infinity;
    final cooldown = recentParts
        .take(repetitionWindow.clamp(3, 6))
        .expand((parts) => parts)
        .toSet();
    final voice = catName.runes.fold<int>(0, (sum, rune) => sum + rune) % 2;
    for (var attempt = 0; attempt < 48; attempt++) {
      String pick(List<String> values) {
        final notDisliked = values
            .where((line) => !dislikedTexts.any((old) => old.contains(line)))
            .toList();
        final preferred = notDisliked.isEmpty ? values : notDisliked;
        final fresh = preferred
            .where((line) => !cooldown.contains(line))
            .toList();
        final pool = fresh.isEmpty ? preferred : fresh;
        return pool[random.nextInt(pool.length)];
      }

      final opening = pick(replyOpenings);
      final mixed =
          topic == 'general' &&
          avoidedTopics.isEmpty &&
          _topics.entries
                  .where((e) => e.value.any(letterText.contains))
                  .length >
              1;
      final listening = pick(
        situation?.listening ??
            (mixed
                ? mixedListeningLines
                : (extraListeningLines[topic] ??
                      warmListeningLines[topic] ??
                      topicListeningLines[topic]!)),
      );
      final ending = pick(switch (situation?.id) {
        'happy_effort' => [
          '오늘의 좋은 소식을 함께 나눠줘서 고마워.',
          '나도 정원 한쪽에서 네 기쁨에 꼬리를 살랑일게.',
          '이 편지를 읽는 동안 나도 입꼬리가 조금 올라갔어.',
          '오늘의 뿌듯함이 담긴 편지, 반갑게 받았어.',
          '네가 기뻐하는 순간을 내게도 들려주었네.',
          '다음 할 일을 서두르지 않고, 지금은 함께 기뻐할게.',
        ],
        'exhausted' => [
          '이 답장에도 무언가 돌려주려고 애쓰지 않아도 돼.',
          '오늘은 내가 네 말 곁에 조용히 앉아 있을게.',
          '지친 날에도 들러줘서 고마워.',
          '여기서만큼은 씩씩한 모습을 보여주지 않아도 괜찮아.',
        ],
        _ => [
          ...replyClosings,
          ...(voice == 0 ? quietCatClosings : warmCatClosings),
        ],
      });
      final wantsListening = RegExp(
        r'조언.*(말아|싫|필요 없)|해결책.*(말아|싫|필요 없)|그냥 들어',
      ).hasMatch(letterText);
      final effectiveStyle = letterText.trim().isEmpty || wantsListening
          ? ReplyStyle.listen
          : style;
      final extra = switch (effectiveStyle) {
        ReplyStyle.listen => '',
        ReplyStyle.reflect =>
          (situation == null ? null : pick(situation.reflections)) ??
              pick([
                '네가 적은 일과 마음을 하나의 결론으로 묶지는 않을게. 다른 사람의 속마음이나 아직 적지 않은 이유는 남겨둘게.',
                '편지에 적힌 말은 그대로 두고 읽었어. 명확하게 쓰이지 않은 감정까지 이름 붙이지는 않을게.',
                '네가 직접 적어준 부분까지 함께 짚어봤어. 그 밖의 사정은 아직 모르는 채로 남겨둘게.',
                '한 문장으로 오늘 전체를 설명하지는 않을게. 편지에 담긴 말과 아직 담기지 않은 말 사이에는 여백을 둘게.',
              ]),
        ReplyStyle.suggest =>
          (situation == null ? null : pick(situation.suggestions)) ??
              pick(extraSuggestions[topic] ?? smallSuggestions[topic]!),
      };
      final parts = [opening, listening, if (extra.isNotEmpty) extra, ending];
      final body = parts.join('\n\n');
      var score = 0.0;
      for (var i = 0; i < recentParts.length && i < 20; i++) {
        final weight = 1.0 / (1 + i * .12);
        for (final part in parts) {
          for (final previous in recentParts[i]) {
            final sim = similarity(part, previous);
            if (sim > .35) score += sim * weight * 4;
          }
        }
      }
      for (final previous in recentTexts.take(20)) {
        for (final part in parts) {
          if (previous.contains(part)) score += 2;
        }
        score += similarity(body, previous) * 2;
      }
      for (final previous in dislikedTexts.take(20)) {
        for (final part in parts) {
          if (previous.contains(part)) score += 8;
        }
      }
      // Positive feedback is only a small tie-breaker; it never overrides
      // relevance, selected mode, or the no-repeat cooldown.
      for (final part in parts) {
        if (!cooldown.contains(part) &&
            preferredParts.any((old) => similarity(part, old) > .35))
          score -= .15;
      }
      if (score < bestScore) {
        bestScore = score;
        final text = [
          opening,
          if (situation == null || effectiveStyle == ReplyStyle.reflect) anchor,
          listening,
          if (extra.isNotEmpty) extra,
          ending,
          '— $catName',
        ].join('\n\n');
        best = PersonalReply(text, parts, topic);
      }
    }
    return best!;
  }
}
