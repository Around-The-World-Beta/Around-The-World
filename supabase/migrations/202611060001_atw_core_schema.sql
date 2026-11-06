-- Around The World — core application schema (Supabase / Postgres)
--
-- WHAT THIS IS
-- The one file to run on a fresh Supabase project. It creates every table this API
-- needs and records them as applied, so the server will not try to create them again.
-- Step-by-step instructions, including how to check it worked: docs/supabase-setup.md
--
-- SOURCE OF TRUTH
-- The Swift migrations in Backend/Sources/App/Migrations own this schema. This file is
-- a faithful transcription of what they produce on Postgres, verified by applying both
-- to empty databases and diffing the result. If you change a Swift migration, update
-- this file in the same commit, or the two will drift. Drift here is what previously
-- broke this project: two files both created a `profiles` table with incompatible
-- shapes, and because the second used "if not exists" it failed silently.
--
-- WHO OWNS WHAT
-- This service owns every table below. Supabase Auth owns `auth.users` and nothing
-- else. The link is `public.users.supabase_user_id`, written only from the verified
-- `sub` claim of a Supabase JWT — never from a request body. See IdentityLink.swift.
--
-- DELIBERATE OMISSIONS
-- * No CHECK constraints on skill tiers, formats, or statuses. Those are validated in
--   APIValidation (Backend/Sources/App/DTOs/Validation.swift), which is the single
--   place that decides what is allowed. Duplicating the list here would reintroduce
--   exactly the drift described above.
-- * No `default gen_random_uuid()` on id columns. The server generates ids.
--
-- SAFE TO RUN ONCE on a fresh project. It is not idempotent by design: running it
-- twice raises a clear error rather than half-applying.

begin;

-- Guard 1 ---------------------------------------------------------------------
-- Refuse to run if the retired web-prototype schema is present. That older file
-- (202607250001_auth_profiles.sql, now deleted) created a `profiles` table keyed on
-- auth.users with a `display_name` column — a different shape from the one below.
-- Applying this file on top of it would leave a database the server cannot use.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'display_name'
  ) then
    raise exception
      'Legacy prototype `profiles` table detected. Run 202611060000_reset_legacy_prototype.sql first, then re-run this file.';
  end if;
end $$;

-- Guard 2 ---------------------------------------------------------------------
-- Refuse to run if this schema is already applied, so a double-paste is obvious.
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'users'
  ) then
    raise exception
      'A `users` table already exists. This schema looks applied — check docs/supabase-setup.md step 5 instead of re-running.';
  end if;
end $$;

-- Migration bookkeeping -------------------------------------------------------
-- The server's migration tool keeps its own log here. Creating it and filling it in
-- is what tells the server "these tables already exist, leave them alone".
create table if not exists public._fluent_migrations (
    id uuid not null,
    name text not null,
    batch bigint not null,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    constraint _fluent_migrations_pkey primary key (id),
    constraint "uq:_fluent_migrations.name" unique (name)
);

-- Tables ----------------------------------------------------------------------

-- One row per account. `supabase_user_id` is the only link to Supabase Auth.
create table public.users (
    id uuid not null,
    email text not null,
    display_name text not null,
    supabase_user_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    constraint users_pkey primary key (id),
    constraint "uq:users.email" unique (email),
    constraint "uq:users.supabase_user_id" unique (supabase_user_id)
);

-- Player profile, exactly one per account.
create table public.profiles (
    id uuid not null,
    user_id uuid not null,
    city text,
    bio text,
    favorite_position text,
    skill_level text,
    avatar_url text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    age bigint,
    constraint profiles_pkey primary key (id),
    constraint "uq:profiles.user_id" unique (user_id),
    constraint profiles_user_id_fkey foreign key (user_id)
        references public.users(id) on delete cascade
);

-- A pickup session. `price_cents` is informational for v1.0; no money is processed.
create table public.games (
    id uuid not null,
    host_user_id uuid not null,
    title text not null,
    venue text not null,
    neighborhood text not null,
    skill text not null,
    format text not null,
    capacity bigint not null,
    price_cents bigint not null,
    notes text not null,
    starts_at timestamp with time zone not null,
    latitude double precision not null,
    longitude double precision not null,
    status text not null,
    image_url text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    constraint games_pkey primary key (id),
    constraint games_host_user_id_fkey foreign key (host_user_id)
        references public.users(id) on delete cascade
);

-- Join / waitlist / cancellation. Browse visibility is derived from these rows.
create table public.participants (
    id uuid not null,
    game_id uuid not null,
    user_id uuid not null,
    status text not null,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    constraint participants_pkey primary key (id),
    constraint "uq:participants.game_id+participants.user_id" unique (game_id, user_id),
    constraint participants_game_id_fkey foreign key (game_id)
        references public.games(id) on delete cascade,
    constraint participants_user_id_fkey foreign key (user_id)
        references public.users(id) on delete cascade
);

-- Directed follow / friend / block edge between two accounts.
create table public.friendships (
    id uuid not null,
    user_id uuid not null,
    friend_user_id uuid not null,
    status text not null,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    constraint friendships_pkey primary key (id),
    constraint "uq:friendships.user_id+friendships.friend_user_id" unique (user_id, friend_user_id),
    constraint friendships_user_id_fkey foreign key (user_id)
        references public.users(id) on delete cascade,
    constraint friendships_friend_user_id_fkey foreign key (friend_user_id)
        references public.users(id) on delete cascade
);

-- Row level security ----------------------------------------------------------
-- Supabase publishes every `public` table through its REST API, reachable with the
-- anon key that ships inside the iOS app. Enabling RLS with NO policies denies that
-- path entirely. This service is unaffected: it connects as the table owner, and
-- owners bypass RLS. Do not add policies unless the app starts talking to Postgres
-- directly, which it should not.
alter table public.users enable row level security;
alter table public.profiles enable row level security;
alter table public.games enable row level security;
alter table public.participants enable row level security;
alter table public.friendships enable row level security;

-- Record the schema as applied ------------------------------------------------
-- These names must match the Swift migration types exactly. `SeedDemoData` is left
-- out on purpose: it is harmless (a no-op unless SEED_DEMO=1) and leaving it unapplied
-- means a staging database can still be seeded later.
insert into public._fluent_migrations (id, name, batch, created_at, updated_at)
values
    (gen_random_uuid(), 'App.CreateUsers',              1, now(), now()),
    (gen_random_uuid(), 'App.CreateProfiles',           1, now(), now()),
    (gen_random_uuid(), 'App.CreateGames',              1, now(), now()),
    (gen_random_uuid(), 'App.CreateParticipants',       1, now(), now()),
    (gen_random_uuid(), 'App.CreateFriendships',        1, now(), now()),
    (gen_random_uuid(), 'App.AddProfileAge',            1, now(), now()),
    (gen_random_uuid(), 'App.NormalizeSkillTiers',      1, now(), now()),
    (gen_random_uuid(), 'App.EnableRowLevelSecurity',   1, now(), now())
on conflict (name) do nothing;

commit;
