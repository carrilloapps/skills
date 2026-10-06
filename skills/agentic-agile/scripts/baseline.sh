#!/usr/bin/env bash
# baseline — accept today's findings so only NEW ones fail (brownfield adoption).
#
# Runs check-spec (per initiative, tickets included), analyze, audit-agile and trace from this
# folder with --json, and fingerprints every finding as tool|rule|file|message (line numbers
# excluded, so edits that only move text keep their fingerprint). --write stores the sorted,
# unique fingerprints in plans/agile/baseline.txt (versioned; --dry-run prints them instead);
# --check fails only on fingerprints that are not in the baseline and lists resolved ones
# (with --strict, resolved entries mean the baseline is stale: exit 2). Phase 0 first
# (check-structure). Writes only the baseline file. PowerShell twin: baseline.ps1.
#
# Usage: baseline.sh --write [--dry-run] | --check   [specs/<initiative> | --spec … | --all]
#                    [--root DIR] [--file PATH] [--today YYYY-MM-DD] [--strict] [--json]
#                    (--skip-structure exists for the parity tests only)
# Exit:  0 ok · 1 new findings (or gate closed) · 2 stale baseline with --strict · 3 config error
set -u
LC_ALL=C
export LC_ALL

ROOT=. SPEC= MODE= DRY=0 FILE=plans/agile/baseline.txt TODAY= STRICT=0 JSON=0 SKIP=0
die() { echo "baseline: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --write) MODE=write; shift ;;
    --check) MODE=check; shift ;;
    --dry-run) DRY=1; shift ;;
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --spec) [ $# -ge 2 ] || die "--spec needs a value"; SPEC=$2; shift 2 ;;
    --all) shift ;;
    --file) [ $# -ge 2 ] || die "--file needs a value"; FILE=$2; shift 2 ;;
    --today) [ $# -ge 2 ] || die "--today needs a value"; TODAY=$2; shift 2 ;;
    --strict) STRICT=1; shift ;;
    --json) JSON=1; shift ;;
    --skip-structure) SKIP=1; shift ;;
    -h|--help) echo "Usage: baseline.sh --write [--dry-run] | --check [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--file PATH] [--today YYYY-MM-DD] [--strict] [--json]"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$SPEC" ] || die "only one initiative folder is allowed"; SPEC=$1; shift ;;
  esac
done
[ -n "$MODE" ] || die "choose --write or --check"
[ $DRY -eq 1 ] && [ "$MODE" != write ] && die "--dry-run only applies to --write"
[ -d "$ROOT" ] || die "project root not found: $ROOT"
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done
FILE=${FILE//\\//}
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '%s' "$s"; }

# ── Phase 0 ──────────────────────────────────────────────────────────────────
if [ $SKIP -eq 0 ]; then
  CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  [ -f "$CS" ] || die "check-structure.sh not found next to baseline.sh"
  bash "$CS" --root "$ROOT" --json >/dev/null 2>&1; SX=$?
  [ $SX -eq 3 ] && die "check-structure failed on root: $ROOT"
  if [ $SX -ne 0 ]; then
    MSG="Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
    if [ $JSON -eq 1 ]; then
      printf '{"root":"%s","mode":"%s","gate":"closed","message":"%s","exit":1}\n' "$(jesc "$RL")" "$MODE" "$(jesc "$MSG")"
    else
      echo "baseline — $RL ($MODE)"
      echo "1. error structure [structure-gate] $MSG"
      echo "Result: gate closed — FAIL"
    fi
    exit 1
  fi
fi

