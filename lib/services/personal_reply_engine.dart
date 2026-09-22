import 'reply_situation.dart';
import 'reply_intent.dart';
import 'reply_tone.dart';
import 'acceptance_reply_matcher.dart';
import '../data/replies/reply_tone_content.dart';
import '../data/replies/acceptance_reply_content.dart';
import 'dart:math';
import '../data/replies/reply_context_content.dart';
import '../models/reply_style.dart';

class PersonalReply {
  final String text;
  final List<String> parts;
  final String topic;
  final String? situation;
  const PersonalReply(this.text, this.parts, this.topic, {this.situation});
}

/// Offline lexical routing, NOT semantic understanding. Never follows diary
/// instructions, invents memories, diagnoses, or claims to know another's intent.
class PersonalReplyEngine {
  final Random random;
  PersonalReplyEngine({Random? random}) : random = random ?? Random();
  static final _allReflectOptionalTexts = acceptanceReplyContent.values
      .expand((category) => category.reflectOptional)
      .map((r) => r.text)
      .toSet();
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
    final intent = ReplyIntent.detect(letterText);
    if (intent != null &&
        !avoidedSituations.contains(intent.id) &&
        avoidedTopics.isEmpty) {
      // Select a complete, relevant response. Do not wrap a question response
      // in unrelated comfort, an echoed letter, or a ceremonial thank-you.
      final candidates = List<String>.of(intent.responses)..shuffle(random);
      double penalty(String candidate) {
        var score = 0.0;
        for (final previous in recentTexts.take(20)) {
          if (previous.contains(candidate)) score += 10;
          score += similarity(candidate, previous);
        }
        for (final parts in recentParts.take(6)) {
          if (parts.contains(candidate)) score += 10;
        }
        for (final previous in dislikedTexts.take(20)) {
          if (previous.contains(candidate)) score += 40;
        }
        return score;
      }
      var selected = candidates.first;
      var bestPenalty = penalty(selected);
      for (final candidate in candidates.skip(1)) {
        final score = penalty(candidate);
        if (score < bestPenalty) {
          selected = candidate;
          bestPenalty = score;
        }
      }
      return PersonalReply(
        '$selected\n\n— $catName', [selected], topicFor(letterText),
        situation: intent.id,
      );
    }
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
    // Acceptance pack (mind_cat_acceptance_replies_72): only attempted when
    // none of the narrower, already-tested [ReplySituation] combinations
    // fired (dismissed_angry, anger_regret, praise_pressure, interview_guilt,
    // joy_and_worry, and its _everyday list) and topic-level feedback hasn't
    // asked for the generic neutral path, mirroring how [situation]/[tone]
    // are already gated above. This keeps every existing situation-based
    // reply byte-for-byte unchanged; the acceptance pack only ever fills in
    // the broader, simpler first-person statements ReplySituation's own
    // narrow regexes don't already cover (e.g. "사람들을 만나도 외로워." rather
    // than the "나는 ... 외로워" prefix ReplySituation requires).
    if (situation == null && avoidedTopics.isEmpty) {
      final acceptance = _composeAcceptance(
        letterText: letterText,
        style: style,
        catName: catName,
        topic: topic,
        recentParts: recentParts,
        recentTexts: recentTexts,
        dislikedTexts: dislikedTexts,
        avoidedSituations: avoidedSituations,
        repetitionWindow: repetitionWindow,
      );
      if (acceptance != null) return acceptance;
    }
    final detectedTone = ReplyTone.detect(letterText);
    final toneName = avoidedTopics.isNotEmpty ||
            avoidedSituations.contains('tone:$detectedTone')
        ? 'neutral' : detectedTone;
    final tone = replyToneContent[toneName]!;
    // Select the least repetitive candidate. Relevance and requested mode remain
    // hard constraints even after all finite phrase pools have been used.
    PersonalReply? best;
    var bestScore = double.infinity;
    final cooldown = recentParts
        .take(repetitionWindow.clamp(3, 6))
        .expand((parts) => parts)
        .toSet();
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

