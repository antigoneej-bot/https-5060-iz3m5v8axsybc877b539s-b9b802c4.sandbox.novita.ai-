# 마음냥 정원 — 살아 있는 정원 화면

승인된 정원 시안을 기반으로 만든 Flutter 구현입니다.

## 화면과 동작

- 홈 맨 위와 나의 정원에 동일한 입체 정원 화면을 배치했습니다.
- 별도로 생성한 낮·밤 배경과 투명 고양이 이미지를 WebP로 최적화했습니다.
- 고양이 쓰다듬기, 물레방아 회전, 물빛, 반딧불이/빛 입자, 배경과 캐릭터의 시차를 구현했습니다.
- 시간 버튼은 기기 시간 → 낮 → 밤 순서로 바뀝니다. 자동 모드에서는 06:00–18:59가 낮입니다. 수동 보기는 화면을 나가면 초기화됩니다.
- 움직임 일시 정지, 기기의 동작 줄이기, 앱 비활성 상태를 처리합니다.
- 마음 남기기 → 기존 감정 고양이 선택, 정원 가꾸기 → 기존 나의 정원, 이웃 정원 → 기존 공개 정원 목록으로 연결했습니다.
- 실제 저장된 여섯 종류 씨앗의 수량을 성장 단계로 표시합니다. 식물을 누르면 기존 추억 편집창이 열립니다. 사용하지 않았다고 식물을 시들게 하지 않습니다.
- 기존 장식 배치와 돌봄 나무 화면은 나의 정원의 펼침 영역에 남겨뒀습니다. 배경의 집·버들나무·꽃·물레방아는 기본 풍경이며 보유 장식 아이템이 아닙니다.

## 구현 범위

고품질 3D 렌더 이미지를 여러 레이어로 배치한 2.5D 화면입니다. 자유 회전 카메라, 3D 메시, 관절 애니메이션은 포함하지 않습니다. 모바일에서는 고양이 터치와 환경 애니메이션이 동작하고, 마우스 환경에서는 포인터에 따라 레이어 시차도 생깁니다. 씨앗은 현재 성장 데이터를 보존하는 벡터 표현이며, 3D 식물 모델로 교체하는 작업은 별도입니다.

이번 변경은 정원 화면에 집중했습니다. 고양이 종류, 결제, 편지·답장 저장, 선물 및 공개 정원 서버의 동작은 변경하지 않았습니다. 이웃 정원 연결은 기존 서버 설정·권한에 따릅니다.

## 파일

- `lib/mongi/widgets/living_garden_scene.dart`: 표시·환경·고양이 터치·씨앗 성장
- `lib/mongi/widgets/living_garden_entry.dart`: 기존 정원/추억 저장소 연결
- `lib/screens/home_tab_screen.dart`: 정원 우선 홈 배치
- `lib/mongi/integration/unified_garden_panel.dart`: 새 정원과 기존 장식 배치 연결
- `assets/living_garden/`: 낮·밤·고양이 WebP
- `test/living_garden_scene_test.dart`: 버튼·씨앗·접근성·낮밤·모션 테스트

## 이미지 제작

Built-in ImageGen으로 생성했습니다. 배경: 승인된 시안의 따뜻한 버들나무·오두막·꽃·시냇물 구도를 유지하고 UI와 고양이를 제거한 정원. 밤: 동일 구도를 유지하고 별빛·달빛·따뜻한 창문 조명으로 변경. 고양이: 시안의 오렌지색 아기 고양이를 투명 배경의 독립 캐릭터로 생성. PNG 원본에서 WebP로 형식만 변환했으며 원본 구도와 투명도를 유지했습니다.

## 확인 명령

```sh
flutter pub get
flutter analyze lib/mongi/widgets/living_garden_scene.dart lib/mongi/widgets/living_garden_entry.dart lib/screens/home_tab_screen.dart lib/mongi/integration/unified_garden_panel.dart
flutter test test/living_garden_scene_test.dart test/garden_growth_test.dart test/garden_moments_test.dart test/mongi_garden_data_test.dart
flutter test --update-goldens --dart-define=GARDEN_GOLDENS=true test/living_garden_scene_test.dart
```

## 이번 검증 결과

Flutter 3.35.4 / Dart 3.9.2에서 변경된 화면·연결 파일 4개의 정적 검사를 완료했습니다. 새 화면 테스트 5개와 기존 성장·정원 순간·정원 데이터 테스트를 합쳐 21개가 통과했습니다. `living-garden-day.png`, `living-garden-night.png`는 이미지 시안이 아니라 Flutter 위젯 렌더링 캡처이며, 사랑 3회·평안 10회의 테스트 데이터를 사용합니다. 기기 설치용 APK/AAB 빌드 및 실제 Android/iOS 기기 실행은 이번 작업에서 수행하지 않았습니다.

## 넓은 정원 업데이트

홈의 정원 가꾸기는 이제 넓은 정원 화면으로 연결됩니다. 산책·확대·아이템 배치·공간 해금·저장과 백업은 `EXPANDED_GARDEN.md`를 참고하세요. 기존 고양이·정원 기록 화면은 넓은 정원 상단의 책 아이콘에서 열 수 있습니다.
