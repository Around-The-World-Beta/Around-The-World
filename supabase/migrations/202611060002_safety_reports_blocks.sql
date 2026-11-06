-- Around The World — report and block tables (trust & safety)
--
-- Run this AFTER 202611060001_atw_core_schema.sql. Safe to skip if the server
-- has already created these tables itself (it will, on the next boot against
-- a database it can migrate).
--
-- If you already ran the core schema by hand in the Supabase SQL editor, paste
-- this file next so report/block work on the hosted database too.

begin;

create table if not exists public.user_reports (
    id uuid not null,
    reporter_user_id uuid not null,
    target_type text not null,
    target_id uuid not null,
    reason text not null,
    details text,
    created_at timestamp with time zone,
    constraint user_reports_pkey primary key (id),
    constraint "uq:user_reports.reporter_user_id+user_reports.target_type+user_reports.target_id"
        unique (reporter_user_id, target_type, target_id),
    constraint user_reports_reporter_user_id_fkey foreign key (reporter_user_id)
        references public.users(id) on delete cascade
);

create table if not exists public.user_blocks (
    id uuid not null,
    blocker_user_id uuid not null,
    blocked_user_id uuid not null,
    created_at timestamp with time zone,
    constraint user_blocks_pkey primary key (id),
    constraint "uq:user_blocks.blocker_user_id+user_blocks.blocked_user_id"
        unique (blocker_user_id, blocked_user_id),
    constraint user_blocks_blocker_user_id_fkey foreign key (blocker_user_id)
        references public.users(id) on delete cascade,
    constraint user_blocks_blocked_user_id_fkey foreign key (blocked_user_id)
        references public.users(id) on delete cascade
);

alter table public.user_reports enable row level security;
alter table public.user_blocks enable row level security;

insert into public._fluent_migrations (id, name, batch, created_at, updated_at)
values
    (gen_random_uuid(), 'App.CreateUserReports', 1, now(), now()),
    (gen_random_uuid(), 'App.CreateUserBlocks',  1, now(), now())
on conflict (name) do nothing;

commit;
