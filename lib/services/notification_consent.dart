/// A shared lane prevents a slow scheduling request from completing after an
/// opt-out has already cancelled that notification.
class NotificationActionQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

bool resolveNotificationConsent(
  bool? explicit,
  Iterable<bool?> legacyChoices,
) => explicit ?? legacyChoices.any((choice) => choice == true);

/// Revoking consent must try every channel even if one preference or platform
/// operation fails. The caller reports failure and retries on the next launch.
Future<void> revokeNotificationConsent(
  Future<void> Function() deny,
  Iterable<Future<void> Function()> cleanup,
) async {
  Object? firstError;
  StackTrace? firstStack;
  for (final action in [deny, ...cleanup]) {
    try {
      await action();
    } catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
    }
  }
  if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
}
