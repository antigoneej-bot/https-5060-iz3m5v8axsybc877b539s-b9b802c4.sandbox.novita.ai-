import 'dart:math';
import '../models/emotion_entry.dart';
import '../models/monthly_report.dart';

/// 한 달 감정기록을 분석해 통계 + 따뜻한 해석 + 조언 + 추천 명상을 만들어내는 서비스.
/// 사용자를 평가하지 않고, 함께 마음을 들여다봐주는 어투로 문장을 구성합니다.
class MonthlyReportService {
  /// [year]/[month]에 해당하는 감정기록으로 리포트를 생성합니다.
  static MonthlyEmotionReport buildReport({
    required int year,
    required int month,
    required List<EmotionEntry> monthEntries,
  }) {
    final entries = [...monthEntries]..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) {
      return MonthlyEmotionReport(
        year: year,
        month: month,
        entries: const [],
        emotionCounts: const {},
        dominantEmotion: null,
        emotionRatios: const {},
        dailyScores: const [],
        weeklyScores: const [],
        weeklyDominant: const [],
        avgIntensityFirstHalf: 0,
        avgIntensitySecondHalf: 0,
        positiveCount: 0,
        negativeCount: 0,
        positiveRatio: 0,
        negativeRatio: 0,
        volatility: 0,
        oneLineSummary: '이번 달은 아직 기록된 마음이 없어요.',
        analysisText: '매일 조금씩 감정을 남겨두면, 다음 달엔 당신의 마음 흐름을 함께 들여다볼 수 있어요.',
        adviceText: '오늘 하루, 지금 마음이 어떤지 짧게라도 적어보는 건 어떨까요.',
        recommendedMeditationKeys: const ['breathing'],
        recommendationReason: '처음 시작하는 마음에는, 가장 편안한 호흡 명상을 추천해요.',
      );
    }

    // ── 감정별 빈도 / 비율 ──
    final counts = <EmotionType, int>{};
    for (final e in entries) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    final total = entries.length;
    final ratios = <EmotionType, double>{
      for (final e in counts.entries) e.key: e.value / total,
    };
    EmotionType? dominant;
    int bestCount = -1;
    counts.forEach((k, v) {
      if (v > bestCount) {
        bestCount = v;
        dominant = k;
      }
    });

    // ── 일자별 평균 점수 ──
    final byDay = <DateTime, List<EmotionEntry>>{};
    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final dailyKeys = byDay.keys.toList()..sort();
    final dailyScores = <MapEntry<DateTime, double>>[
      for (final d in dailyKeys)
        MapEntry(
          d,
          byDay[d]!.map((e) => e.signedScore).reduce((a, b) => a + b) /
              byDay[d]!.length,
        ),
    ];

    // ── 주차별 평균 점수 & 주요 감정 (1~7일 = 1주 ...) ──
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final weekCount = (daysInMonth / 7).ceil();
    final weeklyScores = <double>[];
    final weeklyDominant = <EmotionType?>[];
    for (int w = 0; w < weekCount; w++) {
      final startDay = w * 7 + 1;
      final endDay = min(startDay + 6, daysInMonth);
      final weekEntries = entries
          .where((e) => e.date.day >= startDay && e.date.day <= endDay)
          .toList();
      if (weekEntries.isEmpty) {
        weeklyScores.add(0);
        weeklyDominant.add(null);
        continue;
      }
      final avg =
          weekEntries.map((e) => e.signedScore).reduce((a, b) => a + b) /
          weekEntries.length;
      weeklyScores.add(avg);
      final wc = <EmotionType, int>{};
      for (final e in weekEntries) {
        wc[e.emotion] = (wc[e.emotion] ?? 0) + 1;
      }
      EmotionType? wDominant;
      int wBest = -1;
      wc.forEach((k, v) {
        if (v > wBest) {
          wBest = v;
          wDominant = k;
        }
      });
      weeklyDominant.add(wDominant);
    }

