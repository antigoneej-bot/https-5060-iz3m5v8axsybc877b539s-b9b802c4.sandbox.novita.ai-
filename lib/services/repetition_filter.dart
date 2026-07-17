import 'dart:math';
import '../models/tagged_sentence.dart';
import 'usage_history_service.dart';

/// 반복 방지 시스템(설계서 9.2)의 필터링 규칙 4가지를 적용합니다.
class RepetitionFilter {
  /// 최근 30일 재사용 금지 + 연속 시작/마무리 금지를 적용한 후보 목록을
  /// 반환합니다. 필터링 후 후보가 0개가 되면(9.3 Fallback), 필터를 적용하지
  /// 않은 원본 [candidates]를 그대로 반환합니다 - 편지 생성은 절대 막히지
  /// 않아야 합니다.
  static List<TaggedSentence> exclude(
    List<TaggedSentence> candidates,
    String catId,
    String moduleKey, {
    DateTime? now,
  }) {
    final recentIds = UsageHistoryService.recentlyUsedSentenceIds(
      catId,
      moduleKey,
      now: now,
    );
    final lastUsedId = UsageHistoryService.lastUsedSentenceId(
      catId,
      moduleKey,
    );

    var filtered = candidates
        .where((s) => !recentIds.contains(s.id))
        .where((s) => s.id != lastUsedId)
        .toList();

    if (filtered.isEmpty) {
      // 30일 재사용 금지만 완화(연속 반복 금지는 유지) - 후보 풀이 아주
      // 작은 초기 데이터 상태에서도 편지가 막히지 않도록 단계적으로 완화.
      filtered = candidates.where((s) => s.id != lastUsedId).toList();
    }
    if (filtered.isEmpty) {
      // 모든 완화에도 후보가 없다면(문장이 1개뿐인 극단적 경우) 원본 그대로.
      filtered = candidates;
    }
    return filtered;
  }

  /// 태그 조합 반복 완화(9.2 규칙 4) - 직전 편지와 태그 조합이 완전히
  /// 동일한 후보들을 완전히 배제하지 않고, 무작위 선택 시 가중치를
  /// 낮추기 위해 뒤로 정렬합니다. 실제 가중치 하향 적용은
  /// [WeightRanker]에서 이 결과를 이어받아 처리합니다.
  static List<TaggedSentence> deprioritizeSameCombo(
    List<TaggedSentence> candidates,
    Set<String> lastComboSignatures,
  ) {
    if (lastComboSignatures.isEmpty) return candidates;
    final fresh = <TaggedSentence>[];
    final repeated = <TaggedSentence>[];
    for (final s in candidates) {
      if (lastComboSignatures.contains(_comboSignature(s))) {
        repeated.add(s);
      } else {
        fresh.add(s);
      }
    }
    // fresh(새 조합)를 우선하되, fresh가 비어 있으면 repeated라도 사용.
    return fresh.isNotEmpty ? fresh : repeated;
  }

  static String _comboSignature(TaggedSentence s) {
    final t = s.tags;
    return [
      t.emotions.map((e) => e.name).join(','),
      t.growth.map((e) => e.name).join(','),
      t.intimacy.map((e) => e.name).join(','),
    ].join('|');
  }
}

/// 태그 일치 개수 기반 가중치 정렬 + 상위 그룹 내 무작위 선택(설계서 4.2 3~4단계).
class WeightRanker {
  /// 후보들을 태그 일치 개수(overlapScore) 기준 내림차순으로 정렬합니다.
  static List<TaggedSentence> sortByTagOverlap(
    List<TaggedSentence> candidates,
    int Function(TaggedSentence) scoreFn,
  ) {
    final sorted = [...candidates];
    sorted.sort((a, b) => scoreFn(b).compareTo(scoreFn(a)));
    return sorted;
  }

  /// 가장 높은 점수를 가진 "상위 그룹"(동점 포함) 안에서만 무작위로 하나
  /// 선택합니다. 이렇게 하면 태그가 잘 맞는 문장 위주로 뽑히면서도, 매번
  /// 완전히 결정적이지 않고 적당히 예측 불가능해집니다.
  static TaggedSentence pickFromTopGroup(
    List<TaggedSentence> sortedCandidates,
    int Function(TaggedSentence) scoreFn, {
    Random? random,
  }) {
    if (sortedCandidates.isEmpty) {
      throw StateError('WeightRanker: 선택할 후보가 없습니다.');
    }
    final rng = random ?? Random();
    final topScore = scoreFn(sortedCandidates.first);
    final topGroup = sortedCandidates
        .where((s) => scoreFn(s) == topScore)
        .toList();
    return topGroup[rng.nextInt(topGroup.length)];
  }
}
