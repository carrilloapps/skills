#!/usr/bin/env bash
# check-structure — Phase 0 gate: is the project's agentic-agile structure complete?
#
# Nothing (spec, plan, draft, sprint artifact, ticket, decision record) may be created while
# this gate fails. Checks: plans/agile/ team operating system files exist and are filled (no
# unfilled <placeholders> in prose, no TBD, no checkboxes, per-file required content);
# plans/agile/constitution.md (Version line, a MUST article, Amendments table);
# plans/{sprints,initiatives,decisions,drafts}/, specs/, plans/agile/metrics/events.jsonl and
# the selective .memory/.gitignore block exist. Files that still mention Proposed values
# without a "Confirmed by:" line produce warnings (errors with --strict). Fenced code, code
# spans, HTML tags and autolinks are ignored. Read-only. PowerShell twin: check-structure.ps1.
# --scorecard adds a maturity level per area (L0 missing · L1 started · L2 filled ·
# L3 confirmed · L4 in use), a readiness score, and the capability slots marked "none".
#
# Usage: check-structure.sh [--root DIR] [--strict] [--json] [--scorecard]
# Exit:  0 pass · 1 errors · 2 warnings with --strict · 3 configuration error
set -u
LC_ALL=C
export LC_ALL

ROOT=. STRICT=0 JSON=0 SCORE=0
die() { echo "check-structure: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --strict) STRICT=1; shift ;;
    --json) JSON=1; shift ;;
    --scorecard) SCORE=1; shift ;;
    -h|--help) echo "Usage: check-structure.sh [--root DIR] [--strict] [--json] [--scorecard]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"
LABEL=${ROOT//\\//}
while [ "${LABEL%/}" != "$LABEL" ] && [ "$LABEL" != / ]; do LABEL=${LABEL%/}; done

F_SEV=() F_FILE=() F_LINE=() F_RULE=() F_MSG=() GAPS=()
add() { F_SEV+=("$1"); F_FILE+=("$2"); F_LINE+=("$3"); F_RULE+=("$4"); F_MSG+=("$5"); }

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_HEAD='^#{1,6}[[:space:]]+(.*)$'
RE_CHECK='^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+\[( |x|X)\]'
RE_TBD='(^|[^A-Za-z0-9_])TBD([^A-Za-z0-9_]|$)'
RE_SPAN='^(.*)`[^`]*`(.*)$'
RE_PH='<([A-Za-z][-A-Za-z0-9 _.,:/|]*)>(.*)$'
RE_NUM='^[[:space:]]*[0-9]+[.)][[:space:]]+[^[:space:]]'
RE_PROPOSED='(^|[^a-z])(proposed|propuest[oa]s?)([^a-z]|$)'
RE_CONFIRMED='(confirmed by|confirmado por)[[:space:]]*:'
HTML_TAGS='a b i u p em br hr li ol ul td th tr sub sup kbd pre code div span small strong table thead tbody details summary'

# Sets PH to the unfilled <placeholders> of a prose line (code spans, HTML tags and autolinks skipped).
placeholders() {
  local rest=$1 c lc
  PH=
  while [[ $rest =~ $RE_SPAN ]]; do rest="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"; done
  while [[ $rest =~ $RE_PH ]]; do
    c=${BASH_REMATCH[1]}; rest=${BASH_REMATCH[2]}
    lc=$(printf '%s' "$c" | tr 'A-Z' 'a-z')
    case "$lc" in *://*) continue ;; esac
    case " $HTML_TAGS " in *" $lc "*) continue ;; esac
    PH+="${PH:+, }<$c>"
  done
}
trim() { TRIM=$1; TRIM=${TRIM#"${TRIM%%[![:space:]]*}"}; TRIM=${TRIM%"${TRIM##*[![:space:]]}"}; }
is_sep() { [[ $1 =~ ^[[:space:]]*\| ]] && [[ ! $1 =~ [^-|:[:space:]] ]] && [[ $1 == *-* ]]; }

# Loads a file: prose lines (L_TEXT/L_NO, fences skipped), table data rows (R_TEXT/R_NO/R_HEAD).
load() {
  L_TEXT=() L_NO=() R_TEXT=() R_NO=() R_HEAD=()
  local n=0 fence=0 data=0 head= line
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1)); line=${line%$'\r'}
    if [[ $line =~ $RE_FENCE ]]; then fence=$((1 - fence)); continue; fi
    [ $fence -eq 1 ] && continue
    L_TEXT+=("$line"); L_NO+=("$n")
    if [[ $line =~ $RE_HEAD ]]; then head=${BASH_REMATCH[1]}; data=0; continue; fi
    if is_sep "$line"; then data=1; continue; fi
    if [[ $line =~ ^[[:space:]]*\| ]]; then
      [ $data -eq 1 ] && { R_TEXT+=("$line"); R_NO+=("$n"); R_HEAD+=("$head"); }
    else data=0; fi
  done <"$1"
}
cell() { # $1 row, $2 index (1-based, after the leading pipe) → TRIM
  local -a c
  IFS='|' read -ra c <<<"$1"
  trim "${c[$2]-}"
}

