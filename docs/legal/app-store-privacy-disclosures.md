# App Store Connect — Privacy (nutrition labels)

**For:** Auner, to type into App Store Connect → your app → App Privacy.

This is a filled-in draft for **Around The World 1.0** as the code stands today: native iPhone app, Sign in with Apple, Bay Area pickup soccer, **no payments**, no ads, no analytics SDK.

Do not claim you collect Payment Info. You do not.

Apple’s labels change wording slightly over time. Match the closest option. If a screen asks “is this used to track you across other companies’ apps and websites?” the answer is **No** for everything below.

---

## Tracking

**Do you or your third-party partners use data from this app to track users?**  
**No.**

---

## Data types

### Contact Info

| Type | Collect? | Linked to identity? | Used for tracking? | Purposes to check |
| --- | --- | --- | --- | --- |
| **Name** | Yes | Yes | No | App Functionality |
| **Email Address** | Yes (from Sign in with Apple; may be Hide My Email) | Yes | No | App Functionality |
| Phone Number | **No** | | | |
| Physical Address | **No** | | | |

Name and email come from Apple when the person signs in. We store them on the account.

### Location

| Type | Collect? | Linked to identity? | Used for tracking? | Purposes to check |
| --- | --- | --- | --- | --- |
| **Precise Location** | Yes, **only while using the app** | Yes (when they host, the field pin is saved on that game) | No | App Functionality |
| Coarse Location | Only if Apple groups it with the above — you can leave Coarse **No** if Precise is already Yes | | | |

Purpose string on the phone: *“Around The World uses your location to find nearby pickup games in the Bay Area.”*

We do **not** collect location in the background. We do **not** keep a live trail of the user.

### User Content

| Type | Collect? | Linked to identity? | Used for tracking? | Purposes to check |
| --- | --- | --- | --- | --- |
| **Other User Content** | Yes — bios, game notes, reports | Yes | No | App Functionality |
| Photos or Videos | **No** (the edit-profile picker is preview-only; nothing is uploaded) | | | |
| Customer Support | Yes, if they email you from the support page — that mail lives in your inbox, not in the app database | Optional: you can leave this **No** if you only want in-app data listed | No | |

### Identifiers

| Type | Collect? | Linked to identity? | Used for tracking? | Purposes to check |
| --- | --- | --- | --- | --- |
| **User ID** | Yes — the Around The World account id, plus the Sign in with Apple / Supabase id | Yes | No | App Functionality |
| Device ID | **No** | | | |

### Purchases — **do not enable**

| Type | Collect? |
| --- | --- |
| Purchase History | **No** |
| **Payment Info** | **No** |

There is no Apple Pay, no IAP, no Stripe. Price on a game card is “pay the host at the field.”

### Other types — leave **No** unless you later add them

- Health & Fitness — No  
- Financial Info — No  
- Sensitive Info — No  
- Contacts — No  
- Browsing History — No  
- Search History — No  
- Usage Data / Product Interaction (analytics) — **No** in 1.0 (no analytics SDK)  
- Diagnostics / Crash Data — **No** unless you later turn on Xcode Cloud / a crash tool  
- Advertising Data — No  

---

## Age rating (related, not on the Privacy screen)

When App Store Connect asks for an age rating, pick a rating that matches **13+**: user-generated text (bios and notes), social-ish meetup listings, no unrestricted web, no simulated gambling, no horror. You can set the “unrestricted web access” answer to No.

The profile form currently *allows* typing an age as low as 4. The product is still for 13+. If Apple asks, say the app is 13+ and under-13s should not create an account.

---

## Privacy policy URL

App Store Connect also needs the **public Privacy Policy URL**. That is the page you publish from `privacy-policy.md`. Paste it here in App Store Connect **and** into Xcode as `PRIVACY_POLICY_URL`.

They also want a **support URL**. That is `support.md`.
