# Around The World

Around The World is a pickup sports app for hosting, discovering, joining, and
managing nearby games. The product is being shipped as a **free native iOS app**
(SwiftUI) with a **Swift Vapor** backend and **Supabase** (Postgres + Auth).

## Active build path (Swift / App Store)

| Phase | Focus | Location |
| --- | --- | --- |
| **1 — Database & Backend** | Vapor + Fluent + PostgreSQL CRUD JSON APIs | [`Backend/`](Backend/) |
| **2 — API & Network Client** | Supabase Auth JWTs + iOS networking | `Backend/` + `ios/` |
| **3 — SwiftUI Frontend UI** | Exact layout parity with the prototype | [`ios/`](ios/) |

Architecture notes: [docs/swift-ios-architecture.md](docs/swift-ios-architecture.md)

### Phase 1 backend (Vapor)

```sh
cd Backend
cp .env.example .env
# Point DATABASE_URL at Supabase Postgres (TLS=require), or use local Postgres.
swift run App serve --env development --hostname 0.0.0.0 --port 8080
```

See [`Backend/README.md`](Backend/README.md) for migrations, routes, and examples.

## Legacy web prototype (layout reference)

The existing TanStack / React UI under `src/` remains as the **visual source of
truth** for Phase 3 SwiftUI screens. It is not the App Store binary.

```sh
bun install
cp .env.example .env.local
bun run dev
```

Older gated milestones (web + Capacitor) are still documented in
[docs/launch-milestones.md](docs/launch-milestones.md). Prefer the Swift phases
above for App Store work.

Never commit `.env`, `.env.local`, `.dev.vars`, service-role keys, Apple private
keys, or production credentials.
