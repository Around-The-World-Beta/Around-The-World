# Signing, TestFlight, and submit

You do this in a browser and in Xcode on your Mac. We cannot upload to App Store Connect for you.

If Apple has **not** given you a Team ID yet, do steps 1–3 of “On Apple’s sites,” then stop. Come back when enrolment shows a team. Do not type a made-up Team ID into Xcode.

Bundle id, forever: **`com.aroundtheworld.app`**.

---

## What you need in front of you

Write these down in a notes app. Do not put them in git, in a screenshot of this repo, or in a chat.

| Thing | Where it comes from | Example / placeholder |
| --- | --- | --- |
| Apple ID email | The Apple ID you enrolled with | you@example.com |
| Team name | [developer.apple.com/account](https://developer.apple.com/account) | Auner Vasquez |
| **Team ID** | Same page, 10 characters | `XXXXXXXXXX` — paste the real one when Apple shows it |
| Bundle ID | Already chosen | `com.aroundtheworld.app` |
| Privacy Policy URL | You publish [`docs/legal/privacy-policy.md`](../legal/privacy-policy.md) | `https://…` that opens on your iPhone with no login |
| Support URL | You publish [`docs/legal/support.md`](../legal/support.md) | same idea |
| Terms URL (optional) | [`docs/legal/terms.md`](../legal/terms.md) | same idea |
| App Review email | An inbox you actually read | often the same as Support |
| App Review phone | A number Apple can reach **within 24 hours** during review | include country code, e.g. `+1 …` |
| Supabase URL + anon key | Supabase dashboard | paste into Xcode only |
| Live API URL | Your hosted server (HTTPS) | paste into Xcode for device / TestFlight. Simulator can keep `http://127.0.0.1:8081` |

---

## On Apple’s sites (once enrolment is active)

### 1. Register the App ID

1. Open [Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. **+** → App IDs → App.
3. Description: `Around The World`.
4. Bundle ID: **Explicit** → `com.aroundtheworld.app`.
5. Capabilities: turn on **Sign in with Apple**. Save.

If the identifier already exists (from an earlier attempt), open it and confirm Sign in with Apple is on. Do not create a second one.

### 2. Create the app record in App Store Connect

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+**.
2. Name: `Around The World` (see [store-listing.md](store-listing.md) if it is taken).
3. Primary language: English (U.S.).
4. Bundle ID: `com.aroundtheworld.app`.
5. SKU: `around-the-world-ios`.
6. User access: Full Access.

### 3. Sign in with Apple key (for Supabase)

1. [Keys](https://developer.apple.com/account/resources/authkeys/list) → **+** → name it `ATW Sign in with Apple`.
2. Enable **Sign in with Apple**. Configure it for App ID `com.aroundtheworld.app`.
3. Download the `.p8` once. Store it in your password manager, **not** in this repo.
4. In Supabase: **Authentication → Providers → Apple**. Turn it on. Client IDs: `com.aroundtheworld.app`. Paste the key Apple gave you. Details: [`docs/sign-in-with-apple.md`](../sign-in-with-apple.md).

---

## In Xcode (your Mac)

Open `ios/AroundTheWorld/AroundTheWorld.xcodeproj`.

### Signing

1. Select the **AroundTheWorld** target → **Signing & Capabilities**.
2. Check **Automatically manage signing**.
3. **Team:** pick your Apple Developer team. If the list is empty, enrolment is not done — stop.
4. **Bundle Identifier:** `com.aroundtheworld.app`.
5. Confirm **Sign in with Apple** is in the capability list. If it is missing: **+ Capability** → Sign in with Apple.

Leave `DEVELOPMENT_TEAM` empty **in the project files we ship**. Set the team only in that Xcode dropdown on your machine. That way the Team ID never has to live in git.

### URLs and keys (scheme environment)

Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:

| Name | Simulator | Real iPhone / TestFlight |
| --- | --- | --- |
| `API_BASE_URL` | `http://127.0.0.1:8081` | your **https** API (the phone cannot see your laptop) |
| `SUPABASE_URL` | your project URL | same |
| `SUPABASE_ANON_KEY` | your anon key | same |
| `PRIVACY_POLICY_URL` | live https Privacy Policy | same |
| `SUPPORT_URL` | live https Support | same |
| `TERMS_URL` | optional | optional |

Blank legal URLs are OK until the pages are public. Settings will say the page is not published yet instead of opening a broken link.

Do not paste the **JWT secret**, Apple `.p8`, or database password into Xcode. Those belong on the server host only.

### Run once on a simulator before you archive

1. `./scripts/run-backend.sh` in Terminal.
2. Pick **iPhone 16 Pro** (or 15 Pro) → Run.
3. Sign in with Apple. Browse Matches. Claim a spot. Open Profile. Confirm Help / Privacy open your real pages.

Physical device: same Team, same bundle id, `API_BASE_URL` must be https.

---

## Archive and TestFlight

Do this only after Sign in with Apple works on a build that talks to the **hosted** API. A TestFlight build pointed at `127.0.0.1` will look empty on every tester’s phone.

1. Xcode scheme → **Any iOS Device (arm64)** (not a simulator).
2. Product → **Archive**. Wait.
3. Organizer → the archive → **Distribute App** → **App Store Connect** → Upload.
4. Export compliance: this project sets “uses non-exempt encryption” to **No**. If Apple still asks, answer **No** — we only use HTTPS and Sign in with Apple, which are exempt.
5. In App Store Connect → TestFlight, wait until processing finishes (often 10–30 minutes).

### Internal TestFlight (you + people on your App Store Connect team)

1. TestFlight → the build → Internal Testing.
2. Add yourself. Install **TestFlight** from the App Store on your iPhone. Open the invite.
3. Confirm: sign in, Matches load over https, claim, host, profile, delete-account still present (do not actually delete your only account until you have a spare).

### External TestFlight (Bay Area testers)

1. Collect 5–10 emails of people who actually play pickup here.
2. TestFlight → External Testing → add a group → add the build.
3. Fill **What to Test** in plain language, for example:

   > Bay Area pickup soccer. Sign in with Apple. Find a game on Matches (list + map), claim a spot, host one at a public field, edit your profile. There are no payments in the app. If something looks wrong, screenshot it and email me. Do not send passwords.

4. Submit the group for **Beta App Review** the first time. That is a lighter review than the real App Store. It can take a day or two.
5. When testers reply, fix what they find before you submit to the store.

---

## Fill the listing, then submit

On the iOS version in App Store Connect:

1. Paste [store listing copy](store-listing.md).
2. Upload screenshots from [screenshot-shot-list.md](screenshot-shot-list.md).
3. Privacy Policy URL + Support URL — the same two https links as in Xcode.
4. App Privacy: [`docs/legal/app-store-privacy-disclosures.md`](../legal/app-store-privacy-disclosures.md). Tracking = No. Payment Info = No.
5. Age rating: 13+.
6. **App Review Information** (this is what Apple emails / calls):

   | Field | What they want |
   | --- | --- |
   | First name | Auner |
   | Last name | Vasquez |
   | Phone | Your number with country code |
   | Email | An inbox you read that day |
   | Sign-in required | Yes |
   | Demo account | **Sign in with Apple** — reviewers use their own Apple ID. There is no username/password to give them. |
   | Notes | See the block below |
   | Contact URL | optional; Support URL is enough |

**Review notes** (paste):

```
Around The World is a Bay Area pickup soccer listing app. No in-app purchases, no Apple Pay, no ads.

Sign in with Sign in with Apple (Hide My Email is fine). After sign-in you can browse games, claim a spot, host a game inside the nine-county Bay Area, and edit a profile.

Location is while-using-the-app only, to show nearby games and to drop a pin when hosting. Browse still works if the reviewer denies location.

Account deletion: Profile → Settings → Delete account.

Privacy Policy and Support URLs are on this version. Content reporting and blocking are on the game screen.
```

7. Content rights / advertising: you do not run ads. User-generated text is bios and game notes; report/block exists.
8. Version release: **Manually release this version** until you have seen it on TestFlight yourself.
9. **Add for Review** → Submit.

Apple usually replies in a day or a few days. If they reject, the email says why. Forward that to us; do not guess a fix that changes Sign in with Apple or opens the server back up.

---

## Icon, launch screen, privacy strings (already in the project)

You do **not** need to make extra icon sizes. The App Store icon is **1024 × 1024**, RGB, no transparency. It is already in the Xcode asset catalog.

The launch screen is a black splash with the logo mark — same brand as the app, not a gold flash.

The phone already has the location explanation Apple requires: *“Around The World uses your location to find nearby pickup games in the Bay Area.”* Photo picker on edit-profile does not need a photo-library permission string (it does not upload photos in this version).

---

## Do not

- Do not change `com.aroundtheworld.app`.
- Do not put Team IDs, `.p8` keys, JWT secrets, or anon keys into git.
- Do not turn on In-App Purchase or Apple Pay.
- Do not submit a build whose `API_BASE_URL` is `127.0.0.1`.
- Do not skip the public Privacy Policy / Support links. Review rejects without them.