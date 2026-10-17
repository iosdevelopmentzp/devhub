#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/docs/examples/devhub"
TARGET="$ROOT/Packages/DevHubKit/Sources/DevHubDomain/Policies/ExampleConfig.swift"

python3 - "$SOURCE" "$TARGET" <<'PY'
import os, sys
source, target = sys.argv[1], sys.argv[2]
entries = []
for folder, _, names in sorted(os.walk(source)):
    for name in sorted(names):
        if name.startswith("."):
            continue
        path = os.path.join(folder, name)
        relative = os.path.relpath(path, source)
        text = open(path, encoding="utf-8").read()
        if '"""#' in text:
            sys.exit(f"{relative} contains the raw string end marker")
        executable = "true" if os.access(path, os.X_OK) else "false"
        entries.append(f'        ExampleFile(path: "{relative}", text: #"""\n{text.rstrip(chr(10))}\n"""#, isExecutable: {executable})')
body = ",\n".join(entries)
open(target, "w", encoding="utf-8").write(
    "import Foundation\n\npackage enum ExampleConfig {\n    package static let files: [ExampleFile] = [\n" + body + "\n    ]\n}\n"
)
PY
echo "$TARGET"
