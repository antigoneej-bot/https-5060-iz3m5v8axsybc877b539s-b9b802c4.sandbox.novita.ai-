import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_app/services/diagnostics_service.dart';

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
      pluginConstants: {
        'plugins.flutter.io/firebase_crashlytics': {
          'isCrashlyticsCollectionEnabled': false,
        },
      },
    ),
  ];
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();
  @override
  Future<bool> setValue(String type, String key, Object value) async => false;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/firebase_crashlytics');
  late List<bool> nativeRequests;
  var nativeEnabled = false, failEnable = false, failDisable = false;
  var cleanupCalls = 0;
  Completer<void>? enableStarted, enableReleased;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestFirebaseCoreHostApi.setup(_Core());
    await Firebase.initializeApp();
    DiagnosticsService.enabled.value = false;
    nativeEnabled = false;
    failEnable = false;
    failDisable = false;
    cleanupCalls = 0;
    nativeRequests = [];
    enableStarted = null;
    enableReleased = null;
    final oldFlutter = FlutterError.onError,
        oldAsync = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = oldFlutter;
      PlatformDispatcher.instance.onError = oldAsync;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'Crashlytics#setCrashlyticsCollectionEnabled') {
        final value = (call.arguments as Map)['enabled'] as bool;
        nativeRequests.add(value);
        if (value && enableStarted != null) {
          enableStarted!.complete();
          await enableReleased!.future;
        }
        if (value && failEnable || !value && failDisable) {
          throw PlatformException(code: 'synthetic-sdk-failure');
        }
        nativeEnabled = value;
        return {'isCrashlyticsCollectionEnabled': value};
      }
      if (call.method == 'Crashlytics#deleteUnsentReports') cleanupCalls++;
      return null;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('SDK enable failure rolls back stored consent and collection', () async {
    failEnable = true;
    await expectLater(
      DiagnosticsService.setEnabled(true),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.plugin,
          'plugin',
          'firebase_crashlytics',
        ),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getBool(DiagnosticsService.preferenceKey), false);
    expect(nativeEnabled, false);
    expect(DiagnosticsService.enabled.value, false);
    expect(nativeRequests, [false, true, false]);
  });

  test(
    'failed preference persistence cannot enable collection and still attempts cleanup',
    () async {
      SharedPreferencesStorePlatform.instance = _FailingStore();
      await expectLater(DiagnosticsService.setEnabled(true), throwsStateError);
      expect(nativeRequests, [false]);
      expect(cleanupCalls, 1);
      expect(DiagnosticsService.enabled.value, false);
    },
  );

  test(
    'SDK disable failure still persists opt-out and attempts queued cleanup',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(DiagnosticsService.preferenceKey, true);
      failDisable = true;
      await expectLater(
        DiagnosticsService.setEnabled(false),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.plugin,
            'plugin',
            'firebase_crashlytics',
          ),
        ),
      );
      await prefs.reload();
      expect(prefs.getBool(DiagnosticsService.preferenceKey), false);
      expect(cleanupCalls, 1);
      expect(DiagnosticsService.enabled.value, false);
    },
  );

  test(
    'queued opt-out wins over slow initialization and remains off after reinitialization',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(DiagnosticsService.preferenceKey, true);
      enableStarted = Completer<void>();
      enableReleased = Completer<void>();
      final startup = DiagnosticsService.initialize();
      await enableStarted!.future;
      final optOut = DiagnosticsService.setEnabled(false);
      enableReleased!.complete();
      await startup;
      await optOut;
      await prefs.reload();
      expect(prefs.getBool(DiagnosticsService.preferenceKey), false);
      expect(nativeEnabled, false);
      expect(DiagnosticsService.enabled.value, false);
      nativeRequests.clear();
      await DiagnosticsService.initialize();
      expect(nativeRequests, [false]);
      expect(nativeEnabled, false);
    },
  );
}
