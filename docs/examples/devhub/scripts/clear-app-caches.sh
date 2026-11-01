#!/bin/zsh
set -euo pipefail
if [ -z "$DEVHUB_DATA_CONTAINER" ]; then
    echo "@devhub {\"error\": \"$DEVHUB_BUNDLE_ID is not installed on $DEVHUB_SIMULATOR_NAME\"}"
    exit 1
fi
echo "Profile: ${DEVHUB_PROFILE:-none} · host: ${DEVHUB_HOST:-unknown}"
rm -rf "$DEVHUB_DATA_CONTAINER/Library/Caches"
mkdir -p "$DEVHUB_DATA_CONTAINER/Library/Caches"
while IFS=$'\t' read -r group folder; do
    [ -n "$folder" ] || continue
    rm -rf "$folder/Library/Caches"
    mkdir -p "$folder/Library/Caches"
done <<< "$DEVHUB_GROUP_CONTAINERS"
echo "@devhub {\"toast\": \"Cleared the caches of $DEVHUB_BUNDLE_ID on $DEVHUB_SIMULATOR_NAME ($DEVHUB_SIMULATOR_STATE)\"}"