    // ── 강도 변화 (상반월 vs 하반월) ──
    final firstHalf = entries.where((e) => e.date.day <= 15).toList();
    final secondHalf = entries.where((e) => e.date.day > 15).toList();
    final avgFirst = firstHalf.isEmpty
        ? 0.0
        : firstHalf.map((e) => e.intensity).reduce((a, b) => a + b) /
              firstHalf.length;
    final avgSecond = secondHalf.isEmpty
        ? 0.0
        : secondHalf.map((e) => e.intensity).reduce((a, b) => a + b) /
              secondHalf.length;

    // ── 긍정/부정 비교 ──
    final positive = entries
        .where((e) => e.emotion.valence == EmotionValence.positive)
        .toList();
    final negative = entries
        .where((e) => e.emotion.valence == EmotionValence.negative)
        .toList();
    final positiveRatio = positive.length / total;
    final negativeRatio = negative.length / total;

    // ── 감정 기복(표준편차) ──
    final scores = dailyScores.map((e) => e.value).toList();
    final meanScore = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.isEmpty
        ? 0.0
        : scores.map((s) => pow(s - meanScore, 2)).reduce((a, b) => a + b) /
              scores.length;
    final volatility = sqrt(variance);

    // ── 따뜻한 해석/조언/추천 명상 생성 ──
    final analysis = _buildAnalysis(
      dominant: dominant,
      ratios: ratios,
      weeklyScores: weeklyScores,
      weeklyDominant: weeklyDominant,
      volatility: volatility,
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
      avgFirst: avgFirst,
      avgSecond: avgSecond,
      counts: counts,
      total: total,
    );

    final summary = _buildOneLineSummary(
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
      volatility: volatility,
      weeklyScores: weeklyScores,
    );

    final advice = _buildAdvice(
      dominant: dominant,
      volatility: volatility,
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
      avgFirst: avgFirst,
      avgSecond: avgSecond,
    );

    final (recKeys, recReason) = _buildRecommendation(
      counts: counts,
      total: total,
      dominant: dominant,
    );

