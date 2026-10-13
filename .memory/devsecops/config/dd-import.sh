#!/bin/sh
# usage: dd-import.sh "<scan_type>" <file-relative-to-results> <product> <engagement>
# The API token reaches curl only through the 0600 config written by `bootstrap.sh apply`.
set -eu
RC=/state/curl/dojo-api.rc
[ -f "$RC" ] || { echo "No DefectDojo API config — run: bootstrap.sh apply" >&2; exit 1; }
# $2 is operator input: reject absolute paths and traversal, resolve the folder physically,
# then require a regular (non-symlink) file still under $RESULTS before anything is posted.
RESULTS=/state/results
case "${2:-}" in ""|/*|..|../*|*/..|*/../*) echo "dd-import: give a path relative to results/, without '..'" >&2; exit 2 ;; esac
BASE=$(cd "$RESULTS" && pwd -P) || exit 2
DIR=$(cd "$RESULTS/$(dirname "$2")" && pwd -P) || exit 2
FILE="$DIR/$(basename "$2")"
case "$DIR" in "$BASE"|"$BASE"/*) ;; *) echo "dd-import: resolved path escapes $RESULTS: $2" >&2; exit 2 ;; esac
[ -f "$FILE" ] && [ ! -L "$FILE" ] || { echo "dd-import: not a regular file under results/: $2" >&2; exit 2; }
curl -fsS -K "$RC" -X POST http://sar-dd-nginx:8080/api/v2/import-scan/ \
  -F "scan_type=$1" -F "file=@$FILE" \
  -F "product_name=$3" -F "engagement_name=$4" -F "product_type_name=SAR" \
  -F "auto_create_context=true" -F "active=true" -F "verified=false" \
  -o /dev/null -w "DefectDojo import: HTTP %{http_code}\n"
