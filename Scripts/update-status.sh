#!/bin/zsh

DEVHUB_SUPPORT_DIR="${DEVHUB_SUPPORT_DIR:-$HOME/Library/Application Support/DevHub Generic}"
DEVHUB_UPDATE_BRANCH="${DEVHUB_UPDATE_BRANCH:-main}"

json_string() {
    [[ -n "${1:-}" ]] || { printf 'null'; return; }
    local text="${1//\\/\\\\}"
    text="${text//\"/\\\"}"
    printf '"%s"' "${text//$'\n'/\\n}"
}

write_json_atomically() {
    local file="$1" text="$2"
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$text" > "$file.tmp.$$"
    mv -f "$file.tmp.$$" "$file"
}

update_status() {
    [[ -n "${UPDATE_STATUS_FILE:-}" ]] || return 0
    local phase="$1" commit="${2:-}" message="${3:-}"
    local started="${UPDATE_STARTED_AT:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    write_json_atomically "$UPDATE_STATUS_FILE" "{\"phase\": \"$phase\", \"startedAt\": \"$started\", \"commit\": $(json_string "$commit"), \"message\": $(json_string "$message")}"
}
