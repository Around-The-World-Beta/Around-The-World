# Railway setup — put the server on HTTPS

**Read this when you are ready to put the API on the internet.** Do not start
until the database SQL in [`supabase-setup.md`](./supabase-setup.md) has
already succeeded, and do not deploy an older copy of the repo that predates
the lock-down. The iPhone still cannot sign in until Workstream 2; this step
only gives the phone a real address to talk to.

You do not need to be an engineer. It is create a project, paste six names,
wait for a green check, then open a URL. Each step says what it does and how
to tell it worked.

**Do not paste secrets into a chat message.** They stay in your
`SECRETS-DO-NOT-COMMIT.txt` file and in the Railway Variables box.

**Time:** about 25 minutes the first time, plus a few minutes while Railway
builds the server (the first build is the slow one).

---

## Before you start

1. You have a Railway account with a payment method. (The free trial may
   work for a first deploy; a card is still required.)
2. You have a Supabase project whose SQL check showed the six tables in
   [`supabase-setup.md`](./supabase-setup.md) Step 5.
3. Your secrets file already has `SUPABASE_URL`, `SUPABASE_JWT_SECRET`, and
   `DATABASE_URL`.
4. In GitHub, this repository is `Around-The-World-Beta/Around-The-World`.

**Which git branch to deploy**

Deploy a branch that **includes the lock-down**. That is this workstream’s
branch (`cursor/w3-deploy-8675`) until it is merged, then `main`. If Railway
is pointed at today’s `main` before that merge, you would put the old
unauthenticated server on the internet. Do not do that.

---

## Step 1 — Create the production project

1. Go to <https://railway.com> and sign in.
2. Click **New project**.
3. Choose **Empty project**. Do **not** click **Add PostgreSQL** or
   **Database**. The database already lives in Supabase. A second database
   on Railway would be a different, empty copy the app does not use.
4. Name the project `around-the-world`.
5. Region: pick **US West** if Railway offers a region, so it sits near the
   Bay Area and near your Supabase project.

**How you know it worked:** you are looking at an empty project canvas with
no database box on it.

---

## Step 2 — Add the API service from GitHub

1. In the project, click **New** → **GitHub Repo**.
2. Grant Railway access to `Around-The-World-Beta/Around-The-World` if it
   asks.
3. Select that repository.
4. Open the new service → **Settings**.
5. **Source → Branch:** set it to `cursor/w3-deploy-8675` until this work is
   on `main`. After you merge, switch the branch to `main`.
6. **Root directory:** leave as `/` (the Dockerfile is at the repo root).
7. **Watch paths / wait for CI:** leave the defaults.

Railway should notice the `Dockerfile` at the top of the repo and build
from it. If Settings → Build shows **Builder: Dockerfile**, that is the
right one. If it shows Nixpacks or Railpack instead, set
**Dockerfile path** to `Dockerfile`.

**How you know it worked:** the service exists and the builder is Dockerfile.
The first deploy will fail until you paste variables in Step 4. That is
expected — do not worry about a red deploy yet.

---

## Step 3 — Give it a public HTTPS address

1. Still in the service, open **Settings → Networking**.
2. Click **Generate domain**.
3. Copy the URL it shows. It looks like
   `https://something.up.railway.app`.
4. Paste it into your secrets file as `API_BASE_URL`. No trailing slash.

Railway terminates HTTPS for you. You do not upload a certificate.

**How you know it worked:** the domain is listed, and it starts with
`https://`. You have not opened it in a browser yet — wait until Step 6.

---

## Step 4 — Paste variables (production)

Open the service → **Variables**. Add **exactly these names**. Click **New
variable** for each row. Values come from your secrets file, never from
chat.

### Required — the server will not start without these

| Name | Paste this |
| --- | --- |
| `SUPABASE_JWT_SECRET` | Supabase → **Project Settings → API → JWT Secret** |
| `SUPABASE_URL` | Supabase → **Project Settings → API → Project URL** (`https://xxxxx.supabase.co`, no trailing slash) |
| `DATABASE_URL` | Supabase → **Project Settings → Database → Connection string → URI**, with the real password in place of `[YOUR-PASSWORD]` |

### Leave unset (Railway fills them, or the process has a safe default)

