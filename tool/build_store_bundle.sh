#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Test APKs and Play bundles must use the same login/server configuration.
source tool/android_build_config.sh
prepare_android_release
flutter build appbundle "${android_release_args[@]}"
printf '%s\n' 'AAB: build/app/outputs/bundle/release/app-release.aab'
printf '%s\n' 'Upload to the existing Play app internal test track, then test login on a phone.'
