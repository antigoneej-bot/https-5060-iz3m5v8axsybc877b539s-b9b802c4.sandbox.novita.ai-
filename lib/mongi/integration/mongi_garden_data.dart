import '../models/seed.dart';
import '../models/plant_care.dart';
import '../models/garden_decoration.dart';

/// One snapshot keeps stage progression and its reward in the same write.
class MongiGardenData {
  final List<Map<String, dynamic>> lifeEvents;
  final int stage;
  final int seedTokens;
  final int essence;
  final Map<String, int> walkStock;
  final Set<String> claimedGiftReceipts;
  final Map<String, int> seeds;
  final Map<String, String> plantedOn;
  final Map<String, String> wateredOn;
  final Map<String, String> fertilizedOn;
  final Map<String, String> sunlightOn;

  /// Three points make one existing growth count. Water retains its old value;
  /// optional fertilizer/sunlight add one point each without losing fractions.
  final Map<String, int> careRemainders;
  final Set<String> owned;
  final Set<String> placed;
  final Set<String> recordDays;
  final Set<String> careDays;
  final Set<String> meditationDays;
  final Map<String, int> storyProgress;

  MongiGardenData({
    this.stage = 1,
    List<Map<String, dynamic>> lifeEvents = const [],
    this.seedTokens = 0,
    this.essence = 0,
    Map<String, int> walkStock = const {},
    Set<String> claimedGiftReceipts = const {},
    Map<String, int> seeds = const {},
    Map<String, String> plantedOn = const {},
    Map<String, String> wateredOn = const {},
    Map<String, String> fertilizedOn = const {},
    Map<String, String> sunlightOn = const {},
    Map<String, int> careRemainders = const {},
    Set<String> owned = const {},
    Set<String> placed = const {},
    Set<String> recordDays = const {},
    Set<String>? careDays,
    Set<String> meditationDays = const {},
    Map<String, int> storyProgress = const {},
  }) : lifeEvents = List.unmodifiable(lifeEvents.map((e) => Map<String, dynamic>.unmodifiable(e))),
       walkStock = Map.unmodifiable(walkStock),
       claimedGiftReceipts = Set.unmodifiable(claimedGiftReceipts),
       seeds = Map.unmodifiable(seeds),
       plantedOn = Map.unmodifiable(plantedOn),
       wateredOn = Map.unmodifiable(wateredOn),
       fertilizedOn = Map.unmodifiable(fertilizedOn),
       sunlightOn = Map.unmodifiable(sunlightOn),
       careRemainders = Map.unmodifiable(careRemainders),
       owned = Set.unmodifiable(owned),
       placed = Set.unmodifiable(placed),
       recordDays = Set.unmodifiable(recordDays),
       careDays = Set.unmodifiable(careDays ?? recordDays),
       meditationDays = Set.unmodifiable(meditationDays),
       storyProgress = Map.unmodifiable(storyProgress);

  Map<String, dynamic> toJson() => {
    'version': 3,
    'lifeEvents': lifeEvents,
    'stage': stage,
    'seedTokens': seedTokens,
    'essence': essence,
    'walkStock': walkStock,
    'claimedGiftReceipts': claimedGiftReceipts.toList(),
    'seeds': seeds,
    'plantedOn': plantedOn,
    'wateredOn': wateredOn,
    'fertilizedOn': fertilizedOn,
    'sunlightOn': sunlightOn,
    'careRemainders': careRemainders,
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

    if (![1, 2, 3].contains(json['version']) ||
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
        if (entry.key is! String ||
            (seeds[entry.key] ?? 0) <= 0 ||
            entry.value is! String ||
            !validDay(entry.value as String)) {
          throw const FormatException('잘못된 식물 돌봄 날짜');
        }
        dates[entry.key as String] = entry.value as String;
      }
      return dates;
    }

