#!/bin/zsh
set -e
cd "${0:A:h}/.."
OUTPUT="$PWD/DevHub Launcher.app"
SCRIPT=$(mktemp -t devhub-launcher).applescript
cat > "$SCRIPT" <<APPLESCRIPT
try
    do shell script "'$PWD/Scripts/run.sh' >/tmp/devhub-launcher.log 2>&1"
on error
    display alert "DevHub could not build or start" message "Details are in /tmp/devhub-launcher.log." as critical
end try
APPLESCRIPT
rm -rf "$OUTPUT"
osacompile -o "$OUTPUT" "$SCRIPT"
rm -f "$SCRIPT"
echo "$OUTPUT"
