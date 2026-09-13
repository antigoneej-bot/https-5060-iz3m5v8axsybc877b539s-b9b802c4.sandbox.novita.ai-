import '../models/letter_entry.dart';
import '../models/buried_emotion_entry.dart';

/// '주간 그림자 지도' 기능을 위한 순수 집계(계산) 서비스.
///
/// reflection_service.dart와 같은 원칙을 따릅니다: 위로·평가 언어를 쓰지
/// 않고, 있는 그대로의 빈도·패턴만 관찰해 문장으로 만듭니다. 데이터가
/// 부족하면 억지로 문장을 만들지 않고 null을 반환해, 화면에서 '아직 데이터가
/// 부족해요' 같은 중립적인 안내로 대체합니다.
///
/// 데이터 소스: 기본적으로 LetterEntry(감정체크) 하나만 사용합니다. '오늘의
/// 그림자 방울 터뜨리기'의 방울 색상도 오늘의 LetterEntry에서 파생되므로
/// (1:1), 감정체크 기록이 이미 두 기능의 데이터를 모두 대표합니다. 다만
/// '다시 떠오른 감정'(묻어두기 연동) 인사이트는 예외로, BuriedEmotionEntry
/// (묻어두기 기록)를 별도로 받아 계산합니다 — 이 데이터는 LetterEntry에서
/// 파생되지 않는 독립적인 기록이기 때문입니다.
class WeeklyShadowMapService {
  WeeklyShadowMapService._();

  // ── 무료 티어: 이번 주 Top 3 ──

