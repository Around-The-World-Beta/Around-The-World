-- Around The World — remove the retired web-prototype schema
--
-- ONLY RUN THIS if you already pasted the old `202607250001_auth_profiles.sql` into
-- your Supabase project. On a brand-new project you do not need this file at all —
-- skip straight to 202611060001_atw_core_schema.sql.
--
-- WHY IT EXISTS
-- The old file created `profiles`, `user_roles`, and `audit_events` for the Lovable web
-- prototype, keyed on `auth.users`. Its `profiles` table has a different shape from the
-- one this API needs, and the two cannot coexist under the same name. The API is now the
-- owner of `profiles`, so the prototype's version has to go.
--
-- THIS DELETES DATA. It drops those three tables and everything in them. That is safe
-- if the only thing in them is test data from following the old launch-plan step, which
-- is the only situation this file is for. If real people have signed up and you are not
-- certain, stop and ask before running it.
--
-- It does NOT touch `auth.users`. Your Supabase logins are untouched.

begin;

drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_profile_updated on public.profiles;

drop function if exists public.handle_new_user();
drop function if exists public.audit_profile_update();

drop table if exists public.audit_events;
drop table if exists public.user_roles;
drop table if exists public.profiles;

drop type if exists public.app_role;

commit;

-- Next: run 202611060001_atw_core_schema.sql
