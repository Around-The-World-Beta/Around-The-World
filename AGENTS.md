<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## Cursor Cloud specific instructions

### Product direction

- **App Store path:** native SwiftUI iOS app + Swift Vapor backend + Supabase (Postgres/Auth). See `docs/swift-ios-architecture.md`.
- **Phase 1 backend** lives in `Backend/` (Vapor + Fluent). **Phase 2 network client** lives in `ios/AroundTheWorld/` (`AroundTheWorldKit` SwiftPM package). `src/` is the legacy web prototype used as **UI layout reference** for Phase 3 SwiftUI screens.
- This Cloud Agent environment is **Linux** — it can build/run the Vapor API and `swift test` the networking kit, not a full Xcode/SwiftUI app. SwiftUI UI work needs macOS + Xcode.

### Vapor backend

- Requires Swift 6+ on `PATH` (install under `/opt/swift/current/usr/bin` if missing).
- Local Postgres defaults: user `atw`, password `atw_dev_password`, db `around_the_world`, `DATABASE_TLS=disable`.
- Supabase: set `DATABASE_URL` + `DATABASE_TLS=require` (see `Backend/.env.example`).
- Run from `Backend/`: `swift run App serve --env development --hostname 127.0.0.1 --port 8081` (prefer **8081** when the legacy web `bun run dev` already owns 8080).
- Health: `GET /health`. CRUD under `/api/v1/{users,profiles,games,participants,friendships}`.
- System deps for Vapor on this image: Swift under `/opt/swift/current`, `libstdc++-14-dev` / `g++-14`, local Postgres (`atw` / `atw_dev_password` / `around_the_world`).
- Standard commands: `Backend/README.md`.

### Legacy web prototype

- Bun 1.3.14 + `bun install` / `bun run dev` (port **8080** via Lovable sandbox detection). Runs without Supabase secrets on mock game data.
- `bun test` and `bun run build` pass; `bun run lint` / `bun run typecheck` may report pre-existing failures on `main`.
