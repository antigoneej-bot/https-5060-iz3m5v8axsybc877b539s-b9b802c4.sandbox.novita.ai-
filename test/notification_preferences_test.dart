import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late NotificationService service;
  late DateTime now;
  late List<MethodCall> calls;
  late bool granted;
  late bool failSchedule;
  var failCancel = false;
  Completer<bool>? permissionResponse;

  List<Map<dynamic, dynamic>> schedules(int id) => calls
      .where(
        (call) => call.method == 'zonedSchedule' && call.arguments['id'] == id,
      )
      .map((call) => call.arguments as Map<dynamic, dynamic>)
      .toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    granted = true;
    failSchedule = false;
    failCancel = false;
    permissionResponse = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {'notificationLaunchedApp': false};
        case 'requestNotificationsPermission':
          return permissionResponse?.future ?? Future.value(granted);
        case 'cancel':
          if (failCancel) throw PlatformException(code: 'cancel-unavailable');
          return null;
        case 'zonedSchedule':
          if (failSchedule) {
            throw PlatformException(code: 'schedule-unavailable');
          }
      }
      return null;
    });
    // A future date also satisfies the real plugin's future-date validation.
    now = DateTime.now().toUtc().add(const Duration(days: 2));
    service = NotificationService.forTesting(now: () => now);
    await service.init();
    final futureDay = tz.TZDateTime.from(now, tz.local);
    now = tz.TZDateTime(
      tz.local,
      futureDay.year,
      futureDay.month,
      futureDay.day,
      9,
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    calls.clear();
  });

  tearDown(() async {
    service.dispose();
    await pumpEventQueue();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final morning in [true, false]) {
    test(
      '${morning ? 'morning' : 'evening'} native failure does not enable; failed time and cancel preserve old settings',
      () async {
        Future<bool> enable() =>
            morning ? service.enableMorning() : service.enableEvening();
        Future<bool> enabled() =>
            morning ? service.isMorningEnabled() : service.isEveningEnabled();
        Future<(int, int)> time() =>
            morning ? service.getMorningTime() : service.getEveningTime();
        failSchedule = true;
        expect(await enable(), isFalse);
        expect(await enabled(), isFalse);
        failSchedule = false;
        expect(await enable(), isTrue);
        final before = await time();
        failSchedule = true;
        expect(
          await (morning
              ? service.updateMorningTime(7, 25)
              : service.updateEveningTime(22, 15)),
          isFalse,
        );
        expect(await time(), before);
        expect(await enabled(), isTrue);
        failSchedule = false;
        failCancel = true;
        expect(
          await (morning ? service.disableMorning() : service.disableEvening()),
          isFalse,
        );
        expect(await enabled(), isTrue);
        failCancel = false;
        expect(
          await (morning ? service.disableMorning() : service.disableEvening()),
          isTrue,
        );
        expect(await enabled(), isFalse);
      },
    );
  }

  test(
    'rapid daily enable then disable stays disabled after permission resolves',
    () async {
      permissionResponse = Completer<bool>();
      final enabling = service.enableMorning();
      final disabling = service.disableMorning();
      await pumpEventQueue();
      permissionResponse!.complete(true);
      expect(await enabling, isTrue);
      expect(await disabling, isTrue);
      expect(await service.isMorningEnabled(), isFalse);
      expect(calls.last.method, 'cancel');
    },
  );

  test(
    'new installation starts opted out and preserves explicit old opt-in',
    () async {
      expect(await service.isCrisisEnabled(), isFalse);
      expect(await service.isStreakEnabled(), isFalse);
      await StorageService.setCrisisEnabled(true);
      await StorageService.setStreakEnabled(true);
      expect(await service.isCrisisEnabled(), isTrue);
      expect(await service.isStreakEnabled(), isTrue);
    },
  );

  test(
    'startup removes only legacy and retired reply notification IDs',
    () async {
      service.dispose();
      service = NotificationService.forTesting(now: () => now);
      await service.init();
      expect(
        calls
            .where((call) => call.method == 'cancel')
            .map((call) => call.arguments['id']),
        [1001, 1006, 1007],
      );
      expect(calls.where((call) => call.method == 'cancelAll'), isEmpty);
      expect(
        calls.where((call) => call.method == 'requestNotificationsPermission'),
        isEmpty,
      );
    },
  );

  test(
    'retired reply schedules are canceled without changing other reminders',
    () async {
      await StorageService.setStreakEnabled(true);
      await service.restoreReplyNotification();
      expect(
        calls.where((c) => c.method == 'cancel').map((c) => c.arguments['id']),
        [1006, 1007],
      );
      expect(await service.isStreakEnabled(), isTrue);
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(
        calls.where((c) => c.method == 'requestNotificationsPermission'),
        isEmpty,
      );
    },
  );

  test(
    'legacy callers cannot reenable or schedule automatic answer notifications',
    () async {
      expect(await service.setReplyNotificationsEnabled(true), isFalse);
      expect(await service.replyNotificationsEnabled(), isFalse);
      await service.scheduleCatReplyNotification(
        catName: '고양이',
        scheduledAt: now,
      );
      await service.scheduleHeartLetterReplyNotification(
        typeLabel: '감사 편지',
        scheduledAt: now,
      );
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(
        calls.where((c) => c.method == 'requestNotificationsPermission'),
        isEmpty,
      );
    },
  );

  test('permission denial leaves both conditional reminders off', () async {
    granted = false;
    expect(await service.setCrisisEnabled(true), isFalse);
    expect(await service.setStreakEnabled(true), isFalse);
    expect(await service.isCrisisEnabled(), isFalse);
    expect(await service.isStreakEnabled(), isFalse);
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission').length,
      2,
    );
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test(
    'turning on schedules three-day visit reminder without restarting',
    () async {
      expect(await service.setCrisisEnabled(true), isTrue);
      expect(schedules(1004), hasLength(1));
      final at = DateTime.parse(
        schedules(1004).single['scheduledDateTime'] as String,
      );
      final expected = tz.TZDateTime.from(
        now,
        tz.local,
      ).add(const Duration(days: 3));
      expect(
        at,
        DateTime(expected.year, expected.month, expected.day, expected.hour),
      );
      expect(await service.setCrisisEnabled(false), isTrue);
      expect(await service.isCrisisEnabled(), isFalse);
      expect(calls.last.method, 'cancel');
      expect(calls.last.arguments['id'], 1004);
    },
  );

  test(
    'turning on schedules today care reminder and turning off cancels it',
    () async {
      expect(await service.setStreakEnabled(true), isTrue);
      expect(schedules(1005), hasLength(1));
      expect(schedules(1005).single['scheduledDateTime'], contains('21:30:00'));
      expect(await service.setStreakEnabled(false), isTrue);
      expect(calls.last.arguments['id'], 1005);
      expect(await service.isStreakEnabled(), isFalse);
    },
  );

  test(
    'care reminder stays opted in but does not schedule an expired time',
    () async {
      now = now.add(const Duration(hours: 13));
      expect(await service.setStreakEnabled(true), isTrue);
      expect(await service.isStreakEnabled(), isTrue);
      expect(schedules(1005), isEmpty);
    },
  );

  test(
    'native scheduling failure is reported instead of displaying enabled',
    () async {
      failSchedule = true;
      expect(await service.setCrisisEnabled(true), isFalse);
      expect(await service.isCrisisEnabled(), isFalse);
      expect(await service.setStreakEnabled(true), isFalse);
      expect(await service.isStreakEnabled(), isFalse);
    },
  );

  test(
    'foreground return renews absence deadline; background does not',
    () async {
      await service.setCrisisEnabled(true);
      final first = schedules(1004).single['scheduledDateTime'];
      now = now.add(const Duration(days: 1));
      await service.restoreIfEnabled();
      expect(schedules(1004), hasLength(1));
      calls.clear();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(schedules(1004), hasLength(1));
      expect(schedules(1004).single['scheduledDateTime'], isNot(first));
      expect(
        calls.where((c) => c.method == 'requestNotificationsPermission'),
        isEmpty,
      );
      calls.clear();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await service.refreshForForegroundVisit();
      expect(calls, isEmpty);
    },
  );

  test(
    'a quick off while permission is open wins after the permission result',
    () async {
      permissionResponse = Completer<bool>();
      final enable = service.setCrisisEnabled(true);
      await pumpEventQueue();
      final disable = service.setCrisisEnabled(false);
      permissionResponse!.complete(true);
      expect(await enable, isTrue);
      expect(await disable, isTrue);
      expect(await service.isCrisisEnabled(), isFalse);
      expect(calls.last.method, 'cancel');
      expect(calls.last.arguments['id'], 1004);
    },
  );
}
