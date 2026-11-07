/// '그림자 방울 묻어두기' 기능에서, 오늘 당장 다루지 않고 잠시 땅에 묻어둔
/// 감정 하나의 기록.
///
/// 이 기록은 "미해결 문제" 목록이 아닙니다 - 며칠 뒤 새싹으로 조용히
/// 다시 떠올라, 원한다면 그때의 마음이 지금은 어떤지 짧게 되짚어볼 수 있는
/// 기회를 주는 용도로만 쓰입니다. 재기록을 하지 않고 그냥 흘려보내도
/// 아무 문제가 없습니다(실패/미완료 개념 없음).
class BuriedEmotionEntry {
  final String id;

  /// 묻어둔 감정이 어떤 그림자 고양이(감정 카테고리)였는지.
  final String catId;

  /// 묻을 당시 남겼던 일기/편지의 일부(짧게 잘라낸 문장). 재부상했을 때
  /// "그때는 이런 마음이었어요"를 보여주는 데 씁니다.
  final String letterSnippet;

  /// 묻은 날짜/시각.
  final DateTime buriedAt;

  /// 새싹으로 다시 떠오르는 예정 시각. 지금은 고정 7일 뒤로 두되, 추후
  /// 랜덤(3~10일)으로 튜닝할 수 있도록 이 값 자체를 저장해 둡니다.
  final DateTime resurfaceAt;

  /// 새싹을 이미 만나서(재기록했든, 조용히 흘려보냈든) 처리를 마쳤는지 여부.
  /// true가 되면 더 이상 "떠오를 새싹" 목록에 나타나지 않습니다.
  final bool resurfaced;

  /// 재부상했을 때 사용자가 실제로 짧은 재기록을 남겼는지 여부.
  /// 남기지 않고 흘려보냈다면 false로 남지만, 이는 실패가 아니라
  /// 그저 "그렇게 놓아준 것"으로 취급합니다.
  final bool recorded;

  /// 재기록 시 남긴 짧은 글(선택 사항). 재기록하지 않았다면 null.
  final String? currentReflectionText;

  const BuriedEmotionEntry({
    required this.id,
    required this.catId,
    required this.letterSnippet,
    required this.buriedAt,
    required this.resurfaceAt,
    this.resurfaced = false,
    this.recorded = false,
    this.currentReflectionText,
  });

  BuriedEmotionEntry copyWith({
    bool? resurfaced,
    bool? recorded,
    String? currentReflectionText,
  }) {
    return BuriedEmotionEntry(
      id: id,
      catId: catId,
      letterSnippet: letterSnippet,
      buriedAt: buriedAt,
      resurfaceAt: resurfaceAt,
      resurfaced: resurfaced ?? this.resurfaced,
      recorded: recorded ?? this.recorded,
      currentReflectionText:
          currentReflectionText ?? this.currentReflectionText,
    );
  }

  /// 지금 시각 기준으로 새싹이 떠오를 시점이 되었는지 여부.
  bool isReadyToResurface({DateTime? now}) {
    final ref = now ?? DateTime.now();
    return !resurfaced && !ref.isBefore(resurfaceAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'letterSnippet': letterSnippet,
      'buriedAt': buriedAt.toIso8601String(),
      'resurfaceAt': resurfaceAt.toIso8601String(),
      'resurfaced': resurfaced,
      'recorded': recorded,
      'currentReflectionText': currentReflectionText,
    };
  }

  factory BuriedEmotionEntry.fromMap(Map<dynamic, dynamic> map) {
    return BuriedEmotionEntry(
      id: map['id'] as String,
      catId: map['catId'] as String? ?? '',
      letterSnippet: map['letterSnippet'] as String? ?? '',
      buriedAt:
          DateTime.tryParse(map['buriedAt'] as String? ?? '') ?? DateTime.now(),
      resurfaceAt:
          DateTime.tryParse(map['resurfaceAt'] as String? ?? '') ??
          DateTime.now(),
      resurfaced: map['resurfaced'] as bool? ?? false,
      recorded: map['recorded'] as bool? ?? false,
      currentReflectionText: map['currentReflectionText'] as String?,
    );
  }
}
