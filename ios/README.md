# Around The World — iOS (SwiftUI)

**Status:** placeholder for Phase 3.

This directory will hold the native SwiftUI app targeting TestFlight and the
App Store (free).

## Planned layout (match the current product UI exactly)

| Screen | Source of truth (web prototype) |
| --- | --- |
| Matches (list + map + filters) | `src/routes/index.tsx` |
| Game detail / Claim Spot | `src/routes/games.$gameId.tsx` |
| Host a Game | `src/routes/host.tsx` |
| My Games | `src/routes/my-games.tsx` |
| Friends | `src/routes/friends.tsx` |
| Profile / Account | `src/routes/profile.tsx`, `src/routes/account.tsx` |
| Auth (email + Apple) | `src/routes/auth*.tsx` |

## Requirements (Phase 3)

- macOS with Xcode 16+
- Bundle ID (permanent), signing team, icons, launch screen
- Network client talking to `Backend` `/api/v1`
- Supabase Auth (Phase 2) with Keychain session storage
- Privacy Manifest + location permission copy

Do not start the Xcode project until Phase 1 APIs are stable and Phase 2 auth
is decided. See `docs/swift-ios-architecture.md`.
