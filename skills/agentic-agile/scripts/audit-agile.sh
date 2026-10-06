#!/usr/bin/env bash
# audit-agile — hygiene of the team operating system after Phase 0 (read-only).
#
# Reports, in this order:
#   1. review-overdue      decision records whose "Review on" date has passed (Superseded/Revoked skipped)
#   2. template-drift      section headings of a skill template missing in its plans/agile/ copy
#   3. broken-link         relative Markdown links in plans/ and specs/ that point nowhere
#   4. sprint-report       sprints whose planning.md end date has passed without a report.md
#   5. done-unverified     initiatives in state Done whose specs/<slug>/verification.md is
#                          missing, has no filled verdict, or says ❌
# Fenced code and code spans are ignored. PowerShell twin: audit-agile.ps1 (same output).
#
# Usage: audit-agile.sh [--root DIR] [--json] [--templates DIR] [--today YYYY-MM-DD]
#        (--templates defaults to the skill's templates/ next to this script; --today to the system date)
# Exit:  0 clean · 1 findings · 3 configuration error
set -u
LC_ALL=C
export LC_ALL

ROOT=. JSON=0 TPL= TODAY=
die() { echo "audit-agile: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --templates) [ $# -ge 2 ] || die "--templates needs a value"; TPL=$2; shift 2 ;;
    --today) [ $# -ge 2 ] || die "--today needs a value"; TODAY=$2; shift 2 ;;
    --json) JSON=1; shift ;;
    -h|--help) echo "Usage: audit-agile.sh [--root DIR] [--json] [--templates DIR] [--today YYYY-MM-DD]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"
if [ -n "$TPL" ]; then [ -d "$TPL" ] || die "templates folder not found: $TPL"
else TPL="$(cd "$(dirname "$0")" && pwd)/../templates"; fi
[ -n "$TODAY" ] || TODAY=$(date +%Y-%m-%d)
[[ $TODAY =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "--today must be YYYY-MM-DD"
LABEL=${ROOT//\\//}
while [ "${LABEL%/}" != "$LABEL" ] && [ "$LABEL" != / ]; do LABEL=${LABEL%/}; done

F_FILE=() F_LINE=() F_RULE=() F_MSG=()
add() { F_FILE+=("$1"); F_LINE+=("$2"); F_RULE+=("$3"); F_MSG+=("$4"); }

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_HEAD='^#{1,6}[[:space:]]+(.*)$'
RE_SUB='^#{2,6}[[:space:]]+(.*)$'
RE_DATE='([0-9]{4}-[0-9]{2}-[0-9]{2})(.*)$'
RE_SPAN='^(.*)`[^`]*`(.*)$'
RE_LINK='\]\(([^)[:space:]]+)[^)]*\)(.*)$'
RE_REVIEW='^#{1,6}[[:space:]]+(review on|revisar el|revisi(ó|o)n)'
RE_STATE='(state|estado)[*]*[[:space:]]*:[*]*[[:space:]]*([^·|]*)'
RE_DONE='^(done|hecho|hecha|terminado|terminada|completed|complete|cerrado|cerrada)([^a-z]|$)'
RE_VWORD='(verdict|veredicto)'

trim() { TRIM=$1; TRIM=${TRIM#"${TRIM%%[![:space:]]*}"}; TRIM=${TRIM%"${TRIM##*[![:space:]]}"}; }
load() { # prose lines of a file (fenced code skipped) → L_TEXT/L_NO
  L_TEXT=() L_NO=()
  local n=0 fence=0 line
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1)); line=${line%$'\r'}
    if [[ $line =~ $RE_FENCE ]]; then fence=$((1 - fence)); continue; fi
    [ $fence -eq 1 ] && continue
    L_TEXT+=("$line"); L_NO+=("$n")
  done <"$1"
}
sorted() { # $1 = dir relative to ROOT, $2 = find expression → sorted relative paths
  [ -d "$ROOT/$1" ] || return 0
  (cd "$ROOT" && find "$1" "${@:2}" 2>/dev/null | sort)
}

# ── 1. Decision records due for review ───────────────────────────────────────
while IFS= read -r f; do
  [ -n "$f" ] || continue
  load "$ROOT/$f"
  skip=0 inrev=0 d= dl=0
  shopt -s nocasematch
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    x=${L_TEXT[i]}
    [[ $x =~ $RE_STATE ]] && [[ ${BASH_REMATCH[2]} =~ (superseded|revoked|reemplazad|revocad) ]] && skip=1
    if [[ $x =~ $RE_REVIEW ]]; then inrev=1; continue; fi
    if [ $inrev -eq 1 ]; then
      [[ $x =~ $RE_HEAD ]] && inrev=0 && continue
      if [ -z "$d" ] && [[ $x =~ $RE_DATE ]]; then d=${BASH_REMATCH[1]}; dl=${L_NO[i]}; fi
    fi
  done
  shopt -u nocasematch
  if [ $skip -eq 0 ] && [ -n "$d" ] && [[ $d < $TODAY ]]; then
    add "$f" "$dl" review-overdue "decision review date $d has passed (today $TODAY)"
  fi
done < <(sorted plans/decisions -maxdepth 1 -type f -name '*.md')

# ── 2. Drift between skill templates and plans/agile/ copies ─────────────────
if [ -d "$TPL" ]; then
  for t in methodology definition-of-ready definition-of-done ceremonies team capabilities kpi-directives language autonomy; do
    [ -f "$TPL/$t.md" ] && [ -f "$ROOT/plans/agile/$t.md" ] || continue
    load "$ROOT/plans/agile/$t.md"
    have=$'\n'
    for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ $RE_SUB ]] && { trim "${BASH_REMATCH[1]}"; have+="$TRIM"$'\n'; }; done
    load "$TPL/$t.md"
    for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
      [[ $x =~ $RE_SUB ]] || continue
      trim "${BASH_REMATCH[1]}"
      case "$TRIM" in *'<'*) continue ;; esac
      case "$have" in *$'\n'"$TRIM"$'\n'*) ;; *) add "plans/agile/$t.md" 0 template-drift "section '$TRIM' from the skill template is missing" ;; esac
    done
  done
