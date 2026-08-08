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

## API (`/api/v1`)

| Resource | Endpoints |
| --- | --- |
| Users | `GET/POST /users`, `GET/PATCH/DELETE /users/:id` |
| Profiles | `GET /profiles`, `GET/PATCH/DELETE /profiles/:id`, `GET /profiles/user/:userId` |
| Games | `GET/POST /games`, `GET/PATCH/DELETE /games/:id` |
| Participants | `GET/POST /participants`, … |
| Friendships | `GET/POST /friendships`, … |

Errors:

```json
{ "error": { "message": "User not found", "status": 404 } }
```
