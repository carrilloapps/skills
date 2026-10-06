#!/usr/bin/env bash
# lab-probe — read-only capacity probe for the optional Docker labs of carrilloapps/skills.
#
# Detects Docker, Compose v2, RAM, CPUs, free disk and vm.max_map_count, reads the
# lab catalogs of every installed skill, matches them against the project's files and
# suggests the tools that fit, most critical first. If only one fits, it is the most
# critical one. Never uses the network, never installs, never writes files.
#
# Canonical copy: shared/scripts/lab-probe.sh — vendored byte-identical into
# skills/*/scripts/ by shared/sync.sh. PowerShell twin: lab-probe.ps1 (same output).
#
# Usage: lab-probe.sh [--root DIR] [--catalog FILE]... [--budget-ram MB]
#                     [--include-dashboards] [--json]
# Exit:  0 ok · 3 configuration error · 4 Docker unavailable
set -u
LC_ALL=C
export LC_ALL

ROOT=.
JSON=0
BUDGET_RAM=
INCLUDE_DASH=0
FAKE=
CATALOGS=()
RESERVE_RAM=1024
RESERVE_DISK=1024
UNKNOWN_RAM_BUDGET=2048
MAX_DEPTH=6
SKILL_DIRS=".claude/skills .agents/skills .cursor/skills .github/skills .windsurf/skills .devin/skills .kiro/skills .roo/skills .codex/skills .gemini/skills skills"

die() { echo "lab-probe: $1" >&2; exit 3; }
usage() {
  cat <<'EOF'
lab-probe — suggest the Docker lab tools this machine can run, most critical first.

Options:
  1. --root DIR             project root (default: current directory)
  2. --catalog FILE         extra lab-catalog.tsv (repeatable; installed skills are auto-discovered)
  3. --budget-ram MB        RAM budget instead of (available RAM - 1024 MB)
  4. --include-dashboards   also consider dashboards (SonarQube, DefectDojo, PgHero)
  5. --json                 machine-readable output
Exit codes: 0 ok, 3 configuration error, 4 Docker unavailable.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT=$2; shift 2 ;;
    --catalog) [ $# -ge 2 ] || die "--catalog needs a value"; CATALOGS+=("$2"); shift 2 ;;
    --budget-ram) [ $# -ge 2 ] || die "--budget-ram needs a value"; BUDGET_RAM=$2; shift 2 ;;
    --include-dashboards) INCLUDE_DASH=1; shift ;;
    --json) JSON=1; shift ;;
    --fake-resources) [ $# -ge 2 ] || die "--fake-resources needs a value"; FAKE=$2; shift 2 ;; # test hook
    --fake-resources-file) [ $# -ge 2 ] || die "--fake-resources-file needs a value"; [ -f "$2" ] || die "fake resources file not found: $2"; FAKE=$(cat "$2"); shift 2 ;; # test hook
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[ -d "$ROOT" ] || die "project root not found: $ROOT"
if [ -n "$BUDGET_RAM" ] && ! [[ $BUDGET_RAM =~ ^[0-9]+$ ]]; then die "--budget-ram must be an integer (MB)"; fi

is_int() { [[ ${1-} =~ ^[0-9]+$ ]]; }
or_null() { if is_int "${1-}"; then printf '%s' "$1"; else printf 'null'; fi; }
jesc() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; printf '%s' "$s"; }

# ── Resources ────────────────────────────────────────────────────────────────
OS=unknown ARCH=unknown D_CLI=false D_DAEMON=false D_COMPOSE=false D_VERSION=
RAM_TOTAL= RAM_AVAIL= CPUS= DISK_FREE= MMC= DOCKER_WHY=

