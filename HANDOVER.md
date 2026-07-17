# 고양이 그림자 정원 - 개발자 인수인계 문서

작성일: 2025년 최초 작성 / 2026년 최종 업데이트 (인수인계 시점)

이 문서는 "고양이 그림자 정원"(Mystic Cat Journal) Flutter 앱을 이어서 개발할 개발자를 위한 인수인계 문서입니다.

> ⚠️ **계약 관련 상세 내용**(견적 항목별 금액, 계약 범위와 코드 미완성 항목의 1:1 매핑)은 별도 문서 `개발_인수인계_문서.md`(또는 전달받은 리포트 폴더)를 함께 참고하세요. 이 문서(HANDOVER.md)는 코드/기술 관점의 인수인계에 집중합니다.
>
> **확정 계약: 베로 / A + B-1(최소 출시형) / 112만원(부가세 별도)** — Google Play 결제 연동, 로그인 UI 정리, Hive 데이터 암호화, 스토어 배포 정리가 계약 범위에 포함되어 있으며, 이는 정확히 아래 3번 항목(미완성 항목)과 대응됩니다.

---

## 1. 앱 개요

- **앱 이름**: 고양이 그림자 정원 (Mystic Cat Journal)
- **패키지명(Android)**: `com.mysticcat.journal`
- **한 줄 소개**: 사용자가 자신의 "그림자 고양이"를 돌보며 편지를 쓰고, 마음의 온도를 기록하고, 주간/월간으로 회고하는 감성 저널링 앱
- **주요 기능**:
  - 인트로(비디오) → 웰컴투어(온보딩 투어, 고양이 이름 짓기) → 홈
  - 홈 화면에서 고양이 선택 및 케어(다마고치식 마음 온도 관리)
  - 편지쓰기(저널링) — 마음 온도(before/after) 기록
  - 첫 편지쓰기 시점에 자연스럽게 "가입 유도" 온보딩(소셜 로그인 선택 + 알림 동의) 노출
  - 히스토리(편지 목록) 조회
  - 주간/월간 그림자 회고(reflection) 기능
  - 프리미엄('정원 플러스') 구독 화면 — **결제 미연동 (아래 3번 항목 참고)**
  - 마이페이지(피드백, 설정 등)
  - 묘연(猫緣) 나누기 — 두 사용자가 만난 고양이 조합으로 궁합 코드를 생성/교환하는 소셜 공유 기능
  - 로컬 행동 계측(Analytics) — 편지작성/공유/구독조회 등 12개 이벤트 + D1/D3/D7/D14/D30 리텐션 마일스톤을 기기 로컬에 기록 (Firebase 미연결, 아래 3.6 참고)

---

## 2. 기술 스택

- **Flutter**: 3.35.4 / **Dart**: 3.9.2 (환경 고정, 업그레이드 비권장)
- **상태관리**: Provider (`provider: 6.1.5+1`)
- **로컬 저장소**:
  - `hive` + `hive_flutter` — 편지(LetterEntry), 회고 편지(ReflectionLetterEntry) 등 문서형 데이터
  - `shared_preferences` — 스트릭(연속 방문일), 온보딩/가입 완료 여부, 알림 설정 등 키-값 데이터
  - **⚠️ Firebase는 사용하지 않음** — 모든 데이터는 기기 로컬에만 저장됩니다. 클라우드 동기화나 여러 기기 간 데이터 공유가 필요하다면 Firebase 또는 다른 백엔드 연동이 추가로 필요합니다.
- **주요 패키지**: `google_fonts`, `video_player`, `audioplayers`, `flutter_local_notifications`, `share_plus`, `url_launcher`, `package_info_plus`

전체 의존성은 `pubspec.yaml` 참고.

---

## 3. ⚠️ 미완성/더미(placeholder) 구현 항목 — 반드시 확인 필요

