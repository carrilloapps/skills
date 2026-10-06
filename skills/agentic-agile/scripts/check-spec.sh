#!/usr/bin/env bash
# check-spec — validate an SDD initiative folder (specs/<initiative>/) before its gates.
#
# Phase 1 spec.md (mandatory): Problem, Behavioral contract, Out of scope, Success criteria,
# Constraints and Open questions sections; at least one Gherkin scenario; every scenario has
# Given, When and Then steps (Background Givens count; And/But/* continue the previous step);
# Background holds only Given steps; one keyword language (English or Spanish) per Gherkin
# block; an Origin:/Origen: line per scenario (warning); no TBD. Phase 2 design.md (if
# present): Architecture & Design section (error) and the 8 design elements (warnings).
# Phase 4 verification.md (if present): results table with a Result/Resultado column and a
# Verdict/Veredicto line with ✅/⚠️/❌. Traceability: a Functional requirements table with unique
# FR-### rows; every scenario tagged with a defined @FR-### (error) and @P1/@P2/@P3 (warning);
# SC-### rows map to existing scenario titles (warning); Clarifications answers carry
# "Confirmed by:" (error); a blocking open question fails once design.md exists. tasks.md (if
# present): T### rows, known Req/Depends, Fibonacci or - estimates, no dependency cycle.
# requirements-checklist.md: expected once design.md exists (warning) with >= 80% CHK### rows
# carrying a Ref (warning). Checkbox items (- [ ]) and unfilled <placeholders> in
# prose are errors everywhere. Fenced code blocks are ignored, except ```gherkin / ```feature /
# ```cucumber fences. --tickets also checks the work-item drafts in
# plans/initiatives/<initiative>/tickets/ (QA test cases section, Gherkin rules, checkboxes).
# --all walks every specs/*/ folder under --root (tickets included) and prints a summary.
# Phase 0 first: the project structure must pass check-structure (run from --root, default the
# current directory); while it fails, only the structure-gate finding is reported.
# Read-only. PowerShell twin: check-spec.ps1 (same output).
#
# Usage: check-spec.sh <specs/initiative> [--root DIR] [--strict] [--json] [--tickets]
#        check-spec.sh --all [--root DIR] [--strict] [--json]
#        (--skip-structure exists for the parity tests only)
# Exit:  0 pass · 1 errors · 2 warnings with --strict · 3 configuration error (--all: highest)
set -u
LC_ALL=C
export LC_ALL

DIR= STRICT=0 JSON=0 ROOT=. SKIP=0 TICKETS=0 ALL=0
die() { echo "check-spec: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --json) JSON=1; shift ;;
    --tickets) TICKETS=1; shift ;;
    --all) ALL=1; shift ;;
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --skip-structure) SKIP=1; shift ;;
    -h|--help) echo "Usage: check-spec.sh <specs/initiative> [--root DIR] [--strict] [--json] [--tickets] | --all [--root DIR] [--strict] [--json]"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$DIR" ] || die "only one initiative folder is allowed"; DIR=$1; shift ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done
if [ $ALL -eq 1 ]; then
  [ -z "$DIR" ] || die "--all takes no initiative folder"
  LABEL="$RL/specs (all)"