fake_get() { # flat JSON object → raw value of a key ("" when absent or null)
  local re="\"$1\"[[:space:]]*:[[:space:]]*(\"([^\"]*)\"|[^,}[:space:]]+)"
  if [[ $FAKE =~ $re ]]; then
    if [[ ${BASH_REMATCH[1]} == \"* ]]; then printf '%s' "${BASH_REMATCH[2]}"
    elif [ "${BASH_REMATCH[1]}" != null ]; then printf '%s' "${BASH_REMATCH[1]}"; fi
  fi
}

probe_fake() {
  OS=$(fake_get os); ARCH=$(fake_get arch)
  [ "$(fake_get docker_cli)" = true ] && D_CLI=true
  [ "$(fake_get docker_daemon)" = true ] && D_DAEMON=true
  [ "$(fake_get compose)" = true ] && D_COMPOSE=true
  D_VERSION=$(fake_get docker_version)
  RAM_TOTAL=$(fake_get ram_total_mb); RAM_AVAIL=$(fake_get ram_available_mb)
  CPUS=$(fake_get cpus); DISK_FREE=$(fake_get disk_free_mb); MMC=$(fake_get max_map_count)
  : "${OS:=unknown}" "${ARCH:=unknown}"
}

run_timed() { if command -v timeout >/dev/null 2>&1; then timeout 15 "$@"; else "$@"; fi; }

probe_real() {
  case "$(uname -s 2>/dev/null)" in
    Linux*) OS=linux ;; Darwin*) OS=macos ;; MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  esac
  ARCH=$(uname -m 2>/dev/null || echo unknown)
  case "$ARCH" in x86_64|amd64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
  CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || true)
  if [ -r /proc/meminfo ]; then
    RAM_TOTAL=$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo)
    RAM_AVAIL=$(awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo)
    [ -n "$RAM_AVAIL" ] || RAM_AVAIL=$(awk '/^MemFree:/{print int($2/1024)}' /proc/meminfo)
  elif [ "$OS" = macos ]; then
    RAM_TOTAL=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1048576 ))
    RAM_AVAIL=$(vm_stat 2>/dev/null | awk '/page size of/{ps=$8} /Pages free|Pages inactive|Pages speculative/{gsub(/\./,"",$NF); p+=$NF} END{if(ps) print int(p*ps/1048576)}')
  fi
  DISK_FREE=$(df -Pk "$ROOT" 2>/dev/null | awk 'NR==2{print int($4/1024)}')
  if command -v docker >/dev/null 2>&1; then
    D_CLI=true
    local info
    if info=$(run_timed docker info --format '{{.ServerVersion}}|{{.MemTotal}}|{{.OperatingSystem}}' 2>/dev/null) && [ -n "$info" ]; then
      D_DAEMON=true
      D_VERSION=${info%%|*}
      local rest=${info#*|} mem_mb=${info#*|}
      mem_mb=${mem_mb%%|*}; is_int "$mem_mb" || mem_mb=0
      mem_mb=$(( mem_mb / 1048576 ))
      # Docker Desktop runs containers in a VM: its MemTotal is the real ceiling.
      if [ "$mem_mb" -gt 0 ] && { ! is_int "$RAM_AVAIL" || [ "$mem_mb" -lt "$RAM_AVAIL" ]; }; then RAM_AVAIL=$mem_mb; fi
      case "${rest#*|}" in *"Docker Desktop"*) MMC=desktop ;; esac
    fi
    run_timed docker compose version --short >/dev/null 2>&1 && D_COMPOSE=true
  fi
  # The VM behind Docker Desktop has its own kernel: the host value would be misleading.
  if [ "$MMC" != desktop ] && [ "$OS" = linux ] && [ -r /proc/sys/vm/max_map_count ]; then MMC=$(cat /proc/sys/vm/max_map_count); fi
  [ "$MMC" = desktop ] && MMC=
}

if [ -n "$FAKE" ]; then probe_fake; else probe_real; fi
is_int "$RAM_TOTAL" || RAM_TOTAL=; is_int "$RAM_AVAIL" || RAM_AVAIL=
is_int "$CPUS" || CPUS=; is_int "$DISK_FREE" || DISK_FREE=; is_int "$MMC" || MMC=

if [ "$D_CLI" != true ]; then DOCKER_WHY="docker CLI not found"
elif [ "$D_DAEMON" != true ]; then DOCKER_WHY="Docker daemon not reachable"
elif [ "$D_COMPOSE" != true ]; then DOCKER_WHY="docker compose v2 not available"; fi

if [ -n "$BUDGET_RAM" ]; then BUDGET=$BUDGET_RAM
elif is_int "$RAM_AVAIL"; then BUDGET=$(( RAM_AVAIL > RESERVE_RAM ? RAM_AVAIL - RESERVE_RAM : 0 ))
else BUDGET=$UNKNOWN_RAM_BUDGET; fi
if is_int "$DISK_FREE"; then DISK_BUDGET=$(( DISK_FREE > RESERVE_DISK ? DISK_FREE - RESERVE_DISK : 0 )); else DISK_BUDGET=999999999; fi

