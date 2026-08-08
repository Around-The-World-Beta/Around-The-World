# Around The World — iOS

Native Swift / SwiftUI client for TestFlight and the App Store (free).

## Layout

```
ios/
├── README.md                 ← you are here
└── AroundTheWorld/           ← iOS project directory
    ├── Package.swift         ← AroundTheWorldKit (Network + Models)
    ├── Sources/AroundTheWorldKit/
    │   ├── Network/          ← NetworkManager (async/await)
    │   ├── Models/           ← Codable structs ≡ Vapor JSON
    │   └── Services/         ← AroundTheWorldAPI facade
    ├── App/                  ← SwiftUI app shell for Xcode
    └── Tests/
```

See [`AroundTheWorld/README.md`](AroundTheWorld/README.md) for setup and usage.

## Phase status

| Phase | Status |
| --- | --- |
| 1 — Vapor backend | `Backend/` |
| 2 — Network client + Codable schemas | **`ios/AroundTheWorld/` (this)** |
| 3 — Exact SwiftUI layout (Matches/Map/Host/…) | next; use `src/routes` as visual source of truth |

## Requirements for UI work (Phase 3)

- macOS + Xcode 16+
- Bundle ID, signing, icons, Privacy Manifest
- Supabase Auth + Keychain (after JWT middleware on the API)
