import 'package:flutter/material.dart';

import '../data/shadow_cats_data.dart';
import '../models/letter_entry.dart';
import '../mongi/models/emotion.dart';
import '../utils/cat_palette.dart';
import 'emotion_summary_service.dart';

enum EmotionRecordSource { letter, gardenDiary }

/// A read-only view of a saved feeling. This does not migrate or duplicate data.
/// Catalogues stay namespaced: a letter's "분노" is never silently relabelled as
/// the garden catalogue's "화", nor given an invented mood/intensity score.
class UnifiedEmotionRecord {
  final String id;
  final EmotionRecordSource source;
  final DateTime date;
  final bool hasTime;
  final String emotionId;
  final String label;
  final String emoji;
  final Color color;
  final Color background;
  final String note;
  final int? intensity;

  const UnifiedEmotionRecord({
    required this.id,
    required this.source,
    required this.date,
    required this.hasTime,
    required this.emotionId,
    required this.label,
    required this.emoji,
    required this.color,
    required this.background,
    required this.note,
    this.intensity,
  });

  String get categoryKey => '${source.name}:$emotionId';
  String get sourceLabel =>
      source == EmotionRecordSource.letter ? '편지' : '정원 일기';
  String get displayLabel => '$label · $sourceLabel';
}

class UnifiedEmotionFrequency {
  final UnifiedEmotionRecord emotion;
  final int count;
  const UnifiedEmotionFrequency(this.emotion, this.count);
}

class UnifiedEmotionPeriod {
  final List<UnifiedEmotionRecord> records;
  const UnifiedEmotionPeriod(this.records);

  int get recordedDays =>
      records.map((e) => EmotionSummaryService.day(e.date)).toSet().length;
  int get letterCount =>
      records.where((e) => e.source == EmotionRecordSource.letter).length;
  int get gardenCount => records.length - letterCount;
  List<int> get intensities =>
      records.map((e) => e.intensity).whereType<int>().toList(growable: false);
  double? get averageIntensity {
    final values = intensities;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<UnifiedEmotionFrequency> get ranked {
    final counts = <String, int>{};
    final representatives = <String, UnifiedEmotionRecord>{};
    for (final entry in records) {
      counts.update(entry.categoryKey, (value) => value + 1, ifAbsent: () => 1);
      representatives[entry.categoryKey] = entry;
    }
    return counts.entries
        .map((e) => UnifiedEmotionFrequency(representatives[e.key]!, e.value))
        .toList()
      ..sort((a, b) {
        final count = b.count.compareTo(a.count);
        return count != 0
            ? count
            : a.emotion.categoryKey.compareTo(b.emotion.categoryKey);
      });
  }
}

class UnifiedEmotionSummaryService {
  const UnifiedEmotionSummaryService._();

  static List<UnifiedEmotionRecord> read({
    required Iterable<LetterEntry> letters,
    required Iterable<Map<String, dynamic>> gardenDiary,
  }) {
    final result = <UnifiedEmotionRecord>[];
    final letterIds = <String>{};
    var letterIndex = 0;
    for (final letter in letters) {
      // Persisted letter IDs identify an event; equal text/date alone does not.
      final id = letter.id.isEmpty
          ? 'legacy:${letterIndex++}'
          : 'saved:${letter.id}';
      if (!letterIds.add(id)) continue;
      final matches = shadowCats.where((cat) => cat.id == letter.catId);
      final cat = matches.isEmpty ? null : matches.first;
      result.add(
        UnifiedEmotionRecord(
          id: 'letter:$id',
          source: EmotionRecordSource.letter,
          date: letter.date.toLocal(),
          hasTime: true,
          emotionId: letter.catId,
          label: cat?.keyword ?? '이전 감정 (${letter.catId})',
          emoji: cat?.emoji ?? '💭',
          color: CatPalette.accentFor(letter.catId),
          background: CatPalette.backgroundFor(letter.catId),
          note: letter.letterText,
        ),
      );
    }
    final diaryIds = <String>{};
    var index = 0;
    for (final entry in gardenDiary) {
      final position = index++;
      final date = _date(entry['date']);
      if (date == null) continue;
      final rawType = entry['emotionType'];
      if (rawType is! String || rawType.isEmpty) continue;
      final rawId = entry['id'];
      final id = rawId is String && rawId.isNotEmpty ? rawId : null;
      if (id != null && !diaryIds.add(id)) continue;
      // Legacy garden rows contain only a date, no ID/time. Identical rows can
      // be distinct sessions, so retain them rather than guessing identity.
      final matches = Emotion.all.where((e) => e.type.name == rawType);
      final emotion = matches.isEmpty ? null : matches.first;
      final rawIntensity = entry['intensity'];
      final intensity =
          rawIntensity is num &&
              rawIntensity.isFinite &&
              rawIntensity >= 1 &&
              rawIntensity <= 5 &&
              rawIntensity == rawIntensity.roundToDouble()
          ? rawIntensity.toInt()
          : null;
      result.add(
        UnifiedEmotionRecord(
          id: 'garden:${id == null ? 'legacy:$position' : 'saved:$id'}',
          source: EmotionRecordSource.gardenDiary,
          date: date,
          hasTime: (entry['date'] as String).contains('T'),
          emotionId: rawType,
          label: emotion?.label ?? '이전 감정 ($rawType)',
          emoji: emotion?.emoji ?? '💭',
          color: emotion?.color ?? const Color(0xFF6C8073),
          background: (emotion?.color ?? const Color(0xFF6C8073)).withValues(
            alpha: .12,
          ),
          note: entry['note'] is String ? entry['note'] as String : '',
          intensity: intensity,
        ),
      );
    }
    result.sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date != 0 ? date : a.id.compareTo(b.id);
    });
    return List.unmodifiable(result);
  }

  /// Accept stored YYYY-M-D and ISO timestamps without normalizing invalid
  /// calendar dates (e.g. February 31) into a different month.
  static DateTime? _date(Object? raw) {
    if (raw is! String) return null;
    final datePart = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:$|T)',
    ).firstMatch(raw);
    if (datePart == null) return null;
    final year = int.parse(datePart[1]!);
    final month = int.parse(datePart[2]!);
    final day = int.parse(datePart[3]!);
    if (year < 1900 || year > 9999) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return raw.contains('T') ? DateTime.tryParse(raw)?.toLocal() : date;
  }

  static UnifiedEmotionPeriod period(
    Iterable<UnifiedEmotionRecord> entries,
    DateTime start,
    DateTime end,
  ) {
    final first = EmotionSummaryService.day(start);
    final last = EmotionSummaryService.day(end);
    return UnifiedEmotionPeriod(
      List.unmodifiable(
        entries.where((entry) {
          final day = EmotionSummaryService.day(entry.date);
          return !day.isBefore(first) && !day.isAfter(last);
        }),
      ),
    );
  }
}
