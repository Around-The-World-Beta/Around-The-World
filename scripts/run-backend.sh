#!/usr/bin/env bash
# Start the Around The World API for the iOS simulator (port 8081, SQLite by default).
set -euo pipefail
cd "$(dirname "$0")/../Backend"

export PATH="${PATH}:/opt/swift/current/usr/bin:${HOME}/.swiftly/bin"

if ! command -v swift >/dev/null 2>&1; then
  echo "error: Swift is not installed."
  echo "  macOS:  xcode-select --install   (or install Xcode)"
  echo "          then: swift --version"
  exit 1
fi

# Zero-config local DB. Override with DATABASE_URL / DATABASE_DRIVER=postgres if needed.
export DATABASE_DRIVER="${DATABASE_DRIVER:-sqlite}"
export SQLITE_PATH="${SQLITE_PATH:-around_the_world.sqlite}"
# Local Mac/Simulator convenience: seed Bay Area demo listings unless explicitly disabled.
export SEED_DEMO="${SEED_DEMO:-1}"

echo "→ Building & starting API on http://127.0.0.1:8081  (driver=${DATABASE_DRIVER}, SEED_DEMO=${SEED_DEMO})"
exec swift run App serve --env development --hostname 127.0.0.1 --port 8081
