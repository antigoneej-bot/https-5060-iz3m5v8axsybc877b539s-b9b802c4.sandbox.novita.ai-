#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# A .preview debug APK without login URLs is not a release candidate.
# Use the existing signed-release checks and require explicit server settings.
exec bash tool/build_test_apk.sh