### 3.1 구독/결제 (`lib/services/subscription_service.dart`)
- **현재 상태**: 실제 Google Play 인앱결제(In-App Purchase)가 연결되어 있지 않습니다.
- 구독 상태는 `SharedPreferences`에만 저장되는 임시 구현이며, `purchasePremium()` 호출 시 결제 없이 즉시 프리미엄 처리됩니다.
- 파일 상단에 상세한 TODO 가이드 주석이 이미 작성되어 있습니다. 요약하면:
  1. `pubspec.yaml`에 `in_app_purchase` 패키지 추가
  2. Google Play Console에 앱 등록 후 구독 상품(예: `garden_plus_monthly`) 생성
  3. `purchasePremium()` 내부 구현을 실제 구매 플로우로 교체, 구매 성공 콜백에서 `setPremium(true)` 호출
  4. 앱 시작 시 `restorePurchases()`를 스토어 기준 복원 로직으로 교체
- `PremiumScreen`, `MonthlyShadowReflectionScreen` 등 다른 화면은 `SubscriptionService`의 퍼블릭 API(`isPremium`/`purchasePremium`/`cancelPremium`)만 사용하므로, **내부 구현만 교체하면 다른 화면은 수정할 필요 없습니다.**
- 표시 가격: `SubscriptionService.displayPrice` = `'월 2,500원'`, `displayYearlyPrice` = `'연 15,000원'` (출시 기념 얼리버드 특가 문구 포함, 실제 스토어 상품 가격과 일치시켜야 함)
- **⚠️ Google Play 정책 리스크**: 결제 연동 전까지 프리미엄 기능을 실제로 열어둔 채 출시하면 "결제 없이 잠금 해제되는 가짜 결제 버튼"으로 정책 위반 소지가 있습니다. 결제 연동 전에는 프리미엄 화면을 노출만 하고 실제 구매 버튼은 비활성화하거나 숨기는 것을 권장합니다.

### 3.2 소셜 로그인 (`lib/screens/onboarding_flow_screen.dart`)
- 카카오/Apple/Google 로그인 버튼이 있으나, **실제 OAuth 인증이 연결되어 있지 않습니다.**
- `_onChooseProvider()`에서 버튼 클릭 시 `StorageService.setLoginProvider(provider)`를 호출하고 즉시 성공 처리합니다 (실제 인증 서버 통신 없음).
- 실제 로그인을 구현하려면:
  - 카카오: `kakao_flutter_sdk` 연동
  - Apple: `sign_in_with_apple` 연동
  - Google: `google_sign_in` 연동
  - 이후 서버(백엔드) 또는 Firebase Auth와 연계하여 실제 사용자 인증/세션 관리 필요
- **참고**: 이 앱은 로그인 여부와 무관하게 로컬에만 데이터를 저장하는 구조이므로, 로그인을 "완료" 표시로만 사용 중입니다(가입 여부 플래그 역할). 실제 계정 시스템이 필요하다면 백엔드 연동이 선행되어야 합니다.

### 3.3 회원가입/온보딩 게이팅 로직 (`lib/main.dart`)
- `StorageService.isOnboardingCompleted()`(=회원가입 완료 여부) 값에 따라 앱 실행 시 비디오 인트로 + 웰컴투어를 다시 보여줄지 결정합니다.
- 웰컴투어를 마치면 고양이 선택 탭으로 이동하며, "가입 유도" 온보딩(소셜 로그인 + 알림 동의, `OnboardingFlowScreen`)은 **사용자가 처음 편지쓰기 버튼을 누르는 시점**(`meditation_flow_screen.dart`)에서 자연스럽게 트리거됩니다.
- 이 흐름은 사용자 피드백을 반영해 여러 차례 조정된 결과이므로, 변경 시 아래 순서를 유지해 주세요:
  1. 미가입 상태 → 앱 실행마다 비디오 인트로 + 웰컴투어 반복
  2. 웰컴투어 완료 → 고양이 선택 탭
  3. 첫 편지쓰기 시도 → 온보딩(소셜 로그인 선택 + 알림 동의) 자연 노출 → 완료 시 다시는 노출 안 됨

