-- What a Supabase project already provides and PGlite does not. Loaded
-- before the migrations in tests only; NEVER push this to Supabase.

do $$ begin create role anon nologin noinherit; exception when duplicate_object then null; end $$;
do $$ begin create role authenticated nologin noinherit; exception when duplicate_object then null; end $$;
do $$ begin create role service_role nologin noinherit bypassrls; exception when duplicate_object then null; end $$;

create schema if not exists auth;
create schema if not exists extensions;
grant usage on schema auth, extensions, public to anon, authenticated, service_role;

-- Same body as Supabase's auth.jwt(): PostgREST puts the verified claims in
-- the request.jwt.claims setting of each request's transaction.
create or replace function auth.jwt() returns jsonb
language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb
$$;
grant execute on function auth.jwt() to anon, authenticated, service_role;

-- Supabase's defaults: everything new in public is granted to the API
-- roles (the migrations must revoke what clients should not have).
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
