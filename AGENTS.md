<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project was previously connected to Lovable for a web prototype. The product
> is now a **native iOS app + Vapor backend**. Prefer not to force-push or rewrite
> published git history on shared branches.
<!-- LOVABLE:END -->

## Cursor Cloud specific instructions

### Product

- **Primary client (Cursor / VS Code):** `web/` Vite + React — `./scripts/dev.sh` or `cd web && bun run dev`.
- **API:** `Backend/` (Swift Vapor + Fluent + SQLite / Supabase Postgres).
- **iOS (optional):** `ios/AroundTheWorld/AroundTheWorld.xcodeproj` on macOS only.
- This Cloud Agent is **Linux** — run the **web + API** stack here; it cannot launch the iOS Simulator.

### iOS app

- Single app target; sources live under `ios/AroundTheWorld/AroundTheWorld/`.
- Default API base URL: `http://127.0.0.1:8081` (simulator → Mac host).
- Signing: set Development Team in Xcode before device runs.

### Vapor backend

- **Swift is NOT preinstalled on the Cloud Agent image.** `/opt/swift/current` does not
  exist on a fresh VM, and `libstdc++-14-dev` is not in the default apt lists. Verified
  2026-11-06. Install it before touching `Backend/` — see "Installing Swift" below.
- **Default DB is SQLite** (`around_the_world.sqlite`) — no Postgres required for local/dev.
- Run: `./scripts/run-backend.sh` or `cd Backend && swift run App serve --env development --hostname 127.0.0.1 --port 8081`
- Port **8081** matches the iOS client. Demo seed is **off** unless `SEED_DEMO=1`.
- Postgres/Supabase: set `DATABASE_URL` or `DATABASE_DRIVER=postgres`. See `Backend/README.md` and `RUN.md`.
- Bay Area beta notes: `docs/bay-area-beta.md`, TestFlight gaps: `docs/TESTFLIGHT-CHECKLIST.md`.
- iOS launch diagnostics: Console filter `subsystem:app.aroundtheworld.boot`. Location/MapKit must not run in `App.init`.
- **This Linux VM cannot run the iOS Simulator / Xcode.** Validate the API with `./scripts/run-backend.sh` + `./scripts/smoke-api.sh`. When regenerating `project.pbxproj`, always sync `AroundTheWorld.xcscheme` `BlueprintIdentifier` to the `PBXNativeTarget` id or Xcode Run breaks.
- Local API convenience: `SEED_DEMO` defaults to `1` in `scripts/run-backend.sh`.

### Installing Swift on a Cloud Agent VM (~4 min)

`apt-get update` first — the image's package lists are stale, and without it every
package below reports "Unable to locate package".

```sh
sudo apt-get update
sudo apt-get install -y libncurses-dev libxml2-dev libpython3-dev libcurl4-openssl-dev
curl -sSL -o /tmp/swift.tar.gz \
  https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
sudo mkdir -p /opt/swift && sudo tar xzf /tmp/swift.tar.gz -C /opt/swift
sudo ln -sfn /opt/swift/swift-6.0.3-RELEASE-ubuntu24.04 /opt/swift/current
export PATH=/opt/swift/current/usr/bin:$PATH
swift --version   # expect: Swift version 6.0.3
```

Notes:

- `libncurses-dev` is the one that bites: without it `swift` exits with
  `error while loading shared libraries: libncurses.so.6`, which looks like a broken
  download rather than a missing dependency.
- `libstdc++-14-dev` does **not** exist on Ubuntu 24.04; `libstdc++-13-dev` is already
  present and is sufficient. The older note asking for `-14` was wrong.
- First `swift build` of `Backend/` is ~2.5 min (3,192 steps, fetches Vapor + Fluent).
  Incremental builds are ~12 s.

### Testing against Postgres on a Cloud Agent VM

SQLite covers most work, but schema changes should be checked on Postgres because that is
what Supabase runs, and the two differ (`.int` becomes `BIGINT`, RLS exists only on
Postgres). `supabase/migrations/202611060001_atw_core_schema.sql` must stay byte-identical
to what the Swift migrations produce — see the engineer note in `docs/supabase-setup.md`.

```sh
sudo apt-get install -y postgresql postgresql-client
sudo pg_ctlcluster 16 main start
sudo -u postgres psql -c "create role atw login password 'atw_dev_password' superuser;"
sudo -u postgres psql -c "create database around_the_world owner atw;"

cd Backend
DATABASE_URL="postgresql://atw:atw_dev_password@127.0.0.1:5432/around_the_world" \
  DATABASE_TLS=disable swift run App migrate --yes --env development
```

To confirm the SQL file and the Swift migrations still agree, apply each to its own empty
database and diff `pg_dump --schema-only --no-owner --no-privileges` (ignoring pg_dump's
`\restrict` lines, which differ per run).
