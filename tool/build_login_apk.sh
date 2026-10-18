#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Public function URLs of the Firebase project in this source ZIP.
# These are not API keys or secrets. Explicit environment overrides take priority.
export GARDEN_BACKEND_URL="${GARDEN_BACKEND_URL:-https://asia-northeast3-mycatapp-99bc8.cloudfunctions.net/gardenApi}"
export SOCIAL_AUTH_URL="${SOCIAL_AUTH_URL:-https://asia-northeast3-mycatapp-99bc8.cloudfunctions.net/socialAuth}"
exec bash tool/build_test_apk.sh
