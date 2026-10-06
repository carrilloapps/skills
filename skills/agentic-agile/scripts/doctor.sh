#!/usr/bin/env bash
# doctor — one-screen health of an agentic-agile project (read-only, no network).
#
# Aggregates: the Phase 0 gate and scorecard (check-structure --scorecard), hygiene findings
# (audit-agile), Docker lab availability (lab-probe with this skill's catalog plus any installed
# skill catalogs), and capability slots marked "none"; then suggests the next actions.
# PowerShell twin: doctor.ps1 (same output).
#
# Usage: doctor.sh [--root DIR] [--json] [--today YYYY-MM-DD] [--templates DIR]
#        (--fake-resources-file FILE is passed to lab-probe for the parity tests only)
# Exit:  0 healthy (gate open, no hygiene findings) · 1 attention · 3 configuration error
set -u
LC_ALL=C
export LC_ALL

ROOT=. JSON=0 TODAY= FAKE= TPL=
die() { echo "doctor: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --today) [ $# -ge 2 ] || die "--today needs a value"; TODAY=$2; shift 2 ;;
    --templates) [ $# -ge 2 ] || die "--templates needs a value"; TPL=$2; shift 2 ;;
    --fake-resources-file) [ $# -ge 2 ] || die "--fake-resources-file needs a value"; FAKE=$2; shift 2 ;;
    --json) JSON=1; shift ;;
    -h|--help) echo "Usage: doctor [--root DIR] [--json] [--today YYYY-MM-DD] [--templates DIR]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"
