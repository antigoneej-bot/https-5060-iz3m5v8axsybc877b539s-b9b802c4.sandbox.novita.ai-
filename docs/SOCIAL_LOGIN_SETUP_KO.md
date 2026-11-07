# 마음냥 간편 로그인 적용·설정 안내

이번 수정은 Google·카카오·네이버·페이스북 로그인 코드와 Android 복귀 경로를 연결합니다. 실제 서비스에서 사용하려면 아래 개발자 콘솔 설정, 서버 배포, 같은 소스의 Android 재빌드가 필요합니다. 소스 변경이나 웹 미리보기만으로 휴대폰에 설치한 APK가 업데이트되지는 않습니다.

## 이용자가 사용하는 방식

- **마이 제목 바로 아래의 ‘간편 로그인’ 카드**를 누르면 ‘구글로 계속하기 / 카카오로 계속하기 / 네이버로 계속하기 / 페이스북으로 계속하기’를 선택할 수 있습니다. 로그인하면 카드가 ‘내 계정 관리’로 바뀝니다. 정원 공개 설정, 다른 정원 둘러보기, 받은 응원함에서도 로그인 화면으로 바로 이동합니다.
- 신규 이용자는 별도 이메일 회원가입 양식 없이 제공자 로그인을 선택합니다. 최초 인증 성공 시 마음냥 내부 계정이 만들어집니다.
- Google은 기기의 Google 계정 선택 화면을 사용합니다. 카카오·네이버·페이스북은 브라우저에서 인증하고 앱으로 돌아옵니다. 카카오톡·네이버·페이스북 앱을 반드시 실행하는 구현은 아닙니다.
- 기존 이메일 계정의 로그인·비밀번호 재설정 경로는 유지합니다. 다른 제공자의 계정을 이메일이 같다는 이유로 자동 합치지 않습니다. 이전 구매·백업이 있다면 원래 사용한 계정으로 로그인합니다.
- 로그인 메뉴는 서버 설정 유무와 관계없이 찾을 수 있습니다. 설정이 빠진 경우 이유를 안내하며, 성공한 것처럼 처리하지 않습니다.
- 이번 소셜 로그인 실행 대상은 Android입니다. 웹 미리보기의 화면 표시만으로 Android 인증이 검증됐다고 판단하지 않습니다. iOS는 별도 네이티브 설정·빌드·실기기 검증이 필요합니다.

## 1. 먼저 같은 앱인지 확인

기존 패키지는 `com.mysticcat.journal`입니다. 이번 소스 버전은 `1.0.9+12`로 올렸습니다. **마이 화면 맨 아래의 앱 버전**에서 실제 설치 버전과 빌드 번호를 확인할 수 있습니다. Play Console에 이미 12 이상의 versionCode가 있다면 `pubspec.yaml`의 `+12`를 콘솔에서 사용한 가장 큰 번호보다 크게 바꿉니다.

기존 `android/key.properties`, 키스토어, `android/app/google-services.json`, Firebase 프로젝트와 패키지명을 유지합니다. 키 비밀번호·클라이언트 시크릿을 채팅이나 저장소에 올리지 않습니다. Firebase에서 새 설정 파일을 받는 경우에도 같은 프로젝트·같은 패키지인지 확인합니다.

현재 debug 패키지는 `com.mysticcat.journal.preview`라 기존 설치 앱과 다릅니다. 이 문서의 테스트 APK 스크립트는 기존 패키지의 **서명된 release APK**를 만듭니다. 기존 앱에 업데이트할 때 서명 인증서와 패키지가 같아야 합니다. Play 설치본은 Play 앱 서명 인증서가 사용되므로 업로드 키로 만든 APK와 서명이 다를 수 있습니다. 업데이트가 거부되면 기존 앱을 지우지 말고 서명·버전부터 확인합니다. 이 경우 Play 내부 테스트 트랙으로 업데이트하는 것이 적합합니다.

## 2. Firebase와 Google