### 3.4 마음 온도(Mind Temperature) 초기값
- 모든 마음 온도 관련 시작값/기본값은 **0**으로 설정되어 있습니다(사용자 요청에 따른 최종 값).
  - `lib/services/cat_care_service.dart`: `startTemperature = 0`
  - `lib/providers/app_state_provider.dart`: `tempBefore`/`tempAfter` 초기값 및 `reset()`/`selectCat()` 내부 값 = 0
  - `lib/models/letter_entry.dart`: `fromMap`의 fallback 값 = 0
- 이 값들을 다시 변경할 경우 위 3곳(및 관련 UI 슬라이더의 min/max, 초기 표시값)을 모두 함께 확인해야 합니다.

### 3.5 로컬 데이터 보안 (Hive 암호화)
- 현재 `lib/services/storage_service.dart`에서 사용하는 Hive 박스(편지/회고/짧은메모 등)는 **암호화되어 있지 않습니다.** 민감한 개인 일기 내용이 기기에 평문으로 저장됩니다.
- 계약 범위(B-1)에 "일기(Hive) 암호화, Android 백업 차단"이 포함되어 있으니, 암호화 박스(`Hive.openBox` + `HiveAesCipher`) 적용과 `AndroidManifest.xml`의 `android:allowBackup` 설정을 함께 확인해 주세요.

### 3.6 Analytics (선택, `lib/services/analytics_service.dart`)
- Firebase Analytics가 연결되어 있지 않아, 모든 이벤트는 로컬(SharedPreferences 카운터 + 디버그 콘솔 출력)에만 기록됩니다. 즉 "한 기기 안의 행동 합계"만 확인 가능하고, 여러 사용자에 걸친 실제 D1/D7/D30 리텐션은 알 수 없습니다.
- 파일 상단 주석에 Firebase 연결 4단계가 안내되어 있습니다. 핵심은 `_log()` 메서드 한 곳만 `FirebaseAnalytics.instance.logEvent(...)` 호출로 교체하면, 호출부(편지작성/공유/구독 등 12개 이벤트) 전체는 수정 없이 그대로 Firebase로 전송됩니다.
- 디버그 빌드에서는 마이페이지 > "(개발자용) 로컬 지표 확인"에서 누적 이벤트/리텐션 마일스톤 도달 여부를 확인할 수 있습니다 (`lib/screens/analytics_debug_screen.dart`).
- 이 항목은 계약 범위(B-1) 밖이며, 없어도 출시에는 지장이 없습니다.

### 3.7 릴리즈 서명 키
- `android/key.properties`와 `android/release-key.jks`가 이미 생성되어 있으며, `android/app/build.gradle.kts`에 release 서명 설정이 연결되어 있습니다.
- **⚠️ 이 두 파일은 `.gitignore`에 등록되어 Git에는 포함되지 않습니다.** 별도로 안전하게 전달되니, 개발자는 동일한 위치(`android/key.properties`, `android/release-key.jks`)에 배치해야 릴리즈 빌드가 정상 동작합니다.
- **비밀번호/키 정보는 이 문서가 아닌 별도 채널로 전달됩니다.** (아래 "전달 파일 목록" 참고)
- 이후 Google Play Console에 업로드할 때는 **반드시 동일한 키스토어를 계속 사용**해야 합니다(키를 바꾸면 앱 업데이트가 불가능해집니다). 분실하지 않도록 안전하게 보관하세요.

---

## 4. 프로젝트 구조

```
lib/
  main.dart                      # 앱 진입점, 인트로/온보딩 게이팅 로직
  theme.dart                     # 앱 전역 테마
  models/                        # 데이터 모델 (LetterEntry, ShadowCat, ReflectionLetterEntry 등)
  providers/                     # Provider 상태관리 (AppStateProvider, CatCareProvider 등)
  screens/                       # 화면 위젯들
  services/                      # 비즈니스 로직/저장소 (StorageService, CatCareService, SubscriptionService 등)
  widgets/                       # 재사용 위젯
  utils/                         # 유틸리티 (cat_palette.dart 등)

android/
  app/build.gradle.kts           # 릴리즈 서명 설정 포함
  key.properties                 # 서명 키 정보 (Git 미포함, 별도 전달)
  release-key.jks                # 서명 키스토어 (Git 미포함, 별도 전달)

assets/
  cards/, cards36/, icon/, audio/, video/, nav_icons/, growth/, onboarding_intro/
```

