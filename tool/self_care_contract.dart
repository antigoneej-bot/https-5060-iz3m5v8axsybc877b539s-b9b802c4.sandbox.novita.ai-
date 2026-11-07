import 'dart:convert';
import '../lib/models/self_care_entry.dart';
import '../lib/services/self_care_summary.dart';
import '../lib/services/temperature_insight_service.dart';

/// Runs with Dart alone and is also called by the Flutter test suite.
/// Throws independently of --enable-asserts.
void verifySelfCareContract() {
  void check(bool value, String why) {
    if (!value) throw StateError(why);
  }

  void rejects(Map value) {
    try {
      SelfCareEntry.fromMap(value);
    } on FormatException {
      return;
    }
    throw StateError('Invalid record was accepted: $value');
  }

  SelfCareEntry entry(String id, int day, int? score, {CareAction? action}) =>
      SelfCareEntry(
        id: id,
        createdAt: DateTime(2026, 10, day, 9),
        comfort: score,
        action: action,
      );
  final sample = entry('one', 12, 2, action: CareAction.rest);
  final roundTrip = SelfCareEntry.fromMap(
    jsonDecode(jsonEncode(sample.toMap())) as Map,
  );
  check(
    roundTrip.id == sample.id &&
        roundTrip.comfort == 2 &&
        roundTrip.feedback == null,
    'Planning care must not record completion or helpfulness',
  );
  final lowered = sample.withFeedback(
    CareFeedback.helped,
    1,
    DateTime(2026, 10, 12, 12),
  );
  final restored = SelfCareEntry.fromMap(lowered.toMap());
  check(
    restored.feedback == CareFeedback.helped && restored.afterComfort == 1,
    'Helpfulness must not depend on a higher score',
  );
  for (final bad in [0, 11, -1, 3.5, '4', 100]) {
    rejects({...sample.toMap(), 'comfort': bad});
    rejects({...lowered.toMap(), 'afterComfort': bad});
  }
  rejects({...sample.toMap(), 'action': 'unknown'});
  rejects({...lowered.toMap(), 'feedback': 'diagnosed'});
  rejects({...lowered.toMap(), 'action': null});
  rejects({...lowered.toMap(), 'reviewedAt': null});
  rejects({...lowered.toMap(), 'reviewedAt': '2026-10-01T00:00:00.000'});
  rejects({...sample.toMap(), 'afterComfort': 8});
  rejects({...sample.toMap(), 'promptIndex': 3});
  rejects({...sample.toMap(), 'createdAt': '2026-02-30T09:00:00.000'});

  final summary = SelfCareSummary(
    [
      lowered,
      entry('two', 12, 4),
      entry('three', 13, 9),
      entry('unknown', 14, null),
      entry('outside', 11, 10),
      entry('future', 19, 10),
    ],
    DateTime(2026, 10, 12),
    DateTime(2026, 10, 18),
  );
  check(
    summary.entries.length == 4 && summary.recordedDays == 3,
    'Period boundaries or distinct days wrong',
  );
  check(
    summary.scoredEntries == 3 && summary.dailyComfort.length == 2,
    'Missing scores must not count as zero',
  );
  check(
    summary.average == 6,
    'Average must weight day means equally, not check-ins or after-scores',
  );
  check(summary.elapsedDays == 7, 'Elapsed calendar days must be inclusive');
  check(
    !summary.dailyComfort.containsKey(DateTime(2026, 10, 14)),
    'Unknown day must remain a gap',
  );
  check(
    SelfCareSummary([], DateTime(2026, 2, 1), DateTime(2026, 2, 28)).average ==
        null,
    'No data must be null, not zero',
  );
  check(
    SelfCareSummary(
          [],
          DateTime(2024, 2, 1),
          DateTime(2024, 2, 29),
        ).elapsedDays ==
        29,
    'Leap month must retain 29 days',
  );
  final edge = SelfCareEntry(
    id: 'edge',
    createdAt: DateTime(2025, 12, 31, 23, 59),
    comfort: 5,
  );
  check(
    SelfCareSummary(
          [edge],
          DateTime(2025, 12, 29),
          DateTime(2026, 1, 4),
        ).entries.length ==
        1,
    'Calendar week must include last minute of year',
  );
  final feedbacks = [
    for (final feedback in CareFeedback.values)
      entry(
        feedback.name,
        13,
        null,
        action: CareAction.rest,
      ).withFeedback(feedback, null, DateTime(2026, 10, 13, 12)),
    entry('pending', 13, null, action: CareAction.rest),
  ];
  final actions = SelfCareSummary(
    feedbacks,
    DateTime(2026, 10, 12),
    DateTime(2026, 10, 18),
  ).actions.single;
  check(
    actions.planned == 5 && actions.reviewed == 4 && actions.helped == 1,
    'Pending, unknown and uncomfortable outcomes must remain in their own denominators',
  );
  for (final feedback in CareFeedback.values) {
    check(
      actions.responses[feedback] == 1,
      'Feedback category lost: $feedback',
    );
  }
  final legacy = TemperatureInsightService.analyze([
    MapEntry(DateTime(2026, 10, 13), 0),
  ])!;
  check(
    legacy.bandLabel.contains('온기') &&
        legacy.stateDescription.contains('감정이나 심리 상태를 측정한 점수가 아니에요'),
    'Activity reward must not be interpreted as mental state',
  );
}

void main() {
  verifySelfCareContract();
  print(
    'PASS: self-care serialization, invalid data rejection, calendar boundaries, missing data, daily weighting, feedback denominators and reward separation.',
  );
}
