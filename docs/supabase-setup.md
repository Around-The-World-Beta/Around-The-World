# Supabase setup — replaces Step 1.3 of the launch plan

**Read this instead of Step 1.3 in the App Store Launch Plan PDF.** That step tells you to
paste three SQL files into Supabase in order. Do not do that. Two of those files both tried
to create a table called `profiles` with different shapes, and because the second one said
"create only if it doesn't already exist", it would have done nothing at all and shown you
no error. You would have ended up with a database the app cannot use and no sign that
anything went wrong. Those files have been deleted and replaced with the one file below.

You do not need to be an engineer to follow this. It is copy, paste, and read the result.
Each step says what it does and how to tell it worked.

**Time:** about 20 minutes, plus a few minutes of waiting while Supabase starts your project.

---

## Before you start

Have the repo on your Mac, so you can open the SQL files:

```sh
cd path/to/your/repo
git pull origin main
```

The files you will use are in `supabase/migrations/`.

Also create the secrets file from Step 0.1 of the launch plan if you haven't —
`AroundTheWorld-Launch/SECRETS-DO-NOT-COMMIT.txt`. You will be copying four values into it.

---

## Step 1 — Create the Supabase project

1. Go to <https://supabase.com> and sign in (or sign up — free).
2. Click **New project**.
3. Name it `around-the-world`.
4. Generate a strong database password and **paste it into your secrets file right now**,
   labelled `DB_PASSWORD`. Supabase will not show it to you again.
5. Region: **West US (North California)** or the closest US West option. Your users are in
   the Bay Area, and a closer database means a faster app.
6. Click **Create new project** and wait. It takes a few minutes.

**How you know it worked:** the project dashboard stops saying "Setting up project" and the
status indicator turns green.

---

## Step 2 — Copy your four secrets

Still in the Supabase dashboard:

1. **Project Settings → API**. Copy these three:
   - **Project URL** → save as `SUPABASE_URL`
   - **anon public** key → save as `SUPABASE_ANON_KEY`
   - **JWT Secret** → save as `SUPABASE_JWT_SECRET`
2. **Project Settings → Database → Connection string → URI**. Copy it → save as
   `DATABASE_URL`. It contains the text `[YOUR-PASSWORD]` — replace that with the password
   from Step 1.

Your secrets file should now have five entries:

```
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_JWT_SECRET=...
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.xxxxxxxxxxxx.supabase.co:5432/postgres
DB_PASSWORD=...
```

**How you know it worked:** all five lines are filled in, and `DATABASE_URL` no longer
contains the words `YOUR-PASSWORD` in brackets.

> **A note on the password in that URL.** If your password contains any of `@ : / ? # [ ] %`
> the connection will fail in a confusing way. If so, generate a new password in
> **Project Settings → Database → Reset database password** using only letters and numbers.
> It saves an hour of debugging.

**Do not paste these values into a chat message.** Send them through a password manager
share, 1Password, or an encrypted note.

---

## Step 3 — Only if you already ran the old SQL files

Skip this step entirely on a brand-new project. **Most people skip it.**

Run this only if you previously pasted `202607250001_auth_profiles.sql` into a Supabase
project and you want to keep using that same project.

1. In Supabase, open **SQL Editor** → **New query**.
2. Open `supabase/migrations/202611060000_reset_legacy_prototype.sql` from the repo, copy
   all of it, paste it in.
3. Click **Run**.

This deletes the old prototype's `profiles`, `user_roles`, and `audit_events` tables. **It
deletes the data in them.** That is fine if the only thing in there is your own test data,
which is the only situation this step is for. It does not touch your logins — `auth.users`
is left alone.

**How you know it worked:** the result says `Success. No rows returned`. You may also see
grey "NOTICE" lines saying something "does not exist, skipping" — those are normal and
mean there was nothing there to remove.

---

## Step 4 — Create the app's tables

1. In Supabase, open **SQL Editor** → **New query**.
2. Open `supabase/migrations/202611060001_atw_core_schema.sql` from the repo, copy the
   whole file, paste it in.
