# Corrections to the App Store Launch Plan

The launch plan PDF (`Around-The-World-App-Store-Launch-Plan.pdf`) is still the right
document to work through. Two of its steps are wrong about this repository. Both would cost
real time or real money to undo, so they are corrected here.

Everything else in the plan stands as written.

---

## Correction 1 — the app's identifier

**The plan says**, in Step 1.2, to register the Bundle ID `app.aroundtheworld.ios`.

**Use `com.aroundtheworld.app` instead.** That is the identifier already set in the Xcode
project (`ios/AroundTheWorld/project.yml` and the generated `project.pbxproj`), so using it
means nothing in the code has to change.

### Why this matters more than it looks

**A Bundle ID cannot be changed once you have registered it with Apple and shipped a
build.** It is the permanent identity of the app: it ties together your App Store listing,
Sign in with Apple, push notification certificates, and every user's installed copy.
Changing it later means a new app record, a new listing, and existing users being unable to
update — in practice, starting over.

### This is the last cheap moment to change it

Nothing has been registered with Apple yet, so right now switching is a two-line edit. If
you want a different identifier — for example `com.aroundtheworld.atw`, or something tied to
a domain you own — **say so before you complete Step 1.2 of the plan.** After that it is
permanent.

A reverse-domain name you control is the convention. `com.aroundtheworld.app` is fine
whether or not you own `aroundtheworld.com`; Apple does not verify domain ownership. But if
you do plan to buy a domain for the privacy policy and support pages anyway, it is worth
deciding both at the same time.

### Unrelated, so don't be confused by it

The iOS app logs diagnostics under the label `app.aroundtheworld.boot`. That is a logging
category, not an app identifier, and it has nothing to do with this. Leave it alone.

---

## Correction 2 — Step 1.3, the Supabase SQL

**The plan says** to run three SQL files into Supabase in this order:

```
supabase/migrations/202607250001_auth_profiles.sql
supabase/migrations/202608080001_vapor_core_tables.sql
supabase/migrations/202608080002_profile_age.sql
```

**Do not do this.** Those three files have been deleted from the repository.

The first and second files both created a table called `profiles`, with incompatible shapes
— the first keyed on Supabase's login records, the second on our own user table. Because the
second file used `create table if not exists`, running them in this order would have *done
nothing* for that table and reported **no error at all**. You would have finished Step 1.3
believing it succeeded, and the server would then have failed later for reasons that look
unrelated to the database.

The plan's own warning on that step — "If a SQL statement errors because a table already
exists, stop and note it" — would not have helped, because there would have been no error
to notice.

**Follow [`supabase-setup.md`](./supabase-setup.md) instead.** It is one file to run instead
of three, it refuses to run rather than half-applying if anything is already in the way, and
every step tells you how to confirm it worked.

If you already ran the old files against a Supabase project, that guide's Step 3 cleans it
up — you do not need to start a new project.
