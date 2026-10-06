#!/usr/bin/env bash
# import-speckit — convert a GitHub Spec Kit project into the agentic-agile layout.
#
# Reads <from>/specs/NNN-<feature>/ (spec.md, plan.md, research.md, quickstart.md, data-model.md,
# tasks.md, contracts/) and <from>/.specify/memory/constitution.md, and writes into --root:
# specs/<feature>/{spec.md, design.md, domain-model.md, tasks.md, contracts/} and
# plans/agile/constitution.md (only if absent). User stories become Gherkin scenario skeletons
# (P1-P3 kept; tagged @FR-### only when the feature has a single FR), FR-### / SC-### become
# tables, [NEEDS CLARIFICATION: ...] markers become blocking open questions, and every file is
# labelled "Proposed — imported from spec-kit ..., needs confirmation". Dry run by default
# (numbered plan); --write applies it. Never overwrites a file. No network.
# PowerShell twin: import-speckit.ps1.
#
# Usage: import-speckit.sh [--root DIR] [--from DIR] [--write]
# Exit:  0 ok · 3 configuration error (no Spec Kit features found, bad paths)
set -u
LC_ALL=C
export LC_ALL

ROOT=. FROM= WRITE=0
die() { echo "import-speckit: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --from) [ $# -ge 2 ] || die "--from needs a value"; FROM=$2; shift 2 ;;
    --write) WRITE=1; shift ;;
    -h|--help) echo "Usage: import-speckit.sh [--root DIR] [--from DIR] [--write]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -n "$FROM" ] || FROM=$ROOT