fi

# ── 3. Broken relative links ─────────────────────────────────────────────────
while IFS= read -r f; do
  [ -n "$f" ] || continue
  load "$ROOT/$f"
  base=${f%/*}
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    rest=${L_TEXT[i]}
    while [[ $rest =~ $RE_SPAN ]]; do rest="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"; done
    while [[ $rest =~ $RE_LINK ]]; do
      t=${BASH_REMATCH[1]}; rest=${BASH_REMATCH[2]}
      case "$t" in *://*|mailto:*|'#'*|/*|*'<'*) continue ;; esac
      p=${t%%#*}
      [ -n "$p" ] || continue
      [ -e "$ROOT/$base/$p" ] || add "$f" "${L_NO[i]}" broken-link "broken link: $t"
    done
  done
done < <(sorted plans -type f -name '*.md'; sorted specs -type f -name '*.md')

# ── 4. Sprints past their end date without a report ──────────────────────────
while IFS= read -r s; do
  [ -n "$s" ] || continue
  [ -f "$ROOT/$s/planning.md" ] || continue
  [ -f "$ROOT/$s/report.md" ] && continue
  load "$ROOT/$s/planning.md"
  end=
  shopt -s nocasematch
  for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
    [[ $x =~ (dates|fechas) ]] || continue
    r=$x
    while [[ $r =~ $RE_DATE ]]; do end=${BASH_REMATCH[1]}; r=${BASH_REMATCH[2]}; done
    break
  done
  shopt -u nocasematch
  if [ -n "$end" ] && [[ $end < $TODAY ]]; then
    add "$s/" 0 sprint-report "sprint ended $end without report.md"
  fi
done < <(sorted plans/sprints -mindepth 1 -maxdepth 1 -type d)

# ── 5. Initiatives marked Done without a passing verification ────────────────
while IFS= read -r o; do
  [ -n "$o" ] || continue
  load "$ROOT/$o"
  done_=0
  shopt -s nocasematch
  for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
    if [[ $x =~ $RE_STATE ]]; then trim "${BASH_REMATCH[2]}"; [[ $TRIM =~ $RE_DONE ]] && done_=1; break; fi
  done
  shopt -u nocasematch
  [ $done_ -eq 1 ] || continue
  slug=${o%/overview.md}; slug=${slug##*/}
  v="specs/$slug/verification.md"
  if [ ! -f "$ROOT/$v" ]; then add "$o" 0 done-unverified "initiative is Done but $v is missing"; continue; fi
  load "$ROOT/$v"
  verdict=none
  shopt -s nocasematch
  for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
    [[ $x =~ $RE_VWORD ]] || continue
    ok=0 bad=0
    case "$x" in *✅*|*⚠*) ok=1 ;; esac
    case "$x" in *❌*) bad=1 ;; esac
    if [ $ok -eq 1 ] && [ $bad -eq 0 ]; then verdict=pass; break; fi
    if [ $ok -eq 0 ] && [ $bad -eq 1 ]; then verdict=fail; break; fi
  done
  shopt -u nocasematch
  case $verdict in
    fail) add "$o" 0 done-unverified "initiative is Done but $v verdict is ❌" ;;
    none) add "$o" 0 done-unverified "initiative is Done but $v has no filled verdict" ;;
  esac
done < <(sorted plans/initiatives -mindepth 2 -maxdepth 2 -type f -name overview.md)

# ── Report ───────────────────────────────────────────────────────────────────
N=${#F_FILE[@]}
EXIT=0; [ $N -gt 0 ] && EXIT=1
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '%s' "$s"; }
if [ $JSON -eq 1 ]; then
  out="{\"root\":\"$(jesc "$LABEL")\",\"today\":\"$TODAY\",\"findings\":["
  for ((i = 0; i < N; i++)); do
    [ $i -gt 0 ] && out+=,
    out+="{\"n\":$((i + 1)),\"file\":\"$(jesc "${F_FILE[i]}")\",\"line\":${F_LINE[i]},\"rule\":\"${F_RULE[i]}\",\"message\":\"$(jesc "${F_MSG[i]}")\"}"
  done
  printf '%s\n' "$out],\"count\":$N,\"exit\":$EXIT}"
else
  echo "audit-agile — $LABEL (today $TODAY)"
  [ $N -eq 0 ] && echo "No findings."
  for ((i = 0; i < N; i++)); do
    loc=${F_FILE[i]}; [ "${F_LINE[i]}" -gt 0 ] && loc+=":${F_LINE[i]}"
    printf '%d. %s [%s] %s\n' $((i + 1)) "$loc" "${F_RULE[i]}" "${F_MSG[i]}"
  done
  if [ $N -eq 0 ]; then echo "Result: 0 finding(s) — CLEAN"; else echo "Result: $N finding(s) — ATTENTION"; fi
fi
exit $EXIT
