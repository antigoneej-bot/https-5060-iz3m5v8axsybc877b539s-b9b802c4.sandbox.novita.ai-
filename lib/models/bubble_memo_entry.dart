/// 방울 터뜨리기 중 감정 고양이에게 남기는 아주 짧은 한마디(선택 입력).
///
/// 정식 '편지'(LetterEntry)보다 훨씬 가벼운 기록으로, 오늘 마주한 감정을
/// 터뜨리는 순간 스쳐가듯 떠오른 말을 그대로 담습니다. 이 한마디는 나중에
/// 같은 감정의 방울을 다시 마주쳤을 때 그 고양이가 "기억"하고 회상해줄 수
/// 있는 재료가 됩니다 - 앱을 "나를 기억해주는 공간"으로 느끼게 하는 장치.
///
/// 감정 카테고리는 [catId] 자체가 이미 하나의 감정을 대표하므로(42마리
/// 그림자 고양이 = 42개의 감정) 별도 필드로 중복 저장하지 않습니다.
/// (cat_emotion_tone.dart에서 언제든 tone/intensity로 파생 가능)
class BubbleMemoEntry {
  final String id;
  final String catId;
  final DateTime date;
  final String message;

  /// 이 한마디가 마지막으로 회상(캐릭터 대사창에 노출)된 시각.
  /// 아직 한 번도 회상되지 않았다면 null.
  final DateTime? lastRecalledAt;

  const BubbleMemoEntry({
    required this.id,
    required this.catId,
    required this.date,
    required this.message,
    this.lastRecalledAt,
  });

  BubbleMemoEntry copyWith({DateTime? lastRecalledAt}) {
    return BubbleMemoEntry(
      id: id,
      catId: catId,
      date: date,
      message: message,
      lastRecalledAt: lastRecalledAt ?? this.lastRecalledAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'date': date.toIso8601String(),
      'message': message,
      'lastRecalledAt': lastRecalledAt?.toIso8601String(),
    };
  }

  factory BubbleMemoEntry.fromMap(Map<dynamic, dynamic> map) {
    return BubbleMemoEntry(
      id: map['id'] as String,
      catId: map['catId'] as String,
      date: DateTime.parse(map['date'] as String),
      message: map['message'] as String? ?? '',
      lastRecalledAt: map['lastRecalledAt'] != null
          ? DateTime.parse(map['lastRecalledAt'] as String)
          : null,
    );
  }
}