    final planted = plantDates('plantedOn'), watered = plantDates('wateredOn');
    final fertilized = plantDates('fertilizedOn');
    final sunlight = plantDates('sunlightOn');
    for (final dates in [watered, fertilized, sunlight]) {
      for (final id in dates.keys) {
        if (planted.containsKey(id) && dates[id]!.compareTo(planted[id]!) < 0) {
          throw const FormatException('심기 전의 식물 돌봄 기록');
        }
      }
    }
    final remainderRaw = json['careRemainders'] ?? <String, dynamic>{};
    if (remainderRaw is! Map) throw const FormatException('잘못된 식물 성장 기록');
    final remainders = <String, int>{};
    for (final entry in remainderRaw.entries) {
      if (entry.key is! String ||
          (seeds[entry.key] ?? 0) <= 0 ||
          entry.value is! int ||
          entry.value < 0 ||
          entry.value > 2 ||
          (seeds[entry.key]! >= 10 && entry.value != 0)) {
        throw const FormatException('잘못된 식물 성장 기록');
      }
      remainders[entry.key as String] = entry.value as int;
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
    if (receipts is! List ||
        receipts.any(
          (id) =>
              id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id),
        )) {
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
    final walk = <String, int>{};
    final rawWalk = json['walkStock'] ?? <String, dynamic>{};
    if (rawWalk is! Map) throw const FormatException('잘못된 산책 보관함');
    for (final entry in rawWalk.entries) {
      if (!['churu_tuna','food_dry'].contains(entry.key) || entry.value is! int || entry.value < 0) {
        throw const FormatException('잘못된 산책 보관함');
      }
      walk[entry.key as String] = entry.value as int;
    }
    final rawEvents = json['lifeEvents'] ?? const [];
    if (rawEvents is! List || rawEvents.length > 1000) throw const FormatException('정원 사건 기록을 확인해 주세요.');
    final events = <Map<String, dynamic>>[];
    for (final e in rawEvents) {
      if (e is! Map || e.length != 4 || !['plant', 'growth'].contains(e['kind']) ||
          !SeedType.all.any((s) => s.id == e['plant']) || e['at'] is! String ||
          (DateTime.tryParse(e['at'] as String) == null || dayKey(DateTime.parse(e['at'] as String)) != e['at']) || e['level'] is! int || e['level'] < 1 || e['level'] > 10) {
        throw const FormatException('정원 사건 기록이 올바르지 않아요.');
      }
      events.add(Map<String, dynamic>.from(e));
    }
    return MongiGardenData(
      lifeEvents: events,
      walkStock: walk,
      stage: count('stage', 1),
      seedTokens: count('seedTokens', 0),
      essence: count('essence', 0),
      claimedGiftReceipts: receipts.cast<String>().toSet(),
      seeds: seeds,
      plantedOn: planted,
      wateredOn: watered,
      fertilizedOn: fertilized,
      sunlightOn: sunlight,
      careRemainders: remainders,
      owned: owned,
      placed: placed,
      recordDays: days,
      careDays: care,
      meditationDays: meditationRaw.cast<String>().toSet(),
      storyProgress: progress,
    );
  }

