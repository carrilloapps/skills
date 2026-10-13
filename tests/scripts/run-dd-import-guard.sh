#!/usr/bin/env bash
# run-dd-import-guard.sh — behavioural test for the path guard in the SAR lab's `dd-import.sh`.
#
# `dd-import.sh` posts one results file to DefectDojo; its file argument is operator input, so the
# guard must keep the resolved path inside the results directory (Socket anomaly alert, 2026-10-12).
# This test extracts the template that ships in the skill, rewrites the container path `/state` to a
# sandbox, stubs `curl`, and asserts the outcome of every traversal case. It also asserts that the
# instantiated copy under `.memory/devsecops/config/` is byte-identical to the shipped template.
#
# Reads: the repository. Writes: a temp sandbox only. No network, no installs. Exit 0 clean, 1 failure.
# Usage: bash tests/scripts/run-dd-import-guard.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$REPO_ROOT/skills/sar-cybersecurity/frameworks/docker-lab.md"
COPY="$REPO_ROOT/.memory/devsecops/config/dd-import.sh"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# The fenced sh block that follows the `dd-import.sh` heading in the framework.
awk '/^### `dd-import\.sh`/{f=1} f&&/^```sh$/{c=1;next} c&&/^```$/{exit} c' "$DOC" >"$SANDBOX/template.sh"
[ -s "$SANDBOX/template.sh" ] || { echo "FAIL: no dd-import.sh block found in $DOC"; exit 1; }

if ! diff -q "$SANDBOX/template.sh" "$COPY" >/dev/null; then
  echo "FAIL: .memory/devsecops/config/dd-import.sh drifted from the template in docker-lab.md"
  diff "$SANDBOX/template.sh" "$COPY" || true
  exit 1
fi

mkdir -p "$SANDBOX/bin" "$SANDBOX/state/curl" "$SANDBOX/state/results/2026-10-12" "$SANDBOX/outside"
printf '#!/bin/sh\nfor a in "$@"; do case "$a" in file=@*) echo "SENT ${a#file=@}";; esac; done\n' >"$SANDBOX/bin/curl"
chmod +x "$SANDBOX/bin/curl"
: >"$SANDBOX/state/curl/dojo-api.rc"
echo '{}' >"$SANDBOX/state/results/2026-10-12/njsscan.json"
echo 'SECRET' >"$SANDBOX/outside/passwd"
sed "s#/state#$SANDBOX/state#g" "$SANDBOX/template.sh" >"$SANDBOX/dd-import.sh"

symlinks=yes
ln -s "$SANDBOX/outside/passwd" "$SANDBOX/state/results/link.json" 2>/dev/null || symlinks=no
ln -s "$SANDBOX/outside" "$SANDBOX/state/results/esc" 2>/dev/null || symlinks=no
[ -L "$SANDBOX/state/results/link.json" ] || symlinks=no   # Git Bash copies instead of linking

fails=0
expect() {  # expect SENT|REJECT <file argument> <case name>
  local want="$1" arg="$2" name="$3" out rc=0
  out="$(PATH="$SANDBOX/bin:$PATH" sh "$SANDBOX/dd-import.sh" "njsscan Scan" "$arg" p e 2>&1)" || rc=$?
  if [ "$want" = SENT ]; then
    # The sandbox path is compared by suffix: the script resolves it physically, and on some
    # systems (Git Bash) the physical form of a temp directory differs from the one mktemp printed.
    if [ "$rc" -eq 0 ] && grep -q "^SENT .*/state/results/$arg\$" <<<"$out"; then
      printf 'ok    %-22s %s\n' "$name" "$out"; return
    fi
  elif [ "$rc" -eq 2 ] && ! grep -q '^SENT' <<<"$out"; then
    printf 'ok    %-22s %s\n' "$name" "$out"; return
  fi
  printf 'FAIL  %-22s want %s, rc=%s: %s\n' "$name" "$want" "$rc" "$out"; fails=$((fails + 1))
}

expect SENT   "2026-10-12/njsscan.json"          "results file"
expect REJECT "../../../etc/passwd"              "traversal"
expect REJECT "2026-10-12/../../../etc/passwd"   "nested traversal"
expect REJECT "/etc/passwd"                      "absolute path"
expect REJECT "2026-10-12/nope.json"             "missing file"
expect REJECT ""                                 "empty argument"
if [ "$symlinks" = yes ]; then
  expect REJECT "link.json"  "symlinked file"
  expect REJECT "esc/passwd" "symlinked directory"
else
  echo "skip  symlink cases        (this filesystem does not create symlinks)"
fi

if [ "$fails" -gt 0 ]; then echo "dd-import guard: $fails case(s) failed"; exit 1; fi
echo "dd-import guard: all cases pass"
