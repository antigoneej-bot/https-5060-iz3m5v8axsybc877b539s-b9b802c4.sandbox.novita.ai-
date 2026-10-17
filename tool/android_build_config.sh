#!/usr/bin/env bash
# Shared by build_test_apk.sh and build_store_bundle.sh. Contains no secrets.

require_android_https_endpoint() {
  local name="$1"
  local value="${!name:-}"
  # Reject credentials, query strings, fragments, whitespace and sample hosts.
  if [[ ! "$value" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]+)?(/[^[:space:]?#]*)?/?$ ]]; then
    printf '%s\n' "Set $name to the deployed HTTPS function URL (no query, fragment or credentials)." >&2
    printf '%s\n' 'See docs/SOCIAL_LOGIN_SETUP_KO.md. No Android artifact was built.' >&2
    return 1
  fi
  local host="${value#https://}"
  host="${host%%/*}"
  host="${host%%:*}"
  case "${host,,}" in
    localhost|*.localhost|*.invalid|example.com|*.example.com|127.*|0.0.0.0)
      printf '%s\n' "$name must use the real deployed host, not a placeholder or local host." >&2
      return 1 ;;
  esac
}

prepare_android_release() {
  require_android_https_endpoint GARDEN_BACKEND_URL || return
  require_android_https_endpoint SOCIAL_AUTH_URL || return
  if [[ -n "${GOOGLE_WEB_CLIENT_ID:-}" ]] &&
      [[ ! "$GOOGLE_WEB_CLIENT_ID" =~ ^[A-Za-z0-9._-]+\.apps\.googleusercontent\.com$ ]]; then
    printf '%s\n' 'GOOGLE_WEB_CLIENT_ID must be the Web OAuth client ID, not an Android client ID or secret.' >&2
    return 1
  fi
  if ! command -v flutter >/dev/null 2>&1; then
    printf '%s\n' 'Flutter SDK is required. No Android artifact was built.' >&2
    return 127
  fi
  if [[ ! -f android/key.properties ]]; then
    printf '%s\n' 'The original android/key.properties release signing configuration is required.' >&2
    printf '%s\n' 'Do not generate a replacement key or uninstall the app to bypass an update failure.' >&2
    return 1
  fi
  android_release_args=(
    --release
    "--dart-define=GARDEN_BACKEND_URL=$GARDEN_BACKEND_URL"
    "--dart-define=SOCIAL_AUTH_URL=$SOCIAL_AUTH_URL"
  )
  if [[ -n "${GOOGLE_WEB_CLIENT_ID:-}" ]]; then
    android_release_args+=("--dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID")
  fi
  flutter pub get
  # Existing tool/ diagnostics are still shown, while analyzer errors stop
  # the build. Do not make unrelated informational warnings a release blocker.
  flutter analyze --no-fatal-infos --no-fatal-warnings
  flutter test
}