  /// 최근 7일간 catId별 등장 횟수를 빈도 내림차순으로 정렬해 최대 [limit]개만
  /// 반환합니다((catId, count) 목록). 동률이면 원래 빈도 계산 순서를 유지합니다.
  static List<(String, int)> topEmotionsThisWeek(
    Map<String, int> weeklyFrequency, {
    int limit = 3,
  }) {
    final entries = weeklyFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => (e.key, e.value)).toList();
  }

  /// 이번 주 총 기록 횟수 대비 Top 3가 차지하는 비율(0~1). 파이차트/비율
  /// 표시에 사용합니다. 총합이 0이면 빈 목록.
  static List<(String catId, int count, double ratio)> topEmotionsRatio(
    Map<String, int> weeklyFrequency, {
    int limit = 3,
  }) {
    final total = weeklyFrequency.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];
    final top = topEmotionsThisWeek(weeklyFrequency, limit: limit);
    return top.map((e) => (e.$1, e.$2, e.$2 / total)).toList();
  }

  // ── 프리미엄 티어: 월/분기 비교 ──

  /// 두 기간(A, B) 각각의 catId별 빈도를 계산합니다. [aStart]~[aEnd],
  /// [bStart]~[bEnd]는 날짜 단위(양끝 포함)입니다. 월간 비교("이번 달 vs
  /// 지난 달") 또는 분기 비교("이번 분기 vs 지난 분기") 모두 이 함수 하나로
  /// 처리할 수 있습니다.
  static (Map<String, int> a, Map<String, int> b) comparePeriods(
    List<LetterEntry> history, {
    required DateTime aStart,
    required DateTime aEnd,
    required DateTime bStart,
    required DateTime bEnd,
  }) {
    Map<String, int> freqInRange(DateTime start, DateTime end) {
      final freq = <String, int>{};
      for (final e in history) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (!d.isBefore(start) && !d.isAfter(end)) {
          freq[e.catId] = (freq[e.catId] ?? 0) + 1;
        }
      }
      return freq;
    }

    return (freqInRange(aStart, aEnd), freqInRange(bStart, bEnd));
  }

  /// 이번 달(1일~오늘) vs 지난 달(같은 일수) 빈도 비교의 편의 함수.
  static (Map<String, int> thisMonth, Map<String, int> lastMonth)
  compareThisMonthVsLastMonth(List<LetterEntry> history, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final thisMonthStart = DateTime(ref.year, ref.month, 1);
    // 지난 달 같은 구간(1일부터, 오늘까지 지난 일수만큼)만 비교해 공정하게 만듭니다.
    final daysSoFar = todayStart.difference(thisMonthStart).inDays;
    final lastMonthStart = DateTime(ref.year, ref.month - 1, 1);
    final candidateEnd = lastMonthStart.add(Duration(days: daysSoFar));
    final previousEnd = DateTime(ref.year, ref.month, 0);
    final lastMonthEnd = candidateEnd.isAfter(previousEnd) ? previousEnd : candidateEnd;
    return comparePeriods(
      history,
      aStart: thisMonthStart,
      aEnd: todayStart,
      bStart: lastMonthStart,
      bEnd: lastMonthEnd,
    );
  }

  /// 이번 분기(3개월) vs 지난 분기 빈도 비교의 편의 함수.
  static (Map<String, int> thisQuarter, Map<String, int> lastQuarter)
  compareThisQuarterVsLastQuarter(List<LetterEntry> history, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final quarterStartMonth = ((ref.month - 1) ~/ 3) * 3 + 1;
    final thisQuarterStart = DateTime(ref.year, quarterStartMonth, 1);
    final daysSoFar = todayStart.difference(thisQuarterStart).inDays;
    final lastQuarterStart = DateTime(ref.year, quarterStartMonth - 3, 1);
    final candidateEnd = lastQuarterStart.add(Duration(days: daysSoFar));
    final previousEnd = thisQuarterStart.subtract(const Duration(days: 1));
    final lastQuarterEnd = candidateEnd.isAfter(previousEnd) ? previousEnd : candidateEnd;
    return comparePeriods(
      history,
      aStart: thisQuarterStart,
      aEnd: todayStart,
      bStart: lastQuarterStart,
      bEnd: lastQuarterEnd,
    );
  }

  /// 기간 비교 결과를 관찰형 문장으로 만듭니다. 두 기간 모두 데이터가
  /// 없으면 null. '늘었다/줄었다'는 사실 서술만 하고 좋다/나쁘다 평가는
  /// 하지 않습니다.
  static String? periodComparisonSentence({
    required Map<String, int> currentFreq,
    required Map<String, int> previousFreq,
    required String Function(String catId) catNameFor,
    required String periodLabel, // 예: '이번 달', '이번 분기'
    required String previousLabel, // 예: '지난 달', '지난 분기'
  }) {
    if (currentFreq.isEmpty && previousFreq.isEmpty) return null;
    String? topOf(Map<String, int> freq) {
      if (freq.isEmpty) return null;
      String? topId;
      int topCount = -1;
      freq.forEach((catId, count) {
        if (count > topCount) {
          topCount = count;
          topId = catId;
        }
      });
      return topId;
    }

    final currentTop = topOf(currentFreq);
    final previousTop = topOf(previousFreq);
    if (currentTop == null && previousTop != null) {
      return '$previousLabel엔 ${catNameFor(previousTop)}가 자주 보였지만,\n$periodLabel엔 아직 기록이 없어요.';
    }
    if (currentTop != null && previousTop == null) {
      return '$previousLabel엔 기록이 없었지만,\n$periodLabel엔 ${catNameFor(currentTop)}가 자주 보였어요.';
    }
    if (currentTop == previousTop) {
      return '$previousLabel과 $periodLabel 모두,\n${catNameFor(currentTop!)}가 가장 자주 나타났어요.';
    }
    return '$previousLabel엔 ${catNameFor(previousTop!)}가,\n$periodLabel엔 ${catNameFor(currentTop!)}가 가장 자주 나타났어요.';
  }

  // ── 프리미엄 티어: 요일별 / 시간대별 패턴 ──

  /// 최근 [days]일(기본 90일)간의 (요일, 시간대 구간) 별 catId 빈도를
  /// 계산합니다. 시간대는 4구간(새벽 0~5, 오전 6~11, 오후 12~17, 저녁
  /// 18~23)으로 나눕니다.
  static Map<(int weekday, String slot), Map<String, int>>
  weekdayTimeSlotFrequency(
    List<LetterEntry> history, {
    int days = 90,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final cutoff = todayStart.subtract(Duration(days: days - 1));
    final result = <(int, String), Map<String, int>>{};
    for (final e in history) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d.isBefore(cutoff) || d.isAfter(todayStart)) continue;
      final slot = timeSlotFor(e.date.hour);
      final key = (e.date.weekday, slot);
      final freq = result.putIfAbsent((e.date.weekday, slot), () => {});
      freq[e.catId] = (freq[e.catId] ?? 0) + 1;
      result[key] = freq;
    }
    return result;
  }

  /// 시(hour, 0~23)를 4개의 한글 시간대 라벨로 변환합니다.
  static String timeSlotFor(int hour) {
    if (hour >= 0 && hour < 6) return '새벽';
    if (hour >= 6 && hour < 12) return '오전';
    if (hour >= 12 && hour < 18) return '오후';
    return '저녁';
  }

  static const List<String> _weekdayLabels = [
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  /// weekday(1~7, DateTime.monday=1 기준)를 한글 요일 라벨로 변환합니다.
  static String weekdayLabelFor(int weekday) => _weekdayLabels[weekday - 1];

  /// 요일×시간대 조합 중, 특정 catId가 [threshold]회 이상 나타난 가장 뚜렷한
  /// 패턴 하나를 찾아 문장으로 만듭니다("화요일 오후에 불안 감정이 자주
  /// 나타나요" 형태). 조건을 만족하는 조합이 없으면 null.
  static String? weekdayTimeInsightSentence(
    List<LetterEntry> history, {
    required String Function(String catId) catNameFor,
    int days = 90,
    int threshold = 3,
    DateTime? now,
  }) {
    final buckets = weekdayTimeSlotFrequency(history, days: days, now: now);
    if (buckets.isEmpty) return null;

    (int weekday, String slot)? bestKey;
    String? bestCatId;
    int bestCount = -1;
    buckets.forEach((key, freq) {
      freq.forEach((catId, count) {
        if (count > bestCount) {
          bestCount = count;
          bestCatId = catId;
          bestKey = key;
        }
      });
    });

    if (bestKey == null || bestCatId == null || bestCount < threshold) {
      return null;
    }
    final weekdayLabel = weekdayLabelFor(bestKey!.$1);
    final slotLabel = bestKey!.$2;
    final name = catNameFor(bestCatId!);
    return '최근 $days일 동안 $weekdayLabel요일 $slotLabel에\n$name 감정을 $bestCount번 기록했어요. 감정을 느낀 시간이 아닌 기록한 시간 기준이에요.';
  }

  // ── 프리미엄 티어: 다시 떠오른 감정(묻어두기 아카이빙 연동) ──

  /// [buriedEntries]는 BuriedEmotionService.getAllEntries()의 결과(계정의
  /// 전체 '묻어두기' 기록, 최신순)를 그대로 받습니다. 이 함수는 그중 최근
  /// [days]일 사이에 실제로 새싹으로 '떠올랐던'(resurfaced == true) 기록만
  /// 모아 관찰형 문장으로 만듭니다. 아직 땅 속에서 기다리는 중인 기록은
  /// 대상에서 제외합니다.
  ///
  /// - 재기록(그때의 마음을 지금 다시 적음)까지 남긴 가장 최근 기록이 있다면
  ///   "그때는 ○○, 지금은 △△"처럼 그때와 지금을 나란히 보여줍니다. 과거에
  ///   남겼던 문장은 절대 다른 말로 바꾸지 않고 원문 그대로 인용하며, 그
  ///   내용이 부정적이어도 이 문장 자체는 평가/위로 언어를 더하지 않습니다
  ///   (있는 그대로 관찰만 서술).
  /// - 재기록 없이 조용히 흘려보낸 경우까지 포함해, 재기록이 하나도 없다면
  ///   빈도만 알리는 문장으로 대체합니다.
  /// - 기간 안에 떠오른 기록이 하나도 없으면 null(화면에서 중립적인 안내로
  ///   대체됩니다).
  static String? buriedResurfaceTrendSentence(
    List<BuriedEmotionEntry> buriedEntries, {
    required String Function(String catId) catNameFor,
    int days = 30,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final cutoff = todayStart.subtract(Duration(days: days - 1));

    final resurfacedInPeriod = buriedEntries.where((e) {
      if (!e.resurfaced) return false;
      final d = DateTime(
        e.resurfaceAt.year,
        e.resurfaceAt.month,
        e.resurfaceAt.day,
      );
      return !d.isBefore(cutoff) && !d.isAfter(todayStart);
    }).toList();

    if (resurfacedInPeriod.isEmpty) return null;

    final withReflection =
        resurfacedInPeriod
            .where(
              (e) =>
                  e.recorded &&
                  (e.currentReflectionText?.trim().isNotEmpty ?? false),
            )
            .toList()
          ..sort((a, b) => b.buriedAt.compareTo(a.buriedAt));

    if (withReflection.isNotEmpty) {
      final target = withReflection.first;
      final name = catNameFor(target.catId);
      final then = target.letterSnippet.trim().isEmpty
          ? '(그날 남긴 짧은 문장은 따로 없어요)'
          : target.letterSnippet.trim();
      final nowText = target.currentReflectionText!.trim();
      final countNote = resurfacedInPeriod.length > 1
          ? '\n(이 기간 동안 총 ${resurfacedInPeriod.length}번 다시 떠올랐어요.)'
          : '';
      return '묻어두었던 $name 감정이 다시 떠올랐어요.\n'
          '그때는 "$then"이었는데,\n'
          '지금은 "$nowText"라고 적었어요.$countNote';
    }

    final count = resurfacedInPeriod.length;
    final names = resurfacedInPeriod.map((e) => catNameFor(e.catId)).toSet();
    final nameList = names.take(2).join(', ');
    return '이 기간 동안, 묻어두었던 $nameList 감정이\n총 $count번 새싹으로 다시 떠올랐어요.';
  }
}
