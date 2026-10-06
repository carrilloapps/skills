#!/usr/bin/env bash
# trace — requirement traceability matrix for SDD initiatives (specs/<initiative>/).
#
# Per initiative: FR-### / SC-### from spec.md → Gherkin scenarios (by @FR-### / @SC-### tags,
# inherited from Feature/Rule tags) → tasks.md rows (Req column) → work-item drafts in
# plans/initiatives/<initiative>/tickets/ (FR mentions) → test files that mention the ID →
# verification.md rows (Req column + result mark). Errors: no requirements table, scenario
# without an @FR tag, tag or task pointing to an unknown FR, FR without scenario, FR without
# task (when tasks.md exists), FR without verification row (when verification.md exists).
# Warnings: SC not mapped to a scenario, FR without any test reference.
# Test files: tests/, test/, spec/, __tests__/ (all files) and src/ (names containing "test"
# or ".spec."), plus every --tests-dir; node_modules, .git, .memory/local, fixtures, testdata, __fixtures__, .work, templates, expected, golden(s) and (__)snapshots are skipped
# (other projects' test data must not count as evidence for this one).
# Phase 0 first (check-structure). Read-only. PowerShell twin: trace.ps1 (same output).
#
# Usage: trace.sh [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--tests-dir DIR]...
#                 [--strict] [--json]          (--skip-structure exists for the parity tests only)
# Exit:  0 pass · 1 errors · 2 warnings with --strict · 3 configuration error
set -u
LC_ALL=C
export LC_ALL

ROOT=. SPEC= ALL=0 STRICT=0 JSON=0 SKIP=0 TDIRS=()
die() { echo "trace: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --spec) [ $# -ge 2 ] || die "--spec needs a value"; SPEC=$2; shift 2 ;;
    --all) ALL=1; shift ;;
    --tests-dir) [ $# -ge 2 ] || die "--tests-dir needs a value"; TDIRS+=("$2"); shift 2 ;;
    --strict) STRICT=1; shift ;;
    --json) JSON=1; shift ;;
    --skip-structure) SKIP=1; shift ;;
    -h|--help)
      echo "Usage: trace [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--tests-dir DIR]... [--strict] [--json]"
      echo "Test files: tests/, test/, spec/, __tests__/, src/ (names with 'test' or '.spec.', case-insensitive) and every --tests-dir."
      echo "Skipped: node_modules, .git, .memory/local, fixtures, testdata, __fixtures__, .work, templates, expected, golden, goldens, snapshots, __snapshots__."
      exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$SPEC" ] || die "only one initiative folder is allowed"; SPEC=$1; shift ;;
  esac
done
[ $ALL -eq 1 ] && [ -n "$SPEC" ] && die "--all takes no initiative folder"
[ -d "$ROOT" ] || die "project root not found: $ROOT"
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done

F_SEV=() F_FILE=() F_LINE=() F_RULE=() F_MSG=()
add() { F_SEV+=("$1"); F_FILE+=("$2"); F_LINE+=("$3"); F_RULE+=("$4"); F_MSG+=("$5"); }
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; s=$(printf '%s' "$s" | tr -d '\000-\010\013-\037'); printf '%s' "$s"; }

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_GFENCE='^[[:space:]]*(```|~~~)[[:space:]]*(gherkin|feature|cucumber)([[:space:]]|$)'
RE_SCEN='^[[:space:]]*(scenario|scenario outline|scenario template|escenario|esquema del escenario|plantilla del escenario|example|ejemplo)[[:space:]]*:[[:space:]]*(.*)$'
RE_CONT='^[[:space:]]*(feature|rule|característica|regla)[[:space:]]*:'
RE_TAGL='^[[:space:]]*@'
RE_FRROW='^[[:space:]]*[|][[:space:]]*(FR-[0-9]+)[[:space:]]*[|]'
RE_SCROW='^[[:space:]]*[|][[:space:]]*(SC-[0-9]+)[[:space:]]*[|]'
RE_TROW='^[[:space:]]*[|][[:space:]]*(T[0-9]+)[[:space:]]*[|]'
RE_SEP='^[[:space:]]*[|]?[[:space:]]*:?-{3,}'
RE_MARK='(✅|⚠️|⚠|❌)'

