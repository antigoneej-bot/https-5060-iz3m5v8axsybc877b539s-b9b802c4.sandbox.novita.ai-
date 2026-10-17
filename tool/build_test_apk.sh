#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# This is a signed release APK of the existing package, not the .preview app.
source tool/android_build_config.sh
prepare_android_release
flutter build apk "${android_release_args[@]}"
printf '%s\n' 'APK: build/app/outputs/flutter-apk/app-release.apk'
printf '%s\n' 'Update the installed app only when the package and signing certificate match.'
printf '%s\n' 'If updating is rejected, keep the installed app/data and inspect the signing certificate and versionCode.'
printf '%s\n' 'Direct APK installation does not guarantee Play Integrity or Play Billing approval; use the Play internal test track for those checks.'
