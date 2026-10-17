import '../data/meditation_media_data.dart';

/// A summary of the user's optional answers, never a mood score or a claim
/// that a meditation caused a change. The window is today and six prior local
/// calendar days; skipped answers and future/invalid records are not inferred.
class MeditationRecap {
  final DateTime from;
  final DateTime through;
  final int better;
  final int same;
  final int worse;
  final int recordedDays;
  final String? preferredGuide;
  final bool suggestPause;

  const MeditationRecap({
    required this.from,
    required this.through,
    required this.better,
    required this.same,
    required this.worse,
    required this.recordedDays,
    required this.preferredGuide,
    required this.suggestPause,
  });

  int get total => better + same + worse;

  static DateTime? _checkInDate(String raw) {
    if (!RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z?$',
    ).hasMatch(raw)) {
      return null;
    }
    final year = int.parse(raw.substring(0, 4));
    final month = int.parse(raw.substring(5, 7));
    final day = int.parse(raw.substring(8, 10));
    final calendar = DateTime(year, month, day);
    if (year < 1 ||
        calendar.year != year ||
        calendar.month != month ||
        calendar.day != day ||
        int.parse(raw.substring(11, 13)) > 23 ||
        int.parse(raw.substring(14, 16)) > 59 ||
        int.parse(raw.substring(17, 19)) > 59) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  factory MeditationRecap.fromCheckIns(
    Iterable<Map<String, dynamic>> checkIns, {
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toLocal();
    final today = DateTime(current.year, current.month, current.day);
    final from = DateTime(today.year, today.month, today.day - 6);
    final valid =
        <({String session, String guide, String feeling, DateTime at})>[];
    for (final entry in checkIns) {
      final session = entry['session'];
      final guide = entry['guide'];
      final feeling = entry['feeling'];
      final rawDate = entry['at'];
      if (session is! String ||
          session.trim().isEmpty ||
          guide is! String ||
          !meditationMedia.containsKey(guide) ||
          feeling is! String ||
          !const {'better', 'same', 'worse'}.contains(feeling) ||
          rawDate is! String) {
        continue;
      }
      final at = _checkInDate(rawDate)?.toLocal();
      if (at == null || at.isBefore(from) || at.isAfter(current)) continue;
      valid.add((session: session, guide: guide, feeling: feeling, at: at));
    }
    // Keep the latest copy of a session after a restore/import, regardless of
    // storage order. A duplicate must not inflate either counts or suggestions.
    valid.sort((a, b) => b.at.compareTo(a.at));
    final seen = <String>{};
    final events = valid.where((row) => seen.add(row.session)).toList();
    final days = <DateTime>{};
    final counts = <String, int>{'better': 0, 'same': 0, 'worse': 0};
    final latestByGuide = <String, String>{};
    for (final event in events) {
      counts[event.feeling] = counts[event.feeling]! + 1;
      days.add(DateTime(event.at.year, event.at.month, event.at.day));
      latestByGuide.putIfAbsent(event.guide, () => event.feeling);
    }
    String? preferred;
    for (final event in events) {
      if (event.feeling == 'better' && latestByGuide[event.guide] != 'worse') {
        preferred = event.guide;
        break;
      }
    }
    return MeditationRecap(
      from: from,
      through: today,
      better: counts['better']!,
      same: counts['same']!,
      worse: counts['worse']!,
      recordedDays: days.length,
      preferredGuide: preferred,
      suggestPause: events.isNotEmpty && events.first.feeling == 'worse',
    );
  }
}
