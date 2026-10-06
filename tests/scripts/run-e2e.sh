#!/usr/bin/env bash
# run-e2e.sh — rebuild the agentic-agile end-to-end example project from
# skills/agentic-agile/examples/end-to-end.md and run every validator on it.
# Each "### `path`" section followed by a fenced block becomes one file.
# Usage: tests/scripts/run-e2e.sh [--keep]   (exit 0 = every check passed)
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO/skills/agentic-agile"
SRC="$SKILL/examples/end-to-end.md"
WORK="$REPO/tests/scripts/.work/e2e"
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1

rm -rf "$WORK"; mkdir -p "$WORK"
# Extract: path from the heading, content between the first fence after it and its matching close.
awk -v out="$WORK" '
  { sub(/\r$/, "") }   # tolerate CRLF checkouts (Windows core.autocrlf)
  /^### `[^`]+`/ { p = $0; sub(/^### `/, "", p); sub(/`.*$/, "", p); path = p; next }
  path != "" && fence == "" && /^(```|````)/ { match($0, /^`+/); fence = substr($0, 1, RLENGTH); file = out "/" path
    d = file; sub(/\/[^\/]*$/, "", d); system("mkdir -p \"" d "\""); printf "" > file; next }
  fence != "" && $0 == fence { close(file); fence = ""; path = ""; n++; next }
  fence != "" { print >> file }
  END { print n " files extracted" > "/dev/stderr" }
' "$SRC"
mkdir -p "$WORK/plans/drafts"

FAIL=0; n=0
run() {
  n=$((n + 1)); local label="$1"; shift
  if out=$("$@" 2>&1); then printf '%d. pass %s\n' "$n" "$label"
  else printf '%d. FAIL %s (exit %s)\n%s\n' "$n" "$label" "$?" "$out"; FAIL=1; fi
}
S="$SKILL/scripts"; SPEC="$WORK/specs/invoice-reminders"
# Same checks with every available implementation (bash always; pwsh / Windows PowerShell when present).
RUNNERS=("bash|sh")
command -v pwsh >/dev/null 2>&1 && RUNNERS+=("pwsh -NoProfile -File|ps1")
command -v powershell.exe >/dev/null 2>&1 && RUNNERS+=("powershell.exe -NoProfile -ExecutionPolicy Bypass -File|ps1")
for r in "${RUNNERS[@]}"; do
  cmd=${r%|*} ext=${r#*|}
  # shellcheck disable=SC2086
  run "[$cmd] check-structure --strict" $cmd "$S/check-structure.$ext" --root "$WORK" --strict
  run "[$cmd] check-spec --strict --tickets" $cmd "$S/check-spec.$ext" "$SPEC" --root "$WORK" --strict --tickets
  run "[$cmd] check-spec --all" $cmd "$S/check-spec.$ext" --root "$WORK" --all
  run "[$cmd] trace" $cmd "$S/trace.$ext" "$SPEC" --root "$WORK"
  run "[$cmd] analyze" $cmd "$S/analyze.$ext" "$SPEC" --root "$WORK"
  run "[$cmd] audit-agile" $cmd "$S/audit-agile.$ext" --root "$WORK" --today 2026-10-05
  run "[$cmd] baseline --write --dry-run" $cmd "$S/baseline.$ext" --write --dry-run --root "$WORK" --today 2026-10-05
  run "[$cmd] doctor" $cmd "$S/doctor.$ext" --root "$WORK" --today 2026-10-05
  run "[$cmd] aa converge" $cmd "$S/aa.$ext" converge invoice-reminders --root "$WORK"
done

[ $KEEP -eq 1 ] || rm -rf "$WORK"
[ $FAIL -eq 0 ] && echo "End-to-end example: all checks passed" || echo "End-to-end example: FAILED"
exit $FAIL
