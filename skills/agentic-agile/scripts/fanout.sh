#!/usr/bin/env bash
# fanout — split one list into many self-contained SDD briefs, one per item, each with the model
# tier that should run it.
#
# Reads a list (default plans/initiatives/<slug>/inventory.md; also tasks.md, a converge dump, or
# any Markdown table or numbered list) and writes one brief per item from templates/dispatch-task.md
# into specs/<slug>/dispatch/, plus the manifest specs/<slug>/dispatch.md. A brief carries the item
# verbatim, its location, the requirement it serves, the file allow-list, the acceptance criteria,
# the escalation rule and the exact runner command — so the smallest capable model can execute it
# without the rest of the project in context.
#
# Parsing: a file with at least one table row is read as tables only (its numbered lists are prose,
# like the Sources list of an inventory); a file with no table is read as a numbered or bulleted
# list, IDs assigned by position. Rows whose Status is done or dropped are skipped.
#
# The script writes files and nothing else: it never runs an agent, never dispatches anything, and
# never edits the spec, tasks.md or the tracker. PowerShell twin: fanout.ps1.
#
# Usage: fanout.sh <slug> [--from PATH] [--root DIR] [--model-tier small|default|deep]
#                  [--model NAME] [--autonomy N1|N2|N3|N4] [--only IDS] [--priority P#]
#                  [--limit N] [--json] [--dry-run] [--force]
#                  (--skip-structure exists for the parity tests only)
# Exit:  0 briefs written or already present · 1 gate closed or no item in the list
#        3 configuration error
set -u
LC_ALL=C
export LC_ALL

SKILL=$(cd "$(dirname "$0")/.." && pwd)
ROOT=. SLUG= FROM= TIER=small MODEL= AUTONOMY=N2 ONLY= PRIORITY= LIMIT=50 JSON=0 DRY=0 FORCE=0 SKIP=0
die() { echo "fanout: $1" >&2; exit 3; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --from) [ $# -ge 2 ] || die "--from needs a value"; FROM=$2; shift 2 ;;
    --model-tier) [ $# -ge 2 ] || die "--model-tier needs a value"; TIER=$2; shift 2 ;;
    --model) [ $# -ge 2 ] || die "--model needs a value"; MODEL=$2; shift 2 ;;
    --autonomy) [ $# -ge 2 ] || die "--autonomy needs a value"; AUTONOMY=$2; shift 2 ;;
    --only) [ $# -ge 2 ] || die "--only needs a value"; ONLY=$2; shift 2 ;;
    --priority) [ $# -ge 2 ] || die "--priority needs a value"; PRIORITY=$2; shift 2 ;;
    --limit) [ $# -ge 2 ] || die "--limit needs a value"; LIMIT=$2; shift 2 ;;
    --json) JSON=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --force) FORCE=1; shift ;;
    --skip-structure) SKIP=1; shift ;;
    -h|--help)
      echo "Usage: fanout <slug> [--from PATH] [--root DIR] [--model-tier small|default|deep] [--model NAME] [--autonomy N1|N2|N3|N4] [--only IDS] [--priority P#] [--limit N] [--json] [--dry-run] [--force]"
      echo "  <slug>          initiative in kebab-case; briefs land in specs/<slug>/dispatch/"
      echo "  --from PATH     the list to split (default plans/initiatives/<slug>/inventory.md)"
      echo "  --model-tier    which model row of plans/agile/capabilities.md to use (default small)"
      echo "  --model NAME    use this model instead of the recorded one"
      echo "  --only IDS      comma-separated source IDs to include (e.g. I003,I007)"
      echo "  --priority P#   only rows whose Priority column is P# (e.g. P1)"
      exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$SLUG" ] || die "only one initiative slug is allowed"; SLUG=$1; shift ;;
  esac
done