# ── Directories and shared files ─────────────────────────────────────────────
for d in plans/agile plans/sprints plans/initiatives plans/decisions plans/drafts specs; do
  [ -d "$ROOT/$d" ] || add error "$d/" 0 missing-dir "missing directory (run scripts/init)"
done
f=plans/agile/metrics/events.jsonl
[ -f "$ROOT/$f" ] || add error "$f" 0 missing-file "missing file (run scripts/init)"
f=.memory/.gitignore
if [ ! -f "$ROOT/$f" ]; then add error "$f" 0 missing-file "missing file (run scripts/init)"
else
  for l in 'local/' '*.local.*' '*.recovered.json'; do
    tr -d '\r' <"$ROOT/$f" | grep -Fxq -- "$l" || add error "$f" 0 gitignore-block "missing line: $l"
  done
fi

# ── Team operating system (plans/agile/) ─────────────────────────────────────
for t in methodology definition-of-ready definition-of-done ceremonies team capabilities kpi-directives language autonomy constitution; do
  f=plans/agile/$t.md
  if [ ! -f "$ROOT/$f" ]; then add error "$f" 0 missing-file "missing file (run scripts/init, then complete it with the team)"; continue; fi
  load "$ROOT/$f"
  proposed=0 confirmed=0 nums=0
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    x=${L_TEXT[i]}
    [[ $x =~ $RE_TBD ]] && add error "$f" "${L_NO[i]}" tbd "TBD left in the structure"
    [[ $x =~ $RE_CHECK ]] && add error "$f" "${L_NO[i]}" checkbox "checkbox list item; use numbered or lettered items with a state"
    placeholders "$x"
    [ -n "$PH" ] && add error "$f" "${L_NO[i]}" placeholder "unfilled template placeholder(s): $PH"
    [[ $x =~ $RE_NUM ]] && nums=$((nums + 1))
    p=$x; while [[ $p =~ $RE_SPAN ]]; do p="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"; done
    shopt -s nocasematch
    [[ $p =~ $RE_PROPOSED ]] && proposed=1
    [[ $p =~ $RE_CONFIRMED ]] && confirmed=1
    shopt -u nocasematch
  done
  shopt -s nocasematch
  case "$t" in
    methodology)
      ok=0; for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ (sprint length|duraci(ó|o)n del sprint)[[:space:]]*:[[:space:]]*[^[:space:]] ]] && ok=1; done
      [ $ok -eq 1 ] || add error "$f" 0 content "no sprint length (e.g. 'Sprint length: 2 weeks')"
      ok=0; for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ (scale|escala)[[:space:]]*:[[:space:]]*[^[:space:]] ]] && ok=1; done
      [ $ok -eq 1 ] || add error "$f" 0 content "no estimation scale (e.g. 'Scale: Fibonacci 1, 2, 3, 5, 8, 13')" ;;
    definition-of-ready|definition-of-done)
      [ $nums -ge 3 ] || add error "$f" 0 content "fewer than 3 numbered items" ;;
    ceremonies|kpi-directives)
      [ ${#R_TEXT[@]} -gt 0 ] || add error "$f" 0 content "no table rows" ;;
    team)
      ok=0
      for ((i = 0; i < ${#R_TEXT[@]}; i++)); do
        cell "${R_TEXT[i]}" 1; r=$TRIM; cell "${R_TEXT[i]}" 4
        [ -n "$r" ] && [ -n "$TRIM" ] && ok=1
      done
      [ $ok -eq 1 ] || add error "$f" 0 content "no role row with a usual capacity" ;;
    capabilities)
      seen=0
      for ((i = 0; i < ${#R_TEXT[@]}; i++)); do
        [[ ${R_HEAD[i]} =~ (slots|ranuras) ]] || continue
        seen=1; cell "${R_TEXT[i]}" 1; s=$TRIM; cell "${R_TEXT[i]}" 2
        [ -n "$TRIM" ] || add error "$f" "${R_NO[i]}" content "slot '$s' has no tool, 'none' or 'not applicable'"
        [[ $TRIM == none ]] && GAPS+=("$s")
      done
      [ $seen -eq 1 ] || add error "$f" 0 content "no Slots table" ;;
    language)
      ok=0; for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ gherkin[^:]*:[[:space:]]*[^[:space:]] ]] && ok=1; done
      [ $ok -eq 1 ] || add error "$f" 0 content "no Gherkin keyword language" ;;
    autonomy)
      levels=0
      for ((i = 0; i < ${#R_TEXT[@]}; i++)); do
        if [[ ${R_HEAD[i]} =~ (levels|niveles) ]]; then
          levels=1; cell "${R_TEXT[i]}" 1; s=$TRIM; cell "${R_TEXT[i]}" 2
          [[ $TRIM =~ ^N[0-4]$ ]] || add error "$f" "${R_NO[i]}" content "task '$s' has no autonomy level N0-N4"
        elif [[ ${R_HEAD[i]} =~ (adoption|adopci) ]]; then
          cell "${R_TEXT[i]}" 2; s=$TRIM; cell "${R_TEXT[i]}" 3
          [ -n "$TRIM" ] || add error "$f" "${R_NO[i]}" content "precondition '$s' has no status"
        fi
      done
      [ $levels -eq 1 ] || add error "$f" 0 content "no 'Levels per task' table" ;;
    constitution)
      ok=0; for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ (^|[^a-z])version[[:space:]]*:[[:space:]]*[0-9]+[.][0-9]+[.][0-9]+ ]] && ok=1; done
      [ $ok -eq 1 ] || add error "$f" 0 content "no 'Version: X.Y.Z' line"
      ok=0; for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ $RE_HEAD ]] && [[ ${BASH_REMATCH[1]} =~ (article|art(í|i)culo)[[:space:]]+[0-9]+.*[(]MUST[)] ]] && ok=1; done
      [ $ok -eq 1 ] || add error "$f" 0 content "no MUST article ('### Article N — <title> (MUST)')"
      ok=0; for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do [[ $x =~ ^[[:space:]]*[|][[:space:]]*version[[:space:]]*[|][[:space:]]*date[[:space:]]*[|].*decided[[:space:]]+by ]] && ok=1; done
      [ $ok -eq 1 ] || add error "$f" 0 content "no Amendments table (| Version | Date | Change | Rationale | Decided by |)" ;;
  esac
  shopt -u nocasematch
  [ $proposed -eq 1 ] && [ $confirmed -eq 0 ] && add warning "$f" 0 unconfirmed "mentions Proposed values but has no 'Confirmed by:' line"
