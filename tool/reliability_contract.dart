import 'dart:async';
import '../lib/services/reminder_settings_controller.dart';
import '../lib/models/meditation_check_in_record.dart';

int checked = 0;
void check(bool value, String label) {
  if (!value) throw StateError(label);
  checked++;
}

Future<void> fails(Future<void> Function() action, String label) async {
  try {
    await action();
  } catch (_) {
    checked++;
    return;
  }
  throw StateError(label);
}

Future<void> main() async {
  var stored = const ReminderSetting(false, 9, 0);
  ReminderSetting? scheduled;
  var rejectSchedule = false, rejectSave = false, rejectCancel = false;
  var schedules = 0;
  Completer<void>? pending;
  final controller = ReminderSettingsController(
    read: () async => stored,
    schedule: (h, m) async {
      schedules++;
      if (rejectSchedule) {
        rejectSchedule = false;
        throw StateError('schedule');
      }
      await pending?.future;
      scheduled = ReminderSetting(true, h, m);
    },
    cancel: () async {
      if (rejectCancel) {
        rejectCancel = false;
        throw StateError('cancel');
      }
      scheduled = null;
    },
    persist: (value) async {
      if (rejectSave) {
        rejectSave = false;
        throw StateError('disk');
      }
      stored = value;
    },
  );
  rejectSchedule = true;
  await fails(
    () => controller.change(enabled: true),
    'schedule failure surfaces',
  );
  check(
    !stored.enabled && scheduled == null,
    'failed enable leaves toggle off',
  );
  await controller.change(enabled: true, hour: 10, minute: 20);
  check(
    stored.enabled && scheduled?.hour == 10,
    'queue recovers after failure',
  );
  rejectSchedule = true;
  await fails(
    () => controller.change(hour: 11),
    'time change failure surfaces',
  );
  check(
    stored.hour == 10 && scheduled?.hour == 10,
    'failed time change restores previous time',
  );
  rejectSave = true;
  await fails(() => controller.change(hour: 12), 'preference failure surfaces');
  check(
    stored.hour == 10 && scheduled?.hour == 10,
    'failed persistence restores old schedule',
  );
  rejectCancel = true;
  await fails(
    () => controller.change(enabled: false),
    'cancel failure surfaces',
  );
  check(
    stored.enabled && scheduled != null,
    'failed disable does not claim off',
  );
  final count = schedules;
  await fails(() => controller.change(hour: 24), 'invalid hour rejected');
  await fails(() => controller.change(minute: -1), 'invalid minute rejected');
  check(schedules == count, 'invalid time never reaches platform');
  pending = Completer<void>();
  final update = controller.change(hour: 13);
  await Future<void>.delayed(Duration.zero);
  final disable = controller.change(enabled: false);
  check(
    stored.enabled && stored.hour == 10,
    'pending work not reported as done',
  );
  pending.complete();
  await Future.wait([update, disable]);
  check(
    !stored.enabled && scheduled == null && stored.hour == 13,
    'rapid update then disable serialized',
  );
  pending = null;
  await controller.change(minute: 40);
  check(
    !stored.enabled && scheduled == null && stored.minute == 40,
    'changing disabled time never enables it',
  );

  final raw = <String, dynamic>{
    'session': 'private-session',
    'guide': 'forestRest',
    'feeling': 'worse',
    'at': '2026-10-13T12:00:00.000',
  };
  final record = MeditationCheckInRecord.fromMap(raw);
  check(
    record.toMap()['feeling'] == 'worse',
    'uncomfortable feedback retained verbatim',
  );
  check(!record.toMap().containsKey('score'), 'no inferred numerical score');
  final legacy = MeditationCheckInRecord.parseLegacy([
    raw,
    {...raw, 'feeling': 'better'},
  ]);
  check(
    legacy.length == 1 && legacy.single.feeling == 'worse',
    'retry identity preserves first answer',
  );
  for (final bad in [
    {...raw, 'session': ''},
    {...raw, 'feeling': 'diagnosis'},
    {...raw, 'guide': 'unknown'},
    {...raw, 'at': 'bad'},
  ]) {
    await fails(() async {
      MeditationCheckInRecord.fromMap(bad);
    }, 'invalid feedback rejected');
  }
  await fails(() async {
    MeditationCheckInRecord.parseLegacy([raw, null]);
  }, 'mixed damaged history rejected before migration');
  final many = List.generate(100, (i) => {...raw, 'session': 's-$i'});
  check(
    MeditationCheckInRecord.parseLegacy(many).length == 100,
    'migration does not discard history beyond displayed 90',
  );
  print(
    'PASS: $checked reminder failure/serialization and feedback integrity checks.',
  );
}
