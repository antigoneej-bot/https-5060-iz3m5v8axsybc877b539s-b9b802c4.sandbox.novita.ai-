import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/self_care_entry.dart';
import 'package:flutter_app/services/self_care_summary.dart';

void main() {
  test('UTC storage and local records share the same month and day', () {
    final first = DateTime(2026, 10, 1, 0, 30);
    final last = DateTime(2026, 9, 30, 23, 30);
    final entries = [
      SelfCareEntry(id: 'first', createdAt: first.toUtc(), comfort: 4),
      SelfCareEntry(id: 'same-day', createdAt: first, comfort: 8),
      SelfCareEntry(id: 'last', createdAt: last.toUtc(), comfort: 2),
    ];
    final october = SelfCareSummary(
      entries,
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 31),
    );
    final september = SelfCareSummary(
      entries,
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 30),
    );
    expect(october.entries.map((e) => e.id).toSet(), {'first', 'same-day'});
    expect(october.dailyComfort, {DateTime(2026, 10, 1): 6.0});
    expect(october.recordedDays, 1);
    expect(september.entries.single.id, 'last');
  });

  test('UTC storage respects local week and year boundaries', () {
    final entries = [
      SelfCareEntry(
        id: 'sunday',
        createdAt: DateTime(2026, 10, 4, 23, 59).toUtc(),
      ),
      SelfCareEntry(
        id: 'monday',
        createdAt: DateTime(2026, 10, 5, 0, 1).toUtc(),
      ),
      SelfCareEntry(
        id: 'new-year',
        createdAt: DateTime(2027, 1, 1, 0, 1).toUtc(),
      ),
    ];
    expect(
      SelfCareSummary(
        entries,
        DateTime(2026, 9, 28),
        DateTime(2026, 10, 4),
      ).entries.single.id,
      'sunday',
    );
    expect(
      SelfCareSummary(
        entries,
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 11),
      ).entries.single.id,
      'monday',
    );
    expect(
      SelfCareSummary(
        entries,
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 31),
      ).entries.single.id,
      'new-year',
    );
  });
}