    return MonthlyEmotionReport(
      year: year,
      month: month,
      entries: entries,
      emotionCounts: counts,
      dominantEmotion: dominant,
      emotionRatios: ratios,
      dailyScores: dailyScores,
      weeklyScores: weeklyScores,
      weeklyDominant: weeklyDominant,
      avgIntensityFirstHalf: avgFirst,
      avgIntensitySecondHalf: avgSecond,
      positiveCount: positive.length,
      negativeCount: negative.length,
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
      volatility: volatility,
      oneLineSummary: summary,
      analysisText: analysis,
      adviceText: advice,
      recommendedMeditationKeys: recKeys,
      recommendationReason: recReason,
    );
  }

  static String _buildOneLineSummary({
    required double positiveRatio,
    required double negativeRatio,
    required double volatility,
    required List<double> weeklyScores,
  }) {
    final improving =
        weeklyScores.length >= 2 && weeklyScores.last > weeklyScores.first;
    if (positiveRatio >= 0.6) {
      return '이번 달 당신의 마음은 대체로 따뜻하고 평온한 시간을 보냈어요.';
    }
    if (volatility >= 3) {
      return improving
          ? '이번 달 당신의 마음은 크게 흔들리면서도, 조금씩 다시 안정을 찾아가고 있어요.'
          : '이번 달 당신의 마음은 여러 번 크게 출렁였지만, 그만큼 열심히 하루하루를 버텨왔어요.';
    }
    if (negativeRatio >= 0.6) {
      return improving
          ? '조금 힘든 순간들이 많았지만, 최근엔 마음이 조금씩 가벼워지고 있어요.'
          : '이번 달은 마음이 자주 무거웠던 시간이었어요. 잘 견뎌왔어요.';
    }
    return '이번 달 당신의 마음은 잔잔한 파도처럼, 오르내림 속에서도 균형을 지켜왔어요.';
  }

  static String _buildAnalysis({
    required EmotionType? dominant,
    required Map<EmotionType, double> ratios,
    required List<double> weeklyScores,
    required List<EmotionType?> weeklyDominant,
    required double volatility,
    required double positiveRatio,
    required double negativeRatio,
    required double avgFirst,
    required double avgSecond,
    required Map<EmotionType, int> counts,
    required int total,
  }) {
    final buf = StringBuffer();

    if (dominant != null) {
      final pct = ((ratios[dominant] ?? 0) * 100).round();
      buf.write('이번 달 가장 자주 찾아온 마음은 \'${dominant.label}\'이었어요 (전체의 약 $pct%). ');
    }

    // 주차별 흐름 - 가장 낮은 주와 가장 높은 주 찾기
    if (weeklyScores.isNotEmpty) {
      int lowestWeek = 0;
      double lowestVal = weeklyScores[0];
      int highestWeek = 0;
      double highestVal = weeklyScores[0];
      for (int i = 1; i < weeklyScores.length; i++) {
        if (weeklyScores[i] < lowestVal) {
          lowestVal = weeklyScores[i];
          lowestWeek = i;
        }
        if (weeklyScores[i] > highestVal) {
          highestVal = weeklyScores[i];
          highestWeek = i;
        }
      }
      if (lowestVal < -0.5) {
        final emo = weeklyDominant[lowestWeek];
        if (emo != null && emo.valence == EmotionValence.negative) {
          buf.write(
            '특히 ${lowestWeek + 1}주차에는 \'${emo.label}\'이 자주 마음을 스쳐갔던 것 같아요. ',
          );
        } else {
          buf.write('특히 ${lowestWeek + 1}주차에는 마음이 조금 가라앉는 시간이 있었어요. ');
        }
      }
      if (highestVal > 0.5 && highestWeek != lowestWeek) {
        buf.write('반면 ${highestWeek + 1}주차에는 한결 편안하고 밝은 기운이 느껴졌어요. ');
      }
    }

    // 감정 기복
    if (volatility >= 3) {
      buf.write(
        '전체적으로 감정 기복이 꽤 큰 한 달이었어요. 마음이 크게 오르내렸다는 건, 그만큼 다양한 순간들을 온몸으로 느끼며 지나왔다는 뜻이기도 해요. ',
      );
    } else if (volatility <= 1.2) {
      buf.write('감정의 흐름은 비교적 잔잔하게 이어졌어요. 큰 굴곡 없이 담담하게 하루하루를 보낸 흔적이 느껴져요. ');
    }

    // 상반월 vs 하반월 강도 비교
    if (avgFirst > 0 && avgSecond > 0) {
      final diff = avgSecond - avgFirst;
      if (diff <= -0.6) {
        buf.write(
          '월초보다 월말로 갈수록 감정의 강도가 차분해졌어요. 시간이 지나며 마음이 조금씩 가라앉는 결을 보여주고 있어요. ',
        );
      } else if (diff >= 0.6) {
        buf.write('월초보다 월말로 갈수록 감정이 더 뚜렷하고 강하게 느껴졌던 것 같아요. ');
      }
    }

    // 긍정/부정 비교 마무리
    if (positiveRatio > negativeRatio &&
        positiveRatio - negativeRatio >= 0.15) {
      buf.write('전체적으로 보면 평온하고 감사한 순간들이 힘든 순간보다 조금 더 많았던, 다행스러운 한 달이었어요.');
    } else if (negativeRatio > positiveRatio &&
        negativeRatio - positiveRatio >= 0.15) {
      buf.write(
        '힘든 감정이 조금 더 자주 찾아왔던 달이지만, 그 모든 순간에도 스스로의 마음을 기록하며 돌보려 애써온 당신을 알아주고 싶어요.',
      );
    } else {
      buf.write('밝은 날과 흐린 날이 비슷하게 오가며, 균형 잡힌 흐름을 만들어온 한 달이었어요.');
    }

    return buf.toString();
  }

  static String _buildAdvice({
    required EmotionType? dominant,
    required double volatility,
    required double positiveRatio,
    required double negativeRatio,
    required double avgFirst,
    required double avgSecond,
  }) {
    if (dominant == null) {
      return '오늘의 마음을 한 줄이라도 기록해보는 것부터 시작해볼까요.';
    }

    if (volatility >= 3) {
      return '감정의 파도가 컸던 만큼, 정해진 시간에 짧게라도 쉬어가는 휴식 루틴을 만들어보면 마음을 다잡는 데 도움이 될 수 있어요.';
    }

    switch (dominant) {
      case EmotionType.anxiety:
        return '마음이 자주 흔들렸지만, 그만큼 스스로를 지키려 애써온 노력도 보였어요. 잠들기 전 잠깐의 호흡만으로도 마음이 한결 편안해질 수 있어요.';
      case EmotionType.sadness:
        return '슬픔이 자주 찾아온 달이었어요. 그 감정을 억누르지 않고 그대로 느껴본 것만으로도 충분히 잘하고 있는 거예요. 스스로에게 조금 더 다정해도 괜찮아요.';
      case EmotionType.anger:
        return '마음이 자주 뜨거워졌던 시간들이었어요. 화가 올라올 때는 잠시 멈추고 숨을 고르는 것만으로도 마음의 온도를 낮출 수 있어요.';
      case EmotionType.loneliness:
        return '혼자라는 느낌이 자주 스쳐갔던 달이에요. 작은 연결이라도 스스로를 다시 이어주는 시간을 가져보면 어떨까요.';
      case EmotionType.tired:
        return '몸과 마음이 많이 지쳐있었던 것 같아요. 애쓰지 않고 그냥 쉬어가는 시간을 조금 더 자신에게 허락해줘도 괜찮아요.';
      case EmotionType.calm:
        return '평온한 순간이 조금씩 늘고 있어요. 지금의 이 리듬을 잘 지켜보는 것만으로도 충분해요.';
      case EmotionType.joy:
        return '기분 좋은 순간들이 자주 찾아온 달이었어요. 이 밝은 기운을 기억해두었다가, 흐린 날에도 잠시 꺼내볼 수 있길 바라요.';
      case EmotionType.gratitude:
        return '감사한 마음이 자주 피어난 한 달이었어요. 이런 마음이 쌓일수록, 힘든 순간에도 다시 일어설 힘이 되어줄 거예요.';
    }
  }

  static (List<String>, String) _buildRecommendation({
    required Map<EmotionType, int> counts,
    required int total,
    required EmotionType? dominant,
  }) {
    if (dominant == null) {
      return (
        ['breathing'],
        '아직 마음의 흐름이 뚜렷하지 않을 땐, 가장 편안한 호흡 명상으로 시작해보는 게 좋아요.',
      );
    }

    switch (dominant) {
      case EmotionType.anxiety:
        return (
          ['breathing', 'tensionRelease'],
          '불안이 자주 마음을 스쳐간 만큼, 호흡을 가다듬는 명상과 몸의 긴장을 풀어주는 이완 명상이 마음을 편안하게 해줄 수 있어요.',
        );
      case EmotionType.sadness:
        return (
          ['selfCompassion', 'lovingKindness'],
          '슬픔이 많았던 달에는, 스스로를 다정하게 안아주는 자기연민 명상과 위로가 되는 자애 명상이 마음에 부드러운 온기를 더해줄 수 있어요.',
        );
      case EmotionType.anger:
        return (
          ['angerCooling', 'tensionRelease'],
          '마음이 자주 뜨거웠던 만큼, 감정을 가라앉히는 진정 명상과 몸의 긴장을 이완하는 명상이 도움이 될 수 있어요.',
        );
      case EmotionType.loneliness:
        return (
          ['lovingKindness', 'selfCompassion'],
          '외로움이 자주 찾아왔던 달에는, 나 자신과 주변에 따뜻한 마음을 건네는 자애 명상이 마음의 온기를 채워줄 수 있어요.',
        );
      case EmotionType.tired:
        return (
          ['sleepMeditation', 'deepRestMeditation'],
          '피곤함이 많이 쌓인 달이었던 만큼, 깊이 쉬어가는 수면 명상과 휴식 명상으로 몸과 마음을 충분히 회복해보세요.',
        );
      case EmotionType.calm:
      case EmotionType.gratitude:
      case EmotionType.joy:
        return (
          ['gratitudeExpansion', 'lovingKindness'],
          '평온하고 감사한 마음이 많았던 달이에요. 이 좋은 기운을 더 넓게 확장하는 감사 명상으로 지금의 리듬을 이어가보세요.',
        );
    }
  }
}
