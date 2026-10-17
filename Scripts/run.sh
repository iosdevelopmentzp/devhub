#!/bin/zsh
set -e
cd "${0:A:h}/.."
APP=$(Scripts/build.sh Debug | tail -1)
pkill -x DevHub 2>/dev/null || true
sleep 0.3
open "$APP"
