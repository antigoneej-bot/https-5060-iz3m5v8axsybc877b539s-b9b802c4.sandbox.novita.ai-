import '../models/emotion.dart';
import '../models/emotion_trigger.dart';
import 'emotion_insight_service.dart';

/// "몽이의 마음 성찰" - 옵트인 AI 리플렉션(벤치마킹 제안 #6).
///
/// [EmotionInsightService]/[MongiLetterService]의 다른 함수들은 각각 하나의
/// 축(주간/요일/트리거/무드흐름)만 따로 계산하지만, 이 서비스는 그 결과들을
/// "교차"로 엮어서 지금까지 없던 통찰을 만든다 - 예를 들어 "가장 자주 만난
/// 감정이 특정 요일에 몰려있다"거나 "감사 기록을 남긴 날엔 마음이 더
/// 편안했다" 같은, 여러 기록을 동시에 살펴봐야만 알 수 있는 패턴이다.
///
/// 이런 "여러 기록을 한꺼번에 엮어서 보여준다"는 특성이 평소 화면들보다
/// 더 개인적이고 예민하게 느껴질 수 있어, 설정에서 명시적으로 동의한
/// 사용자에게만 노출한다(GardenProvider.aiReflectionOptIn).
///
/// 이름에 "AI"가 들어가지만 실제로는 서버/외부 AI 모델을 전혀 호출하지
/// 않는다 - 이 기기에만 저장된 데이터를 규칙 기반으로 종합해서 돌려주는
/// 순수 함수이며, 이 앱의 다른 인사이트 서비스들과 동일한 설계 원칙
/// ("문구는 화면에서 AppLocalizations로 완성한다")을 따른다.
class MindReflectionService {
  const MindReflectionService._();

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// [EmotionInsightService]의 같은 이름 private 메서드와 동일한 가중치
  /// 규칙으로, 일기 항목 하나의 무드 점수(-1.0 ~ +1.0)를 계산한다.
  static double _entryMoodScore(Map<String, dynamic> entry) {
    final typeName = entry['emotionType'] as String?;
    if (typeName == null) return 0;
    final emotion = Emotion.byTypeName(typeName);
    final intensity = (entry['intensity'] as num?)?.toInt();
    final weight = (intensity != null && intensity >= 1 && intensity <= 5)
        ? intensity / 5.0
        : 0.7;
    return emotion.isPositive ? weight : -weight;
  }

