/// 오늘 나를 위해 지켜주고 싶은 약속 하나.
/// 일반적인 '할 일(Todo)'이 아니라, 하루 동안 스스로에게 건네는 다짐이라는
/// 톤을 지키기 위해 필드명도 의도적으로 '약속(promise)'으로 통일했습니다.
/// 자정이 지나면 지키지 못한 약속도 '실패'로 남기지 않고 조용히 정리됩니다
/// (PromiseService의 자동 아카이빙 로직 참고).
class PromiseEntry {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool kept; // 지켰는지 여부 ('완료'라는 생산성 용어 대신 '지켰다'로 표현)
  final DateTime? keptAt;

  const PromiseEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.kept = false,
    this.keptAt,
  });

  /// 지켰는지 여부를 갱신합니다. [kept]가 true이면 [keptAt]도 지금 시각으로,
  /// false이면 [keptAt]도 함께 비웁니다.
  PromiseEntry withKept(bool kept) {
    return PromiseEntry(
      id: id,
      text: text,
      createdAt: createdAt,
      kept: kept,
      keptAt: kept ? DateTime.now() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'kept': kept,
      'keptAt': keptAt?.toIso8601String(),
    };
  }

  factory PromiseEntry.fromMap(Map<dynamic, dynamic> map) {
    return PromiseEntry(
      id: map['id'] as String,
      text: map['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      kept: map['kept'] as bool? ?? false,
      keptAt: map['keptAt'] != null
          ? DateTime.tryParse(map['keptAt'] as String)
          : null,
    );
  }
}