1. 실제 서비스의 Firebase Console → Authentication → 로그인 제공자에서 Google을 활성화하고 지원 이메일을 설정합니다.
2. 같은 Firebase 프로젝트의 Android 앱에 실제 설치본의 SHA-1을 등록합니다. Play 설치본은 Play Console의 **앱 서명 인증서** 지문을 사용합니다. 직접 배포 APK와 개발 빌드는 각각 해당 서명을 확인합니다.
3. SHA-256도 등록하고 App Check의 Play Integrity를 해당 Android 앱에 설정합니다. Play 배포 여부에 대한 App Check 요구사항을 실제 배포 방식과 맞춥니다. 직접 설치한 APK가 Play 설치본과 같은 판정을 받는다고 가정하지 않습니다.
4. 필요한 경우 같은 앱의 `google-services.json`을 다시 받습니다. Web OAuth 클라이언트 항목이 포함되어 있는지 확인합니다.
5. Web 클라이언트를 설정 파일에서 얻을 수 없을 때만 빌드에 `GOOGLE_WEB_CLIENT_ID`를 전달합니다. Android 클라이언트 ID나 Client Secret을 넣는 자리가 아닙니다.

이 구현에서 카카오·네이버·페이스북은 서버가 발급하는 Firebase Custom Token을 사용합니다. Firebase의 Facebook 로그인 제공자를 따로 켜는 방식과 혼용하지 않습니다.

## 3. 카카오·네이버·페이스북 공통 서버 설정

`backend/.env.example` 및 `backend/social-auth-setup.md`와 함께 설정합니다. 실제 값은 배포 프로젝트 환경에 넣고 커밋하지 않습니다.

| 설정 | 의미 | 저장 위치 |
|---|---|---|
| `GARDEN_ANDROID_APP_ID` | Firebase Android 앱 ID. 패키지명이 아님 | 서버 환경 |
| `SOCIAL_AUTH_CALLBACK_URL` | 배포된 `socialAuth` 함수의 정확한 HTTPS URL | 서버 환경 |
| `KAKAO_CLIENT_ID` | 카카오 REST API 키 | 서버 환경 |
| `NAVER_CLIENT_ID` | 네이버 로그인 애플리케이션 Client ID | 서버 환경 |
| `FACEBOOK_APP_ID` | Meta 앱 ID | 서버 환경 |
| `FACEBOOK_GRAPH_VERSION` | 해당 Meta 앱에서 지원하는 Graph API 버전, `v숫자.숫자` 형식 | 서버 환경 |
| `KAKAO_CLIENT_SECRET` | 카카오 Client Secret | Secret Manager |
| `NAVER_CLIENT_SECRET` | 네이버 Client Secret | Secret Manager |
| `FACEBOOK_APP_SECRET` | Meta App Secret | Secret Manager |
| `GARDEN_BACKEND_URL` | 배포된 `gardenApi` URL | 앱 빌드 |
| `SOCIAL_AUTH_URL` | 배포된 `socialAuth` URL | 앱 빌드 |
| `GOOGLE_WEB_CLIENT_ID` | 필요한 경우 지정하는 Web OAuth Client ID | 앱 빌드 |

`FACEBOOK_GRAPH_VERSION`에는 자동 기본값이 없습니다. Meta 개발자 콘솔에서 현재 앱이 사용하는 지원 버전을 확인해 명시합니다. 클라이언트 ID만 넣고 시크릿이나 콜백을 빠뜨리면 로그인할 수 없습니다.

각 제공자에 등록하는 콜백은 **서버의 HTTPS URL**입니다. `SOCIAL_AUTH_CALLBACK_URL`에 `/callback`, 쿼리 또는 슬래시를 임의로 더하지 않습니다. 아래 주소는 서버가 인증 결과를 Android 앱으로 돌려보낼 때만 사용합니다.

```text
com.mysticcat.journal.auth://callback
```

제공자의 비밀번호·Client Secret·Access Token을 APK에 넣지 않습니다. 서버가 제공자 사용자 ID를 확인한 뒤 1회용 세션과 인증 증명을 교환하여 Firebase에 로그인합니다. 개인 편지 본문·감정 기록을 소셜 로그인 제공자에게 보내지 않습니다.

### 카카오

1. 카카오 디벨로퍼스에서 마음냥용 애플리케이션의 카카오 로그인을 활성화합니다.
2. 앱의 REST API 키와 Client Secret을 서버에 설정합니다.
3. 카카오 로그인 Redirect URI에 `SOCIAL_AUTH_CALLBACK_URL`을 정확히 등록합니다.
4. 서비스 이름·개인정보 안내·동의 항목을 확인합니다. 현재 로그인에 필요한 최소 정보만 요청하고, 실제 일반 이용자에게 공개 가능한 상태인지 확인합니다.