  /// 지금까지 쌓인 기록을 종합해 "마음 성찰" 통찰 목록을 계산한다.
  /// 데이터가 너무 적으면(다이어리 5개 미만) [MindReflectionResult.hasEnoughData]가
  /// false로 반환되며, 화면에서는 대신 "조금 더 기록을 쌓아주세요" 안내를
  /// 보여준다.
  static MindReflectionResult buildReflection({
    required List<Map<String, dynamic>> diaryEntries,
    required List<Map<String, dynamic>> gratitudeEntries,
    required int checkInStreak,
  }) {
    if (diaryEntries.length < 5) {
      return const MindReflectionResult(hasEnoughData: false, insights: []);
    }

    final candidates = <MindReflectionInsight>[];

    // 1) "감정 × 요일" 교차 - 가장 자주 만난 감정이 특정 요일에 유독
    // 몰려있는지 살펴본다. 우연을 배제하기 위해 그 감정의 전체 등장
    // 횟수 중 40% 이상이 한 요일에 몰려있고, 최소 3회 이상일 때만 인정한다.
    final topEmotions = EmotionInsightService.topEmotions(
      diaryEntries: diaryEntries,
      limit: 1,
    );
    if (topEmotions.isNotEmpty && topEmotions.first.value >= 4) {
      final emotion = topEmotions.first.key;
      final weekdayCounts = List<int>.filled(7, 0);
      var total = 0;
      for (final entry in diaryEntries) {
        if (entry['emotionType'] != emotion.type.name) continue;
        final date = _parseDate(entry['date'] as String?);
        if (date == null) continue;
        weekdayCounts[date.weekday % 7]++;
        total++;
      }
      var maxIndex = -1;
      var maxCount = 0;
      for (var i = 0; i < 7; i++) {
        if (weekdayCounts[i] > maxCount) {
          maxCount = weekdayCounts[i];
          maxIndex = i;
        }
      }
      if (maxIndex >= 0 && maxCount >= 3 && maxCount / total >= 0.4) {
        candidates.add(
          MindReflectionInsight(
            kind: MindReflectionInsightKind.emotionWeekdayLink,
            emotion: emotion,
            weekdayIndex: maxIndex,
            count: maxCount,
          ),
        );
      }
    }

    // 2) "원인 × 부정 감정" 교차 - 이미 있는 트리거 인사이트 중, 특정
    // 원인이 부정 감정과 뚜렷하게 연결될 때만 재사용한다.
    final triggerInsight = EmotionInsightService.buildTriggerInsightKind(
      diaryEntries: diaryEntries,
    );
    if (triggerInsight != null &&
        triggerInsight.kind == TriggerInsightKind.dominantNegativeCause) {
      candidates.add(
        MindReflectionInsight(
          kind: MindReflectionInsightKind.triggerNegativeLink,
          trigger: triggerInsight.trigger,
          count: triggerInsight.count,
        ),
      );
    }

    // 3) "성장 신호" - 예전보다 뚜렷하게 줄어든 부정 감정.
    final improved = EmotionInsightService.mostImprovedEmotion(
      diaryEntries: diaryEntries,
    );
    if (improved != null) {
      candidates.add(
        MindReflectionInsight(
          kind: MindReflectionInsightKind.growthSignal,
          emotion: improved,
        ),
      );
    }

    // 4) "감사 기록 × 무드" 교차 - 감사/성취를 남긴 날과 남기지 않은 날의
    // 평균 무드 점수를 비교한다. 두 그룹 모두 최소 3일치 데이터가 있어야
    // 비교 대상으로 인정하고, 차이가 뚜렷할(0.25 이상) 때만 통찰로 채택한다.
    if (gratitudeEntries.length >= 3) {
      final gratitudeDates = gratitudeEntries
          .map((e) => e['date'] as String?)
          .whereType<String>()
          .toSet();
      var sumWith = 0.0;
      var countWith = 0;
      var sumWithout = 0.0;
      var countWithout = 0;
      for (final entry in diaryEntries) {
        final dateStr = entry['date'] as String?;
        if (dateStr == null) continue;
        final score = _entryMoodScore(entry);
        if (gratitudeDates.contains(dateStr)) {
          sumWith += score;
          countWith++;
        } else {
          sumWithout += score;
          countWithout++;
        }
      }
      if (countWith >= 3 && countWithout >= 3) {
        final avgWith = sumWith / countWith;
        final avgWithout = sumWithout / countWithout;
        if (avgWith - avgWithout >= 0.25) {
          candidates.add(
            const MindReflectionInsight(
              kind: MindReflectionInsightKind.gratitudeMoodLink,
            ),
          );
        }
      }
    }

    // 5) "꾸준함" 신호 - 체크인 연속일이 뚜렷하게 쌓였을 때.
    if (checkInStreak >= 5) {
      candidates.add(
        MindReflectionInsight(
          kind: MindReflectionInsightKind.consistencySignal,
          streak: checkInStreak,
        ),
      );
    }

    if (candidates.isEmpty) {
      candidates.add(
        const MindReflectionInsight(
          kind: MindReflectionInsightKind.defaultObservation,
        ),
      );
    }

    // 소음을 줄이기 위해 위 우선순위 중 최대 3개만 보여준다.
    return MindReflectionResult(
      hasEnoughData: true,
      insights: candidates.take(3).toList(),
    );
  }
}

/// [MindReflectionService.buildReflection]이 고를 수 있는 통찰 종류.
/// 실제 문구는 화면에서 [AppLocalizations]를 통해 언어별로 골라 붙인다.
enum MindReflectionInsightKind {
  emotionWeekdayLink,
  triggerNegativeLink,
  growthSignal,
  gratitudeMoodLink,
  consistencySignal,
  defaultObservation,
}

/// 통찰 하나의 계산 결과. [kind]에 따라 필요한 값만 채워진다.
class MindReflectionInsight {
  final MindReflectionInsightKind kind;

  /// emotionWeekdayLink/growthSignal에서 쓰이는 감정.
  final Emotion? emotion;

  /// emotionWeekdayLink에서 쓰이는 "가장 몰려있는 요일"(일=0 ... 토=6).
  final int? weekdayIndex;

  /// triggerNegativeLink에서 쓰이는 트리거 태그.
  final EmotionTrigger? trigger;

  /// emotionWeekdayLink/triggerNegativeLink에서 쓰이는 등장 횟수.
  final int? count;

  /// consistencySignal에서 쓰이는 연속 체크인 일수.
  final int? streak;

  const MindReflectionInsight({
    required this.kind,
    this.emotion,
    this.weekdayIndex,
    this.trigger,
    this.count,
    this.streak,
  });
}

/// [MindReflectionService.buildReflection]의 계산 결과.
class MindReflectionResult {
  /// 성찰을 보여줄 만큼 데이터가 쌓였는지(다이어리 5개 이상).
  final bool hasEnoughData;

  /// 우선순위대로 최대 3개까지의 통찰. [hasEnoughData]가 false면 항상 비어있다.
  final List<MindReflectionInsight> insights;

  const MindReflectionResult({
    required this.hasEnoughData,
    required this.insights,
  });
}
