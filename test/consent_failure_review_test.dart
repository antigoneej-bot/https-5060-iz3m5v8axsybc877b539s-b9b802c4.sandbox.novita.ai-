import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/analytics_service.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_app/services/storage_service.dart';

// Original 92 failure reproductions. Expectations retained unchanged for 93.
class _Core extends MockFirebaseApp {
  @override
  Future<List<PigeonInitializeResponse?>> initializeCore() async => [
    PigeonInitializeResponse(
      name: '[DEFAULT]',
      options: PigeonFirebaseOptions(
        apiKey: 'synthetic',
        projectId: 'synthetic',
        appId: 'synthetic',
        messagingSenderId: 'synthetic',
      ),
      pluginConstants: {},
    ),
  ];
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const analytics = MethodChannel('plugins.flutter.io/firebase_analytics');
  const notification = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezone = MethodChannel('garden/device_timezone');
  late NotificationService service;
  var failAnalyticsOff = false;
  var failChannels = false;
  var failMorningCancel = false;
  var nativeAnalytics = false;
  final sentEvents = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestFirebaseCoreHostApi.setup(_Core());
    await Firebase.initializeApp();
    failAnalyticsOff = failChannels = failMorningCancel = false;
    nativeAnalytics = false;
    sentEvents.clear();
    AnalyticsService.sharingEnabled.value = false;
    AnalyticsService.optOutPending.value = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(analytics, (
      call,
    ) async {
      if (call.method == 'Analytics#setAnalyticsCollectionEnabled') {
        final enabled = (call.arguments as Map)['enabled'] as bool;
        if (!enabled && failAnalyticsOff)
          throw PlatformException(code: 'synthetic-sdk-off-failure');
        nativeAnalytics = enabled;
      }
      if (call.method == 'Analytics#logEvent')
        sentEvents.add((call.arguments as Map)['eventName'] as String);
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezone,
      (_) async => {'id': 'Asia/Seoul', 'offsetSeconds': 32400},
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(notification, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'getNotificationAppLaunchDetails')
        return {'notificationLaunchedApp': false};
      if (call.method == 'requestNotificationsPermission') return true;
      if (call.method == 'createNotificationChannel' && failChannels)
        throw PlatformException(code: 'synthetic-channel-failure');
      if (call.method == 'cancel' &&
          call.arguments['id'] == 1002 &&
          failMorningCancel)
        throw PlatformException(code: 'synthetic-cancel-failure');
      return null;
    });
    service = NotificationService.forTesting(
      now: () => DateTime.utc(2026, 11, 6),
    );
  });
  tearDown(() {
    service.dispose();
    for (final channel in [analytics, notification, timezone]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('CONTROL: successful Analytics OFF persists and stops events', () async {
    await AnalyticsService().setSharing(true);
    await AnalyticsService().setSharing(false);
    await AnalyticsService().logEvent('synthetic_review');
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getBool('analytics_sharing_v1'), false);
    expect(AnalyticsService.sharingEnabled.value, false);
    expect(nativeAnalytics, false);
    expect(sentEvents, isEmpty);
  });

  test(
    'REQUIRED: Analytics SDK failure must still preserve OFF for next startup',
    () async {
      await AnalyticsService().setSharing(true);
      failAnalyticsOff = true;
      await expectLater(
        AnalyticsService().setSharing(false),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'synthetic-sdk-off-failure',
          ),
        ),
      );
      await AnalyticsService().logEvent('synthetic_after_off_failure');
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final persisted = prefs.getBool('analytics_sharing_v1');
      final memory = AnalyticsService.sharingEnabled.value;
      failAnalyticsOff = false;
      await AnalyticsService().loadConsent();
      expect(
        {
          'stored': persisted,
          'memory': memory,
          'sentAfterOff': sentEvents.length,
          'nativeAfterReload': nativeAnalytics,
        },
        {
          'stored': false,
          'memory': false,
          'sentAfterOff': 0,
          'nativeAfterReload': false,
        },
      );
    },
  );

  test('CONTROL: successful morning OFF preserves selected time', () async {
    expect(await service.enableMorning(hour: 8, minute: 25), true);
    expect(await service.disableMorning(), true);
    expect(await service.isMorningEnabled(), false);
    expect(await service.getMorningTime(), (8, 25));
  });

  test(
    'REQUIRED: channel failure must not forget requested morning OFF',
    () async {
      await StorageService.setMorningEnabled(true);
      await StorageService.setMorningTime(8, 25);
      failChannels = true;
      expect(
        await service.disableMorning(),
        false,
      ); // Failure must remain visible.
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(
        await service.isMorningEnabled(),
        false,
        reason:
            'The requested OFF must remain recorded for retry rather than restoring old ON.',
      );
    },
  );

  test(
    'REQUIRED: cancellation failure must retain OFF and retry cancellation',
    () async {
      expect(await service.enableMorning(hour: 8, minute: 25), true);
      failMorningCancel = true;
      expect(
        await service.disableMorning(),
        false,
      ); // Do not pretend native cancel succeeded.
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(
        await service.isMorningEnabled(),
        false,
        reason: 'A failed cancel must not restore the user consent to ON.',
      );
    },
  );
}
