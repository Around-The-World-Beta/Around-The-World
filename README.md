# Around The World

Native **iOS** pickup-sports app (SwiftUI) + **Swift Vapor** API.

> **Start here:** [`RUN.md`](RUN.md) — step-by-step Xcode + backend checklist.

## Quick start

**Terminal (API):**
```sh
./scripts/run-backend.sh
```

**Xcode (app):** open
```
ios/AroundTheWorld/AroundTheWorld.xcodeproj
```
then press **Run** on an iPhone simulator.

The API defaults to **SQLite** (no Postgres install). Demo matches are seeded automatically.  
iOS talks to `http://127.0.0.1:8081`.

## Repo map

| Path | What |
| --- | --- |
| `ios/AroundTheWorld/AroundTheWorld.xcodeproj` | **Open this in Xcode** |
| `Backend/` | Vapor JSON API |
| `scripts/run-backend.sh` | One-command API start |
| `supabase/` | Optional hosted Postgres SQL |
| `RUN.md` | Troubleshooting |

Never commit `.env`, service-role keys, or Apple private keys.