else
  [ -n "$DIR" ] || die "missing initiative folder (e.g. specs/my-initiative)"
  [ -d "$DIR" ] || die "initiative folder not found: $DIR"
  LABEL=${DIR//\\//}
  while [ "${LABEL%/}" != "$LABEL" ]; do LABEL=${LABEL%/}; done
fi

F_SEV=() F_FILE=() F_LINE=() F_RULE=() F_MSG=() FR_IDS=
add() { F_SEV+=("$1"); F_FILE+=("$2"); F_LINE+=("$3"); F_RULE+=("$4"); F_MSG+=("$5"); }

# Loads a file into L_TEXT/L_NO/L_G/L_B, skipping fenced code blocks except Gherkin fences
# (L_G=1; L_B numbers each Gherkin block, 0 for prose).
L_TEXT=() L_NO=() L_G=() L_B=()
load() {
  L_TEXT=() L_NO=() L_G=() L_B=()
  local n=0 fence=0 g=0 b=0 line
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1)); line=${line%$'\r'}
    if [[ $line =~ $RE_FENCE ]]; then
      if [ $fence -eq 0 ]; then
        fence=1; g=0
        shopt -s nocasematch; [[ $line =~ $RE_GFENCE ]] && { g=1; b=$((b + 1)); }; shopt -u nocasematch
      else fence=0; g=0; fi
      continue
    fi
    [ $fence -eq 1 ] && [ $g -eq 0 ] && continue
    L_TEXT+=("$line"); L_NO+=("$n"); L_G+=("$g")
    if [ $g -eq 1 ]; then L_B+=("$b"); else L_B+=(0); fi
  done <"$1"
}

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_GFENCE='^[[:space:]]*(```|~~~)[[:space:]]*(gherkin|feature|cucumber)([[:space:]]|$)'
RE_HEAD='^#{1,6}[[:space:]]+(.*)$'
RE_CHECK='^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+\[( |x|X)\]'
RE_TBD='(^|[^A-Za-z0-9_])TBD([^A-Za-z0-9_]|$)'
RE_SCEN='^[[:space:]]*(scenario|scenario outline|scenario template|escenario|esquema del escenario|plantilla del escenario)[[:space:]]*:'
RE_SCEN_G='^[[:space:]]*(Example|Ejemplo)[[:space:]]*:'
RE_BG='^[[:space:]]*(Background|Antecedentes)[[:space:]]*:'
RE_END='^[[:space:]]*(Feature|Rule|Examples|Scenarios|Característica|Regla|Ejemplos|Escenarios)[[:space:]]*:'
RE_GIVEN='^[[:space:]]*(Given|Dado|Dada|Dados|Dadas)[[:space:]]'
RE_WHEN='^[[:space:]]*(When|Cuando)[[:space:]]'
RE_THEN='^[[:space:]]*(Then|Entonces)[[:space:]]'
RE_EN='^[[:space:]]*((Feature|Rule|Background|Scenario Outline|Scenario Template|Scenario|Example|Examples|Scenarios)[[:space:]]*:|(Given|When|Then|And|But)[[:space:]])'
RE_ES='^[[:space:]]*((Característica|Regla|Antecedentes|Esquema del escenario|Plantilla del escenario|Escenario|Ejemplo|Ejemplos|Escenarios)[[:space:]]*:|(Dado|Dada|Dados|Dadas|Cuando|Entonces|Y|E|Pero)[[:space:]])'
RE_ORIGIN='(^|[^a-z])(origin|origen)([*][*])?[[:space:]]*:'
RE_TABLE='^[[:space:]]*[|].*(result|resultado)'
RE_VWORD='(verdict|veredicto)'
RE_MARK='(✅|⚠|❌)'
RE_SPAN='^(.*)`[^`]*`(.*)$'
RE_PH='<([A-Za-z][-A-Za-z0-9 _.,:/|]*)>(.*)$'
RE_NUMITEM='^[[:space:]]*[0-9]+[.)][[:space:]]'

has_heading() { # $1 = case-insensitive ERE
  local i h
  shopt -s nocasematch
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    [ "${L_G[i]}" = 1 ] && continue # Gherkin '# comments' are not headings
    if [[ ${L_TEXT[i]} =~ $RE_HEAD ]]; then h=${BASH_REMATCH[1]}; if [[ $h =~ $1 ]]; then shopt -u nocasematch; return 0; fi; fi
  done
  shopt -u nocasematch
  return 1
}

scan_lines() { # $1 = file label, $2 = 1 to also check TBD, $3 = 1 to also check placeholders
  local i
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    if [ "$2" = 1 ] && [[ ${L_TEXT[i]} =~ $RE_TBD ]]; then add error "$1" "${L_NO[i]}" tbd "TBD left in the spec"; fi
    if [[ ${L_TEXT[i]} =~ $RE_CHECK ]]; then add error "$1" "${L_NO[i]}" checkbox "checkbox list item; use numbered or lettered items with a state"; fi
    [ "$3" = 1 ] || continue
    [ "${L_G[i]}" = 1 ] && continue # Gherkin <params> are legitimate (Scenario Outline)
    placeholders "${L_TEXT[i]}"
    [ -n "$PH" ] && add error "$1" "${L_NO[i]}" placeholder "unfilled template placeholder(s): $PH"
  done
}

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
HTML_TAGS='a b i u p em br hr li ol ul td th tr sub sup kbd pre code div span small strong table thead tbody details summary'

