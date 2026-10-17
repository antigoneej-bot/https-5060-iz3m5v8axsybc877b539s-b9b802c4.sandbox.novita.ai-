/// Summarizes the existing care reward counter, never a person's mental state.
/// Legacy enum/field names stay compatible; all display labels describe numbers.
library;

import 'dart:math';

/// Activity-counter bands. Names remain for compatibility, not mood inference.
enum TempBand { warm, calm, tired, recovering }

/// 기간 내 온도가 어떤 흐름을 보였는지.
enum TempTrend { rising, falling, stable, volatile }

/// Numeric ranges of the activity counter.
enum TempTier { positive, neutral, negative }

/// Number of recorded days in each numeric range.
class TempTierBreakdown {
  final int positiveDays;
  final int neutralDays;
  final int negativeDays;

  const TempTierBreakdown({
    required this.positiveDays,
    required this.neutralDays,
    required this.negativeDays,
  });

  int get totalDays => positiveDays + neutralDays + negativeDays;

  double get positivePercent =>
      totalDays == 0 ? 0 : positiveDays / totalDays * 100;
  double get neutralPercent =>
      totalDays == 0 ? 0 : neutralDays / totalDays * 100;
  double get negativePercent =>
      totalDays == 0 ? 0 : negativeDays / totalDays * 100;

  /// 3단계 중 가장 많은 비중을 차지한 구간 (요약 문구에 사용).
  TempTier get dominantTier {
    if (positiveDays >= neutralDays && positiveDays >= negativeDays) {
      return TempTier.positive;
    }
    if (negativeDays >= neutralDays && negativeDays >= positiveDays) {
      return TempTier.negative;
    }
    return TempTier.neutral;
  }
}

/// Factual counter summary and explanation shown on the history screen.
class TemperatureInsight {
  final TempBand band;
  final TempTrend trend;
  final double average;
  final int latest;
  final int highest;
  final int lowest;

  /// Counter summary and reward rollover explanation.
  final String stateDescription;

  /// Points to the separate self-reported emotion records.
  final String solution;

  /// Neutral optional care copy, independent of counter values.
  final String comfort;

  /// Optional rest invitation, never a counter-based prescription.
  final String meditation;

  const TemperatureInsight({
    required this.band,
    required this.trend,
    required this.average,
    required this.latest,
    required this.highest,
    required this.lowest,
    required this.stateDescription,
    required this.solution,
    required this.comfort,
    required this.meditation,
  });

  String get bandLabel {
    switch (band) {
      case TempBand.warm:
        return '평균 온기 75~100';
      case TempBand.calm:
        return '평균 온기 50 이상 75 미만';
      case TempBand.tired:
        return '평균 온기 25 이상 50 미만';
      case TempBand.recovering:
        return '평균 온기 0 이상 25 미만';
    }
  }

  String get trendLabel {
    switch (trend) {
      case TempTrend.rising:
        return '기록된 온기 값이 늘었어요';
      case TempTrend.falling:
        return '기록된 온기 값이 낮아졌어요 · 보상 적립 여부를 함께 확인해요';
      case TempTrend.stable:
        return '기록된 온기 값이 비슷해요';
      case TempTrend.volatile:
        return '기록된 온기 값에 차이가 있어요 · 보상 후 다시 쌓일 수 있어요';
    }
  }

  String get emoji {
    switch (band) {
      case TempBand.warm:
        return '🌿';
      case TempBand.calm:
        return '🍃';
      case TempBand.tired:
        return '🌱';
      case TempBand.recovering:
        return '🌱';
    }
  }
}

/// [TempTier]에 대한 한글 표기/설명을 모아둔 확장.
extension TempTierLabel on TempTier {
  String get label {
    switch (this) {
      case TempTier.positive:
        return '67~100';
      case TempTier.neutral:
        return '34~66';
      case TempTier.negative:
        return '0~33';
    }
  }

  String get emoji {
    switch (this) {
      case TempTier.positive:
        return '🌿';
      case TempTier.neutral:
        return '🍃';
      case TempTier.negative:
        return '🌱';
    }
  }
}