| Name | Why |
| --- | --- |
| `PORT` | Railway sets this. Do not type a number. |
| `HOST` | The container already listens on `0.0.0.0`. |
| `SEED_DEMO` | **Do not add this on production.** Demo games are staging-only. |
| `VAPOR_ENV` | Leave unset so the process runs as `production`. |

### Optional — only if you have a reason

| Name | Default if unset | When to set it |
| --- | --- | --- |
| `DATABASE_TLS` | `require` | Leave unset. |
| `CORS_ALLOWED_ORIGINS` | empty (no website may call the API) | Leave unset. The iPhone does not use CORS. Do not set `*`. |
| `RATE_LIMIT_PER_MINUTE` | `120` | Leave unset unless the API starts returning HTTP 429 to real phones. |

**`DATABASE_URL` details that trip people up**

- The password in the URI must be the real database password, not the
  placeholder `[YOUR-PASSWORD]`.
- If the password contains `@ : / ? # [ ] %`, reset it in Supabase to
  letters and numbers only, then update `DATABASE_URL` here and in your
  secrets file.
- Prefer the **direct** URI on port `5432` (`db.<ref>.supabase.co`) or the
  **Session pooler** URI (also port `5432`, host contains `pooler`). Do
  **not** use the Transaction pooler on port `6543` — this server keeps
  connections open and that mode breaks them.
- If the deploy logs say it cannot connect, or mention IPv6, switch
  `DATABASE_URL` to the Session pooler URI from the same Supabase
  **Connection string** panel.

**How you know it worked:** the Variables list shows the three required
names. Railway hides the values; you should still see the names.

---

## Step 5 — Health check

1. Service → **Settings → Deploy**.
2. **Healthcheck path:** `/health`
3. **Healthcheck timeout:** `120` seconds (first boot runs database
   migrations).

If `railway.toml` in the repo already filled these in, you will see
`/health` and can skip typing them.

**How you know it worked:** the healthcheck path is exactly `/health`,
starting with a slash and with no trailing slash.

---

## Step 6 — Deploy and confirm it is alive

1. Trigger a deploy if one is not already running (**Deploy** / push is
   enough).
2. Wait until the deployment is **Success** and the healthcheck is green.
   The first image build compiles Swift and takes several minutes. Later
   deploys are faster.
3. On your Mac, in Terminal:

```sh
curl https://YOUR-SERVICE.up.railway.app/health
```

Replace the host with the domain from Step 3. You should see JSON with
these three fields (order may vary):

```json
{"status":"ok","service":"around-the-world-api","database":"ok"}
```

4. Then, from this repo:

```sh
./scripts/verify-deploy.sh https://YOUR-SERVICE.up.railway.app
```

That script checks `/health`, the public Bay Area county list, public
browse, and the same unauthenticated attacks the lock-down closed. Every
private path should be **401**. Browse may return `[]` — production has
no demo games, and that is correct.

**How you know it worked:** `curl` returns that JSON, and
`verify-deploy.sh` prints `Deploy looks good.`

**If `/health` says `"database":"error"`** the process is up but it cannot
reach Supabase. Re-read the `DATABASE_URL` notes in Step 4. Do not add
`SEED_DEMO` to “fix” an empty game list.

**If the iPhone still cannot sign in:** that is Workstream 2. This
workstream only puts the locked-down server on HTTPS.

---

## Step 7 — Staging (separate database, demo games allowed)

Production stays empty until real people host. For testers you want the
Bay Area demo listings, on a **different** Supabase project, never on the
production one.

1. Repeat [`supabase-setup.md`](./supabase-setup.md) for a second project
   named `around-the-world-staging`. Save its four values with `STAGING_`
   in front in your secrets file so you cannot mix them up.
2. In the same Railway project, create a **staging** environment
   (Railway → **Environments → New environment**, duplicate from
   production, name it `staging`), **or** create a second Railway project
   named `around-the-world-staging`. Either is fine; two environments in
   one project is less to keep track of.
3. Generate a **second** HTTPS domain. Save it as
   `STAGING_API_BASE_URL`.
4. Paste the **staging** Supabase values into that environment’s
   Variables, same three required names as Step 4.
5. Then add two extras that production must not have:

| Name | Value |
| --- | --- |
| `VAPOR_ENV` | `staging` |
| `SEED_DEMO` | `1` |

Set `SEED_DEMO=1` **before** this environment’s first successful boot.
Seeding runs once. Setting it later does nothing.

6. Health check is still `/health`. Confirm with:

