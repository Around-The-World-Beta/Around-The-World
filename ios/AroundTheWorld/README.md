# Around The World — iOS

## Open in Xcode

Double-click:

```
AroundTheWorld.xcodeproj
```

Select an **iPhone simulator** → press **▶ Run**.

Full checklist (API + common errors): see [`../../RUN.md`](../../RUN.md).

## API

The app loads matches from `http://127.0.0.1:8081`.

Start the backend **before** Run if you want live data:

```sh
../../scripts/run-backend.sh
```

Without the API, the UI still launches and shows an error / retry state.

## Signing

- **Simulator:** no Apple Developer team required (project is configured for that).
- **Physical device:** set your Team under *Signing & Capabilities*.
