#!/usr/bin/env bash
# Primary Cursor / VS Code workflow: API + web app.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="${PATH}:/opt/swift/current/usr/bin:${HOME}/.swiftly/bin:${HOME}/.bun/bin"

if ! command -v bun >/dev/null 2>&1; then
  echo "error: bun is required. Install from https://bun.sh"
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "error: Swift is required for the Vapor API."
  exit 1
fi

cd "$ROOT/web"
if [[ ! -d node_modules ]]; then
  bun install
fi

# Start API in background
export DATABASE_DRIVER="${DATABASE_DRIVER:-sqlite}"
export SQLITE_PATH="${SQLITE_PATH:-$ROOT/Backend/around_the_world.sqlite}"
export SEED_DEMO="${SEED_DEMO:-1}"

echo "→ API  http://127.0.0.1:8081  (SEED_DEMO=${SEED_DEMO})"
echo "→ Web  http://127.0.0.1:5173  (Cursor / VS Code / any browser)"

(
  cd "$ROOT/Backend"
  swift run App serve --env development --hostname 127.0.0.1 --port 8081
) &
API_PID=$!

cleanup() {
  kill "$API_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for health
for _ in $(seq 1 90); do
  if curl -fsS http://127.0.0.1:8081/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

cd "$ROOT/web"
exec bun run dev -- --host 0.0.0.0 --port 5173
