# AroundTheWorld (iOS)

Native iOS project directory for the App Store client.

| Piece | Path | Role |
| --- | --- | --- |
| **AroundTheWorldKit** | `Sources/AroundTheWorldKit/` | Reusable networking + Codable models (SwiftPM) |
| **App shell** | `App/` | SwiftUI `@main` entry (add to an Xcode iOS app target) |
| **Tests** | `Tests/AroundTheWorldKitTests/` | Schema decode/encode tests |

## Network stack

- `NetworkManager` — `actor`, async/await `URLSession`, generic GET/POST/PATCH/DELETE
- `AroundTheWorldAPI` — typed methods for every Vapor `/api/v1` route
- Models mirror backend DTOs in `Backend/Sources/App/DTOs/APIResponses.swift` **field-for-field** (camelCase)

```swift
import AroundTheWorldKit

let api = AroundTheWorldAPI()

// Point at your Vapor server (default: http://127.0.0.1:8081)
await NetworkManager.shared.setConfiguration(.localDevelopment)

let health = try await api.health()
let games = try await api.listGames()

let user = try await api.createUser(
    CreateUserRequest(
        email: "player@example.com",
        displayName: "Priya N.",
        city: "Brooklyn, NY",
        skillLevel: "Casual"
    )
)
```

## Open in Xcode (Mac)

1. `File → New → Project → App` (SwiftUI, iOS 17+, product name `AroundTheWorld`).
2. `File → Add Package Dependencies…` → **Add Local…** → select this `ios/AroundTheWorld` folder.
3. Link `AroundTheWorldKit` to the app target.
4. Replace the template app files with `App/AroundTheWorldApp.swift` + `App/ContentView.swift`.
5. Start the Vapor API (`Backend/`), then Run on a simulator.

> App Transport Security: `http://127.0.0.1` is allowed for local networking in recent iOS simulators. For a LAN device IP, add an ATS exception in Info.plist during development.

## Verify on this machine (Linux / CI)

```sh
cd ios/AroundTheWorld
swift test
```

## Schema map

| Swift type | Vapor type | Endpoint family |
| --- | --- | --- |
| `HealthResponse` | `HealthResponse` | `GET /health` |
| `UserResponse` / `CreateUserRequest` / `UpdateUserRequest` | same names | `/api/v1/users` |
| `ProfileResponse` / `UpdateProfileRequest` | same | `/api/v1/profiles` |
| `GameResponse` / `CreateGameRequest` / `UpdateGameRequest` | same | `/api/v1/games` |
| `ParticipantResponse` / create+update | same | `/api/v1/participants` |
| `FriendshipResponse` / create+update | same | `/api/v1/friendships` |
| `APIErrorBody` | `JSONErrorMiddleware.ErrorBody` | all error responses |
| `APIMessage` | `APIMessage` | delete confirmations |