---

## 5. 개발자가 해야 할 일 (체크리스트)

### 계약 범위 (베로, A+B-1, 112만원) — 반드시 진행
- [ ] `android/key.properties`, `android/release-key.jks`를 전달받은 대로 정확한 위치에 배치
- [ ] `flutter pub get` 실행 후 `flutter build apk --release`로 빌드 검증
- [ ] **실제 결제 연동**: Google Play 인앱결제 구독 상품 연동, 구매·복원, 로컬 무료 프리미엄 부여 제거 (3.1 참고)
- [ ] **로그인 UI 정리**: 가짜 소셜 로그인 제거 또는 '로컬로 계속' 플로우로 정리 (3.2 참고)
- [ ] **로컬 데이터 암호화**: 일기(Hive) 암호화, Android 백업 차단 (3.5 참고)
- [ ] **스토어 배포 기반 정리**: 릴리즈 서명 최종 점검, applicationId 확정, 페이월 문구·잠금 정합 확인, 개인정보처리방침·문의처 정리
- [ ] Google Play Console 앱 등록 및 스토어 등록 정보(스크린샷, 설명, 개인정보처리방침 URL 등) 준비
- [ ] 실제 배포 전 `flutter analyze` 및 전체 QA(웰컴투어 → 편지쓰기 → 온보딩 → 히스토리 → 회고 → 프리미엄 화면 → 묘연 나누기) 진행

### 계약 범위 밖 (선택, B-2 또는 별도 협의 필요)
- [ ] 실제 소셜 로그인(Google/카카오/Apple) SDK 연동 (3.2 참고) — 계약은 "가짜 로그인 UI 정리"까지만 포함, 실 연동은 B-2 범위
- [ ] 클라우드 동기화가 필요하면 Firebase 또는 자체 백엔드 도입 검토 — 현재는 완전히 로컬 전용 앱
- [ ] Firebase Analytics 연결 (3.6 참고) — 없어도 출시 가능
- [ ] 알림 권한(`flutter_local_notifications`) 관련 Android 13+ 런타임 권한 재점검

---

## 6. 알려진 이슈 / 참고사항

- Google 로그인 화면에서 로딩이 멈추는 현상이 이전에 보고된 적이 있으나, 실제 OAuth 연동이 없는 더미 구현이므로 3.2 항목(실 연동) 진행 시 함께 해결될 것으로 예상됩니다.
- 피드백 수신 이메일: `antigone.ej@gmail.com` (`lib/screens/my_screen.dart`) — 실제 운영 주소로 설정되어 있으니 변경 시 주의하세요.
- iOS 관련 설정(`ios/Runner/Info.plist`)은 앱 이름만 동기화되어 있으며, 이 프로젝트는 Android/Web 중심으로 개발되었기 때문에 iOS 빌드는 별도로 검증되지 않았습니다. iOS 출시 시 추가 점검이 필요합니다.

---

## 7. 전달 파일 목록

1. **릴리즈 APK** (`app-release.apk`, 서명 완료) — 바로 설치/테스트 가능
2. **전체 소스코드** (압축본, `.git` 히스토리 포함)
3. **이 인수인계 문서** (`HANDOVER.md`)
4. **서명 키 정보** (`android/key.properties`, `android/release-key.jks`) — 별도 채널로 전달 (보안상 소스코드 압축본에는 포함되어 있을 수 있으니, 전달받은 즉시 안전한 곳에 별도 보관하고 필요 시 압축본에서 제거 후 재배포하는 것을 권장합니다)
