#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Mindnyang's existing QA APK uses App Check's registered debug provider.
# This helper is for device login testing, not Google Play production release.
# The OAuth callback is compared exactly with SOCIAL_AUTH_URL by the app.
# Pin it here so an old Cloud Run environment override cannot silently return.
export SOCIAL_AUTH_URL='https://asia-northeast3-mycatapp-99bc8.cloudfunctions.net/socialAuth'
# Preserve the garden endpoint used by the installed QA APK.
export GARDEN_BACKEND_URL='https://gardenapi-zk2q7ixdva-du.a.run.app'

source tool/android_build_config.sh
prepare_android_release
flutter build apk "${android_release_args[@]}" \
  --dart-define=UNLOCK_ALL_PREMIUM=false \
  --dart-define=APP_CHECK_DEBUG_PROVIDER=true

printf '%s\n' 'QA APK: build/app/outputs/flutter-apk/app-release.apk'
printf '%s\n' 'Same package and original signing key: install as an update; keep app data.'
printf '%s\n' 'This APK uses App Check debug attestation. Do not publish it as a production release.'
