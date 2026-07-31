#!/bin/bash
# Batch image generation for the ai-image-set skill.
#
# Bash, not zsh: zsh does not word-split unquoted variables and the
# read-loop below would silently collapse each line into one field.
#
# STRICTLY SEQUENTIAL BY DESIGN. The service allows only ONE in-flight
# request per IP and answers a second one with HTTP 429 and a JSON body
# ("Queue full for IP ... max: 1"). Never run two copies of this script
# at once, and never let another agent generate against the same service
# while it runs — you will get JSON error documents saved under .jpg names.
#
# Idempotent — existing VALID files are skipped, so a run that timed out
# or was interrupted is resumed by running it again. Corrupt downloads are
# deleted rather than kept, so a rerun repairs them.
#
# Usage:
#   bash generate.sh <output-dir> <jobs-file> "<shared prompt tail>"
#
# jobs-file: one job per line, TAB-separated:
#   filename<TAB>seed<TAB>prompt
#
# Run it with run_in_background: true — with model=flux a single image
# takes 15–60s, so any sizeable batch outlives a synchronous tool call.

set -u

OUT=${1:?output directory required}
JOBS=${2:?jobs file required}
TAIL=${3:-}

MAX_RETRIES=4
GAP=2 # pause between requests so we do not run into the queue limit

mkdir -p "$OUT"

# A JPEG starts with FF D8. Check the signature, not the size: a 429 reply
# arrives as non-empty JSON and passes a "file is not empty" check.
is_jpeg() {
  [ -s "$1" ] || return 1
  [ "$(head -c 2 "$1" | xxd -p 2>/dev/null)" = "ffd8" ]
}

ok=0
skipped=0
failed=0

while IFS=$'\t' read -r name seed prompt; do
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue ;; esac

  target="$OUT/$name"

  if is_jpeg "$target"; then
    echo "skip  $name"
    skipped=$((skipped + 1))
    continue
  fi
  rm -f "$target"

  full="$prompt"
  [ -n "$TAIL" ] && full="$prompt, $TAIL"
  encoded=$(printf '%s' "$full" | sed 's/ /%20/g; s/,/%2C/g')
  url="https://image.pollinations.ai/prompt/${encoded}?width=1024&height=1280&nologo=true&model=flux&seed=${seed}"

  attempt=1
  while [ "$attempt" -le "$MAX_RETRIES" ]; do
    code=$(curl -s -o "$target" -w '%{http_code}' -L --max-time 180 "$url")

    if [ "$code" = "200" ] && is_jpeg "$target"; then
      echo "ok    $name  $(du -h "$target" | cut -f1)"
      ok=$((ok + 1))
      break
    fi

    rm -f "$target"

    if [ "$attempt" -eq "$MAX_RETRIES" ]; then
      echo "FAIL  $name  (http $code, attempts: $attempt)"
      failed=$((failed + 1))
      break
    fi

    # 429 = the queue is busy. Back off further each time: 5, 10, 20, 40 seconds.
    backoff=$((5 * (1 << (attempt - 1))))
    echo "retry $name  (http $code, waiting ${backoff}s)"
    sleep "$backoff"
    attempt=$((attempt + 1))
  done

  sleep "$GAP"
done < "$JOBS"

echo "---"
echo "generated: $ok   skipped: $skipped   failed: $failed"
echo "valid JPEGs in $OUT: $(find "$OUT" -type f -exec sh -c 'head -c2 "$1" | grep -q $"\xff\xd8"' _ {} \; -print 2>/dev/null | wc -l | tr -d ' ')"
[ "$failed" -gt 0 ] && echo "rerun the script — it will generate only the missing ones"
exit 0
