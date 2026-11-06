#!/usr/bin/env bash
# Re-run the completion-plan unauthenticated attack sequence against a running API.
# Expects every step to fail closed (401). Exits 1 if any step is still open.
set -euo pipefail
BASE="${1:-http://127.0.0.1:8081}"
FAIL=0

check() {
  local name="$1" expected="$2" method="$3" path="$4"
  shift 4
  local code
  code="$(curl -sS -o /tmp/atw-audit-body.json -w "%{http_code}" -X "$method" "$BASE$path" \
    -H "Content-Type: application/json" "$@" || true)"
  echo "→ $name"
  echo "  $method $path → $code (want $expected)"
  python3 - <<PY || true
import json
try:
    body=json.load(open("/tmp/atw-audit-body.json"))
    print(" ", body)
except Exception:
    print(" ", open("/tmp/atw-audit-body.json").read()[:300])
PY
  if [[ "$code" != "$expected" ]]; then
    echo "  FAIL"
    FAIL=1
  else
    echo "  OK"
  fi
  echo
}

echo "Unauthenticated attack sequence against $BASE"
echo

check "1. create account with only email+name" "401" POST "/api/v1/users" \
  -d '{"email":"attacker@example.com","displayName":"Attacker"}'

check "2. dump every user (emails)" "401" GET "/api/v1/users"

check "3. dump every profile" "401" GET "/api/v1/profiles"

check "4. create a game as someone else" "401" POST "/api/v1/games" \
  -d '{"hostUserId":"00000000-0000-0000-0000-000000000001","title":"Stolen","venue":"Franklin Square Park","neighborhood":"San Francisco, San Francisco","skill":"Casual","format":"5v5","capacity":10,"priceCents":0,"notes":"","startsAt":"2026-12-01T19:00:00Z","latitude":37.7644,"longitude":-122.4102}'

check "5. delete a game with no credentials" "401" DELETE "/api/v1/games/00000000-0000-0000-0000-000000000001"

check "6. delete a user with no credentials" "401" DELETE "/api/v1/users/00000000-0000-0000-0000-000000000001"

check "7. read someone else's schedule by id" "401" GET "/api/v1/games/mine?userId=00000000-0000-0000-0000-000000000001"
check "8. read someone else's profile by id" "401" GET "/api/v1/profiles/user/00000000-0000-0000-0000-000000000001"
check "9. read someone else's friend list by id" "401" GET "/api/v1/friendships/user/00000000-0000-0000-0000-000000000001"

echo "→ 10. CORS: unknown website origin must not be reflected"
CORS="$(curl -sS -D - -o /dev/null -H "Origin: https://evil.example" "$BASE/health" | tr -d '\r' | awk -F': ' 'tolower($1)=="access-control-allow-origin"{print $2}')"
echo "  Access-Control-Allow-Origin: ${CORS:-<none>}"
if [[ "$CORS" == "*" || "$CORS" == "https://evil.example" ]]; then
  echo "  FAIL"
  FAIL=1
else
  echo "  OK"
fi
echo

if [[ "$FAIL" -ne 0 ]]; then
  echo "Attack surface still open."
  exit 1
fi
echo "All unauthenticated attacks failed closed."