NAMES=()
if [ -n "$SPEC" ]; then
  s=${SPEC//\\//}; while [ "${s%/}" != "$s" ]; do s=${s%/}; done
  { [ -d "$ROOT/$s" ] || { [ -d "$s" ] && [ -d "$ROOT/specs/${s##*/}" ]; }; } || die "initiative folder not found: $ROOT/$s"
  NAMES+=("${s##*/}"); SCOPE=(--spec "specs/${s##*/}")
else
  SCOPE=()
  [ -d "$ROOT/specs" ] && while IFS= read -r d; do [ -n "$d" ] && NAMES+=("$d"); done < <(cd "$ROOT/specs" && for d in */; do [ -d "$d" ] && printf '%s\n' "${d%/}"; done | sort)
fi

# ── Collect fingerprints ─────────────────────────────────────────────────────
RE_F='"file":"((\\.|[^"\\])*)","line":[0-9]+,"rule":"([^"]*)","message":"((\\.|[^"\\])*)"'
FP=()
collect() { # tool json prefix (prefix is prepended to file names that do not start with plans/ or specs/)
  local rest=$2 f
  while [[ $rest =~ $RE_F ]]; do
    f=${BASH_REMATCH[1]}
    case "$f" in plans/*|specs/*|structure) ;; *) f="$3$f" ;; esac
    FP+=("$1|${BASH_REMATCH[3]}|$f|${BASH_REMATCH[4]}")
    rest=${rest#*"${BASH_REMATCH[0]}"}
  done
}
run() { # tool args… → OUT (stdout) ; dies on configuration errors
  local t=$1; shift
  OUT=$(bash "$(cd "$(dirname "$0")" && pwd)/$t.sh" "$@" 2>/dev/null); local x=$?
  [ $x -eq 3 ] && die "$t failed with a configuration error"
  return 0
}
for d in ${NAMES[@]+"${NAMES[@]}"}; do
  run check-spec "$ROOT/specs/$d" --root "$ROOT" --skip-structure --tickets --json
  collect check-spec "$OUT" "specs/$d/"
done
run analyze --root "$ROOT" --skip-structure --json ${SCOPE[@]+"${SCOPE[@]}"}; collect analyze "$OUT" ""
AA=(--root "$ROOT" --json); [ -n "$TODAY" ] && AA+=(--today "$TODAY")
run audit-agile "${AA[@]}"; collect audit-agile "$OUT" ""
run trace --root "$ROOT" --skip-structure --json ${SCOPE[@]+"${SCOPE[@]}"}; collect trace "$OUT" ""

CUR=()
while IFS= read -r l; do [ -n "$l" ] && CUR+=("$l"); done < <(for l in ${FP[@]+"${FP[@]}"}; do printf '%s\n' "$l"; done | sort -u)

# ── Write ────────────────────────────────────────────────────────────────────
if [ "$MODE" = write ]; then
  if [ $DRY -eq 0 ]; then
    mkdir -p "$(dirname "$ROOT/$FILE")"
    {
      echo "# agentic-agile baseline — accepted findings (tool|rule|file|message), one per line."
      echo "# Regenerate with scripts/baseline --write; scripts/baseline --check fails only on findings not listed here."
      for l in ${CUR[@]+"${CUR[@]}"}; do printf '%s\n' "$l"; done
    } >"$ROOT/$FILE"
  fi
  if [ $JSON -eq 1 ]; then
    if [ $DRY -eq 1 ]; then dj=true; else dj=false; fi
    printf '{"root":"%s","mode":"write","dry_run":%s,"file":"%s","fingerprints":[' "$(jesc "$RL")" "$dj" "$(jesc "$FILE")"
    for ((i = 0; i < ${#CUR[@]}; i++)); do [ $i -gt 0 ] && printf ','; printf '"%s"' "$(jesc "${CUR[i]}")"; done
    printf '],"count":%d,"exit":0}\n' ${#CUR[@]}
  else
    echo "baseline — $RL (write)"
    for ((i = 0; i < ${#CUR[@]}; i++)); do printf '%d. %s\n' $((i + 1)) "${CUR[i]}"; done
    if [ $DRY -eq 1 ]; then echo "Result: would write ${#CUR[@]} fingerprint(s) to $FILE (dry run)"
    else echo "Result: wrote ${#CUR[@]} fingerprint(s) to $FILE"; fi
  fi
  exit 0
fi

# ── Check ────────────────────────────────────────────────────────────────────
[ -f "$ROOT/$FILE" ] || die "baseline not found: $FILE (run --write first)"
BASE=()
while IFS= read -r l || [ -n "$l" ]; do
  l=${l%$'\r'}
  case "$l" in ''|'#'*) continue ;; esac
  BASE+=("$l")
done <"$ROOT/$FILE"
NEW=() RES=() ACC=0
for c in ${CUR[@]+"${CUR[@]}"}; do
  hit=0; for b in ${BASE[@]+"${BASE[@]}"}; do [ "$b" = "$c" ] && { hit=1; break; }; done
  if [ $hit -eq 1 ]; then ACC=$((ACC + 1)); else NEW+=("$c"); fi
done
while IFS= read -r b; do
  [ -n "$b" ] || continue
  hit=0; for c in ${CUR[@]+"${CUR[@]}"}; do [ "$b" = "$c" ] && { hit=1; break; }; done
  [ $hit -eq 1 ] || RES+=("$b")
done < <(for b in ${BASE[@]+"${BASE[@]}"}; do printf '%s\n' "$b"; done | sort -u)
EXIT=0
if [ ${#NEW[@]} -gt 0 ]; then EXIT=1; elif [ $STRICT -eq 1 ] && [ ${#RES[@]} -gt 0 ]; then EXIT=2; fi

if [ $JSON -eq 1 ]; then
  printf '{"root":"%s","mode":"check","file":"%s","new":[' "$(jesc "$RL")" "$(jesc "$FILE")"
  for ((i = 0; i < ${#NEW[@]}; i++)); do [ $i -gt 0 ] && printf ','; printf '"%s"' "$(jesc "${NEW[i]}")"; done
  printf '],"resolved":['
  for ((i = 0; i < ${#RES[@]}; i++)); do [ $i -gt 0 ] && printf ','; printf '"%s"' "$(jesc "${RES[i]}")"; done
  if [ $STRICT -eq 1 ]; then st=true; else st=false; fi
  printf '],"accepted":%d,"strict":%s,"exit":%d}\n' $ACC "$st" $EXIT
else
  echo "baseline — $RL (check)"
  if [ ${#NEW[@]} -eq 0 ]; then echo "No new findings."; else
    echo "New findings:"
    for ((i = 0; i < ${#NEW[@]}; i++)); do printf '%d. %s\n' $((i + 1)) "${NEW[i]}"; done
  fi
  if [ ${#RES[@]} -gt 0 ]; then
    echo "Resolved (no longer reported; refresh with --write):"
    for ((i = 0; i < ${#RES[@]}; i++)); do printf '%d. %s\n' $((i + 1)) "${RES[i]}"; done
  fi
  case $EXIT in 0) v=PASS ;; 1) v=FAIL ;; *) v=WARN ;; esac
  echo "Result: ${#NEW[@]} new, ${#RES[@]} resolved, $ACC accepted — $v"
fi
exit $EXIT
