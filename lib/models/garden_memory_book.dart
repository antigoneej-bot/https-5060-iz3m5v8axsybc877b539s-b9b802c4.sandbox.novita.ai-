import '../l10n/app_language.dart';
import 'dart:convert';

import '../mongi/models/garden_decoration.dart';
import '../mongi/models/garden_layout.dart';
import '../mongi/models/seed.dart';

String gardenBookMonth(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}';
}

DateTime parseGardenBookMonth(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(value)) {
    throw FormatException(tr("기록집의 달을 확인해 주세요."));
  }
  final date = DateTime.parse('$value-01');
  if (date.year < 1900 || date.year > 2200) {
    throw FormatException(tr("기록집의 달을 확인해 주세요."));
  }
  return date;
}

DateTime _date(Object? value) {
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null || date.year < 1900 || date.year > 2200) {
    throw FormatException(tr("기록집의 날짜가 올바르지 않아요."));
  }
  return date;
}

String _bookDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _readBookDay(Object? raw, DateTime legacyDate) {
  // v24 used the timestamp's stored calendar fields. Preserve those days when
  // migrating; new books explicitly store their chosen local calendar day.
  final value = raw ?? _bookDay(legacyDate);
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      _bookDay(_date(value)) != value) {
    throw FormatException(tr("기록집의 기억 날짜를 확인해 주세요."));
  }
  return value;
}

String _text(Object? value, int max, {bool empty = false}) {
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty)) {
    throw FormatException(tr("기록집의 내용이 올바르지 않아요."));
  }
  return value;
}

void _keys(Map data, Set<String> allowed) {
  if (data.keys.any((key) => key is! String || !allowed.contains(key))) {
    throw FormatException(tr("알 수 없는 기록집 항목이 있어요."));
  }
}

List<T> _rows<T>(Object? raw, int max, T Function(Map) read) {
  if (raw is! List || raw.length > max || raw.any((row) => row is! Map)) {
    throw FormatException(tr("기록집의 목록을 확인해 주세요."));
  }
  return List.unmodifiable(raw.map((row) => read(row as Map)));
}

/// Only a sentence explicitly selected by its author is copied into a book.
class GardenBookQuote {
  final String letterId, text;
  final DateTime writtenAt;
  final String? calendarDay;
  DateTime get calendarDate =>
      DateTime.parse(calendarDay ?? _bookDay(writtenAt.toLocal()));
  const GardenBookQuote({
    required this.letterId,
    required this.text,
    required this.writtenAt,
    this.calendarDay,
  });
  Map<String, dynamic> toJson() => {
    'letterId': letterId,
    'text': text,
    'writtenAt': writtenAt.toIso8601String(),
    'calendarDay': _bookDay(calendarDate),
  };
  factory GardenBookQuote.fromJson(Map data) {
    _keys(data, {'letterId', 'text', 'writtenAt', 'calendarDay'});
    return GardenBookQuote(
      letterId: _text(data['letterId'], 160),
      text: _text(data['text'], 500),
      writtenAt: _date(data['writtenAt']),
      calendarDay: _readBookDay(data['calendarDay'], _date(data['writtenAt'])),
    );
  }
}

/// A selected plant label/anniversary. Its private diary is never copied.
class GardenBookPlant {
  final String plantId, name;
  final String? anniversaryOn;
  const GardenBookPlant({
    required this.plantId,
    required this.name,
    this.anniversaryOn,
  });
  Map<String, dynamic> toJson() => {
    'plantId': plantId,
    'name': name,
    if (anniversaryOn != null) 'anniversaryOn': anniversaryOn,
  };
  factory GardenBookPlant.fromJson(Map data) {
    _keys(data, {'plantId', 'name', 'anniversaryOn'});
    final id = _text(data['plantId'], 60);
    if (!SeedType.all.any((seed) => seed.id == id)) {
      throw FormatException(tr("기록집의 식물을 확인해 주세요."));
    }
    final anniversary = data['anniversaryOn'];
    if (anniversary != null) {
      if (anniversary is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(anniversary)) {
        throw FormatException(tr("기념일을 확인해 주세요."));
      }
      final date = _date(anniversary);
      if (date.toIso8601String().substring(0, 10) != anniversary) {
        throw FormatException(tr("기념일을 확인해 주세요."));
      }
    }
    return GardenBookPlant(
      plantId: id,
      name: _text(data['name'], 120),
      anniversaryOn: anniversary as String?,
    );
  }
}