# Gherkin rules over the loaded file ($1 = label, $2 = 1 to warn on scenarios without Origin).
# Sets SC_COUNT. Regions: a scenario or Background runs until the next scenario, Background,
# Feature/Rule/Examples keyword, Markdown heading or the end of its Gherkin block.
SC_COUNT=0 SC_TITLES=()
gherkin_checks() { # $3 = 1 to check @FR-### / @P1-@P3 tags against FR_IDS
  local f=$1 warn_origin=$2 tagcheck=${3-0} i x b kind=none sline=0 sb=0 hg=0 hw=0 ht=0 ho=0 miss
  local ptags= rtags= stags= t frs pri
  local -a bgb=() en=() es=() bstart=() ftags=()
  SC_COUNT=0 SC_TITLES=()
  close_region() {
    if [ "$kind" = scen ]; then
      [ "${bgb[sb]-0}" = 1 ] && hg=1
      miss=
      [ $hg -eq 1 ] || miss+="${miss:+, }Given"
      [ $hw -eq 1 ] || miss+="${miss:+, }When"
      [ $ht -eq 1 ] || miss+="${miss:+, }Then"
      [ -n "$miss" ] && add error "$f" "$sline" scenario-steps "scenario without $miss step(s)"
      if [ "$tagcheck" = 1 ]; then
        frs=0 pri=0
        for t in $stags; do
          if [[ $t =~ ^@(FR-[0-9]+)$ ]]; then
            frs=1; has_id "${BASH_REMATCH[1]}" "$FR_IDS" || add error "$f" "$sline" scenario-fr "scenario tags unknown requirement ${BASH_REMATCH[1]}"
          fi
          [[ $t =~ ^@P[1-3]$ ]] && pri=1
        done
        [ $frs -eq 1 ] || add error "$f" "$sline" scenario-fr "scenario without an @FR-### tag"
        [ $pri -eq 1 ] || add warning "$f" "$sline" scenario-priority "scenario without a priority tag (@P1, @P2 or @P3)"
      fi
      [ "$warn_origin" = 1 ] && [ $ho -eq 0 ] && add warning "$f" "$sline" scenario-origin "scenario without Origin:/Origen: line"
    fi
    kind=none
  }
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    x=${L_TEXT[i]} b=${L_B[i]}
    if [ "$b" != 0 ]; then
      [ -n "${bstart[b]-}" ] || bstart[b]=${L_NO[i]}
      [[ $x =~ $RE_EN ]] && en[b]=1
      [[ $x =~ $RE_ES ]] && es[b]=1
    fi
    if [ "$kind" != none ] && [ "$b" != "$sb" ]; then close_region; fi
    if [[ $x =~ ^[[:space:]]*@ ]]; then ptags+=" $x"; continue; fi
    shopt -s nocasematch
    if [[ $x =~ $RE_SCEN ]]; then local is_scen=1; else local is_scen=0; fi
    shopt -u nocasematch
    if [ "$is_scen" = 0 ] && [ "$b" != 0 ] && [[ $x =~ $RE_SCEN_G ]]; then is_scen=1; fi
    if [ "$is_scen" = 1 ]; then
      close_region; kind=scen sline=${L_NO[i]} sb=$b hg=0 hw=0 ht=0 ho=0
      stags="${ftags[b]-} $rtags $ptags" ptags=
      trim "${x#*:}"; SC_TITLES+=("$TRIM")
      SC_COUNT=$((SC_COUNT + 1)); continue
    fi
    if [[ $x =~ $RE_BG ]]; then close_region; kind=bg sb=$b ptags=; continue; fi
    if [[ $x =~ $RE_END ]] || { [ "$b" = 0 ] && [[ $x =~ $RE_HEAD ]]; }; then
      close_region
      if [[ $x =~ ^[[:space:]]*(Feature|Característica)[[:space:]]*: ]]; then ftags[b]=$ptags rtags=
      elif [[ $x =~ ^[[:space:]]*(Rule|Regla)[[:space:]]*: ]]; then rtags=$ptags
      elif [ "$b" = 0 ]; then rtags=; fi
      ptags=; continue
    fi
    case "$kind" in
      scen)
        [[ $x =~ $RE_GIVEN ]] && hg=1
        [[ $x =~ $RE_WHEN ]] && hw=1
        [[ $x =~ $RE_THEN ]] && ht=1
        shopt -s nocasematch; [[ $x =~ $RE_ORIGIN ]] && ho=1; shopt -u nocasematch ;;
      bg)
        [[ $x =~ $RE_GIVEN ]] && bgb[sb]=1
        if [[ $x =~ $RE_WHEN ]] || [[ $x =~ $RE_THEN ]]; then
          add error "$f" "${L_NO[i]}" background-steps "Background may only contain Given steps"
        fi ;;
    esac
  done
  close_region
  for b in "${!bstart[@]}"; do
    [ "${en[b]-0}" = 1 ] && [ "${es[b]-0}" = 1 ] && add error "$f" "${bstart[b]}" gherkin-language "Gherkin block mixes English and Spanish keywords; use one language per block"
  done
  return 0
}