```sh
curl https://YOUR-STAGING.up.railway.app/health
./scripts/verify-deploy.sh https://YOUR-STAGING.up.railway.app
```

Staging browse should list demo games across all nine counties. Production
browse should not.

**How you know it worked:** two HTTPS URLs, two different
`DATABASE_URL` values, only staging has `SEED_DEMO` and `VAPOR_ENV=staging`.

---

## Step 8 — Point the iPhone at the HTTPS URL

The app already reads `API_BASE_URL`. Nothing else in the phone talks to
the server.

**Xcode Run on the Simulator (Debug)** keeps talking to your Mac:

```
http://127.0.0.1:8081
```

That is set in two places on purpose: `ios/AroundTheWorld/Config/Debug.xcconfig`
and the scheme environment variable `API_BASE_URL`. Leave them for local
work.

**To hit staging from the Simulator** without a rebuild of the URL into
the Info.plist: in Xcode, Product → Scheme → Edit Scheme → Run →
Arguments → Environment Variables, set `API_BASE_URL` to your staging
`https://…` URL (no trailing slash).

**TestFlight / a real iPhone / Archive** uses Release. Open
`ios/AroundTheWorld/Config/Release.xcconfig` and set:

```
API_BASE_URL = https:/$()/YOUR-SERVICE.up.railway.app
```

The odd `https:/$()/` spelling is required: in an xcconfig file, `//`
starts a comment, so a normal `https://` would silently drop the rest of
the line. No trailing slash. Commit that one-line change once you have
the real domain — a public API URL is not a secret.

Until you do that, a TestFlight build still points at `127.0.0.1` and
will not see any games on a physical phone.

Settings in the app shows the URL it is actually using, labelled
`API_BASE_URL`.

`SUPABASE_URL` and `SUPABASE_ANON_KEY` on the phone are for Sign in with
Apple in Workstream 2. They are not required for this step. Browse of
public games only needs `API_BASE_URL`.

---

## What you should not do

- Do not add a Railway PostgreSQL plugin.
- Do not set `SEED_DEMO` on production.
- Do not set `CORS_ALLOWED_ORIGINS` to `*`.
- Do not deploy `main` until the lock-down and this deploy branch are
  merged into it.
- Do not put `SUPABASE_JWT_SECRET` or `DATABASE_URL` in the iPhone app,
  in git, or in chat.
- Do not turn on payments, and do not remove the Bay Area coordinate
  check. Neither belongs in this deploy.

---

## If you get stuck

Note the step number and what the screen or Terminal said, and send both.
Useful clues:

| What you see | What to do |
| --- | --- |
| Deploy logs: `SUPABASE_JWT_SECRET is not set` | Step 4 — that variable is missing on this environment. |
| Deploy logs: `DATABASE_URL is not set` | Step 4. Confirm you did not add a Railway database instead. |
| `/health` → `"database":"error"` | Wrong `DATABASE_URL`, password with special characters, or Transaction pooler (port 6543). |
| Deploy never becomes green | Healthcheck path is not `/health`, or the first Swift build is still running. |
| `curl` works, iPhone does not | Release.xcconfig still has `127.0.0.1`. Step 8. |
| Browse is empty on production | Expected. Host games after sign-in (W2 + W4), or use staging with `SEED_DEMO=1`. |
| HTTP 401 on `/api/v1/users` | Expected. The lock-down is working. |

---

## For engineers

- `Dockerfile` at the repo root builds `Backend/` with Swift 6.0.3 and
  starts `./App serve --env production --hostname 0.0.0.0`. `PORT` comes
  from the platform.
- Hosted boots refuse to start without `SUPABASE_JWT_SECRET`,
  `SUPABASE_URL`, and `DATABASE_URL`. They never fall back to SQLite or
  the local JWT secret.
- `SEED_DEMO` is ignored when `VAPOR_ENV=production` (the container
  default). Staging must set `VAPOR_ENV=staging`.
- `GET /health` pings the database. Railway should not receive traffic
  until it returns `200`. `/health` is excluded from the rate limiter so
  probes cannot starve real clients.
- `railway.toml` sets `healthcheckPath` and the Dockerfile builder.
  Railway’s newer services may ignore Config as Code; the dashboard steps
  above are then the source of truth. Do not introduce
  `.railway/railway.ts` that provisions a Railway Postgres.
- Auth contract: [`auth-contract.md`](./auth-contract.md).
