#!/usr/bin/env bash
# aa — single entry point for the agentic-agile workflow (any agent, any OS).
#
# Intents dispatch to the sibling scripts or scaffold artifacts from the skill templates.
# Scaffolding intents (specify, plan, tasks) require the Phase 0 gate to be open and never
# overwrite a file. converge groups the trace + analyze findings of one initiative into numbered
# next tasks (missing · partial · contradictory · unrequested). No network. PowerShell twin: aa.ps1.
#
# Usage: aa.sh <intent> [args]            aa.sh help   (intent list)
# Exit:  the dispatched script's exit code · scaffolding: 0 ok, 1 blocked · 3 configuration error
set -u
LC_ALL=C
export LC_ALL

SKILL=$(cd "$(dirname "$0")/.." && pwd)
die() { echo "aa: $1" >&2; exit 3; }

usage() {
  cat <<'EOF'
Usage: aa <intent> [args]
Intents:
1. init [--preset NAME] [--dry-run]  scaffold plans/agile/, plans/, specs/ (scripts/init)
2. structure [--scorecard]           Phase 0 gate (scripts/check-structure)
3. doctor                            one-screen health (scripts/doctor)
4. specify <slug>                    create specs/<slug>/spec.md (gate open)
5. clarify <slug>                    open questions and unconfirmed answers (frameworks/clarify.md)
6. plan <slug>                       create design.md, domain-model.md, requirements-checklist.md (spec passes)
7. tasks <slug>                      create tasks.md (design passes)
8. verify <slug> [--strict]          validate the initiative (scripts/check-spec)
9. trace / analyze / baseline        traceability, cross-artifact analysis, accepted findings
10. audit                            hygiene of the team's system (scripts/audit-agile)
11. converge <slug>                  trace + analyze gaps as numbered next tasks
12. import-speckit [--from DIR] [--write]  convert a Spec Kit project (dry run by default)
13. help                             this list
Common option: --root DIR (project root, default: current directory).
EOF
}

[ $# -gt 0 ] || { usage; exit 3; }
INTENT=$1; shift
ROOT=. SLUG= REST=()
ARGS=("$@")
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    -*) REST+=("$1"); shift ;;
    *) if [ -z "$SLUG" ]; then SLUG=$1; else REST+=("$1"); fi; shift ;;
  esac
done
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done

