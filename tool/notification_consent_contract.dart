import 'dart:async';
import '../lib/services/notification_consent.dart';

Future<void> main() async {
  var checks = 0;
  void check(bool condition, String label) {
    if (!condition) throw StateError(label);
    checks++;
  }

  check(!resolveNotificationConsent(null, [null, null]), 'new install is off');
  check(
    !resolveNotificationConsent(false, [true, true]),
    'decline beats stale switches',
  );
  check(
    resolveNotificationConsent(null, [null, true]),
    'explicit legacy choice retained',
  );
  check(
    resolveNotificationConsent(true, [false]),
    'consent retained independently of channels',
  );
  final events = <String>[];
  var consent = true;
  var scheduled = true;
  try {
    await revokeNotificationConsent(
      () async {
        consent = false;
        events.add('deny');
      },
      [
        () async {
          events.add('failed preference');
          throw StateError('disk');
        },
        () async {
          scheduled = false;
          events.add('cancel first');
        },
        () async {
          events.add('failed cancel');
          throw StateError('platform');
        },
        () async {
          events.add('cancel last');
        },
      ],
    );
    throw StateError('must surface failure');
  } catch (e) {
    check(e.toString().contains('disk'), 'first failure surfaced');
  }
  check(
    !consent && !scheduled,
    'deny persists and other channels cancel despite failure',
  );
  check(
    events.join('|') ==
        'deny|failed preference|cancel first|failed cancel|cancel last',
    'every cleanup attempted',
  );
  final lane = NotificationActionQueue();
  final pending = Completer<void>();
  events.clear();
  final schedule = lane.run(() async {
    await pending.future;
    scheduled = true;
    events.add('schedule');
  });
  final decline = lane.run(
    () => revokeNotificationConsent(
      () async {
        consent = false;
      },
      [
        () async {
          scheduled = false;
          events.add('cancel');
        },
      ],
    ),
  );
  await Future<void>.delayed(Duration.zero);
  check(events.isEmpty, 'decline waits for in-flight platform schedule');
  pending.complete();
  await Future.wait([schedule, decline]);
  check(
    !scheduled && events.join('|') == 'schedule|cancel',
    'slow schedule cannot revive after decline',
  );
  try {
    await lane.run(() async {
      throw StateError('temporary');
    });
  } catch (_) {}
  check(
    await lane.run(() async => 7) == 7,
    'queue recovers after failed operation',
  );
  print('PASS: $checks notification consent, failure cleanup and race checks.');
}
