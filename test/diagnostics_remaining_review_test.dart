import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/diagnostics_service.dart';

class ReviewFirebaseCore extends MockFirebaseApp {
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
      pluginConstants: {
        'plugins.flutter.io/firebase_crashlytics': {
          'isCrashlyticsCollectionEnabled': true,
        },
      },
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'REVIEW: opting out must persist even when queued-report cleanup fails',
    () async {
      SharedPreferences.setMockInitialValues({'diagnostics_sharing_v1': true});
      TestFirebaseCoreHostApi.setup(ReviewFirebaseCore());
      await Firebase.initializeApp();
      var nativeEnabled = true;
      const channel = MethodChannel('plugins.flutter.io/firebase_crashlytics');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'Crashlytics#setCrashlyticsCollectionEnabled') {
              nativeEnabled = (call.arguments as Map)['enabled'] as bool;
              return {'isCrashlyticsCollectionEnabled': nativeEnabled};
            }
            if (call.method == 'Crashlytics#deleteUnsentReports') {
              throw PlatformException(code: 'simulated-cleanup-failure');
            }
            return null;
          });
      Object? thrown;
      try {
        await DiagnosticsService.setEnabled(false);
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isNotNull);
      expect(nativeEnabled, false);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('diagnostics_sharing_v1'),
        false,
        reason:
            'A subsequent initialize reads this value and must not enable sharing again.',
      );
    },
  );
}
