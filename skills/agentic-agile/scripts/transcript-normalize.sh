#!/usr/bin/env bash
# transcript-normalize — convert a meeting transcript (WebVTT, SRT or "Speaker: text"
# lines) into normalized JSON Lines, redacting personal data and secrets on the way.
#
# Output: one {"speaker","start","end","text","source"} object per cue, then one summary
# object with redaction counts. Default destination:
# .memory/local/agentic-agile/transcripts/<name>.jsonl (agent-private, never versioned).
# Never uses the network; writes only inside the project. PowerShell twin: transcript-normalize.ps1.
#
# Usage: transcript-normalize.sh <file> [--out DIR]   (DIR relative to the project, no "..")
# Exit:  0 ok · 3 configuration error
set -u
LC_ALL=C
export LC_ALL

IN= OUT=.memory/local/agentic-agile/transcripts
die() { echo "transcript-normalize: $1" >&2; exit 3; }
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || die "--out needs a value"; OUT=$2; shift 2 ;;
    -h|--help) echo "Usage: transcript-normalize.sh <file> [--out DIR]"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$IN" ] || die "only one input file is allowed"; IN=$1; shift ;;
  esac
done
[ -n "$IN" ] || die "missing input file"
[ -f "$IN" ] || die "input file not found: $IN"
OUT=${OUT//\\//}
case "$OUT" in /*|[A-Za-z]:*) die "--out must be a path relative to the project" ;; esac
case "/$OUT/" in */../*) die "--out must not contain '..'" ;; esac

SRC=${IN//\\//}; SRC=${SRC##*/}
BASE=${SRC%.*}; [ -n "$BASE" ] || BASE=$SRC

TS='(([0-9]{1,2}):)?([0-9]{1,2}):([0-9]{2})[.,]([0-9]{3})'
RE_TIME="^${TS}[[:space:]]+-->[[:space:]]+${TS}"
RE_VOICE='^<v(\.[^ >]*)?[[:space:]]+([^>]+)>'
RE_TAG='<[^>]*>'
RE_SPEAKER='^([^:<> ]{1,40}( [^:<> ]{1,40}){0,3}):[[:space:]]+(.*)$' # 1-4 words before ':'
SECRET_RES=(
  '([Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd])[ ]*[:=][ ]*[^ ]+'
  '(sk|pk|rk)_(live|test)_[A-Za-z0-9]{8,}'
  'AKIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'eyJ[A-Za-z0-9_-]{10,}[.][A-Za-z0-9_-]{10,}[.][A-Za-z0-9_-]{5,}'
)
RE_EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}'
RE_IBAN='[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}'
RE_CARD='[0-9]([ -]?[0-9]){12,18}'
RE_PHONE='[+]?[0-9][0-9 ().-]{6,}[0-9]'
C_SECRET=0 C_EMAIL=0 C_IBAN=0 C_CARD=0 C_PHONE=0

TEXT=
HITS=0
redact() { # $1 regex, $2 label — rewrites TEXT; HITS = number of replacements
  local re=$1 m
  HITS=0
  while [[ $TEXT =~ $re ]]; do m=${BASH_REMATCH[0]}; TEXT=${TEXT/"$m"/$2}; HITS=$((HITS + 1)); done
}
jesc() {
  local s=$1
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}
  s=$(printf '%s' "$s" | tr -d '\000-\010\013-\037')
  printf '%s' "$s"
}
fmt_ts() { printf '%02d:%02d:%02d.%s' "$((10#${1:-0}))" "$((10#$2))" "$((10#$3))" "$4"; }

