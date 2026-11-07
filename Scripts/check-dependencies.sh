#!/bin/zsh
set -o pipefail
cd "${0:A:h}/.."

SRC=Packages/DevHubKit/Sources
STATUS=0

report() {
  print -r -- "dependencies: $1"
  STATUS=1
}

listed() {
  grep -vE '^\s*(#|$)' "$1" | grep -qxF -- "$2"
}

hits=$(grep -n '\.package(' Packages/DevHubKit/Package.swift)
[[ -n "$hits" ]] && report "Package.swift declares a package dependency; third-party packages need the owner's consent (.claude/rules/dependencies.md)" && print -r -- "$hits"

hits=$(grep -n 'XCRemoteSwiftPackageReference\|repositoryURL' DevHub.xcodeproj/project.pbxproj)
[[ -n "$hits" ]] && report "project.pbxproj references a remote package" && print -r -- "$hits"

hits=$(git ls-files -co --exclude-standard 2>/dev/null | grep -vE '^(DerivedData|\.build|\.claude/worktrees)/' | grep -E '(^|/)(Package\.resolved|Podfile|Cartfile|Gemfile|package\.json|Brewfile|Mintfile|\.tool-versions|[^/]+\.lock)$')
[[ -n "$hits" ]] && report "package manager files found" && print -r -- "$hits"

hits=$(grep -nE '^\s*-?\s*uses:' .github/workflows/*.yml | grep -vE 'uses:\s*[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[0-9a-f]{40}(\s*#.*)?$')
[[ -n "$hits" ]] && report "a GitHub Action is not pinned to a 40-character commit SHA" && print -r -- "$hits"

for name in $(grep -rzhoE 'shell\.(run|stream)\(\s*"[^"]+"|path\(of: "[^"]+"|isInstalled\("[^"]+"|DoctorTool\(name: "[^"]+"|executable: "[^"]+"' "$SRC" --include='*.swift' | tr '\0' '\n' | grep '"$' | sed -E 's/.*"([^"]+)"$/\1/; s|.*/||' | sort -u); do
  listed Scripts/allowed-tools.txt "$name" || report "the executable '$name' is not in Scripts/allowed-tools.txt"
done

for host in $(grep -rhoE 'https?://[A-Za-z0-9.-]+' "$SRC/DevHubData" --include='*.swift' | sed -E 's|https?://||' | sort -u); do
  listed Scripts/allowed-hosts.txt "$host" || report "DevHubData talks to '$host', which is not in Scripts/allowed-hosts.txt"
done

[[ $STATUS -eq 0 ]] && print -r -- "dependencies: ok"
exit $STATUS
