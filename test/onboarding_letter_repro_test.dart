// 사용자가 보고한 "편지를 저장하지 못했어요" 버그를 실제 위젯 트리에서
// 그대로 재현하기 위한 진단용 테스트. 좌표 클릭 기반 브라우저 자동화가
// Flutter Web 캔버스에서 신뢰할 수 없었기 때문에, 동일한 코드 경로를
// 위젯 테스트로 직접 구동합니다.
//
// 주의: 배경(StarsBackground)에 repeat()으로 무한 반복되는
// AnimationController가 있어 pumpAndSettle()은 절대 끝나지 않습니다.
// 반드시 pump(Duration)만 사용합니다.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/screens/onboarding_flow_screen.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';

void main() {
  testWidgets('온보딩 화면에서 편지 보내기 - 저장 실패 재현 시도', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('onboarding_repro_');
    Hive.init(tempDir.path);
    addTearDown(() => tempDir.deleteSync(recursive: true));

    await StorageService.init();
    await StorageService.setCurrentUser('local_user');
    CatCareService.setCurrentUser('local_user');

    final cat = shadowCats.first;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => CatCareProvider()),
        ],
        child: MaterialApp(
          home: OnboardingFlowScreen(cat: cat),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(
      textFieldFinder,
      '오늘은 그냥 나를 내려놓고 물흐르듯 흘렀어. 그러니 마음이 편안해지고 즐거웠어.',
    );
    await tester.pump();

    final sendButtonFinder = find.text('보내기');
    expect(sendButtonFinder, findsOneWidget);
    await tester.tap(sendButtonFinder);
    await tester.pump(); // busy=true, sending 단계로 전환

    // _onSendLetter 내부 최소 표시시간(1400ms) 경과
    await tester.pump(const Duration(milliseconds: 1500));
    // saveOnboardingLetter의 비동기 저장/후처리 완료 대기 (여러 프레임)
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final failureSnackbar = find.text('편지를 저장하지 못했어요. 다시 보내 주세요');
    if (failureSnackbar.evaluate().isNotEmpty) {
      fail('편지 저장이 실패했습니다! (재현 성공 - 원인 조사 필요)');
    }

    expect(find.text('이 편지, 계속 이어가고 싶다면'), findsOneWidget);
  });
}
