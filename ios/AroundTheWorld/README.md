# Around The World — iOS

## Open in Xcode

1. Pull latest `main` (scheme target ID must match the project — older commits break Run).
2. Double-click:

```
AroundTheWorld.xcodeproj
```

3. Select an **iPhone simulator (iOS 17+)** → press **▶ Run**.
4. In a Terminal first: `../../scripts/run-backend.sh` (seeds Bay Area demo games).

Full checklist: [`../../RUN.md`](../../RUN.md).

## API

Default: `http://127.0.0.1:8081`. Without the API the app still launches and shows error/retry within ~8s (not a hang).

## Signing

- **Simulator:** no Apple Developer team required (project is configured for that).
- **Physical device:** set your Team under *Signing & Capabilities*. Leave **DEVELOPMENT_TEAM** empty in the project until Apple has given you a Team ID. Do not invent one.
- **Bundle ID:** `com.aroundtheworld.app` (do not change it).
- **Sign in with Apple:** see [`../../docs/sign-in-with-apple.md`](../../docs/sign-in-with-apple.md) for the Xcode + Apple + Supabase checklist.
- **Profile and Settings:** see [`../../docs/profile-and-settings.md`](../../docs/profile-and-settings.md).
- **Host a game:** see [`../../docs/host-a-game.md`](../../docs/host-a-game.md). Gold **+** → form → **Post Game**. Needs sign-in. No payments.
- **Store listing, screenshots, TestFlight, submit:** [`../../docs/release/README.md`](../../docs/release/README.md).
