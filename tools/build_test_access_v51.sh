#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter build appbundle --release \
  --dart-define=UNLOCK_ALL_PREMIUM=true \
  --dart-define=APP_CHECK_DEBUG_PROVIDER=false \
  --dart-define=GARDEN_BACKEND_URL=https://gardenapi-zk2q7ixdva-du.a.run.app \
  --dart-define=SOCIAL_AUTH_URL=https://asia-northeast3-mycatapp-99bc8.cloudfunctions.net/socialAuth
