# Host a game — what to do on your Mac

This is the checklist for posting a pickup game from the iPhone app. You do not need to write any code. Hosting is **free**. There is no checkout and no price field. The pin must be in the **nine-county Bay Area** or the server will refuse it.

Sign in has to work first. Use [`sign-in-with-apple.md`](sign-in-with-apple.md) if the Apple sheet is not set up yet. The game server that **locks down accounts** (the W1 pull request) must be the one running — Publish sends the login token, never a user id.

This machine cannot run the iPhone Simulator. Verify on your Mac with Xcode.

## What the app does now

1. The gold **+** opens **Host a Game** if you are signed in. If you are not, it asks you to **Sign in with Apple** and does not crash.
2. Fill in **Game Title**, **Venue / Field** (search or drop a pin on the map), **Date**, **Kickoff Time**, **Format** (5v5 / 6v6 / 7v7 / 8v8 / 11v11), **Skill Level** (Casual / Intermediate / Baller / Open to All), **Max Players**, and optional **Notes**.
3. **Post Game** saves it as you. You should see **Game Posted!** then **Back to Find**.
4. The game shows on **Matches** (Browse) for that day, and on **My Games** with a **Hosting** label.
5. Open it from My Games: **Edit game** changes the same fields; **Cancel game** takes it off Matches.

## Xcode checklist (run this)

1. Start the API on your Mac. You want the **account-protected** server (the W1 change), not the old open one:
   - `./scripts/run-backend.sh`
2. Open `ios/AroundTheWorld/AroundTheWorld.xcodeproj`
3. Select the **AroundTheWorld** target → **Signing & Capabilities**
   - **Team:** your Apple Developer team (leave empty until you have one)
   - **Bundle Identifier:** `com.aroundtheworld.app` — do not change it
   - **Sign in with Apple** must be listed
4. Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:
   - `API_BASE_URL` = `http://127.0.0.1:8081` (Simulator)
   - `SUPABASE_URL` and `SUPABASE_ANON_KEY` as in the sign-in checklist
5. Pick an **iPhone simulator (iOS 17+)** or a physical iPhone
6. Press **Run**
7. **Signed out:** tap **+**. You should get the sign-in sheet, not a crash. Cancel and Matches still works.
8. **Sign in with Apple**
9. Tap **+**. You should see the full form (title, venue search, map pin, date, kickoff, format chips, skill chips, max players, notes) and a real **Post Game** button — not faded fake text. Notes stop at **500** characters.
10. Search a Bay Area field (try **Franklin Square Park**) or drop a pin in San Francisco. Title something like **Friday Night 7v7**. Leave skill **Intermediate**, format **7v7**, players **14**.
11. Tap **Post Game**. You should see **Game Posted!** then **Back to Find**.
12. **Matches:** the new game is in **Free Sessions** on that date. If the field is far from San Francisco, the distance filter may have opened up so you can see it.
13. **My Games:** same game, with **Hosting**.
14. Open it → **Edit game** → change the title → **Save changes**. Confirm Matches / My Games show the new title.
15. Open it → **Cancel game** → confirm. It disappears from Matches. My Games can still list it as **Cancelled**.
16. Try dropping a pin **outside** the Bay Area (Los Angeles). Post Game should refuse with a Bay Area message. That is intentional.

## If something fails

| What you see | Likely cause |
| --- | --- |
| Sign-in sheet instead of the form | You are signed out — that is correct |
| “Sign in isn't set up on this build yet” | Missing Supabase keys in the scheme — see the sign-in checklist |
| Post Game fails with “Sign in required” | The locked-down API (W1) is not running, or the token expired |
| Post Game fails mentioning `hostUserId` | You are still on the old server. W1 must be running. |
| Game Posted but it is not on Matches | Check the **date strip** (only 7 days) and the distance filter (default 10 miles). My Games still shows it. |
| Simulator cannot reach the API | Run `./scripts/run-backend.sh` first. A physical iPhone cannot use `127.0.0.1` |

Do not add a price or a payment screen. Do not change the bundle id. Bay Area only stays as the server already enforces it.
