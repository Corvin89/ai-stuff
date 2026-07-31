#!/bin/bash
# Viewport screenshots for the web-visual-audit skill.
#
# Bash, not zsh: on macOS zsh does not word-split unquoted variables, so the
# width loop and the stray-PID kill below would collapse into a single argument.
#
# NEVER touches /Applications/Google Chrome.app — that is the user's live
# browser, with their tabs and their sessions in it. Uses the standalone
# Playwright headless shell with a throwaway --user-data-dir, so it can never
# attach to a running instance and hand the URL to the user's window instead
# of taking a screenshot.
#
# Idempotent: valid PNGs are skipped, invalid ones are deleted, so an
# interrupted run is resumed by running the script again.
#
# Usage:
#   bash capture.sh <url> <out-dir> [width | widthxheight ...]
#
#   FORCE=1    re-shoot files that already exist
#   BUDGET=n   virtual time budget in ms (default 8000)
#   TIMEOUT=n  watchdog seconds per shot (default 45)
#   SHELL_BIN  override the headless binary path
#
# Default widths: 360 768 1440.

set -u

URL=${1:?url required}
OUT=${2:?output directory required}
shift 2
WIDTHS=${*:-"360 768 1440"}
TIMEOUT=${TIMEOUT:-45}
BUDGET=${BUDGET:-8000}

# Resolve by glob, never by a pinned revision: the number in the directory name
# differs per machine, and a hardcoded one breaks on every machine but the
# author's while the binary sits right there.
if [ -z "${SHELL_BIN:-}" ]; then
  for c in "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell \
           "$HOME"/.cache/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell; do
    [ -x "$c" ] && SHELL_BIN="$c"
  done
fi

if [ -z "${SHELL_BIN:-}" ] || [ ! -x "$SHELL_BIN" ]; then
  echo "No standalone headless shell found."
  echo "Ask the user to run:  npx playwright install chromium-headless-shell"
  echo "Do NOT fall back to the browser in /Applications — it is the user's."
  exit 1
fi

mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)   # --screenshot resolves relative paths against cwd

# A dead dev server yields a perfectly valid PNG of Chrome's own error page:
# right magic bytes, right size, wrong page. Fail here instead of shooting three.
curl -sS -o /dev/null -m 10 "$URL" || { echo "no answer from $URL — is the dev server up?"; exit 1; }

is_png() { [ -s "$1" ] && [ "$(head -c 4 "$1" | xxd -p)" = "89504e47" ]; }

ok=0; skipped=0; failed=0

for spec in $WIDTHS; do
  w=${spec%%x*}
  if [ "$spec" = "$w" ]; then
    if [ "$w" -le 768 ]; then h=800; else h=900; fi
  else
    h=${spec#*x}
  fi
  # A tall window approximates a full-page capture, but 100vh then resolves
  # against that height: heroes become window-tall and sticky headers never
  # stick. Such frames are not evidence for anything viewport-relative.
  [ -n "${TALL:-}" ] && h=${TALL_HEIGHT:-6000}

  # Device scale 2 below 768: a 360px-wide PNG is mush when reviewed by eye,
  # and real defects hide in mush. A tall frame at scale 2 would be enormous,
  # so full-page captures stay at scale 1.
  if [ "$w" -le 768 ] && [ -z "${TALL:-}" ]; then dsf=2; else dsf=1; fi

  target="$OUT/${w}.png"
  if [ -z "${FORCE:-}" ] && is_png "$target"; then
    echo "skip  ${w}px"
    skipped=$((skipped + 1)); continue
  fi
  rm -f "$target"

  profile=$(mktemp -d "${TMPDIR:-/tmp}/wva-profile.XXXXXX")

  "$SHELL_BIN" \
    --user-data-dir="$profile" \
    --no-first-run --no-default-browser-check --disable-extensions \
    --hide-scrollbars \
    --default-background-color=FFFFFFFF \
    --force-device-scale-factor="$dsf" \
    --virtual-time-budget="$BUDGET" \
    --run-all-compositor-stages-before-draw \
    --window-size="${w},${h}" \
    --screenshot="$target" \
    "$URL" >"$profile/out.log" 2>"$profile/err.log" &
  pid=$!

  # macOS has no timeout(1). Watch our own PID and nothing else.
  waited=0
  while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt "$TIMEOUT" ]; do
    sleep 1; waited=$((waited + 1))
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "kill  ${w}px — pid $pid exceeded ${TIMEOUT}s"
    kill "$pid" 2>/dev/null; sleep 2; kill -9 "$pid" 2>/dev/null
  fi
  wait "$pid" 2>/dev/null

  # Match the UNIQUE profile path. Never the string "chrome": pkill -f chrome
  # would hit the user's browser and any other agent's at the same time.
  strays=$(pgrep -f "$profile" 2>/dev/null)
  [ -n "$strays" ] && kill $strays 2>/dev/null

  keep=""
  if is_png "$target"; then
    dims=$(sips -g pixelWidth -g pixelHeight "$target" 2>/dev/null | awk '/pixel/{printf "%s ", $2}')
    bytes=$(wc -c < "$target" | tr -d ' ')
    echo "ok    ${w}px -> $target  [${dims}px]  ${bytes}b"
    [ "$bytes" -lt 10000 ] && echo "      WARN tiny file — the page probably rendered blank"
    ok=$((ok + 1))
  else
    rm -f "$target"
    echo "FAIL  ${w}px — stderr kept at $profile/err.log"
    failed=$((failed + 1)); keep=1
  fi

  [ -z "$keep" ] && rm -rf "$profile"
done

echo "---"
echo "shot: $ok   skipped: $skipped   failed: $failed"
echo "PNG width is scaled: a 360px viewport at scale 2 is a 720px file. Report the viewport, not the file."
[ "$failed" -gt 0 ] && echo "rerun — only missing frames are re-shot"
exit 0
