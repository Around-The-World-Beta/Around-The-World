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
- Local Postgres defaults: user `atw`, password `atw_dev_password`, db `around_the_world`, `DATABASE_TLS=disable`.
- Run: `cd Backend && swift run App serve --env development --hostname 127.0.0.1 --port 8081`
- Prefer **8081** so it does not collide with other local servers.
- Standard commands: `Backend/README.md`.
