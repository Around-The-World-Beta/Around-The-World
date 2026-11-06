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

**Simulator (Debug):** `http://127.0.0.1:8081` — `Config/Debug.xcconfig` and the scheme
environment variable `API_BASE_URL`. Start the API with `../../scripts/run-backend.sh`.

**Hosted / TestFlight:** paste the Railway HTTPS URL into
`Config/Release.xcconfig` as `API_BASE_URL = https:/$()/YOUR-SERVICE.up.railway.app`
(the `$()` spelling is required in xcconfig). Full steps:
[`../../docs/railway-setup.md`](../../docs/railway-setup.md) Step 8.

Settings in the app shows the URL it is actually using. Sign-in is a later workstream;
browse of public games only needs that URL.

Without the API the app still launches and shows error/retry within ~8s (not a hang).

## Signing

- **Simulator:** no Apple Developer team required (project is configured for that).
- **Physical device:** set your Team under *Signing & Capabilities*.
