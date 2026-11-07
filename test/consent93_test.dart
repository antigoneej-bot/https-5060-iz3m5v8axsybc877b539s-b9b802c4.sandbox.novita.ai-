import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_app/services/analytics_service.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/privacy_config.dart';
import 'package:flutter_app/models/companion_reminder.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/widgets/consent_retry_notice.dart';

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();
  @override
  Future<bool> setValue(String type, String key, Object value) async => false;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const analytics = MethodChannel('plugins.flutter.io/firebase_analytics');
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezone = MethodChannel('garden/device_timezone');
  late NotificationService service;
  final failIds = <int>{}, canceled = <int>[], scheduled = <int>[];
  var failChannels = false, failOn = false, failOff = false;
  var nativeSharing = false;
  Completer<void>? enableStarted, releaseEnable;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    AnalyticsService.sharingEnabled.value = false;
    AnalyticsService.optOutPending.value = false;
    failIds.clear();
    canceled.clear();
    scheduled.clear();
    failChannels = failOn = failOff = nativeSharing = false;
    enableStarted = releaseEnable = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(analytics, (
      call,
    ) async {
      if (call.method == 'Analytics#setAnalyticsCollectionEnabled') {
        final value = call.arguments['enabled'] as bool;
        if (value && enableStarted != null) {
          enableStarted!.complete();
          await releaseEnable!.future;
        }
        if ((value && failOn) || (!value && failOff))
          throw PlatformException(code: 'synthetic-sdk');
        nativeSharing = value;
      }
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezone,
      (_) async => {'id': 'Asia/Seoul', 'offsetSeconds': 32400},
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(notifications, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'getNotificationAppLaunchDetails')
        return {'notificationLaunchedApp': false};
      if (call.method == 'requestNotificationsPermission') return true;
      if (call.method == 'createNotificationChannel' && failChannels)
        throw PlatformException(code: 'synthetic-channel');
      if (call.method == 'cancel') {
        final id = call.arguments['id'] as int;
        canceled.add(id);
        if (failIds.contains(id))
          throw PlatformException(code: 'synthetic-cancel');
      }
      if (call.method == 'zonedSchedule')
        scheduled.add(call.arguments['id'] as int);
      return null;
    });
    service = NotificationService.forTesting(
      now: () => DateTime.utc(2026, 11, 6),
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  });
  tearDown(() async {
    service.dispose();
    await pumpEventQueue();
    for (final c in [analytics, notifications, timezone]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(c, null);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'new opt-out immediately blocks app events while an older ON completes',
    () async {
      enableStarted = Completer<void>();
      releaseEnable = Completer<void>();
      final on = AnalyticsService().setSharing(true);
      await enableStarted!.future;
      final off = AnalyticsService().setSharing(false);
      expect(AnalyticsService.sharingEnabled.value, false);
      releaseEnable!.complete();
      await Future.wait([on, off]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool('analytics_sharing_v1'), false);
      expect(nativeSharing, false);
      expect(AnalyticsService.sharingEnabled.value, false);
    },
  );
  test(
    'startup ON and explicit OFF serialize without restoring stale consent',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_sharing_v1', true);
      enableStarted = Completer<void>();
      releaseEnable = Completer<void>();
      final load = AnalyticsService().loadConsent();
      await enableStarted!.future;
      final off = AnalyticsService().setSharing(false);
      releaseEnable!.complete();
      await Future.wait([load, off]);
      await prefs.reload();
      expect(prefs.getBool('analytics_sharing_v1'), false);
      expect(nativeSharing, false);
    },
  );
  test('SDK enable failure leaves stored consent and events OFF', () async {
    failOn = true;
    await expectLater(
      AnalyticsService().setSharing(true),
      throwsA(isA<PlatformException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getBool('analytics_sharing_v1'), false);
    expect(nativeSharing, false);
    expect(AnalyticsService.sharingEnabled.value, false);
  });
  test(
    'disk failure cannot enable Analytics and still attempts native OFF',
    () async {
      nativeSharing = true;
      SharedPreferencesStorePlatform.instance = _FailingStore();
      await expectLater(AnalyticsService().setSharing(false), throwsStateError);
      expect(nativeSharing, false);
      expect(AnalyticsService.sharingEnabled.value, false);
      expect(AnalyticsService.optOutPending.value, true);
      SharedPreferences.setMockInitialValues({});
      await AnalyticsService().retryOptOut();
      expect(AnalyticsService.optOutPending.value, false);
    },
  );
  test(
    'foreground retries pending Analytics OFF without enabling collection',
    () async {
      await AnalyticsService().setSharing(true);
      failOff = true;
      await expectLater(
        AnalyticsService().setSharing(false),
        throwsA(isA<PlatformException>()),
      );
      expect(AnalyticsService.optOutPending.value, true);
      failOff = false;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await AnalyticsService().retryOptOut();
      expect(nativeSharing, false);
      expect(AnalyticsService.optOutPending.value, false);
    },
  );
  test(
    'restart retries saved morning OFF after channel failure, without scheduling it',
    () async {
      await StorageService.setMorningEnabled(true);
      await StorageService.setMorningTime(8, 25);
      failChannels = true;
      expect(await service.disableMorning(), false);
      expect(service.cancellationPending.value, contains('morning'));
      service.dispose();
      failChannels = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      service = NotificationService.forTesting(
        now: () => DateTime.utc(2026, 11, 6),
      );
      await service.restoreIfEnabled();
      expect(await service.isMorningEnabled(), false);
      expect(await service.getMorningTime(), (8, 25));
      expect(canceled, contains(1002));
      expect(scheduled, isNot(contains(1002)));
      expect(service.cancellationPending.value, isEmpty);
    },
  );
  for (final visit in [true, false]) {
    test(
      '${visit ? 'visit' : 'streak'} OFF persists after cancel failure and retries',
      () async {
        final id = visit ? 1004 : 1005;
        await (visit
            ? StorageService.setCrisisEnabled(true)
            : StorageService.setStreakEnabled(true));
        failIds.add(id);
        expect(
          await (visit
              ? service.setCrisisEnabled(false)
              : service.setStreakEnabled(false)),
          false,
        );
        expect(
          await (visit ? service.isCrisisEnabled() : service.isStreakEnabled()),
          false,
        );
        expect(
          service.cancellationPending.value,
          contains(visit ? 'visit' : 'streak'),
        );
        failIds.clear();
        await service.retryPendingCancellations();
        expect(canceled, contains(id));
        expect(scheduled, isNot(contains(id)));
        expect(service.cancellationPending.value, isEmpty);
      },
    );
  }
  test(
    'companion partial cancellation tries every slot and restart preserves care budget',
    () async {
      final prefs = await SharedPreferences.getInstance();
      const old = CompanionReminderSettings(
        enabled: true,
        hour: 20,
        minute: 15,
      );
      await prefs.setString(CompanionNotifications.settingsKey, old.encode());
      const ledger = '[{"day":"2026-11-06","when":"2026-11-06T20:15:00"}]';
      await prefs.setString(CompanionNotifications.ledgerKey, ledger);
      await prefs.setString(
        'local_user_companion_journey_v1',
        'preserved-synthetic-record',
      );
      failIds.add(2201);
      expect(await service.changeCompanionReminders(enabled: false), false);
      expect(canceled, containsAll(CompanionNotifications.ids));
      expect(service.cancellationPending.value, contains('companion'));
      final saved = await service.getCompanionReminderSettings();
      expect(saved.enabled, false);
      expect(saved.hour, 20);
      expect(saved.minute, 15);
      failIds.clear();
      service.dispose();
      await prefs.reload();
      service = NotificationService.forTesting(
        now: () => DateTime.utc(2026, 11, 6),
      );
      await service.restoreIfEnabled();
      expect(scheduled, isEmpty);
      expect(prefs.getString(CompanionNotifications.ledgerKey), ledger);
      expect(
        prefs.getString('local_user_companion_journey_v1'),
        'preserved-synthetic-record',
      );
      expect(service.cancellationPending.value, isEmpty);
    },
  );
  test(
    'new explicit opt-in supersedes pending cancellation and preserves time',
    () async {
      expect(await service.enableEvening(hour: 21, minute: 10), true);
      failIds.add(1003);
      expect(await service.disableEvening(), false);
      failIds.clear();
      expect(await service.enableEvening(hour: 21, minute: 10), true);
      await service.retryPendingCancellations();
      expect(await service.isEveningEnabled(), true);
      expect(await service.getEveningTime(), (21, 10));
      expect(service.cancellationPending.value, isNot(contains('evening')));
    },
  );
  test('conditional consent writes report physical disk failure', () async {
    SharedPreferencesStorePlatform.instance = _FailingStore();
    await expectLater(StorageService.setCrisisEnabled(false), throwsStateError);
    await expectLater(StorageService.setStreakEnabled(false), throwsStateError);
  });
  test('care refresh with reminders OFF does not initialize or cancel native alarms', () async {
    expect(await service.refreshCompanionReminders(), true);
    expect(canceled, isEmpty);
    expect(scheduled, isEmpty);
    expect(service.cancellationPending.value, isEmpty);
  });
  testWidgets(
    'pending cancellation stays readable and retry works in small landscape at 2x text',
    (tester) async {
      // This is an active Android UI; service-only tests deliberately stay paused.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await AppLanguage.instance.select('en');
      addTearDown(() => AppLanguage.instance.select('ko'));
      await tester.runAsync(() async {
        await StorageService.setMorningEnabled(true);
        failIds.add(1002);
        expect(await service.disableMorning(), false);
        expect(canceled, contains(1002));
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(568, 320),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: NotificationCancellationNotice(service: service),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining("We haven't confirmed that your phone canceled them"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      failIds.clear();
      await tester.ensureVisible(find.byType(TextButton));
      await tester.runAsync(() async {
        await tester.tap(find.byType(TextButton));
        // Join the real native operation started by the button, not elapsed time.
        await service.retryPendingCancellations();
      });
      await tester.pumpAndSettle();
      expect(service.cancellationPending.value, isEmpty);
      expect(
        find.textContaining("We haven't confirmed that your phone canceled them"),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
  test(
    'Crashlytics policy is available in Korean and English without translating records',
    () async {
      await AppLanguage.instance.select('en');
      expect(
        tr(PrivacyConfig.errorReportingNotice),
        contains('Firebase Crashlytics'),
      );
      expect(
        tr(PrivacyConfig.errorReportingNotice),
        contains('off by default'),
      );
      expect(tr(PrivacyConfig.errorReportingNotice), isNot(contains('오류')));
      await AppLanguage.instance.select('ko');
      expect(
        tr(PrivacyConfig.errorReportingNotice),
        PrivacyConfig.errorReportingNotice,
      );
    },
  );
}
