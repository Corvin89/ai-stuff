#!/bin/bash
# Tests for generate.sh. Run as: bash test-generate.sh
#
# No network. `curl` and `sleep` are stubbed on PATH, so the script's real
# logic is exercised — retries, backoff, idempotency — in under a second.
#
# Every case here is a defect that actually shipped. Do not delete one because
# it looks trivial; each of them reached main once.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT="$SCRIPT_DIR/generate.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

failures=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then
    printf '  ok    %s\n' "$1"
  else
    printf '  FAIL  %s\n          expected: [%s]\n          actual:   [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

# ---------------------------------------------------------------- stubs

mkdir -p "$WORK/bin"

cat > "$WORK/bin/curl" <<'STUB'
#!/bin/bash
target=""; url=""
while [ $# -gt 0 ]; do
  case $1 in
    -o) target=$2; shift 2 ;;
    -w|--max-time) shift 2 ;;
    -s|-L) shift ;;
    *) url=$1; shift ;;
  esac
done
printf '%s\n' "$url" >> "$STUB_LOG"
case "${STUB_MODE:-ok}" in
  429) printf '{"error":"Queue full for IP, max: 1"}' > "$target"; printf '429' ;;
  *)   printf '\377\330\377\340JFIF stub payload' > "$target"; printf '200' ;;
esac
STUB

# The script backs off 5, 10, 20 seconds between retries and pauses GAP
# between jobs. Real sleeps would make this suite take a minute per failure.
printf '#!/bin/bash\nexit 0\n' > "$WORK/bin/sleep"

chmod +x "$WORK/bin/curl" "$WORK/bin/sleep"
export PATH="$WORK/bin:$PATH"

# Sets RC and OUT. Not a command substitution: that runs in a subshell and
# would discard the exit status, which is one of the things under test.
run() { # out-dir jobs-file [tail]
  STUB_LOG="$WORK/urls.log" bash "$SCRIPT" "$1" "$2" "${3:-}" > "$WORK/last.out" 2>&1
  RC=$?
  OUT=$(cat "$WORK/last.out")
}

# ------------------------------------------------- unit: the two functions

# Sourced from the real file so the tests cannot drift from the implementation.
eval "$(sed -n '/^is_jpeg()/,/^}/p; /^urlencode()/,/^}/p' "$SCRIPT")"

echo "urlencode"
check "ASCII specials"    'vase%20%26%20bowl%20%232%2C%20blue' "$(urlencode 'vase & bowl #2, blue')"
# Regression: bash 3.2 returns a SIGNED char, so these came back as
# %FFFFFFFFFFFFFFC3 and the service silently rendered a different subject.
check "latin-1 accent"    'caf%C3%A9%20au%20lait'              "$(urlencode 'café au lait')"
check "all-multibyte"     '%C3%B1%C3%BC%C3%A9'                 "$(urlencode 'ñüé')"
check "em dash"           'a%20%E2%80%94%20b'                  "$(urlencode 'a — b')"
# `?` truncates the query string, taking model= and seed= with it; `%` would
# otherwise produce an invalid escape sequence.
check "question mark"     'what%20now%3F'                      "$(urlencode 'what now?')"
check "percent"           '50%25%20off'                        "$(urlencode '50% off')"
check "unreserved intact" 'a-b_c.d~e'                          "$(urlencode 'a-b_c.d~e')"
check "empty string"      ''                                   "$(urlencode '')"

if command -v python3 >/dev/null 2>&1; then
  for s in 'vase & bowl #2, blue' 'café au lait' 'ñüé åäö' 'a — b' 'what now? 50% off' 'a/b\c"d'"'"'e'; do
    check "matches urllib.parse.quote: $s" \
      "$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""))' "$s")" \
      "$(urlencode "$s")"
  done
else
  echo "  skip  urllib.parse.quote cross-check (no python3)"
fi

