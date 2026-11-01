import 'dart:convert';
import 'companion_coat.dart';

/// Only activity dates and action names are stored; never letter text or mood.
enum CompanionMoment {
  feed,
  play,
  pet,
  brush,
  rest,
  care,
  letter,
  meditation,
  plant,
  water,
  garden,
}

String companionDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class CompanionJourney {
  static const thresholds = [0, 7, 30, 90];
  final int previousCareDays;
  final List<String> careDays;
  final Map<CompanionMoment, String> firstMoments;
  final String? today;
  final Set<CompanionMoment> todayMoments;
  final CompanionCoat? coat;
  final bool keepBaby;

  /// Each resident owns its growth; the original total remains the garden history.
  final Map<CompanionCoat, int> family;
  final Map<CompanionCoat, String> familyLastDays;
  Map<CompanionCoat, int> get residents =>
      family.isEmpty ? {coat ?? CompanionCoat.ginger: growthDays} : family;
  int get activeGrowthDays => residents[coat ?? CompanionCoat.ginger] ?? 0;
  bool get canAdopt =>
      residents.length < 6 && residents.values.every((days) => days >= 90);
  CompanionJourney adopt(CompanionCoat value) {
    if (!canAdopt || residents.containsKey(value)) {
      throw StateError('함께하는 아이들이 다 자라면 새 아기를 데려올 수 있어요.');
    }
    return _withFamily(
      value,
      {...residents, value: 0},
      familyLastDays,
      baby: false,
    );
  }

  CompanionJourney _withFamily(
    CompanionCoat value,
    Map<CompanionCoat, int> members,
    Map<CompanionCoat, String> lastDays, {
    bool? baby,
  }) => CompanionJourney(
    previousCareDays: previousCareDays,
    careDays: careDays,
    firstMoments: firstMoments,
    today: today,
    todayMoments: todayMoments,
    coat: value,
    keepBaby: baby ?? keepBaby,
    automaticBehavior: automaticBehavior,
    family: Map.unmodifiable(members),
    familyLastDays: Map.unmodifiable({
      ...lastDays,
      if (family.isEmpty &&
          today != null &&
          members.containsKey(coat ?? CompanionCoat.ginger))
        coat ?? CompanionCoat.ginger: today!,
    }),
  );
  final bool automaticBehavior;

  const CompanionJourney({
    this.family = const {},
    this.familyLastDays = const {},
    this.previousCareDays = 0,
    this.careDays = const [],
    this.firstMoments = const {},
    this.today,
    this.todayMoments = const {},
    this.coat,
    this.keepBaby = false,
    this.automaticBehavior = true,
  });

  int get growthDays => previousCareDays + careDays.length;
  Map<int, String> get milestones => {
    for (final count in [7, 30, 90, 100])
      if (count > previousCareDays && count <= growthDays)
        count: careDays[count - previousCareDays - 1],
  };
  int get stage => activeGrowthDays >= 90
      ? 3
      : activeGrowthDays >= 30
      ? 2
      : activeGrowthDays >= 7
      ? 1
      : 0;
  String get stageLabel =>
      const ['아기 고양이', '자라는 고양이', '든든한 고양이', '다 자란 고양이'][stage];
  String get bondLabel =>
      const ['서로 알아가는 중', '손길이 익숙해졌어요', '함께 쉬는 사이', '쌓인 시간이 있어요'][stage];
  int? get daysToNext =>
      stage == 3 ? null : thresholds[stage + 1] - activeGrowthDays;
  double get progress => stage == 3
      ? 1
      : (activeGrowthDays - thresholds[stage]) /
            (thresholds[stage + 1] - thresholds[stage]);

  // Scale the whole cat and its contact shadow together, never separate limbs.
  // The largest stage stays at the existing garden size.
  double get visualScale => keepBaby ? .82 : const [.82, .88, .94, 1.0][stage];

  bool didToday(CompanionMoment action, DateTime now) =>
      today == companionDay(now) && todayMoments.contains(action);

  CompanionJourney withCoat(CompanionCoat value) {
    final current = coat ?? CompanionCoat.ginger;
    if (residents.containsKey(value))
      return _withFamily(value, residents, {
        ...familyLastDays,
        if (family.isEmpty && today != null) current: today!,
      });
    // All six appearances remain free. Changing fur never creates/deletes a resident.
    final members = {...residents};
    final days = members.remove(current)!;
    final last = {
      ...familyLastDays,
      if (family.isEmpty && today != null) current: today!,
    };
    final date = last.remove(current);
    members[value] = days;
    if (date != null) last[value] = date;
    return _withFamily(value, members, last);
  }

  CompanionJourney withBaby(bool value) => CompanionJourney(
    family: family,
    familyLastDays: familyLastDays,
    previousCareDays: previousCareDays,
    careDays: careDays,
    firstMoments: firstMoments,
    today: today,
    todayMoments: todayMoments,
    coat: coat,
    keepBaby: value,
    automaticBehavior: automaticBehavior,
  );

  CompanionJourney withAutomaticBehavior(bool value) => CompanionJourney(
    family: family,
    familyLastDays: familyLastDays,
    previousCareDays: previousCareDays,
    careDays: careDays,
    firstMoments: firstMoments,
    today: today,
    todayMoments: todayMoments,
    coat: coat,
    keepBaby: keepBaby,
    automaticBehavior: value,
  );

  CompanionJourney record(CompanionMoment action, DateTime now) {
    final day = companionDay(now);
    final days = {...careDays, day}.toList()..sort();
    final active = coat ?? CompanionCoat.ginger;
    final members = {...residents};
    final last = {...familyLastDays};
    // One growth day per resident, even when switching or restoring the app.
    final already =
        (last[active] != null && last[active]!.compareTo(day) >= 0) ||
        (family.isEmpty && careDays.contains(day));
    if (!already) members[active] = members[active]! + 1;
    if (last[active] == null || last[active]!.compareTo(day) < 0) {
      last[active] = day;
    }
    return CompanionJourney(
      family: Map.unmodifiable(members),
      familyLastDays: Map.unmodifiable(last),
      previousCareDays: previousCareDays,
      careDays: List.unmodifiable(days),
      firstMoments: Map.unmodifiable({
        ...firstMoments,
        action: firstMoments[action] ?? day,
      }),
      today: day,
      todayMoments: Set.unmodifiable({
        if (today == day) ...todayMoments,
        action,
      }),
      coat: coat,
      keepBaby: keepBaby,
      automaticBehavior: automaticBehavior,
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'family': family.map((k, v) => MapEntry(k.name, v)),
    'familyLastDays': familyLastDays.map((k, v) => MapEntry(k.name, v)),
    'previousCareDays': previousCareDays,
    'careDays': careDays,
    'firstMoments': firstMoments.map((key, value) => MapEntry(key.name, value)),
    'today': today,
    'todayMoments': todayMoments.map((a) => a.name).toList(),
    'coat': coat?.name,
    'keepBaby': keepBaby,
    'automaticBehavior': automaticBehavior,
  });

  static bool _day(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    return parsed != null && companionDay(parsed) == value;
  }

  static CompanionJourney decode(String source) {
    final raw = jsonDecode(source);
    final names = CompanionMoment.values.map((a) => a.name).toSet();
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['previousCareDays'] is! int ||
        raw['previousCareDays'] < 0 ||
        raw['previousCareDays'] > 100000 ||
        raw['keepBaby'] is! bool ||
        (raw.containsKey('automaticBehavior') &&
            raw['automaticBehavior'] is! bool) ||
        raw['careDays'] is! List ||
        (raw['careDays'] as List).length > 36600 ||
        !(raw['careDays'] as List).every(_day) ||
        raw['firstMoments'] is! Map ||
        !(raw['firstMoments'] as Map).entries.every(
          (e) => names.contains(e.key) && _day(e.value),
        ) ||
        (raw['today'] != null && !_day(raw['today'])) ||
        raw['todayMoments'] is! List ||
        !(raw['todayMoments'] as List).every(names.contains)) {
      throw const FormatException('고양이와 함께한 기록을 읽을 수 없어요.');
    }
    final days = (raw['careDays'] as List).cast<String>();
    if (days.toSet().length != days.length ||
        (raw['today'] != null && !days.contains(raw['today'])) ||
        (raw['today'] == null && (raw['todayMoments'] as List).isNotEmpty) ||
        !(raw['firstMoments'] as Map).values.every(days.contains)) {
      throw const FormatException('고양이 돌봄 날짜가 일치하지 않아요.');
    }
    final members = <CompanionCoat, int>{};
    final last = <CompanionCoat, String>{};
    final familyRaw = raw['family'] ?? {};
    final lastRaw = raw['familyLastDays'] ?? {};
    if (familyRaw is! Map || lastRaw is! Map)
      throw const FormatException('고양이 가족 기록 오류');
    for (final e in familyRaw.entries) {
      final c = CompanionCoat.parse(e.key);
      if (c == null || e.value is! int || e.value < 0 || e.value > 136600) {
        throw const FormatException('고양이 성장 기록 오류');
      }
      members[c] = e.value as int;
    }
    for (final e in lastRaw.entries) {
      final c = CompanionCoat.parse(e.key);
      if (c == null || !members.containsKey(c) || !_day(e.value))
        throw const FormatException('고양이 돌봄 날짜 오류');
      last[c] = e.value as String;
    }
    if (members.isNotEmpty &&
        !members.containsKey(
          CompanionCoat.parse(raw['coat']) ?? CompanionCoat.ginger,
        )) {
      throw const FormatException('함께할 고양이 기록 오류');
    }
    return CompanionJourney(
      family: Map.unmodifiable(members),
      familyLastDays: Map.unmodifiable(last),
      previousCareDays: raw['previousCareDays'],
      careDays: List.unmodifiable(days),
      firstMoments: Map.unmodifiable(
        (raw['firstMoments'] as Map).map(
          (key, value) => MapEntry(
            CompanionMoment.values.byName(key as String),
            value as String,
          ),
        ),
      ),
      today: raw['today'],
      todayMoments: Set.unmodifiable(
        (raw['todayMoments'] as List).map(
          (a) => CompanionMoment.values.byName(a as String),
        ),
      ),
      coat: CompanionCoat.parse(raw['coat']),
      keepBaby: raw['keepBaby'],
      automaticBehavior: raw['automaticBehavior'] ?? true,
    );
  }
}