json_report() { # prints the JSON object of the collected findings
  local i out st
  out="{\"initiative\":\"$(jesc "$LABEL")\",\"findings\":["
  for ((i = 0; i < ${#F_SEV[@]}; i++)); do
    [ $i -gt 0 ] && out+=,
    out+="{\"n\":$((i + 1)),\"severity\":\"${F_SEV[i]}\",\"file\":\"$(jesc "${F_FILE[i]}")\",\"line\":${F_LINE[i]},\"rule\":\"${F_RULE[i]}\",\"message\":\"$(jesc "${F_MSG[i]}")\"}"
  done
  if [ $STRICT -eq 1 ]; then st=true; else st=false; fi
  printf '%s\n' "$out],\"errors\":$E,\"warnings\":$W,\"strict\":$st,\"exit\":$EXIT}"
}
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '%s' "$s"; }


# ── Section and table helpers ────────────────────────────────────────────────
trim() { TRIM=$1; TRIM=${TRIM#"${TRIM%%[![:space:]]*}"}; TRIM=${TRIM%"${TRIM##*[![:space:]]}"}; }
is_sep() { [[ $1 =~ ^[[:space:]]*\| ]] && [[ ! $1 =~ [^-|:[:space:]] ]] && [[ $1 == *-* ]]; }
# Cells of a table row without the outer pipes → C (0-based array), CN (count).
cells() {
  local r=$1 k
  r=${r#"${r%%[![:space:]]*}"}; r=${r%"${r##*[![:space:]]}"}; r=${r#|}; r=${r%|}
  C=()
  IFS='|' read -ra C <<<"$r|"
  for k in "${!C[@]}"; do trim "${C[k]}"; C[k]=$TRIM; done
  CN=${#C[@]}
}
# Prose lines and table data rows inside the section whose heading matches $1 (ERE, case-insensitive;
# empty = whole file) of the loaded file → S_LINE/S_LNO, S_ROW/S_RNO/S_HDR; S_FOUND = 1 if found.
sec() {
  S_LINE=() S_LNO=() S_ROW=() S_RNO=() S_HDR=() S_FOUND=0
  local i x in=0 lvl=0 hl h hdr=
  [ -z "$1" ] && { in=1; S_FOUND=1; }
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    [ "${L_G[i]}" = 1 ] && continue
    x=${L_TEXT[i]}
    if [[ $x =~ ^(#{1,6})[[:space:]]+(.*)$ ]]; then
      hl=${#BASH_REMATCH[1]} h=${BASH_REMATCH[2]} hdr=
      [ -z "$1" ] && continue
      [ $in -eq 1 ] && [ $hl -le $lvl ] && in=0
      if [ $in -eq 0 ]; then shopt -s nocasematch; [[ $h =~ $1 ]] && { in=1; lvl=$hl; S_FOUND=1; }; shopt -u nocasematch; fi
      continue
    fi
    [ $in -eq 1 ] || continue
    if [[ $x =~ ^[[:space:]]*\| ]]; then
      is_sep "$x" && continue
      if [ -z "$hdr" ]; then hdr=$x; else S_ROW+=("$x"); S_RNO+=("${L_NO[i]}"); S_HDR+=("$hdr"); fi
    else
      hdr=; S_LINE+=("$x"); S_LNO+=("${L_NO[i]}")
    fi
  done
}
col() { # $1 header row, $2 ERE (case-insensitive) → COL (0-based) or -1
  local k
  cells "$1"; COL=-1
  shopt -s nocasematch
  for ((k = 0; k < CN; k++)); do [[ ${C[k]} =~ $2 ]] && { COL=$k; break; }; done
  shopt -u nocasematch
}
has_id() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

# ── Phase 0 ──────────────────────────────────────────────────────────────────
GATE=0
if [ $SKIP -eq 0 ]; then
  CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  [ -f "$CS" ] || die "check-structure.sh not found next to check-spec.sh"
  SJ=$(bash "$CS" --root "$ROOT" --json 2>/dev/null); SX=$?
  [ $SX -eq 3 ] && die "check-structure failed on root: $ROOT"
  if [ $SX -ne 0 ]; then
    GATE=1
    SE=$(printf '%s' "$SJ" | sed -n 's/.*"errors":\([0-9]*\).*/\1/p')
    add error structure 0 structure-gate "Phase 0 structure incomplete ($SE error(s)); run scripts/check-structure --root $RL and complete plans/agile/ with the team before any spec"
  fi
fi

# ── --all: one child run per initiative ──────────────────────────────────────
if [ $ALL -eq 1 ] && [ $GATE -eq 0 ]; then
  CHILD=(--root "$ROOT" --skip-structure --tickets)
  [ $STRICT -eq 1 ] && CHILD+=(--strict)
  NAMES=() XS=() ES=() WS=() JS=()
  if [ -d "$ROOT/specs" ]; then
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      j=$(bash "$0" "$ROOT/specs/$d" "${CHILD[@]}" --json 2>/dev/null); x=$?
      NAMES+=("$d"); XS+=("$x"); JS+=("$j")
      ES+=("$(printf '%s' "$j" | sed -n 's/.*"errors":\([0-9]*\).*/\1/p')")
      WS+=("$(printf '%s' "$j" | sed -n 's/.*"warnings":\([0-9]*\).*/\1/p')")
    done < <(cd "$ROOT/specs" && for d in */; do [ -d "$d" ] && printf '%s\n' "${d%/}"; done | sort)
  fi
  E=0 W=0 EXIT=0
  for ((i = 0; i < ${#NAMES[@]}; i++)); do
    E=$((E + ${ES[i]:-0})); W=$((W + ${WS[i]:-0}))
    [ "${XS[i]}" -gt $EXIT ] && EXIT=${XS[i]}
  done
  if [ $JSON -eq 1 ]; then
    out="{\"root\":\"$(jesc "$RL")\",\"initiatives\":["
    for ((i = 0; i < ${#NAMES[@]}; i++)); do [ $i -gt 0 ] && out+=,; out+=${JS[i]}; done
    if [ $STRICT -eq 1 ]; then st=true; else st=false; fi
    printf '%s\n' "$out],\"count\":${#NAMES[@]},\"errors\":$E,\"warnings\":$W,\"strict\":$st,\"exit\":$EXIT}"
  else
    echo "check-spec — $LABEL"
    [ ${#NAMES[@]} -eq 0 ] && echo "No initiatives under specs/."
    for ((i = 0; i < ${#NAMES[@]}; i++)); do
      echo
      bash "$0" "$ROOT/specs/${NAMES[i]}" "${CHILD[@]}" 2>/dev/null
    done
    echo
    echo "Summary:"
    for ((i = 0; i < ${#NAMES[@]}; i++)); do
      case ${XS[i]} in 0) v=PASS ;; 1) v=FAIL ;; 2) v=WARN ;; *) v=ERROR ;; esac
      printf '%d. specs/%s — %s (%s error(s), %s warning(s))\n' $((i + 1)) "${NAMES[i]}" "$v" "${ES[i]:-0}" "${WS[i]:-0}"
    done
    case $EXIT in 0) v=PASS ;; 1) v=FAIL ;; 2) v=WARN ;; *) v=ERROR ;; esac
    echo "Result: ${#NAMES[@]} initiative(s), $E error(s), $W warning(s) — $v"
  fi
  exit $EXIT
fi

# ── Phase 1 ──────────────────────────────────────────────────────────────────
if [ $GATE -eq 1 ] || [ $ALL -eq 1 ]; then :
elif [ ! -f "$DIR/spec.md" ]; then
  add error spec.md 0 phase1-missing "spec.md not found (Phase 1 is mandatory)"
else
  load "$DIR/spec.md"
  SECTIONS=(
    'Problem|problem|problema'
    'Behavioral contract|behaviou?ral contract|contrato de comportamiento|contrato conductual|comportamiento esperado'
    'Out of scope|out of scope|out-of-scope|fuera de alcance'
    'Success criteria|success criteria|criterios de (é|É|e)xito'
    'Constraints|constraints|restricciones'
    'Open questions|open questions|preguntas abiertas'
  )
  for s in "${SECTIONS[@]}"; do
    has_heading "${s#*|}" || add error spec.md 0 missing-section "missing section: ${s%%|*}"
  done
  sec 'functional requirements|requisitos funcionales'
  for ((i = 0; i < ${#S_ROW[@]}; i++)); do
    cells "${S_ROW[i]}"; id=${C[0]-}
    [[ $id =~ ^FR-[0-9]+$ ]] || continue
    if has_id "$id" "$FR_IDS"; then add error spec.md "${S_RNO[i]}" fr-duplicate "duplicate requirement ID $id"
    else FR_IDS+=" $id"; fi
  done
  [ -n "$FR_IDS" ] || add error spec.md 0 fr-missing "no Functional requirements table with FR-### rows"
  gherkin_checks spec.md 1 1
  [ $SC_COUNT -gt 0 ] || add error spec.md 0 no-scenarios "no Gherkin scenario (Scenario:/Escenario:)"
  sec 'success criteria|criterios de (é|É|e)xito'
  for ((i = 0; i < ${#S_ROW[@]}; i++)); do
    cells "${S_ROW[i]}"; id=${C[0]-}
    [[ $id =~ ^SC-[0-9]+$ ]] || continue
    col "${S_HDR[i]}" 'scenario|escenario'
    if [ $COL -lt 0 ]; then add warning spec.md "${S_RNO[i]}" sc-scenario "success criterion $id has no Scenario(s) column"; continue; fi
    cells "${S_ROW[i]}"; v=${C[COL]-}
    if [ -z "$v" ] || [ "$v" = - ]; then add warning spec.md "${S_RNO[i]}" sc-scenario "success criterion $id maps to no scenario"; continue; fi
    IFS=',' read -ra ents <<<"$v"
    for e in "${ents[@]}"; do
      trim "$e"; e=${TRIM//\"/}; found=0
      shopt -s nocasematch
      for t in ${SC_TITLES[@]+"${SC_TITLES[@]}"}; do [[ $t == "$e" ]] && found=1; done
      shopt -u nocasematch
      [ $found -eq 1 ] || add warning spec.md "${S_RNO[i]}" sc-scenario "success criterion $id maps to unknown scenario: $e"
    done
  done
  sec 'clarifications|aclaraciones'
  shopt -s nocasematch
  for ((i = 0; i < ${#S_LINE[@]}; i++)); do
    [[ ${S_LINE[i]} =~ $RE_NUMITEM ]] || continue
    [[ ${S_LINE[i]} =~ (confirmed by|confirmado por)[[:space:]]*: ]] || add error spec.md "${S_LNO[i]}" clarify-unconfirmed "clarification answer without Confirmed by:"
  done
  shopt -u nocasematch
  if [ -f "$DIR/design.md" ]; then
    sec 'open questions|preguntas abiertas'
    for ((i = 0; i < ${#S_ROW[@]}; i++)); do
      col "${S_HDR[i]}" 'block|bloquea'; [ $COL -ge 0 ] || continue
      bc=$COL; col "${S_HDR[i]}" 'question|pregunta'; qc=$COL
      cells "${S_ROW[i]}"; v=$(printf '%s' "${C[bc]-}" | tr 'A-Z' 'a-z')
      case "$v" in
        yes|y|si|sí|true)
          if [ $qc -ge 0 ]; then q=${C[qc]-}; else q="row ${S_RNO[i]}"; fi
          add error spec.md "${S_RNO[i]}" blocking-question "blocking open question still open: $q; cannot enter Phase 2" ;;
      esac
    done
  fi
  scan_lines spec.md 1 1
fi

# ── Phase 2 ──────────────────────────────────────────────────────────────────
if [ $GATE -eq 0 ] && [ $ALL -eq 0 ] && [ -f "$DIR/design.md" ]; then
  load "$DIR/design.md"
  has_heading 'architecture (&|and) design|arquitectura y dise(ñ|Ñ)o' || add error design.md 0 phase2-heading "missing '## Architecture & Design' section"
  ELEMENTS=(
    'Architectural style|architectural style|estilo arquitect(ó|Ó|o)nico'
    'Layers|layers|capas'
    'Bounded context|bounded[- ]context|contexto acotado|contexto delimitado'
    'Patterns|patterns|patrones'
    'State model|state model|modelo de estado'
    'Composition points|composition points|puntos de composici(ó|Ó|o)n'
    'Public surface|public surface|superficie p(ú|Ú|u)blica'
    'Anti-violations|anti-violations|anti-violaciones|antiviolaciones'
  )
  for e in "${ELEMENTS[@]}"; do
    has_heading "${e#*|}" || add warning design.md 0 design-element "design element not found: ${e%%|*}"
  done
  scan_lines design.md 0 1
fi

# ── Tasks (tasks.md) ─────────────────────────────────────────────────────────
if [ $GATE -eq 0 ] && [ $ALL -eq 0 ] && [ -f "$DIR/tasks.md" ]; then
  load "$DIR/tasks.md"
  sec '^(phase|fase)[[:space:]]+[0-9]+'
  T_IDS= T_ROW=() T_NO=()
  for ((i = 0; i < ${#S_ROW[@]}; i++)); do
    cells "${S_ROW[i]}"; id=${C[0]-}
    if [[ ! $id =~ ^T[0-9]+$ ]] || [ $CN -lt 7 ]; then
      add error tasks.md "${S_RNO[i]}" task-format "row is not a task (| T### | P | Req | Task | Depends | Est | Status |)"; continue
    fi
    if has_id "$id" "$T_IDS"; then add error tasks.md "${S_RNO[i]}" task-duplicate "duplicate task ID $id"; continue; fi
    T_IDS+=" $id"; T_ROW+=("${S_ROW[i]}"); T_NO+=("${S_RNO[i]}")
  done
  [ -n "$T_IDS" ] || add error tasks.md 0 task-format "no task rows (T###)"
  T_DEP=()
  for ((i = 0; i < ${#T_ROW[@]}; i++)); do
    cells "${T_ROW[i]}"; id=${C[0]} req=${C[2]} dep=${C[4]} est=${C[5]} deps=
    if [ "$req" != - ] && [ -n "$req" ]; then
      for r in ${req//,/ }; do
        if [[ ! $r =~ ^FR-[0-9]+$ ]]; then add error tasks.md "${T_NO[i]}" task-req "task $id has an invalid requirement reference: $r"
        elif ! has_id "$r" "$FR_IDS"; then add error tasks.md "${T_NO[i]}" task-req "task $id references unknown requirement $r"; fi
      done
    fi
    if [ "$dep" != - ] && [ -n "$dep" ]; then
      for r in ${dep//,/ }; do
        if has_id "$r" "$T_IDS"; then deps+=" $r"
        else add error tasks.md "${T_NO[i]}" task-depends "task $id depends on unknown task $r"; fi
      done
    fi
    T_DEP+=("$deps")
    case "$est" in 1|2|3|5|8|13|-) ;; *) add error tasks.md "${T_NO[i]}" task-estimate "task $id estimate '$est' is not Fibonacci (1, 2, 3, 5, 8, 13) or -" ;; esac
  done
  # ponytail: repeated passes, O(n^2) — fine for the size of a tasks.md
  done_ids= changed=1
  while [ $changed -eq 1 ]; do
    changed=0
    for ((i = 0; i < ${#T_ROW[@]}; i++)); do
      cells "${T_ROW[i]}"; id=${C[0]}
      has_id "$id" "$done_ids" && continue
      ready=1; for r in ${T_DEP[i]}; do has_id "$r" "$done_ids" || ready=0; done
      [ $ready -eq 1 ] && { done_ids+=" $id"; changed=1; }
    done
  done
  left=
  for ((i = 0; i < ${#T_ROW[@]}; i++)); do cells "${T_ROW[i]}"; has_id "${C[0]}" "$done_ids" || left+="${left:+, }${C[0]}"; done
  [ -n "$left" ] && add error tasks.md 0 task-cycle "dependency cycle among: $left"
  scan_lines tasks.md 0 1
fi

# ── Requirements-quality checklist (requirements-checklist.md) ───────────────
if [ $GATE -eq 0 ] && [ $ALL -eq 0 ]; then
  if [ -f "$DIR/requirements-checklist.md" ]; then
    load "$DIR/requirements-checklist.md"
    sec ''
    tot=0 refd=0
    for ((i = 0; i < ${#S_ROW[@]}; i++)); do
      cells "${S_ROW[i]}"; [[ ${C[0]-} =~ ^CHK[0-9]+$ ]] || continue
      tot=$((tot + 1)); col "${S_HDR[i]}" '^ref'
      if [ $COL -ge 0 ]; then cells "${S_ROW[i]}"; v=${C[COL]-}; [ -n "$v" ] && [ "$v" != - ] && refd=$((refd + 1)); fi
    done
    if [ $tot -eq 0 ]; then add warning requirements-checklist.md 0 checklist-empty "no CHK### items"
    elif [ $((refd * 100)) -lt $((tot * 80)) ]; then add warning requirements-checklist.md 0 checklist-ref "only $((refd * 100 / tot))% of checklist items reference the spec (80% required)"; fi
    scan_lines requirements-checklist.md 0 1
  elif [ -f "$DIR/design.md" ]; then
    add warning requirements-checklist.md 0 checklist-missing "requirements-checklist.md missing (required before Phase 2 under --strict)"
  fi
fi

# ── Phase 4 ──────────────────────────────────────────────────────────────────
if [ $GATE -eq 0 ] && [ $ALL -eq 0 ] && [ -f "$DIR/verification.md" ]; then
  load "$DIR/verification.md"
  table=0 verdict=0
  shopt -s nocasematch
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    [[ ${L_TEXT[i]} =~ $RE_TABLE ]] && table=1
    if [[ ${L_TEXT[i]} =~ $RE_VWORD ]] && [[ ${L_TEXT[i]} =~ $RE_MARK ]]; then verdict=1; fi
  done
  shopt -u nocasematch
  [ $table -eq 1 ] || add error verification.md 0 phase4-table "no results table with a Result/Resultado column"
  [ $verdict -eq 1 ] || add error verification.md 0 phase4-verdict "no Verdict/Veredicto line with a check, warning or cross mark"
  scan_lines verification.md 0 1
fi

# ── Work-item drafts (--tickets) ─────────────────────────────────────────────
if [ $GATE -eq 0 ] && [ $ALL -eq 0 ] && [ $TICKETS -eq 1 ]; then
  SLUG=${LABEL##*/}
  TD="$ROOT/plans/initiatives/$SLUG/tickets"
  if [ -d "$TD" ]; then
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      tl="plans/initiatives/$SLUG/tickets/$t"
      load "$TD/$t"
      has_heading 'qa test cases|casos de prueba' || add error "$tl" 0 ticket-qa "work item without a QA test cases section"
      gherkin_checks "$tl" 0
      scan_lines "$tl" 0 0
    done < <(cd "$TD" && for t in *.md; do [ -f "$t" ] && printf '%s\n' "$t"; done | sort)
  fi
fi

# ── Report ───────────────────────────────────────────────────────────────────
E=0 W=0
for s in ${F_SEV[@]+"${F_SEV[@]}"}; do if [ "$s" = error ]; then E=$((E + 1)); else W=$((W + 1)); fi; done
EXIT=0
if [ $E -gt 0 ]; then EXIT=1; elif [ $STRICT -eq 1 ] && [ $W -gt 0 ]; then EXIT=2; fi

if [ $JSON -eq 1 ]; then
  json_report
else
  echo "check-spec — $LABEL"
  if [ ${#F_SEV[@]} -eq 0 ]; then echo "No findings."; fi
  for ((i = 0; i < ${#F_SEV[@]}; i++)); do
    loc=${F_FILE[i]}; [ "${F_LINE[i]}" -gt 0 ] && loc+=":${F_LINE[i]}"
    printf '%d. %s %s [%s] %s\n' $((i + 1)) "${F_SEV[i]}" "$loc" "${F_RULE[i]}" "${F_MSG[i]}"
  done
  case $EXIT in 0) verdict=PASS ;; 1) verdict=FAIL ;; *) verdict=WARN ;; esac
  echo "Result: $E error(s), $W warning(s) — $verdict"
fi
exit $EXIT
