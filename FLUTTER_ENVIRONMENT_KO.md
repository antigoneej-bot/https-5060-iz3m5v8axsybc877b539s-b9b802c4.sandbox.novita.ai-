# Flutter 실행 환경

이 소스용으로 Linux 작업 환경에 Flutter 3.35.7 / Dart 3.9.2, Microsoft OpenJDK 17.0.20.1(컴파일러 포함),
Android command-line tools 19.0, Android SDK platforms 34·35·36 / build-tools 35.0.0 / NDK 27.0.12077973 / CMake 3.22.1을 설치했습니다.
Flutter 공식 배포 SHA-256 및 Android 도구 배포 체크섬을 확인했습니다.

## 같은 작업 서버에서 사용

    source /workspace/scratch/0e5d604fd97f/flutter-environment/activate.sh
    cd /workspace/scratch/0e5d604fd97f/unified/mind-cat-garden-main
    flutter --version
    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --debug

환경 활성화에는 CI=true와 FLUTTER_SUPPRESS_ANALYTICS=true가 포함됩니다.
CI 설정은 Flutter의 클라우드 메타데이터 자동 조회를 생략합니다.

## 새 Linux 환경에서 다시 설치

이 작업 서버의 SDK와 캐시는 영구 보관이 보장되지 않습니다. 소스와 재설치 스크립트는
다운로드 ZIP에 포함되어 있습니다. SDK 자체(수 GB)는 ZIP에 중복 포함하지 않았습니다.

필요한 기본 도구: Python 3.12 이상, Git, curl, unzip, xz. JDK 17은 --android 옵션으로 함께 설치됩니다.
Linux x64에서 프로젝트 루트에서 실행합니다.

    python3 tool/setup_flutter_linux.py --android
    source "$HOME/garden-flutter-env/activate.sh"
    flutter pub get
    flutter doctor -v

Android 라이선스에는 화면에서 직접 동의합니다. 이미 약관을 검토하고 동의한
자동화 환경에서만 --accept-android-licenses 옵션을 사용합니다.

## 범위

이 환경은 Android 빌드와 Flutter 테스트용입니다. Android Studio GUI,
Android 에뮬레이터, iOS/Xcode, 사용자 Windows PC 원격 설치는 포함하지 않습니다.
APK 빌드와 휴대전화에서 직접 조작하는 검증은 별개입니다.
릴리스 배포에는 기존 앱의 서명키와 스토어 결제/서비스 설정이 필요합니다.

공식 설치 참고: https://docs.flutter.dev/install/manual

## 실제 검증 결과

- Flutter SDK와 Dart 버전 명령 실행 성공. Android 도구 체인 및 SDK 라이선스 검사 통과.
- flutter pub get 성공. 실제 해결된 pubspec.lock을 포함합니다.
- flutter test --no-pub: 61개 전체 통과(약 16초).
- flutter analyze --no-pub: 오류 0개, 기존 코드 경고 3개·정보성 안내 30개. 기본 analyze 명령은 이 안내 때문에 종료 코드 1을 반환하므로 ‘무경고 통과’는 아닙니다.
- 기존 테스트의 전역 플랫폼 설정 복원과 샘플 백업 Map 타입을 수정했습니다. 검증 조건은 유지했습니다.
- 추가 정원 코드의 Dart 형식과 단순 린트 19건을 정리했습니다.
- verification/flutter-test.log와 verification/flutter-analyze.log에 실행 결과가 있습니다.

Android 빌드는 컨테이너에서 Kotlin 보조 프로세스가 종료되는 문제를 피하도록
android/gradle.properties에 kotlin.compiler.execution.strategy=in-process를 설정했습니다.

## APK 빌드 성공

flutter build apk --debug --no-pub 종료 코드 0, 테스트용 APK 생성 성공.
apksigner로 v2 서명 검증 및 APK 내부 ZIP CRC 검사를 통과했습니다.
앱 ID com.mysticcat.journal, 버전 1.0.5(6), minSdk 24, targetSdk 36입니다.
첫 성공 빌드는 의존성 준비를 포함해 약 14분 25초 걸렸습니다.

APK는 개발용 서명입니다. 기존 배포 앱과 서명이 다르면 덮어 설치할 수 없으며,
이번 파일은 스토어 제출용 릴리스가 아닙니다. 실제 휴대전화에서의 조작·저장·공유·결제는
아직 확인하지 않았습니다. 기존 앱 삭제로 기록을 잃지 않도록 테스트용 기기에서
먼저 검증하거나 원래 배포 서명키로 빌드해야 합니다.

이전 문서의 ‘Flutter 미설치/테스트 미실행/APK 미생성’ 설명보다 이 문서가 최신입니다.