sib() { # $1 script name (fixed list), rest = args → runs it and exits with its code
  local f
  case "$1" in
    init) f="$(cd "$(dirname "$0")" && pwd)/init.sh" ;;
    check-structure) f="$(cd "$(dirname "$0")" && pwd)/check-structure.sh" ;;
    check-spec) f="$(cd "$(dirname "$0")" && pwd)/check-spec.sh" ;;
    doctor) f="$(cd "$(dirname "$0")" && pwd)/doctor.sh" ;;
    audit-agile) f="$(cd "$(dirname "$0")" && pwd)/audit-agile.sh" ;;
    trace) f="$(cd "$(dirname "$0")" && pwd)/trace.sh" ;;
    analyze) f="$(cd "$(dirname "$0")" && pwd)/analyze.sh" ;;
    baseline) f="$(cd "$(dirname "$0")" && pwd)/baseline.sh" ;;
    import-speckit) f="$(cd "$(dirname "$0")" && pwd)/import-speckit.sh" ;;
    *) die "unknown script: $1" ;;
  esac
  shift
  [ -f "$f" ] || die "scripts/$(basename "$f") not found (install the complete agentic-agile skill)"
  bash "$f" "$@"; exit $?
}
need_slug() {
  [ -n "$SLUG" ] || die "$INTENT needs an initiative slug (e.g. aa $INTENT invoice-export)"
  [[ $SLUG =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid slug: $SLUG (use kebab-case: a-z, 0-9, -)"
  [ -d "$ROOT" ] || die "project root not found: $ROOT"
  if [ "$RL" = . ]; then SPEC=specs/$SLUG; else SPEC=$RL/specs/$SLUG; fi
}
gate() { # Phase 0 must be open before any artifact is created
  local cs
  cs="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  bash "$cs" --root "$ROOT" >/dev/null 2>&1
  local x=$?
  [ $x -eq 3 ] && die "check-structure failed on root: $ROOT"
  if [ $x -ne 0 ]; then
    echo "Blocked: Phase 0 gate closed. Run: aa structure --root $RL, then complete plans/agile/ with the team."
    exit 1
  fi
}
spec_passes() {
  local cp
  cp="$(cd "$(dirname "$0")" && pwd)/check-spec.sh"
  bash "$cp" "$SPEC" --root "$ROOT" >/dev/null 2>&1
}
N=0
scaffold() { # $1 template name, $2 target relative to the initiative → create or skip
  local t="$SKILL/templates/$1" f="$SPEC/$2"
  N=$((N + 1))
  if [ -e "$f" ]; then printf '%d. skip %s (exists)\n' "$N" "$f"
  else mkdir -p "$SPEC"; cp "$t" "$f"; printf '%d. create %s\n' "$N" "$f"; fi
}
need_templates() { local t; for t in "$@"; do [ -f "$SKILL/templates/$t" ] || die "missing template: templates/$t"; done; }

RE_FENCE='^[[:space:]]*(```|~~~)'
RE_HEAD='^(#{1,6})[[:space:]]+(.*)$'
RE_ITEM='^[[:space:]]*[0-9]+[.)][[:space:]]'
RE_MSG='"message":"(([^"\\]|\\.)*)"'
RE_RULE='"rule":"([^"]*)"'
RE_CAT='"category":"([^"]*)"'
trim() { TRIM=$1; TRIM=${TRIM#"${TRIM%%[![:space:]]*}"}; TRIM=${TRIM%"${TRIM##*[![:space:]]}"}; }
cells() {
  local r=$1 k
  r=${r#"${r%%[![:space:]]*}"}; r=${r%"${r##*[![:space:]]}"}; r=${r#|}; r=${r%|}
  C=(); IFS='|' read -ra C <<<"$r|"
  for k in "${!C[@]}"; do trim "${C[k]}"; C[k]=$TRIM; done
}
col_of() { # $1 header row, $2 ERE → COL (0-based) or -1
  local k; cells "$1"; COL=-1
  shopt -s nocasematch
  for ((k = 0; k < ${#C[@]}; k++)); do [[ ${C[k]} =~ $2 ]] && { COL=$k; break; }; done
  shopt -u nocasematch
}

case "$INTENT" in
  help|-h|--help) usage; exit 0 ;;
  init) sib init "${ARGS[@]}" ;;
  structure) sib check-structure "${ARGS[@]}" ;;
  doctor) sib doctor "${ARGS[@]}" ;;
  audit) sib audit-agile "${ARGS[@]}" ;;
  trace) sib trace "${ARGS[@]}" ;;
  analyze) sib analyze "${ARGS[@]}" ;;
  baseline) sib baseline "${ARGS[@]}" ;;
  import-speckit) sib import-speckit "${ARGS[@]}" ;;
  verify) need_slug; sib check-spec "$SPEC" --root "$ROOT" ${REST[@]+"${REST[@]}"} ;;

  specify)
    need_slug; need_templates spec.md; gate
    echo "aa specify — $SPEC"
    scaffold spec.md spec.md
    echo "Next: fill Phase 1 (FR-### table, Gherkin scenarios tagged @FR-### and @P1-@P3, open questions), then run: aa clarify $SLUG"
    exit 0 ;;

  clarify)
    need_slug
    f=$SPEC/spec.md
    [ -f "$f" ] || die "spec not found: $f (run: aa specify $SLUG)"
    sect= lvl=0 fence=0 hdr= qn=0 blocking=0 answers=0 unconf=0 Q=()
    while IFS= read -r line || [ -n "$line" ]; do
      line=${line%$'\r'}
      if [[ $line =~ $RE_FENCE ]]; then fence=$((1 - fence)); continue; fi
      [ $fence -eq 1 ] && continue
      if [[ $line =~ $RE_HEAD ]]; then
        hl=${#BASH_REMATCH[1]} h=${BASH_REMATCH[2]} hdr=
        if [ -n "$sect" ] && [ $hl -le $lvl ]; then sect=; fi
        shopt -s nocasematch
        if [ -z "$sect" ]; then
          if [[ $h =~ open\ questions|preguntas\ abiertas ]]; then sect=open lvl=$hl
          elif [[ $h =~ clarifications|aclaraciones ]]; then sect=clar lvl=$hl; fi
        fi
        shopt -u nocasematch
        continue
      fi
      case "$sect" in
        open)
          [[ $line =~ ^[[:space:]]*\| ]] || { hdr=; continue; }
          [[ ! $line =~ [^-|:[:space:]] ]] && continue
          if [ -z "$hdr" ]; then hdr=$line; continue; fi
          col_of "$hdr" 'question|pregunta'; qc=$COL
          col_of "$hdr" '^for$|^para$|owner|responsable'; fc=$COL
          col_of "$hdr" 'block|bloquea'; bc=$COL
          cells "$line"
          [ $qc -ge 0 ] && q=${C[qc]-} || q=
          [ -n "$q" ] || continue
          [ $fc -ge 0 ] && fo=${C[fc]-} || fo=-
          [ $bc -ge 0 ] && bl=${C[bc]-} || bl=-
          qn=$((qn + 1)); Q+=("$qn. $q — for ${fo:--} — blocks sprint: ${bl:--}")
          case "$(printf '%s' "$bl" | tr 'A-Z' 'a-z')" in yes|y|si|sí|true) blocking=$((blocking + 1)) ;; esac ;;
        clar)
          [[ $line =~ $RE_ITEM ]] || continue
          answers=$((answers + 1))
          shopt -s nocasematch
          [[ $line =~ (confirmed\ by|confirmado\ por)[[:space:]]*: ]] || unconf=$((unconf + 1))
          shopt -u nocasematch ;;
      esac
    done <"$f"
    echo "aa clarify — $SPEC"
    if [ $qn -eq 0 ]; then echo "Open questions: none"; else echo "Open questions:"; printf '%s\n' "${Q[@]}"; fi
    echo "Clarifications: $answers answer(s), $unconf without Confirmed by"
    echo "Protocol: frameworks/clarify.md — at most 5 questions, one at a time, numbered options with a recommended one; record each answer under ## Clarifications > ### Session YYYY-MM-DD with Confirmed by: <name> (<role>)."
    if [ $blocking -gt 0 ] || [ $unconf -gt 0 ]; then
      echo "Result: $blocking blocking question(s), $unconf unconfirmed answer(s) — ATTENTION"; exit 1
    fi
    echo "Result: 0 blocking question(s), 0 unconfirmed answer(s) — READY"; exit 0 ;;

  plan)
    need_slug; need_templates design.md domain-model.md requirements-checklist.md; gate
    [ -f "$SPEC/spec.md" ] || die "spec not found: $SPEC/spec.md (run: aa specify $SLUG)"
    if ! spec_passes; then echo "Blocked: $SPEC does not pass check-spec. Run: aa verify $SLUG"; exit 1; fi
    echo "aa plan — $SPEC"
    scaffold design.md design.md
    scaffold domain-model.md domain-model.md
    scaffold requirements-checklist.md requirements-checklist.md
    echo "Next: fill design.md (8 elements), domain-model.md and requirements-checklist.md, then run: aa tasks $SLUG"
    exit 0 ;;

  tasks)
    need_slug; need_templates tasks.md; gate
    if [ ! -f "$SPEC/design.md" ]; then echo "Blocked: $SPEC/design.md missing. Run: aa plan $SLUG"; exit 1; fi
    if ! spec_passes; then echo "Blocked: $SPEC does not pass check-spec (spec and design). Run: aa verify $SLUG"; exit 1; fi
    echo "aa tasks — $SPEC"
    scaffold tasks.md tasks.md
    echo "Next: list T### tasks per phase (mark [P] when parallel, map Req to FR-###), estimate only after the team votes, then run: aa verify $SLUG"
    exit 0 ;;

  converge)
    need_slug
    TR="$(cd "$(dirname "$0")" && pwd)/trace.sh"
    AN="$(cd "$(dirname "$0")" && pwd)/analyze.sh"
    [ -f "$TR" ] || die "scripts/trace.sh not found (install the complete agentic-agile skill)"
    [ -f "$AN" ] || die "scripts/analyze.sh not found (install the complete agentic-agile skill)"
    G_MISS=() G_PART=() G_CONT=() G_UNRQ=()
    for s in trace analyze; do
      if [ $s = trace ]; then f=$TR; else f=$AN; fi
      j=$(bash "$f" --root "$ROOT" --spec "specs/$SLUG" --json 2>/dev/null); x=$?
      [ $x -eq 3 ] && die "$s failed on $SPEC"
      while IFS= read -r o; do
        [[ $o =~ $RE_MSG ]] || continue
        m=${BASH_REMATCH[1]}; m=${m//\\\"/\"}; m=${m//\\\\/\\}
        r=; [[ $o =~ $RE_RULE ]] && r=${BASH_REMATCH[1]}
        cat=; [[ $o =~ $RE_CAT ]] && cat=${BASH_REMATCH[1]}
        if [ -z "$cat" ]; then
          k=$(printf '%s %s' "$r" "$m" | tr 'A-Z' 'a-z')
          case "$k" in
            *unrequested*|*unmapped*|*orphan*|*"not requested"*) cat=unrequested ;;
            *contradict*|*conflict*|*inconsisten*|*mismatch*) cat=contradictory ;;
            *partial*) cat=partial ;;
            *) cat=missing ;;
          esac
        fi
        e="$m ($s${r:+: $r})"
        case "$cat" in
          partial) G_PART+=("$e") ;; contradictory) G_CONT+=("$e") ;; unrequested) G_UNRQ+=("$e") ;; *) G_MISS+=("$e") ;;
        esac
      done < <(printf '%s' "$j" | grep -o '{[^{}]*}')
    done
    echo "aa converge — $SPEC"
    n=0
    group() { # $1 title, rest = entries
      local t=$1; shift
      [ $# -gt 0 ] || return 0
      echo "$t:"
      for e in "$@"; do n=$((n + 1)); printf '%d. %s\n' "$n" "$e"; done
    }
    group Missing ${G_MISS[@]+"${G_MISS[@]}"}
    group Partial ${G_PART[@]+"${G_PART[@]}"}
    group Contradictory ${G_CONT[@]+"${G_CONT[@]}"}
    group Unrequested ${G_UNRQ[@]+"${G_UNRQ[@]}"}
    if [ $n -eq 0 ]; then echo "No gaps: spec, tasks and code converge."; exit 0; fi
    echo "Next: add $n task(s) under '## Phase N: Convergence' in $SPEC/tasks.md (one per gap, mapped to its FR-###), then run: aa converge $SLUG"
    exit 1 ;;

  *) die "unknown intent: $INTENT (run: aa help)" ;;
esac
