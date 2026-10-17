#!/bin/zsh
# Usage: Scripts/test.sh [--skip integration] [swift test arguments]
# `--skip integration` becomes `--skip IntegrationTests`: swift test has no flag to skip a tag, so integration
# tests carry `.tags(.integration)` and live in suites whose name ends in `IntegrationTests`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

args=()
while [ $# -gt 0 ]; do
    if [ "$1" = "--skip" ] && [ "${2:-}" = "integration" ]; then
        args+=(--skip IntegrationTests)
        shift 2
    else
        args+=("$1")
        shift
    fi
done

swift test --package-path "$ROOT/Packages/DevHubKit" -q "${args[@]}" 2>&1 \
    | grep -E '✘|recorded an issue|Test run with|error:'