  MongiGardenData copy({
    List<Map<String, dynamic>>? lifeEvents,
    int? stage,
    int? seedTokens,
    int? essence,
    Map<String, int>? walkStock,
    Set<String>? claimedGiftReceipts,
    Map<String, int>? seeds,
    Map<String, String>? plantedOn,
    Map<String, String>? wateredOn,
    Map<String, String>? fertilizedOn,
    Map<String, String>? sunlightOn,
    Map<String, int>? careRemainders,
    Set<String>? owned,
    Set<String>? placed,
    Set<String>? recordDays,
    Set<String>? careDays,
    Set<String>? meditationDays,
    Map<String, int>? storyProgress,
  }) => MongiGardenData(
    lifeEvents: lifeEvents ?? this.lifeEvents,
    stage: stage ?? this.stage,
    seedTokens: seedTokens ?? this.seedTokens,
    essence: essence ?? this.essence,
    walkStock: walkStock ?? this.walkStock,
    claimedGiftReceipts: claimedGiftReceipts ?? this.claimedGiftReceipts,
    seeds: seeds ?? this.seeds,
    plantedOn: plantedOn ?? this.plantedOn,
    wateredOn: wateredOn ?? this.wateredOn,
    fertilizedOn: fertilizedOn ?? this.fertilizedOn,
    sunlightOn: sunlightOn ?? this.sunlightOn,
    careRemainders: careRemainders ?? this.careRemainders,
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
        amount < 0 ||
        amount > 5) {
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
  List<Map<String, dynamic>> _event(String kind, String id, DateTime date, int level) {
    final next = [...lifeEvents, <String, dynamic>{'kind': kind, 'plant': id, 'at': dayKey(date), 'level': level}];
    return next.length <= 1000 ? next : next.sublist(next.length - 1000);
  }

  MongiGardenData plant(String id, {DateTime? now}) {
    if (seedTokens < 1 ||
        !SeedType.all.any((s) => s.id == id) ||
        (seeds[id] ?? 0) > 0)
      return this;
    return copy(
      lifeEvents: _event('plant', id, now ?? DateTime.now(), 1),
      seedTokens: seedTokens - 1,
      seeds: {...seeds, id: 1},
      plantedOn: {...plantedOn, id: dayKey(now ?? DateTime.now())},
    );
  }

  /// Remove only this planting. Currency and lifetime care receipts are not
  /// refunded or reset; a later planting starts with fresh care dates.
  MongiGardenData removePlant(String id) {
    if (!SeedType.all.any((seed) => seed.id == id)) {
      throw ArgumentError.value(id, 'id');
    }
    return copy(
      seeds: {...seeds}..remove(id),
      plantedOn: {...plantedOn}..remove(id),
      wateredOn: {...wateredOn}..remove(id),
      fertilizedOn: {...fertilizedOn}..remove(id),
      sunlightOn: {...sunlightOn}..remove(id),
      careRemainders: {...careRemainders}..remove(id),
    );
  }

  /// Existing game rewards still grant a seed. If that species is already
  /// planted, keep its reward as an inventory token instead of forced growth.
  MongiGardenData plantReward(String id, {DateTime? now}) {
    if (!SeedType.all.any((s) => s.id == id)) throw ArgumentError.value(id);
    if ((seeds[id] ?? 0) > 0) return copy(seedTokens: seedTokens + 1);
    return copy(
      lifeEvents: _event('plant', id, now ?? DateTime.now(), 1),
      seeds: {...seeds, id: 1},
      plantedOn: {...plantedOn, id: dayKey(now ?? DateTime.now())},
    );
  }

  bool wateredToday(String id, DateTime today) =>
      caredToday(id, PlantCare.water, today);

  Map<String, String> _careDates(PlantCare care) => switch (care) {
    PlantCare.water => wateredOn,
    PlantCare.fertilizer => fertilizedOn,
    PlantCare.sunlight => sunlightOn,
  };

  bool caredToday(String id, PlantCare care, DateTime today) {
    final last = _careDates(care)[id];
    return last != null && last.compareTo(dayKey(today)) >= 0;
  }

  double growthFor(String id) {
    final count = seeds[id] ?? 0;
    if (count <= 0) return 0;
    return (count + (careRemainders[id] ?? 0) / 3).clamp(1.0, 10.0);
  }

  double growthProgress(String id) => ((growthFor(id) - 1) / 9).clamp(0.0, 1.0);

  MongiGardenData waterPlant(String id, DateTime today) =>
      carePlant(id, PlantCare.water, today);

  /// Each type is available once daily. Water alone still matures a seed in
  /// nine care days; all three shorten that to six. No missed-day penalty,
  /// mandatory chores, currency fee, or passive growth. Legacy counts survive.
  MongiGardenData carePlant(String id, PlantCare care, DateTime today) {
    final count = seeds[id] ?? 0;
    if (!SeedType.all.any((s) => s.id == id) || count <= 0) {
      throw StateError('먼저 씨앗을 심어 주세요.');
    }
    final day = dayKey(today);
    if (caredToday(id, care, today) ||
        [
          plantedOn[id],
          wateredOn[id],
          fertilizedOn[id],
          sunlightOn[id],
        ].any((last) => last != null && last.compareTo(day) > 0))
      return this;
    final points = (careRemainders[id] ?? 0) + care.growthPoints;
    final grown = count >= 10 ? count : (count + points ~/ 3).clamp(1, 10);
    return copy(
      lifeEvents: grown > count ? _event('growth', id, today, grown) : lifeEvents,
      seeds: {...seeds, id: grown},
      careRemainders: {...careRemainders, id: grown >= 10 ? 0 : points % 3},
      wateredOn: care == PlantCare.water ? {...wateredOn, id: day} : wateredOn,
      fertilizedOn: care == PlantCare.fertilizer
          ? {...fertilizedOn, id: day}
          : fertilizedOn,
      sunlightOn: care == PlantCare.sunlight
          ? {...sunlightOn, id: day}
          : sunlightOn,
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
