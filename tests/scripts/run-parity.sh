#!/usr/bin/env bash
# run-parity — run every case in cases.tsv with each available implementation (bash, pwsh,
# powershell.exe) and compare stdout, exit code and produced files with expected/.
#
# Usage: tests/scripts/run-parity.sh [--update] [--only bash|pwsh|powershell]
#   --update  regenerate expected/ from the bash implementation (review the diff!)
# Exit: 0 all match · 1 at least one mismatch · 3 usage error
set -u
LC_ALL=C
export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
FIX=$HERE/fixtures EXP=$HERE/expected WORK=$HERE/.work
UPDATE=0 ONLY=
while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1; shift ;;
    --only) ONLY=${2-}; shift 2 ;;
    *) echo "run-parity: unknown option: $1" >&2; exit 3 ;;
  esac
done

RUNNERS=(bash)
command -v pwsh >/dev/null 2>&1 && RUNNERS+=(pwsh)
command -v powershell.exe >/dev/null 2>&1 && RUNNERS+=(powershell)
[ $UPDATE -eq 1 ] && RUNNERS=(bash)
[ -n "$ONLY" ] && RUNNERS=("$ONLY")

native() { # Windows-native path for powershell.exe (Git Bash: cygpath, WSL: wslpath)
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"
  elif [ "$runner" = powershell ] && command -v wslpath >/dev/null 2>&1; then wslpath -w "$1"
  else printf '%s' "$1"; fi
}
script_for() { # $1 impl, $2 runner
  local ext=sh dir=$REPO/skills/agentic-agile/scripts
  [ "$2" = bash ] || ext=ps1
  [ "$1" = lab-probe ] && dir=$REPO/shared/scripts
  printf '%s/%s.%s' "$dir" "$1" "$ext"
}
invoke() { # $1 runner, $2 script, rest = args
  local r=$1 s=$2; shift 2
  case "$r" in
    bash) bash "$s" "$@" </dev/null ;;
    pwsh) pwsh -NoProfile -NonInteractive -File "$(native "$s")" "$@" </dev/null ;;
    powershell) powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(native "$s")" "$@" </dev/null ;;
  esac
}
tree_dump() { (cd "$1" && find . -type f | sort | while IFS= read -r f; do printf '== %s\n' "${f#./}"; tr -d '\r' <"$f"; printf '\n'; done); }

pass=0 fail=0 n=0
for runner in "${RUNNERS[@]}"; do
  while IFS= read -r row; do
    row=${row%$'\r'}   # tolerate CRLF checkouts (Windows core.autocrlf)
    case "$row" in ''|'#'*) continue ;; esac
    IFS=$'\x1f' read -r name mode impl seed args want <<<"${row//$'\t'/$'\x1f'}"
    w=$WORK/$runner/$name
    rm -rf "$w"; mkdir -p "$w"
    script=$(script_for "$impl" "$runner")
    # shellcheck disable=SC2086
    set -- $args
    case "$mode" in
      repo) cwd=$FIX ;;
      transcript) cwd=$w/project; mkdir -p "$cwd/input"; cp "$FIX"/transcripts/* "$cwd/input/" ;;
      init|init2)
        cwd=$w/project; mkdir -p "$cwd" "$w/skill/scripts" "$w/skill/templates"
        cp "$script" "$w/skill/scripts/"; cp "$FIX"/init-templates/*.md "$w/skill/templates/"
        script=$w/skill/scripts/$(basename "$script")
        [ -d "$FIX/aa-preset/presets" ] && cp -R "$FIX/aa-preset/presets" "$w/skill/"
        [ "$seed" = - ] || cp -R "$FIX/$seed/." "$cwd/"
        [ "$mode" = init2 ] && (cd "$cwd" && invoke "$runner" "$script" "$@" >/dev/null 2>&1)
        ;;
      skill) # every script of the runner's kind + fixture templates/presets + trace/analyze stubs
        cwd=$w/project; mkdir -p "$cwd" "$w/skill/scripts" "$w/skill/templates"
        ext=${script##*.}
        cp "$REPO"/skills/agentic-agile/scripts/*."$ext" "$w/skill/scripts/"
        cp "$FIX"/aa-entry/stubs/*."$ext" "$w/skill/scripts/"
        cp "$FIX"/init-templates/*.md "$FIX"/aa-entry/templates/*.md "$w/skill/templates/"
        cp -R "$FIX/aa-preset/presets" "$w/skill/"
        script=$w/skill/scripts/$(basename "$script")
        [ "$seed" = - ] || cp -R "$FIX/$seed/." "$cwd/"
        ;;
    esac
    got_out=$(cd "$cwd" && invoke "$runner" "$script" "$@" 2>/dev/null | tr -d '\r'; exit "${PIPESTATUS[0]}")
    got_exit=$?
    got_tree=
    [ "$mode" = repo ] || got_tree=$(tree_dump "$cwd")
    n=$((n + 1))
    if [ $UPDATE -eq 1 ]; then
      mkdir -p "$EXP"; printf '%s\n' "$got_out" >"$EXP/$name.out"
      if [ -n "$got_tree" ]; then printf '%s\n' "$got_tree" >"$EXP/$name.tree"; else rm -f "$EXP/$name.tree"; fi
      printf '%d. updated %s (exit %s, expected %s)\n' "$n" "$name" "$got_exit" "$want"
      [ "$got_exit" = "$want" ] || fail=$((fail + 1))
      continue
    fi
    why=
    [ "$got_exit" = "$want" ] || why="exit $got_exit, expected $want"
    [ -z "$why" ] && [ "$got_out" != "$(cat "$EXP/$name.out" 2>/dev/null)" ] && why="stdout differs from expected/$name.out"
    if [ -z "$why" ] && [ "$mode" != repo ] && [ "$got_tree" != "$(cat "$EXP/$name.tree" 2>/dev/null)" ]; then why="files differ from expected/$name.tree"; fi
    if [ -z "$why" ]; then pass=$((pass + 1)); printf '%d. pass %s · %s\n' "$n" "$runner" "$name"
    else
      fail=$((fail + 1)); printf '%d. FAIL %s · %s — %s\n' "$n" "$runner" "$name" "$why"
      [ "${PARITY_DIFF-}" = 1 ] && diff <(cat "$EXP/$name.out") <(printf '%s\n' "$got_out") | head -20
    fi
  done <"$HERE/cases.tsv"
done
echo "Runners: ${RUNNERS[*]} · $pass passed · $fail failed"
[ $fail -eq 0 ]