class TemperatureInsightService {
  TemperatureInsightService._();

  /// Groups the reward-counter values without assigning emotional meaning.
  static TempTier tierFor(int value) {
    if (value >= 67) return TempTier.positive;
    if (value >= 34) return TempTier.neutral;
    return TempTier.negative;
  }

  /// Counts recorded days in each reward-counter range.
  static TempTierBreakdown tierBreakdown(
    List<MapEntry<DateTime, int>> entries,
  ) {
    var positive = 0;
    var neutral = 0;
    var negative = 0;
    for (final e in entries) {
      switch (tierFor(e.value)) {
        case TempTier.positive:
          positive++;
          break;
        case TempTier.neutral:
          neutral++;
          break;
        case TempTier.negative:
          negative++;
          break;
      }
    }
    return TempTierBreakdown(
      positiveDays: positive,
      neutralDays: neutral,
      negativeDays: negative,
    );
  }

  /// [entries]는 이미 원하는 기간(주간 7일 / 월간 30일)으로 필터링된
  /// (날짜, 온도) 목록이어야 하며, 날짜 오름차순으로 정렬되어 있어야
  /// 합니다(화면에서 이미 그렇게 정렬해 넘겨줍니다).
  static TemperatureInsight? analyze(List<MapEntry<DateTime, int>> entries) {
    if (entries.isEmpty) return null;

    final values = entries.map((e) => e.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final highest = values.reduce(max);
    final lowest = values.reduce(min);
    final latest = values.last;

    final band = _bandFor(average);
    final trend = _trendFor(values);

    return TemperatureInsight(
      band: band,
      trend: trend,
      average: average,
      latest: latest,
      highest: highest,
      lowest: lowest,
      stateDescription: _stateDescription(band, trend, average),
      solution: _solution(band, trend),
      comfort: _comfort(band, trend),
      meditation: _meditation(band, trend),
    );
  }

  static TempBand _bandFor(double average) {
    if (average >= 75) return TempBand.warm;
    if (average >= 50) return TempBand.calm;
    if (average >= 25) return TempBand.tired;
    return TempBand.recovering;
  }

  static TempTrend _trendFor(List<int> values) {
    if (values.length < 2) return TempTrend.stable;

    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / n;
    final stddev = sqrt(variance);

    final splitIndex = (n / 2).floor().clamp(1, n - 1);
    final firstHalf = values.sublist(0, splitIndex);
    final secondHalf = values.sublist(splitIndex);
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    final diff = secondAvg - firstAvg;

    if (stddev >= 20) return TempTrend.volatile;
    if (diff >= 6) return TempTrend.rising;
    if (diff <= -6) return TempTrend.falling;
    return TempTrend.stable;
  }

  static const activityExplanation =
      '돌봄 온기는 출석·편지·돌봄 같은 활동으로 쌓는 값이에요. '
      '감정이나 심리 상태를 측정한 점수가 아니에요. '
      '구독자는 100에 도달하면 포인트를 받고 0부터 다시 쌓아요. '
      '값이 낮아져도 마음이 나빠졌다는 뜻은 아니에요.';

  static String _stateDescription(
    TempBand band,
    TempTrend trend,
    double average,
  ) =>
      '이 기간에 저장된 온기의 평균은 ${average.toStringAsFixed(1)}이에요. $activityExplanation';

  static String _solution(TempBand band, TempTrend trend) =>
      '내 마음을 돌아보고 싶다면 직접 고른 감정과 남긴 편지를 살펴보세요. '
      '감정 통계에서 기록과 주간·월간 회고를 다시 볼 수 있어요.';

  static String _comfort(TempBand band, TempTrend trend) =>
      '온기를 얼마나 모았는지로 마음이나 노력을 평가하지 않아요. '
      '쉬었던 날에도 이전 돌봄이 사라지지 않아요.';

  static String _meditation(TempBand band, TempTrend trend) =>
      '쉬고 싶을 때는 명상이나 호흡을 선택해도 좋아요. '
      '온기 값에 따라 특정 활동이 필요하다고 판단하지 않아요.';
}