# ── Catalogs ─────────────────────────────────────────────────────────────────
for d in $SKILL_DIRS; do
  for f in "$ROOT/$d"/*/frameworks/lab-catalog.tsv; do [ -f "$f" ] && CATALOGS+=("$f"); done
done
[ ${#CATALOGS[@]} -gt 0 ] || die "no lab-catalog.tsv found (install a skill or pass --catalog)"

N=0
T_ID=() T_SKILL=() T_CRIT=() T_RAM=() T_DISK=() T_KIND=() T_PROFILE=() T_COMPOSE=() T_SIGNALS=() T_REQ=() T_NOTES=()
has_id() { local i; for ((i = 0; i < N; i++)); do [ "${T_ID[i]}" = "$1" ] && return 0; done; return 1; }
for cat in "${CATALOGS[@]}"; do
  [ -f "$cat" ] || die "catalog not found: $cat"
  ln=0
  while IFS= read -r line || [ -n "$line" ]; do
    ln=$((ln + 1)); line=${line%$'\r'}
    case "$line" in ''|'#'*|id$'\t'*) continue ;; esac
    tabs=${line//[!$'\t']/}
    [ ${#tabs} -eq 10 ] || die "$cat:$ln: expected 11 tab-separated columns"
    IFS=$'\x1f' read -r id skill crit ram disk kind profile compose signals req notes <<<"${line//$'\t'/$'\x1f'}"
    { is_int "$crit" && is_int "$ram" && is_int "$disk"; } || die "$cat:$ln: criticality, ram_mb and disk_mb must be integers"
    case "$kind" in scanner|dashboard) ;; *) die "$cat:$ln: kind must be scanner or dashboard" ;; esac
    has_id "$id" && continue
    T_ID[N]=$id T_SKILL[N]=$skill T_CRIT[N]=$crit T_RAM[N]=$ram T_DISK[N]=$disk T_KIND[N]=$kind
    T_PROFILE[N]=$profile T_COMPOSE[N]=$compose T_SIGNALS[N]=$signals T_REQ[N]=$req T_NOTES[N]=$notes
    N=$((N + 1))
  done <"$cat"
done

# ── Stack detection ──────────────────────────────────────────────────────────
# Skipped: VCS/dependency dirs, agent-private state, and test data or templates that would
# fake a stack signal (fixtures, testdata, __fixtures__, .work, templates).
FILES=$(cd "$ROOT" && find . -maxdepth $MAX_DEPTH \( -name .git -o -name node_modules -o -name vendor -o -name fixtures -o -name testdata -o -name __fixtures__ -o -name .work -o -name templates -o -path ./.memory/local \) -prune -o -type f -print 2>/dev/null | sed 's#^\./##')

glob_re() { # glob → anchored ERE; same translation as the PowerShell twin
  local g=$1 out='' i c
  for ((i = 0; i < ${#g}; i++)); do
    c=${g:i:1}
    if [ "$c" = '*' ] && [ "${g:i+1:1}" = '*' ]; then
      if [ "${g:i+2:1}" = / ]; then out+='(.*/)?'; i=$((i + 2)); else out+='.*'; i=$((i + 1)); fi
    else
      case "$c" in
        '*') out+='[^/]*' ;; '?') out+='[^/]' ;; .|+|'('|')'|'$') out+="[$c]" ;; *) out+=$c ;;
      esac
    fi
  done
  printf '^%s$' "$out"
}

