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
# → JSON array of open Bay Area matches (empty unless you seeded or connected Supabase)
```

**Default database is SQLite** (`Backend/around_the_world.sqlite`) — no Postgres install needed.  
Demo games are **not** seeded by default. For local sample data: `SEED_DEMO=1 ./scripts/run-backend.sh`.

If the Simulator used to freeze on launch with a spinner: pull latest `main` (URLSession no longer waits for connectivity) and keep the API running, or you’ll get a fast error/empty state instead of a hang.

Leave this Terminal window running.

---

## 2. Run the iOS app in Xcode

1. **Pull latest `main`** (important — an older scheme pointed at a deleted target ID and Xcode couldn’t Run).
2. Open **exactly** this file (not the repo root folder):
   ```
   ios/AroundTheWorld/AroundTheWorld.xcodeproj
   ```
3. Wait for Xcode to finish indexing.
4. Top bar: choose **AroundTheWorld** scheme + an **iPhone 16** (or any) **iOS 17+** simulator.
5. Press **▶ Run** (`Cmd + R`).

### If Xcode won’t open / build / run

| Symptom | Fix |
| --- | --- |
| Scheme missing / “does not contain a scheme” / Run greyed out | Pull latest `main`. Product → Scheme → Manage Schemes → ensure **AroundTheWorld** is shared/checked. |
| “No such file” / project won’t open | You opened the wrong path. Use the `.xcodeproj` above. |
| Signing / Team errors | Simulator builds are set to not require a team. For a **physical iPhone**, set **Signing & Capabilities → Team** to your Apple ID. |
| App Icon / asset catalog errors | Pull latest `main` (App Icon is included). |
| Build fails after old cache | Xcode → **Product → Clean Build Folder**, delete DerivedData (`~/Library/Developer/Xcode/DerivedData`), reopen project. |
| Simulator black screen / crash on launch | Console filter `app.aroundtheworld.boot`. Confirm iOS 17+ simulator. |
| Freeze / infinite spinner | Pull latest hang fix; start the API (step 1). Without API you should get an error/retry within ~8s, not a hang. |
| App opens but “Something broke” / empty matches | Backend isn’t running. Do step 1; `./scripts/smoke-api.sh` should list Bay Area games. |
| Physical device can’t load games | `127.0.0.1` is the phone itself. Set scheme env `API_BASE_URL=http://<your-mac-lan-ip>:8081`. |

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
