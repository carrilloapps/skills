#!/bin/sh
# usage: dd-import.sh "<scan_type>" <results-relative-file> <product> <engagement>
# The API token reaches curl only through the 0600 config written by `bootstrap.sh apply`.
set -eu
RC=/state/curl/dojo-api.rc
[ -f "$RC" ] || { echo "No DefectDojo API config — run: bootstrap.sh apply" >&2; exit 1; }
curl -fsS -K "$RC" -X POST http://sar-dd-nginx:8080/api/v2/import-scan/ \
  -F "scan_type=$1" -F "file=@/state/results/$2" \
  -F "product_name=$3" -F "engagement_name=$4" -F "product_type_name=SAR" \
  -F "auto_create_context=true" -F "active=true" -F "verified=false" \
  -o /dev/null -w "DefectDojo import: HTTP %{http_code}\n"
