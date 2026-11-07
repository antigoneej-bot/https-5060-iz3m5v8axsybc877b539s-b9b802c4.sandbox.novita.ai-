import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'REVIEW: notification channel failure must not escape optional startup initialization',
    () async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      var reachedChannelCreation = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'getNotificationAppLaunchDetails') {
              return {'notificationLaunchedApp': false};
            }
            if (call.method == 'createNotificationChannel') {
              reachedChannelCreation = true;
              throw PlatformException(code: 'synthetic-channel-failure');
            }
            return null;
          });
      Object? failure;
      final service = NotificationService.forTesting(now: DateTime.now);
      addTearDown(service.dispose);
      try {
        await service.init();
      } catch (e) {
        failure = e;
      }
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(reachedChannelCreation, true);
      expect(
        failure,
        isNull,
        reason:
            'main awaits this before runApp; channel failure must not block the local garden.',
      );
    },
  );
}
