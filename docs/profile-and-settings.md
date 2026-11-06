# Profile and Settings — what to do on your Mac

This is the checklist for the new Profile screen and Settings list. You do not need to write any code. The app identifier is **`com.aroundtheworld.app`** — do not change it.

Sign in still uses the same Apple + Supabase steps in [`sign-in-with-apple.md`](sign-in-with-apple.md). Do that first if you have not already.

This Linux machine cannot compile SwiftUI. Please run the steps below in Xcode on your Mac.

## What the app does now

1. Tap the avatar in the header to open **Profile**.
2. **Signed out:** you see an empty profile and a **Sign in** button. The app does not crash. You can still open Settings (language, location, legal pages).
3. **Signed in:** your name, city · age, position, and bio show on the profile. **Edit** opens a sheet for those fields (bio is capped at 200 characters). **Save** writes to the server (`PATCH /api/v1/me` for the name, `PATCH /api/v1/me/profile` for the rest).
4. **Settings** is the designed list: Location Access, Language (twelve languages), Notifications, Payments, Help & Feedback, Terms, Privacy Policy, Log Out, Delete Account.
5. **Log Out** and **Delete Account** are the same actions as before. Delete Account is required by Apple; it calls `DELETE /api/v1/me` and then signs you out. There is not a second delete path.
6. **Payments** says hosting is free / pay at the field. There is no Stripe and no in-app money.
7. **Notifications** says this is coming in version 1.1.
8. English and Spanish switch the in-app copy. The other ten languages are listed so the screen matches the design; they stay on English until those translations exist.
9. City on the profile is a text field (Bay Area only for posting games — that is the server’s job, not a city picker here).

## Photo (honest gap)

You can tap the photo on Edit Profile and pick one from the library. It previews on that sheet.

It does **not** upload. The server can store a picture *address* (`avatarUrl`) but it has no “upload this photo” endpoint and no file storage wired up. Inventing that would have meant changing the Vapor server, which this work did not do.

Until that exists, the caption under the photo is correct: the picture stays on the phone for the preview, and is not saved to your account.

## Xcode checklist (run this)

1. Start the API on your Mac: `./scripts/run-backend.sh`
2. Open `ios/AroundTheWorld/AroundTheWorld.xcodeproj`
3. Select the **AroundTheWorld** target → **Signing & Capabilities**
   - Check **Automatically manage signing**
   - **Team:** pick your Apple Developer team (leave it empty until the team exists)
   - **Bundle Identifier:** `com.aroundtheworld.app`
   - Confirm **Sign in with Apple** is listed
4. Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:
   - `API_BASE_URL` = `http://127.0.0.1:8081` (Simulator)
   - `SUPABASE_URL` = your project URL
   - `SUPABASE_ANON_KEY` = your anon key
5. Pick an **iPhone simulator (iOS 17+)** or a physical iPhone
6. Press **Run**
7. **Signed out:** tap the avatar → empty profile + **Sign in**. Cancel sign-in. Confirm Matches still lists games and the profile did not crash.
8. Sign in with Apple.
9. Profile should show your name (from Apple, if Apple sent one). Tap **Edit**. Change name, city (type it — e.g. Oakland, CA), age, position, bio. Tap **Save**. The profile should show the new values.
10. Tap the photo in Edit. Pick an image. You should see a preview and the “stays on this phone” note. Save — the photo will not appear on your account yet (see Photo gap above).
11. Open **Settings** from the card on Profile.
    - **Location Access** — first tap asks the phone; if you already said no, it opens iPhone Settings
    - **Language** — English and Spanish change the words in the app; the other ten stay English for now. Scroll to the bottom and confirm **Indonesian** is visible
    - **Notifications** — “Coming in version 1.1”
    - **Payments** — “Hosting is free. Pay at the field.”
    - **Help & Feedback**, **Terms**, **Privacy Policy** — these open the public pages only after you publish the text in `docs/legal/` and paste `SUPPORT_URL`, `TERMS_URL`, and `PRIVACY_POLICY_URL` into the Xcode scheme. Until then the row explains that the page is not published yet. See [`legal/publish-and-xcode-checklist.md`](legal/publish-and-xcode-checklist.md).
12. Scroll to the bottom of Settings. **Log Out** — confirm. Profile should go back to the empty + sign-in state. Matches still work.
13. Sign in again. Settings → **Delete Account** → confirm. That is the Apple-required in-app deletion path. You should be signed out afterwards.

## If something fails

| What you see | Likely cause |
| --- | --- |
| Empty profile after a successful Apple login | Server auth update is not running, or `SUPABASE_JWT_SECRET` is unset on the API |
| Save on Edit Profile fails | API not running, or you are not signed in |
| Photo does not stay after Save | Expected — no upload endpoint yet |
| Help / Terms / Privacy say the page is not published | Expected until you publish `docs/legal/` and paste the https links into Xcode |
| “Sign in isn't set up on this build yet” | See [`sign-in-with-apple.md`](sign-in-with-apple.md) |

Do not change the bundle id. Do not add payments. Do not add a city picker for posting games.
