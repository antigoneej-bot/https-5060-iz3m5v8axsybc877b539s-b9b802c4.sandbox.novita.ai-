#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Preserve the deployed endpoints already used by the working QA application.
# This is the Play internal-test/production authentication path, not debug QA.
export SOCIAL_AUTH_URL='https://asia-northeast3-mycatapp-99bc8.cloudfunctions.net/socialAuth'
export GARDEN_BACKEND_URL='https://gardenapi-zk2q7ixdva-du.a.run.app'
exec bash tool/build_store_bundle.sh
