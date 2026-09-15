import '../models/seed.dart';
import '../models/garden_decoration.dart';

/// One snapshot keeps stage progression and its reward in the same write.
class MongiGardenData {
  final int stage;
  final int seedTokens;
  final int essence;
  final Map<String, int> seeds;
  final Set<String> owned;
  final Set<String> placed;
  final Set<String> recordDays;
  final Set<String> careDays;
  final Set<String> meditationDays;
  final Map<String, int> storyProgress;

  MongiGardenData({
    this.stage = 1,
    this.seedTokens = 0,
    this.essence = 0,
    Map<String, int> seeds = const {},
    Set<String> owned = const {},
    Set<String> placed = const {},
    Set<String> recordDays = const {},
    Set<String>? careDays,
    Set<String> meditationDays = const {},
    Map<String, int> storyProgress = const {},
  }) : seeds = Map.unmodifiable(seeds),
       owned = Set.unmodifiable(owned),
       placed = Set.unmodifiable(placed),
       recordDays = Set.unmodifiable(recordDays),
       careDays = Set.unmodifiable(careDays ?? recordDays),
       meditationDays = Set.unmodifiable(meditationDays),
       storyProgress = Map.unmodifiable(storyProgress);

  Map<String, dynamic> toJson() => {
    'version': 2,
    'stage': stage,
    'seedTokens': seedTokens,
    'essence': essence,
    'seeds': seeds,
    'owned': owned.toList(),
    'placed': placed.toList(),
    'recordDays': recordDays.toList(),
    'careDays': careDays.toList(),
    'meditationDays': meditationDays.toList(),
    'storyProgress': storyProgress,
  };

  factory MongiGardenData.fromJson(Map<String, dynamic> json) {
    int count(String key, int minimum) {
      final value = json[key];
      if (value is! int || value < minimum) {
        throw const FormatException('잘못된 정원 기록');
      }
      return value;
    }

    if (![1, 2].contains(json['version']) ||
        json['seeds'] is! Map ||
        json['owned'] is! List ||
        json['placed'] is! List) {
      throw const FormatException('지원하지 않는 정원 기록');
    }
    final seeds = <String, int>{};
    for (final entry in (json['seeds'] as Map).entries) {
      if (!SeedType.all.any((s) => s.id == entry.key) ||
          entry.value is! int ||
          (entry.value as int) < 0) {
        throw const FormatException('잘못된 씨앗 기록');
      }
      seeds[entry.key as String] = entry.value as int;
    }
    Set<String> decorations(String key) {
      final result = <String>{};
      for (final value in json[key] as List) {
        if (value is! String ||
            !GardenDecoration.all.any((d) => d.id == value)) {
          throw const FormatException('잘못된 장식 기록');
        }
        result.add(value);
      }
      return result;
    }

    final daysRaw = json['recordDays'] ?? <dynamic>[];
    final progressRaw = json['storyProgress'] ?? <String, dynamic>{};
    if (daysRaw is! List || progressRaw is! Map) {
      throw const FormatException('잘못된 성장 기록');
    }
    final days = <String>{};
    for (final day in daysRaw) {
      if (day is! String || !validDay(day)) {
        throw const FormatException('잘못된 기록 날짜');
      }
      days.add(day);
    }
    final careRaw = json['careDays'] ?? days.toList();
    if (careRaw is! List || careRaw.any((d) => d is! String || !validDay(d))) {
      throw const FormatException('잘못된 돌봄 보상 날짜');
    }
    final care = {...days, ...careRaw.cast<String>()};
    final meditationRaw = json['meditationDays'] ?? <dynamic>[];
    if (meditationRaw is! List ||
        meditationRaw.any((d) => d is! String || !validDay(d)))
      throw const FormatException('잘못된 명상 날짜');
    final progress = <String, int>{};
    for (final entry in progressRaw.entries) {
      if (entry.key is! String ||
          !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(entry.key as String) ||
          entry.value is! int ||
          (entry.value as int) < 0 ||
          (entry.value as int) > 3) {
        throw const FormatException('잘못된 이야기 기록');
      }
      progress[entry.key as String] = entry.value as int;
    }
    final owned = decorations('owned'), placed = decorations('placed');
    if (!owned.containsAll(placed)) throw const FormatException('소유하지 않은 장식');
    return MongiGardenData(
      stage: count('stage', 1),
      seedTokens: count('seedTokens', 0),
      essence: count('essence', 0),
      seeds: seeds,
      owned: owned,
      placed: placed,
      recordDays: days,
      careDays: care,
      meditationDays: meditationRaw.cast<String>().toSet(),
      storyProgress: progress,
    );
  }

  MongiGardenData copy({
    int? stage,
    int? seedTokens,
    int? essence,
    Map<String, int>? seeds,
    Set<String>? owned,
    Set<String>? placed,
    Set<String>? recordDays,
    Set<String>? careDays,
    Set<String>? meditationDays,
    Map<String, int>? storyProgress,
  }) => MongiGardenData(
    stage: stage ?? this.stage,
    seedTokens: seedTokens ?? this.seedTokens,
    essence: essence ?? this.essence,
    seeds: seeds ?? this.seeds,
    owned: owned ?? this.owned,
    placed: placed ?? this.placed,
    recordDays: recordDays ?? this.recordDays,
    careDays: careDays ?? this.careDays,
    meditationDays: meditationDays ?? this.meditationDays,
    storyProgress: storyProgress ?? this.storyProgress,
  );

  int get careLeaves => recordDays.length + meditationDays.length + stage - 1;
  int get careTreeTier => careLeaves == 0
      ? 0
      : careLeaves < 3
      ? 1
      : careLeaves < 7
      ? 2
      : careLeaves < 14
      ? 3
      : 4;

  /// Duplicate or stale completion callbacks cannot issue another reward.
  MongiGardenData clearStage(int completedStage) => completedStage != stage
      ? this
      : copy(
          stage: stage + 1,
          seedTokens: seedTokens + 1,
          essence: essence + 30,
        );

  MongiGardenData plant(String id) {
    if (seedTokens < 1 || !SeedType.all.any((s) => s.id == id)) return this;
    return copy(
      seedTokens: seedTokens - 1,
      seeds: {...seeds, id: (seeds[id] ?? 0) + 1},
    );
  }

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static bool validDay(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) return false;
    final date = DateTime.tryParse(key);
    return date != null && dayKey(date) == key;
  }

  /// Shared daily allowance across all quiet care activities. Persist receipt
  /// and currency together; old record receipts also count as already claimed.
  MongiGardenData claimCareDay(DateTime today) {
    final day = dayKey(today);
    if (careDays.contains(day)) return this;
    return copy(
      seedTokens: seedTokens + 1,
      essence: essence + 20,
      careDays: {...careDays, day},
    );
  }

  MongiGardenData claimRecordDay(DateTime today) {
    final day = dayKey(today);
    // Preserve every claimed date across clock corrections and backup restores.
    // A future date must not block a different, legitimate recording day.
    if (recordDays.contains(day)) return this;
    return claimCareDay(today).copy(recordDays: {...recordDays, day});
  }
}
