#!/bin/zsh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Packages/DevHubKit/Sources"
TESTS="$ROOT/Packages/DevHubKit/Tests"
HOST="$ROOT/DevHub"
EXCEPTIONS="$ROOT/Scripts/layer-exceptions.txt"
MODULES=(DevHubDomain DevHubData DevHubMocks DevHubUI DevHubPresentation DevHubComposition DevHubTestSupport)
STATUS=0

report() {
    echo "layers: $1"
    STATUS=1
}

forbid() {
    local dir="$1" pattern="$2" reason="$3" exclude="${4:-}"
    [ -d "$SRC/$dir" ] || return 0
    local matches
    if [ -n "$exclude" ]; then
        matches="$(grep -rEn --include='*.swift' "$pattern" "$SRC/$dir" | grep -Ev "$exclude" || true)"
    else
        matches="$(grep -rEn --include='*.swift' "$pattern" "$SRC/$dir" || true)"
    fi
    [ -z "$matches" ] && return 0
    report "$reason"
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
}

forbid DevHubDomain '^import (SwiftUI|AppKit|Cocoa|Observation|Combine)' 'DevHubDomain imports a UI or app framework'
forbid DevHubDomain '\b(Process|UserDefaults|NSWorkspace|NSPasteboard|NSScreen|NSPanel)[.(]|\bNSApp\b|FileManager\.default' 'DevHubDomain touches the system directly'

forbid DevHubData '^import (SwiftUI|Observation)' 'DevHubData imports SwiftUI or Observation'
forbid DevHubData '^import AppKit' 'DevHubData imports AppKit outside DevHubData/Workspace' '/DevHubData/Workspace/'
forbid DevHubData '\.shared\b' 'DevHubData uses a shared singleton' 'URLSession\.shared|NSWorkspace\.shared'
forbid DevHubData '\bProcess\(' 'DevHubData runs a process outside ShellRunner' '/DevHubData/Shell/ShellRunner\.swift:'
forbid DevHubData 'UserDefaults' 'DevHubData uses UserDefaults outside UserDefaultsKeyValueStore' '/DevHubData/Persistence/UserDefaultsKeyValueStore\.swift:'

forbid DevHubData '\bNW(Listener|Connection)\b|^import Network' 'Network.framework used outside DevHubData/Network/MockServer' '/DevHubData/Network/MockServer/'
for module in DevHubDomain DevHubMocks DevHubUI DevHubPresentation DevHubComposition; do
    forbid "$module" '\bNW(Listener|Connection)\b|^import Network$' "$module uses Network.framework (only DevHubData/Network/MockServer may)"
done

forbid DevHubMocks '^import (SwiftUI|AppKit|Observation)' 'DevHubMocks imports a UI framework'

forbid DevHubUI '^import DevHub' 'DevHubUI imports a DevHub module'

forbid DevHubPresentation '^import DevHubData' 'DevHubPresentation imports DevHubData'
forbid DevHubPresentation '^import DevHubMocks' 'DevHubPresentation imports DevHubMocks outside PresentationAssembly+Preview.swift' '/DevHubPresentation/Shared/PresentationAssembly\+Preview\.swift:'
forbid DevHubPresentation '\bProcess\(' 'DevHubPresentation runs a process'
forbid DevHubPresentation '\.shared\b' 'DevHubPresentation uses a shared singleton' 'NSWorkspace\.shared|NSApplication\.shared|NSApp\b'
forbid DevHubPresentation 'NSPasteboard' 'NSPasteboard used outside DevHubPresentation/Shared/PasteboardWriter.swift' '/DevHubPresentation/Shared/PasteboardWriter\.swift:'
forbid DevHubPresentation 'UserDefaults' 'DevHubPresentation uses UserDefaults'

for module in DevHubDomain DevHubData DevHubMocks; do
    forbid "$module" '^nonisolated ' "$module declares nonisolated at the top level (it is the module default)"
done

matches="$(grep -rEn --include='*.swift' '\bpublic\b' "$SRC" "$TESTS" | grep -v "^$SRC/DevHubComposition/" || true)"
if [ -n "$matches" ]; then
    report 'public used outside DevHubComposition'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi

matches="$(grep -rEn --include='*.swift' '@testable' "$SRC" "$HOST" || true)"
if [ -n "$matches" ]; then
    report '@testable used outside Packages/DevHubKit/Tests'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi

matches="$(find "$HOST" -name '*.swift' -type f | grep -vx "$HOST/DevHubApp.swift" || true)"
if [ -n "$matches" ]; then
    report 'DevHub/ holds Swift files other than DevHubApp.swift'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi
[ -f "$HOST/DevHubApp.swift" ] || report 'DevHub/DevHubApp.swift is missing'

exceptions="$( [ -f "$EXCEPTIONS" ] && grep -Ev '^\s*(#|$)' "$EXCEPTIONS" | sed -E 's/\s+#.*$//' || true )"

check_file_rule() {
    local root="$1"
    [ -d "$root" ] || return 0
    while IFS= read -r file; do
        relative="${file#$ROOT/}"
        printf '%s\n' "$exceptions" | grep -qx "$relative" && continue
        name="$(basename "$file" .swift)"
        primary="${name%%+*}"
        declared="$(grep -E '^(nonisolated |final |indirect |public |package |internal |@[A-Za-z]+ )*(struct|class|enum|protocol|actor) [A-Za-z_][A-Za-z0-9_]*' "$file" | sed -E 's/^.*(struct|class|enum|protocol|actor) ([A-Za-z_][A-Za-z0-9_]*).*/\2/' || true)"
        extended="$(grep -E '^(nonisolated |public |package |internal |@[A-Za-z]+ )*extension [A-Za-z_][A-Za-z0-9_.]*' "$file" | sed -E 's/^.*extension ([A-Za-z_][A-Za-z0-9_]*).*/\1/' | grep -vx "$primary" | grep -vx "$name" || true)"
        count=$(( $(printf '%s' "$declared" | grep -c . ) + $(printf '%s' "$extended" | grep -c . ) ))
        if [ "$count" -gt 1 ]; then
            report "$relative holds more than one top-level type: $(printf '%s\n%s' "$declared" "$extended" | grep . | tr '\n' ' ')"
        fi
        if [ "$count" -ge 1 ] && ! printf '%s\n%s\n' "$declared" "$extended" | grep -qx "$primary"; then
            report "$relative: file name does not match a declared type ($(printf '%s\n%s' "$declared" "$extended" | grep . | tr '\n' ' '))"
        fi
    done < <(find "$root" -name '*.swift' -type f)
}

for module in $MODULES; do
    check_file_rule "$SRC/$module"
done
check_file_rule "$TESTS"

if [ "$STATUS" -eq 0 ]; then
    echo "layers: ok"
fi
exit $STATUS
