-- Optional: add profile.age for Bay Area beta player profiles.
alter table public.profiles
  add column if not exists age integer;
