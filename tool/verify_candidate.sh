#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for executable in flutter node python3; do
  if ! command -v "$executable" >/dev/null 2>&1; then
    printf '%s\n' "Required tool missing: $executable. Verification incomplete."
    exit 1
  fi
done
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --timeout 2m
node tool/test_cat_walk.cjs
python3 tool/test_release_config.py
python3 tool/test_billing_check.py
(cd backend && node --test)
printf '%s\n' 'Local checks passed. Real-device, console, billing and signing verification still required.'
