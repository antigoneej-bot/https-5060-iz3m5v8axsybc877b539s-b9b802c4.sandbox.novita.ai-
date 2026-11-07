# 식빵 자세·골골송 수정안 (63, Flutter 빌드 미검증)

이 패키지는 검증된 1.0.59(62)에 적용하는 별도 수정안입니다. 기존 정식 작업 소스 및 APK/AAB를 대체하지 않습니다.

## 동작
- 정원 하단 ‘식빵 쉬기’ 버튼: 선택한 고양이가 앞발을 몸 밑에 넣고 눈을 감은 자세로 휴식. 다시 누르면 해제. 산책 동작을 선택해도 해제.
- 기존 휴식 상황과 고양이 돌보기의 휴식 상호작용에도 식빵 그림을 사용.
- 몸이 아주 작게 오르내리는 숨쉬기. 움직임 줄이기 설정과 화면 비활성 상태에서는 정지.
- 기존 sfx_purr.mp3를 사용하며 효과음 설정을 따름. 정원에서는 8초 간격으로 골골송 재생. 여러 고양이가 쉬어도 한 마리만 소리를 맡음. 화면 종료·가림·앱 백그라운드·효과음 끄기 시 정지.
- 산책에서는 사용자가 ‘잠깐 쉬기’를 누른 경우만 골골송 시작. 식빵 그림을 휴식 카드에서 확인. 시간·보상·이동은 멈추고 이어서 산책하면 계속 진행. 산책 중 자동 멈춤 추가 없음.
- 6종 동반 고양이 무늬 대응. 기본 고양이는 새 치즈 식빵 자세 사용. 기존 서기·걷기·성장 자산은 그대로 유지.

## 적용
먼저 기존 Flutter 프로젝트를 별도 복사하여 백업하세요. 수정 패키지의 flutter_app 폴더 안 파일을 기존 62번 프로젝트의 같은 경로에 덮어쓰면 됩니다. 이 ZIP은 전체 프로젝트가 아니라 변경된 파일과 새 이미지입니다.

Flutter 환경에서 다음을 수행한 뒤 빌드하세요:
```
flutter pub get
dart format lib/widgets/companion_loaf_art.dart lib/widgets/companion_presence.dart lib/mongi/widgets/garden_ambient.dart lib/mongi/widgets/garden_world_view.dart lib/screens/cat_walk_screen.dart lib/services/sound_service.dart
flutter analyze
flutter test
node tool/test_cat_walk.cjs
```

## 검증 상태
- JavaScript 회귀 검사 실행 통과: 기존 수집/보상/대사/휴식/재개/엽서, 수동 휴식에서 식빵 켜짐, 휴식 중 시간·보상 진행 정지, 재개 시 해제, 백그라운드 휴식에서 골골송 요청하지 않음.
- 이미지 원본 RGBA 알파 확인, 6종 프레임 측정. 원래 이미지 파일들은 변경하지 않음.
- Flutter SDK가 현재 환경에 없고 공식 다운로드 시도가 HTTP 404로 실패. Flutter 정적 분석·위젯 테스트·실기기·APK/AAB/iOS 빌드는 미실행.
- 출시 판정 또는 전체 테스트 통과를 의미하지 않음. 62번 APK에 자동 반영되지 않음.
- 실제 기기에서 식빵 크기/접지선, 6종별 프레임 경계, 화면 전환 시 소리 정지, 음악 동시 재생 및 음량 확인 필요.

## 새 그림
내장 이미지 생성 도구로 생성. 기존 companion_coats.png를 참고하여 3열×2행, 치즈/흰색/고등어/검정/턱시도/삼색 순서로 앞발을 완전히 접은 식빵 자세·감은 눈·몸에 감긴 꼬리·투명 배경을 요청했습니다. assets/living_garden/companion_loaf.png에 원본 그대로 포함합니다.
