#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Test APKs and Play bundles must use the same login/server configuration.
source tool/android_build_config.sh
export PRIVACY_OPERATOR="${PRIVACY_OPERATOR:-박은정 (마음냥 정원)}"
export PRIVACY_CONTACT="${PRIVACY_CONTACT:-maeumnyang.help@gmail.com}"
export PRIVACY_POLICY_URL="${PRIVACY_POLICY_URL-https://mindnyang-privacy.antigone-ej.chatgpt.site/privacy.html}"
export ACCOUNT_DELETION_URL="${ACCOUNT_DELETION_URL-https://mindnyang-privacy.antigone-ej.chatgpt.site/delete-account.html}"
for key in PRIVACY_OPERATOR PRIVACY_CONTACT PRIVACY_POLICY_URL ACCOUNT_DELETION_URL; do
  if [[ -z "${!key:-}" ]]; then
    printf '%s\n' "Set verified $key before a production build." >&2
    exit 1
  fi
done
require_android_https_endpoint PRIVACY_POLICY_URL
require_android_https_endpoint ACCOUNT_DELETION_URL
if [[ "${ADMOB_TEST_ADS:-false}" == true ]]; then
  printf '%s\n' 'Production build cannot contain test advertisements.' >&2
  exit 1
fi
prepare_android_release
flutter build appbundle "${android_release_args[@]}" \
  --dart-define=APP_CHECK_DEBUG_PROVIDER=false \
  --dart-define=UNLOCK_ALL_PREMIUM=false \
  --dart-define=TEST_SHOW_ONBOARDING=false \
  --dart-define=RELEASE_ENV=production \
  "--dart-define=PRIVACY_OPERATOR=$PRIVACY_OPERATOR" \
  "--dart-define=PRIVACY_CONTACT=$PRIVACY_CONTACT" \
  "--dart-define=PRIVACY_POLICY_URL=$PRIVACY_POLICY_URL" \
  "--dart-define=ACCOUNT_DELETION_URL=$ACCOUNT_DELETION_URL"
printf '%s\n' 'AAB: build/app/outputs/bundle/release/app-release.aab'
printf '%s\n' 'Upload to the existing Play app internal test track, then test login on a phone.'
printf '%s\n' 'Uses Play Integrity. Configure the Play app-signing SHA-256 and linked Firebase project; do not register individual debug tokens.'
