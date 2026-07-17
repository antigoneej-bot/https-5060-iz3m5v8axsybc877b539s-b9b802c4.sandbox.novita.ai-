import 'dart:io';

import 'package:flutter/material.dart';
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
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    await tester.pumpWidget(const MysticCatApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
