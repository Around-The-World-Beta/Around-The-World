# Swift / iOS architecture (App Store path)

Around The World is pivoting from the Lovable web prototype to a **native
Swift / SwiftUI iOS app** backed by a **Swift Vapor API** and **Supabase**
(managed Postgres + Auth).

## Target structure

```
[Phase 1: Database & Backend]
        │
        ▼
[Phase 2: API & Network Client]
        │
        ▼
[Phase 3: SwiftUI Frontend UI]
        │
        ▼
[TestFlight beta → App Store (free)]
```

| Path | Role |
| --- | --- |
| `Backend/` | Vapor 4 + Fluent REST API (JSON) |
| `ios/AroundTheWorld/` | SwiftPM kit (`NetworkManager` + Codable models) + SwiftUI app shell |
| `supabase/` | Auth / SQL helpers, Supabase project docs |
| `src/` | Legacy web UI — **layout reference only** until SwiftUI parity |

## Backend ownership (Phase 1)

Vapor owns these tables via Fluent migrations:

- `users` — app identity (`email`, `display_name`, optional `supabase_user_id`)
- `profiles` — player profile fields (city, bio, position, skill, avatar)
- `games` — pickup matches (host, venue, skill, format, capacity, geo, price)
- `participants` — join / waitlist / leave
- `friendships` — social edges (pending / accepted / blocked)

All routes under `/api/v1/*` return clean JSON. Errors use:

```json
{ "error": { "message": "...", "status": 404 } }
```

## Supabase role

| Concern | Phase | Owner |
| --- | --- | --- |
| Managed PostgreSQL | 1 | Supabase Postgres via `DATABASE_URL` |
| Fluent schema / CRUD | 1 | Vapor |
| Email + Sign in with Apple | 2 | Supabase Auth |
| JWT validation on API | 2 | Vapor middleware |
| SwiftUI screens | 3 | `ios/` |

`users.supabase_user_id` is the bridge from Supabase Auth UUIDs into Fluent-owned rows.

## App Store notes (free app)

- No IAP required for a free app with optional paid pickup games collected
  outside Apple’s digital goods rules — confirm with counsel before charging
  in-app for real-world field fees.
- Need: Apple Developer Program, permanent Bundle ID, Privacy Manifest,
  Sign in with Apple (if Apple login is offered), location purpose strings,
  TestFlight, App Privacy labels.
- SwiftUI / Xcode builds require **macOS + Xcode**. Linux Cloud Agents can
  build and run the **Vapor backend only**.

## Exact UI layout goal

Phase 3 must reproduce the current product layout from `src/routes` and
`src/components` (Matches list/map, Filters sheet, Game detail + Claim Spot,
Host flow, My Games, Friends, Profile/Account). Treat the web prototype as the
visual source of truth until native screens replace it.
