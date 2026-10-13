/// Select future notifications independently from the unread inbox badge.
T? nextScheduledReply<T>(
  Iterable<T> entries, {
  required DateTime now,
  required bool Function(T) isSeen,
  required DateTime Function(T) availableAt,
}) {
  T? next;
  DateTime? nextAt;
  for (final entry in entries) {
    final at = availableAt(entry);
    if (isSeen(entry) || !at.isAfter(now)) continue;
    if (nextAt == null || at.isBefore(nextAt)) {
      next = entry;
      nextAt = at;
    }
  }
  return next;
}
