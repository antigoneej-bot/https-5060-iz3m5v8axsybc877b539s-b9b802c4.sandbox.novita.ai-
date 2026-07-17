/// 고양이 기억 시스템의 기록 한 건 (설계서 6장 참고).
///
/// 편지에 12개 카테고리 키워드 중 하나가 감지되면 생성되며, 캡처 시점
/// 기준 3/7/14/30일 후 회상 예정일을 미리 계산해둡니다.
/// [BuriedEmotionEntry]와 동일한 시간지연 구조를 그대로 재사용한 모델입니다.
class MemoryEntry {
  final String id;
  final String catId;

  /// 감지된 카테고리 (예: '면접', '감기' 등 - memory_keyword_dictionary.dart 참고)
  final String keyword;

  /// 원문 일부(짧게 발췌)
  final String originalSnippet;

  final DateTime capturedAt;

  /// capturedAt + 3/7/14/30일 (오름차순 고정)
  final List<DateTime> recallDueDates;

  /// 이미 회상 처리된(사용된) 예정일들. ISO8601 문자열로 저장/비교합니다.
  final Set<String> alreadyRecalledAt;

  const MemoryEntry({
    required this.id,
    required this.catId,
    required this.keyword,
    required this.originalSnippet,
    required this.capturedAt,
    required this.recallDueDates,
    this.alreadyRecalledAt = const {},
  });

  /// 캡처 시점 기준 3/7/14/30일 후 회상 예정일 리스트를 계산합니다.
  static List<DateTime> computeDueDates(DateTime capturedAt) {
    return const [3, 7, 14, 30]
        .map((days) => capturedAt.add(Duration(days: days)))
        .toList();
  }

  /// [now] 기준으로 "오늘 회상해도 되는" 예정일이 있으면 그 날짜를 반환합니다.
  /// (이미 회상한 예정일은 제외, 가장 오래된 것 우선)
  DateTime? dueDateFor(DateTime now) {
    final ref = DateTime(now.year, now.month, now.day);
    final candidates = recallDueDates.where((d) {
      final day = DateTime(d.year, d.month, d.day);
      if (day.isAfter(ref)) return false;
      return !alreadyRecalledAt.contains(d.toIso8601String());
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  /// 회상 시점(3/7/14/30일 중 몇 일째)을 인덱스로 반환합니다. (0=3일,1=7일,2=14일,3=30일)
  int recallStageIndex(DateTime dueDate) {
    return recallDueDates.indexWhere((d) => d == dueDate);
  }

  MemoryEntry withRecalled(DateTime dueDate) {
    return MemoryEntry(
      id: id,
      catId: catId,
      keyword: keyword,
      originalSnippet: originalSnippet,
      capturedAt: capturedAt,
      recallDueDates: recallDueDates,
      alreadyRecalledAt: {
        ...alreadyRecalledAt,
        dueDate.toIso8601String(),
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'keyword': keyword,
      'originalSnippet': originalSnippet,
      'capturedAt': capturedAt.toIso8601String(),
      'recallDueDates': recallDueDates.map((d) => d.toIso8601String()).toList(),
      'alreadyRecalledAt': alreadyRecalledAt.toList(),
    };
  }

  factory MemoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return MemoryEntry(
      id: map['id'] as String,
      catId: map['catId'] as String? ?? '',
      keyword: map['keyword'] as String? ?? '',
      originalSnippet: map['originalSnippet'] as String? ?? '',
      capturedAt:
          DateTime.tryParse(map['capturedAt'] as String? ?? '') ??
          DateTime.now(),
      recallDueDates:
          (map['recallDueDates'] as List?)
              ?.map((e) => DateTime.tryParse(e as String))
              .whereType<DateTime>()
              .toList() ??
          const [],
      alreadyRecalledAt:
          (map['alreadyRecalledAt'] as List?)?.map((e) => e as String).toSet() ??
          const {},
    );
  }
}
