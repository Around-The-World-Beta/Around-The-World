# Around The World — Vapor Backend (Phase 1)

Native **Swift / Vapor** API for the Around The World iOS app.

- **Framework:** Vapor 4 + Fluent
- **Database:** PostgreSQL (local or **Supabase Postgres**)
- **Responses:** clean JSON (`application/json`)
- **Auth:** Supabase Auth JWT validation lands in **Phase 2**

## Repository layout (Swift / App Store path)

```
Around-The-World/
├── Backend/          ← this service (Phase 1: DB + CRUD APIs)
├── ios/              ← SwiftUI app (Phase 3)
├── supabase/         ← Supabase SQL / Auth helpers
├── src/              ← legacy Lovable web prototype (reference UI only)
└── docs/             ← architecture + launch docs
```

## Requirements

- Swift 6.0+
- PostgreSQL 16+ **or** a Supabase project with a Postgres connection string

## Quick start (local Postgres)

```sh
cd Backend

# Option A: Docker Postgres
docker compose up -d

# Option B: local Postgres already running with:
#   user=atw password=atw_dev_password db=around_the_world

cp .env.example .env
# edit .env if needed — default DATABASE_TLS=disable for local

export $(grep -v '^#' .env | xargs)
swift run App serve --env development --hostname 0.0.0.0 --port 8080
```

Health check:

```sh
curl -s http://localhost:8080/health
```

## Supabase Postgres

1. Create a Supabase project (dev / staging / prod separately).
2. Copy the **Database** connection URI into `DATABASE_URL`.
3. Set `DATABASE_TLS=require`.
4. Run migrations against that database:

```sh
export DATABASE_URL='postgresql://...'
export DATABASE_TLS=require
swift run App migrate --env production
swift run App serve --env production --hostname 0.0.0.0 --port 8080
```

> Phase 1 creates Fluent-owned tables (`users`, `profiles`, `games`, `participants`, `friendships`).
> Existing `supabase/migrations/*_auth_profiles.sql` was written for the web prototype’s
> `auth.users`-linked profiles. Do **not** mix those tables with Fluent’s `users`/`profiles`
> until Phase 2 unifies identity around Supabase Auth JWTs + `supabase_user_id`.

## API surface (`/api/v1`)

| Resource | Endpoints |
| --- | --- |
| Users | `GET/POST /users`, `GET/PATCH/DELETE /users/:id` |
| Profiles | `GET /profiles`, `GET/PATCH/DELETE /profiles/:id`, `GET /profiles/user/:userId` |
| Games | `GET/POST /games`, `GET/PATCH/DELETE /games/:id` |
| Participants | `GET/POST /participants`, `GET/PATCH/DELETE /participants/:id`, `GET /participants/game/:gameId` |
| Friendships | `GET/POST /friendships`, `GET/PATCH/DELETE /friendships/:id`, `GET /friendships/user/:userId` |

Errors are always JSON:

```json
{ "error": { "message": "User not found", "status": 404 } }
```

### Example — create user + host a game

```sh
# Create user (also creates an empty profile)
curl -s -X POST http://localhost:8080/api/v1/users \
  -H 'Content-Type: application/json' \
  -d '{"email":"host@example.com","displayName":"Coach T","city":"Brooklyn, NY","skillLevel":"Baller"}'

# Create game (host is auto-joined)
curl -s -X POST http://localhost:8080/api/v1/games \
  -H 'Content-Type: application/json' \
  -d '{
    "hostUserId":"USER_UUID",
    "title":"Saturday Scrimmage & Drills",
    "venue":"Red Hook Rec Fields",
    "neighborhood":"Red Hook",
    "skill":"Baller",
    "format":"8v8",
    "capacity":16,
    "priceCents":1000,
    "notes":"First 30 min touch drills, then full scrimmage.",
    "startsAt":"2026-08-09T13:00:00Z",
    "latitude":40.6734,
    "longitude":-74.0083
  }'
```

## Migrations

```sh
swift run App migrate
swift run App migrate --revert --yes
```

Development auto-migrates on boot.

## Tests

```sh
swift test
```

## Next phases

1. **Phase 2 — API & Network Client:** Supabase Auth JWT middleware, hardened authorization, Swift `URLSession` / async client for the iOS app.
2. **Phase 3 — SwiftUI Frontend UI:** native screens matching the current Matches / Map / Host / Friends / Profile layout for TestFlight + App Store.
