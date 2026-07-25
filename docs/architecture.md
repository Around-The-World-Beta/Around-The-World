# Architecture and security decisions

## Product architecture

- Client: the existing React and TanStack Start application.
- API style: REST endpoints implemented behind the TanStack Start server
  boundary.
- Identity: managed Supabase Auth.
- Data: managed PostgreSQL with PostGIS.
- Web hosting: the existing Lovable/Cloudflare-compatible deployment path,
  confirmed before staging deployment.
- iOS: Capacitor native container added after backend flows pass in staging.

REST is preferred because games, participants, profiles, reports, and sessions
map cleanly to resources. It also keeps authorization, cache policy, request
limits, and audit behavior explicit per endpoint.

## Environment boundaries

Development, staging, and production must use different:

- Supabase projects and databases
- authentication callback URLs and Apple configuration
- server secrets and encryption keys
- storage buckets
- analytics/error-tracking projects
- rate-limit namespaces

Production data must never be copied to development. Sanitized fixtures should
be used for local testing.

## Location boundary

Device coordinates are sensitive transient request data. The default design:

1. Ask for foreground location only when the user starts nearby search.
2. Send coordinates over TLS to a rate-limited search endpoint.
3. Use them for an indexed PostGIS query.
4. Return distance and the minimum venue detail needed for the current state.
5. Do not write the search coordinates to application tables or analytics.

Game venue coordinates are host-provided meetup data, not a participant's live
location. Their precision can be reduced before joining when the host selects a
restricted-disclosure setting.

## Authentication boundary

- Email verification is required before hosting or joining.
- The API validates access tokens and resource ownership on every request.
- Database row-level security provides defense in depth.
- Short-lived access tokens and rotating refresh tokens are used.
- Native refresh credentials are stored in the iOS Keychain.
- Service-role credentials are server-only and never use a `VITE_` prefix.
- Sensitive account changes require recent authentication.
- Administrator actions require MFA and generate audit events.

## Secret handling

- Local values belong in ignored `.env.local` or `.dev.vars` files.
- CI, staging, and production values belong in their platform secret stores.
- Apple `.p8` keys, Supabase service-role keys, signing material, and encryption
  keys must never be committed.
- Public browser configuration is explicitly separated from server-only
  configuration in `.env.example`.

