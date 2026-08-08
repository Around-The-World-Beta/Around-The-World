# Get the app running (Xcode + API)

Two processes are required:

1. **Backend API** (Terminal) — serves JSON on port `8081`
2. **iOS app** (Xcode Simulator) — UI that calls that API

---

## 1. Start the backend

In Terminal on your Mac:

```sh
cd /path/to/Around-The-World
chmod +x scripts/run-backend.sh
./scripts/run-backend.sh
```

Or manually:

```sh
cd Backend
swift run App serve --env development --hostname 127.0.0.1 --port 8081
```

Check it:

```sh
curl http://127.0.0.1:8081/health
# → {"status":"ok","service":"around-the-world-api"}

curl http://127.0.0.1:8081/api/v1/games
# → JSON array of demo matches
```

**Default database is SQLite** (`Backend/around_the_world.sqlite`) — no Postgres install needed.  
Demo games are seeded automatically on first boot.

Leave this Terminal window running.

---

## 2. Run the iOS app in Xcode

1. Open **exactly** this file (not the repo root folder):
   ```
   ios/AroundTheWorld/AroundTheWorld.xcodeproj
   ```
2. Wait for Xcode to finish indexing.
3. Top bar: choose **AroundTheWorld** scheme + an **iPhone 16** (or any) simulator.
4. Press **▶ Run** (`Cmd + R`).

### If Xcode won’t open / build / run

| Symptom | Fix |
| --- | --- |
| “No such file” / project won’t open | You opened the wrong path. Use the `.xcodeproj` above. Pull latest `main`. |
| Signing / Team errors | Simulator builds are set to not require a team. For a **physical iPhone**, set **Signing & Capabilities → Team** to your Apple ID. |
| App Icon / asset catalog errors | Pull latest `main` (placeholder App Icon is included). |
| Build fails after old cache | Xcode → **Product → Clean Build Folder**, delete DerivedData, reopen project. |
| Simulator black screen / crash on launch | Check the Xcode console. Confirm deployment target iOS 17+ simulator. |
| App opens but “Something broke” / empty matches | Backend isn’t running. Do step 1 and confirm `curl` health works. |
| Physical device can’t load games | `127.0.0.1` is the phone itself. Point `APIConfiguration` at your Mac’s LAN IP (e.g. `http://192.168.x.x:8081`). |

---

## 3. Optional: Postgres / Supabase later

```sh
export DATABASE_DRIVER=postgres
# or
export DATABASE_URL='postgresql://...'
export DATABASE_TLS=require
./scripts/run-backend.sh
```

---

## Quick mental model

```
iPhone Simulator  --HTTP-->  Vapor :8081  --SQL-->  SQLite (dev) or Supabase (hosted)
     ▲                            ▲
  Xcode Run                 ./scripts/run-backend.sh
```
