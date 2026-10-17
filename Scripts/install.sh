#!/bin/zsh
set -e
cd "${0:A:h}/.."
APP=$(Scripts/build.sh Release | tail -1)
pkill -f "^/Applications/DevHub.app/Contents/MacOS/DevHub" 2>/dev/null || true
rm -rf /Applications/DevHub.app
ditto "$APP" /Applications/DevHub.app
open /Applications/DevHub.app
echo /Applications/DevHub.app
