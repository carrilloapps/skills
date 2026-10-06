#!/usr/bin/env bash
# analyze — deterministic cross-artifact consistency checks for SDD initiatives (specs/<x>/).
#
# Severities CRITICAL / HIGH / MEDIUM / LOW; findings are sorted (severity, file, line, rule,
# message) and get stable IDs A001…. Checks: requirement (FR-###) text duplicated (MEDIUM);
# scenario title duplicated (LOW); ambiguous vocabulary from frameworks/analyze.md section 3
# (+ plans/agile/ambiguity-terms.txt; "!term" removes) in a requirement (HIGH) or success
# criterion (MEDIUM) cell without a number; unresolved [NEEDS CLARIFICATION] markers in spec,
# design or tasks (HIGH); blocking open questions (HIGH); FR text in tasks.md or tickets that
# differs from spec.md (MEDIUM); constitution violations — "Violates: Article N" lines or ❌ rows
# in design.md "Constitution check" — against plans/agile/constitution.md (MUST: CRITICAL,
# SHOULD: MEDIUM, unknown article: HIGH); tasks.md duplicate IDs, unknown dependencies and
# dependency cycles (HIGH); requirements-checklist.md items traced to a spec reference < 80%
# (HIGH). Phase 0 first (check-structure). Read-only. PowerShell twin: analyze.ps1.
#
# Usage: analyze.sh [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--strict] [--json]
#                   (--skip-structure exists for the parity tests only)
# Exit:  0 pass · 1 CRITICAL/HIGH findings · 2 MEDIUM/LOW findings with --strict · 3 config error
set -u
LC_ALL=C
export LC_ALL

ROOT=. SPEC= STRICT=0 JSON=0 SKIP=0
die() { echo "analyze: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --spec) [ $# -ge 2 ] || die "--spec needs a value"; SPEC=$2; shift 2 ;;
    --all) shift ;;
    --strict) STRICT=1; shift ;;
    --json) JSON=1; shift ;;
    --skip-structure) SKIP=1; shift ;;
    -h|--help) echo "Usage: analyze.sh [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--strict] [--json]"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$SPEC" ] || die "only one initiative folder is allowed"; SPEC=$1; shift ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done

F=() # "rank<TAB>file<TAB>line6<TAB>rule<TAB>severity<TAB>line<TAB>message"
add() { # severity file line rule message
  local r=4
  case "$1" in CRITICAL) r=1 ;; HIGH) r=2 ;; MEDIUM) r=3 ;; esac
  F+=("$r"$'\t'"$2"$'\t'"$(printf '%06d' "$3")"$'\t'"$4"$'\t'"$1"$'\t'"$3"$'\t'"$5")
}
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '%s' "$s"; }

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_GFENCE='^[[:space:]]*(```|~~~)[[:space:]]*(gherkin|feature|cucumber)([[:space:]]|$)'
RE_HEAD='^(#{1,6})[[:space:]]+(.*)$'
RE_SCEN='^[[:space:]]*(scenario|scenario outline|scenario template|escenario|esquema del escenario|plantilla del escenario|example|ejemplo)[[:space:]]*:[[:space:]]*(.*)$'
RE_SEP='^[[:space:]]*[|]?[[:space:]]*:?-{3,}'
RE_ROW='^[[:space:]]*[|]'
RE_NC='\[(needs clarification[^]]*)\]'
RE_VIOL='(violates|viola)[[:space:]]*:[[:space:]]*(article|artículo|articulo)[[:space:]]+([0-9]+)'
RE_ART='^###[[:space:]]+(article|artículo|articulo)[[:space:]]+([0-9]+)[[:space:]]*(—|:|-)?[[:space:]]*([^(]*)(.*)$'
RE_DRIFT='(FR-[0-9]+)[[:space:]]*(:|[[:space:]]—|[[:space:]]-)[[:space:]]+(.+)$'