[ -n "$SLUG" ] || die "fanout needs an initiative slug (e.g. fanout invoice-export)"
[[ $SLUG =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid slug: $SLUG (use kebab-case: a-z, 0-9, -)"
case "$TIER" in small|default|deep) ;; *) die "--model-tier must be small, default or deep" ;; esac
case "$AUTONOMY" in N1|N2|N3|N4) ;; *) die "--autonomy must be N1, N2, N3 or N4 (N0 means the agent does not participate)" ;; esac
[[ $LIMIT =~ ^[0-9]+$ ]] && [ "$LIMIT" -gt 0 ] || die "--limit must be a positive integer"
[ -d "$ROOT" ] || die "project root not found: $ROOT"
RL=${ROOT//\\//}; while [ "${RL%/}" != "$RL" ] && [ "$RL" != / ]; do RL=${RL%/}; done
[ -n "$FROM" ] || FROM="plans/initiatives/$SLUG/inventory.md"
FROM=${FROM//\\//}
case "$FROM" in /*|[A-Za-z]:*) die "--from must be a path relative to the project" ;; esac
case "/$FROM/" in */../*) die "--from must not contain '..'" ;; esac
for t in dispatch-task.md dispatch.md; do [ -f "$SKILL/templates/$t" ] || die "missing template: templates/$t"; done

jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; printf '%s' "$s" | tr -d '\000-\010\013-\037'; }

# ── Phase 0 ──────────────────────────────────────────────────────────────────
if [ $SKIP -eq 0 ]; then
  CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
  [ -f "$CS" ] || die "check-structure.sh not found next to fanout.sh"
  bash "$CS" --root "$ROOT" --json >/dev/null 2>&1; SX=$?
  [ $SX -eq 3 ] && die "check-structure failed on root: $RL"
  if [ $SX -ne 0 ]; then
    MSG="Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
    if [ $JSON -eq 1 ]; then
      printf '{"root":"%s","slug":"%s","gate":"closed","message":"%s","exit":1}\n' "$(jesc "$RL")" "$SLUG" "$(jesc "$MSG")"
    else
      echo "fanout — $RL ($SLUG)"
      echo "1. error structure [structure-gate] $MSG"
      echo "Result: gate closed — FAIL"
    fi
    exit 1
  fi
fi

[ -f "$ROOT/$FROM" ] || die "list not found: $FROM (run scripts/discover $SLUG --pattern ... first, or pass --from PATH)"

# ── Helpers ──────────────────────────────────────────────────────────────────
SEP=$'\001'
trim() { TRIM=$1; TRIM=${TRIM#"${TRIM%%[![:space:]]*}"}; TRIM=${TRIM%"${TRIM##*[![:space:]]}"}; }
cells() { # $1 table row → C[] (escaped pipes restored, cells trimmed)
  local r=$1 k
  r=${r//'\|'/$SEP}   # quoted: an unquoted \\| would match a bare pipe
  trim "$r"; r=$TRIM; r=${r#|}; r=${r%|}
  C=(); IFS='|' read -ra C <<<"$r|"
  for k in "${!C[@]}"; do trim "${C[k]//$SEP/|}"; C[k]=$TRIM; done
}
col_of() { # $1 header row, $2… candidate EREs in order → COL (0-based) or -1
  local hdr=$1 k p; shift
  cells "$hdr"
  COL=-1
  shopt -s nocasematch
  for p in "$@"; do
    for ((k = 0; k < ${#C[@]}; k++)); do
      if [[ ${C[k]} =~ $p ]]; then COL=$k; shopt -u nocasematch; return 0; fi
    done
  done
  shopt -u nocasematch
  return 0
}
slugify() { # $1 text → SLUGV (kebab-case, bounded, never empty)
  local s
  s=$(printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-*//' -e 's/-*$//')
  [ ${#s} -le 48 ] || s=${s:0:48}
  s=${s%-}
  [ -n "$s" ] || s=item
  SLUGV=$s
}
title_of() { # $1 item text → TITLEV (bounded, single line)
  local s=$1
  [ ${#s} -le 60 ] || s="${s:0:57}..."
  TITLEV=$s
}

# ── Read the list ────────────────────────────────────────────────────────────
RE_SEPROW='^[[:space:]]*\|[-|: ]+\|?[[:space:]]*$'
RE_ID='^[A-Za-z]+[0-9]{3}$'
RE_BULLET='^[[:space:]]*([-*+][[:space:]]+|[0-9]+[.)][[:space:]]+)'
RE_FR='FR-[0-9]{3}'
RE_LOCTXT='^([^[:space:]|]+:[0-9]+)[[:space:]]+(.*)$'

L_RAW=()
while IFS= read -r line || [ -n "$line" ]; do L_RAW+=("${line%$'\r'}"); done <"$ROOT/$FROM"

S_ID=() S_ITEM=() S_LOC=() S_REQ=() HAS_TABLE=0
hdr= prev= intbl=0 fence=0
for line in ${L_RAW[@]+"${L_RAW[@]}"}; do
  case "$line" in '```'*|'~~~'*) fence=$((1 - fence)); continue ;; esac
  [ $fence -eq 1 ] && continue
  trim "$line"
  if [ -z "$TRIM" ] || [ "${TRIM:0:1}" != '|' ]; then intbl=0; prev=; continue; fi
  if [ $intbl -eq 0 ]; then
    if [[ $line =~ $RE_SEPROW ]] && [ -n "$prev" ]; then hdr=$prev; intbl=1; prev=; continue; fi
    prev=$line; continue
  fi
  [[ $line =~ $RE_SEPROW ]] && continue
  col_of "$hdr" '^id$'; idc=$COL
  col_of "$hdr" '^task$' '^item$' '^finding$' '^description$' '^summary$'; itc=$COL
  col_of "$hdr" '^location$' '^file$' '^path$'; lcc=$COL
  col_of "$hdr" '^req$' '^requirement$' '^reqs$'; rqc=$COL
  col_of "$hdr" '^priority$' '^prio$'; prc=$COL
  col_of "$hdr" '^status$' '^state$'; stc=$COL
  cells "$line"
  id=; [ $idc -ge 0 ] && id=${C[idc]-}
  if [ $idc -ge 0 ]; then [[ $id =~ $RE_ID ]] || continue; fi
  it=; if [ $itc -ge 0 ]; then it=${C[itc]-}; else for ((k = 0; k < ${#C[@]}; k++)); do [ $k -eq "$idc" ] && continue; [ -n "${C[k]-}" ] && { it=${C[k]}; break; }; done; fi
  [ -n "$it" ] || continue
  HAS_TABLE=1
  st=; [ $stc -ge 0 ] && st=$(printf '%s' "${C[stc]-}" | tr 'A-Z' 'a-z')
  case "$st" in done|dropped|cancelled|canceled|descartado|hecho) continue ;; esac
  pr=; [ $prc -ge 0 ] && pr=${C[prc]-}
  if [ -n "$PRIORITY" ]; then
    shopt -s nocasematch; [[ $pr == "$PRIORITY" ]] || { shopt -u nocasematch; continue; }; shopt -u nocasematch
  fi
  lc=-; [ $lcc -ge 0 ] && [ -n "${C[lcc]-}" ] && lc=${C[lcc]}
  rq=; [ $rqc -ge 0 ] && rq=${C[rqc]-}
  if [ -z "$rq" ] || [ "$rq" = - ]; then
    if [[ $it =~ $RE_FR ]]; then rq=${BASH_REMATCH[0]}; else rq=unmapped; fi
  fi
  [ -n "$id" ] || id=R$(printf '%03d' $((${#S_ID[@]} + 1)))
  if [ -n "$ONLY" ]; then case ",$ONLY," in *",$id,"*) ;; *) continue ;; esac; fi
  S_ID+=("$id"); S_ITEM+=("$it"); S_LOC+=("$lc"); S_REQ+=("$rq")
done

if [ $HAS_TABLE -eq 0 ]; then
  S_ID=() S_ITEM=() S_LOC=() S_REQ=()
  fence=0 n=0
  for line in ${L_RAW[@]+"${L_RAW[@]}"}; do
    case "$line" in '```'*|'~~~'*) fence=$((1 - fence)); continue ;; esac
    [ $fence -eq 1 ] && continue
    [[ $line =~ $RE_BULLET ]] || continue
    it=${line#"${BASH_REMATCH[0]}"}
    while [[ $it =~ $RE_BULLET ]]; do it=${it#"${BASH_REMATCH[0]}"}; done
    trim "$it"; it=$TRIM
    [ -n "$it" ] || continue
    lc=-
    if [[ $it =~ $RE_LOCTXT ]]; then lc=${BASH_REMATCH[1]}; it=${BASH_REMATCH[2]}; fi
    rq=unmapped; [[ $it =~ $RE_FR ]] && rq=${BASH_REMATCH[0]}
    n=$((n + 1)); id=L$(printf '%03d' $n)
    if [ -n "$ONLY" ]; then case ",$ONLY," in *",$id,"*) ;; *) continue ;; esac; fi
    S_ID+=("$id"); S_ITEM+=("$it"); S_LOC+=("$lc"); S_REQ+=("$rq")
  done
fi

TOTAL=${#S_ID[@]}
TRUNC=0
if [ "$TOTAL" -gt "$LIMIT" ]; then TRUNC=1; TOTAL=$LIMIT; fi

if [ "$TOTAL" -eq 0 ]; then
  MSG="no item in $FROM (expected a Markdown table with an Item or Task column, or a numbered list)"
  if [ $JSON -eq 1 ]; then
    printf '{"root":"%s","slug":"%s","from":"%s","briefs":[],"count":0,"message":"%s","exit":1}\n' "$(jesc "$RL")" "$SLUG" "$(jesc "$FROM")" "$(jesc "$MSG")"
  else
    echo "fanout — $RL ($SLUG)"
    echo "Result: 0 brief(s) — $MSG"
  fi
  exit 1
fi

# ── Model tier and runner from the team's capabilities ───────────────────────
CAP=plans/agile/capabilities.md
MODEL_SRC=flag RUNNER=
if [ -z "$MODEL" ] && [ -f "$ROOT/$CAP" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    trim "$line"; [ "${TRIM:0:1}" = '|' ] || continue
    cells "$line"
    k=${C[0]-}; v=${C[1]-}
    [ -n "$v" ] || continue
    # A slot the team answered with none / not applicable is not a model name or a command.
    case "$v" in '<'*) continue ;; esac
    case "$(printf '%s' "$v" | tr 'A-Z' 'a-z')" in none|'not applicable'|'no aplica'|n/a|-) continue ;; esac
    shopt -s nocasematch
    if [[ $k =~ ^model[^A-Za-z0-9]*$TIER$ ]]; then MODEL=$v; MODEL_SRC=capabilities; fi
    if [[ $k =~ ^agent[^A-Za-z0-9]*runner$ ]]; then RUNNER=$v; fi
    shopt -u nocasematch
  done <"$ROOT/$CAP"
fi
[ -n "$MODEL" ] || { MODEL='<model-not-recorded>'; MODEL_SRC=unset; }
RUNNER_SRC=capabilities
if [ -z "$RUNNER" ]; then
  RUNNER_SRC=default
  RUNNER='<agent-cli> --model {{MODEL}} "Execute the brief at {{BRIEF}} exactly as written. Do not touch files outside its allow-list. If a decision is needed, stop and return the question."'
fi

# ── Write the briefs ─────────────────────────────────────────────────────────
SPEC=specs/$SLUG
SPEC_PATH=$SPEC/spec.md
TASKS_PATH=$SPEC/tasks.md
SPEC_MISSING=0; [ -f "$ROOT/$SPEC_PATH" ] || SPEC_MISSING=1

B_ID=() B_FILE=() B_ACT=()
N=0 CREATED=0 SKIPPED=0 UNMAPPED=0
OUTLINES=()
for ((i = 0; i < TOTAL; i++)); do
  did=D$(printf '%03d' $((i + 1)))
  slugify "${S_ITEM[i]}"; fslug=$SLUGV
  rel="$SPEC/dispatch/$did-$fslug.md"
  [ "${S_REQ[i]}" = unmapped ] && UNMAPPED=$((UNMAPPED + 1))
  B_ID+=("$did"); B_FILE+=("$rel")
  N=$((N + 1))
  if [ -e "$ROOT/$rel" ] && [ $FORCE -eq 0 ]; then
    B_ACT+=(skip); SKIPPED=$((SKIPPED + 1))
    OUTLINES+=("$N. skip $rel (exists)")
    continue
  fi
  B_ACT+=(create); CREATED=$((CREATED + 1))
  OUTLINES+=("$N. create $rel (${S_ID[i]}, Req ${S_REQ[i]}, $TIER/$MODEL)")
  [ $DRY -eq 1 ] && continue
  title_of "${S_ITEM[i]}"
  inv=${RUNNER//'{{MODEL}}'/$MODEL}
  inv=${inv//'{{BRIEF}}'/$rel}
  mkdir -p "$ROOT/$SPEC/dispatch"
  while IFS= read -r tl || [ -n "$tl" ]; do
    s=$tl
    s=${s//'{{ID}}'/$did}
    s=${s//'{{TITLE}}'/$TITLEV}
    s=${s//'{{SLUG}}'/$SLUG}
    s=${s//'{{SOURCE_ID}}'/${S_ID[i]}}
    s=${s//'{{SOURCE_FILE}}'/$FROM}
    s=${s//'{{REQ}}'/${S_REQ[i]}}
    s=${s//'{{AUTONOMY}}'/$AUTONOMY}
    s=${s//'{{TIER}}'/$TIER}
    s=${s//'{{MODEL}}'/$MODEL}
    s=${s//'{{ITEM}}'/${S_ITEM[i]}}
    s=${s//'{{LOCATION}}'/${S_LOC[i]}}
    s=${s//'{{SPEC_PATH}}'/$SPEC_PATH}
    s=${s//'{{TASKS_PATH}}'/$TASKS_PATH}
    s=${s//'{{INVOCATION}}'/$inv}
    printf '%s\n' "$s"
  done <"$SKILL/templates/dispatch-task.md" >"$ROOT/$rel"
done

MAN=$SPEC/dispatch.md
N=$((N + 1))
MAN_ACT=create
if [ -e "$ROOT/$MAN" ] && [ $FORCE -eq 0 ]; then MAN_ACT=skip; OUTLINES+=("$N. skip $MAN (exists)")
else OUTLINES+=("$N. create $MAN"); fi
if [ "$MAN_ACT" = create ] && [ $DRY -eq 0 ]; then
  mkdir -p "$ROOT/$SPEC"
  {
    while IFS= read -r tl || [ -n "$tl" ]; do
      s=$tl
      s=${s//'{{SLUG}}'/$SLUG}
      s=${s//'{{SOURCE_FILE}}'/$FROM}
      s=${s//'{{COUNT}}'/$TOTAL}
      s=${s//'{{TIER}}'/$TIER}
      s=${s//'{{MODEL}}'/$MODEL}
      s=${s//'{{AUTONOMY}}'/$AUTONOMY}
      s=${s//'{{TASKS_PATH}}'/$TASKS_PATH}
      if [ "$s" = '{{ROWS}}' ]; then
        for ((i = 0; i < TOTAL; i++)); do
          title_of "${S_ITEM[i]}"
          printf '| [%s](%s) | %s | %s | %s | %s | %s | %s | todo | - |\n' \
            "${B_ID[i]}" "dispatch/${B_FILE[i]##*/}" "${TITLEV//|/\\|}" "${S_ID[i]}" "${S_REQ[i]}" "$TIER" "$MODEL" "$AUTONOMY"
        done
        continue
      fi
      # RUNNER last: its own {{MODEL}} / {{BRIEF}} placeholders must survive into the manifest.
      s=${s//'{{RUNNER}}'/$RUNNER}
      printf '%s\n' "$s"
    done <"$SKILL/templates/dispatch.md"
  } >"$ROOT/$MAN"
fi

# ── Report ───────────────────────────────────────────────────────────────────
if [ $JSON -eq 1 ]; then
  printf '{"root":"%s","slug":"%s","from":"%s","manifest":"%s","tier":"%s","model":"%s","model_source":"%s","autonomy":"%s","briefs":[' \
    "$(jesc "$RL")" "$SLUG" "$(jesc "$FROM")" "$(jesc "$MAN")" "$TIER" "$(jesc "$MODEL")" "$MODEL_SRC" "$AUTONOMY"
  for ((i = 0; i < TOTAL; i++)); do
    [ $i -gt 0 ] && printf ','
    printf '{"id":"%s","source":"%s","req":"%s","file":"%s","action":"%s","item":"%s","location":"%s"}' \
      "${B_ID[i]}" "${S_ID[i]}" "${S_REQ[i]}" "$(jesc "${B_FILE[i]}")" "${B_ACT[i]}" "$(jesc "${S_ITEM[i]}")" "$(jesc "${S_LOC[i]}")"
  done
  if [ $TRUNC -eq 1 ]; then tj=true; else tj=false; fi
  if [ $DRY -eq 1 ]; then dj=true; else dj=false; fi
  printf '],"count":%d,"created":%d,"skipped":%d,"unmapped":%d,"truncated":%s,"dry_run":%s,"exit":0}\n' \
    "$TOTAL" "$CREATED" "$SKIPPED" "$UNMAPPED" "$tj" "$dj"
else
  echo "fanout — $RL ($SLUG)"
  printf '%s\n' ${OUTLINES[@]+"${OUTLINES[@]}"}
  [ $TRUNC -eq 1 ] && echo "Truncated at --limit $LIMIT; the list has more items than this dispatch covers."
  [ $SPEC_MISSING -eq 1 ] && echo "No $SPEC_PATH yet: the briefs point at it, so run 'aa specify $SLUG' and fill Phase 1 before dispatching them."
  [ $UNMAPPED -gt 0 ] && echo "Unmapped: $UNMAPPED brief(s) serve no FR-### — map them in $TASKS_PATH before implementation, or drop them as not-work."
  if [ "$MODEL_SRC" = unset ]; then
    echo "Model for tier $TIER not recorded in $CAP (Slots row 'Model · $TIER'). Relay this to the user:"
    echo "  1. record the model for this tier in $CAP, or re-run with --model <name> (recommended: the smallest model that can pass the acceptance criteria)"
    echo "  2. run the briefs with each agent's default model and no routing"
  fi
  [ "$RUNNER_SRC" = default ] && echo "Runner command not recorded in $CAP (Slots row 'Agent runner'); the briefs carry the generic shape with <agent-cli> to fill in."
  if [ $DRY -eq 1 ]; then echo "Result: $TOTAL brief(s) from $FROM — would create $CREATED, skip $SKIPPED (dry run)"
  else echo "Result: $TOTAL brief(s) from $FROM — created $CREATED, skipped $SKIPPED, manifest $MAN"; fi
fi
exit 0
