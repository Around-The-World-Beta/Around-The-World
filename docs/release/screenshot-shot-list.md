# Screenshot shot list — two iPhone sizes

Apple will not accept a listing with no screenshots. You take these on **your Mac** (Simulator is fine) or on your iPhone once Xcode runs. We cannot take them from here.

Capture the **same six shots** at **both** sizes below. Upload PNG. No transparency. Portrait. Do not add a fake phone frame — Apple draws its own.

---

## The two sizes

App Store Connect grouping names change. The pixel sizes do not. Use these simulators (Xcode → run destination):

| Upload slot | Simulator to pick | Pixel size (portrait) |
| --- | --- | --- |
| **1 — large iPhone** (Connect may say *6.9-inch* or *Dynamic Island, large display*) | **iPhone 16 Pro Max** (iPhone 15 Pro Max is the same size) | **1320 × 2868** |
| **2 — medium iPhone** (Connect may say *6.3-inch* or *Dynamic Island, medium display*) | **iPhone 16 Pro** (iPhone 15 Pro is the same size) | **1206 × 2622** |

If Xcode only offers 15 Pro / 15 Pro Max, use those. Check the file: Mac Preview → Tools → Show Inspector → pixel dimensions must match the table.

**6.5-inch** (older Max phones, 1284 × 2778) is optional if you already uploaded size 1. Apple will scale. Do not spend time on iPad — this app is iPhone only.

---

## How to capture

1. Start the API on your Mac (`./scripts/run-backend.sh`) so Matches is not empty. A physical iPhone cannot use `127.0.0.1` — for that you need the hosted HTTPS API.
2. Xcode → open `ios/AroundTheWorld/AroundTheWorld.xcodeproj` → pick the simulator in the table → Run.
3. Sign in with Apple. Allow location if the shot is the map or host pin.
4. Simulator menu **Device → Screenshot** (or **⌘S**). On a real iPhone: volume up + side button.
5. Files land on the desktop. Rename them `01-matches-list-69.png`, `01-matches-list-63.png`, and so on.
6. Crop nothing. Do not put them in Keynote with slogans unless you really want marketing frames. Raw app screens are enough for 1.0.

### Make them look like a real product

- Language: English.
- Status bar: no personal notifications, no 12% battery if you can help it. Simulator is usually clean.
- Game titles: real-sounding Bay Area pickup (“Sunday 7v7 at Crocker,” not “Test Game 1”).
- Do not screenshot empty My Games, error banners, debug Settings, or the Friends placeholder.
- Do not screenshot a faded / un-tappable Publish button. If Host still shows that, skip shot 5 until Publish works.

---

## The six shots (do this twice)

Order on the store page is the order people swipe. Put them in this order.

### 1 — Matches, list

**What to show:** the Matches tab. Date strip across the top. List / Map toggle on List. A few game cards with venue, time, skill, spots, Free or a small field price.

**Caption you can type under it in Connect (optional):** Find pickup across the Bay Area.

### 2 — Matches, map

**What to show:** same tab, Map selected. Pins on real Bay Area fields. Not a blank ocean.

**Caption:** See the field before you go.

### 3 — Filters

**What to show:** the Filters sheet covering the screen (Preferred time, Distance, Game difficulty). Gold “See N Games” at the bottom.

**Caption:** Day, distance, and how serious.

### 4 — Game + Claim Spot

**What to show:** one game open. Venue, kickoff, format, host, notes if they look decent, gold **Claim Spot**. Not a full game. Not the report sheet.

**Caption:** Claim a spot. Waitlist if it is full.

### 5 — Host

**What to show:** the + screen with a Bay Area venue searched or a pin on a field, form filled enough that it looks like a real listing (title, time, format, skill). Gold **Post Game** enabled — not greyed out.

**Skip this shot** only if Post Game is missing or faded. A broken host screen on the App Store is worse than five shots.

**Caption:** Host for free. Pin a Bay Area field.

### 6 — Profile (or My Games)

**Prefer Profile** if it shows your name, city, position, bio. **My Games** is the backup if Profile is still thin — show at least one game you hosted or claimed.

**Caption:** Your games, your profile. Sign in with Apple.

Optional seventh if you have room: the Sign in with Apple screen, black background, the real Apple button. Do not add an eighth of Settings / Delete account / Friends.

---

## After you have the files

In App Store Connect → your app → the iOS version → **Previews and Screenshots**:

1. Drop the 1320 × 2868 set into the large iPhone slot.
2. Drop the 1206 × 2622 set into the medium iPhone slot.
3. Same order in both slots.
4. You can add an app preview video later. Not required for 1.0.