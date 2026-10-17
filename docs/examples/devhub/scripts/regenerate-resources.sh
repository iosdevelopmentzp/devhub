#!/bin/zsh
# devhub: title = Regenerate resources
# devhub: subtitle = Runs the resource generator after asset or string changes
# devhub: icon = wand.and.stars
# devhub: tint = purple
# devhub: input = target, Target, choice, App|Widget
# devhub: input = clean, Clean first, toggle, false
# devhub: placements = home.scripts
# devhub: cwd = checkout
set -euo pipefail
echo "@devhub {\"progress\": \"Generating for $DEVHUB_INPUT_TARGET\"}"
if [ "$DEVHUB_INPUT_CLEAN" = "true" ]; then
    echo "Cleaning generated files first"
fi
echo "Replace this line with the generator command"
echo "@devhub {\"toast\": \"Resources generated\"}"
