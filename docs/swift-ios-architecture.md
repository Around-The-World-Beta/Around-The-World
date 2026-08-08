# Swift / iOS architecture

Around The World ships as a **native iOS app** (SwiftUI) plus a **Swift Vapor** API
backed by PostgreSQL (local or Supabase).

## Open the app

```
ios/AroundTheWorld/AroundTheWorld.xcodeproj
```

Press Run in Xcode (iOS 17+ simulator or device).

## Layout

| Path | Role |
| --- | --- |
| `ios/AroundTheWorld/` | Xcode iOS application |
| `Backend/` | Vapor REST API (`/api/v1`) |
| `supabase/` | Optional SQL for Supabase Postgres |

## Client ↔ API

- `NetworkManager` (async/await) + `AroundTheWorldAPI`
- Codable models match Vapor JSON field-for-field
- Screens use `@StateObject` view models with loading / error / empty states

## Supabase

| Concern | Owner |
| --- | --- |
| Postgres | Supabase via `DATABASE_URL` on the Vapor service |
| Auth (Sign in with Apple, email) | Next iteration — JWT middleware on Vapor |
