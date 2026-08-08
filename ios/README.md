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
| 2 — Network client + Codable schemas | `ios/AroundTheWorld/Sources/AroundTheWorldKit/` |
| 3 — SwiftUI dashboard + detail (live data) | **`ios/AroundTheWorld/App/`** (inspired by `src/`; iterate visually next) |

## Requirements for UI work (Phase 3)

- macOS + Xcode 16+
- Bundle ID, signing, icons, Privacy Manifest
- Supabase Auth + Keychain (after JWT middleware on the API)
