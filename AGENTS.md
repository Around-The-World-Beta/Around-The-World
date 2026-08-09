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

- Swift under `/opt/swift/current/usr/bin` when present; needs `libstdc++-14-dev` on this image.
- **Default DB is SQLite** (`around_the_world.sqlite`) — no Postgres required for local/dev.
- Run: `./scripts/run-backend.sh` or `cd Backend && swift run App serve --env development --hostname 127.0.0.1 --port 8081`
- Port **8081** matches the iOS client. Demo seed is **off** unless `SEED_DEMO=1`.
- Postgres/Supabase: set `DATABASE_URL` or `DATABASE_DRIVER=postgres`. See `Backend/README.md` and `RUN.md`.
- Bay Area beta notes: `docs/bay-area-beta.md`, TestFlight gaps: `docs/TESTFLIGHT-CHECKLIST.md`.
- iOS launch diagnostics: Console filter `subsystem:app.aroundtheworld.boot`. Location/MapKit must not run in `App.init`.
- **This Linux VM cannot run the iOS Simulator / Xcode.** Validate the API with `./scripts/run-backend.sh` + `./scripts/smoke-api.sh`. When regenerating `project.pbxproj`, always sync `AroundTheWorld.xcscheme` `BlueprintIdentifier` to the `PBXNativeTarget` id or Xcode Run breaks.
- Local API convenience: `SEED_DEMO` defaults to `1` in `scripts/run-backend.sh`.
