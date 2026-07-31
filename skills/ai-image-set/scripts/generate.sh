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
#
# Exit status: 0 if every job produced a valid JPEG, 1 if any job failed.

set -u

OUT=${1:?output directory required}
JOBS=${2:?jobs file required}
TAIL=${3:-}

MAX_RETRIES=4
GAP=2 # pause between requests, to stay clear of the queue limit

mkdir -p "$OUT"

# A JPEG starts with FF D8. Check the signature, not the size: the 429
# response arrives as non-empty JSON and passes any "file is not empty" test.
# od rather than xxd — od is POSIX and always present, xxd ships with vim.
is_jpeg() {
  [ -s "$1" ] || return 1
  [ "$(LC_ALL=C od -An -N2 -tx1 "$1" | tr -d ' \n')" = "ffd8" ]
}

# Percent-encode a string for use in the URL path. The prompt is user prose,
# so it cannot be pasted in raw: `&` would append a query parameter of its own
# and `#` would truncate the URL at the fragment marker. Encoding only spaces
# and commas is not enough.
urlencode() {
  local LC_ALL=C
  local string=$1 out='' char hex i
  for ((i = 0; i < ${#string}; i++)); do
    char=${string:i:1}
    case $char in
      [a-zA-Z0-9._~-]) out+=$char ;;
      *)
        printf -v hex '%%%02X' "'$char"
        out+=$hex
        ;;
    esac
  done
  printf '%s' "$out"
}

ok=0
skipped=0
failed=0

# `|| [ -n "$name" ]` keeps the last job when the file has no trailing
# newline: read returns non-zero there but has already filled the fields,
# and without this the final image is skipped with no error at all.
while IFS=$'\t' read -r name seed prompt || [ -n "${name:-}" ]; do
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
  encoded=$(urlencode "$full")
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

# Count with the same signature check used above. The previous one-liner
# grepped for the literal text \xff\xd8 and so always reported zero.
valid=0
while IFS= read -r file; do
  is_jpeg "$file" && valid=$((valid + 1))
done < <(find "$OUT" -type f)

echo "---"
echo "generated: $ok   skipped: $skipped   failed: $failed"
echo "valid JPEGs in $OUT: $valid"

if [ "$failed" -gt 0 ]; then
  echo "rerun the script — it will only regenerate what is missing"
  exit 1
fi
exit 0
