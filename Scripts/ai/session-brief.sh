#!/bin/zsh
# Prints a short brief for an AI session. With --copilot, wraps it as the JSON a Copilot sessionStart hook expects.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

brief() {
    echo "## DevHub session brief"
    echo
    echo "### Recent commits"
    git log --oneline -10 2>/dev/null || echo "(no git history yet)"
    echo
    echo "### Uncommitted changes"
    CHANGES="$(git status --short 2>/dev/null)"
    if [ -n "$CHANGES" ]; then echo "$CHANGES"; else echo "(clean)"; fi
    echo
    echo "### CHANGELOG.md — Unreleased"
    UNRELEASED="$(awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md 2>/dev/null | sed '/^$/d')"
    if [ -n "$UNRELEASED" ]; then echo "$UNRELEASED"; else echo "(empty)"; fi
    echo
    echo "### docs/STATUS.md"
    cat docs/STATUS.md 2>/dev/null
    echo
    echo "Rule: before this session ends, record changed behaviour in CHANGELOG.md under [Unreleased] and refresh docs/STATUS.md when the stage, a decision or the next steps change. Load the update-docs skill."
}

if [ "${1:-}" = "--copilot" ]; then
    cat >/dev/null
    brief | python3 -c 'import json, sys; print(json.dumps({"additionalContext": sys.stdin.read()}))'
else
    brief
fi
