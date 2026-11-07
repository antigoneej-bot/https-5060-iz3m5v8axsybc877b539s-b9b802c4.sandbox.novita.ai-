/// 데일리 카드뽑기(무의식) 기록 — 하루에 한 번, 완전 무작위로 뽑힌 그림자
/// 고양이를 영구적으로 남겨두기 위한 모델입니다.
///
/// [LetterEntry]가 '의식적으로 선택한' 고양이를 기록하는 반면, 이 모델은
/// '무의식(랜덤 추첨)이 보여준' 고양이를 기록합니다. 두 기록을 비교하면
/// 동시성(Synchronicity)이나 반복되는 그림자 패턴을 관찰할 수 있습니다.
class DailyDrawEntry {
  /// 하루에 한 번만 뽑히므로, 날짜 하나당 항목 하나입니다.
  /// id는 날짜 문자열(yyyy-MM-dd 00:00 기준 ISO)을 그대로 사용해
  /// 자연스럽게 하루 1건만 저장되도록 합니다.
  final String id;
  final String catId; // ShadowCat.id
  final DateTime date;

  DailyDrawEntry({required this.id, required this.catId, required this.date});

  Map<String, dynamic> toMap() {
    return {'id': id, 'catId': catId, 'date': date.toIso8601String()};
  }

  factory DailyDrawEntry.fromMap(Map<dynamic, dynamic> map) {
    return DailyDrawEntry(
      id: map['id'] as String,
      catId: map['catId'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
