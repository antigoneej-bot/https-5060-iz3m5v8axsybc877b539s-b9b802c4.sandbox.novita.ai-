/// Legacy activity statistics kept for source compatibility.
/// Never interpret care rewards as a person's emotional or clinical state.
library;

enum TempBand { warm, calm, tired, recovering }

enum TempTrend { rising, falling, stable, volatile }

enum TempTier { positive, neutral, negative }

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
  TempTier get dominantTier =>
      positiveDays >= neutralDays && positiveDays >= negativeDays
      ? TempTier.positive
      : negativeDays >= neutralDays
      ? TempTier.negative
      : TempTier.neutral;
}

extension TempTierLabel on TempTier {
  String get label => switch (this) {
    TempTier.positive => '온기 67~100',
    TempTier.neutral => '온기 34~66',
    TempTier.negative => '온기 0~33',
  };
  String get emoji => '🌱';
}

class TemperatureInsight {
  final TempBand band;
  final TempTrend trend;
  final double average;
  final int latest;
  final int highest;
  final int lowest;
  final String stateDescription;
  final String solution;
  final String comfort;
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
  String get bandLabel => '돌봄 활동 기록';
  String get trendLabel => '활동 보상 수치이며 마음 상태의 변화가 아니에요';
  String get emoji => '🌱';
}

class TemperatureInsightService {
  TemperatureInsightService._();
  static TempTier tierFor(int value) => value >= 67
      ? TempTier.positive
      : value >= 34
      ? TempTier.neutral
      : TempTier.negative;
  static TempTierBreakdown tierBreakdown(
    List<MapEntry<DateTime, int>> entries,
  ) => TempTierBreakdown(
    positiveDays: entries
        .where((e) => tierFor(e.value) == TempTier.positive)
        .length,
    neutralDays: entries
        .where((e) => tierFor(e.value) == TempTier.neutral)
        .length,
    negativeDays: entries
        .where((e) => tierFor(e.value) == TempTier.negative)
        .length,
  );
  static TemperatureInsight? analyze(List<MapEntry<DateTime, int>> entries) {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort((a, b) => a.key.compareTo(b.key));
    final values = sorted.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    return TemperatureInsight(
      band: avg >= 75
          ? TempBand.warm
          : avg >= 50
          ? TempBand.calm
          : avg >= 25
          ? TempBand.tired
          : TempBand.recovering,
      // Reward conversion can lower the value, so do not derive a mood trend.
      trend: TempTrend.stable,
      average: avg,
      latest: values.last,
      highest: values.reduce((a, b) => a > b ? a : b),
      lowest: values.reduce((a, b) => a < b ? a : b),
      stateDescription:
          '출석·편지·돌봄으로 쌓인 온기 기록이에요. 심리 상태나 회복 정도를 알 수 있는 점수는 아니에요.',
      solution: '내 마음은 돌아보고 돌보기에서 직접 남길 수 있어요.',
      comfort: '활동을 쉬었다고 내 마음을 낮게 평가하지 않아요.',
      meditation: '원할 때 나에게 맞는 돌봄을 선택하고, 해본 뒤 어땠는지 남겨 보세요.',
    );
  }
}
