/// 네 가지 마음편지(감사·용서·미안함·사랑)의 종류.
///
/// 그림자 고양이에게 쓰는 기존 편지(감정 기반, 다음날 답장)와는 별개로,
/// 언제든 짧게 쓰고 그 자리에서 곧바로 따뜻한 답장을 받을 수 있는
/// 가벼운 마음편지 기능입니다.
enum SpecialLetterType { gratitude, forgiveness, apology, love }

extension SpecialLetterTypeX on SpecialLetterType {
  String get label {
    switch (this) {
      case SpecialLetterType.gratitude:
        return '감사 편지';
      case SpecialLetterType.forgiveness:
        return '용서 편지';
      case SpecialLetterType.apology:
        return '미안한 편지';
      case SpecialLetterType.love:
        return '사랑 편지';
    }
  }

  /// 짧은 박스 안에 보이는 한 줄 안내.
  String get shortPrompt {
    switch (this) {
      case SpecialLetterType.gratitude:
        return '고마운 마음을 짧게 전해보세요';
      case SpecialLetterType.forgiveness:
        return '내려놓고 싶은 마음을 적어보세요';
      case SpecialLetterType.apology:
        return '미안했던 마음을 살짝 꺼내보세요';
      case SpecialLetterType.love:
        return '사랑하는 마음을 담아보세요';
    }
  }

  /// 편지 쓰기 박스 안의 질문 문구.
  String get question {
    switch (this) {
      case SpecialLetterType.gratitude:
        return '누구에게, 무엇이 고마웠나요?';
      case SpecialLetterType.forgiveness:
        return '누구를(또는 나 자신을) 용서하고 싶나요?';
      case SpecialLetterType.apology:
        return '누구에게, 어떤 마음이 미안한가요?';
      case SpecialLetterType.love:
        return '누구에게, 어떤 사랑을 전하고 싶나요?';
    }
  }

  String get hint {
    switch (this) {
      case SpecialLetterType.gratitude:
        return '짧아도 괜찮아요. 떠오르는 그대로 적어보세요';
      case SpecialLetterType.forgiveness:
        return '용서는 그 사람을 위한 것이 아니라, 나를 위한 것이에요';
      case SpecialLetterType.apology:
        return '누구에게도 보내지 않아도 돼요. 마음을 위한 기록이에요';
      case SpecialLetterType.love:
        return '나 자신에게 보내는 사랑도 좋아요';
    }
  }

  String get emoji {
    switch (this) {
      case SpecialLetterType.gratitude:
        return '🌼';
      case SpecialLetterType.forgiveness:
        return '🕊️';
      case SpecialLetterType.apology:
        return '🌧️';
      case SpecialLetterType.love:
        return '💗';
    }
  }

  String get storageKey {
    switch (this) {
      case SpecialLetterType.gratitude:
        return 'gratitude';
      case SpecialLetterType.forgiveness:
        return 'forgiveness';
      case SpecialLetterType.apology:
        return 'apology';
      case SpecialLetterType.love:
        return 'love';
    }
  }

  static SpecialLetterType fromStorageKey(String key) {
    return SpecialLetterType.values.firstWhere(
      (t) => t.storageKey == key,
      orElse: () => SpecialLetterType.gratitude,
    );
  }
}

/// 마음편지 한 통의 기록. 보내는 즉시 답장 텍스트가 함께 생성되어
/// 저장되므로(다음날까지 기다리지 않음), [replyText]는 항상 값이 있습니다.
class SpecialLetterEntry {
  final String id;
  final SpecialLetterType type;
  final String letterText;
  final String replyText;
  final DateTime createdAt;

  SpecialLetterEntry({
    required this.id,
    required this.type,
    required this.letterText,
    required this.replyText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.storageKey,
      'letterText': letterText,
      'replyText': replyText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SpecialLetterEntry.fromMap(Map<dynamic, dynamic> map) {
    return SpecialLetterEntry(
      id: map['id'] as String,
      type: SpecialLetterTypeX.fromStorageKey(map['type'] as String? ?? 'gratitude'),
      letterText: map['letterText'] as String? ?? '',
      replyText: map['replyText'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
