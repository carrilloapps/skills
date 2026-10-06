#!/usr/bin/env bash
# sync — vendor the canonical shared scripts (shared/scripts/*) byte-identical into every
# skills/<skill>/scripts/ folder, so each skill keeps working when installed alone.
#
# Usage: shared/sync.sh [--check]     (--check: report drift, change nothing, exit 1 on drift)
# PowerShell twin: shared/sync.ps1 (-Check).
set -u
REPO=$(cd "$(dirname "$0")/.." && pwd)
CHECK=0
case "${1-}" in --check) CHECK=1 ;; '') ;; -h|--help) echo "Usage: sync.sh [--check]"; exit 0 ;; *) echo "sync: unknown option: $1" >&2; exit 3 ;; esac

n=0 drift=0
for skill in "$REPO"/skills/*/; do
  [ -f "$skill/SKILL.md" ] || [ -d "$skill/frameworks" ] || continue
  for src in "$REPO"/shared/scripts/*; do
    [ -f "$src" ] || continue
    dest="$skill/scripts/$(basename "$src")"
    rel=${dest#"$REPO"/}; rel=${rel//\/\//\/}
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then continue; fi
    n=$((n + 1))
    if [ $CHECK -eq 1 ]; then echo "$n. drift: $rel"; drift=1
    else mkdir -p "$skill/scripts"; cp "$src" "$dest"; echo "$n. synced: $rel"; fi
  done
done
[ $n -eq 0 ] && echo "All vendored shared scripts are in sync."
exit $drift
