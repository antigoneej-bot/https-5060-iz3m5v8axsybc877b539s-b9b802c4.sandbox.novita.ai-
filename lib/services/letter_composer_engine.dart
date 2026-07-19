import 'dart:math';
import '../models/letter_context.dart';
import '../models/letter_tags.dart';
import '../models/tagged_sentence.dart';
import '../data/letter_sentence_pools.dart';
import 'tag_matcher.dart';
import 'repetition_filter.dart';
import 'usage_history_service.dart';
import 'cat_memory_service.dart';
import 'cat_mood_picker.dart';
import 'letter_emoji_decorator.dart';
import '../utils/feature_flags.dart';

/// 모듈형 편지 조합 엔진(설계서 4장).
///
/// 8개 모듈(인사/분위기/공감/기억(조건부)/위로/행동제안/고양이감정/마무리)을
/// CandidatePool → RepetitionFilter → 가중치정렬 → 최종선택의 4단계
/// 파이프라인으로 매번 새로 조합합니다.
///
/// 반복 방지 기록(Hive 쓰기)이 필요해 [compose]는 비동기입니다. 편지 생성은
/// 어떤 상황에서도 실패해서는 안 되므로(9.3 Fallback 안전장치), 문장 풀이
/// 비어 있는 극단적인 경우에도 이 메서드는 항상 문자열을 반환합니다.
class LetterComposerEngine {
  final Random random;

  LetterComposerEngine({Random? random}) : random = random ?? Random();

  Future<String> compose(LetterContext ctx) async {
    final now = ctx.now;
    final catMood = CatMoodPicker.pick(ctx, now, random: random);
    final active = ActiveTags.fromContext(ctx, now, catMoodOverride: catMood);

    final selections = <String, String>{};
    final lines = <String>[];

    void pickAndAdd(
      List<TaggedSentence> pool,
      String moduleKey, {
      String? emoji,
    }) {
      final sentence = _pick(pool, active, ctx.catId, moduleKey);
      if (sentence != null) {
        selections[moduleKey] = sentence.id;
        final text = (FeatureFlags.useLetterEmoji && emoji != null)
            ? LetterEmojiDecorator.append(sentence.text, emoji)
            : sentence.text;
        lines.add(text);
      }
    }

    pickAndAdd(
      greetingPool,
      LetterModuleKey.greeting,
      emoji: LetterEmojiDecorator.forGreeting(ctx.growthStage),
    );
    pickAndAdd(moodPool, LetterModuleKey.mood);
    pickAndAdd(empathyPool, LetterModuleKey.empathy);

    // ④ 기억 모듈 - 조건부(회상 예정일이 도달한 기억이 있을 때만 삽입)
    final dueMemory = CatMemoryService.findDueMemory(ctx.catId, now: now);
    if (dueMemory != null) {
      final memoryLine = await CatMemoryService.renderAndMarkRecalled(
        dueMemory,
        random: random,
      );
      lines.add(memoryLine);
    }

    // ⑤ 위로 - 보낸 편지의 그림자 고양이(catId)가 전용으로 갖고 있는
    // comfortMessage가 있으면 그것을 그대로 사용합니다. EmotionTag는 52종
    // 그림자 고양이를 11종으로 뭉뚱그리기 때문에("다친 고양이" → sad로
    // 매핑되어 "슬픔"류 범용 문장이 나가는 등) 보낸 편지와 답장의 감정이
    // 어긋나 보일 수 있었습니다. 전용 문구를 우선 사용해 이 매치 문제를
    // 근본적으로 해결합니다.
    if (ctx.catComfortMessage != null && ctx.catComfortMessage!.isNotEmpty) {
      selections[LetterModuleKey.comfort] = 'shadowcat_comfort_${ctx.catId}';
      lines.add(ctx.catComfortMessage!);
    } else {
      pickAndAdd(comfortPool, LetterModuleKey.comfort);
    }

    // ⑥ 행동제안 - 최근 5회 연속으로 명상 제안을 건너뛰었다면(설계서 8.2),
    // "제안형" 대신 "그냥 안부형"(actionGentlePool)으로 자동 전환합니다.
    final useGentleAction = ctx.recentMeditationSkipStreak >= 5;
    pickAndAdd(
      useGentleAction ? actionGentlePool : actionPool,
      LetterModuleKey.action,
    );

    pickAndAdd(
      catMoodPool,
      LetterModuleKey.catMood,
      emoji: LetterEmojiDecorator.forCatMood(catMood),
    );
    pickAndAdd(
      closingPool,
      LetterModuleKey.closing,
      emoji: LetterEmojiDecorator.forClosing(ctx.intimacyStage),
    );

    if (selections.isNotEmpty) {
      await UsageHistoryService.record(ctx.catId, selections, now: now);
    }

    return lines.join('\n\n');
  }

  TaggedSentence? _pick(
    List<TaggedSentence> pool,
    ActiveTags active,
    String catId,
    String moduleKey,
  ) {
    if (pool.isEmpty) return null;
    final matched = TagMatcher.filter(pool, active);
    final filtered = RepetitionFilter.exclude(matched, catId, moduleKey);
    if (filtered.isEmpty) return null;
    final sorted = WeightRanker.sortByTagOverlap(
      filtered,
      (s) => TagMatcher.overlapScore(s, active),
    );
    return WeightRanker.pickFromTopGroup(
      sorted,
      (s) => TagMatcher.overlapScore(s, active),
      random: random,
    );
  }
}