/// This records the author's own helpfulness rating, never inferred efficacy.
class GardenBookCare {
  final String entryId, actionLabel;
  final String? sourceLetterId;
  final DateTime completedAt;
  final String? calendarDay;
  DateTime get calendarDate =>
      DateTime.parse(calendarDay ?? _bookDay(completedAt.toLocal()));
  const GardenBookCare({
    required this.entryId,
    required this.actionLabel,
    required this.completedAt,
    this.sourceLetterId,
    this.calendarDay,
  });
  Map<String, dynamic> toJson() => {
    'entryId': entryId,
    'actionLabel': actionLabel,
    'completedAt': completedAt.toIso8601String(),
    'calendarDay': _bookDay(calendarDate),
    if (sourceLetterId != null) 'sourceLetterId': sourceLetterId,
  };
  factory GardenBookCare.fromJson(Map data) {
    _keys(data, {
      'entryId',
      'actionLabel',
      'completedAt',
      'sourceLetterId',
      'calendarDay',
    });
    return GardenBookCare(
      entryId: _text(data['entryId'], 160),
      actionLabel: _text(data['actionLabel'], 500),
      completedAt: _date(data['completedAt']),
      calendarDay: _readBookDay(
        data['calendarDay'],
        _date(data['completedAt']),
      ),
      sourceLetterId: data['sourceLetterId'] == null
          ? null
          : _text(data['sourceLetterId'], 160),
    );
  }
}

class GardenBookReflection {
  final DateTime at;
  final String text;
  const GardenBookReflection({required this.at, required this.text});
  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'text': text};
  factory GardenBookReflection.fromJson(Map data) {
    _keys(data, {'at', 'text'});
    return GardenBookReflection(
      at: _date(data['at']),
      text: _text(data['text'], 500),
    );
  }
}

/// A dated configuration snapshot, not a fabricated photograph of an old month.
/// No journal text, account identifier, inventory currency or purchase data.
class GardenBookSnapshot {
  final DateTime capturedAt;
  final Map<String, int> seeds;
  final List<String> decorations;
  final GardenLayout layout;
  final int memoryDays;
  final String companionName;
  GardenBookSnapshot({
    required this.capturedAt,
    required Map<String, int> seeds,
    required List<String> decorations,
    required this.layout,
    required this.memoryDays,
    required this.companionName,
  }) : seeds = Map.unmodifiable(seeds),
       decorations = List.unmodifiable(decorations);
  Map<String, dynamic> toJson() => {
    'capturedAt': capturedAt.toIso8601String(),
    'seeds': seeds,
    'decorations': decorations,
    'layout': layout.toJson(),
    'memoryDays': memoryDays,
    'companionName': companionName,
  };
  factory GardenBookSnapshot.fromJson(Map data) {
    _keys(data, {
      'capturedAt',
      'seeds',
      'decorations',
      'layout',
      'memoryDays',
      'companionName',
    });
    final seeds = data['seeds'], decorations = data['decorations'];
    if (seeds is! Map ||
        seeds.length > SeedType.all.length ||
        seeds.entries.any(
          (e) =>
              !SeedType.all.any((s) => s.id == e.key) ||
              e.value is! int ||
              e.value < 0 ||
              e.value > 1000000,
        ) ||
        decorations is! List ||
        decorations.length > GardenDecoration.all.length ||
        decorations.any(
          (d) => !GardenDecoration.all.any((item) => item.id == d),
        ) ||
        decorations.toSet().length != decorations.length ||
        data['layout'] is! Map ||
        data['memoryDays'] is! int ||
        data['memoryDays'] < 0 ||
        data['memoryDays'] > 1000000) {
      throw FormatException(tr("정원 구성 기록이 올바르지 않아요."));
    }
    _keys(data['layout'] as Map, {'version', 'spaces', 'positions'});
    return GardenBookSnapshot(
      capturedAt: _date(data['capturedAt']),
      seeds: Map<String, int>.from(seeds),
      decorations: decorations.cast<String>(),
      layout: GardenLayout.fromJson(data['layout'] as Map),
      memoryDays: data['memoryDays'] as int,
      companionName: _text(data['companionName'], 120),
    );
  }
}

class GardenMemoryBook {
  final String month, style;
  final DateTime createdAt, updatedAt;
  final GardenBookSnapshot snapshot;
  final List<GardenBookQuote> quotes;
  final List<GardenBookPlant> plants;
  final List<GardenBookCare> care;
  final List<GardenBookReflection> reflections;
  String get id => 'book-$month';
  GardenMemoryBook({
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    required this.snapshot,
    this.style = 'basic',
    List<GardenBookQuote> quotes = const [],
    List<GardenBookPlant> plants = const [],
    List<GardenBookCare> care = const [],
    List<GardenBookReflection> reflections = const [],
  }) : quotes = List.unmodifiable(quotes),
       plants = List.unmodifiable(plants),
       care = List.unmodifiable(care),
       reflections = List.unmodifiable(reflections);

