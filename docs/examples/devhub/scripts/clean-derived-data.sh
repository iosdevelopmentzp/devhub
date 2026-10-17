#!/bin/zsh
set -euo pipefail
ROOT="$HOME/Library/Developer/Xcode/DerivedData"
echo "@devhub {\"progress\": \"Looking for DerivedData of $DEVHUB_CHECKOUT_PATH\"}"
REMOVED=0
for folder in "$ROOT"/*/; do
    plist="$folder/info.plist"
    [ -f "$plist" ] || continue
    workspace="$(/usr/libexec/PlistBuddy -c 'Print :WorkspacePath' "$plist" 2>/dev/null || true)"
    case "$workspace" in
        "$DEVHUB_CHECKOUT_PATH"/*)
            echo "Removing $folder"
            rm -rf "$folder"
            REMOVED=$((REMOVED + 1))
            ;;
    esac
done
echo "@devhub {\"toast\": \"Removed $REMOVED DerivedData folder(s)\"}"
