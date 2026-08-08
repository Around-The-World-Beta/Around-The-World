# AroundTheWorld (iOS)

Native iOS project directory for the App Store client.

| Piece | Path | Role |
| --- | --- | --- |
| **AroundTheWorldKit** | `Sources/AroundTheWorldKit/` | NetworkManager + Codable models (SwiftPM) |
| **App UI** | `App/` | SwiftUI dashboard + detail (add to Xcode app target) |
| **Tests** | `Tests/AroundTheWorldKitTests/` | Schema + live API tests |

## App UI (SwiftUI)

Inspired by the original KickUp web prototype (`src/routes/index.tsx`, `games.$gameId.tsx`, `GameCard.tsx`).

```
App/
├── AroundTheWorldApp.swift          ← @main, configures NetworkManager
├── ContentView.swift                ← root → MatchesDashboardView
├── Theme/AppTheme.swift             ← dark + gold tokens (easy to restyle)
├── ViewModels/
│   ├── MatchesViewModel.swift       ← @StateObject, live listGames()
│   └── GameDetailViewModel.swift    ← @StateObject, getGame + participants
├── Views/
│   ├── MatchesDashboardView.swift   ← main dashboard
│   └── GameDetailView.swift         ← detail / Claim Spot
├── Components/                      ← loading, error, empty, cards, tiles
└── Extensions/GameDisplay.swift
```

### State handling

Each screen uses `@StateObject` + `LoadState`:

| State | UI |
| --- | --- |
| `loading` | `ProgressView` + message |
| `failed` | Error copy + **Try again** |
| `empty` | Empty database / not-found copy |
| `loaded` | Live cards / detail from Vapor |

Pull-to-refresh reloads the dashboard.

### Usage sketch

```swift
@StateObject private var viewModel = MatchesViewModel()

// Inside .task / retry:
await viewModel.load()
```

`MatchesViewModel` and `GameDetailViewModel` call `AroundTheWorldAPI` → `NetworkManager`.

## Network stack

```swift
import AroundTheWorldKit

await NetworkManager.shared.setConfiguration(.localDevelopment) // :8081
let api = AroundTheWorldAPI()
let games = try await api.listGames()
```

## Open in Xcode (Mac)

1. `File → New → Project → App` (SwiftUI, iOS 17+).
2. Add local package: this `ios/AroundTheWorld` folder → link `AroundTheWorldKit`.
3. Add **all** files under `App/` to the app target (not the kit target).
4. Start Vapor (`Backend/` on port **8081**), then Run.

## Verify kit on Linux / CI

```sh
cd ios/AroundTheWorld
swift test
```

## Schema map

Swift Codable types mirror `Backend/.../APIResponses.swift` field-for-field.
See `Sources/AroundTheWorldKit/Models/`.
