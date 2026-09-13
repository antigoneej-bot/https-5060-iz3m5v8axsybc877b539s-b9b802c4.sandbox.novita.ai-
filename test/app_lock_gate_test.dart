import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/app_lock_service.dart';
import '../lib/widgets/app_lock_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(AppLockService.channel, null);
  });
  testWidgets('locked app hides records and canceled authentication keeps them hidden', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var accept = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(AppLockService.channel, (call) async {
      if (call.method == 'isEnabled') return true;
      return accept;
    });
    await tester.pumpWidget(MaterialApp(builder: (_, child) => AppLockGate(child: child!), home: const Scaffold(body: Text('PRIVATE_RECORD'))));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE_RECORD'), findsNothing);
    await tester.tap(find.text('휴대전화 잠금으로 열기'));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE_RECORD'), findsNothing);
    accept = true;
    await tester.tap(find.text('휴대전화 잠금으로 열기'));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE_RECORD'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('PRIVATE_RECORD'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('PRIVATE_RECORD'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