3. Click **Run**.

This creates the five tables the app needs — `users`, `profiles`, `games`, `participants`,
`friendships` — plus a small bookkeeping table the server uses to remember that these
already exist. It also switches on a protection called row level security, explained in
Step 6.

**How you know it worked:** the result says `Success. No rows returned`.

**If you see a red error instead, read it — it is written for you:**

| Error says | What to do |
|---|---|
| "Legacy prototype `profiles` table detected" | Go back and do Step 3, then run this again. |
| "A `users` table already exists" | This file has already been run on this project. Skip to Step 5. |

The file is deliberately not safe to run twice — it stops with a clear message rather than
half-applying. If something goes wrong, nothing is left in a partial state.

---

## Step 5 — Check it worked

In the SQL Editor, run this:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

**You should see exactly six rows, in this order:**

```
_fluent_migrations
friendships
games
participants
profiles
users
```

If you see `user_roles` or `audit_events` in that list, the old prototype tables are still
there — do Step 3, then Step 4 again.

You can also click **Table Editor** in the sidebar and see the same six tables. They will
all be empty. That is correct — nobody has signed up yet.

---

## Step 6 — Understand the warning Supabase will show you

Supabase may display a security advisor notice about your tables. Here is what is going on,
because it is worth understanding rather than dismissing.

Supabase automatically publishes everything in your database through its own web API, and
that API can be reached using the `SUPABASE_ANON_KEY` — a key that ships *inside the iPhone
app*, where anyone determined enough can read it. Left alone, that would mean anyone could
read and change your users, games, and profiles directly, going straight around our server
and all of its rules.

Step 4 switched on **row level security** on all five tables, with no exceptions granted to
anybody. That closes the door completely: nothing can reach those tables through Supabase's
own API. Our server is unaffected, because it connects as the database's owner, and owners
are allowed past that door.

**What this means for you:** if an engineer ever proposes "adding a policy" to one of those
tables, that is a decision worth questioning, not a routine change. The app is designed to
talk only to our own server, never to the database directly.

---

## Step 7 — What happens next (and what you do not need to do)

**You do not need to create the tables again, ever.** Step 4 also told the server that this
schema is already in place, so the server will not try to recreate it.

The first time the server starts against this database you will see it run exactly one thing,
named `SeedDemoData`. That is the demo Bay Area listings, and it only actually inserts
anything if someone sets `SEED_DEMO=1`. On your real production database, leave `SEED_DEMO`
unset and it does nothing.

Two notes for later:

- **Seeding happens once, on the very first start.** If you want the demo Bay Area listings
  on a *staging* database, set `SEED_DEMO=1` before the first time the server starts against
  it. Setting it afterwards has no effect, because the server records that step as done.
- **Use two separate Supabase projects** — one for staging, one for production — rather than
  seeding fake games into the database real people use. Repeat this guide to create the
  second one.

Deploying the server itself, and pointing it at this `DATABASE_URL`, is the next piece of
work. It is not something you do by hand.

---

## If you get stuck

Note the step number and what the screen said, and send both. Do not try the next step
until the current one shows the result described above — that is how the original
Step 1.3 problem went unnoticed.

---

## For engineers

The Swift migrations in `Backend/Sources/App/Migrations/` are the source of truth for this
schema. `202611060001_atw_core_schema.sql` is a transcription of what they produce on
Postgres, verified by applying each to an empty Postgres 16 database and diffing
`pg_dump --schema-only` output — the two are byte-identical.

**If you change a Swift migration, update the SQL file in the same commit**, and add the new
migration's name to the `_fluent_migrations` insert at the bottom. Otherwise a hand-applied
database and a server-applied one diverge, which is the exact failure this replaced.

The two also agree on what is *not* in the database: there are no CHECK constraints on skill
tiers, formats, or statuses. `APIValidation` in `Backend/Sources/App/DTOs/Validation.swift`
is the single place that decides what those may be.