  GardenMemoryBook copy({
    DateTime? updatedAt,
    String? style,
    List<GardenBookQuote>? quotes,
    List<GardenBookPlant>? plants,
    List<GardenBookCare>? care,
    List<GardenBookReflection>? reflections,
  }) => GardenMemoryBook(
    month: month,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    snapshot: snapshot,
    style: style ?? this.style,
    quotes: quotes ?? this.quotes,
    plants: plants ?? this.plants,
    care: care ?? this.care,
    reflections: reflections ?? this.reflections,
  );

  GardenMemoryBook withoutLetter(String letterId, {DateTime? now}) => copy(
    updatedAt: now ?? updatedAt,
    quotes: quotes.where((quote) => quote.letterId != letterId).toList(),
    care: care.where((entry) => entry.sourceLetterId != letterId).toList(),
  );

  /// Sharing is an explicit projection. No private category or source ID is
  /// included unless the owner checks that category in the share dialog.
  String shareText({
    bool includeQuotes = false,
    bool includePlants = false,
    bool includeCare = false,
    bool includeReflections = false,
  }) => [
    tr("마음냥 정원 · {0}의 기록집", [month]),
    if (includeQuotes)
      ...quotes.map(
        (quote) => tr("{0}월 {1}일 · {2}", [
          quote.calendarDate.month,
          quote.calendarDate.day,
          quote.text,
        ]),
      ),
    if (includePlants)
      ...plants.map(
        (plant) =>
            '${plant.name}${plant.anniversaryOn == null ? '' : tr(" · 기념일 {0}", [plant.anniversaryOn])}',
      ),
    if (includeCare)
      ...care.map((entry) => tr("내가 도움이 됐다고 남긴 경험 · {0}", [entry.actionLabel])),
    if (includeReflections)
      ...reflections.map(
        (entry) =>
            '${entry.at.toIso8601String().substring(0, 10)} · ${entry.text}',
      ),
  ].join('\n\n');

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'month': month,
    'style': style,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'snapshot': snapshot.toJson(),
    'quotes': quotes.map((x) => x.toJson()).toList(),
    'plants': plants.map((x) => x.toJson()).toList(),
    'care': care.map((x) => x.toJson()).toList(),
    'reflections': reflections.map((x) => x.toJson()).toList(),
  };

  factory GardenMemoryBook.fromJson(Map data) {
    _keys(data, {
      'version',
      'id',
      'month',
      'style',
      'createdAt',
      'updatedAt',
      'snapshot',
      'quotes',
      'plants',
      'care',
      'reflections',
    });
    final month = data['month'];
    parseGardenBookMonth(month);
    if (data['version'] != 1 ||
        data['id'] != 'book-$month' ||
        !{'basic', 'seasonal'}.contains(data['style']) ||
        data['snapshot'] is! Map ||
        jsonEncode(data).length > 100000) {
      throw FormatException(tr("기록집의 형식을 확인해 주세요."));
    }
    final created = _date(data['createdAt']),
        updated = _date(data['updatedAt']);
    final snapshot = GardenBookSnapshot.fromJson(data['snapshot'] as Map);
    final quotes = _rows(data['quotes'], 3, GardenBookQuote.fromJson);
    final plants = _rows(data['plants'], 6, GardenBookPlant.fromJson);
    final care = _rows(data['care'], 12, GardenBookCare.fromJson);
    final reflections = _rows(
      data['reflections'],
      60,
      GardenBookReflection.fromJson,
    );
    if (updated.isBefore(created) ||
        snapshot.capturedAt.isAfter(created) ||
        quotes.any(
          (q) =>
              gardenBookMonth(q.calendarDate) != month ||
              q.writtenAt.isAfter(updated),
        ) ||
        care.any(
          (c) =>
              gardenBookMonth(c.calendarDate) != month ||
              c.completedAt.isAfter(updated),
        ) ||
        quotes.map((q) => q.letterId).toSet().length != quotes.length ||
        plants.map((p) => p.plantId).toSet().length != plants.length ||
        care.map((c) => c.entryId).toSet().length != care.length ||
        reflections.any(
          (r) => r.at.isBefore(created) || r.at.isAfter(updated),
        )) {
      throw FormatException(tr("선택한 달과 기록 날짜를 확인해 주세요."));
    }
    return GardenMemoryBook(
      month: month as String,
      createdAt: created,
      updatedAt: updated,
      style: data['style'] as String,
      snapshot: snapshot,
      quotes: quotes,
      plants: plants,
      care: care,
      reflections: reflections,
    );
  }
}
