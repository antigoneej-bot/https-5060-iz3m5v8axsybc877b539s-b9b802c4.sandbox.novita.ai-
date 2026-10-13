/// Calendar-day milestones; opening a screen never changes a stored date.
class GardenAnniversary {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  static int daysTogether(DateTime start, DateTime now) =>
      daysBetween(start, now) + 1;
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static DateTime? parse(String? value) {
    if (value == null) return null;
    final date = DateTime.tryParse(value);
    return date != null && key(date) == value ? day(date) : null;
  }

  static DateTime anniversary(DateTime start, int years) {
    final year = start.year + years;
    final lastDay = DateTime(year, start.month + 1, 0).day;
    return DateTime(
      year,
      start.month,
      start.day > lastDay ? lastDay : start.day,
    );
  }

  static ({String label, DateTime date}) next(DateTime start, DateTime now) {
    final today = day(now), base = day(start);
    final years = (today.year - base.year).clamp(1, 9999);
    final dates =
        <({String label, DateTime date})>[
            if (!base.isBefore(today)) (label: '기억할 날', date: base),
            for (final count in [30, 100])
              (
                label: '$count일',
                date: DateTime(base.year, base.month, base.day + count - 1),
              ),
            for (final year in [years, years + 1])
              (label: '$year주년', date: anniversary(base, year)),
          ].where((item) => !item.date.isBefore(today)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return dates.first;
  }

  static String label(DateTime start, DateTime now) {
    final nextDay = next(start, now);
    final remaining = daysBetween(now, nextDay.date);
    return remaining == 0
        ? '오늘은 ${nextDay.label}이에요'
        : '${nextDay.label}까지 $remaining일';
  }
}