[ -d "$ROOT" ] || die "project root not found: $ROOT"
[ -d "$FROM" ] || die "Spec Kit project not found: $FROM"
norm() { local p=${1//\\//}; while [ "${p%/}" != "$p" ] && [ "$p" != / ]; do p=${p%/}; done; printf '%s' "$p"; }
RL=$(norm "$ROOT") FL=$(norm "$FROM")
rel() { if [ "$RL" = . ]; then printf '%s' "$1"; else printf '%s/%s' "$RL" "$1"; fi; }

FEATS=()
if [ -d "$FROM/specs" ]; then
  while IFS= read -r d; do [ -n "$d" ] && FEATS+=("$d"); done < <(cd "$FROM/specs" && for d in */; do [ -f "$d/spec.md" ] && printf '%s\n' "${d%/}"; done | sort)
fi
[ ${#FEATS[@]} -gt 0 ] || die "no Spec Kit features found under $FL/specs (expected specs/NNN-<feature>/spec.md)"

LABEL_PRE='Proposed — imported from spec-kit `'
LABEL_POST='`, needs confirmation.'
N=0
step() { N=$((N + 1)); printf '%d. %s\n' "$N" "$1"; }
emit() { # $1 target (relative to root), $2 source label, $3 content, $4 = copy to copy file $3 as-is
  local t=$1
  if [ -e "$ROOT/$t" ]; then step "skip $(rel "$t") (exists)"; return; fi
  step "create $(rel "$t") (from $2)"
  [ $WRITE -eq 1 ] || return 0
  mkdir -p "$(dirname "$ROOT/$t")"
  if [ "${4-}" = copy ]; then cp "$3" "$ROOT/$t"; else printf '%s' "$3" >"$ROOT/$t"; fi
}
demote() { # prints file $1 with Markdown headings demoted by two levels (fenced code untouched)
  local line fence=0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    if [[ $line =~ $RE_FENCE ]]; then fence=$((1 - fence)); printf '%s\n' "$line"; continue; fi
    if [ $fence -eq 0 ] && [[ $line =~ ^(#{1,6})[[:space:]](.*)$ ]]; then
      local h="##${BASH_REMATCH[1]}"; h=${h:0:6}
      printf '%s %s\n' "$h" "${BASH_REMATCH[2]}"
    else printf '%s\n' "$line"; fi
  done <"$1"
}
cellsafe() { local v=${1//|//}; printf '%s' "$v"; }
trim() { TRIM=$1; TRIM=${TRIM#"${TRIM%%[![:space:]]*}"}; TRIM=${TRIM%"${TRIM##*[![:space:]]}"}; }

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_STORY='^###[[:space:]]+User Story[[:space:]]+([0-9]+)[[:space:]]*[^[:alnum:][:space:]]+[[:space:]]*(.*)$'
RE_PRIO='[(]Priority:[[:space:]]*(P[1-3])[)]'
RE_ACC='^[[:space:]]*[0-9]+[.][[:space:]]+[*][*]Given[*][*][[:space:]]*(.*),[[:space:]]*[*][*]When[*][*][[:space:]]*(.*),[[:space:]]*[*][*]Then[*][*][[:space:]]*(.*)$'
RE_FR='^[[:space:]]*[-*][[:space:]]+[*][*](FR-[0-9]+)[*][*][[:space:]]*:?[[:space:]]*(.*)$'
RE_SC='^[[:space:]]*[-*][[:space:]]+[*][*](SC-[0-9]+)[*][*][[:space:]]*:?[[:space:]]*(.*)$'
RE_NC='\[NEEDS CLARIFICATION:[[:space:]]*([^]]*)\](.*)$'
RE_Q='^[[:space:]]*[-*][[:space:]]+(Q:.*)$'
RE_BULLET='^[[:space:]]*[-*][[:space:]]+(.*)$'
RE_H2='^##[[:space:]]+(.*)$'
RE_H3='^###[[:space:]]+(.*)$'
RE_PHASE='^##[[:space:]]+Phase[[:space:]]+([0-9]+)[[:space:]]*:?[[:space:]]*(.*)$'
RE_TASK='^[[:space:]]*[-*][[:space:]]+\[( |x|X)\][[:space:]]+(T[0-9]+)[[:space:]]+(.*)$'

for feat in "${FEATS[@]}"; do
  slug=${feat#"${feat%%[!0-9]*}"}; slug=${slug#-}; [ -n "$slug" ] || slug=$feat
  src="specs/$feat"; dst="specs/$slug"
  echo "Feature: $src → $(rel "$dst")"

  # ── spec.md ────────────────────────────────────────────────────────────────
  title=$slug FRS=() FRT=() SCS=() SCT=() QS=() ASM=() EDGE=() OPENQ=()
  ST_T=() ST_P=() ST_G=() ST_W=() ST_H=() ST_N=()
  sec= sub= story=0 sp= stitle=
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    if [[ $line =~ ^#[[:space:]]+(Feature Specification:[[:space:]]*)?(.*)$ ]] && [ "$title" = "$slug" ]; then trim "${BASH_REMATCH[2]}"; [ -n "$TRIM" ] && title=$TRIM; continue; fi
    rest=$line
    while [[ $rest =~ $RE_NC ]]; do trim "${BASH_REMATCH[1]}"; OPENQ+=("$TRIM"); rest=${BASH_REMATCH[2]}; done
    if [[ $line =~ $RE_STORY ]]; then
      story=${BASH_REMATCH[1]} stitle=${BASH_REMATCH[2]} sp=-
      [[ $stitle =~ $RE_PRIO ]] && sp=${BASH_REMATCH[1]}
      stitle=${stitle%%(Priority*}; trim "$stitle"; stitle=$TRIM; sub=story; continue
    fi
    if [[ $line =~ $RE_H2 ]]; then sec=${BASH_REMATCH[1]} sub=; story=0; continue; fi
    if [[ $line =~ $RE_H3 ]]; then sub=${BASH_REMATCH[1]}; story=0; continue; fi
    if [ $story -gt 0 ] && [[ $line =~ $RE_ACC ]]; then
      ST_T+=("US$story $stitle"); ST_P+=("$sp"); ST_N+=("$story")
      trim "${BASH_REMATCH[1]}"; ST_G+=("$TRIM"); trim "${BASH_REMATCH[2]}"; ST_W+=("$TRIM"); trim "${BASH_REMATCH[3]}"; ST_H+=("$TRIM")
      continue
    fi
    if [[ $line =~ $RE_FR ]]; then FRS+=("${BASH_REMATCH[1]}"); FRT+=("${BASH_REMATCH[2]}"); continue; fi
    if [[ $line =~ $RE_SC ]]; then SCS+=("${BASH_REMATCH[1]}"); SCT+=("${BASH_REMATCH[2]}"); continue; fi
    case "$sec" in
      Clarifications*) [[ $line =~ $RE_Q ]] && QS+=("${BASH_REMATCH[1]}") ;;
      Assumptions*) [[ $line =~ $RE_BULLET ]] && ASM+=("${BASH_REMATCH[1]}") ;;
    esac
    case "$sub" in Edge\ Cases*) [[ $line =~ $RE_BULLET ]] && EDGE+=("${BASH_REMATCH[1]}") ;; esac
  done <"$FROM/$src/spec.md"

  only=; [ ${#FRS[@]} -eq 1 ] && only=${FRS[0]}
  o="# Spec: $title"$'\n\n'"$LABEL_PRE$src/spec.md$LABEL_POST"$'\n\n'
  o+="## 1.1 Problem"$'\n\n'"Proposed — imported, needs confirmation: state the problem, its value and the stakeholders (Spec Kit has no Problem section; see the user stories below)."$'\n\n'
  o+="## Functional requirements"$'\n\n'"| ID | Requirement | Priority |"$'\n'"|----|-------------|----------|"$'\n'
  for ((i = 0; i < ${#FRS[@]}; i++)); do o+="| ${FRS[i]} | $(cellsafe "${FRT[i]}") | - |"$'\n'; done
  o+=$'\n'"## 1.2 Behavioral contract"$'\n\n'"\`\`\`gherkin"$'\n'"# language: en"$'\n'"Feature: $title"$'\n'
  for ((i = 0; i < ${#ST_T[@]}; i++)); do
    tags=; [ -n "$only" ] && tags="@$only "; [ "${ST_P[i]}" != - ] && tags+="@${ST_P[i]}"; trim "$tags"; tags=$TRIM
    o+=$'\n'
    [ -n "$tags" ] && o+="  $tags"$'\n'
    o+="  Scenario: ${ST_T[i]} - $((i + 1))"$'\n'
    o+="    # Origin: imported from spec-kit $src/spec.md (User Story ${ST_N[i]}); Proposed, link @FR-### and confirm"$'\n'
    o+="    Given ${ST_G[i]}"$'\n'"    When ${ST_W[i]}"$'\n'"    Then ${ST_H[i]}"$'\n'
  done
  o+="\`\`\`"$'\n\n'"## 1.3 Out of scope"$'\n\n'"Proposed — imported, needs confirmation: Spec Kit has no out-of-scope section; list the exclusions with the team."$'\n\n'
  o+="## 1.4 Success criteria"$'\n\n'"| ID | Criterion | Scenario(s) |"$'\n'"|----|-----------|-------------|"$'\n'
  for ((i = 0; i < ${#SCS[@]}; i++)); do o+="| ${SCS[i]} | $(cellsafe "${SCT[i]}") | - |"$'\n'; done
  o+=$'\n'"## 1.5 Constraints & assumptions"$'\n\n'
  if [ ${#ASM[@]} -eq 0 ]; then o+="Proposed — imported, needs confirmation: none listed in Spec Kit."$'\n'
  else for ((i = 0; i < ${#ASM[@]}; i++)); do o+="$((i + 1)). ${ASM[i]} (Proposed)"$'\n'; done; fi
  if [ ${#QS[@]} -gt 0 ]; then
    o+=$'\n'"## Clarifications"$'\n\n'"### Session imported"$'\n\n'
    for ((i = 0; i < ${#QS[@]}; i++)); do o+="$((i + 1)). ${QS[i]} — Proposed, imported; needs Confirmed by"$'\n'; done
  fi
  o+=$'\n'"## Open questions"$'\n\n'"| # | Question | For | Blocks sprint? |"$'\n'"|---|----------|-----|----------------|"$'\n'
  for ((i = 0; i < ${#OPENQ[@]}; i++)); do o+="| $((i + 1)) | $(cellsafe "${OPENQ[i]}") | team | Yes |"$'\n'; done
  if [ ${#EDGE[@]} -gt 0 ]; then
    o+=$'\n'"## Imported notes"$'\n\n'"Edge cases from Spec Kit (turn each into a scenario or an out-of-scope item):"$'\n\n'
    for ((i = 0; i < ${#EDGE[@]}; i++)); do o+="$((i + 1)). ${EDGE[i]}"$'\n'; done
  fi
  emit "$dst/spec.md" "$src/spec.md" "$o"

  # ── design.md (plan.md + research.md + quickstart.md) ───────────────────────
  if [ -f "$FROM/$src/plan.md" ]; then
    o="# Design: $title"$'\n\n'"$LABEL_PRE$src/plan.md$LABEL_POST"$'\n\n'"## Architecture & Design"$'\n\n'
    for e in "1. Architectural style" "2. Layers" "3. Bounded context" "4. Patterns to mirror" "5. State model" "6. Composition points" "7. Public surface delta" "8. Anti-violations"; do
      o+="### $e"$'\n\n'"Proposed — fill from the imported notes below."$'\n\n'
    done
    o+="## Imported notes"$'\n'
    for f in plan research quickstart; do
      [ -f "$FROM/$src/$f.md" ] || continue
      o+=$'\n'"### From $f.md"$'\n\n'"$(demote "$FROM/$src/$f.md")"$'\n'
    done
    emit "$dst/design.md" "$src/plan.md" "$o"
  fi

  # ── domain-model.md ────────────────────────────────────────────────────────
  if [ -f "$FROM/$src/data-model.md" ]; then
    o="# Domain model: $title"$'\n\n'"$LABEL_PRE$src/data-model.md$LABEL_POST"$'\n\n'"$(demote "$FROM/$src/data-model.md")"$'\n'
    emit "$dst/domain-model.md" "$src/data-model.md" "$o"
  fi

  # ── contracts/ ─────────────────────────────────────────────────────────────
  if [ -d "$FROM/$src/contracts" ]; then
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      emit "$dst/contracts/$c" "$src/contracts/$c" "$FROM/$src/contracts/$c" copy
    done < <(cd "$FROM/$src/contracts" && find . -type f | sed 's|^\./||' | sort)
  fi

  # ── tasks.md ───────────────────────────────────────────────────────────────
  if [ -f "$FROM/$src/tasks.md" ]; then
    o="# Tasks: $title"$'\n\n'"$LABEL_PRE$src/tasks.md$LABEL_POST"$'\n'
    TH=$'| ID | P | Req | Task | Depends | Est | Status |\n|----|---|-----|------|---------|-----|--------|\n'
    inphase=0
    while IFS= read -r line || [ -n "$line" ]; do
      line=${line%$'\r'}
      if [[ $line =~ $RE_PHASE ]]; then o+=$'\n'"## Phase ${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}"$'\n\n'"$TH"; inphase=1; continue; fi
      [[ $line =~ $RE_TASK ]] || continue
      [ $inphase -eq 1 ] || { o+=$'\n'"## Phase 1: Imported"$'\n\n'"$TH"; inphase=1; }
      st=-; [ "${BASH_REMATCH[1]}" != ' ' ] && st=✅
      id=${BASH_REMATCH[2]} d=${BASH_REMATCH[3]} p=- req=-
      if [[ $d =~ ^\[P\][[:space:]]*(.*)$ ]]; then p='[P]'; d=${BASH_REMATCH[1]}; fi
      if [[ $d =~ ^\[US[0-9]+\][[:space:]]*(.*)$ ]]; then d=${BASH_REMATCH[1]}; [ -n "$only" ] && req=$only; fi
      o+="| $id | $p | $req | $(cellsafe "$d") | - | - | $st |"$'\n'
    done <"$FROM/$src/tasks.md"
    emit "$dst/tasks.md" "$src/tasks.md" "$o"
  fi
done

# ── constitution ─────────────────────────────────────────────────────────────
c=.specify/memory/constitution.md
if [ -f "$FROM/$c" ]; then
  o="$LABEL_PRE$c$LABEL_POST"$'\n\n'"$(tr -d '\r' <"$FROM/$c")"$'\n'
  emit plans/agile/constitution.md "$c" "$o"
fi

echo "Imported content is Proposed: confirm it with the team (Confirmed by), link scenarios to FR-###, then run: aa verify <feature>"
if [ $WRITE -eq 1 ]; then echo "Written: $N action(s) applied (existing files skipped)."
else echo "Dry run: nothing written. Re-run with --write to apply."; fi
exit 0
