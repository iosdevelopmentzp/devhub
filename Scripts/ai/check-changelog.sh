#!/bin/zsh
# Blocks a session that changed code without a changelog entry.
# Claude Code Stop hook: exit 2 with the reason on stderr.
# Copilot agentStop hook (--copilot): prints {"decision": "block", "reason": "..."} or {"decision": "allow"}.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0
MODE="${1:-claude}"
INPUT="$(cat)"

allow() {
    if [ "$MODE" = "--copilot" ]; then echo '{"decision": "allow"}'; fi
    exit 0
}

block() {
    MESSAGE="DevHub: files under DevHub/, Scripts/ or .github/ changed but CHANGELOG.md did not. Load the update-docs skill: add entries under [Unreleased], refresh docs/STATUS.md if the stage, decisions or next steps changed, then stop."
    if [ "$MODE" = "--copilot" ]; then
        python3 -c 'import json, sys; print(json.dumps({"decision": "block", "reason": sys.argv[1]}))' "$MESSAGE"
        exit 0
    fi
    echo "$MESSAGE" >&2
    exit 2
}

if printf '%s' "$INPUT" | grep -q '"stop_hook_active": *true'; then
    allow
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || allow

CHANGED="$({ git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u)"
CODE_CHANGED="$(printf '%s\n' "$CHANGED" | grep -E '^(DevHub/|Scripts/|\.github/)' || true)"
[ -z "$CODE_CHANGED" ] && allow

if printf '%s\n' "$CHANGED" | grep -qx 'CHANGELOG.md'; then
    allow
fi
if git log -1 --name-only --format= 2>/dev/null | grep -qx 'CHANGELOG.md'; then
    allow
fi
block