### 네이버

1. 네이버 개발자센터의 마음냥 애플리케이션에 네이버 로그인 API를 추가합니다.
2. 이번 브라우저 OAuth 흐름에 맞는 서비스 환경, 실제 서비스 URL, Callback URL을 등록합니다. Callback URL은 `SOCIAL_AUTH_CALLBACK_URL`과 같습니다.
3. Client ID·Client Secret을 서버에 설정하고 등록된 테스트 계정으로 검증합니다.
4. 실제 일반 이용자가 사용할 수 있도록 네이버 로그인 검수를 신청합니다. 테스트 계정의 성공만으로 공개 사용까지 승인됐다고 판단하지 않습니다.

### 페이스북

1. Meta for Developers에서 마음냥 앱에 Facebook Login 사용 사례/제품을 설정합니다.
2. 앱 ID와 App Secret은 서버에 넣습니다. Client OAuth Login과 Web OAuth Login을 확인하고 **Valid OAuth Redirect URIs**에 `SOCIAL_AUTH_CALLBACK_URL`을 정확히 등록합니다.
3. 서버는 `public_profile`로 사용자 식별자를 확인합니다. 이메일 제공 동의가 없어도 이 식별자로 로그인합니다. 친구 목록·게시 권한을 요청하지 않습니다.
4. 앱의 테스트 역할 계정으로 먼저 확인한 뒤, Live 상태와 일반 이용자를 위한 권한 접근 수준을 확인합니다. 앱 유형에 따라 요구되는 사업자 확인·검수·서비스 정보와 개인정보처리방침·데이터 삭제 안내를 완료합니다. 정확한 요구사항은 해당 앱 콘솔에 표시된 상태를 기준으로 확인합니다.

## 4. 서버 배포

CLI가 올바른 Firebase 프로젝트를 가리키는지 확인한 후 다음 Secret들을 대화형 입력으로 등록합니다. 실제 비밀값을 명령문에 직접 넣지 않습니다.

```bash
firebase functions:secrets:set KAKAO_CLIENT_SECRET
firebase functions:secrets:set NAVER_CLIENT_SECRET
firebase functions:secrets:set FACEBOOK_APP_SECRET
```

`socialAuth`는 위 세 Secret을 바인딩하므로 배포 전에 준비합니다. 제공자 하나의 등록이 끝나지 않았다면 해당 Client ID를 비워 시작이 차단되게 하고, 부분 운영 절차는 서버 설정 문서를 확인합니다. 빈 값을 유효한 서비스 설정처럼 보고하지 않습니다.

서버 코드를 설치·검증한 후 같은 프로젝트에 `socialAuth`와 수정된 `gardenApi`를 배포합니다. 기존 배포 명령과 함수 이름은 `firebase.json`을 확인하고 사용합니다. 배포된 URL을 서버 콜백과 제공자 설정에 반영한 뒤 필요 시 서버를 다시 배포합니다. Custom Token을 만들 함수 서비스 계정의 서명 권한과 App Check 설정도 확인합니다. 공개 콜백 접근과 App Check 보호 POST 요청은 역할이 다르므로 운영 인증 검사를 없애서 테스트를 통과시키지 않습니다.

Firebase 로그인 성공은 개인 기록의 자동 클라우드 동기화가 완료됐다는 뜻이 아닙니다. 백업·복원은 별도 기능입니다. 계정 삭제 후 제공자 동의 철회까지 자동 완료되는지 여부도 구분하며, 현재 제공자 연결 해제는 각 제공자의 계정 설정에서 확인합니다.

## 5. 같은 설정으로 APK와 AAB 만들기

Flutter SDK가 설치된 실제 빌드 환경에서 실행합니다. 아래 예시 문자열을 그대로 사용하지 말고 배포 결과의 실제 URL로 바꿉니다. 스크립트는 누락된 URL·예시 호스트·잘못된 Web Client ID 형식을 빌드 전에 차단합니다.

