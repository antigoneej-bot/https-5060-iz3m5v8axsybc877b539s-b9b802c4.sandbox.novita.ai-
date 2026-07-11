/// 그림자 고양이에게 쓴 편지 기록
class LetterEntry {
  final String id;
  final String catId; // ShadowCat.id
  final DateTime date;
  final String letterText;
  final double tempBefore;
  final double? tempAfter;
  final String? meditationKey;

  LetterEntry({
    required this.id,
    required this.catId,
    required this.date,
    required this.letterText,
    required this.tempBefore,
    this.tempAfter,
    this.meditationKey,
  });

  double? get tempChange {
    if (tempAfter == null) return null;
    return tempAfter! - tempBefore;
  }

  bool get improved => tempChange != null && tempChange! > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'date': date.toIso8601String(),
      'letterText': letterText,
      'tempBefore': tempBefore,
      'tempAfter': tempAfter,
      'meditationKey': meditationKey,
    };
  }

  factory LetterEntry.fromMap(Map<dynamic, dynamic> map) {
    return LetterEntry(
      id: map['id'] as String,
      catId: map['catId'] as String,
      date: DateTime.parse(map['date'] as String),
      letterText: map['letterText'] as String? ?? '',
      tempBefore: (map['tempBefore'] as num?)?.toDouble() ?? 0,
      tempAfter: (map['tempAfter'] as num?)?.toDouble(),
      meditationKey: map['meditationKey'] as String?,
    );
  }
}
