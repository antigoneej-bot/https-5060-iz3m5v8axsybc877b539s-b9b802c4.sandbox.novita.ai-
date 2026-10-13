import '../models/seed.dart';
import '../models/garden_decoration.dart';

/// One snapshot keeps stage progression and its reward in the same write.
class MongiGardenData {
  final int stage;
  final int seedTokens;
  final int essence;
  final Set<String> claimedGiftReceipts;
  final Map<String, int> seeds;
  final Map<String, String> plantedOn;
  final Map<String, String> wateredOn;
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
    Set<String> claimedGiftReceipts = const {},
    Map<String, int> seeds = const {},
    Map<String, String> plantedOn = const {},
    Map<String, String> wateredOn = const {},
    Set<String> owned = const {},
    Set<String> placed = const {},
    Set<String> recordDays = const {},
    Set<String>? careDays,
    Set<String> meditationDays = const {},
    Map<String, int> storyProgress = const {},
  }) : claimedGiftReceipts = Set.unmodifiable(claimedGiftReceipts),
       seeds = Map.unmodifiable(seeds),
       plantedOn = Map.unmodifiable(plantedOn),
       wateredOn = Map.unmodifiable(wateredOn),
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
    'claimedGiftReceipts': claimedGiftReceipts.toList(),
    'seeds': seeds,
    'plantedOn': plantedOn,
    'wateredOn': wateredOn,
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
    Map<String, String> plantDates(String key) {
      final raw = json[key] ?? <String, dynamic>{};
      if (raw is! Map) throw const FormatException('잘못된 식물 돌봄 날짜');
      final dates = <String, String>{};
      for (final entry in raw.entries) {
        if (entry.key is! String || (seeds[entry.key] ?? 0) <= 0 ||
            entry.value is! String || !validDay(entry.value as String)) {
          throw const FormatException('잘못된 식물 돌봄 날짜');
        }
        dates[entry.key as String] = entry.value as String;
      }
      return dates;
    }
    final planted = plantDates('plantedOn'), watered = plantDates('wateredOn');
    for (final id in watered.keys) {
      if (planted.containsKey(id) && watered[id]!.compareTo(planted[id]!) < 0) {
        throw const FormatException('심기 전의 물주기 기록');
      }
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

    final receipts = json['claimedGiftReceipts'] ?? <dynamic>[];
    if (receipts is! List || receipts.any((id) =>
        id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id))) {
      throw const FormatException('잘못된 선물 수령 기록');
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
      claimedGiftReceipts: receipts.cast<String>().toSet(),
      seeds: seeds,
      plantedOn: planted,
      wateredOn: watered,
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
    Set<String>? claimedGiftReceipts,
    Map<String, int>? seeds,
    Map<String, String>? plantedOn,
    Map<String, String>? wateredOn,
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
    claimedGiftReceipts: claimedGiftReceipts ?? this.claimedGiftReceipts,
    seeds: seeds ?? this.seeds,
    plantedOn: plantedOn ?? this.plantedOn,
    wateredOn: wateredOn ?? this.wateredOn,
    owned: owned ?? this.owned,
    placed: placed ?? this.placed,
    recordDays: recordDays ?? this.recordDays,
    careDays: careDays ?? this.careDays,
    meditationDays: meditationDays ?? this.meditationDays,
    storyProgress: storyProgress ?? this.storyProgress,
  );

  /// Currency and its receipt travel together through writes and backups.
  MongiGardenData receiveGift(String receipt, int amount) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(receipt) ||
        amount < 0 || amount > 5) {
      throw const FormatException('잘못된 선물 수령 기록');
    }
    if (claimedGiftReceipts.contains(receipt)) return this;
    return copy(
      essence: essence + amount,
      claimedGiftReceipts: {...claimedGiftReceipts, receipt},
    );
  }

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

  /// A seed starts one plant; replanting never consumes a second token.
  MongiGardenData plant(String id, {DateTime? now}) {
    if (seedTokens < 1 || !SeedType.all.any((s) => s.id == id) ||
        (seeds[id] ?? 0) > 0) return this;
    return copy(
      seedTokens: seedTokens - 1,
      seeds: {...seeds, id: 1},
      plantedOn: {...plantedOn, id: dayKey(now ?? DateTime.now())},
    );
  }

  /// Existing game rewards still grant a seed. If that species is already
  /// planted, keep its reward as an inventory token instead of forced growth.
  MongiGardenData plantReward(String id, {DateTime? now}) {
    if (!SeedType.all.any((s) => s.id == id)) throw ArgumentError.value(id);
    if ((seeds[id] ?? 0) > 0) return copy(seedTokens: seedTokens + 1);
    return copy(
      seeds: {...seeds, id: 1},
      plantedOn: {...plantedOn, id: dayKey(now ?? DateTime.now())},
    );
  }

  bool wateredToday(String id, DateTime today) =>
      wateredOn[id] != null && wateredOn[id]!.compareTo(dayKey(today)) >= 0;

  /// One saved care action per plant/day. No missed-day penalty, currency fee,
  /// or passive growth. Old growth counts remain exactly as they were.
  MongiGardenData waterPlant(String id, DateTime today) {
    final count = seeds[id] ?? 0;
    if (!SeedType.all.any((s) => s.id == id) || count <= 0) {
      throw StateError('먼저 씨앗을 심어 주세요.');
    }
    final day = dayKey(today);
    if (wateredToday(id, today) ||
        (plantedOn[id] != null && plantedOn[id]!.compareTo(day) > 0)) return this;
    return copy(
      seeds: {...seeds, id: count >= 10 ? count : count + 1},
      wateredOn: {...wateredOn, id: day},
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

  MongiGardenData reconcileRecordDays(Iterable<DateTime> dates) {
    var next = this;
    for (final date in dates) {
      next = next.claimRecordDay(date);
    }
    return next;
  }

  MongiGardenData claimRecordDay(DateTime today) {
    final day = dayKey(today);
    // Preserve every claimed date across clock corrections and backup restores.
    // A future date must not block a different, legitimate recording day.
    if (recordDays.contains(day)) return this;
    return claimCareDay(today).copy(recordDays: {...recordDays, day});
  }
}
