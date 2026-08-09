# Around the World — Bay Area

Pickup soccer across **all nine SF Bay Area counties**.

Primary workflow is **Cursor / VS Code / any IDE** (web app + Vapor API).  
The native iOS project under `ios/` remains optional for TestFlight later.

## Quick start (Cursor / VS Code)

```sh
./scripts/dev.sh
```

Then open **http://127.0.0.1:5173**

Or two terminals:

```sh
./scripts/run-backend.sh   # API :8081 — seeds Bay Area demos
cd web && bun install && bun run dev   # Web :5173
```

## What you get

| Surface | Path | How to run |
| --- | --- | --- |
| **Web app (primary)** | `web/` | `bun run dev` in Cursor/VS Code |
| **API** | `Backend/` | `./scripts/run-backend.sh` |
| iOS (optional) | `ios/AroundTheWorld/` | Xcode on a Mac |

## Bay Area coverage

Seed + browse region include the nine counties:

San Francisco · San Mateo · Santa Clara · Alameda · Contra Costa · Marin · Solano · Napa · Sonoma

Cities/venues are listed via `GET /api/v1/meta/bay-area`.

## Repo map

| Path | What |
| --- | --- |
| `web/` | Vite + React client — open in Cursor/VS Code |
| `Backend/` | Swift Vapor JSON API |
| `scripts/dev.sh` | One-command API + web |
| `ios/` | Optional SwiftUI app |
| `supabase/` | Optional hosted Postgres SQL |
| `RUN.md` | Troubleshooting |

Never commit `.env`, service-role keys, or Apple private keys.
