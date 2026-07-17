import 'letter_tags.dart';

/// 편지를 만들기 전에 한 번에 모아두는 조립 결과 (설계서 5장 참고).
///
/// `TemplateReplyGenerator`(지금)와 향후 `AiReplyGenerator`(6개월 후, AI 도입 시)가
/// 공유하는 입력 규격입니다. 이 클래스 자체는 절대 바뀌지 않는 것이 목표이며,
/// "무엇으로 편지를 쓰는가"만 고정해두고 "어떻게 조합하는가"는 구현체마다
/// 달라지도록 설계했습니다.
class LetterContext {
  final String catId;
  final EmotionTag todayEmotion;
  final EmotionTag? yesterdayEmotion;
  final List<EmotionTag> last7DaysEmotions;
  final List<EmotionTag> last30DaysEmotions;
  final String? todayLetterText;
  final String? yesterdayLetterText;

  /// 최근 사용된 감정/기억 키워드 (표시용 참고 - 지금 버전에서는 직접 쓰이지
  /// 않지만, AI 전환 시 프롬프트 재료로 바로 활용할 수 있도록 남겨둡니다)
  final List<String> recentKeywords;

  final bool meditationSucceededYesterday;
  final int meditationStreak;

  /// 최근 편지들에서 명상 제안을 연속으로 건너뛴 횟수(설계서 8.2 참고).
  /// 5 이상이면 ⑥ 행동제안 모듈이 "제안형" 대신 "그냥 안부형"으로 자동
  /// 전환되어, 강요로 느껴지지 않도록 합니다.
  final int recentMeditationSkipStreak;
  final int visitStreak;
  final GrowthTag growthStage;
  final IntimacyTag intimacyStage;
  final DateTime now;

  const LetterContext({
    required this.catId,
    required this.todayEmotion,
    this.yesterdayEmotion,
    this.last7DaysEmotions = const [],
    this.last30DaysEmotions = const [],
    this.todayLetterText,
    this.yesterdayLetterText,
    this.recentKeywords = const [],
    this.meditationSucceededYesterday = false,
    this.meditationStreak = 0,
    this.recentMeditationSkipStreak = 0,
    this.visitStreak = 0,
    required this.growthStage,
    required this.intimacyStage,
    required this.now,
  });

  /// 최근 감정이 부정적 톤으로 3일 이상 이어졌는지 (⑦ 고양이 감정 모듈,
  /// '걱정' 가중치 상승 조건에 사용)
  bool get hasNegativeStreak {
    const negative = {
      EmotionTag.anxious,
      EmotionTag.lonely,
      EmotionTag.angry,
      EmotionTag.sad,
      EmotionTag.regretful,
      EmotionTag.weary,
    };
    if (last7DaysEmotions.length < 3) return false;
    return last7DaysEmotions.take(3).every((e) => negative.contains(e));
  }
}
