#!/usr/bin/env bash
# End-to-end API smoke for Bay Area beta (run while backend is up).
set -euo pipefail
BASE="${1:-http://127.0.0.1:8081}"

echo "→ health"
curl -fsS "$BASE/health" | tee /tmp/atw-health.json
echo

echo "→ browse open Bay Area games"
curl -fsS "$BASE/api/v1/games?includeFull=false&region=bay-area" | tee /tmp/atw-games.json
echo

python3 - <<'PY'
import json, urllib.request
games = json.load(open("/tmp/atw-games.json"))
print(f"open games: {len(games)}")
for g in games:
    assert g["joinedCount"] < g["capacity"], g
    print(f"  - {g['title']} @ {g['neighborhood']} ({g['joinedCount']}/{g['capacity']})")
if not games:
    raise SystemExit("expected seeded Bay Area games — start with SEED_DEMO=1 ./scripts/run-backend.sh")

meta = json.load(urllib.request.urlopen("http://127.0.0.1:8081/api/v1/meta/bay-area"))
assert len(meta["counties"]) == 9, meta["counties"]
needed = set(meta["counties"])
found = set()
for g in games:
    # neighborhood format: "City, County"
    parts = [p.strip() for p in g["neighborhood"].split(",")]
    if len(parts) >= 2:
        found.add(parts[-1])
missing = needed - found
if missing:
    raise SystemExit(f"seed missing counties: {sorted(missing)}")
print(f"OK — all 9 counties represented ({', '.join(sorted(found))})")
PY
