# Authentication contract

This is the agreement between the iPhone app and the server for “who is calling.” Workstream 2 (Sign in with Apple on iOS) should be built against this file. Nothing here is a website login.

**Bundle ID:** `com.aroundtheworld.app`  
**Identity provider:** Supabase Auth  
**Server:** this Vapor API. It owns `users`, `profiles`, `games`, `participants`, and `friendships`. Supabase owns only `auth.users`.

---

## What the phone sends

After Sign in with Apple (via Supabase Auth), the app holds a Supabase **access token**. On every request that is not public browse, send:

```
Authorization: Bearer <access_token>
Accept: application/json
Content-Type: application/json   (when there is a body)
```

Store the token in the Keychain. When it expires, refresh it with Supabase (`auth.refreshSession`) and retry once. Do not put a user id, email, or `supabaseUserId` in the path, query, or body to say who you are. The server takes `sub` from the verified token and ignores any host/user id you send.

Public (no token):

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Hosting health check |
| `GET` | `/api/v1/meta/bay-area` | County list |
| `GET` | `/api/v1/games` | Browse open Bay Area games |
| `GET` | `/api/v1/games/:id` | One game’s public card |

Everything else requires a token and returns `401` with `{ "error": { "message": "Sign in required", "status": 401 } }` if it is missing or invalid.

---

## Token shape the server verifies

Supabase access tokens, documented at [JWT claims](https://supabase.com/docs/guides/auth/jwt-fields). Tests mint the same shape with a local HS256 secret.

Header (typical shared-secret project):

```json
{ "alg": "HS256", "typ": "JWT" }
```

Payload the server requires:

| Claim | Rule |
| --- | --- |
| `sub` | UUID. This becomes `users.supabase_user_id`. |
| `aud` | Must include `"authenticated"`. |
| `role` | Must be `"authenticated"`. `anon` and `service_role` are rejected. |
| `exp` | Must be in the future. |
| `iss` | If `SUPABASE_URL` is set, must equal `{SUPABASE_URL}/auth/v1`. |
| `is_anonymous` | Must not be `true`. |
| `email` | Used on first login to fill `users.email`. |
| `user_metadata.name` / `user_metadata.full_name` | Used on first login as `displayName` if present. |

The server **does not** accept a user id from the client to create or link an account. The first authenticated call to `GET /api/v1/me` creates the app user and an empty profile from those claims.

---

## Account endpoints (`/api/v1/me`)

| Method | Path | Result |
| --- | --- | --- |
| `GET` | `/api/v1/me` | Current user + profile. Creates them on first login. |
| `PATCH` | `/api/v1/me` | `{ "displayName": "…" }` only. Email is not writable here. |
| `DELETE` | `/api/v1/me` | Deletes the signed-in account and cascaded rows. Apple requires an in-app delete path. |
| `GET` | `/api/v1/me/profile` | Your profile. |
| `PATCH` | `/api/v1/me/profile` | `city`, `bio` (≤200), `favoritePosition`, `skillLevel`, `avatarUrl`, `age`. |
| `GET` | `/api/v1/me/games` | Games you host or have joined/waitlisted. |
| `GET` | `/api/v1/me/friendships` | Your friend/follow rows. |

`GET /api/v1/me` response:

```json
{
  "user": {
    "id": "app-user-uuid",
    "email": "you@privaterelay.appleid.com",
    "displayName": "Auner",
    "supabaseUserId": "supabase-auth-user-uuid",
    "createdAt": "…",
    "updatedAt": "…"
  },
  "profile": {
    "id": "profile-uuid",
    "userId": "app-user-uuid",
    "city": null,
    "bio": null,
    "favoritePosition": null,
    "skillLevel": null,
    "avatarUrl": null,
    "age": null,
    "createdAt": "…",
    "updatedAt": "…"
  }
}
```

Use `user.id` as the app’s current-user id after sign-in. Never send it back to prove identity.

---

## Writes that used to take someone else’s id

| Action | Request | Who it applies to |
| --- | --- | --- |
| Host a game | `POST /api/v1/games` | Host is always the token. Do **not** send `hostUserId`. |
| Edit / cancel a game | `PATCH` / `DELETE /api/v1/games/:id` | Host only (`403` otherwise). Cancel with `{ "status": "cancelled" }`. |
| Claim a spot | `POST /api/v1/participants` `{ "gameId": "…" }` | Player is always the token. Do **not** send `userId`. |
| Leave / cancel a signup | `PATCH` / `DELETE /api/v1/participants/:id` | Your row only. |
| Follow | `POST /api/v1/friendships` `{ "friendUserId": "…" }` | Follower is always the token. |
| Public player card | `GET /api/v1/players/:userId` | Authenticated. No email. |

Browse stays public so Matches and Map work while signed out. Claim Spot, Host publish, My Games, Profile, and Friends require a token.

---

## Removed on purpose

These used to dump or mutate anyone’s data with no login. They now return `401` and must not be called:

- `GET/POST /api/v1/users`, `GET/PATCH/DELETE /api/v1/users/:id`
- `GET /api/v1/profiles`, `GET/PATCH/DELETE /api/v1/profiles/:id`
- `GET /api/v1/profiles/user/:userId`
- `GET /api/v1/games/mine?userId=`
- `GET /api/v1/participants` (all rows)
- `GET /api/v1/friendships`, `GET /api/v1/friendships/user/:userId`

---

## Errors

Same envelope as the rest of the API:

```json
{ "error": { "message": "Sign in required", "status": 401 } }
```

| Status | When |
| --- | --- |
| `401` | Missing, expired, anonymous, wrong-secret, or wrong-issuer token |
| `403` | Valid token, but not your game / signup / profile |
| `409` | Duplicate email link, already joined, already following |
| `429` | More than `RATE_LIMIT_PER_MINUTE` requests from one IP in 60 seconds |

---

## iOS checklist for W2

1. Add Sign in with Apple with bundle id `com.aroundtheworld.app`.
2. Exchange the Apple credential with Supabase Auth; keep `session.accessToken`.
3. `NetworkManager.setBearerToken(accessToken)` (already on the client).
4. Call `GET /api/v1/me` once after sign-in; store `user.id` in memory (not as a credential).
5. My Games → `GET /api/v1/me/games`. Claim Spot → `POST /api/v1/participants` with only `gameId`. Host → `POST /api/v1/games` with no `hostUserId`.
6. Sign out: drop the Keychain session and the bearer token.
7. Delete account: `DELETE /api/v1/me`, then sign out.

CORS does not apply to the native app. Rate limits do.

---

## Local development without Auner’s real JWT secret

Unit tests mint HS256 tokens with `test-jwt-secret-for-unit-tests-only`.

`swift run` in development will boot with `local-dev-jwt-secret-not-for-production` if `SUPABASE_JWT_SECRET` is unset, so browse still works. **Real Sign in with Apple tokens will not verify until the real secret is set.** Put it in the environment; never commit it.

To talk to a local server with a real Supabase login, set `SUPABASE_JWT_SECRET` and `SUPABASE_URL` to the values from the Supabase project (see Railway list below).
