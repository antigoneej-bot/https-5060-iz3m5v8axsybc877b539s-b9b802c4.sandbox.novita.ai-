import 'care_journal_entry.dart';

/// Counts explicit reports within a calendar period, never an effectiveness score.
class CareNextStep {
  const CareNextStep({
    this.suggested,
    this.awaitingFeedback,
    this.reviewed = 0,
    this.helped = 0,
  });
  final CareJournalEntry? suggested, awaitingFeedback;
  final int reviewed, helped;

  factory CareNextStep.fromEntries(
    Iterable<CareJournalEntry> entries, {
    required DateTime now,
  }) {
    final local = now.toLocal();
    final start = DateTime(local.year, local.month, local.day - 29);
    final recent = entries
        .where(
          (e) =>
              e.actionKind != null &&
              e.completedAt != null &&
              !e.completedAt!.isAfter(now) &&
              !e.completedAt!.toLocal().isBefore(start) &&
              !e.updatedAt.isAfter(now),
        )
        .toList();
    final feedback = recent.where((e) => e.helpfulness != null).toList()
      ..sort((a, b) {
        final order = b.updatedAt.compareTo(a.updatedAt);
        if (order != 0) return order;
        // Conflicting reports at the same instant do not create a suggestion.
        if (a.wasHelpful != b.wasHelpful) return a.wasHelpful ? 1 : -1;
        return b.id.compareTo(a.id);
      });
    String group(CareJournalEntry e) =>
        '${e.actionKind?.name}:${e.actionLabel}:${e.contextLabel ?? ''}';
    final seen = <String>{};
    CareJournalEntry? suggested;
    for (final entry in feedback) {
      if (seen.add(group(entry)) && entry.wasHelpful) {
        suggested = entry;
        break;
      }
    }
    final related = suggested == null
        ? <CareJournalEntry>[]
        : feedback.where((e) => group(e) == group(suggested!)).toList();
    final awaiting = recent.where((e) => e.helpfulness == null).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return CareNextStep(
      suggested: suggested,
      awaitingFeedback: awaiting.isEmpty ? null : awaiting.first,
      reviewed: related.length,
      helped: related.where((e) => e.wasHelpful).length,
    );
  }
}
