#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK is required; no build or tests were run.' >&2
  exit 127
fi
flutter --version
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
