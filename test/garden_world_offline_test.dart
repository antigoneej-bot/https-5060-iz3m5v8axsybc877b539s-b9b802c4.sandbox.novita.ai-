import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/garden_world_screen.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Garden extends GardenProvider {
  String? owner = 'alice';
  final requests = <Completer<List<ReceivedCheer>>>[];
  _Garden() {
    gardenMotionEnabled = false;
  }
  @override
  String? get publicGardenAccount => owner;
  @override
  Future<void> ensureInitialized() async {}
  @override
  Future<List<ReceivedCheer>> loadMyPublicCheers() {
    final response = Completer<List<ReceivedCheer>>();
    requests.add(response);
    return response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const offlineMessage = '내 정원은 사용할 수 있어요. 새로 받은 마음은 연결 후 다시 확인해 주세요.';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('garden-offline-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 23))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
  });
  tearDown(() async {
    await StorageService.clearCurrentUser();
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> openGarden(WidgetTester tester, _Garden garden) async {
    final cat = CatCareProvider();
    addTearDown(garden.dispose);
    addTearDown(cat.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
            ChangeNotifierProvider<CatCareProvider>.value(value: cat),
          ],
          child: const MaterialApp(home: GardenWorldScreen()),
        ),
      );
      // The real encrypted local stores use filesystem I/O, so let them finish
      // outside the widget test's fake clock. The server promise stays pending.
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
        if (garden.requests.isNotEmpty) break;
      }
    });
    await tester.pump();
  }

  Future<void> flushNetworkFuture(WidgetTester tester) async {
    // These promises were created alongside real local I/O in runAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump();
  }

  testWidgets(
    'local garden stays usable through slow requests, retries, account changes and exit',
    (tester) async {
      final garden = _Garden();
      await openGarden(tester, garden);
      expect(garden.requests, hasLength(1));
      expect(find.byType(GardenWorldView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(seconds: 50));
      expect(find.byType(GardenWorldView), findsOneWidget);
      garden.requests.single.completeError(StateError('offline'));
      await flushNetworkFuture(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(offlineMessage), findsOneWidget);
      expect(find.byType(GardenWorldView), findsOneWidget);
      await tester.tap(find.text('다시 확인'));
      await flushNetworkFuture(tester);
      expect(garden.requests, hasLength(2));
      garden.requests.last.complete([]);
      await flushNetworkFuture(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());

      // All scenarios share one fake-clock zone, matching the app lifetime of
      // the serialized local stores instead of abandoning their future queues.
      final switchedGarden = _Garden();
      await openGarden(tester, switchedGarden);
      final oldResponse = switchedGarden.requests.single;
      switchedGarden.owner = 'bob';
      oldResponse.completeError(StateError('old account offline'));
      await flushNetworkFuture(tester);
      expect(find.text(offlineMessage), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flushNetworkFuture(tester);
      expect(switchedGarden.requests, hasLength(2));
      switchedGarden.requests.last.complete([]);
      await flushNetworkFuture(tester);
      expect(find.byType(GardenWorldView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());

      final exitedGarden = _Garden();
      await openGarden(tester, exitedGarden);
      final response = exitedGarden.requests.single;
      await tester.pumpWidget(const SizedBox.shrink());
      response.completeError(StateError('offline after exit'));
      await flushNetworkFuture(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(offlineMessage), findsNothing);
    },
  );
}
