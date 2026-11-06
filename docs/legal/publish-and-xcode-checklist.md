# Publish the legal pages + Xcode checklist

You do not need to write code. This is the list for your Mac and for Apple.

The app **cannot invent a live website**. The Privacy Policy and Support text live in this folder. You publish them somewhere public, then paste the two https links into Xcode.

---

## 1. Publish two public pages

You need two links that open on your iPhone **without signing in**:

1. Privacy Policy — text in [`privacy-policy.md`](privacy-policy.md)
2. Support / Help — text in [`support.md`](support.md)

Optional third: Terms — [`terms.md`](terms.md). Settings has a Terms row. If you skip it, that row stays “not published yet.”

### Easiest: Notion

1. Open [notion.so](https://www.notion.so) and make a new page called **Around The World — Privacy Policy**.
2. Open `privacy-policy.md` in this repo. Copy everything **below** the first `---` line (the policy itself, not the “this is the text to publish” note).
3. Paste into Notion. Replace **[add your email here when you publish this page]** with the email you actually read.
4. Share → **Share to web** → turn it on → copy the public link. Open that link in Safari on your phone to confirm it loads.
5. Repeat for Support (`support.md`).
6. Keep both links in a note. You will paste them in two places (Xcode and App Store Connect).

### Also fine: GitHub Pages or Carrd

Same idea: public https page, no login, your email on the page. GitHub: repo Settings → Pages. Carrd: a simple one-page site. Do not use a Google Doc that asks people to request access.

---

## 2. Paste the links into Xcode

1. Open `ios/AroundTheWorld/AroundTheWorld.xcodeproj`.
2. Select the **AroundTheWorld** target → **Signing & Capabilities**
   - **Automatically manage signing**
   - **Team:** your Apple Developer team
   - **Bundle Identifier:** `com.aroundtheworld.app` (do not change this)
   - Confirm **Sign in with Apple** is listed
3. Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables. Add or fill:

| Name | Value |
| --- | --- |
| `API_BASE_URL` | `http://127.0.0.1:8081` on Simulator |
| `SUPABASE_URL` | your Supabase project URL |
| `SUPABASE_ANON_KEY` | your anon key |
| `PRIVACY_POLICY_URL` | the https Privacy Policy link from step 1 |
| `SUPPORT_URL` | the https Support link from step 1 |
| `TERMS_URL` | optional Terms link |

Leave a legal URL **blank** until the page is really live. The Settings row will say it is not published yet instead of opening a broken website.

4. Pick an iPhone simulator (iOS 17+) or your iPhone.
5. Start the API on your Mac: `./scripts/run-backend.sh`
6. Press **Run**.

---

## 3. What to tap in the app (this work)

Linux cannot compile SwiftUI. Please run this on your Mac.

1. **Signed out:** Profile → Settings → Help, Terms, Privacy. If you have not pasted the links yet, you get a short message, not a crash, and not a fake website.
2. Sign in with Apple.
3. Profile → Edit → bio. You cannot type past **200** characters. Save still works.
4. Host tab → notes. You cannot type past **500** characters. Post still works.
5. Open a game that is **not yours** → scroll under Claim Spot.
   - **Report this game** — pick a reason, send. You should see a thanks message (needs the server safety PR).
   - **Block host** — confirm. You should see a confirmation. That host’s games should disappear from Matches after you go back once the server safety PR is running.
6. Settings → **Delete account** → confirm. You should be signed out. Profile goes back to the empty + Sign in state. That is the Apple-required deletion path. It calls the server (`DELETE /api/v1/me`) and then forgets the session on the phone.

Do not add payments. Do not change the bundle id.

---

## 4. App Store Connect (when you submit)

1. Paste the same Privacy Policy URL on the app’s App Store Connect page.
2. Paste the same Support URL.
3. Fill **App Privacy** using [`app-store-privacy-disclosures.md`](app-store-privacy-disclosures.md).
4. Age rating: treat the app as **13+**.

---

## 5. Secrets

Never put real keys in the git repo, in a chat, or in a screenshot.

Real values belong in:

- Xcode scheme environment variables (on your Mac)
- Railway / hosting environment variables
- A secrets file that is **not** committed (see `.gitignore` — `.env` is ignored)

If a key ever landed in git, treat it as leaked: rotate it in Supabase / Apple / Railway, then put only the new value in the private place. There is a scan script: `scripts/scan-secrets.sh`.
