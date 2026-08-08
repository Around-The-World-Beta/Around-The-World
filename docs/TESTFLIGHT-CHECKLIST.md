# TestFlight checklist — Bay Area beta

## Done in this pass
- [x] Launch hang root cause fixed (URLSession waitsForConnectivity + deferred location)
- [x] Roster-derived browse visibility (`joinedCount < capacity`)
- [x] Seed data off by default; empty states for real Supabase data
- [x] Settings + EN/ES localization layer
- [x] Native MapKit browse + host search/pin-drop
- [x] API keys read from env / Info.plist build settings (none committed)

## Blocked on you
- [ ] Final logo file (swap App Icon / splash / nav BrandHeader)
- [ ] Lovable profile screenshots/link (rebuild profile layout)
- [ ] Real `SUPABASE_URL` + `SUPABASE_ANON_KEY` + `DATABASE_URL`
- [ ] `GOOGLE_PLACES_API_KEY` if venue photos are in scope for beta
- [ ] Apple Developer team + App Store Connect app record

## Still missing for testers next week
1. **Auth** — Sign in with Apple / Supabase Auth + JWT middleware. Claim Spot / My Games / Profile stay empty without a `currentUserID`.
2. **Hosted API** — Deploy Vapor (or Fly/Railway) against Supabase Postgres; point iOS `API_BASE_URL` at HTTPS (ATS).
3. **Real Bay Area listings** — Create host accounts + games in Supabase (or temporarily `SEED_DEMO=1` on a staging DB).
4. **Signing** — Set `DEVELOPMENT_TEAM`, archive, upload to TestFlight; add external/internal testers.
5. **Privacy** — Privacy Nutrition Labels, location purpose string review, Privacy Manifest if required by SDKs.
6. **Push / email** — Optional for beta; not implemented.
7. **Publish host flow** — Location picker is ready; create-game API call still needs signed-in `hostUserId`.
8. **Physical device API** — Simulator uses `127.0.0.1`; devices need LAN IP or hosted URL.
