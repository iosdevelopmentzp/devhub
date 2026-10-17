#!/bin/zsh
set -o pipefail
cd "${0:A:h}/.."

DENYLIST="${DEVHUB_DENYLIST:-$HOME/.devhub/anonymity-denylist.txt}"
ALLOWED_HOSTS='^(github\.com|[a-z0-9-]+\.github\.com|gitlab\.com|api\.anthropic\.com|([a-z0-9-]+\.)*example\.(com|org)|([a-z0-9-]+\.)*invalid|localhost|127\.0\.0\.1|keepachangelog\.com|semver\.org|www\.apple\.com|host)$'

FILES=("${(@f)$(git ls-files -co --exclude-standard 2>/dev/null)}")
if [[ ${#FILES} -eq 0 || -z "${FILES[1]}" ]]; then
  FILES=("${(@f)$(find . -type f -not -path './.git/*' -not -path './DerivedData/*' -not -path '*/.build/*' -not -path '*/xcuserdata/*' | sed 's|^\./||')}")
fi
FILES=(${FILES:#Scripts/check-anonymous.sh})
FILES=(${^FILES}(N.))

FOUND=0
report() {
  print -r -- "anonymous: $1"
  FOUND=1
}

scan() {
  local mode="$1" pattern="$2"
  local hits
  hits=$(print -rl -- $FILES | tr '\n' '\0' | xargs -0 /usr/bin/grep -nIi$mode -- "$pattern" 2>/dev/null)
  [[ -n "$hits" ]] || return 0
  print -rl -- "${(@f)hits}" | head -20 | while IFS= read -r line; do report "denied word: ${line[1,200]}"; done
}

if [[ -f "$DENYLIST" ]]; then
  while IFS= read -r word || [[ -n "$word" ]]; do
    word="${word%%[[:space:]]}"
    [[ -z "$word" || "$word" == \#* ]] && continue
    if [[ "$word" == re:* ]]; then
      scan E "${word#re:}"
    else
      scan F "$word"
    fi
  done < "$DENYLIST"
fi

BUNDLE_HITS=$(print -rl -- $FILES | tr '\n' '\0' | xargs -0 /usr/bin/grep -noIE '\bcom\.[a-zA-Z0-9-]+\.[a-zA-Z0-9]' 2>/dev/null | /usr/bin/grep -vE ':com\.(apple|example)\.')
[[ -n "$BUNDLE_HITS" ]] && print -rl -- "${(@f)BUNDLE_HITS}" | head -20 | while IFS= read -r line; do report "bundle ID: $line"; done

SUITE_HITS=$(print -rl -- $FILES | tr '\n' '\0' | xargs -0 /usr/bin/grep -noIE '\bgroup\.(com|net|org|io|app|dev)\.[a-zA-Z0-9.-]+' 2>/dev/null | /usr/bin/grep -vE ':group\.com\.example(\.|$)')
[[ -n "$SUITE_HITS" ]] && print -rl -- "${(@f)SUITE_HITS}" | head -20 | while IFS= read -r line; do report "plist suite: $line"; done

HOST_HITS=$(print -rl -- $FILES | tr '\n' '\0' | xargs -0 /usr/bin/grep -noIE 'https?://[a-zA-Z0-9.-]+' 2>/dev/null)
if [[ -n "$HOST_HITS" ]]; then
  print -rl -- "${(@f)HOST_HITS}" | while IFS= read -r line; do
    host="${line##*://}"
    host="${host:l}"
    host="${host%.}"
    [[ "$host" =~ $ALLOWED_HOSTS ]] || report "host: $line"
  done
fi

if git rev-parse --verify HEAD >/dev/null 2>&1 && [[ -f "$DENYLIST" ]]; then
  MESSAGE=$(git log -1 --format=%B)
  while IFS= read -r word || [[ -n "$word" ]]; do
    word="${word%%[[:space:]]}"
    [[ -z "$word" || "$word" == \#* ]] && continue
    if [[ "$word" == re:* ]]; then
      print -r -- "$MESSAGE" | /usr/bin/grep -qiE -- "${word#re:}" && report "denied word in the last commit message"
    else
      print -r -- "$MESSAGE" | /usr/bin/grep -qiF -- "$word" && report "denied word in the last commit message"
    fi
  done < "$DENYLIST"
fi

if [[ $FOUND -ne 0 ]]; then
  exit 1
fi
[[ -f "$DENYLIST" ]] || print -r -- "anonymous: no denylist at $DENYLIST, built-in patterns only"
echo "anonymous: ok"
