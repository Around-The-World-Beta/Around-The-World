# Around The World

Native **iOS** pickup-sports app (SwiftUI) with a **Swift Vapor** API and **Supabase** Postgres.

This repository is an **iOS app + backend**, not a website.

## Run the iOS app (Xcode)

1. Open in Xcode:
   ```
   ios/AroundTheWorld/AroundTheWorld.xcodeproj
   ```
2. Choose an iPhone simulator → press **Run**.

Details: [`ios/AroundTheWorld/README.md`](ios/AroundTheWorld/README.md)

## Run the API (Vapor)

```sh
cd Backend
cp .env.example .env
swift run App serve --env development --hostname 127.0.0.1 --port 8081
```

Point `DATABASE_URL` at Supabase Postgres for hosted data (`DATABASE_TLS=require`).  
See [`Backend/README.md`](Backend/README.md).

## Repo map

| Path | What it is |
| --- | --- |
| `ios/AroundTheWorld/` | **Xcode iOS app** (open the `.xcodeproj`) |
| `Backend/` | Vapor + Fluent JSON API |
| `supabase/` | Optional SQL migrations |
| `docs/` | Architecture notes |

Never commit `.env`, service-role keys, Apple private keys, or production credentials.