# .labprobeignore at the project root: one glob or directory per line (# comments); a match
# excludes the path and everything under it.
if [ -f "$ROOT/.labprobeignore" ]; then
  IGN=''
  while IFS= read -r g || [ -n "$g" ]; do
    g=${g%$'\r'}; g=${g#./}; g=${g%/}
    case "$g" in ''|'#'*) continue ;; esac
    r=$(glob_re "$g"); r=${r#^}; r=${r%\$}
    IGN+="${IGN:+|}$r"
  done <"$ROOT/.labprobeignore"
  [ -n "$IGN" ] && FILES=$(printf '%s\n' "$FILES" | grep -Ev "^($IGN)(/.*)?$")
fi
BASES=$(printf '%s\n' "$FILES" | sed 's#.*/##')

applicable() { # $1 = comma-separated globs
  [ "$1" = '*' ] && return 0
  local base_re='' path_re='' g
  local IFS=,
  for g in $1; do
    [ -n "$g" ] || continue
    if [[ $g == */* ]]; then path_re+="${path_re:+|}$(glob_re "$g")"; else base_re+="${base_re:+|}$(glob_re "$g")"; fi
  done
  { [ -n "$base_re" ] && printf '%s\n' "$BASES" | grep -Eq "$base_re"; } && return 0
  { [ -n "$path_re" ] && printf '%s\n' "$FILES" | grep -Eq "$path_re"; } && return 0
  return 1
}

REQ_RE='^([a-z_]+)>=([0-9]+)$'
req_fail() { # prints the reason when a requirement is not met
  local r key min val IFS=';'
  for r in $1; do
    [ -n "$r" ] || continue
    [[ $r =~ $REQ_RE ]] || { echo "invalid requirement: $r"; return 0; }
    key=${BASH_REMATCH[1]} min=${BASH_REMATCH[2]}
    case "$key" in max_map_count) val=$MMC ;; cpus) val=$CPUS ;; ram_total_mb) val=$RAM_TOTAL ;; *) val= ;; esac
    if ! is_int "$val"; then echo "requires $key>=$min (unknown on this machine)"; return 0; fi
    [ "$val" -ge "$min" ] || { echo "requires $key>=$min (current $val)"; return 0; }
  done
  return 1
}

# ── Selection ────────────────────────────────────────────────────────────────
ORDER=()
while IFS= read -r k; do [ -n "$k" ] && ORDER+=("${k##*|}"); done < <(
  for ((i = 0; i < N; i++)); do printf '%03d|%07d|%s|%d\n' $((999 - T_CRIT[i])) "${T_RAM[i]}" "${T_ID[i]}" "$i"; done | sort
)

SEL=() REASON=() USED=0 DUSED=0
fits() { # $1 index → empty when it fits, else the reason
  local i=$1
  if [ $((USED + T_RAM[i])) -gt "$BUDGET" ]; then echo "exceeds RAM budget (needs ${T_RAM[i]} MB, $((BUDGET - USED)) MB left)"
  elif [ $((DUSED + T_DISK[i])) -gt "$DISK_BUDGET" ]; then echo "exceeds free disk (needs ${T_DISK[i]} MB, $((DISK_BUDGET - DUSED)) MB left)"; fi
}
take() { SEL+=("$1"); USED=$((USED + T_RAM[$1])); DUSED=$((DUSED + T_DISK[$1])); }

DASH=()
for i in ${ORDER[@]+"${ORDER[@]}"}; do
  if ! applicable "${T_SIGNALS[i]}"; then REASON[i]="no matching files in the project"
  elif why=$(req_fail "${T_REQ[i]}"); then REASON[i]=$why
  elif [ -n "$DOCKER_WHY" ]; then REASON[i]="Docker unavailable: $DOCKER_WHY${T_NOTES[i]:+ — ${T_NOTES[i]}}"
  elif [ "${T_KIND[i]}" = dashboard ]; then DASH+=("$i")
  elif why=$(fits "$i") && [ -n "$why" ]; then REASON[i]=$why
  else take "$i"; fi
done
for i in ${DASH[@]+"${DASH[@]}"}; do
  if [ $INCLUDE_DASH -eq 0 ]; then REASON[i]="dashboard: add --include-dashboards to consider it (~${T_RAM[i]} MB)"
  elif why=$(fits "$i") && [ -n "$why" ]; then REASON[i]=$why
  else take "$i"; fi
done

run_cmd() {
  local i=$1
  if [ "${T_KIND[i]}" = dashboard ]; then printf 'docker compose -f %s --profile %s up -d' "${T_COMPOSE[i]}" "${T_PROFILE[i]}"
  else printf 'docker compose -f %s --profile %s run --rm %s' "${T_COMPOSE[i]}" "${T_PROFILE[i]}" "${T_ID[i]}"; fi
}
letter() { local n=$1 s=''; while :; do s=$(printf "\\$(printf '%03o' $((97 + n % 26)))")$s; n=$((n / 26 - 1)); [ $n -lt 0 ] && break; done; printf '%s' "$s"; }

EXIT=0; [ -n "$DOCKER_WHY" ] && EXIT=4

if [ $JSON -eq 1 ]; then
  out="{\"os\":\"$(jesc "$OS")\",\"arch\":\"$(jesc "$ARCH")\",\"docker\":{\"cli\":$D_CLI,\"daemon\":$D_DAEMON,\"compose\":$D_COMPOSE,\"version\":"
  if [ -n "$D_VERSION" ]; then out+="\"$(jesc "$D_VERSION")\""; else out+=null; fi
  out+=",\"unavailable_reason\":"; if [ -n "$DOCKER_WHY" ]; then out+="\"$DOCKER_WHY\""; else out+=null; fi
  out+="},\"resources\":{\"ram_total_mb\":$(or_null "$RAM_TOTAL"),\"ram_available_mb\":$(or_null "$RAM_AVAIL"),\"ram_budget_mb\":$BUDGET,\"cpus\":$(or_null "$CPUS"),\"disk_free_mb\":$(or_null "$DISK_FREE"),\"max_map_count\":$(or_null "$MMC")},\"selected\":["
  r=0
  for i in ${SEL[@]+"${SEL[@]}"}; do
    r=$((r + 1)); [ $r -gt 1 ] && out+=,
    out+="{\"rank\":$r,\"id\":\"$(jesc "${T_ID[i]}")\",\"skill\":\"$(jesc "${T_SKILL[i]}")\",\"criticality\":${T_CRIT[i]},\"ram_mb\":${T_RAM[i]},\"disk_mb\":${T_DISK[i]},\"kind\":\"${T_KIND[i]}\",\"profile\":\"$(jesc "${T_PROFILE[i]}")\",\"compose\":\"$(jesc "${T_COMPOSE[i]}")\",\"run\":\"$(jesc "$(run_cmd "$i")")\",\"notes\":\"$(jesc "${T_NOTES[i]}")\"}"
  done
  out+="],\"skipped\":["
  s=0
  for i in ${ORDER[@]+"${ORDER[@]}"}; do
    [ -n "${REASON[i]-}" ] || continue
    [ $s -gt 0 ] && out+=,
    out+="{\"label\":\"$(letter $s)\",\"id\":\"$(jesc "${T_ID[i]}")\",\"skill\":\"$(jesc "${T_SKILL[i]}")\",\"reason\":\"$(jesc "${REASON[i]}")\"}"
    s=$((s + 1))
  done
  out+="],\"exit\":$EXIT}"
  printf '%s\n' "$out"
else
  printf 'Lab probe — %s/%s · Docker: %s\n' "$OS" "$ARCH" "${DOCKER_WHY:-${D_VERSION:-available}}"
  printf 'Resources: RAM available %s MB (budget %s MB) · CPUs %s · disk free %s MB · vm.max_map_count %s\n' \
    "${RAM_AVAIL:-unknown}" "$BUDGET" "${CPUS:-unknown}" "${DISK_FREE:-unknown}" "${MMC:-unknown}"
  echo
  if [ ${#SEL[@]} -eq 0 ]; then echo 'Suggested: none fits right now.'
  else
    echo 'Suggested, most critical first (approve each run individually):'
    r=0
    for i in ${SEL[@]+"${SEL[@]}"}; do
      r=$((r + 1))
      printf '%d. %s (%s) — criticality %s, ~%s MB — run: %s\n' "$r" "${T_ID[i]}" "${T_SKILL[i]}" "${T_CRIT[i]}" "${T_RAM[i]}" "$(run_cmd "$i")"
      [ -n "${T_NOTES[i]}" ] && printf '   note: %s\n' "${T_NOTES[i]}"
    done
  fi
  s=0
  for i in ${ORDER[@]+"${ORDER[@]}"}; do
    [ -n "${REASON[i]-}" ] || continue
    [ $s -eq 0 ] && { echo; echo 'Skipped:'; }
    printf '%s. %s (%s) — %s\n' "$(letter $s)" "${T_ID[i]}" "${T_SKILL[i]}" "${REASON[i]}"
    s=$((s + 1))
  done
fi
exit $EXIT
