#!/bin/zsh
set -euo pipefail
if [ -z "$DEVHUB_DATA_CONTAINER" ]; then
    echo "@devhub {\"error\": \"$DEVHUB_BUNDLE_ID is not installed on $DEVHUB_SIMULATOR_NAME\"}"
    exit 1
fi
echo "Profile: ${DEVHUB_PROFILE:-none} · host: ${DEVHUB_HOST:-unknown}"
rm -rf "$DEVHUB_DATA_CONTAINER/Library/Caches"
mkdir -p "$DEVHUB_DATA_CONTAINER/Library/Caches"
echo "@devhub {\"toast\": \"Cleared the caches of $DEVHUB_BUNDLE_ID\"}"
