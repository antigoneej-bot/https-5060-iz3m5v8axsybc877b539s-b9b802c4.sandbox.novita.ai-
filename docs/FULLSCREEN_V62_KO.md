# 1.0.59 (62) 산책 전체 화면·정원 작은 버튼

- 산책 시작 시 현재 방향으로 전체 화면 진입. 오른쪽 위 회전 버튼으로 가로/세로 전환, 해제 버튼 또는 Android 뒤로 가기로 일반 화면 복귀.
- 고정 16:9 영상을 늘리지 않고 화면 비율에 맞춰 캔버스 폭과 고양이 위치를 다시 계산. 배경·고양이 비율 유지.
- 산책의 휴식, 마치기, 점프, 음악, 숨은 보물, 보상, 엽서 기능 유지. 작게 표시하되 주요 버튼의 터치 높이는 44px 이상 유지.
- 정원 가로 하단 기능 버튼 최소 높이 72→48, 아이콘 28→18, 글자 16→12. 가로에서만 적용. 꾸미기 패널 위치 조정.
- 기존 고양이·음악·감정 기록·구독 혜택·정원 자산 유지. 산책 보상은 기존과 같이 체험용이며 실제 창고 적립은 하지 않음.
- Android 30 이상은 WindowInsetsController로 시스템 바 숨김/복귀 처리. 화면 가장자리 스와이프로 시스템 바를 다시 표시 가능. 화면 종료 시 회전 및 시스템 바 복구. 기존 개인정보 화면 잠금(FLAG_SECURE) 처리 유지.

## 검증

Flutter 관련 테스트 27개 통과. 기존 산책 JavaScript 회귀 테스트 및 세로 360×800 / 가로 800×360 캔버스 좌표 검사 통과. 가로 정원 버튼 크기·전체 캔버스·기능 호출 검사 포함.

실행 명령:

```
flutter test --no-pub test/cat_walk_screen_test.dart test/garden_fullscreen_test.dart test/garden_world_view_test.dart test/healing_activities_test.dart
node tool/test_cat_walk.cjs
flutter analyze --no-pub lib/screens/cat_walk_screen.dart lib/mongi/widgets/garden_world_view.dart lib/mongi/screens/garden_world_screen.dart
```

전체 Flutter 테스트 전체를 재실행한 결과가 아닌 관련 범위 테스트 결과임. 정적 분석에는 기존 스타일 정보 메시지가 남음. 실제 Android/iOS 기기는 미검증. 브라우저 화면 검사는 Chromium 다운로드 실패로 실행하지 못함. Flutter 정원 가로 화면은 테스트 렌더링으로 확인.

## 설치 후 확인

1. 세로에서 산책 시작 → 전체 화면, 휴식/재개/보상/엽서 확인.
2. 회전 버튼으로 가로·세로 반복 전환 → 고양이 비율·수집 동작 유지 확인.
3. 카메라 구멍/노치/하단 제스처 영역에 버튼이 겹치지 않는지 확인.
4. Android 15/16에서 상태 바 숨김, 가장자리 스와이프 표시, 뒤로 가기 해제, 다른 화면 복귀 확인.
5. 백그라운드·화면 잠금 후 복귀, 키보드로 호칭 입력 후 시작, 기존 앱 음악 유지 확인.
6. 가로 정원에서 물주기/씨앗/꾸미기/창고/전체보기/확대·축소 확인.

Google Play 업로드 및 실제 배포는 실행하지 않음. 이전 감사 버전의 출시 차단 항목과 테스트용 보상 상태는 이번 UI 변경으로 해소되지 않음.

구현 참고: https://developer.android.com/develop/ui/views/layout/immersive
