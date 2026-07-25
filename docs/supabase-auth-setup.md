# Supabase authentication setup

The application code is environment-safe when these values are absent. Live
account creation remains disabled until each environment is configured.

Create separate Supabase projects for development and staging. Production is
created only after staging passes the Milestone 2 gate.

## 1. Apply the database migration

Apply `supabase/migrations/202607250001_auth_profiles.sql` to the development
project, inspect the resulting tables and policies, then repeat in staging.

The migration:

- creates private-by-default profiles, roles, and audit events;
- enables row-level security on every exposed table;
- prevents users from assigning their own roles;
- creates a profile and `user` role when an Auth user is created;
- cascades profile and role deletion when the Auth account is deleted.

## 2. Configure email authentication

In Authentication settings:

- keep email confirmation required;
- set the minimum password length to 12;
- enable leaked-password protection;
- keep refresh-token rotation enabled;
- use a short access-token lifetime appropriate for the platform;
- configure a production-grade SMTP provider before external beta;
- customize verification and recovery emails without revealing whether an
  unregistered address exists.

Set the Site URL and exact allowed redirect URLs. Development should include:

- `http://localhost:3000/auth/callback`

Staging and production must use their own HTTPS origins. Do not use broad
wildcard redirects in production.

## 3. Configure bot protection and limits

Create separate Cloudflare Turnstile widgets for development/staging and
production. Configure the Turnstile secret in Supabase Auth CAPTCHA settings.
Place only the public site key in `VITE_TURNSTILE_SITE_KEY`.

Review Supabase Auth rate limits for:

- password sign-in;
- signup and verification email;
- password recovery;
- token refresh;
- MFA challenge and verification.

Rate-limit game and location APIs separately in later milestones.

## 4. Configure Sign in with Apple

After Apple Developer enrollment:

- create the permanent App ID/bundle ID;
- enable Sign in with Apple;
- create the web Services ID and return URL required by Supabase;
- generate and securely store the Apple `.p8` signing key;
- enable the Apple provider in Supabase;
- schedule Apple client-secret rotation before expiry.

Never commit the `.p8` file or Apple client secret.

## 5. Add environment values

Copy `.env.example` to `.env.local` and set:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (server only)
- `AUTH_SITE_URL`
- `VITE_TURNSTILE_SITE_KEY`

Hosted values belong in the hosting provider's secret store. Never place the
service-role key in a `VITE_` variable or browser bundle.

## 6. Milestone 2 live verification

Run these tests in both development and staging:

- create and verify a new email account;
- verify duplicate signup does not disclose account existence;
- reject weak passwords and repeated login attempts;
- sign in, refresh, expire, and revoke sessions;
- reset a password using the PKCE callback;
- enroll, challenge, and remove TOTP MFA;
- confirm an enrolled account cannot bypass MFA;
- update a profile and verify another user cannot read or update it;
- sign out locally and globally;
- delete email and Apple accounts and confirm associated rows are removed;
- verify secrets and tokens never appear in client bundles or logs.