```bash
export GARDEN_BACKEND_URL='배포된 gardenApi의 https URL'
export SOCIAL_AUTH_URL='배포된 socialAuth의 https URL'
# 설정 파일에 Web OAuth 클라이언트가 없을 때만 지정
# export GOOGLE_WEB_CLIENT_ID='실제-Web-클라이언트-ID.apps.googleusercontent.com'

# 직접 업데이트할 테스트 APK가 필요할 때
bash tool/build_test_apk.sh

# Play Console 내부 테스트용 AAB가 필요할 때
bash tool/build_store_bundle.sh
```

두 스크립트는 `tool/android_build_config.sh`에서 같은 설정을 가져옵니다. 각각 의존성 설치·분석·테스트를 거쳐 release 빌드를 만듭니다. APK와 AAB가 둘 다 필요하지 않다면 필요한 스크립트만 실행합니다. URL 형식 검사는 서버가 실제 배포됐거나 응답한다는 검증을 대신하지 않습니다.

분석은 `flutter analyze --no-fatal-infos --no-fatal-warnings`로 실행합니다. 기존 `tool/` 스크립트의 info·warning도 출력하되, 분석 **에러**는 빌드를 중단합니다. 전체 `flutter test` 실패도 빌드를 중단하며 테스트 실패를 무시하는 옵션은 추가하지 않았습니다.

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

`google_sign_in: 7.2.0`, `flutter_web_auth_2: 4.1.0`을 추가했습니다. 후자의 고정 버전 지침에 따라 콜백 Activity를 추가하고 MainActivity의 빈 `taskAffinity` 재정의를 제거했습니다. 향후 플러그인 버전을 바꾸면 해당 버전의 Manifest 지침도 함께 확인합니다.

`pubspec.lock`은 임의로 만들어 넣지 않습니다. Flutter 환경에서 `flutter pub get`을 실행하고 생성·변경된 lock 파일을 검토해 함께 보관합니다. 이번 전달본의 실제 분석·테스트·빌드 실행 여부는 별도 검증 보고를 기준으로 확인합니다. 제공자 콘솔의 실제 자격정보와 휴대폰을 사용한 로그인은 별도 완료 확인이 필요합니다.

## 6. 폰에서 확인할 것

| 확인 | 통과 기준 |
|---|---|
| 설치 버전 | 같은 패키지의 새 버전이 설치되고 로그인 메뉴가 보임 |
| 각 제공자 최초 로그인 | 별도 비밀번호 가입 없이 로그인 성공 후 계정 상태가 바뀜 |
| 취소·뒤로가기·네트워크 끊김 | 거짓 성공이나 무한 로딩 없이 재시도 가능 |
| 재실행·로그아웃·다른 계정 | 현재 계정이 정확하고 이전 계정의 서버 권한을 넘겨받지 않음 |
| 기존 이메일 이용자 | 이전 계정에 다시 로그인하고 기존 접근 권한을 확인할 수 있음 |
| 두 계정의 공개 정원 | A의 공개 정원을 B에서 보고 응원이 실제로 전달됨 |
| 구매·복원 | 원래 마음냥 계정·Play 계정으로 구독 및 아이템 권한을 확인 |

계정별 버튼만 누른 화면, 웹 미리보기, 콘솔의 함수 생성 메시지는 위 실기기 검증을 대신하지 않습니다. 설정 담당자는 각 제공자의 성공·취소 결과와 설치 버전을 함께 남깁니다.

## 공식 참고

- [Firebase Android Google 로그인](https://firebase.google.com/docs/auth/android/google-signin)
- [Firebase App Check / Play Integrity](https://firebase.google.com/docs/app-check/android/play-integrity-provider)
- [Firebase Custom Token](https://firebase.google.com/docs/auth/admin/create-custom-tokens)
- [Google 로그인 Android 플러그인 설정](https://pub.dev/packages/google_sign_in_android)
- [flutter_web_auth_2 4.1.0](https://pub.dev/packages/flutter_web_auth_2/versions/4.1.0)
- [카카오 로그인 설정](https://developers.kakao.com/docs/ko/kakaologin/prerequisite)
- [네이버 로그인 개발 가이드](https://developers.naver.com/docs/login/devguide/devguide.md)
- [Meta 수동 로그인 흐름](https://developers.facebook.com/documentation/facebook-login/guides/advanced/manual-flow)
- [Meta 접근 수준](https://developers.facebook.com/docs/graph-api/overview/access-levels/)
