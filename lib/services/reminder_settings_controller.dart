/// Serializes device scheduling and preference changes. Failed changes restore
/// the previous schedule where the platform still permits it, and surface errors.
class ReminderSettingsController {
  ReminderSettingsController({
    required this.read,
    required this.schedule,
    required this.cancel,
    required this.persist,
  });
  final Future<ReminderSetting> Function() read;
  final Future<void> Function(int hour, int minute) schedule;
  final Future<void> Function() cancel;
  final Future<void> Function(ReminderSetting value) persist;
  Future<void> _tail = Future.value();

  Future<void> change({bool? enabled, int? hour, int? minute}) {
    final result = _tail.then((_) async {
      final old = await read();
      final next = ReminderSetting(
        enabled ?? old.enabled,
        hour ?? old.hour,
        minute ?? old.minute,
      );
      next.validate();
      try {
        await _apply(next);
        await persist(next);
      } catch (_) {
        // A platform failure cannot be made atomic with preferences. Best effort
        // rollback plus a visible error; never report this change as successful.
        try {
          await _apply(old);
        } catch (_) {}
        try {
          await persist(old);
        } catch (_) {}
        rethrow;
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _apply(ReminderSetting value) =>
      value.enabled ? schedule(value.hour, value.minute) : cancel();
}

class ReminderSetting {
  final bool enabled;
  final int hour, minute;
  const ReminderSetting(this.enabled, this.hour, this.minute);
  void validate() {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('알림 시간이 올바르지 않아요.');
    }
  }
}
