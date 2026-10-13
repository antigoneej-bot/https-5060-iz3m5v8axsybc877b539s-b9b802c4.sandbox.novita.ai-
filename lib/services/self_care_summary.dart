import '../models/self_care_entry.dart';

class CareActionSummary {
  final CareAction action;
  final int planned;
  final Map<CareFeedback, int> responses;
  const CareActionSummary(this.action, this.planned, this.responses);
  int get reviewed => responses.values.fold(0, (a, b) => a + b);
  int get helped => responses[CareFeedback.helped] ?? 0;
}

/// Descriptive counts only: missing is not zero, after-scores aren't baselines,
/// repeated check-ins don't give that day extra weight in the period mean.
class SelfCareSummary {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final List<SelfCareEntry> entries;
  final DateTime start;
  final DateTime end;
  SelfCareSummary(Iterable<SelfCareEntry> all, DateTime start, DateTime end)
    : start = day(start),
      end = day(end),
      entries =
          all
              .where(
                (e) =>
                    !day(e.createdAt).isBefore(day(start)) &&
                    !day(e.createdAt).isAfter(day(end)),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Map<DateTime, double> get dailyComfort {
    final values = <DateTime, List<int>>{};
    for (final entry in entries) {
      if (entry.comfort != null) {
        values.putIfAbsent(day(entry.createdAt), () => []).add(entry.comfort!);
      }
    }
    return values.map(
      (key, scores) =>
          MapEntry(key, scores.reduce((a, b) => a + b) / scores.length),
    );
  }

  int get scoredEntries => entries.where((e) => e.comfort != null).length;
  int get recordedDays => entries.map((e) => day(e.createdAt)).toSet().length;
  int get elapsedDays =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;
  double? get average {
    final values = dailyComfort.values;
    return values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
  }

  /// Pending plans stay visible across week/month boundaries, without a deadline.
  static List<SelfCareEntry> pending(
    Iterable<SelfCareEntry> all,
    DateTime now,
  ) =>
      (all
          .where(
            (e) =>
                e.action != null &&
                e.feedback == null &&
                !e.createdAt.isAfter(now),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// A recent uncomfortable experience takes precedence over older helpful ones.
  /// This is the person's own history, not a claim of treatment effectiveness.
  static List<CareAction> reusable(Iterable<SelfCareEntry> all) {
    final entries = all.where((e) => e.feedback != null).toList()
      ..sort((a, b) {
        final date = b.reviewedAt!.compareTo(a.reviewedAt!);
        if (date != 0) return date;
        if (a.feedback == CareFeedback.uncomfortable &&
            b.feedback != CareFeedback.uncomfortable)
          return -1;
        if (b.feedback == CareFeedback.uncomfortable &&
            a.feedback != CareFeedback.uncomfortable)
          return 1;
        return b.id.compareTo(a.id);
      });
    final seen = <CareAction>{};
    return [
      for (final entry in entries)
        if (entry.action != null &&
            seen.add(entry.action!) &&
            entry.feedback == CareFeedback.helped)
          entry.action!,
    ];
  }

  List<CareActionSummary> get actions => [
    for (final action in CareAction.values)
      if (entries.any((e) => e.action == action))
        CareActionSummary(
          action,
          entries.where((e) => e.action == action).length,
          {
            for (final response in CareFeedback.values)
              response: entries
                  .where((e) => e.action == action && e.feedback == response)
                  .length,
          },
        ),
  ];
}
