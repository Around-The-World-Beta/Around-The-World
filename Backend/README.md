# Around The World — Vapor Backend

Swift / Vapor JSON API for the iOS app.

## Quick start (recommended — SQLite, zero setup)

From the repo root:

```sh
./scripts/run-backend.sh
```

Or:

```sh
cd Backend
swift run App serve --env development --hostname 127.0.0.1 --port 8081
```

Verify:

```sh
curl http://127.0.0.1:8081/health
curl http://127.0.0.1:8081/api/v1/games
```

Defaults:

- **Port:** `8081` (matches the iOS client)
- **Database:** SQLite file `around_the_world.sqlite` (auto-created)
- **Seed data:** demo users + 3 games on first boot

Full app checklist: [`../RUN.md`](../RUN.md)

## Postgres / Supabase (optional)

```sh
export DATABASE_DRIVER=postgres
# local: user atw / password atw_dev_password / db around_the_world
# or:
export DATABASE_URL='postgresql://...'
export DATABASE_TLS=require
./scripts/run-backend.sh
```

`docker compose up -d` in this folder starts a local Postgres 16 if you prefer that over SQLite.

**Setting up a hosted Supabase project:** follow [`../docs/supabase-setup.md`](../docs/supabase-setup.md).
It replaces Step 1.3 of the launch plan PDF, which is wrong — see
[`../docs/launch-plan-corrections.md`](../docs/launch-plan-corrections.md).

## Schema

`Sources/App/Migrations/` is the source of truth. `supabase/migrations/202611060001_atw_core_schema.sql`
is a verified transcription for applying the same schema by hand in the Supabase SQL editor.
**Change one and you must change the other in the same commit** — the two diverging is what
broke this project before. `docs/supabase-setup.md` explains how to re-verify them.

This service owns `users`, `profiles`, `games`, `participants`, and `friendships`. Supabase Auth
owns `auth.users` and nothing else. They are linked by `users.supabase_user_id`, which is written
only from a verified JWT and is rejected if a client sends it — see `Sources/App/IdentityLink.swift`.

**How the iPhone signs in:** [`../docs/auth-contract.md`](../docs/auth-contract.md).

## Railway / HTTPS

Owner walkthrough (what to click, exact variable names, how to know `/health` worked): [`../docs/railway-setup.md`](../docs/railway-setup.md).

The deployable unit is the `Dockerfile` at the repo root. Hosted boots refuse to start without `SUPABASE_JWT_SECRET`, `SUPABASE_URL`, and `DATABASE_URL`. They never use SQLite. `SEED_DEMO` is ignored in production.

| Name | Where it comes from |
| --- | --- |
| `SUPABASE_JWT_SECRET` | Project Settings → API → JWT Secret |
| `SUPABASE_URL` | Project Settings → API → Project URL |
| `DATABASE_URL` | Project Settings → Database → Connection string → URI |
| `CORS_ALLOWED_ORIGINS` | Leave empty unless a specific website must call the API |
| `RATE_LIMIT_PER_MINUTE` | Optional; default `120` |
| `SEED_DEMO` | Staging only (`1`), never production |
| `VAPOR_ENV` | Unset on production. Staging: `staging` |
| `PORT` | Leave unset — Railway injects it |

## API (`/api/v1`)

Public (no token): `GET /health`, `GET /meta/bay-area`, `GET /games`, `GET /games/:id`.

Authenticated (`Authorization: Bearer <supabase access token>`):

| Resource | Endpoints |
| --- | --- |
| Account | `GET/PATCH/DELETE /me` |
| Profile | `GET/PATCH /me/profile` |
| My games / friends | `GET /me/games`, `GET /me/friendships` |
| Host | `POST /games`, `PATCH/DELETE /games/:id` (host only) |
| Claim spot | `POST /participants` (player = token) |
| Player card | `GET /players/:id` (no email) |

Dump endpoints (`GET /users`, `GET /profiles`, `GET /games/mine?userId=`, …) return `401`.

Errors:

```json
{ "error": { "message": "Sign in required", "status": 401 } }
```