echo "is_jpeg"
printf '\377\330\377\340JFIF' > "$WORK/real.jpg"
printf '{"error":"Queue full for IP"}' > "$WORK/err429.jpg"   # the case that started all this
: > "$WORK/empty.jpg"
printf '\377' > "$WORK/truncated.jpg"
printf '\211PNG\r\n\032\n' > "$WORK/wrong.jpg"
for f in real:0 err429:1 empty:1 truncated:1 wrong:1; do
  is_jpeg "$WORK/${f%%:*}.jpg"
  check "${f%%:*}" "${f##*:}" "$?"
done

# ------------------------------------------------------ end-to-end: script

echo "clean run"
printf 'a.jpg\t1\tfirst prompt\nb.jpg\t2\tsecond prompt\n' > "$WORK/jobs.tsv"
run "$WORK/out1" "$WORK/jobs.tsv" "shared tail"
check "exit status"        "0" "$RC"
check "counters"           "generated: 2   skipped: 0   failed: 0" "$(echo "$OUT" | grep '^generated:')"
# This line reported 0 on every successful run for as long as the script existed.
check "tally is not zero"  "valid JPEGs in $WORK/out1: 2" "$(echo "$OUT" | grep '^valid JPEGs')"
check "prompt tail joined" "1" "$(grep -c 'first%20prompt%2C%20shared%20tail' "$WORK/urls.log")"

echo "jobs file with no trailing newline"
printf 'a.jpg\t1\tone\nb.jpg\t2\ttwo\nc.jpg\t3\tthree' > "$WORK/nonl.tsv"
run "$WORK/out2" "$WORK/nonl.tsv"
# The last job used to vanish here with no error of any kind.
check "last job generated" "3" "$(echo "$OUT" | grep -c '^ok ')"
check "c.jpg on disk"      "0" "$([ -f "$WORK/out2/c.jpg" ]; echo $?)"

echo "single job, no trailing newline"
printf 'solo.jpg\t7\tonly one' > "$WORK/solo.tsv"
run "$WORK/out3" "$WORK/solo.tsv"
check "generated"          "1" "$(echo "$OUT" | grep -c '^ok ')"

echo "comments and blank lines"
printf '# a comment\n\nreal.jpg\t1\tprompt\n' > "$WORK/cmt.tsv"
run "$WORK/out4" "$WORK/cmt.tsv"
check "only the real job"  "generated: 1   skipped: 0   failed: 0" "$(echo "$OUT" | grep '^generated:')"

echo "idempotent rerun"
: > "$WORK/urls.log"
run "$WORK/out1" "$WORK/jobs.tsv" "shared tail"
check "both skipped"       "generated: 0   skipped: 2   failed: 0" "$(echo "$OUT" | grep '^generated:')"
check "no requests made"   "0" "$(wc -l < "$WORK/urls.log" | tr -d ' ')"
check "exit status"        "0" "$RC"

echo "failure path"
printf 'z.jpg\t1\tdoomed\n' > "$WORK/fail.tsv"
STUB_MODE=429 run "$WORK/out5" "$WORK/fail.tsv"
# A caller could not previously tell a failed run from a clean one.
check "exit status"        "1" "$RC"
check "counted as failed"  "generated: 0   skipped: 0   failed: 1" "$(echo "$OUT" | grep '^generated:')"
# The 429 body is valid JSON and non-empty — a size check would have kept it.
check "429 body not kept"  "1" "$([ -f "$WORK/out5/z.jpg" ]; echo $?)"
check "retries attempted"  "4" "$(wc -l < "$WORK/urls.log" | tr -d ' ')"

echo "recovery after a failed run"
run "$WORK/out5" "$WORK/fail.tsv"
check "regenerated"        "0" "$RC"
check "counters"           "generated: 1   skipped: 0   failed: 0" "$(echo "$OUT" | grep '^generated:')"

echo "---"
if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
exit 0
