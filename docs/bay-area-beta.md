# Bay Area beta — implementation notes

## Launch hang (item 1)

**Root cause:** Matches loaded immediately via `URLSession.shared`, which defaults to `waitsForConnectivity = true` and a 30s request timeout. With the Vapor API down (common in Simulator), the first screen stayed on a spinner until the OS eventually failed the request — felt like a freeze (no crash).

**Fix:**
- Dedicated ephemeral `URLSession` with `waitsForConnectivity = false` and 8s timeouts
- Boot logger (`subsystem: app.aroundtheworld.boot`) through network / auth / Supabase / location steps
- Location + MapKit permission **deferred** until Map or Host tab (never in `App.init`)
- Idle load state no longer shows an infinite spinner before `.task` runs

Filter Xcode console: `subsystem:app.aroundtheworld.boot`.

## Fully booked visibility (item 2)

Browse: `GET /api/v1/games?includeFull=false` keeps only `joinedCount < capacity`.  
My games: `GET /api/v1/games/mine?userId=` returns joined/waitlisted sessions including full ones.  
Cancellation (`participants.status = cancelled`) lowers `joinedCount` so the listing reappears automatically.

## Real data (item 3)

- Demo seed is **off** unless `SEED_DEMO=1`
- Point `DATABASE_URL` at Supabase Postgres for real data
- iOS has no hardcoded session/player arrays; empty states when the API returns `[]`

## Settings + EN/ES (item 4)

`Settings` → Language (Device default / English / Spanish). Strings in `en.lproj` + `es.lproj` via `L10n`. Preference in `UserDefaults` (`atw.language.preference`), per-user key ready once auth lands.

## MapKit (item 5)

- **Map** tab: native `Map` annotations for open sessions
- **Host** tab: `MKLocalSearchCompleter` + tap-to-drop pin (no manual coordinates)
- Google Places kept as photo helper only (`GOOGLE_PLACES_API_KEY`)

## Still waiting on you (items 6–7)

- Final logo file → swap App Icon / BrandHeader / launch screen
- Lovable profile screenshots → rebuild `PlayerProfileView` layout (fields already: age, skill, position, bio, based-in)

## API keys (item 8)

| Key | Where | Status |
| --- | --- | --- |
| `API_BASE_URL` | Info.plist / build setting | Defaults to `http://127.0.0.1:8081` |
| `SUPABASE_URL` | Info.plist / env | **Missing** until you set it |
| `SUPABASE_ANON_KEY` | Info.plist / env | **Missing** until you set it |
| `GOOGLE_PLACES_API_KEY` | Info.plist / env | **Missing** until you set it |
| `DATABASE_URL` | Backend `.env` | Required for hosted Supabase Postgres |
| `SUPABASE_JWT_SECRET` | Backend `.env` | Required for Auth (Phase 2) |

No secrets are committed. Settings screen lists which client keys are still empty/placeholders.
