import 'emotion_entry.dart';

/// 한 달 동안의 감정기록을 분석한 결과.
/// 통계(그래프용 데이터) + 따뜻한 해석 문장 + 조언 + 추천 명상을 함께 담습니다.
class MonthlyEmotionReport {
  final int year;
  final int month;
  final List<EmotionEntry> entries;

  final Map<EmotionType, int> emotionCounts;
  final EmotionType? dominantEmotion;
  final Map<EmotionType, double> emotionRatios; // 0~1

  /// 일자별 평균 감정 점수 (부호 있음, -5~+5). 날짜순 정렬.
  final List<MapEntry<DateTime, double>> dailyScores;

  /// 주차별(1~5주) 평균 감정 점수
  final List<double> weeklyScores;

  /// 주차별로 가장 두드러졌던 감정 (있다면)
  final List<EmotionType?> weeklyDominant;

  final double avgIntensityFirstHalf;
  final double avgIntensitySecondHalf;

  final int positiveCount;
  final int negativeCount;
  final double positiveRatio;
  final double negativeRatio;

  /// 감정 기복 정도 (일별 점수의 표준편차, 클수록 기복이 큼)
  final double volatility;

  final String oneLineSummary;
  final String analysisText;
  final String adviceText;
  final List<String> recommendedMeditationKeys;
  final String recommendationReason;

  const MonthlyEmotionReport({
    required this.year,
    required this.month,
    required this.entries,
    required this.emotionCounts,
    required this.dominantEmotion,
    required this.emotionRatios,
    required this.dailyScores,
    required this.weeklyScores,
    required this.weeklyDominant,
    required this.avgIntensityFirstHalf,
    required this.avgIntensitySecondHalf,
    required this.positiveCount,
    required this.negativeCount,
    required this.positiveRatio,
    required this.negativeRatio,
    required this.volatility,
    required this.oneLineSummary,
    required this.analysisText,
    required this.adviceText,
    required this.recommendedMeditationKeys,
    required this.recommendationReason,
  });

  bool get isEmpty => entries.isEmpty;

  String get yearMonthKey => '$year-${month.toString().padLeft(2, '0')}';

  String get monthLabel => '$year년 $month월';
}