# load FILE → L_TEXT/L_NO (fenced code skipped, Gherkin fences kept)
L_TEXT=() L_NO=()
load() {
  L_TEXT=() L_NO=()
  local n=0 fence=0 g=0 line
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1)); line=${line%$'\r'}
    if [[ $line =~ $RE_FENCE ]]; then
      if [ $fence -eq 0 ]; then
        fence=1; g=0; shopt -s nocasematch; [[ $line =~ $RE_GFENCE ]] && g=1; shopt -u nocasematch
      else fence=0; g=0; fi
      continue
    fi
    [ $fence -eq 1 ] && [ $g -eq 0 ] && continue
    L_TEXT+=("$line"); L_NO+=("$n")
  done <"$1"
}
cells() { # $1 = table row → CELLS (trimmed)
  local r=$1 c
  r=${r#"${r%%[![:space:]]*}"}; r=${r#|}; r=${r%"${r##*[![:space:]]}"}; r=${r%|}
  CELLS=()
  IFS='|' read -ra parts <<<"$r|"
  for c in ${parts[@]+"${parts[@]}"}; do c=${c#"${c%%[![:space:]]*}"}; c=${c%"${c##*[![:space:]]}"}; CELLS+=("$c"); done
}
ids_in() { # $1 = text, $2 = prefix (FR|SC) → IDS (unique, in order)
  local rest=$1 re="($2-[0-9]+)(.*)$" id
  IDS=()
  while [[ $rest =~ $re ]]; do
    id=${BASH_REMATCH[1]}; rest=${BASH_REMATCH[2]}
    case " ${IDS[*]-} " in *" $id "*) ;; *) IDS+=("$id") ;; esac
  done
}
# String maps "|key=val|…" (bash 3.2 has no associative arrays): mget NAME KEY → MV, mset NAME KEY VAL
mget() { local s=${!1}; case "$s" in *"|$2="*) MV=${s#*"|$2="}; MV=${MV%%|*} ;; *) MV= ;; esac; }
mset() {
  local s=${!1} rest
  case "$s" in *"|$2="*) rest=${s#*"|$2="}; rest=${rest#*|}; s="${s%%"|$2="*}|$rest" ;; esac
  printf -v "$1" '%s' "$s$2=$3|"
}
minc() { mget "$1" "$2"; mset "$1" "$2" $(( ${MV:-0} + 1 )); }

# ── Phase 0 ──────────────────────────────────────────────────────────────────
GATE=0
if [ $SKIP -eq 0 ]; then
  CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  [ -f "$CS" ] || die "check-structure.sh not found next to trace.sh"
  bash "$CS" --root "$ROOT" --json >/dev/null 2>&1; SX=$?
  [ $SX -eq 3 ] && die "check-structure failed on root: $RL"
  if [ $SX -ne 0 ]; then
    GATE=1
    add error structure 0 structure-gate "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
  fi
fi

# ── Initiatives ──────────────────────────────────────────────────────────────
NAMES=()
if [ $GATE -eq 0 ]; then
  if [ -n "$SPEC" ]; then
    s=${SPEC//\\//}; while [ "${s%/}" != "$s" ]; do s=${s%/}; done
    { [ -d "$ROOT/$s" ] || { [ -d "$s" ] && [ -d "$ROOT/specs/${s##*/}" ]; }; } || die "initiative folder not found: $RL/$s"
    NAMES+=("${s##*/}")
  elif [ -d "$ROOT/specs" ]; then
    while IFS= read -r d; do [ -n "$d" ] && NAMES+=("$d"); done < <(cd "$ROOT/specs" && for d in */; do [ -d "$d" ] && printf '%s\n' "${d%/}"; done | sort)
  fi
fi

# Test corpus: one line per test file "path<TAB>ids…"
TEST_IDS=()
if [ $GATE -eq 0 ] && [ ${#NAMES[@]} -gt 0 ]; then
  scan_dir() { # $1 = dir relative to ROOT, $2 = 1 to keep only test-named files
    [ -d "$ROOT/$1" ] || return 0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if [ "$2" = 1 ]; then lc=$(printf '%s' "${f##*/}" | tr 'A-Z' 'a-z'); case "$lc" in *test*|*.spec.*) ;; *) continue ;; esac; fi
      local ids
      ids=$(grep -Eo 'FR-[0-9]+' "$ROOT/$f" 2>/dev/null | sort -u | tr '\n' ' ')
      [ -n "$ids" ] && TEST_IDS+=("$ids")
    done < <(cd "$ROOT" && find "$1" -type d \( -name node_modules -o -name .git -o -path '*/.memory/local' -o -name fixtures -o -name testdata -o -name __fixtures__ -o -name .work -o -name templates -o -name expected -o -name golden -o -name goldens -o -name snapshots -o -name __snapshots__ \) -prune -o -type f -print 2>/dev/null | sort)
  }
  for d in tests test spec __tests__; do scan_dir "$d" 0; done
  scan_dir src 1
  for d in ${TDIRS[@]+"${TDIRS[@]}"}; do scan_dir "${d//\\//}" 0; done
fi
test_count() { local id=$1 n=0 t; for t in ${TEST_IDS[@]+"${TEST_IDS[@]}"}; do case " $t " in *" $id "*) n=$((n + 1)) ;; esac; done; TC=$n; }

M_SPEC=() M_ROWS=() # per initiative: matrix rows "id|kind|scen|tasks|tickets|tests|verify"
for name in ${NAMES[@]+"${NAMES[@]}"}; do
  base="specs/$name" dir="$ROOT/specs/$name"
  FRS=() SCS=() UNK=() SCN='|' TK='|' TKT='|' VER='|' SCMAP='|'
  if [ ! -f "$dir/spec.md" ]; then
    add error "$base/spec.md" 0 spec-missing "spec.md not found"
    M_SPEC+=("$base"); M_ROWS+=(""); continue
  fi
  load "$dir/spec.md"
  scol=-1 ftags= rtags= pend=
  for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
    x=${L_TEXT[i]} no=${L_NO[i]}
    if [[ $x =~ $RE_FRROW ]]; then id=${BASH_REMATCH[1]}; case " ${FRS[*]-} " in *" $id "*) ;; *) FRS+=("$id") ;; esac; continue; fi
    if [[ $x =~ $RE_SCROW ]]; then
      id=${BASH_REMATCH[1]}; case " ${SCS[*]-} " in *" $id "*) ;; *) SCS+=("$id") ;; esac
      if [ $scol -ge 0 ]; then cells "$x"; v=${CELLS[scol]-}; [ -n "$v" ] && [ "$v" != - ] && mset SCMAP "$id" 1; fi
      continue
    fi
    if [[ $x =~ ^[[:space:]]*[|] ]] && [ $((i + 1)) -lt ${#L_TEXT[@]} ] && [[ ${L_TEXT[i+1]} =~ $RE_SEP ]]; then
      cells "$x"; scol=-1
      for ((k = 0; k < ${#CELLS[@]}; k++)); do shopt -s nocasematch; [[ ${CELLS[k]} =~ (scenario|escenario) ]] && scol=$k; shopt -u nocasematch; done
      continue
    fi
    if [[ $x =~ $RE_TAGL ]]; then pend+=" $x"; continue; fi
    shopt -s nocasematch
    if [[ $x =~ $RE_CONT ]]; then
      shopt -u nocasematch
      shopt -s nocasematch
      if [[ $x =~ ^[[:space:]]*(feature|caracter) ]]; then ftags=$pend; rtags=; else rtags=$pend; fi
      shopt -u nocasematch
      pend=; continue
    fi
    if [[ $x =~ $RE_SCEN ]]; then
      shopt -u nocasematch
      title=${BASH_REMATCH[2]}; title=${title%"${title##*[![:space:]]}"}
      ids_in "$ftags $rtags $pend" FR; frt=(${IDS[@]+"${IDS[@]}"})
      ids_in "$ftags $rtags $pend" SC; for id in ${IDS[@]+"${IDS[@]}"}; do mset SCMAP "$id" 1; done
      pend=
      if [ ${#frt[@]} -eq 0 ]; then add error "$base/spec.md" "$no" scenario-untagged "scenario without an @FR-### tag: $title"; continue; fi
      for id in "${frt[@]}"; do
        minc SCN "$id"
        case " ${FRS[*]-} " in *" $id "*) ;; *) UNK+=("$no|$id|$title") ;; esac
      done
      continue
    fi
    shopt -u nocasematch
    [[ $x =~ ^[[:space:]]*(#|$) ]] || pend=
  done
  for u in ${UNK[@]+"${UNK[@]}"}; do
    IFS='|' read -r no id title <<<"$u"
    case " ${FRS[*]-} " in *" $id "*) ;; *) add error "$base/spec.md" "$no" scenario-unknown-req "scenario tag @$id is not a declared requirement: $title" ;; esac
  done
  [ ${#FRS[@]} -gt 0 ] || add error "$base/spec.md" 0 no-requirements "no FR-### rows in a functional requirements table"

  HAS_T=0
  if [ -f "$dir/tasks.md" ]; then
    HAS_T=1; load "$dir/tasks.md"
    for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
      [[ ${L_TEXT[i]} =~ $RE_TROW ]] || continue
      tid=${BASH_REMATCH[1]}; cells "${L_TEXT[i]}"
      ids_in "${CELLS[2]-}" FR
      for id in ${IDS[@]+"${IDS[@]}"}; do
        case " ${FRS[*]-} " in
          *" $id "*) minc TK "$id" ;;
          *) add error "$base/tasks.md" "${L_NO[i]}" task-unknown-req "task $tid references $id, which is not a declared requirement" ;;
        esac
      done
    done
  fi
  HAS_K=0 td="$ROOT/plans/initiatives/$name/tickets"
  if [ -d "$td" ]; then
    HAS_K=1
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      for id in $(grep -Eo 'FR-[0-9]+' "$td/$t" 2>/dev/null | sort -u); do minc TKT "$id"; done
    done < <(cd "$td" && for t in *.md; do [ -f "$t" ] && printf '%s\n' "$t"; done | sort)
  fi
  HAS_V=0
  if [ -f "$dir/verification.md" ]; then
    HAS_V=1; load "$dir/verification.md"
    for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
      [[ $x =~ ^[[:space:]]*[|] ]] || continue
      ids_in "$x" FR; [ ${#IDS[@]} -gt 0 ] || continue
      mark=-; [[ $x =~ $RE_MARK ]] && mark=${BASH_REMATCH[1]}
      [ "$mark" = "⚠️" ] && mark=⚠
      for id in "${IDS[@]}"; do mget VER "$id"; [ -n "$MV" ] && [ "$MV" != - ] || mset VER "$id" "$mark"; done
    done
  fi

  rows=
  for id in ${FRS[@]+"${FRS[@]}"}; do
    mget SCN "$id"; sc=${MV:-0}; test_count "$id"
    tk=-; [ $HAS_T -eq 1 ] && { mget TK "$id"; tk=${MV:-0}; }
    kt=-; [ $HAS_K -eq 1 ] && { mget TKT "$id"; kt=${MV:-0}; }
    vr=-; [ $HAS_V -eq 1 ] && { mget VER "$id"; vr=${MV:-none}; }
    rows+="$id|FR|$sc|$tk|$kt|$TC|$vr"$'\n'
    [ "$sc" -gt 0 ] || add error "$base/spec.md" 0 fr-no-scenario "$id has no scenario tagged @$id"
    [ $HAS_T -eq 1 ] && [ "$tk" = 0 ] && add error "$base/tasks.md" 0 fr-no-task "$id has no task in tasks.md"
    [ $HAS_V -eq 1 ] && [ "$vr" = none ] && add error "$base/verification.md" 0 fr-no-verification "$id has no row in verification.md"
    [ "$TC" -gt 0 ] || add warning "$base/spec.md" 0 fr-no-test "$id is not referenced by any test file"
  done
  for id in ${SCS[@]+"${SCS[@]}"}; do
    m=no; mget SCMAP "$id"; [ -n "$MV" ] && m=yes
    rows+="$id|SC|$m|-|-|-|-"$'\n'
    [ $m = yes ] || add warning "$base/spec.md" 0 sc-no-scenario "$id is not mapped to a scenario (Scenario(s) column or @$id tag)"
  done
  M_SPEC+=("$base"); M_ROWS+=("$rows")
done

# ── Report ───────────────────────────────────────────────────────────────────
E=0 W=0
for s in ${F_SEV[@]+"${F_SEV[@]}"}; do if [ "$s" = error ]; then E=$((E + 1)); else W=$((W + 1)); fi; done
EXIT=0
if [ $E -gt 0 ]; then EXIT=1; elif [ $STRICT -eq 1 ] && [ $W -gt 0 ]; then EXIT=2; fi
num() { case "$1" in -|none) printf 'null' ;; *) printf '%s' "$1" ;; esac; }

if [ $JSON -eq 1 ]; then
  printf '{"root":"%s","specs":[' "$(jesc "$RL")"
  for ((s = 0; s < ${#M_SPEC[@]}; s++)); do
    [ $s -gt 0 ] && printf ','
    printf '{"spec":"%s","matrix":[' "$(jesc "${M_SPEC[s]}")"
    first=1
    while IFS='|' read -r id kind sc tk kt tc vr; do
      [ -n "$id" ] || continue
      [ $first -eq 1 ] || printf ','; first=0
      if [ "$kind" = SC ]; then
        if [ "$sc" = yes ]; then mp=true; else mp=false; fi
        printf '{"id":"%s","kind":"SC","mapped":%s}' "$id" "$mp"
      else
        vj=null; case "$vr" in -|none) ;; *) vj="\"$vr\"" ;; esac
        printf '{"id":"%s","kind":"FR","scenarios":%s,"tasks":%s,"tickets":%s,"tests":%s,"verify":%s}' "$id" "$sc" "$(num "$tk")" "$(num "$kt")" "$tc" "$vj"
      fi
    done <<<"${M_ROWS[s]}"
    printf ']}'
  done
  printf '],"findings":['
  for ((i = 0; i < ${#F_SEV[@]}; i++)); do
    [ $i -gt 0 ] && printf ','
    printf '{"n":%d,"severity":"%s","file":"%s","line":%s,"rule":"%s","message":"%s"}' $((i + 1)) "${F_SEV[i]}" "$(jesc "${F_FILE[i]}")" "${F_LINE[i]}" "${F_RULE[i]}" "$(jesc "${F_MSG[i]}")"
  done
  if [ $STRICT -eq 1 ]; then st=true; else st=false; fi
  printf '],"errors":%d,"warnings":%d,"strict":%s,"exit":%d}\n' "$E" "$W" "$st" "$EXIT"
else
  echo "trace — $RL"
  [ $GATE -eq 0 ] && [ ${#M_SPEC[@]} -eq 0 ] && echo "No initiatives under specs/."
  for ((s = 0; s < ${#M_SPEC[@]}; s++)); do
    echo
    echo "${M_SPEC[s]}"
    [ -n "${M_ROWS[s]}" ] || continue
    echo "| Req | Scenarios | Tasks | Tickets | Tests | Verify |"
    echo "|-----|-----------|-------|---------|-------|--------|"
    while IFS='|' read -r id kind sc tk kt tc vr; do
      [ -n "$id" ] || continue
      printf '| %s | %s | %s | %s | %s | %s |\n' "$id" "$sc" "$tk" "$kt" "$tc" "$vr"
    done <<<"${M_ROWS[s]}"
  done
  [ ${#M_SPEC[@]} -gt 0 ] && echo
  [ ${#F_SEV[@]} -eq 0 ] && echo "No findings."
  for ((i = 0; i < ${#F_SEV[@]}; i++)); do
    loc=${F_FILE[i]}; [ "${F_LINE[i]}" -gt 0 ] && loc+=":${F_LINE[i]}"
    printf '%d. %s %s [%s] %s\n' $((i + 1)) "${F_SEV[i]}" "$loc" "${F_RULE[i]}" "${F_MSG[i]}"
  done
  case $EXIT in 0) v=PASS ;; 1) v=FAIL ;; *) v=WARN ;; esac
  echo "Result: $E error(s), $W warning(s) — $v"
fi
exit $EXIT
