#!/usr/bin/env bash
# discover — deterministic sweep of the project into one inventory list with stable IDs.
#
# Two input kinds, combinable, both normalized into the same table:
#   --pattern RE   every line of every text file under the root that matches RE (label Verified:
#                  the line was read this run and carries its path:line)
#   --from FILE    one item per line from a list the agent already produced (web, MCP, tracker,
#                  another tool). Bullets and numbering are stripped; headings, fences and table
#                  rows are ignored; a leading `path:line` becomes the location (label Documented).
# Items are deduplicated by location + text, numbered I001.., and written to
# plans/initiatives/<slug>/inventory.md (or --out). Only that file is written. No network.
# The deep part of a deep search (facet expansion, MCP and web sources, saturation) is the agent's
# protocol in frameworks/discover.md; this script is the reproducible half of it.
#
# Patterns are regular expressions limited to the syntax that behaves identically in POSIX ERE and
# .NET: literals, character classes, anchors, alternation, grouping, quantifiers. PowerShell twin:
# discover.ps1.
#
# Usage: discover.sh <slug> [--pattern RE]... [--from FILE]... [--root DIR] [--out PATH]
#                    [--include GLOB]... [--exclude GLOB]... [--ext EXT]... [--ignore-case]
#                    [--limit N] [--max-bytes N] [--label LABEL] [--json] [--dry-run] [--force]
#                    (--skip-structure exists for the parity tests only)
# Exit:  0 items inventoried · 1 nothing found, gate closed, or output exists without --force
#        3 configuration error
set -u
LC_ALL=C
export LC_ALL

ROOT=. SLUG= OUT= LIMIT=200 MAXB=1048576 LABEL= JSON=0 DRY=0 FORCE=0 SKIP=0 ICASE=0
PAT=() FROM=() INC=() EXC=() EXT=()
EXT_DEFAULT="md txt json jsonl yml yaml toml ini cfg conf env properties sh bash zsh ps1 psm1 py js mjs cjs ts tsx jsx vue svelte go rs java kt kts swift c h cpp cc hpp cs rb php pl sql html css scss sass less xml gradle tf tfvars graphql proto csv tsv"
PRUNE=".git node_modules .memory dist build out vendor .venv venv target coverage .next .nuxt .cache __pycache__ .terraform graphify-out .work"
die() { echo "discover: $1" >&2; exit 3; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --pattern) [ $# -ge 2 ] || die "--pattern needs a value"; PAT+=("$2"); shift 2 ;;
    --from) [ $# -ge 2 ] || die "--from needs a value"; FROM+=("$2"); shift 2 ;;
    --include) [ $# -ge 2 ] || die "--include needs a value"; INC+=("$2"); shift 2 ;;
    --exclude) [ $# -ge 2 ] || die "--exclude needs a value"; EXC+=("$2"); shift 2 ;;
    --ext) [ $# -ge 2 ] || die "--ext needs a value"; EXT+=("${2#.}"); shift 2 ;;
    --out) [ $# -ge 2 ] || die "--out needs a value"; OUT=$2; shift 2 ;;
    --label) [ $# -ge 2 ] || die "--label needs a value"; LABEL=$2; shift 2 ;;
    --limit) [ $# -ge 2 ] || die "--limit needs a value"; LIMIT=$2; shift 2 ;;
    --max-bytes) [ $# -ge 2 ] || die "--max-bytes needs a value"; MAXB=$2; shift 2 ;;
    --ignore-case) ICASE=1; shift ;;
    --json) JSON=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --force) FORCE=1; shift ;;
    --skip-structure) SKIP=1; shift ;;
    -h|--help)
      echo "Usage: discover <slug> [--pattern RE]... [--from FILE]... [--root DIR] [--out PATH] [--include GLOB]... [--exclude GLOB]... [--ext EXT]... [--ignore-case] [--limit N] [--max-bytes N] [--label LABEL] [--json] [--dry-run] [--force]"
      echo "  <slug>         initiative in kebab-case; output defaults to plans/initiatives/<slug>/inventory.md"
      echo "  --pattern RE   sweep the project for lines matching RE (repeatable)"
      echo "  --from FILE    normalize a list the agent already produced, one item per line (repeatable)"
      echo "  --include/--exclude  glob on the relative path, * crosses directory separators"
      echo "  --ext EXT      add a file extension to the text allow-list (repeatable)"
      exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$SLUG" ] || die "only one initiative slug is allowed"; SLUG=$1; shift ;;
  esac
