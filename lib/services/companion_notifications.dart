part of 'notification_service.dart';

extension CompanionNotifications on NotificationService {
  static const settingsKey = 'companion_reminder_settings_v1';
  static const ledgerKey = 'companion_reminder_plan_v1';
  static const consumedKey = 'companion_reminder_consumed_day_v1';
  static const ids = [2200, 2201, 2202, 2203, 2204, 2205, 2206, 2207];

  Future<CompanionReminderSettings> getCompanionReminderSettings() async =>
      CompanionReminderSettings.decode(
        (await SharedPreferences.getInstance()).getString(settingsKey),
      );

  Future<void> _saveCompanionSettings(
    CompanionReminderSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(settingsKey, settings.encode())) {
      throw StateError('고양이 소식 설정을 저장하지 못했어요.');
    }
  }

  Future<void> _cancelCompanionSlots() async {
    if (kIsWeb || !_initialized) return;
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  /// Treat a due reservation as delivered even when the OS cannot confirm it.
  /// This deliberately favors fewer notifications over sending twice today.
  Future<String?> _companionConsumedDay(
    SharedPreferences prefs,
    DateTime now,
  ) async {
    var consumed = prefs.getString(consumedKey);
    final today = companionDay(now);
    final raw = prefs.getString(ledgerKey);
    if (raw != null) {
      try {
        final ledger = jsonDecode(raw);
        if (ledger is! List) throw const FormatException();
        for (final entry in ledger) {
          if (entry is! Map ||
              entry['day'] is! String ||
              entry['when'] is! String) {
            throw const FormatException();
          }
          final due = DateTime.parse(entry['when']);
          if (entry['day'] == today && !due.isAfter(now)) consumed = today;
        }
      } catch (_) {
        consumed =
            today; // Unknown delivery history must never trigger a repeat.
      }
    }
    if (consumed != null && !await prefs.setString(consumedKey, consumed)) {
      throw StateError('알림 횟수를 저장하지 못했어요.');
    }
    return consumed;
  }

  Future<void> _applyCompanionSchedule(
    CompanionReminderSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = _now().toLocal();
    final consumed = await _companionConsumedDay(prefs, now);
    await _cancelCompanionSlots();
    final slots = settings.enabled
        ? planCompanionReminders(
            now: now,
            settings: settings,
            journey: await CompanionJourneyStore.load(
              CatCareService.localOwner,
            ),
            consumedDay: consumed,
          )
        : <CompanionReminderSlot>[];
    // Persist the delivery budget before scheduling. A crash can omit an
    // invitation, but cannot create a second invitation on the same date.
    if (!await prefs.setString(
      ledgerKey,
      jsonEncode(slots.map((s) => s.toLedger()).toList()),
    )) {
      throw StateError('알림 예약을 저장하지 못했어요.');
    }
    if (kIsWeb || !settings.enabled) return;
    final name = companionDisplayName(await StorageService.getCompanionName());
    for (final slot in slots) {
      await _plugin.zonedSchedule(
        slot.id,
        '$name의 작은 부탁 🐾',
        CompanionInvitation.message(slot.invitation.action),
        // Keep the user's local-clock instant even though legacy reminders
        // use the Seoul timezone. No additional permission or server is needed.
        tz.TZDateTime.from(slot.when, tz.local),
        await _reminderBellDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: slot.invitation.payload,
      );
    }
  }

  /// Explicit opt-in only. Time edits and enable/disable share the existing
  /// queue with foreground refreshes, so stale refreshes cannot re-enable it.
  Future<bool> changeCompanionReminders({
    bool? enabled,
    int? hour,
    int? minute,
  }) => _serializeConditional(() async {
    CompanionReminderSettings? old;
    try {
      old = await getCompanionReminderSettings();
      final next = CompanionReminderSettings(
        enabled: enabled ?? old.enabled,
        hour: hour ?? old.hour,
        minute: minute ?? old.minute,
      );
      if (!next.validTime) return false;
      if (next.enabled) {
        if (kIsWeb) return false;
        await init();
        if (!_initialized || !await _requestPermission()) return false;
      } else if (!kIsWeb) {
        await init();
        if (!_initialized) return false;
      }
      await _applyCompanionSchedule(next);
      await _saveCompanionSettings(next);
      companionReminderChanges.fire();
      return true;
    } catch (_) {
      if (old != null) {
        try {
          await _applyCompanionSchedule(old);
          await _saveCompanionSettings(old);
        } catch (_) {
          // Only claim an off state after native cancellation actually succeeds.
          try {
            await _cancelCompanionSlots();
            await _saveCompanionSettings(
              CompanionReminderSettings(hour: old.hour, minute: old.minute),
            );
          } catch (_) {}
        }
      }
      companionReminderChanges.fire();
      return false;
    }
  });

  Future<bool> _refreshCompanionSafely() async {
    try {
      final settings = await getCompanionReminderSettings();
      if (!settings.enabled) return true;
      if (kIsWeb) return false;
      await init();
      if (!_initialized) return false;
      await _applyCompanionSchedule(settings);
      return true;
    } catch (_) {
      // Care remains saved even if the OS temporarily rejects a notification.
      try {
        await _cancelCompanionSlots();
      } catch (_) {}
      return false;
    }
  }

  /// Called after a saved care action, rename, restore and foreground visit.
  /// Never asks for permission or changes the user's consent.
  Future<bool> refreshCompanionReminders() =>
      _serializeConditional(_refreshCompanionSafely);
}
