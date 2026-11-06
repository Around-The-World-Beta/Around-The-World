# Sign in with Apple — what to do on your Mac

This is the checklist for turning the new sign-in screen on. You do not need to write any code. The app identifier is **`com.aroundtheworld.app`** — do not change it.

Team / signing is left blank on purpose. Do not type a Team ID until Apple has given you one.

## What the app does now

1. Matches still work if nobody is signed in.
2. Claim Spot, the gold **+** (Host), My Games, and Profile ask you to **Sign in with Apple**.
3. After Apple says yes, the phone trades that login with Supabase, stores the session in the iOS Keychain (so it survives closing the app), then calls the server at `GET /api/v1/me`. That is how Claim Spot / My Games / Host / Profile know who you are.
4. **Sign out** and **Delete account** live in Settings (gear on the profile screen). Delete account is required by Apple; it calls `DELETE /api/v1/me` and then signs you out.

## One-time Apple setup

Wait until your Apple Developer enrolment shows a **Team** in Xcode. If Team ID has not arrived yet, stop here and come back — the screens will still build.

1. Open [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Register (or open) App ID **`com.aroundtheworld.app`**.
3. Enable **Sign in with Apple** on that App ID. Save.
4. In [App Store Connect](https://appstoreconnect.apple.com), create the app record with the same identifier if you have not already.

## One-time Supabase setup

Sign in with Apple talks to **Supabase Auth**, not directly to our game server.

1. In the Supabase dashboard: **Authentication → Providers → Apple**. Turn it on.
2. Client IDs: `com.aroundtheworld.app`
3. Add the Apple secret key / Services ID Apple shows you when you create a Sign in with Apple key. (Apple → Keys → Sign in with Apple.)
4. Copy the project URL (`https://….supabase.co`) and the **anon** public key. You will paste those into Xcode, not into git.

Our server also needs `SUPABASE_JWT_SECRET` and `SUPABASE_URL` when it runs, or real Apple logins will not verify. That is the server auth workstream, not this iPhone change.

## Xcode checklist (run this)

1. Start the API on your Mac: `./scripts/run-backend.sh`
2. Open `ios/AroundTheWorld/AroundTheWorld.xcodeproj`
3. Select the **AroundTheWorld** target → **Signing & Capabilities**
   - Check **Automatically manage signing**
   - **Team:** pick your Apple Developer team (leave it empty until the team exists)
   - **Bundle Identifier:** `com.aroundtheworld.app`
   - Confirm **Sign in with Apple** is listed. If it is missing, click **+ Capability** → **Sign in with Apple**
4. Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:
   - `API_BASE_URL` = `http://127.0.0.1:8081` (Simulator)
   - `SUPABASE_URL` = your project URL
   - `SUPABASE_ANON_KEY` = your anon key
5. Pick an **iPhone simulator (iOS 17+)** or a physical iPhone
6. Press **Run**
7. In the Simulator: **Settings → Sign in to your iPhone** with the Apple ID you want to test (or use a real iPhone)
8. In the app: tap the avatar → **Sign in with Apple** → browse still works if you cancel
9. After a successful sign-in: Profile shows your name; My Games loads your list; Claim Spot sends `POST /api/v1/participants` with only the game id
10. Force-quit the app and reopen — you should still be signed in
11. Settings → **Sign out** → reopen — signed out, Matches still list games
12. Sign in again → Settings → **Delete account** → confirm. That is the Apple-required in-app deletion path

## If something fails

| What you see | Likely cause |
| --- | --- |
| “Sign in isn't set up on this build yet” | `SUPABASE_URL` / `SUPABASE_ANON_KEY` missing in the scheme |
| Apple sheet never appears / signing error | Team not selected, or Sign in with Apple capability not on the App ID |
| Apple works, then the app user is empty | Server auth update (W1) is not running yet, or `SUPABASE_JWT_SECRET` is unset on the API |
| Simulator cannot reach the API | Run `./scripts/run-backend.sh` first. A physical iPhone cannot use `127.0.0.1` — that needs the hosted API |

Do not change the bundle id. Do not add payments. Bay Area only stays as the server already enforces it.