done

[ -n "$SLUG" ] || die "discover needs an initiative slug (e.g. discover invoice-export --pattern TODO)"
[[ $SLUG =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid slug: $SLUG (use kebab-case: a-z, 0-9, -)"
[ ${#PAT[@]} -gt 0 ] || [ ${#FROM[@]} -gt 0 ] || die "nothing to search: pass at least one --pattern or --from"
[[ $LIMIT =~ ^[0-9]+$ ]] && [ "$LIMIT" -gt 0 ] || die "--limit must be a positive integer"
[[ $MAXB =~ ^[0-9]+$ ]] && [ "$MAXB" -gt 0 ] || die "--max-bytes must be a positive integer"
[ -d "$ROOT" ] || die "project root not found: $ROOT"
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done
[ -n "$OUT" ] || OUT="plans/initiatives/$SLUG/inventory.md"
OUT=${OUT//\\//}
case "$OUT" in /*|[A-Za-z]:*) die "--out must be a path relative to the project" ;; esac
case "/$OUT/" in */../*) die "--out must not contain '..'" ;; esac
case "$LABEL" in ''|Verified|Documented|Proposed) ;; *) die "--label must be Verified, Documented or Proposed" ;; esac

jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; printf '%s' "$s" | tr -d '\000-\010\013-\037'; }

# ── Phase 0 ──────────────────────────────────────────────────────────────────
# The inventory is a plan artifact, so the structure gate owns it like every other one.
if [ $SKIP -eq 0 ]; then
  CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  [ -f "$CS" ] || die "check-structure.sh not found next to discover.sh"
  bash "$CS" --root "$ROOT" --json >/dev/null 2>&1; SX=$?
  [ $SX -eq 3 ] && die "check-structure failed on root: $RL"
  if [ $SX -ne 0 ]; then
    MSG="Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
    if [ $JSON -eq 1 ]; then
      printf '{"root":"%s","slug":"%s","gate":"closed","message":"%s","exit":1}\n' "$(jesc "$RL")" "$SLUG" "$(jesc "$MSG")"
    else
      echo "discover — $RL ($SLUG)"
      echo "1. error structure [structure-gate] $MSG"
      echo "Result: gate closed — FAIL"
    fi
    exit 1
  fi
fi

if [ -e "$ROOT/$OUT" ] && [ $FORCE -eq 0 ] && [ $DRY -eq 0 ]; then
  MSG="$OUT exists; re-run with --force to replace it (IDs are renumbered) or pass --out PATH"
  if [ $JSON -eq 1 ]; then
    printf '{"root":"%s","slug":"%s","out":"%s","message":"%s","exit":1}\n' "$(jesc "$RL")" "$SLUG" "$(jesc "$OUT")" "$(jesc "$MSG")"
  else
    echo "discover — $RL ($SLUG)"
    echo "1. skip $OUT (exists)"
    echo "Result: $MSG — FAIL"
  fi
  exit 1
fi

# ── Sources ──────────────────────────────────────────────────────────────────
SRC_ID=() SRC_KIND=() SRC_VAL=()
for p in ${PAT[@]+"${PAT[@]}"}; do SRC_ID+=("S$((${#SRC_ID[@]} + 1))"); SRC_KIND+=(sweep); SRC_VAL+=("$p"); done
for f in ${FROM[@]+"${FROM[@]}"}; do SRC_ID+=("S$((${#SRC_ID[@]} + 1))"); SRC_KIND+=(list); SRC_VAL+=("$f"); done

EXTS=" $EXT_DEFAULT ${EXT[*]-} "
text_ext() { # $1 relative path → 0 when its extension is in the allow-list
  local e=${1##*/}
  case "$e" in *.*) e=${e##*.} ;; *) return 1 ;; esac
  e=$(printf '%s' "$e" | tr 'A-Z' 'a-z')
  case "$EXTS" in *" $e "*) return 0 ;; esac
  return 1
}
keep_path() { # $1 relative path → 0 when the include/exclude globs keep it
  local g hit=0
  if [ ${#INC[@]} -gt 0 ]; then
    for g in "${INC[@]}"; do case "$1" in $g) hit=1; break ;; esac; done
    [ $hit -eq 1 ] || return 1
  fi
  for g in ${EXC[@]+"${EXC[@]}"}; do case "$1" in $g) return 1 ;; esac; done
  return 0
}
norm() { # $1 raw text → NORM (single line, whitespace collapsed, bounded length)
  local s=$1
  s=${s//$'\t'/ }
  s=$(printf '%s' "$s" | tr -s ' ')
  s=${s#"${s%%[![:space:]]*}"}; s=${s%"${s##*[![:space:]]}"}
  [ ${#s} -le 160 ] || s="${s:0:157}..."
  NORM=$s
}
cell() { CELL=${1//|/\\|}; }   # escape pipes only where a Markdown table needs it

ITEM=() LOC=() SRC=() LAB=() SEEN=$'\n' COUNT=0 TRUNC=0
add_item() { # $1 text, $2 location, $3 source id, $4 label
  local t
  norm "$1"; t=$NORM
  [ -n "$t" ] || return 0
  case "$SEEN" in *$'\n'"$2|$t"$'\n'*) return 0 ;; esac
  if [ $COUNT -ge "$LIMIT" ]; then TRUNC=1; return 0; fi
  SEEN+="$2|$t"$'\n'
  ITEM+=("$t"); LOC+=("$2"); SRC+=("$3"); LAB+=("$4"); COUNT=$((COUNT + 1))
}

# ── Sweep ────────────────────────────────────────────────────────────────────
if [ ${#PAT[@]} -gt 0 ]; then
  PRUNE_ARGS=()
  for d in $PRUNE; do
    [ ${#PRUNE_ARGS[@]} -eq 0 ] || PRUNE_ARGS+=(-o)
    PRUNE_ARGS+=(-name "$d")
  done
  [ $ICASE -eq 1 ] && shopt -s nocasematch
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    rel=${p#"$ROOT"/}; rel=${rel#./}
    rel=${rel//\\//}
    [ "$rel" = "$OUT" ] && continue
    text_ext "$rel" || continue
    keep_path "$rel" || continue
    sz=$(wc -c <"$p" 2>/dev/null || echo 0)
    [ "$sz" -le "$MAXB" ] || continue
    ln=0
    while IFS= read -r line || [ -n "$line" ]; do
      ln=$((ln + 1))
      line=${line%$'\r'}
      for ((i = 0; i < ${#PAT[@]}; i++)); do
        if [[ $line =~ ${PAT[i]} ]]; then
          add_item "$line" "$rel:$ln" "S$((i + 1))" "${LABEL:-Verified}"
          break
        fi
      done
    done <"$p"
  done < <(find "$ROOT" -type d \( "${PRUNE_ARGS[@]}" \) -prune -o -type f -print 2>/dev/null | sort)
  [ $ICASE -eq 1 ] && shopt -u nocasematch
fi

# ── External lists ───────────────────────────────────────────────────────────
RE_LOC='^([^[:space:]|]+:[0-9]+)[[:space:]]+(.*)$'
RE_BULLET='^[[:space:]]*([-*+][[:space:]]+|[0-9]+[.)][[:space:]]+)'
for ((k = 0; k < ${#FROM[@]}; k++)); do
  lf=${FROM[k]//\\//}
  case "$lf" in /*|[A-Za-z]:*) lp=$lf ;; *) lp=$ROOT/$lf ;; esac
  [ -f "$lp" ] || die "--from file not found: ${FROM[k]}"
  sid="S$((${#PAT[@]} + k + 1))"
  fence=0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case "$line" in '```'*|'~~~'*) fence=$((1 - fence)); continue ;; esac
    [ $fence -eq 1 ] && continue
    case "$line" in '' | '#'* | '|'* | '>'*) continue ;; esac
    while [[ $line =~ $RE_BULLET ]]; do line=${line#"${BASH_REMATCH[0]}"}; done
    loc=-
    if [[ $line =~ $RE_LOC ]]; then loc=${BASH_REMATCH[1]}; line=${BASH_REMATCH[2]}; fi
    add_item "$line" "$loc" "$sid" "${LABEL:-Documented}"
  done <"$lp"
done

# ── Report ───────────────────────────────────────────────────────────────────
pad() { printf 'I%03d' "$1"; }
if [ $COUNT -eq 0 ]; then
  MSG="no item matched; widen the pattern, add --ext, or check --from"
  if [ $JSON -eq 1 ]; then
    printf '{"root":"%s","slug":"%s","out":"%s","items":[],"count":0,"truncated":false,"message":"%s","exit":1}\n' "$(jesc "$RL")" "$SLUG" "$(jesc "$OUT")" "$(jesc "$MSG")"
  else
    echo "discover — $RL ($SLUG)"
    echo "Result: 0 item(s) — $MSG"
  fi
  exit 1
fi

if [ $JSON -eq 1 ]; then
  printf '{"root":"%s","slug":"%s","out":"%s","sources":[' "$(jesc "$RL")" "$SLUG" "$(jesc "$OUT")"
  for ((i = 0; i < ${#SRC_ID[@]}; i++)); do
    [ $i -gt 0 ] && printf ','
    printf '{"id":"%s","kind":"%s","value":"%s"}' "${SRC_ID[i]}" "${SRC_KIND[i]}" "$(jesc "${SRC_VAL[i]}")"
  done
  printf '],"items":['
  for ((i = 0; i < COUNT; i++)); do
    [ $i -gt 0 ] && printf ','
    printf '{"id":"%s","item":"%s","location":"%s","source":"%s","label":"%s"}' "$(pad $((i + 1)))" "$(jesc "${ITEM[i]}")" "$(jesc "${LOC[i]}")" "${SRC[i]}" "${LAB[i]}"
  done
  if [ $TRUNC -eq 1 ]; then tj=true; else tj=false; fi
  if [ $DRY -eq 1 ]; then dj=true; else dj=false; fi
  printf '],"count":%d,"truncated":%s,"dry_run":%s,"exit":0}\n' "$COUNT" "$tj" "$dj"
else
  echo "discover — $RL ($SLUG)"
  for ((i = 0; i < COUNT; i++)); do printf '%s %s — %s\n' "$(pad $((i + 1)))" "${LOC[i]}" "${ITEM[i]}"; done
  [ $TRUNC -eq 1 ] && echo "Truncated at --limit $LIMIT; narrow the pattern or raise the limit to see the rest."
  if [ $DRY -eq 1 ]; then echo "Result: $COUNT item(s) from ${#SRC_ID[@]} source(s) — would write $OUT (dry run)"
  else echo "Result: $COUNT item(s) from ${#SRC_ID[@]} source(s) — wrote $OUT"; fi
fi

[ $DRY -eq 1 ] && exit 0

mkdir -p "$(dirname "$ROOT/$OUT")"
{
  echo "# Inventory: $SLUG"
  echo
  echo "Generated by \`scripts/discover\` from ${#SRC_ID[@]} source(s). One row per item found, deduplicated by location and text. IDs are stable inside this file and are never reused; re-running with \`--force\` renumbers them."
  echo
  echo "Labels: **Verified** — the line was read this run and carries its \`path:line\` · **Documented** — it comes from a list produced elsewhere · **Proposed** — the agent's own suggestion (never written by the script)."
  echo
  echo "Sources:"
  echo
  for ((i = 0; i < ${#SRC_ID[@]}; i++)); do
    if [ "${SRC_KIND[i]}" = sweep ]; then printf '%d. %s — sweep for `%s`\n' $((i + 1)) "${SRC_ID[i]}" "${SRC_VAL[i]}"
    else printf '%d. %s — list `%s`\n' $((i + 1)) "${SRC_ID[i]}" "${SRC_VAL[i]}"; fi
  done
  echo
  echo "| ID | Item | Location | Source | Label | Priority | Status |"
  echo "|----|------|----------|--------|-------|----------|--------|"
  for ((i = 0; i < COUNT; i++)); do
    cell "${ITEM[i]}"
    printf '| %s | %s | %s | %s | %s | - | open |\n' "$(pad $((i + 1)))" "$CELL" "${LOC[i]}" "${SRC[i]}" "${LAB[i]}"
  done
  echo
  [ $TRUNC -eq 1 ] && { echo "Truncated at \`--limit $LIMIT\`: the sweep found more than this file lists."; echo; }
  echo "Next: set \`Priority\` per row with the team (P1/P2/P3), drop the rows that are not work, then split the rest into one self-contained brief per item with \`scripts/fanout $SLUG --from $OUT\`."
} >"$ROOT/$OUT"
exit 0
