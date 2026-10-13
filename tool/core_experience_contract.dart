import '../lib/mongi/models/garden_anniversary.dart';
import '../lib/models/self_care_entry.dart';
import '../lib/services/self_care_summary.dart';

int checked = 0;
void check(bool ok, String description) {
  if (!ok) throw StateError(description);
  checked++;
}

void main() {
  final start = DateTime(2026, 10, 14);
  check(
    GardenAnniversary.daysTogether(start, start) == 1,
    'plant day is day one',
  );
  final hundred = DateTime(2026, 10, 14 + 99);
  check(
    GardenAnniversary.next(start, hundred).label == '100일',
    '100th day is +99 calendar days',
  );
  check(
    GardenAnniversary.label(start, hundred) == '오늘은 100일이에요',
    'celebrate on date',
  );
  check(
    GardenAnniversary.anniversary(DateTime(2024, 2, 29), 1) ==
        DateTime(2025, 2, 28),
    'leap-day anniversary',
  );
  check(
    GardenAnniversary.next(DateTime(2020, 10, 14), start).label == '6주년',
    'annual recurrence',
  );
  check(
    GardenAnniversary.next(DateTime(2027, 1, 1), start).label == '기억할 날',
    'future date',
  );
  check(
    GardenAnniversary.parse('2026-02-30') == null,
    'invalid normalized day rejected',
  );
  check(GardenAnniversary.parse('2026-1-01') == null, 'strict canonical day');
  check(
    GardenAnniversary.daysBetween(
          DateTime(2026, 3, 8, 23),
          DateTime(2026, 3, 9, 1),
        ) ==
        1,
    'calendar dates, not elapsed hours',
  );
  final oldHelpful = SelfCareEntry(
    id: 'old',
    createdAt: DateTime(2026, 8, 1),
    action: CareAction.rest,
    feedback: CareFeedback.helped,
    reviewedAt: DateTime(2026, 8, 2),
  );
  final recentUncomfortable = SelfCareEntry(
    id: 'recent',
    createdAt: DateTime(2026, 9, 1),
    action: CareAction.rest,
    feedback: CareFeedback.uncomfortable,
    reviewedAt: DateTime(2026, 9, 2),
  );
  final pending = SelfCareEntry(
    id: 'pending',
    createdAt: DateTime(2026, 9, 5),
    action: CareAction.kindness,
  );
  check(
    SelfCareSummary.reusable([oldHelpful, recentUncomfortable]).isEmpty,
    'latest uncomfortable suppresses replay',
  );
  check(
    SelfCareSummary.reusable([oldHelpful]).single == CareAction.rest,
    'helpful replay',
  );
  check(
    SelfCareSummary.reusable([
      oldHelpful,
      SelfCareEntry(
        id: 'same-time',
        createdAt: oldHelpful.createdAt,
        action: CareAction.rest,
        feedback: CareFeedback.uncomfortable,
        reviewedAt: oldHelpful.reviewedAt,
      ),
    ]).isEmpty,
    'uncomfortable feedback wins at identical review timestamps',
  );
  check(
    SelfCareSummary.pending([pending, oldHelpful], start).single.id ==
        'pending',
    'unfinished care survives period boundary',
  );
  check(
    SelfCareSummary.pending([
      SelfCareEntry(
        id: 'future',
        createdAt: DateTime(2027),
        action: CareAction.rest,
      ),
    ], start).isEmpty,
    'future plan not treated as overdue',
  );
  final summary = SelfCareSummary(
    [pending, oldHelpful],
    DateTime(2026, 9, 1),
    DateTime(2026, 9, 30),
  );
  check(summary.average == null, 'unanswered comfort is not zero');
  print(
    'PASS: $checked calendar anniversary, follow-up and self-care data contracts.',
  );
}