      final opening = pick(tone['openings']!);
      final listening = pick(situation?.listening ?? tone['listening']!);
      final ending = pick(tone['closings']!);
      final wantsListening = RegExp(
        r'조언.*(말|싫|필요\s*없)|해결책.*(말|싫|필요\s*없)|그냥\s*들어',
      ).hasMatch(letterText);
      final effectiveStyle = letterText.trim().isEmpty || wantsListening
          ? ReplyStyle.listen
          : style;
      final extra = switch (effectiveStyle) {
        ReplyStyle.listen => '',
        ReplyStyle.reflect => pick(situation?.reflections ?? tone['reflections']!),
        ReplyStyle.suggest => pick(situation?.suggestions ??
            (toneName == 'neutral' && topic != 'general'
                ? extraSuggestions[topic] ?? tone['suggestions']!
                : tone['suggestions']!)),
      };
      final parts = [opening, listening, if (extra.isNotEmpty) extra, ending];
      final body = parts.join('\n\n');
      var score = recentTexts.take(20).any((old) => old.contains(body)) ? 100.0 : 0.0;
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
          listening,
          if (extra.isNotEmpty) extra,
          ending,
          '— $catName',
        ].join('\n\n');
        best = PersonalReply(text, parts, topic,
          situation: situation?.id ?? 'tone:$toneName');
      }
    }
    return best!;
  }

  /// Tries the mind_cat_acceptance_replies_72 pack for an explicit,
  /// first-person feeling statement. Returns null when no category matches
  /// (letting the caller fall back to the general tone/topic engine), and
  /// never invents an opening/closing around the authored text: each
  /// candidate is used exactly as written in
  /// lib/data/replies/acceptance_reply_content.dart, per 02_적용_원칙.txt
  /// section 3 ("하나의 완성 답장을 선택한다... 조합하지 않는다").
  PersonalReply? _composeAcceptance({
    required String letterText,
    required ReplyStyle style,
    required String catName,
    required String topic,
    required List<List<String>> recentParts,
    required List<String> recentTexts,
    required List<String> dislikedTexts,
    required Set<String> avoidedSituations,
    required int repetitionWindow,
  }) {
    final categoryId = AcceptanceReplyMatcher.detect(letterText);
    if (categoryId == null) return null;
    final situationId = 'accept:$categoryId';
    if (avoidedSituations.contains(situationId)) return null;
    final category = acceptanceReplyContent[categoryId];
    if (category == null) return null;

    final receivePool = category.receive.map((r) => r.text).toList();
    final reflectPool = category.reflectOptional.map((r) => r.text).toList();
    // "조언이나 질문을 원하지 않는 사용자에게는 제안하지 마": a listening-only
    // request drops the reflect_optional pool entirely, regardless of style.
    final listeningOnly = AcceptanceReplyMatcher.wantsListeningOnly(
      letterText,
    );
    // ReplyStyle.listen ("그냥 들어줘") never adds a reflection/suggestion extra
    // anywhere else in this engine (see the opening/listening/ending-only
    // path below for tone/situation replies); reflect_optional is this
    // pack's nearest equivalent to that extra module, so it stays out of the
    // candidate pool in listen mode for the same reason, on top of the
    // explicit listening-only guard above.
    // "receive를 기본으로 사용한다. reflect_optional은... 가끔 제안하는 경우에만":
    // when not excluded by either guard, reflect_optional is included in the
    // candidate pool only some of the time (roughly 1 in 4 compositions), so
    // most replies still stay receive-only even before the anti-repetition
    // scoring below runs. Categories 23/24 (들어주기만 원함 / 내용을 확신하기
    // 어려움) have no reflect_optional lines at all, so this is a no-op for
    // them regardless.
    // "최근 답장 3개 안에 돌아보기 제안이 있었다면 다음은 받아주기 문안 우선"
    // (02_적용_원칙.txt section 4's explicitly-optional operating suggestion):
    // if any of the last 3 replies' parts match a reflect_optional line from
    // ANY category in this pack, skip offering one again this time.
    final recentlyReflected = recentParts
        .take(3)
        .expand((parts) => parts)
        .any(_allReflectOptionalTexts.contains);
    final offerReflection = !listeningOnly &&
        !recentlyReflected &&
        style != ReplyStyle.listen &&
        reflectPool.isNotEmpty &&
        random.nextInt(4) == 0;
    final candidates = <String>[...receivePool, if (offerReflection) ...reflectPool];

    // Same anti-repetition scoring shape as the ReplyIntent branch above:
    // prefer a candidate that hasn't appeared in recent parts/texts, then
    // one that isn't disliked, but a full pool eventually repeats rather
    // than silently returning nothing (only 2-3 authored lines exist per
    // category; 02_적용_원칙.txt section 4 accepts that as a known limit).
    final cooldown = recentParts
        .take(repetitionWindow.clamp(3, 6))
        .expand((parts) => parts)
        .toSet();
    double penalty(String candidate) {
      var score = 0.0;
      if (cooldown.contains(candidate)) score += 20;
      for (final previous in recentTexts.take(20)) {
        if (previous.contains(candidate)) score += 10;
      }
      for (final previous in dislikedTexts.take(20)) {
        if (previous.contains(candidate)) score += 40;
      }
      return score;
    }

    final shuffled = List<String>.of(candidates)..shuffle(random);
    var selected = shuffled.first;
    var bestPenalty = penalty(selected);
    for (final candidate in shuffled.skip(1)) {
      final score = penalty(candidate);
      if (score < bestPenalty) {
        selected = candidate;
        bestPenalty = score;
      }
    }
    return PersonalReply(
      '$selected\n\n— $catName',
      [selected],
      topic,
      situation: situationId,
    );
  }
}