L_TEXT=() L_NO=()
load() { # FILE → L_TEXT/L_NO (fenced code skipped, Gherkin fences kept)
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
cells() { # row → CELLS (trimmed)
  local r=$1 c
  r=${r#"${r%%[![:space:]]*}"}; r=${r#|}; r=${r%"${r##*[![:space:]]}"}; r=${r%|}
  CELLS=()
  IFS='|' read -ra parts <<<"$r"
  for c in ${parts[@]+"${parts[@]}"}; do c=${c#"${c%%[![:space:]]*}"}; c=${c%"${c##*[![:space:]]}"}; CELLS+=("$c"); done
}
is_header() { [[ ${L_TEXT[$1]} =~ $RE_ROW ]] && [ $(($1 + 1)) -lt ${#L_TEXT[@]} ] && [[ ${L_TEXT[$1+1]} =~ $RE_SEP ]]; }
norm_words() { printf ' %s ' "$(printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9\200-\377' ' ' | tr -s ' ' | sed 's/^ //; s/ $//')"; }
norm_text() { # lowercase ASCII, collapsed whitespace, trimmed, trailing period dropped
  local s
  s=$(printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -s ' \t' '  ' | sed 's/^ //; s/ $//; s/[.]$//')
  printf '%s' "$s"
}
lower() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }

# Ambiguous terms (normalized " term ")
TERMS=()
read_terms() { # $1 = file, $2 = 1 to read only between the ambiguity-terms markers (Markdown)
  local t n on=1
  [ -f "$1" ] || return 0
  [ "${2-0}" = 1 ] && on=0
  while IFS= read -r t || [ -n "$t" ]; do
    t=${t%$'\r'}; t=${t#"${t%%[![:space:]]*}"}; t=${t%"${t##*[![:space:]]}"}
    case "$t" in '<!-- ambiguity-terms:begin -->') on=1; continue ;; '<!-- ambiguity-terms:end -->') on=0; continue ;; esac
    [ $on -eq 1 ] || continue
    case "$t" in ''|'#'*|'```'*) continue ;; esac
    if [ "${t#!}" != "$t" ]; then
      n=$(norm_words "${t#!}"); local keep=() x
      for x in ${TERMS[@]+"${TERMS[@]}"}; do [ "$x" = "$n" ] || keep+=("$x"); done
      TERMS=(${keep[@]+"${keep[@]}"})
      continue
    fi
    n=$(norm_words "$t"); [ "$n" = "  " ] && continue
    local dup=0 x; for x in ${TERMS[@]+"${TERMS[@]}"}; do [ "$x" = "$n" ] && dup=1; done
    [ $dup -eq 0 ] && TERMS+=("$n")
  done <"$1"
}
ambiguous() { # cell text → AMB ("a, b" in list order) unless the text has a digit
  local w x
  AMB=
  case "$1" in *[0-9]*) return ;; esac
  w=$(norm_words "$1")
  for x in ${TERMS[@]+"${TERMS[@]}"}; do
    case "$w" in *"$x"*) x=${x# }; x=${x% }; AMB+="${AMB:+, }$x" ;; esac
  done
}

# ── Phase 0 ──────────────────────────────────────────────────────────────────
GATE=0
if [ $SKIP -eq 0 ]; then
  CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  [ -f "$CS" ] || die "check-structure.sh not found next to analyze.sh"
  bash "$CS" --root "$ROOT" --json >/dev/null 2>&1; SX=$?
  [ $SX -eq 3 ] && die "check-structure failed on root: $ROOT"
  if [ $SX -ne 0 ]; then
    GATE=1
    add CRITICAL structure 0 structure-gate "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
  fi
fi

NAMES=()
if [ $GATE -eq 0 ]; then
  if [ -n "$SPEC" ]; then
    s=${SPEC//\\//}; while [ "${s%/}" != "$s" ]; do s=${s%/}; done
    { [ -d "$ROOT/$s" ] || { [ -d "$s" ] && [ -d "$ROOT/specs/${s##*/}" ]; }; } || die "initiative folder not found: $ROOT/$s"
    NAMES+=("${s##*/}")
  elif [ -d "$ROOT/specs" ]; then
    while IFS= read -r d; do [ -n "$d" ] && NAMES+=("$d"); done < <(cd "$ROOT/specs" && for d in */; do [ -d "$d" ] && printf '%s\n' "${d%/}"; done | sort)
  fi
  read_terms "$(cd "$(dirname "$0")" && pwd)/../frameworks/analyze.md" 1
  read_terms "$ROOT/plans/agile/ambiguity-terms.txt"
fi

# Constitution: ART_N[i] number, ART_L[i] MUST|SHOULD, ART_T[i] title
ART_N=() ART_L=() ART_T=()
if [ $GATE -eq 0 ] && [ -f "$ROOT/plans/agile/constitution.md" ]; then
  load "$ROOT/plans/agile/constitution.md"
  shopt -s nocasematch
  for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
    [[ $x =~ $RE_ART ]] || continue
    num=${BASH_REMATCH[2]} t=${BASH_REMATCH[4]} rest=${BASH_REMATCH[5]}
    t=${t%"${t##*[![:space:]]}"}
    lvl=; [[ $rest =~ \((MUST|SHOULD)\) ]] && lvl=$(printf '%s' "${BASH_REMATCH[1]}" | tr 'a-z' 'A-Z')
    ART_N+=("$num"); ART_L+=("$lvl"); ART_T+=("$t")
  done
  shopt -u nocasematch
fi
article() { # number file line context
  local i
  for ((i = 0; i < ${#ART_N[@]}; i++)); do
    [ "${ART_N[i]}" = "$1" ] || continue
    if [ "${ART_L[i]}" = MUST ]; then add CRITICAL "$2" "$3" constitution-violation "$4 violates Article $1 (MUST): ${ART_T[i]}"
    else add MEDIUM "$2" "$3" constitution-violation "$4 violates Article $1 (SHOULD): ${ART_T[i]}"; fi
    return
  done
  add HIGH "$2" "$3" constitution-unknown-article "$4 references Article $1, which is not in plans/agile/constitution.md"
}

for name in ${NAMES[@]+"${NAMES[@]}"}; do
  base="specs/$name" dir="$ROOT/specs/$name"
  FR_ID=() FR_KEY=() FR_RAW=()
  if [ -f "$dir/spec.md" ]; then
    load "$dir/spec.md"
    seen_titles=() inq=0 qlvl=0 bcol=-1 qcol=1
    for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
      x=${L_TEXT[i]} no=${L_NO[i]}
      if [[ $x =~ $RE_HEAD ]]; then
        h=${BASH_REMATCH[2]} lv=${#BASH_REMATCH[1]}
        shopt -s nocasematch
        if [[ $h =~ (open questions|preguntas abiertas) ]]; then inq=1; qlvl=$lv; bcol=-1; qcol=1
        elif [ $inq -eq 1 ] && [ "$lv" -le "$qlvl" ]; then inq=0; fi
        shopt -u nocasematch
        continue
      fi
      if [[ $x =~ $RE_ROW ]] && ! [[ $x =~ $RE_SEP ]]; then
        cells "$x"
        if is_header "$i"; then
          if [ $inq -eq 1 ]; then
            for ((k = 0; k < ${#CELLS[@]}; k++)); do
              shopt -s nocasematch
              [[ ${CELLS[k]} =~ (block|bloquea) ]] && bcol=$k
              [[ ${CELLS[k]} =~ (question|pregunta) ]] && qcol=$k
              shopt -u nocasematch
            done
          fi
          continue
        fi
        c0=${CELLS[0]-} c1=${CELLS[1]-}
        if [[ $c0 =~ ^FR-[0-9]+$ ]]; then
          key=$(norm_text "$c1") j=-1
          for ((k = 0; k < ${#FR_ID[@]}; k++)); do [ "${FR_KEY[k]}" = "$key" ] && { j=$k; break; }; done
          [ $j -ge 0 ] && [ -n "$key" ] && add MEDIUM "$base/spec.md" "$no" duplicate-requirement "$c0 duplicates the text of ${FR_ID[j]}"
          FR_ID+=("$c0"); FR_KEY+=("$key"); FR_RAW+=("$c1")
          ambiguous "$c1"; [ -n "$AMB" ] && add HIGH "$base/spec.md" "$no" ambiguous-term "$c0 uses ambiguous term(s) without a measurable criterion: $AMB"
        elif [[ $c0 =~ ^SC-[0-9]+$ ]]; then
          ambiguous "$c1"; [ -n "$AMB" ] && add MEDIUM "$base/spec.md" "$no" ambiguous-term "$c0 uses ambiguous term(s) without a measurable criterion: $AMB"
        elif [ $inq -eq 1 ] && [ $bcol -ge 0 ]; then
          b=$(lower "${CELLS[bcol]-}")
          case "$b" in yes|y|si|sí|true) add HIGH "$base/spec.md" "$no" blocking-question "blocking open question: ${CELLS[qcol]-}" ;; esac
        fi
        continue
      fi
      shopt -s nocasematch
      if [[ $x =~ $RE_SCEN ]]; then
        shopt -u nocasematch
        t=${BASH_REMATCH[2]}; t=${t%"${t##*[![:space:]]}"}; key=$(norm_text "$t")
        dup=0; for s in ${seen_titles[@]+"${seen_titles[@]}"}; do [ "$s" = "$key" ] && dup=1; done
        if [ $dup -eq 1 ]; then add LOW "$base/spec.md" "$no" duplicate-scenario "scenario title repeats an earlier scenario: $t"; else seen_titles+=("$key"); fi
      fi
      shopt -u nocasematch
    done
  fi

  for f in spec.md design.md tasks.md; do
    [ -f "$dir/$f" ] || continue
    load "$dir/$f"
    inc=0 clvl=0
    for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
      x=${L_TEXT[i]} no=${L_NO[i]}
      shopt -s nocasematch
      if [[ $x =~ $RE_NC ]]; then add HIGH "$base/$f" "$no" needs-clarification "unresolved [${BASH_REMATCH[1]}] marker"; fi
      if [[ $x =~ $RE_VIOL ]]; then n=${BASH_REMATCH[3]}; shopt -u nocasematch; article "$n" "$base/$f" "$no" "$f"; fi
      shopt -u nocasematch
      [ "$f" = design.md ] || continue
      if [[ $x =~ $RE_HEAD ]]; then
        lv=${#BASH_REMATCH[1]} h=${BASH_REMATCH[2]}
        shopt -s nocasematch
        if [[ $h =~ (constitution check|verificaci(ó|o)n de (la )?constituci(ó|o)n|chequeo de (la )?constituci(ó|o)n) ]]; then inc=1; clvl=$lv
        elif [ $inc -eq 1 ] && [ "$lv" -le "$clvl" ]; then inc=0; fi
        shopt -u nocasematch
        continue
      fi
      if [ $inc -eq 1 ] && [[ $x =~ $RE_ROW ]] && ! [[ $x =~ $RE_SEP ]]; then
        # A row is failing when a status cell (any cell after the first) starts with ❌;
        # a legend such as "✅/❌/⚠️" in the header is not a status.
        IFS='|' read -r -a cells <<<"$x"
        c1=${cells[1]:-} hit=0
        for ((ci = 2; ci < ${#cells[@]}; ci++)); do
          c=${cells[ci]#"${cells[ci]%%[![:space:]]*}"}
          case "$c" in ❌*) case "$c" in */*) ;; *) hit=1 ;; esac ;; esac
        done
        [ $hit -eq 1 ] || continue
        n=
        shopt -s nocasematch
        if [[ $x =~ (article|artículo|articulo)[[:space:]]+([0-9]+) ]]; then n=${BASH_REMATCH[2]}
        elif [[ $c1 =~ ^[[:space:]]*([0-9]+)([^0-9]|$) ]]; then n=${BASH_REMATCH[1]}; fi
        shopt -u nocasematch
        if [ -n "$n" ]; then article "$n" "$base/$f" "$no" "constitution check"
        else add HIGH "$base/$f" "$no" constitution-unknown-article "constitution check row marked ❌ without an article number"; fi
      fi
    done
  done

  drift() { # file label → MEDIUM term-drift for "FR-### : text" lines that differ from spec.md
    local i x id txt key k
    load "$1"
    for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
      x=${L_TEXT[i]}
      [[ $x =~ $RE_DRIFT ]] || continue
      id=${BASH_REMATCH[1]} txt=${BASH_REMATCH[3]}; txt=${txt%"${txt##*[![:space:]]}"}
      key=$(norm_text "$txt")
      for ((k = 0; k < ${#FR_ID[@]}; k++)); do
        [ "${FR_ID[k]}" = "$id" ] || continue
        [ "${FR_KEY[k]}" = "$key" ] || add MEDIUM "$2" "${L_NO[i]}" term-drift "$id text differs from spec.md: $txt"
        break
      done
    done
  }
  if [ -f "$dir/tasks.md" ]; then
    drift "$dir/tasks.md" "$base/tasks.md"
    load "$dir/tasks.md"
    T_ID=() T_DEP=() T_LN=()
    for ((i = 0; i < ${#L_TEXT[@]}; i++)); do
      [[ ${L_TEXT[i]} =~ ^[[:space:]]*[|][[:space:]]*(T[0-9]+)[[:space:]]*[|] ]] || continue
      tid=${BASH_REMATCH[1]}; cells "${L_TEXT[i]}"
      dup=0; for t in ${T_ID[@]+"${T_ID[@]}"}; do [ "$t" = "$tid" ] && dup=1; done
      if [ $dup -eq 1 ]; then add HIGH "$base/tasks.md" "${L_NO[i]}" task-duplicate-id "task ID $tid is used more than once"; continue; fi
      deps=; rest=${CELLS[4]-}
      while [[ $rest =~ (T[0-9]+)(.*)$ ]]; do deps+=" ${BASH_REMATCH[1]}"; rest=${BASH_REMATCH[2]}; done
      T_ID+=("$tid"); T_DEP+=("$deps"); T_LN+=("${L_NO[i]}")
    done
    for ((i = 0; i < ${#T_ID[@]}; i++)); do
      for d in ${T_DEP[i]}; do
        known=0; for t in "${T_ID[@]}"; do [ "$t" = "$d" ] && known=1; done
        [ $known -eq 1 ] || add HIGH "$base/tasks.md" "${T_LN[i]}" task-unknown-dep "${T_ID[i]} depends on $d, which does not exist"
      done
    done
    # ponytail: O(n^3) peel of tasks whose deps are all done; fine for hand-written task lists
    DONE=(); for ((i = 0; i < ${#T_ID[@]}; i++)); do DONE+=(0); done
    changed=1
    while [ $changed -eq 1 ]; do
      changed=0
      for ((i = 0; i < ${#T_ID[@]}; i++)); do
        [ "${DONE[i]}" = 1 ] && continue
        ok=1
        for d in ${T_DEP[i]}; do
          for ((k = 0; k < ${#T_ID[@]}; k++)); do [ "${T_ID[k]}" = "$d" ] && [ "${DONE[k]}" = 0 ] && ok=0; done
        done
        [ $ok -eq 1 ] && { DONE[i]=1; changed=1; }
      done
    done
    left=
    while IFS= read -r t; do [ -n "$t" ] && left+="${left:+, }$t"; done < <(for ((i = 0; i < ${#T_ID[@]}; i++)); do [ "${DONE[i]}" = 0 ] && printf '%s\n' "${T_ID[i]}"; done | sort)
    [ -n "$left" ] && add HIGH "$base/tasks.md" 0 task-cycle "tasks in or blocked by a dependency cycle: $left"
  fi
  td="$ROOT/plans/initiatives/$name/tickets"
  if [ -d "$td" ]; then
    while IFS= read -r t; do [ -n "$t" ] && drift "$td/$t" "plans/initiatives/$name/tickets/$t"; done < <(cd "$td" && for t in *.md; do [ -f "$t" ] && printf '%s\n' "$t"; done | sort)
  fi
  if [ -f "$dir/requirements-checklist.md" ]; then
    load "$dir/requirements-checklist.md"
    tot=0 ref=0
    for x in ${L_TEXT[@]+"${L_TEXT[@]}"}; do
      [[ $x =~ ^[[:space:]]*[|][[:space:]]*CHK[0-9]+[[:space:]]*[|] ]] || continue
      cells "$x"; tot=$((tot + 1)); r=${CELLS[3]-}
      [ -n "$r" ] && [ "$r" != - ] && ref=$((ref + 1))
    done
    if [ $tot -gt 0 ] && [ $((ref * 100)) -lt $((tot * 80)) ]; then
      add HIGH "$base/requirements-checklist.md" 0 checklist-coverage "requirements checklist traces $ref of $tot items ($((ref * 100 / tot))%) to a spec reference; minimum 80%"
    fi
  fi
done

# ── Report ───────────────────────────────────────────────────────────────────
SORTED=()
while IFS= read -r l; do [ -n "$l" ] && SORTED+=("$l"); done < <(for l in ${F[@]+"${F[@]}"}; do printf '%s\n' "$l"; done | sort)
C=0 H=0 M=0 LW=0
for l in ${SORTED[@]+"${SORTED[@]}"}; do case ${l%%$'\t'*} in 1) C=$((C + 1)) ;; 2) H=$((H + 1)) ;; 3) M=$((M + 1)) ;; *) LW=$((LW + 1)) ;; esac; done
E=$((C + H)) W=$((M + LW)) EXIT=0
if [ $E -gt 0 ]; then EXIT=1; elif [ $STRICT -eq 1 ] && [ $W -gt 0 ]; then EXIT=2; fi

if [ $JSON -eq 1 ]; then
  printf '{"root":"%s","findings":[' "$(jesc "$RL")"
  for ((i = 0; i < ${#SORTED[@]}; i++)); do
    IFS=$'\t' read -r _ file _ rule sev line msg <<<"${SORTED[i]}"
    [ $i -gt 0 ] && printf ','
    printf '{"n":%d,"id":"A%03d","severity":"%s","file":"%s","line":%s,"rule":"%s","message":"%s"}' $((i + 1)) $((i + 1)) "$sev" "$(jesc "$file")" "$line" "$rule" "$(jesc "$msg")"
  done
  if [ $STRICT -eq 1 ]; then st=true; else st=false; fi
  printf '],"critical":%d,"high":%d,"medium":%d,"low":%d,"errors":%d,"warnings":%d,"strict":%s,"exit":%d}\n' $C $H $M $LW $E $W "$st" $EXIT
else
  echo "analyze — $RL"
  [ $GATE -eq 0 ] && [ ${#NAMES[@]} -eq 0 ] && echo "No initiatives under specs/."
  [ ${#SORTED[@]} -eq 0 ] && echo "No findings."
  for ((i = 0; i < ${#SORTED[@]}; i++)); do
    IFS=$'\t' read -r _ file _ rule sev line msg <<<"${SORTED[i]}"
    loc=$file; [ "$line" -gt 0 ] && loc+=":$line"
    printf '%d. A%03d %s %s [%s] %s\n' $((i + 1)) $((i + 1)) "$sev" "$loc" "$rule" "$msg"
  done
  case $EXIT in 0) v=PASS ;; 1) v=FAIL ;; *) v=WARN ;; esac
  echo "Result: ${#SORTED[@]} finding(s): $C critical, $H high, $M medium, $LW low — $v"
fi
exit $EXIT
