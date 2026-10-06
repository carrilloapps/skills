#!/bin/sh
# sar-bootstrap — generates (init) and applies (apply) ONE local dashboard credential.
# Never prints secrets. Secrets reach curl only through 0600 config files read with -K
# (never argv, never a pipe). Output files are owned by the owner of the mounted folder.
set -eu
STATE=/state; CRED="$STATE/credentials.env"; TOK="$STATE/tokens.env"; ENV="$STATE/env"; RC="$STATE/curl"
SONAR=http://sar-sonarqube:9000; DOJO=http://sar-dd-nginx:8080
umask 077

rand() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"; }
val() { sed -n "s/^$1=//p" "$2" 2>/dev/null | head -n 1; }
strong() {  # SonarQube rule (strictest): >= 12 chars with upper, lower, digit, special
  [ "${#1}" -ge 12 ] && printf '%s' "$1" | grep -q '[A-Z]' && printf '%s' "$1" | grep -q '[a-z]' \
    && printf '%s' "$1" | grep -q '[0-9]' && printf '%s' "$1" | grep -q '[^A-Za-z0-9]'
}
own() { chown "$(stat -c %u:%g "$STATE")" "$@"; }
put() { grep -q "^$1=" "$2" 2>/dev/null || printf '%s=%s\n' "$1" "$3" >>"$2"; }
q() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }   # escape for a curl config value

init() {
  touch "$CRED"
  P=$(val DASHBOARD_PASSWORD "$CRED")
  if [ -z "$P" ]; then P="$(rand 16)Aa1-"; put DASHBOARD_PASSWORD "$CRED" "$P"; fi
  strong "$P" || { echo "DASHBOARD_PASSWORD in credentials.env is too weak (>= 12 chars, upper, lower, digit, special)." >&2; exit 1; }
  DB=$(val POSTGRES_PASSWORD "$CRED"); [ -n "$DB" ] || DB=$(rand 32)
  put DASHBOARD_USER "$CRED" admin
  put POSTGRES_PASSWORD "$CRED" "$DB"
  put SONAR_JDBC_PASSWORD "$CRED" "$DB"
  put DD_ADMIN_USER "$CRED" admin
  put DD_ADMIN_PASSWORD "$CRED" "$P"
  put DD_DATABASE_URL "$CRED" "postgresql://defectdojo:$DB@sar-dd-postgres:5432/defectdojo"
  put DD_SECRET_KEY "$CRED" "$(rand 50)"
  put DD_CREDENTIAL_AES_256_KEY "$CRED" "$(rand 32)"
  derive
  touch "$TOK"; own "$CRED" "$TOK"
  echo "Credential ready: .memory/local/devsecops/credentials.env (user: admin). Same password for every dashboard."
}

# One env file per container, holding only the keys it needs (re-derived on every init),
# plus the curl config files apply/dd-import use.
envf() { f="$ENV/$1"; shift; : >"$f"; for k in "$@"; do printf '%s=%s\n' "${k#*:}" "$(val "${k%%:*}" "$CRED")" >>"$f"; done; own "$f"; }
derive() {
  mkdir -p "$ENV" "$RC"; own "$ENV" "$RC"
  envf sonarqube-db.env POSTGRES_PASSWORD
  envf sonarqube.env SONAR_JDBC_PASSWORD
  envf defectdojo-db.env POSTGRES_PASSWORD
  envf defectdojo.env DD_DATABASE_URL DD_SECRET_KEY DD_CREDENTIAL_AES_256_KEY
  envf defectdojo-admin.env DD_ADMIN_USER DD_ADMIN_PASSWORD
  [ -f "$ENV/sonar-scanner.env" ] || { : >"$ENV/sonar-scanner.env"; own "$ENV/sonar-scanner.env"; }   # filled by apply
  W=$(q "$(val DASHBOARD_PASSWORD "$CRED")")
  printf 'user = "admin:%s"\n' "$W" >"$RC/sonar-admin.rc"
  # SonarQube's documented first-boot login is admin/admin; this config replaces it with the shared password.
  printf 'user = "admin:admin"\ndata-urlencode = "login=admin"\ndata-urlencode = "previousPassword=admin"\ndata-urlencode = "password=%s"\n' "$W" >"$RC/sonar-first-login.rc"
  printf 'data-urlencode = "username=admin"\ndata-urlencode = "password=%s"\n' "$W" >"$RC/dojo-login.rc"
  own "$RC"/*.rc
}

reachable() { curl -s -o /dev/null --max-time 3 "$1"; }
wait_up() { i=0; until curl -fs "$SONAR/api/system/status" | grep -q '"status":"UP"'; do
  i=$((i+1)); [ "$i" -lt 120 ] || { echo "SonarQube not UP after 10 min" >&2; return 1; }; sleep 5; done; }
token() { sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }

apply() {
  [ -f "$RC/sonar-admin.rc" ] || { echo "Run init first." >&2; exit 1; }
  if reachable "$SONAR"; then
    wait_up
    if ! curl -fs -K "$RC/sonar-admin.rc" "$SONAR/api/authentication/validate" | grep -q '"valid":true'; then
      curl -fs -K "$RC/sonar-first-login.rc" -X POST "$SONAR/api/users/change_password" >/dev/null
    fi
    if [ -z "$(val SONAR_TOKEN "$TOK")" ]; then
      put SONAR_TOKEN "$TOK" "$(curl -fs -K "$RC/sonar-admin.rc" -X POST "$SONAR/api/user_tokens/generate" \
          --data-urlencode name=sar-scanner --data-urlencode type=GLOBAL_ANALYSIS_TOKEN | token)"
    fi
    mkdir -p "$ENV"; printf 'SONAR_TOKEN=%s\n' "$(val SONAR_TOKEN "$TOK")" >"$ENV/sonar-scanner.env"; own "$ENV" "$ENV/sonar-scanner.env"
    echo "SonarQube: http://127.0.0.1:9000 — password applied, scanner token stored."
  fi
  if reachable "$DOJO" && [ -z "$(val DD_API_TOKEN "$TOK")" ]; then
    put DD_API_TOKEN "$TOK" "$(curl -fs -K "$RC/dojo-login.rc" -X POST "$DOJO/api/v2/api-token-auth/" | token)"
    echo "DefectDojo: http://127.0.0.1:8080 — API token stored."
  fi
  if [ -n "$(val DD_API_TOKEN "$TOK")" ]; then
    printf 'header = "Authorization: Token %s"\n' "$(q "$(val DD_API_TOKEN "$TOK")")" >"$RC/dojo-api.rc"; own "$RC/dojo-api.rc"
  fi
  own "$TOK"
}

case "${1:-init}" in init) init ;; apply) apply ;; *) echo "usage: bootstrap.sh init|apply" >&2; exit 2 ;; esac
