import '../models/letter_tags.dart';

/// 편지 문장에 이모지를 붙이는 헬퍼 (방법 B - 태그 기반 자동 부착).
///
/// 문장 마스터 데이터(letter_sentence_pools.dart)는 그대로 두고, 조합
/// 단계에서 몇 개 모듈에만 태그에 맞는 이모지를 덧붙입니다. 이렇게 하면
/// 문장을 늘리거나 바꿔도 이모지 로직을 따로 손보지 않아도 됩니다.
///
/// 배치:
/// - ① 인사: 성장 단계에 맞는 고양이 이모지
/// - ⑦ 고양이감정: 그날 고양이 기분에 맞는 표정 이모지
/// - ⑧ 마무리: 친밀도가 깊어질수록 진해지는 하트
class LetterEmojiDecorator {
  LetterEmojiDecorator._();

  static const Map<GrowthTag, String> _greetingEmoji = {
    GrowthTag.baby: '🐾',
    GrowthTag.teen: '😺',
    GrowthTag.young: '🐱',
    GrowthTag.adult: '🐈',
  };

  static const Map<CatMoodTag, String> _catMoodEmoji = {
    CatMoodTag.good: '😊',
    CatMoodTag.sleepy: '😴',
    CatMoodTag.worried: '🥺',
    CatMoodTag.cheer: '💪',
    CatMoodTag.excited: '✨',
    CatMoodTag.playful: '😼',
    CatMoodTag.quiet: '🐾',
  };

  /// 친밀도가 깊어질수록 하트가 진해지도록 단계적으로 배치.
  static const Map<IntimacyTag, String> _closingEmoji = {
    IntimacyTag.firstMeet: '🐾',
    IntimacyTag.shy: '🤍',
    IntimacyTag.friend: '💛',
    IntimacyTag.family: '💚',
    IntimacyTag.lifelongFriend: '💕',
  };

  static String forGreeting(GrowthTag growth) =>
      _greetingEmoji[growth] ?? '🐾';

  static String forCatMood(CatMoodTag mood) => _catMoodEmoji[mood] ?? '🐾';

  static String forClosing(IntimacyTag intimacy) =>
      _closingEmoji[intimacy] ?? '🐾';

  /// 문장 끝에 이모지를 한 칸 띄워 덧붙입니다.
  static String append(String text, String emoji) => '$text $emoji';
}
