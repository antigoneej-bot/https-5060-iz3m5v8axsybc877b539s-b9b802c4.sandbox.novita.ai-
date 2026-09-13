# 서버 연결 안내 — 배포 전 확인 필요

이 폴더는 배포 가능한 형태의 출발점이며 실제 Firebase 프로젝트에 배포하지 않았습니다. Firebase·Play 관리자 설정과 실기기 내부 테스트가 필요합니다. 비밀키를 앱·ZIP·저장소에 넣지 마세요.

## 1. Firebase와 Play 준비

- 앱에서 사용하는 Firebase 프로젝트와 Android 등록 정보를 확인합니다. 이메일/비밀번호 인증과 이메일 인증 메일을 설정합니다.
- Firestore, 기본 Cloud Storage 버킷, Cloud Functions 실행에 필요한 결제·API 설정을 준비합니다. 예산 알림을 설정하고 예상 트래픽으로 비용을 확인합니다.
- App Check의 Play Integrity에 실제 앱 서명 SHA-256과 배포 경로를 등록합니다. 코드의 `GARDEN_ANDROID_APP_ID`는 Android 패키지명이 아니라 Firebase Android 앱 ID입니다.
- Functions 실행 서비스 계정에 Google Play의 해당 앱 구매 조회·구독 관리에 필요한 권한을 부여하고 Google Play Developer API를 활성화합니다. 런타임 기본 인증을 사용하며 앱 안에 서비스 계정 JSON을 배포하지 않습니다.
- 패키지 `com.mysticcat.journal`, 상품 `garden_plus_monthly`, `garden_plus_yearly`가 실제 Play Console과 일치하는지 확인합니다.
- Pub/Sub `play-rtdn` 토픽에 Google Play의 실시간 개발자 알림을 연결합니다. Google의 알림 게시 계정에 해당 토픽 Publisher 권한을 주고 테스트 알림을 확인합니다.

공식 참고:
- [App Check / Play Integrity 설정](https://firebase.google.com/docs/app-check/android/play-integrity-provider)
- [구독 상태와 외부 계정 식별자](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2)
- [실시간 개발자 알림 설정](https://developer.android.com/google/play/billing/getting-ready#configure-rtdn)
- [Flutter Google Play 구매 인자](https://pub.dev/documentation/in_app_purchase_android/latest/in_app_purchase_android/GooglePlayPurchaseParam-class.html)

## 2. 설치·배포

Node 22와 Firebase CLI가 있는 관리자 개발 환경에서 실행합니다. 아래 값은 실제 프로젝트 값으로 교체해야 합니다.

```bash
cd backend
npm install
npm test
cp .env.example .env
```

`.env`의 `GARDEN_ANDROID_APP_ID`를 설정하고 프로젝트 루트로 돌아와 배포합니다. **동봉 규칙은 모든 클라이언트 직접 접근을 차단하므로, 다른 앱과 공유하는 Firebase 프로젝트라면 기존 규칙을 검토·병합한 뒤 배포해야 합니다.** 관리 SDK를 사용하는 이 서버만 저장소에 접근하도록 의도했습니다.

```bash
firebase deploy --project YOUR_PROJECT_ID --only functions,firestore:rules,storage
```

Functions 런타임 인증·권한, 기본 Storage 버킷 및 RTDN 토픽을 확인합니다. 배포 결과의 gardenApi HTTPS URL을 사용합니다.

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define=GARDEN_BACKEND_URL=YOUR_HTTPS_GARDEN_API_URL
```

Play 내부 테스트에서 설치하고 App Check가 통과하는지 확인합니다. 운영 검증을 통과시키려고 App Check나 계정 소유권 검사를 제거하지 마세요. URL 없는 빌드는 기존 로컬 구독 판정이며 서버 기능은 비활성입니다. 현재 구현은 Android Play 대상입니다.

## 3. 계정과 기존 구매 이전

신규 구매는 이메일 인증된 Firebase UID의 SHA-256 값을 Play 구매의 계정 식별자로 전달합니다. 실제 플러그인 버전에서 Google 조회 응답의 `obfuscatedExternalAccountId`가 동일한지 반드시 내부 구매로 확인합니다. 토큰 소유권은 트랜잭션으로 고정하며 다른 계정이 가져갈 수 없습니다.

과거 구매는 이 식별자가 없을 수 있습니다. 구매 토큰을 처음 제출한 계정에 무조건 연결하지 않도록 `purchase-migration-required`로 차단했습니다. 기존 구독자의 검증된 소유권을 이전하는 운영 절차/관리 도구는 아직 없습니다. 영수증 제출만으로 자동 연결하지 말고 소유권 확인·지원·감사 절차를 마련한 뒤 이전하세요. 이전 전 기존 사용자의 구독이 갑자기 차단되는 서버 모드 전환은 출시하지 마세요.

계정 삭제는 해당 백업·계정·검증 정보를 삭제하고 재사용 방지용 구매 토큰 해시 표식만 남깁니다. Play 구독은 별도로 남습니다. 백업 삭제 실패·중간 실패 재시도와 동시 요청은 통합 테스트에서 확인해야 합니다.

## 4. 반드시 확인할 통합 시나리오

- 구매→Google 검증→구매 승인→권한 반영, 복원, 갱신, 갱신 취소 후 만료일까지 접근, 만료·보류·환불, 네트워크 실패 재시도.
- 다른 Firebase 계정의 구매 토큰 제출, 다른 앱 App Check 토큰, 이메일 미인증, 잘못된 토큰으로 권한이나 데이터가 열리지 않는지.
- RTDN이 실제 Google 최신 상태를 반영하는지. 지연·중복·재시도에도 사용자 권한이 적절한지.
- 두 계정의 서버 백업 목록·복원·삭제가 격리되는지. 암호 오류와 파일 변조 시 기존 기기 데이터가 유지되는지.
- 백업 11개 업로드 후 최근 10개 보존, 실패 시 이전 백업 유지, 구독 종료 후 기존 백업 복원.
- 현재는 서버 판정의 보안 저장소 캐시를 최대 48시간, 실제 만료일 이내에서 허용합니다. 따라서 기기 오프라인 권한 회수는 즉각적이지 않습니다. 서버 백업 API는 매번 Google 상태를 확인합니다.
- 장기 구독자의 구매 토큰 누적 시 Google 조회 시간·쿼터, 대용량 백업, 계정 삭제 도중 요청, 함수 오류 재시도를 부하/통합 테스트합니다. 예산·속도 제한·보존 정책은 출시 운영 조건에 맞게 확정합니다.

보안 규칙·관리자 IAM·삭제 후 보존되는 사업자 백업 및 로그 정책까지 확인해야 실제 저장/삭제 보장을 설명할 수 있습니다. 코드만으로 운영 환경의 보안을 검증한 것은 아닙니다.
