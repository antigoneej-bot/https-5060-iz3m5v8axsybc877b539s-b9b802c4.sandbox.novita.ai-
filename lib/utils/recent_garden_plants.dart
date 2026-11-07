/// Existing records contain a day, not a planting timestamp. Return every
/// candidate on that day rather than inventing an order between them.
List<String> recentGardenPlants({
  required Map<String, int> seeds,
  required Map<String, String> plantedOn,
  String? sessionLast,
}) {
  if (sessionLast != null && (seeds[sessionLast] ?? 0) > 0) {
    return [sessionLast];
  }
  final known = plantedOn.entries.where(
    (entry) =>
        (seeds[entry.key] ?? 0) > 0 &&
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entry.value),
  );
  if (known.isEmpty) return const [];
  final latest = known
      .map((e) => e.value)
      .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  return known.where((e) => e.value == latest).map((e) => e.key).toList();
}
