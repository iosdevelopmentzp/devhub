#!/bin/zsh
set -u
if [ -z "${DEVHUB_DATA_CONTAINER:-}" ]; then
    print '@devhub {"error": "The app is not installed on this simulator."}'
    exit 0
fi
log="$DEVHUB_DATA_CONTAINER/Library/Caches/network.jsonl"
tail -n 200 -F "$log" 2>/dev/null | while IFS= read -r line; do
    [ -n "$line" ] && print -r -- "@devhub {\"request\": $line}"
done
