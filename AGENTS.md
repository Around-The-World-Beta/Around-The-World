<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## Cursor Cloud specific instructions

### Stack and runtime

- TanStack Start + React 19 + Vite 8, package-managed with **Bun** (`bun.lock`). Node 22 is also present.
- Bun 1.3.14 is installed at `~/.bun` and its `bin` is added to `PATH` in `~/.bashrc`. Non-login shells (e.g. `bash -c`) do not source `~/.bashrc`, so prefix `PATH="$HOME/.bun/bin:$PATH"` when `bun` is not found.
- Standard scripts live in `package.json` (`dev`, `build`, `lint`, `test`, `typecheck`, `check`). Local dev quickstart is in `README.md`.

### Running the app

- `bun run dev` starts Vite. The dev server listens on **port 8080** (Lovable sandbox detection overrides the `.env.example` `APP_URL=...:3000`); use `http://localhost:8080/`.
- The app runs fully **without any Supabase or Turnstile secrets**: authentication is disabled when Supabase env vars are absent, and game data is served from `src/lib/mock-data.ts`. The core discovery UI (matches list, filters, game detail, map view) works with no secrets — no login required.
- To exercise live auth (signup/login/MFA/profile), configure Supabase per `docs/supabase-auth-setup.md` and set `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`, etc. in `.env.local` (copy from `.env.example`; `.env.local` is gitignored).

### Quality gates (non-obvious baseline)

- `bun test` and `bun run build` pass. As of the current `main`, `bun run lint` (prettier formatting violations) and `bun run typecheck` (Supabase-related `never` types + `bun:test` module resolution) report **pre-existing failures**, and the `main` "Quality" CI workflow is red for the same reasons. Compare against this baseline before assuming your change introduced a lint/type failure.
