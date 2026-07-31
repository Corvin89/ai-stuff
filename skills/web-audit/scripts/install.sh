#!/bin/bash
# Installs the web-audit skill for Claude Code and reports what it can and
# cannot do on this machine.
#
#   bash install.sh            symlink — updates arrive with git pull
#   bash install.sh --copy     copy — edit freely, no upstream changes
#
# Installs nothing else. If a browser binary is missing it prints the command
# and stops: downloading hundreds of megabytes is the user's decision.

set -u

SRC=$(cd "$(dirname "$0")/.." && pwd)
DEST="$HOME/.claude/skills/web-audit"
MODE=${1:-symlink}

mkdir -p "$HOME/.claude/skills"

if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  # Still report capabilities below: someone re-running this is usually asking
  # "why does nothing get captured", and the answer is in that report.
  echo "already installed at $DEST"
  echo "to switch install mode, remove it first:  rm -rf '$DEST'"
else
  if [ "$MODE" = "--copy" ]; then
    cp -R "$SRC" "$DEST"
    echo "copied  $SRC  ->  $DEST"
    echo "git pull will NOT update this copy."
  else
    ln -s "$SRC" "$DEST"
    echo "linked  $DEST  ->  $SRC"
  fi
fi

chmod +x "$SRC/scripts/"*.sh 2>/dev/null

echo
echo "Capabilities on this machine"
echo "----------------------------"

# Resolved by glob: the revision number differs on every machine, and a pinned
# one fails while the binary sits right there.
shell_bin=""
for c in "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell \
         "$HOME"/.cache/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell; do
  [ -x "$c" ] && shell_bin="$c"
done

if [ -n "$shell_bin" ]; then
  echo "screenshots   yes   $shell_bin"
else
  echo "screenshots   NO    the skill cannot run at all without this"
  echo "                    fix:  npx playwright install chromium-headless-shell"
fi

if node -e "require.resolve('playwright')" >/dev/null 2>&1; then
  echo "measurement   yes   playwright resolves here"
elif NODE_PATH=$(npm root -g 2>/dev/null) node -e "require.resolve('playwright')" >/dev/null 2>&1; then
  echo "measurement   yes   playwright resolves globally"
else
  echo "measurement   no    contrast numbers and the flows lens will be skipped"
  echo "                    optional fix:  npm i -g playwright"
fi

echo
echo "The user's everyday browser is never launched, and never killed."
echo
echo "Usage:  /web-audit all | mobile | desktop | view | layout | responsive |"
echo "                   contrast | consistency | flows | copy   [route|region]"
