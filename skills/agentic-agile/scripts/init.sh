#!/usr/bin/env bash
# init — idempotent scaffold of the agentic-agile workspace inside the current project.
#
# Creates plans/agile/ (team operating system and constitution, from the skill templates;
# --preset NAME overrides them with presets/NAME/<file>.md when present), plans/{sprints,
# initiatives,decisions,drafts}/, plans/agile/metrics/events.jsonl, specs/, the selective
# .memory/.gitignore block and .memory/local/agentic-agile/transcripts/. Never overwrites
# an existing file; never writes outside the project root. PowerShell twin: init.ps1.
#
# --vcs decides whether specs/ and plans/ are versioned. They are the team's shared
# specs and operating system, so the default for a team is to version them; a public
# or solo repository may prefer not to. Trade-off and how to switch later:
# frameworks/artifact-versioning.md. With the default (ask) nothing is written to
# .gitignore: the question is printed for the agent to relay to the user.
#
# Usage: init.sh [--root DIR] [--preset scrum|kanban|regulated] [--vcs versioned|ignored|ask] [--dry-run]
# Exit:  0 ok · 3 configuration error (missing templates, unknown preset, bad root, bad --vcs)
set -u
LC_ALL=C
export LC_ALL

ROOT=.
DRY=0 PRESET=scrum VCS=ask
TEMPLATES="methodology definition-of-ready definition-of-done ceremonies team capabilities kpi-directives language autonomy constitution hooks"
die() { echo "init: $1" >&2; exit 3; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --preset) [ $# -ge 2 ] || die "--preset needs a value"; PRESET=$2; shift 2 ;;
    --vcs) [ $# -ge 2 ] || die "--vcs needs a value"; VCS=$2; shift 2 ;;
    -h|--help)
      echo "Usage: init [--root DIR] [--preset scrum|kanban|regulated] [--vcs versioned|ignored|ask] [--dry-run]"
      echo "  --vcs versioned  specs/ and plans/ are versioned (reviewed in pull requests, kept in history)"
      echo "  --vcs ignored    add specs/ and plans/ to the project .gitignore (they stay on this machine)"
      echo "  --vcs ask        default: print the choice for the user instead of deciding it"
      exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"

SKILL_DIR=$(cd "$(dirname "$0")/.." && pwd)
TPL_DIR="$SKILL_DIR/templates"
PRE_DIR="$SKILL_DIR/presets/$PRESET"
AVAIL=$( { echo scrum; [ -d "$SKILL_DIR/presets" ] && (cd "$SKILL_DIR/presets" && for d in */; do [ -d "$d" ] && echo "${d%/}"; done); } | sort -u | tr '
' ' ')
AVAIL=${AVAIL% }
case " $AVAIL " in *" $PRESET "*) ;; *) die "unknown preset: $PRESET (available: ${AVAIL// /, })" ;; esac
case "$VCS" in versioned|ignored|ask) ;; *) die "unknown --vcs value: $VCS (use versioned, ignored or ask)" ;; esac
src() { if [ -f "$PRE_DIR/$1.md" ]; then printf '%s' "$PRE_DIR/$1.md"; else printf '%s' "$TPL_DIR/$1.md"; fi; }
missing=''
for t in $TEMPLATES; do [ -f "$(src "$t")" ] || missing+=" $t.md"; done
[ -z "$missing" ] || die "missing templates in $TPL_DIR:$missing"

N=0
step() { N=$((N + 1)); if [ $DRY -eq 1 ]; then printf '%d. (dry-run) %s\n' "$N" "$1"; else printf '%d. %s\n' "$N" "$1"; fi; }
ensure_dir() { [ $DRY -eq 1 ] || mkdir -p "$ROOT/$1"; }

for t in $TEMPLATES; do
  f="plans/agile/$t.md"
  if [ -e "$ROOT/$f" ]; then step "skip $f (exists)"
  else
    s=$(src "$t"); note=; [ "$s" = "$TPL_DIR/$t.md" ] || note=" (preset $PRESET)"
    step "create $f$note"; [ $DRY -eq 1 ] || { ensure_dir plans/agile; cp "$s" "$ROOT/$f"; }
  fi