CS="$(cd "$(dirname "$0")" && pwd)/check-structure.sh"
AS="$(cd "$(dirname "$0")" && pwd)/audit-agile.sh"
LP="$(cd "$(dirname "$0")" && pwd)/lab-probe.sh"
CAT="$(cd "$(dirname "$0")" && pwd)/../frameworks/lab-catalog.tsv"
LABEL=${ROOT//\\//}
while [ "${LABEL%/}" != "$LABEL" ] && [ "$LABEL" != / ]; do LABEL=${LABEL%/}; done
field() { printf '%s' "$1" | sed -n "s/.*\"$2\":\\([^,}]*\\).*/\\1/p" | head -n 1; }
sfield() { printf '%s' "$1" | sed -n "s/.*\"$2\":\"\\([^\"]*\\)\".*/\\1/p" | head -n 1; }

# ── Collect ──────────────────────────────────────────────────────────────────
SJ=$(bash "$CS" --root "$ROOT" --scorecard --json 2>/dev/null); SX=$?
[ $SX -eq 3 ] && die "check-structure failed on root: $ROOT"
GATE=$(sfield "$SJ" gate); SE=$(field "$SJ" errors); SW=$(field "$SJ" warnings)
PCT=$(field "$SJ" percent); SUM=$(field "$SJ" score)
AREAS=(process capabilities autonomy metrics transcripts) LV=()
for a in "${AREAS[@]}"; do LV+=("$(field "$SJ" "$a")"); done
GAPS=()
graw=$(printf '%s' "$SJ" | sed -n 's/.*"gaps":\[\([^]]*\)\].*/\1/p')
if [ -n "$graw" ]; then
  while IFS= read -r g; do [ -n "$g" ] && GAPS+=("$g"); done < <(printf '%s\n' "$graw" | sed 's/^"//; s/"$//; s/","/\n/g')
fi

AA=(--root "$ROOT" --json); [ -n "$TODAY" ] && AA+=(--today "$TODAY"); [ -n "$TPL" ] && AA+=(--templates "$TPL")
AJ=$(bash "$AS" "${AA[@]}" 2>/dev/null); AX=$?
[ $AX -eq 3 ] && die "audit-agile failed on root: $ROOT"
AN=$(field "$AJ" count)

LA=(--root "$ROOT" --json --catalog "$CAT"); [ -n "$FAKE" ] && LA+=(--fake-resources-file "$FAKE")
LJ=$(bash "$LP" "${LA[@]}" 2>/dev/null); LX=$?
if [ $LX -eq 3 ] || [ -z "$LJ" ]; then DOCK=unknown; DDET="lab-probe configuration error"
else
  # Read only the "docker":{...} object: "compose" also appears in every selected tool entry.
  DJ=$(printf '%s' "$LJ" | sed -n 's/^[^{]*{[^{]*"docker":{\([^}]*\)}.*/\1/p')
  if [ "$(field "$DJ" daemon)" = true ] && [ "$(field "$DJ" compose)" = true ]; then DOCK=yes; DDET="Docker $(sfield "$DJ" version)"
  else DOCK=no; DDET=$(sfield "$DJ" unavailable_reason); [ -n "$DDET" ] || DDET="Docker not available"; fi
fi

# ── Next actions ─────────────────────────────────────────────────────────────
ACT=()
[ "$GATE" = open ] || ACT+=("Complete plans/agile/ with the team: run scripts/check-structure --root $LABEL")
low=; for ((i = 0; i < ${#AREAS[@]}; i++)); do [ "${LV[i]}" -lt 3 ] && low+="${low:+, }${AREAS[i]}"; done
[ -n "$low" ] && ACT+=("Fill and confirm the plans/agile/ files of: $low (target L3)")
[ "${AN:-0}" -gt 0 ] && ACT+=("Fix the hygiene findings: run scripts/audit-agile --root $LABEL")
[ "$DOCK" = yes ] || ACT+=("Docker lab unavailable ($DDET): start Docker or use the CLI routes in frameworks/capabilities.md")
gl=; for g in ${GAPS[@]+"${GAPS[@]}"}; do gl+="${gl:+, }$g"; done
[ -n "$gl" ] && ACT+=("Decide a tool or 'not applicable' for the capability slots marked none: $gl")
EXIT=0; { [ "$GATE" = open ] && [ "${AN:-0}" -eq 0 ]; } || EXIT=1

# ── Report ───────────────────────────────────────────────────────────────────
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; s=$(printf '%s' "$s" | tr -d '\000-\010\013-\037'); printf '%s' "$s"; }
if [ $JSON -eq 1 ]; then
  sc=$(printf '%s' "$SJ" | sed -n 's/.*"scorecard":\({[^}]*}\).*/\1/p')
  if [ "$DOCK" = yes ]; then dv=true; else dv=false; fi
  out="{\"root\":\"$(jesc "$LABEL")\",\"gate\":\"$GATE\",\"structure\":{\"errors\":$SE,\"warnings\":$SW},\"scorecard\":$sc,\"hygiene_findings\":${AN:-0},\"docker\":{\"available\":$dv,\"detail\":\"$(jesc "$DDET")\"},\"gaps\":["
  for ((i = 0; i < ${#GAPS[@]}; i++)); do [ $i -gt 0 ] && out+=,; out+="\"$(jesc "${GAPS[i]}")\""; done
  out+="],\"actions\":["
  for ((i = 0; i < ${#ACT[@]}; i++)); do [ $i -gt 0 ] && out+=,; out+="\"$(jesc "${ACT[i]}")\""; done
  printf '%s\n' "$out],\"exit\":$EXIT}"
else
  echo "doctor — $LABEL"
  echo "1. Phase 0 gate: $GATE ($SE error(s), $SW warning(s))"
  lv=; for ((i = 0; i < ${#AREAS[@]}; i++)); do lv+="${lv:+, }${AREAS[i]} L${LV[i]}"; done
  echo "2. Readiness: $PCT% ($SUM/20) — $lv"
  echo "3. Hygiene (audit-agile): ${AN:-0} finding(s)"
  if [ "$DOCK" = yes ]; then echo "4. Docker lab: available ($DDET)"; else echo "4. Docker lab: unavailable — $DDET"; fi
  echo "5. Capability gaps: ${gl:-none}"
  echo "Next actions:"
  L=(a b c d e f g h)
  if [ ${#ACT[@]} -eq 0 ]; then echo "a. No action needed."; fi
  for ((i = 0; i < ${#ACT[@]}; i++)); do echo "${L[i]}. ${ACT[i]}"; done
  if [ $EXIT -eq 0 ]; then echo "Result: HEALTHY"; else echo "Result: ATTENTION"; fi
fi
exit $EXIT
