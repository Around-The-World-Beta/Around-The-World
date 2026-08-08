-- Optional SQL mirror of Fluent Phase 1 tables for teams that prefer applying
-- schema in the Supabase SQL editor. Prefer `swift run App migrate` when the
-- Vapor service owns the database lifecycle.
--
-- NOTE: This is separate from 202607250001_auth_profiles.sql (web prototype
-- profiles tied to auth.users). Phase 2 will unify identity via supabase_user_id.

create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  display_name text not null,
  supabase_user_id uuid unique,
  created_at timestamptz,
  updated_at timestamptz
);

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  city text,
  bio text,
  favorite_position text,
  skill_level text,
  avatar_url text,
  created_at timestamptz,
  updated_at timestamptz
);

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  venue text not null,
  neighborhood text not null,
  skill text not null,
  format text not null,
  capacity integer not null,
  price_cents integer not null,
  notes text not null,
  starts_at timestamptz not null,
  latitude double precision not null,
  longitude double precision not null,
  status text not null,
  image_url text,
  created_at timestamptz,
  updated_at timestamptz
);

create table if not exists public.participants (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  status text not null,
  created_at timestamptz,
  updated_at timestamptz,
  unique (game_id, user_id)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  friend_user_id uuid not null references public.users(id) on delete cascade,
  status text not null,
  created_at timestamptz,
  updated_at timestamptz,
  unique (user_id, friend_user_id)
);

create index if not exists games_starts_at_idx on public.games (starts_at);
create index if not exists participants_game_id_idx on public.participants (game_id);
create index if not exists friendships_user_id_idx on public.friendships (user_id);
