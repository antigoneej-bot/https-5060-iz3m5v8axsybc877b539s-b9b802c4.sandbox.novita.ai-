#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK is required. No release bundle was built.' >&2
  exit 127
fi
case "${GARDEN_BACKEND_URL:-}" in
  https://?*) ;;
  *) echo 'Set GARDEN_BACKEND_URL to the deployed and verified HTTPS gardenApi endpoint.' >&2; exit 1 ;;
esac
if [[ ! -f android/key.properties ]]; then
  echo 'Release signing configuration android/key.properties is required.' >&2
  exit 1
fi
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define="GARDEN_BACKEND_URL=$GARDEN_BACKEND_URL"
