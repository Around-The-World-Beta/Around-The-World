# Around The World

Around The World is a mobile-first pickup sports app for hosting, discovering,
joining, and managing nearby games.

The current product UI is a prototype. Production backend, authentication,
geospatial search, moderation, and iOS distribution are being added in gated
milestones documented in [docs/launch-milestones.md](docs/launch-milestones.md).

Milestone 2 authentication code is implemented. Follow
[docs/supabase-auth-setup.md](docs/supabase-auth-setup.md) to connect the
development and staging projects and complete live verification.

## Local development

Requirements:

- Bun 1.3.14
- Node.js 22 or newer

```sh
bun install
cp .env.example .env.local
bun run dev
```

Before opening a pull request:

```sh
bun run check
```

Never commit `.env.local`, `.dev.vars`, service-role keys, Apple private keys,
or production credentials.

## Project status

Milestone 1 established the launch foundation. Milestone 2 account flows are
implemented but remain disabled when Supabase environment values are absent.
Game data remains mocked until Milestone 3.
