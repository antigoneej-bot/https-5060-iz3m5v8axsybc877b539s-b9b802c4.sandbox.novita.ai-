import '../utils/feature_flags.dart';

/// 그림자 고양이에게 쓴 편지 기록
class LetterEntry {
  final String id;
  final String catId; // ShadowCat.id
  final DateTime date;
  final String letterText;

  /// 편지를 보낸 뒤 선택적으로 실천한 명상/움직임 가이드 키. 명상은 어디까지나
  /// 선택사항이라, 실천하지 않았다면 null입니다(편지 저장 자체와는 무관).
  final String? meditationKey;

  /// 오늘의 기분을 나타내는 이모티콘(날씨처럼 고르는 방식). 글을 쓰기 힘들거나
  /// 귀찮을 때, 이 이모티콘 하나로 편지 내용을 대신할 수 있습니다. 선택하지
  /// 않았다면 null.
  final String? moodEmoji;

  /// 이 편지에 대한 고양이의 답장을 이미 열어봤는지 여부. 홈 화면의
  /// "답장이 도착했어요" 배너를 한 번만 보여주기 위한 플래그입니다.
  final bool replySeen;

  LetterEntry({
    required this.id,
    required this.catId,
    required this.date,
    required this.letterText,
    this.meditationKey,
    this.moodEmoji,
    this.replySeen = false,
  });

  /// 답장을 열어봤음을 표시한 새 인스턴스를 반환합니다.
  LetterEntry withReplySeen() {
    return LetterEntry(
      id: id,
      catId: catId,
      date: date,
      letterText: letterText,
      meditationKey: meditationKey,
      moodEmoji: moodEmoji,
      replySeen: true,
    );
  }

  /// 편지를 보낸 뒤 명상을 실천했다면(또는 건너뛰었다면) 그 결과를 반영한
  /// 새 인스턴스를 반환합니다. 편지 저장 자체는 이미 끝난 뒤에 호출되므로,
  /// 명상을 하지 않고 건너뛰어도 편지 기록은 안전하게 남아 있습니다.
  LetterEntry withMeditationKey(String? key) {
    return LetterEntry(
      id: id,
      catId: catId,
      date: date,
      letterText: letterText,
      meditationKey: key,
      moodEmoji: moodEmoji,
      replySeen: replySeen,
    );
  }

  /// 이 편지에 대한 그림자 고양이의 답장을 열어볼 수 있게 되는 시각.
  /// "오늘 편지를 쓰면 다음날 아침에 답장이 온다"는 컨셉을 살려,
  /// 편지를 쓴 날의 다음날 오전 6시로 고정합니다(저장하지 않고 매번
  /// [date] 기준으로 계산하므로 별도 마이그레이션이 필요 없습니다).
  DateTime get replyAvailableAt {
    final next = date.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, 6, 0);
  }

  /// 지금 시각 기준으로 답장을 열어볼 수 있는 상태인지 여부.
  ///
  /// ⚠️ [FeatureFlags.debugInstantReply]가 true인 동안에는 대기 없이 항상
  /// true를 반환합니다(디버그 전용, 정식 배포 전 반드시 false로 되돌릴 것).
  bool get isReplyReady =>
      FeatureFlags.debugInstantReply ||
      DateTime.now().isAfter(replyAvailableAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'date': date.toIso8601String(),
      'letterText': letterText,
      'meditationKey': meditationKey,
      'moodEmoji': moodEmoji,
      'replySeen': replySeen,
    };
  }

  factory LetterEntry.fromMap(Map<dynamic, dynamic> map) {
    return LetterEntry(
      id: map['id'] as String,
      catId: map['catId'] as String,
      date: DateTime.parse(map['date'] as String),
      letterText: map['letterText'] as String? ?? '',
      meditationKey: map['meditationKey'] as String?,
      moodEmoji: map['moodEmoji'] as String?,
      replySeen: map['replySeen'] as bool? ?? false,
    );
  }
}
