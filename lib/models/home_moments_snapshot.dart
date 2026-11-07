import '../mongi/integration/mongi_garden_data.dart';
import '../mongi/models/seed.dart';
import 'letter_entry.dart';

/// A read-only projection of existing records. Viewing it never earns rewards.
class HomeMomentsSnapshot {
  HomeMomentsSnapshot({
    required Iterable<LetterEntry> letters,
    required MongiGardenData? garden,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final saved = {for (final entry in letters) entry.id: entry}.values;
    hasRecords = saved.isNotEmpty;
    recordsToday = saved.where((entry) {
      final date = entry.date.toLocal();
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day &&
          !date.isAfter(local);
    }).length;
    wateredPlants = List.unmodifiable([
      if (garden != null)
        for (final seed in SeedType.all)
          if ((garden.seeds[seed.id] ?? 0) > 0 &&
              garden.wateredOn[seed.id] == key)
            (seed: seed, growth: garden.seeds[seed.id]!),
    ]);
  }

  late final int recordsToday;
  late final bool hasRecords;
  late final List<({SeedType seed, int growth})> wateredPlants;
  bool get hasToday => recordsToday > 0 || wateredPlants.isNotEmpty;
}