done
for d in plans/sprints plans/initiatives plans/decisions plans/drafts specs; do
  f="$d/.gitkeep"
  if [ -e "$ROOT/$f" ]; then step "skip $f (exists)"
  else step "create $f"; [ $DRY -eq 1 ] || { ensure_dir "$d"; : >"$ROOT/$f"; }; fi
done
f=plans/agile/metrics/events.jsonl
if [ -e "$ROOT/$f" ]; then step "skip $f (exists)"
else step "create $f"; [ $DRY -eq 1 ] || { ensure_dir plans/agile/metrics; : >"$ROOT/$f"; }; fi

BLOCK=$'# Managed by carrilloapps/skills \xe2\x80\x94 ignores agent-private paths only.\n# Shared team state under .memory/<skill>/ stays versioned.\nlocal/\n*.local.*\n*.recovered.json'
f=.memory/.gitignore
add=()
while IFS= read -r l; do
  if [ -f "$ROOT/$f" ] && tr -d '\r' <"$ROOT/$f" | grep -Fxq -- "$l"; then continue; fi
  add+=("$l")
done <<<"$BLOCK"
if [ ${#add[@]} -eq 0 ]; then step "skip $f (block present)"
else
  step "append ${#add[@]} line(s) to $f"
  if [ $DRY -eq 0 ]; then
    ensure_dir .memory
    if [ -s "$ROOT/$f" ] && [ -n "$(tail -c 1 "$ROOT/$f")" ]; then printf '\n' >>"$ROOT/$f"; fi
    printf '%s\n' "${add[@]}" >>"$ROOT/$f"
  fi
fi

if [ "$VCS" = ignored ]; then
  GI_BLOCK=$'# Managed by carrilloapps/skills: agentic-agile artifacts.\n# Versioned by default; this project chose to keep them out of version control.\n# Delete the two path lines below to version the specs and plans again.\nplans/\nspecs/'
  f=.gitignore
  gadd=()
  while IFS= read -r l; do
    if [ -f "$ROOT/$f" ] && tr -d '\r' <"$ROOT/$f" | grep -Fxq -- "$l"; then continue; fi
    gadd+=("$l")
  done <<<"$GI_BLOCK"
  if [ ${#gadd[@]} -eq 0 ]; then step "skip $f (plans/ and specs/ already ignored)"
  else
    step "append ${#gadd[@]} line(s) to $f (specs/ and plans/ not versioned)"
    if [ $DRY -eq 0 ]; then
      if [ -s "$ROOT/$f" ] && [ -n "$(tail -c 1 "$ROOT/$f")" ]; then printf '\n' >>"$ROOT/$f"; fi
      printf '%s\n' "${gadd[@]}" >>"$ROOT/$f"
    fi
  fi
fi

d=.memory/local/agentic-agile/transcripts
if [ -d "$ROOT/$d" ]; then step "skip $d/ (exists)"
else step "create $d/"; ensure_dir "$d"; fi
case "$VCS" in
  versioned) echo "Versioning: specs/ and plans/ are versioned — they will appear in git and in pull requests." ;;
  ignored) echo "Versioning: specs/ and plans/ are ignored by this project — they stay on this machine." ;;
  ask)
    echo "Versioning choice for specs/ and plans/ (nothing written yet — relay this to the user):"
    echo "  1. versioned — the team's specs, plans, decisions and sprint records are reviewed in"
    echo "     pull requests and kept in history. Re-run: init --vcs versioned"
    echo "  2. ignored — they stay on this machine only; no roadmap detail reaches the remote."
    echo "     Re-run: init --vcs ignored"
    echo "  Trade-off and how to switch later: frameworks/artifact-versioning.md" ;;
esac
echo "Next: complete plans/agile/ with the team, then run scripts/check-structure (Phase 0 gate) before any spec, plan, draft, ticket or decision record."
exit 0
