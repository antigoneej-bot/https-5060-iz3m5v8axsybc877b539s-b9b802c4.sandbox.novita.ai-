/// 반복 방지 시스템의 사용 기록 한 건 (설계서 9장 참고).
///
/// 매 편지 생성 후 사용된 모듈별 문장 ID를 기록해, 최근 30일 내 재사용을
/// 막고 연속 시작/마무리 반복을 방지하는 데 사용됩니다.
class UsageHistoryEntry {
  final String catId;
  final String moduleKey; // LetterModuleKey 값
  final String sentenceId;
  final DateTime usedAt;

  const UsageHistoryEntry({
    required this.catId,
    required this.moduleKey,
    required this.sentenceId,
    required this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'catId': catId,
      'moduleKey': moduleKey,
      'sentenceId': sentenceId,
      'usedAt': usedAt.toIso8601String(),
    };
  }

  factory UsageHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return UsageHistoryEntry(
      catId: map['catId'] as String? ?? '',
      moduleKey: map['moduleKey'] as String? ?? '',
      sentenceId: map['sentenceId'] as String? ?? '',
      usedAt: DateTime.tryParse(map['usedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
