#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$(git -C "$ROOT" rev-parse --absolute-git-dir)/hooks"
LINE='exec "$(git rev-parse --show-toplevel)/Scripts/auto-install.sh"'

mkdir -p "$HOOKS"
for name in post-commit post-merge; do
    HOOK="$HOOKS/$name"
    if [[ -f "$HOOK" ]] && ! grep -qF "$LINE" "$HOOK"; then
        echo "Skipped $HOOK: it has other content. Add this line to it: $LINE"
        continue
    fi
    printf '#!/bin/sh\n%s\n' "$LINE" > "$HOOK"
    chmod +x "$HOOK"
    echo "Installed $HOOK"
done
