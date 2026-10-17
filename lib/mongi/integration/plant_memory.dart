import 'package:characters/characters.dart';
import '../models/seed.dart';

/// Calendar days are stored without a time zone: a chosen anniversary must not
/// move when a backup is opened in another country.
String plantMemoryDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parsePlantMemoryDay(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('기념일의 날짜가 올바르지 않아요.');
  }
  final date = DateTime.tryParse(value);
  if (date == null ||
      date.year < 1900 ||
      date.year > 2200 ||
      plantMemoryDay(date) != value) {
    throw const FormatException('기념일의 날짜가 올바르지 않아요.');
  }
  return date;
}

class PlantMemoryEntry {
  final String id;
  final String on;
  final String note;
  const PlantMemoryEntry({
    required this.id,
    required this.on,
    required this.note,
  });
  Map<String, dynamic> toJson() => {'id': id, 'on': on, 'note': note};
  factory PlantMemoryEntry.fromJson(Map<dynamic, dynamic> data) {
    final id = data['id'], note = data['note'];
    parsePlantMemoryDay(data['on']);
    if (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
        note is! String ||
        note.trim().isEmpty ||
        note.characters.length > 300) {
      throw const FormatException('식물의 추억 기록이 올바르지 않아요.');
    }
    return PlantMemoryEntry(id: id, on: data['on'] as String, note: note);
  }
}

class PlantMemory {
  static const maxEntries = 60;
  final String plantId;
  final String name;

  /// Kept for old readers; new writes keep this equal to the last entry.
  final String note;
  final DateTime updatedAt;
  final String? anniversaryOn;
  final List<PlantMemoryEntry> entries;
  const PlantMemory({
    required this.plantId,
    required this.name,
    required this.note,
    required this.updatedAt,
    this.anniversaryOn,
    this.entries = const [],
  });

  /// Old one-note records become one dated memory, without inventing a planted
  /// date or an anniversary. Merely reading an old record does not rewrite it.
  List<PlantMemoryEntry> get timeline => entries.isNotEmpty
      ? entries
      : note.trim().isEmpty
      ? const []
      : [
          PlantMemoryEntry(
            id: 'legacy-${updatedAt.microsecondsSinceEpoch}',
            on: plantMemoryDay(updatedAt),
            note: note,
          ),
        ];

  Map<String, dynamic> toJson() => {
    'version': 2,
    'plantId': plantId,
    'name': name,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
    if (anniversaryOn != null) 'anniversaryOn': anniversaryOn,
    'entries': timeline.map((entry) => entry.toJson()).toList(),
  };

  /// The selected date is day 1. Calendar arithmetic avoids DST/time-of-day
  /// causing a 30-day or 100-day card to appear a day early or late.
  int? daysTogether(DateTime now) {
    if (anniversaryOn == null) return null;
    final start = parsePlantMemoryDay(anniversaryOn);
    return DateTime.utc(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
  }

  List<int> milestonesReached(DateTime now) {
    final days = daysTogether(now);
    return days == null ? const [] : [30, 100].where((d) => days >= d).toList();
  }

  String milestoneCaption(int day) =>
      '${name.isEmpty ? SeedType.byId(plantId).label : name} · 함께한 $day일';

  factory PlantMemory.fromJson(Map<dynamic, dynamic> data) {
    final id = data['plantId'], name = data['name'], note = data['note'];
    final date = data['updatedAt'] is String
        ? DateTime.tryParse(data['updatedAt'])
        : null;
    if (id is! String ||
        !SeedType.all.any((s) => s.id == id) ||
        name is! String ||
        name.characters.length > 40 ||
        note is! String ||
        note.characters.length > 300 ||
        date == null ||
        date.year < 1900 ||
        date.year > 2200 ||
        (data['version'] != null && data['version'] != 2)) {
      throw const FormatException('식물의 추억 기록이 올바르지 않아요.');
    }
    final anniversary = data['anniversaryOn'];
    if (anniversary != null) parsePlantMemoryDay(anniversary);
    final rawEntries = data['entries'];
    if (rawEntries != null &&
        (rawEntries is! List || rawEntries.length > maxEntries)) {
      throw const FormatException('추억은 식물마다 60개까지 보관할 수 있어요.');
    }
    final entries = <PlantMemoryEntry>[];
    for (final raw in (rawEntries as List? ?? const [])) {
      if (raw is! Map) throw const FormatException('추억 기록이 올바르지 않아요.');
      final entry = PlantMemoryEntry.fromJson(raw);
      if (entries.any((saved) => saved.id == entry.id)) {
        throw const FormatException('추억 기록이 중복되어 있어요.');
      }
      entries.add(entry);
    }
    if (data['version'] == 2 &&
        ((entries.isEmpty && note.isNotEmpty) ||
            (entries.isNotEmpty && entries.last.note != note))) {
      throw const FormatException('추억 내용이 일치하지 않아요.');
    }
    return PlantMemory(
      plantId: id,
      name: name,
      note: note,
      updatedAt: date,
      anniversaryOn: anniversary as String?,
      entries: List.unmodifiable(entries),
    );
  }
}
