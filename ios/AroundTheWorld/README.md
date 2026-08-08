# Around The World — iOS App

Native **SwiftUI** iPhone/iPad app. This is not a website.

## Open & run in Xcode

1. On a Mac, install **Xcode 16+** from the App Store.
2. Double-click:
   ```
   ios/AroundTheWorld/AroundTheWorld.xcodeproj
   ```
3. Select an **iPhone simulator** (or your device).
4. Set your **Team** under Signing & Capabilities (required for device runs).
5. Press **▶ Run**.

The app talks to the Vapor API at `http://127.0.0.1:8081` by default (simulator → Mac).

### Start the API (separate Terminal)

```sh
cd Backend
cp .env.example .env   # first time
swift run App serve --env development --hostname 127.0.0.1 --port 8081
```

Without the API, the Matches screen shows the error/empty states (still a valid app launch).

## Project layout

```
AroundTheWorld.xcodeproj     ← open this in Xcode
AroundTheWorld/
  AroundTheWorldApp.swift    ← @main
  ContentView.swift
  Views/                     ← Matches dashboard + game detail
  ViewModels/                ← @StateObject live fetchers
  Network/                   ← async/await NetworkManager
  Models/                    ← Codable ≡ Vapor JSON
  Services/                  ← AroundTheWorldAPI
  Components/ Theme/ …
  Info.plist
  Assets.xcassets
```

## Bundle ID

`com.aroundtheworld.app` — change in Xcode if you need a different App Store ID.