CUES=0 BODY=
# JSON Lines record shapes (values are passed as printf arguments, never interpolated into the format)
FMT_CUE='{"speaker":%s,"start":%s,"end":%s,"text":"%s","source":"%s"}'
FMT_SUMMARY='{"summary":{"source":"%s","format":"%s","cues":%d,"redactions":{"secret":%d,"email":%d,"iban":%d,"card":%d,"phone":%d}}}'
emit() { # $1 start, $2 end, $3 raw text
  local speaker='' raw=$3
  if [[ $raw =~ $RE_VOICE ]]; then speaker=${BASH_REMATCH[2]}; fi
  while [[ $raw =~ $RE_TAG ]]; do raw=${raw/"${BASH_REMATCH[0]}"/}; done
  if [ -z "$speaker" ] && [[ $raw =~ $RE_SPEAKER ]]; then speaker=${BASH_REMATCH[1]}; raw=${BASH_REMATCH[3]}; fi
  speaker=$(printf '%s' "$speaker" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  TEXT=$(printf '%s' "$raw" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ -n "$TEXT" ] || return 0
  local r
  for r in "${SECRET_RES[@]}"; do redact "$r" '[REDACTED_SECRET]'; C_SECRET=$((C_SECRET + HITS)); done
  redact "$RE_EMAIL" '[REDACTED_EMAIL]'; C_EMAIL=$((C_EMAIL + HITS))
  redact "$RE_IBAN" '[REDACTED_IBAN]'; C_IBAN=$((C_IBAN + HITS))
  redact "$RE_CARD" '[REDACTED_CARD]'; C_CARD=$((C_CARD + HITS))
  redact "$RE_PHONE" '[REDACTED_PHONE]'; C_PHONE=$((C_PHONE + HITS))
  local js=null je=null jsp=null
  [ -n "$1" ] && js="\"$1\""; [ -n "$2" ] && je="\"$2\""; [ -n "$speaker" ] && jsp="\"$(jesc "$speaker")\""
  BODY+=$(printf "$FMT_CUE" "$jsp" "$js" "$je" "$(jesc "$TEXT")" "$(jesc "$SRC")")$'\n'
  CUES=$((CUES + 1))
}

LINES=()
first=1
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%$'\r'}
  [ $first -eq 1 ] && line=${line#$'\xef\xbb\xbf'} && first=0
  LINES+=("$line")
done <"$IN"

FORMAT=plain
for l in ${LINES[@]+"${LINES[@]}"}; do
  [ -n "$l" ] || continue
  case "$l" in WEBVTT*) FORMAT=vtt ;; esac
  break
done
if [ $FORMAT = plain ]; then for l in ${LINES[@]+"${LINES[@]}"}; do [[ $l =~ $RE_TIME ]] && { FORMAT=srt; break; }; done; fi

if [ $FORMAT = plain ]; then
  for l in ${LINES[@]+"${LINES[@]}"}; do [ -n "$l" ] && emit '' '' "$l"; done
else
  in=0 start='' end='' text=''
  for l in ${LINES[@]+"${LINES[@]}"}; do
    if [[ $l =~ $RE_TIME ]]; then
      [ $in -eq 1 ] && emit "$start" "$end" "$text"
      start=$(fmt_ts "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}")
      end=$(fmt_ts "${BASH_REMATCH[7]}" "${BASH_REMATCH[8]}" "${BASH_REMATCH[9]}" "${BASH_REMATCH[10]}")
      in=1 text=''
    elif [ $in -eq 1 ]; then
      if [ -z "$l" ]; then emit "$start" "$end" "$text"; in=0
      else text+="${text:+ }$l"; fi
    fi
  done
  [ $in -eq 1 ] && emit "$start" "$end" "$text"
fi

TOTAL=$((C_SECRET + C_EMAIL + C_IBAN + C_CARD + C_PHONE))
BODY+=$(printf "$FMT_SUMMARY" "$(jesc "$SRC")" "$FORMAT" "$CUES" "$C_SECRET" "$C_EMAIL" "$C_IBAN" "$C_CARD" "$C_PHONE")$'\n'
mkdir -p "$OUT" || die "cannot create $OUT"
DEST="${OUT%/}/$BASE.jsonl"
printf '%s' "$BODY" >"$DEST"
echo "wrote $DEST ($CUES cue(s), $TOTAL redaction(s))"
exit 0
