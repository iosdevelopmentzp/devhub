#!/bin/zsh
cd "${0:A:h}/.."
APP="${1:-$PWD/DerivedData/Build/Products/Debug/DevHub.app}"
pkill -x DevHub 2>/dev/null
"$APP/Contents/MacOS/DevHub" >/dev/null 2>&1 &
PID=$!
sleep 3
if kill -0 $PID 2>/dev/null; then echo alive; kill $PID; else echo dead; exit 1; fi
