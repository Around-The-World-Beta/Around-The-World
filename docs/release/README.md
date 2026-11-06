# Release — what you do in Apple’s sites

This folder is for **Auner**, not for an engineer. Nobody can upload a build to App Store Connect from this repo. That has to happen on your Mac, signed with your Apple team.

Start here, in order:

1. [Store listing copy](store-listing.md) — paste into App Store Connect (name, subtitle, description, keywords, What’s New).
2. [Screenshot shot list](screenshot-shot-list.md) — what to capture on the iPhone once Xcode runs, at the two sizes Apple wants.
3. [Signing, TestFlight, and submit](signing-and-testflight.md) — Team ID, Sign in with Apple, privacy URLs, contact details, archive, TestFlight, submit.

Legal pages you publish first (Privacy Policy + Support) live in [`docs/legal/`](../legal/README.md). Paste those two https links into Xcode **and** App Store Connect.

**Identifier:** `com.aroundtheworld.app` — do not change it.  
**No payments** in this version. **Bay Area only.** Native iPhone app.

If your Apple Team ID has not arrived yet, stop at creating the App Store Connect app record and come back. Leave the team field empty in Xcode until Apple shows you a real team.