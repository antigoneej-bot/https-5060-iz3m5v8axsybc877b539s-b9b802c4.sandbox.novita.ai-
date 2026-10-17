# 간편 로그인 서버 설정

이 파일은 코드에 필요한 서버 설정을 설명합니다. 실제 콘솔 설정 및 배포 완료를 뜻하지 않습니다. 앱 빌드 설정과 각 제공사 콘솔 절차는 `../docs/SOCIAL_LOGIN_SETUP_KO.md`를 함께 확인하세요.

## 로그인 경로

- Google: 앱의 Google 인증 → Firebase Auth 자격 증명 → 서버에서 검증한 Firebase ID 토큰.
- 카카오·네이버·Facebook: 앱 `start` 요청 → 제공사 브라우저 동의 → `socialAuth` HTTPS 콜백 → 앱 전용 callback → 앱 `exchange` → Firebase custom token 로그인.
- provider의 검증된 ID만 계정 식별에 사용합니다. 이메일 주소가 같아도 계정을 자동으로 합치지 않으며, 제공사 이메일을 Firebase 인증된 이메일로 꾸미지 않습니다.
- Facebook은 앱 범위 사용자 ID를 사용합니다. 다른 Facebook 앱 ID로 교체하면 같은 사람도 다른 계정이 될 수 있으므로 운영 App ID를 유지하세요.

## 환경값

| 종류 | 이름 | 값 |
| --- | --- | --- |
| 환경변수 | `SOCIAL_AUTH_CALLBACK_URL` | 실제 배포한 `socialAuth` 함수의 HTTPS URL 자체. `/callback`을 덧붙이지 않습니다. 앱의 `SOCIAL_AUTH_URL`과 정확히 일치해야 합니다. |
| 환경변수 | `GARDEN_ANDROID_APP_ID` | Firebase Android App ID. 패키지명과 다릅니다. |
| 환경변수 | `KAKAO_CLIENT_ID` | 카카오 REST API 키 |
| 환경변수 | `NAVER_CLIENT_ID` | 네이버 Client ID |
| 환경변수 | `FACEBOOK_APP_ID` | 운영 Meta App ID |
| 환경변수 | `FACEBOOK_GRAPH_VERSION` | 운영 앱에서 지원하는 Graph API 버전. 예: `v26.0`. 필수값이며 기본 버전은 없습니다. |
| Secret Manager | `KAKAO_CLIENT_SECRET` | 카카오 Client Secret |
| Secret Manager | `NAVER_CLIENT_SECRET` | 네이버 Client Secret |
| Secret Manager | `FACEBOOK_APP_SECRET` | Meta App Secret |

세 가지 Secret은 함수 배포 설정에 모두 바인딩됩니다. 아직 사용할 수 없는 제공사는 Client ID를 비워 두어 시작 단계부터 차단하세요. 앱/웹 소스와 빌드 define에는 Client Secret을 넣지 마세요.

## 보안과 운영

- `start`와 `exchange`는 해당 Android 앱의 유효한 Firebase App Check 토큰을 요구합니다. 제공사가 호출하는 HTTPS 콜백만 App Check 대상에서 제외되며, 대신 일회용 서버 `state`를 확인합니다.
- 앱과 서버 사이에는 S256 proof를 사용합니다. 이 proof는 서버의 일회용 로그인 세션 교환을 보호하며, 제공사의 OAuth 자체에 PKCE를 추가했다고 주장하지 않습니다.
- 브라우저 및 앱 callback URL에는 불투명한 세션 값만 전달합니다. 제공사 access token·secret·Firebase token은 callback에 넣지 않습니다.
- Facebook은 `public_profile`만 요청하고 `/debug_token`으로 앱 ID, USER 유형, 유효 상태, 사용자 ID, 제공된 만료 시각을 확인합니다. `/me?fields=id`의 ID가 일치해야 하며 서버의 `appsecret_proof`를 사용합니다.
- Meta의 문서화된 code 교환 GET 요청에는 secret이 query에 포함됩니다. HTTP 라이브러리의 요청 URL/응답 원문 로깅을 켜지 마세요. 이 구현은 이를 로깅하지 않고 외부 redirect도 따르지 않습니다.
- `socialAuthSessions`, `socialAuthStates`, `socialAuthLimits`는 클라이언트가 읽거나 쓰지 못하도록 현재 deny-all Firestore 규칙을 유지합니다. 각 컬렉션의 `expireAt`에 TTL을 설정하면 만료 문서를 정리할 수 있습니다. TTL 전에도 서버가 10분 만료를 강제합니다.
- 소셜 신원 검증은 `firebase.sign_in_provider == custom`과 서버 custom claims 두 항목이 모두 맞아야 인정합니다. 관리자 권한은 별도로 인증된 이메일과 관리자 목록을 요구합니다.
- 탈퇴 완료 계정이 돌아오면 이전 기록과 결제를 복구하지 않는 새 UID를 생성합니다. 모든 서버 데이터 정리를 마쳤다는 `deleted: true`가 있지만 완료 마커만 빠졌다면, 제공사 로그인을 다시 검증한 뒤 Firebase Auth가 정확히 `auth/user-not-found`를 반환한 경우에만 트랜잭션으로 완료 마커를 복구합니다. Auth 계정이 남아 있거나 네트워크 오류가 나거나 데이터 정리가 미완료인 경우는 계속 차단합니다.
- 이메일 미인증 계정도 본인 계정을 삭제할 수 있습니다. 검증된 Firebase ID 토큰의 비익명 계정이어야 하며, 서버가 최근 5분 이내 재인증을 확인합니다. `auth_time` 누락·문자열·무한값·오래된 값은 거부하고 미래 시각은 30초의 시계 오차까지만 허용합니다. 이 예외는 계정 삭제에만 적용하며 정원·예약·결제 등 다른 API 권한은 넓히지 않습니다.
- Firebase custom token 발급 권한, App Check 설정, 배포 IAM, 제공사 앱 공개/승인은 실제 프로젝트에서 확인해야 합니다. 로컬 테스트는 이러한 외부 설정을 대신하지 않습니다.

## 검증

`cd backend && npm test`는 실제 gardenApi 라우트를 로드한 메모리 테스트와 소셜 세션 흐름을 실행합니다. 제공사 동의 취소, 잘못된 state/proof, 재전송, 만료, 삭제 계정 재가입, Facebook 토큰 검증 실패를 포함합니다. 실제 제공사 계정이나 실제 Firebase 서버를 사용하는 테스트는 아닙니다.
