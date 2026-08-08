<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project was previously connected to Lovable for a web prototype. The product
> is now a **native iOS app + Vapor backend**. Prefer not to force-push or rewrite
> published git history on shared branches.
<!-- LOVABLE:END -->

## Cursor Cloud specific instructions

### Product

- **iOS app (Xcode):** `ios/AroundTheWorld/AroundTheWorld.xcodeproj` — open this on macOS and Run.
- **API:** `Backend/` (Swift Vapor + Fluent + PostgreSQL / Supabase).
- This Cloud Agent is **Linux** — it cannot launch the iOS Simulator or Xcode. It can build/run the Vapor API.

### iOS app

- Single app target; sources live under `ios/AroundTheWorld/AroundTheWorld/`.
- Default API base URL: `http://127.0.0.1:8081` (simulator → Mac host).
- Signing: set Development Team in Xcode before device runs.

### Vapor backend

- Swift under `/opt/swift/current/usr/bin` when present; needs `libstdc++-14-dev` on this image.
- **Default DB is SQLite** (`around_the_world.sqlite`) — no Postgres required for local/dev.
- Run: `./scripts/run-backend.sh` or `cd Backend && swift run App serve --env development --hostname 127.0.0.1 --port 8081`
- Port **8081** matches the iOS client. Demo games are seeded on first boot.
- Postgres/Supabase: set `DATABASE_URL` or `DATABASE_DRIVER=postgres`. See `Backend/README.md` and `RUN.md`.
