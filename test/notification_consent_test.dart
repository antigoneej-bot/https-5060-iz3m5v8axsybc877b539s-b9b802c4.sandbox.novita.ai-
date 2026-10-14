import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/notification_service.dart';
import '../tool/notification_consent_contract.dart' as contract;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Outside a real app, no platform implementation auto-registers itself
  // behind FlutterLocalNotificationsPlatform.instance, so resolving the
  // Android-specific implementation (used for cancel/initialize/etc.) would
  // throw LateInitializationError. Register it once for the whole suite.
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  Completer<void>? scheduleGate;
  int? failCancelOnce;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    scheduleGate = null;
    failCancelOnce = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'cancel' &&
              (call.arguments as Map)['id'] == failCancelOnce) {
            failCancelOnce = null;
            throw PlatformException(code: 'cancel-failed');
          }
          if (call.method == 'initialize') return true;
          if (call.method == 'requestNotificationsPermission') return true;
          if (call.method == 'getNotificationAppLaunchDetails') {
            return <String, dynamic>{'notificationLaunchedApp': false};
          }
          if (call.method == 'zonedSchedule') await scheduleGate?.future;
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });
  test('consent races and partial cleanup failures', contract.main);
  test(
    'decline clears all reminder/reply settings and seven owned IDs',
    () async {
      SharedPreferences.setMockInitialValues({
        'notification_opt_in': true,
        'reminder_morning_enabled': true,
        'reminder_evening_enabled': true,
        'reminder_crisis_enabled': true,
        'reminder_streak_enabled': true,
        'cat_reply_notifications': true,
      });
      await NotificationService().applyOnboardingOptIn(false);
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'notification_opt_in',
        'reminder_morning_enabled',
        'reminder_evening_enabled',
        'reminder_crisis_enabled',
        'reminder_streak_enabled',
        'cat_reply_notifications',
      ]) {
        expect(prefs.getBool(key), isFalse, reason: key);
      }
      final ids = calls
          .where((c) => c.method == 'cancel')
          .map((c) => (c.arguments as Map)['id'])
          .toSet();
      expect(ids, containsAll([1001, 1002, 1003, 1004, 1005, 1006, 1007]));
    },
  );
  test(
    'resume never resurrects old enabled flags after explicit opt-out',
    () async {
      SharedPreferences.setMockInitialValues({
        'notification_opt_in': false,
        'reminder_crisis_enabled': true,
        'reminder_streak_enabled': true,
        'cat_reply_notifications': true,
      });
      await NotificationService().restoreIfEnabled();
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(await NotificationService().isCrisisEnabled(), isFalse);
      expect(await NotificationService().replyNotificationsEnabled(), isFalse);
    },
  );
  test(
    'enabling morning alone does not enable other old reminder defaults',
    () async {
      SharedPreferences.setMockInitialValues({
        'notification_opt_in': false,
        'reminder_crisis_enabled': true,
        'reminder_streak_enabled': true,
        'cat_reply_notifications': true,
      });
      expect(await NotificationService().enableMorning(), isTrue);
      expect(await NotificationService().isMorningEnabled(), isTrue);
      expect(await NotificationService().isEveningEnabled(), isFalse);
      expect(await NotificationService().isCrisisEnabled(), isFalse);
      expect(await NotificationService().isStreakEnabled(), isFalse);
      expect(await NotificationService().replyNotificationsEnabled(), isFalse);
    },
  );
  test('a slow pending schedule finishes before opt-out cancels it', () async {
    scheduleGate = Completer<void>();
    final service = NotificationService();
    final enable = service.enableMorning();
    for (
      var i = 0;
      i < 30 && !calls.any((c) => c.method == 'zonedSchedule');
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(calls.any((c) => c.method == 'zonedSchedule'), isTrue);
    final disable = service.applyOnboardingOptIn(false);
    scheduleGate!.complete();
    await enable;
    await disable;
    expect(await service.isMorningEnabled(), isFalse);
    final scheduledAt = calls.lastIndexWhere(
      (c) => c.method == 'zonedSchedule',
    );
    final cancelledAt = calls.lastIndexWhere(
      (c) => c.method == 'cancel' && (c.arguments as Map)['id'] == 1002,
    );
    expect(cancelledAt, greaterThan(scheduledAt));
  });
  test(
    'a failed old cancellation is retried before enabling just one channel',
    () async {
      SharedPreferences.setMockInitialValues({
        'notification_opt_in': true,
        'reminder_evening_enabled': true,
      });
      // Initialize before injecting failure: legacy cancellation is unrelated.
      await NotificationService().init();
      failCancelOnce = 1003;
      await expectLater(
        NotificationService().applyOnboardingOptIn(false),
        throwsA(isA<PlatformException>()),
      );
      calls.clear();
      expect(await NotificationService().enableMorning(), isTrue);
      await NotificationService().restoreIfEnabled();
      expect(await NotificationService().isEveningEnabled(), isFalse);
      expect(
        calls.where(
          (c) => c.method == 'cancel' && (c.arguments as Map)['id'] == 1003,
        ),
        isNotEmpty,
      );
      expect(
        calls.where(
          (c) => c.method == 'cancel' && (c.arguments as Map)['id'] == 1006,
        ),
        isNotEmpty,
      );
      expect(
        calls.where(
          (c) => c.method == 'cancel' && (c.arguments as Map)['id'] == 1007,
        ),
        isNotEmpty,
      );
    },
  );
}
