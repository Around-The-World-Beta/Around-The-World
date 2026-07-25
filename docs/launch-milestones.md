# Launch milestones

Each milestone has an explicit completion gate. A later milestone should not be
treated as complete while an earlier gate is failing.

## Milestone 1 — Launch foundation

Goal: make the project safe and repeatable before connecting user data.

- Isolate this application as its own Git repository.
- Document architecture, privacy boundaries, and environment ownership.
- Provide secret-free environment templates.
- Add baseline HTTP response protections.
- Add reproducible lint, type-check, and production-build commands.
- Add CI that runs the same checks for every pull request.

Completion gate:

- Git resolves to this application folder, not the user's home directory.
- No secrets are committed.
- Lint, type-check, and production build pass from a clean install.

## Milestone 2 — Accounts and authentication

Goal: add secure account creation and protected sessions.

Status: implementation complete; live development/staging connection and
end-to-end verification pending.

- Create separate Supabase development and staging projects.
- Add email/password signup, verified email, login, logout, password reset, and
  session recovery.
- Add Sign in with Apple and mobile-safe PKCE callback handling.
- Store mobile refresh credentials in the iOS Keychain.
- Add protected routes and server-side token validation.
- Add profile creation, session management, reauthentication, and in-app
  account deletion.
- Add signup/login throttling, bot protection, breached-password protection,
  and security audit events.

Completion gate:

- Account lifecycle works end to end in staging.
- An unauthenticated or different user cannot access protected records.
- Refresh, expiry, reset, revocation, and deletion tests pass.

## Milestone 3 — Games backend and authorization

Goal: replace mock games with durable, ownership-protected records.

- Add Postgres/PostGIS schema and migrations.
- Add profiles, games, participants, waitlist, blocks, reports, feedback, and
  audit-event tables.
- Implement create, read, update, cancel, join, leave, and “my games” APIs.
- Use database transactions to prevent duplicate joins and overbooking.
- Apply row-level security and API ownership checks.
- Validate and sanitize every request.

Completion gate:

- Host and participant flows persist across devices.
- Ownership and capacity concurrency tests pass.
- The UI no longer uses mock data for authenticated game flows.

## Milestone 4 — Private location search

Goal: support nearby discovery without building a location-history system.

- Add foreground-only location permission with a clear explanation.
- Add manual city/address search when permission is declined.
- Implement indexed PostGIS radius queries from 1–10 miles.
- Return relative distance and appropriately coarse pre-join location data.
- Avoid retaining device coordinates by default.
- Add query throttling and protection against location scraping.

Completion gate:

- Real-device permission, denial, reduced-accuracy, and manual-entry paths work.
- Search accuracy and privacy tests pass.
- One user can never retrieve another user's device coordinates.

## Milestone 5 — Trust, safety, and privacy

Goal: make real-world meetups supportable and reviewable.

- Add block, report, moderation, participant removal, and host cancellation.
- Add data export and complete deletion workflows.
- Add retention rules and redacted audit logging.
- Publish privacy policy, terms, community rules, and support contact.
- Decide and enforce the beta age policy with legal review.
- Add consent-aware, privacy-minimized analytics and feedback.

Completion gate:

- Reports reach a monitored moderation queue.
- Deletion removes account-associated data according to policy.
- Legal/privacy disclosures match actual application behavior.

## Milestone 6 — Native iOS application

Goal: package the product as a reliable iOS app.

- Add Capacitor and the iOS project.
- Configure the permanent bundle ID, signing, icons, launch assets, and version.
- Add native location, Sign in with Apple, Keychain storage, universal links,
  sharing, notifications, and network-state handling.
- Add accessibility, privacy manifest, permission copy, and SDK declarations.

Completion gate:

- Core flows pass on physical iPhones across supported iOS versions.
- Release archive signs and uploads successfully.
- No sensitive session data is stored in ordinary web storage.

## Milestone 7 — Operations and staging beta

Goal: make failures visible and recoverable.

- Deploy isolated staging frontend, API, and database environments.
- Add CI/CD approvals for staging and production.
- Add redacted error tracking, uptime checks, metrics, and alerts.
- Configure backups and perform a restore rehearsal.
- Add beta feedback and privacy-conscious funnel analytics.
- Run security, accessibility, performance, and core-flow regression checks.

Completion gate:

- Staging uses no mock data and no production credentials.
- Alerts and restore procedures have been tested.
- Beta-blocking issues are resolved.

## Milestone 8 — TestFlight

Goal: validate the release with real testers.

- Upload a signed internal build.
- Complete internal testing before external distribution.
- Provide beta metadata, reviewer credentials, and test instructions.
- Expand from a small external cohort only after stability review.
- Triage crashes, authentication failures, and safety reports.

Completion gate:

- Core-flow success and crash-free targets are met.
- Feedback and moderation channels are actively monitored.
- A release candidate is approved for submission.

## Milestone 9 — App Store launch

Goal: submit and safely operate the public release.

- Complete listing metadata, screenshots, age rating, accessibility details,
  export compliance, privacy labels, and review notes.
- Provide a working review account and backend.
- Submit the release candidate and resolve review feedback.
- Use a controlled release and monitor launch health.
- Maintain incident, support, key-rotation, backup, and update routines.

Completion gate:

- Apple approves the version and production monitoring is healthy.
- Support, privacy, moderation, and incident owners are assigned.
