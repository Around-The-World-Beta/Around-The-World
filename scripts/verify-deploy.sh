#!/usr/bin/env bash
# Prove a hosted API is up, locked down, and not seeded as production.
# Usage: ./scripts/verify-deploy.sh https://YOUR-SERVICE.up.railway.app
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 https://YOUR-SERVICE.up.railway.app"
  echo "Do not include a trailing slash."
  exit 2
fi

BASE="${1%/}"
FAIL=0

echo "Checking $BASE"
echo

echo "→ GET /health"
HEALTH_CODE="$(curl -sS -o /tmp/atw-health.json -w "%{http_code}" "$BASE/health" || true)"
echo "  HTTP $HEALTH_CODE"
python3 - <<'PY'
import json, sys
body = json.load(open("/tmp/atw-health.json"))
print(" ", body)
if body.get("status") != "ok" or body.get("service") != "around-the-world-api" or body.get("database") != "ok":
    sys.exit(1)
PY
if [[ "$HEALTH_CODE" != "200" ]]; then
  echo "  FAIL — health must be HTTP 200 with status=ok"
  FAIL=1
else
  echo "  OK"
fi
echo

echo "→ GET /api/v1/meta/bay-area (public)"
META_CODE="$(curl -sS -o /tmp/atw-meta.json -w "%{http_code}" "$BASE/api/v1/meta/bay-area" || true)"
echo "  HTTP $META_CODE"
python3 - <<'PY'
import json, sys
body = json.load(open("/tmp/atw-meta.json"))
counties = body.get("counties") or []
print(f"  counties: {len(counties)}")
if len(counties) != 9:
    sys.exit(1)
PY
if [[ "$META_CODE" != "200" ]]; then
  echo "  FAIL"
  FAIL=1
else
  echo "  OK"
fi
echo

echo "→ GET /api/v1/games (public browse; production may be an empty list)"
GAMES_CODE="$(curl -sS -o /tmp/atw-games.json -w "%{http_code}" "$BASE/api/v1/games" || true)"
echo "  HTTP $GAMES_CODE"
python3 - <<'PY'
import json
body = json.load(open("/tmp/atw-games.json"))
print(f"  open games: {len(body) if isinstance(body, list) else 'not a list'}")
PY
if [[ "$GAMES_CODE" != "200" ]]; then
  echo "  FAIL — browse must stay public"
  FAIL=1
else
  echo "  OK"
fi
echo

echo "→ unauthenticated writes must still be 401 (W1 lock-down)"
ROOT="$(cd "$(dirname "$0")" && pwd)"
if ! "$ROOT/audit-unauthenticated.sh" "$BASE"; then
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "Deploy check failed."
  exit 1
fi

echo "Deploy looks good."
echo "The iPhone still cannot sign in until Workstream 2 (Sign in with Apple)."