done

# ── Report ───────────────────────────────────────────────────────────────────
E=0 W=0
for s in ${F_SEV[@]+"${F_SEV[@]}"}; do if [ "$s" = error ]; then E=$((E + 1)); else W=$((W + 1)); fi; done
EXIT=0
if [ $E -gt 0 ]; then EXIT=1; elif [ $STRICT -eq 1 ] && [ $W -gt 0 ]; then EXIT=2; fi
GATE=closed; [ $EXIT -eq 0 ] && GATE=open
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '%s' "$s"; }

# ── Scorecard ────────────────────────────────────────────────────────────────
AREAS=(process capabilities autonomy metrics transcripts)
area_files() {
  case "$1" in
    process) echo "methodology definition-of-ready definition-of-done ceremonies constitution" ;;
    capabilities) echo "capabilities" ;;
    autonomy) echo "autonomy team" ;;
    metrics) echo "kpi-directives" ;;
    transcripts) echo "language" ;;
  esac
}
any_file() { local g; for g in "$@"; do [ -f "$g" ] && return 0; done; return 1; }
in_use() { # L4 evidence that the area is used, not only written down
  case "$1" in
    process) any_file "$ROOT"/plans/sprints/*/retro.md ;;
    capabilities) [ ${#GAPS[@]} -eq 0 ] ;;
    autonomy) [ -f "$ROOT/plans/agile/metrics/events.jsonl" ] && grep -q '[^[:space:]]' "$ROOT/plans/agile/metrics/events.jsonl" ;;
    metrics) any_file "$ROOT"/plans/sprints/*/report.md ;;
    transcripts) any_file "$ROOT"/.memory/local/agentic-agile/transcripts/*.jsonl ;;
  esac
}
LEVELS=() SCORE_SUM=0
if [ $SCORE -eq 1 ]; then
  for a in "${AREAS[@]}"; do
    present=0 errs=0 warns=0
    for t in $(area_files "$a"); do
      [ -f "$ROOT/plans/agile/$t.md" ] && present=$((present + 1))
      for ((i = 0; i < ${#F_SEV[@]}; i++)); do
        [ "${F_FILE[i]}" = "plans/agile/$t.md" ] || continue
        if [ "${F_SEV[i]}" = error ]; then errs=$((errs + 1)); else warns=$((warns + 1)); fi
      done
    done
    if [ $present -eq 0 ]; then lv=0; elif [ $errs -gt 0 ]; then lv=1; elif [ $warns -gt 0 ]; then lv=2; else lv=3; fi
    [ $lv -eq 3 ] && in_use "$a" && lv=4
    LEVELS+=("$lv"); SCORE_SUM=$((SCORE_SUM + lv))
  done
fi

if [ $JSON -eq 1 ]; then
  out="{\"root\":\"$(jesc "$LABEL")\",\"findings\":["
  for ((i = 0; i < ${#F_SEV[@]}; i++)); do
    [ $i -gt 0 ] && out+=,
    out+="{\"n\":$((i + 1)),\"severity\":\"${F_SEV[i]}\",\"file\":\"$(jesc "${F_FILE[i]}")\",\"line\":${F_LINE[i]},\"rule\":\"${F_RULE[i]}\",\"message\":\"$(jesc "${F_MSG[i]}")\"}"
  done
  if [ $STRICT -eq 1 ]; then st=true; else st=false; fi
  out+="],\"errors\":$E,\"warnings\":$W,\"strict\":$st,\"gate\":\"$GATE\""
  if [ $SCORE -eq 1 ]; then
    out+=",\"scorecard\":{"
    for ((i = 0; i < ${#AREAS[@]}; i++)); do out+="\"${AREAS[i]}\":${LEVELS[i]},"; done
    out+="\"score\":$SCORE_SUM,\"max\":20,\"percent\":$((SCORE_SUM * 100 / 20))},\"gaps\":["
    for ((i = 0; i < ${#GAPS[@]}; i++)); do [ $i -gt 0 ] && out+=,; out+="\"$(jesc "${GAPS[i]}")\""; done
    out+="]"
  fi
  printf '%s\n' "$out,\"exit\":$EXIT}"
else
  echo "check-structure — $LABEL"
  if [ ${#F_SEV[@]} -eq 0 ]; then echo "No findings."; fi
  for ((i = 0; i < ${#F_SEV[@]}; i++)); do
    loc=${F_FILE[i]}; [ "${F_LINE[i]}" -gt 0 ] && loc+=":${F_LINE[i]}"
    printf '%d. %s %s [%s] %s\n' $((i + 1)) "${F_SEV[i]}" "$loc" "${F_RULE[i]}" "${F_MSG[i]}"
  done
  case $EXIT in 0) verdict=PASS ;; 1) verdict=FAIL ;; *) verdict=WARN ;; esac
  echo "Result: $E error(s), $W warning(s) — $verdict"
  if [ $GATE = open ]; then echo "Phase 0 gate: open."
  else echo "Phase 0 gate: closed. Do not create specs, plans, drafts, sprint artifacts, tickets or decision records; complete the items above with the team first."; fi
  if [ $SCORE -eq 1 ]; then
    echo "Scorecard (L0 missing · L1 started · L2 filled · L3 confirmed · L4 in use):"
    for ((i = 0; i < ${#AREAS[@]}; i++)); do printf '%d. %s — L%s\n' $((i + 1)) "${AREAS[i]}" "${LEVELS[i]}"; done
    echo "Readiness: $((SCORE_SUM * 100 / 20))% ($SCORE_SUM/20)"
    g=; for ((i = 0; i < ${#GAPS[@]}; i++)); do g+="${g:+, }${GAPS[i]}"; done
    echo "Capability gaps (slot = none): ${g:-none}"
  fi
fi
exit $EXIT
