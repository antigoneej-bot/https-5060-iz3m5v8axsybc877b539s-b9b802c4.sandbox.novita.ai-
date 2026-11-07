import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/auto_backup_service.dart';
import 'package:flutter_app/models/backup_progress.dart';
import 'package:flutter_app/widgets/record_load_failure.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  group('optional notifications and device timezone', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    const timezone = MethodChannel('garden/device_timezone');
    late NotificationService service;
    late List<MethodCall> calls;
    var zone = 'Asia/Seoul';
    var offset = 32400;
    var failChannels = false, failSchedule = false;
    late DateTime now;
    List<Map<dynamic, dynamic>> schedules(int id) => calls
        .where((c) => c.method == 'zonedSchedule' && c.arguments['id'] == id)
        .map((c) => c.arguments as Map<dynamic, dynamic>)
        .toList();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      zone = 'Asia/Seoul';
      offset = 32400;
      failChannels = false;
      failSchedule = false;
      calls = [];
      now = DateTime.utc(
        2030,
        3,
        9,
        15,
      ); // Before US daylight saving transition.
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        timezone,
        (_) async => {'id': zone, 'offsetSeconds': offset},
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'initialize') return true;
        if (call.method == 'getNotificationAppLaunchDetails') {
          return {'notificationLaunchedApp': false};
        }
        if (call.method == 'requestNotificationsPermission') return true;
        if (call.method == 'createNotificationChannel' && failChannels ||
            call.method == 'zonedSchedule' && failSchedule) {
          throw PlatformException(code: 'synthetic-unavailable');
        }
        return null;
      });
      service = NotificationService.forTesting(now: () => now);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    });
    tearDown(() async {
      service.dispose();
      await pumpEventQueue();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(timezone, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'channel and scheduling failures preserve opt-in; retry restores saved time without a permission prompt',
      () async {
        await StorageService.setMorningEnabled(true);
        await StorageService.setMorningTime(8, 25);
        failChannels = true;
        await service.restoreIfEnabled();
        expect(await service.isMorningEnabled(), isTrue);
        expect(schedules(1002), isEmpty);
        failChannels = false;
        failSchedule = true;
        await service.restoreIfEnabled();
        expect(await service.isMorningEnabled(), isTrue);
        expect(await service.getMorningTime(), (8, 25));
        failSchedule = false;
        calls.clear();
        await service.restoreIfEnabled();
        expect(
          schedules(1002).single['scheduledDateTime'],
          contains('08:25:00'),
        );
        expect(
          calls.where((c) => c.method == 'requestNotificationsPermission'),
          isEmpty,
        );
      },
    );

    test(
      'timezone change on foreground reschedules enabled daily notifications and preserves the chosen hour',
      () async {
        await service.init();
        expect(await service.enableMorning(hour: 9, minute: 10), isTrue);
        expect(schedules(1002).last['timeZoneName'], 'Asia/Seoul');
        zone = 'America/New_York';
        offset = -18000;
        calls.clear();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await service.refreshForForegroundVisit(); // Joins the lifecycle queue.
        expect(schedules(1002), hasLength(1));
        expect(schedules(1002).single['timeZoneName'], zone);
        expect(
          schedules(1002).single['scheduledDateTime'],
          contains('09:10:00'),
        );
        expect(await service.getMorningTime(), (9, 10));
        expect(await service.isMorningEnabled(), isTrue);
        expect(
          calls.where((c) => c.method == 'requestNotificationsPermission'),
          isEmpty,
        );
        expect(schedules(1003), isEmpty); // No new opt-ins.
      },
    );

    test(
      'next morning across DST keeps nine oclock rather than adding 24 hours',
      () async {
        zone = 'America/New_York';
        offset = -18000;
        await service.init();
        expect(tz.TZDateTime.from(now, tz.local).hour, 10);
        expect(await service.enableMorning(), isTrue);
        final scheduled = schedules(1002).single;
        expect(
          scheduled['scheduledDateTime'],
          startsWith('2030-03-10T09:00:00'),
        );
        final target = tz.TZDateTime(tz.local, 2030, 3, 10, 9);
        expect(target.timeZoneOffset, const Duration(hours: -4));
      },
    );

    test(
      'unknown native zone uses its offset instead of Korean timezone',
      () async {
        zone = 'Unknown/Device';
        offset = 19800;
        await service.init();
        expect(await service.enableMorning(), isTrue);
        expect(schedules(1002).single['timeZoneName'], 'GMT+05:30');
        expect(tz.local.timeZone(now.millisecondsSinceEpoch).offset, 19800000);
      },
    );
  });

  test(
    'multiple manual requests share a receipt and only one newer snapshot upload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final started = Completer<void>(), secondStarted = Completer<void>();
      final firstReceipt = Completer<Map<String, dynamic>>(),
          secondReceipt = Completer<Map<String, dynamic>>();
      var content = 'first', uploads = 0;
      final service = AutoBackupService.forTesting(
        owner: () => 'synthetic-coalescing',
        enabled: () async => true,
        snapshot: () async => {
          'schema': 1,
          'createdAt': '2030-03-09',
          'boxes': {
            'synthetic': [
              {'key': 'one', 'value': content},
            ],
          },
          'settings': {},
        },
        upload: (_, __) {
          uploads++;
          if (uploads == 1) {
            started.complete();
            return firstReceipt.future;
          }
          secondStarted.complete();
          return secondReceipt.future;
        },
        password: (_) async => 'synthetic-password',
        restoring: () async => false,
        now: () => DateTime.utc(2030, 3, 9),
      );
      final automatic = service.run();
      await started.future;
      content = 'newer';
      var manualDone = false;
      final manual = Future.wait([
        service.run(force: true),
        service.run(force: true),
      ]).then((_) => manualDone = true);
      firstReceipt.complete({'savedAt': '2030-03-09T00:00:00Z'});
      await secondStarted.future;
      expect(manualDone, isFalse);
      expect(uploads, 2);
      secondReceipt.complete({'savedAt': '2030-03-09T00:00:01Z'});
      await automatic;
      await manual;
      expect(uploads, 2);
      expect(service.status.value.phase, BackupPhase.saved);
      expect((await service.readSummary()).pendingChanges, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'manual join does not retransmit an unconfirmed write',
    () async {
      SharedPreferences.setMockInitialValues({});
      final started = Completer<void>(), release = Completer<void>();
      var uploads = 0;
      final service = AutoBackupService.forTesting(
        owner: () => 'synthetic-failure',
        enabled: () async => true,
        snapshot: () async => {'schema': 1, 'boxes': {}, 'settings': {}},
        upload: (_, __) async {
          uploads++;
          started.complete();
          await release.future;
          throw TimeoutException('synthetic');
        },
        password: (_) async => 'synthetic-password',
        restoring: () async => false,
        now: () => DateTime.utc(2030, 3, 9),
      );
      final automatic = service.run();
      await started.future;
      final manual = service.run(force: true);
      release.complete();
      await automatic;
      await manual;
      expect(uploads, 1);
      expect(service.status.value.phase, BackupPhase.failed);
      expect((await service.readSummary()).lastConfirmedAt, isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'disable during the last secure-storage check prevents a later upload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final checking = Completer<void>(), allowed = Completer<bool>();
      var reads = 0, uploads = 0;
      const secure = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        secure,
        (_) async => null,
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          secure,
          null,
        ),
      );
      final service = AutoBackupService.forTesting(
        owner: () => 'synthetic-stop',
        enabled: () async {
          if (++reads == 3) {
            checking.complete();
            return allowed.future;
          }
          return true;
        },
        snapshot: () async => {'schema': 1, 'boxes': {}, 'settings': {}},
        upload: (_, __) async {
          uploads++;
          return {'savedAt': '2030-03-09T00:00:00Z'};
        },
        password: (_) async => 'synthetic-password',
        restoring: () async => false,
        now: () => DateTime.utc(2030, 3, 9),
      );
      final pending = service.run();
      await checking.future;
      await service.disable();
      allowed.complete(true); // A stale successful secure-storage read.
      await pending;
      expect(uploads, 0);
      expect(service.status.value.phase, BackupPhase.off);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'English record recovery fits small landscape at double text and retries without deleting',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppLanguage.instance.select('en');
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: RecordLoadFailure(onRetry: () => retries++),
          ),
        ),
      );
      expect(
        find.text(
          'Your records could not be loaded. You can retry without deleting them.',
        ),
        findsOneWidget,
      );
      final button = find.text('Reload');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
