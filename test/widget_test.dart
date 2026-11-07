import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // MysticCatApp은 initState에서 곧바로 SharedPreferences/Hive에 접근하는
    // 여러 서비스를 초기화합니다. 실제 앱 실행(main())에서는 이 초기화가
    // main() 함수 안에서 먼저 끝나 있지만, 위젯 테스트는 그 부트스트랩을
    // 거치지 않고 바로 위젯을 pump하므로 여기서 동일한 초기화를 해줘야 합니다.
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('flutter_app_test_');
    Hive.init(tempDir.path);
    // flutter_secure_storage 는 테스트 환경에 플랫폼 구현이 없어 mock
    // 핸들러를 등록하지 않으면 read() 호출이 응답을 영원히 받지 못한 채
    // 멈춥니다. HiveEncryption 이 이 read 에 타임아웃을 두게 되면서(실제
    // 기기/브라우저에서 이 호출이 멈추는 문제를 막기 위한 수정) 테스트에도
    // 타이머가 생겨, 응답이 없으면 "Timer is still pending" 으로 테스트가
    // 실패하게 되었습니다. 실제 서비스와 동일하게 mock 응답을 등록해
    // read 가 즉시 끝나도록 합니다.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            null,
          );
    });

    await tester.pumpWidget(const MysticCatApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
