#!/bin/zsh
set -o pipefail
cd "${0:A:h}/.."
CONFIGURATION="${1:-Debug}"
xcodebuild \
  -project DevHub.xcodeproj \
  -scheme DevHub \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath DerivedData \
  -quiet \
  build 2>&1 | grep -v -E 'IDERunDestination: Supported platforms|^$'
STATUS=${pipestatus[1]}
[[ $STATUS -eq 0 ]] || exit $STATUS
echo "$PWD/DerivedData/Build/Products/$CONFIGURATION/DevHub.app"
