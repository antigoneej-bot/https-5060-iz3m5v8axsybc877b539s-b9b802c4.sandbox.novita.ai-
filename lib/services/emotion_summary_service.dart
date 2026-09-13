import '../models/letter_entry.dart';

/// Counts written records, not emotional intensity. Random cards are excluded.
class EmotionSummaryService {
  static DateTime day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
  static DateTime weekStart(DateTime date) {
    final local = day(date);
    return DateTime(local.year, local.month, local.day - local.weekday + 1);
  }
  static DateTime weekEnd(DateTime date) {
    final start = weekStart(date);
    return DateTime(start.year, start.month, start.day + 6);
  }
  static List<LetterEntry> entries(List<LetterEntry> history, DateTime start, DateTime end) {
    return history.where((entry) {
      final date = day(entry.date);
      return !date.isBefore(day(start)) && !date.isAfter(day(end));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
  static Map<String, int> frequency(List<LetterEntry> entries) {
    final result = <String, int>{};
    for (final entry in entries) {
      result[entry.catId] = (result[entry.catId] ?? 0) + 1;
    }
    return result;
  }
  static List<MapEntry<String, int>> ranked(List<LetterEntry> entries) {
    return frequency(entries).entries.toList()..sort((a, b) {
      final count = b.value.compareTo(a.value);
      return count == 0 ? a.key.compareTo(b.key) : count;
    });
  }
  static int recordedDays(List<LetterEntry> entries) => entries.map((e) => day(e.date)).toSet().length;
}
