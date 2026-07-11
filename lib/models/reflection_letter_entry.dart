/// 월간 리플렉션 레터(프리미엄) - 한 달간 만난 그림자 고양이 한 마리에게
/// 남긴 짧은 답장 한 장을 나타냅니다.
/// '위로/해결'이 아니라, 그 달의 감정을 되짚어보며 스스로에게 쓰는 기록입니다.
class ReflectionLetterEntry {
  final String id;
  final String catId; // ShadowCat.id
  final String monthKey; // 'yyyy-MM' 형식, 어떤 달의 회고인지 구분
  final DateTime date;
  final String letterText;

  ReflectionLetterEntry({
    required this.id,
    required this.catId,
    required this.monthKey,
    required this.date,
    required this.letterText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'monthKey': monthKey,
      'date': date.toIso8601String(),
      'letterText': letterText,
    };
  }

  factory ReflectionLetterEntry.fromMap(Map<dynamic, dynamic> map) {
    return ReflectionLetterEntry(
      id: map['id'] as String,
      catId: map['catId'] as String,
      monthKey: map['monthKey'] as String,
      date: DateTime.parse(map['date'] as String),
      letterText: map['letterText'] as String? ?? '',
    );
  }
}
