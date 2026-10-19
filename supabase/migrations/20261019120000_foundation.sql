-- Business Ledger on Supabase Postgres — 1/7: foundation.
--
-- Identity comes from Firebase Auth through Supabase third-party auth:
-- PostgREST verifies the Firebase ID token and exposes its claims through
-- auth.jwt(). `app.uid()` is the only way the schema learns who is calling.
--
-- Schemas
--   public : tables and the RPCs the app calls (exposed by PostgREST)
--   app    : internal helpers, ledger rules, triggers (NOT exposed)
--
-- Every object here is created with `if not exists` / `create or replace`
-- where Postgres allows it, so re-running a migration is harmless.

create schema if not exists app;
grant usage on schema app to anon, authenticated, service_role;

-- Functions created in `app` are not executable by PUBLIC by default; the
-- few that RLS policies need are granted explicitly (see 4/7).
alter default privileges in schema app revoke execute on functions from public;

do $$ begin
  -- Ordered: viewer < editor < admin < owner, so `role >= 'admin'` works.
  create type app.member_role as enum ('viewer', 'editor', 'admin', 'owner');
exception when duplicate_object then null; end $$;

-- One global counter stamped on every insert/update of a business-scoped
-- row; clients pull "rows with seq > cursor" per business (README §Sync).
create sequence if not exists app.sync_seq as bigint;

-- ---------------------------------------------------------------------------
-- Identity
-- ---------------------------------------------------------------------------

create or replace function app.firebase_project() returns text
language sql immutable set search_path = '' as $$ select 'busineedger-ab7a1'::text $$;

/** The verified JWT claims of this request ('{}' when there are none). */
create or replace function app.claims() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(auth.jwt(), '{}'::jsonb)
$$;

/**
 * Firebase uid of the caller, or null. Only tokens issued by this Firebase
 * project count: a Supabase Auth token, an anon key or another project's
 * token yields null, and every policy and RPC requires a non-null uid.
 */
create or replace function app.uid() returns text
language sql stable set search_path = '' as $$
  select case
    when c->>'iss' = 'https://securetoken.google.com/' || app.firebase_project()
     and c->>'aud' = app.firebase_project()
     and nullif(c->>'sub', '') is not null
    then c->>'sub'
  end
  from (select app.claims() as c) s
$$;

/** True when the current statement runs as a client role (not inside an RPC). */
create or replace function app.is_client() returns boolean
language sql stable set search_path = '' as $$
  select current_user::text in ('anon', 'authenticated')
$$;

-- ---------------------------------------------------------------------------
-- Errors (README §Error contract)
--
-- SQLSTATE PTnnn makes PostgREST answer with HTTP status nnn; DETAIL carries
-- JSON {"code", "reason", ...extra}; MESSAGE is safe to show to the user.
-- ---------------------------------------------------------------------------

create or replace function app.error_state(p_code text) returns text
language sql immutable set search_path = '' as $$
  select case p_code
    when 'invalid-argument'    then 'PT400'
    when 'unauthenticated'     then 'PT401'
    when 'permission-denied'   then 'PT403'
    when 'not-found'           then 'PT404'
    when 'aborted'             then 'PT409'
    when 'failed-precondition' then 'PT412'
    when 'already-exists'      then 'PT422'
    else 'P0001'
  end
$$;

create or replace function app.fail(
  p_code text, p_message text, p_reason text, p_extra jsonb default '{}'::jsonb
) returns void
language plpgsql immutable set search_path = '' as $$
begin
  raise exception using
    errcode = app.error_state(p_code),
    message = p_message,
    detail = (jsonb_build_object('code', p_code, 'reason', p_reason) || coalesce(p_extra, '{}'::jsonb))::text;
end $$;

create or replace function app.invalid(p_message text, p_field text default null) returns void
language plpgsql immutable set search_path = '' as $$
begin
  perform app.fail('invalid-argument', p_message, 'validation',
    case when p_field is null then '{}'::jsonb else jsonb_build_object('field', p_field) end);
end $$;

create or replace function app.require_uid() returns text
language plpgsql stable set search_path = '' as $$
declare v_uid text := app.uid();
begin
  if v_uid is null then
    perform app.fail('unauthenticated', 'Sign in to continue.', 'unauthenticated');
  end if;
  return v_uid;
end $$;

-- ---------------------------------------------------------------------------
-- Argument validation (ports of functions/src/schemas.ts)
-- ---------------------------------------------------------------------------

/** JS String.prototype.trim(): strips all leading/trailing white space. */
create or replace function app.trim_text(p text) returns text
language sql immutable set search_path = '' as $$
  select regexp_replace(p, '^[\s ﻿]+|[\s ﻿]+$', '', 'g')
$$;

/** A trimmed optional text argument of at most p_max characters. */
create or replace function app.arg_text(p_value text, p_max integer, p_field text) returns text
language plpgsql immutable set search_path = '' as $$
declare v text;
begin
  if p_value is null then return null; end if;
  v := app.trim_text(p_value);
  if length(v) > p_max then
    perform app.invalid(format('Use at most %s characters.', p_max), p_field);
  end if;
  return v;
end $$;

/** `yyyy-MM-dd` that actually exists (no 2026-02-30). */
create or replace function app.is_calendar_date(p text) returns boolean
language plpgsql immutable set search_path = '' as $$
begin
  if p is null or p !~ '^\d{4}-\d{2}-\d{2}$' then return false; end if;
  return to_char(p::date, 'YYYY-MM-DD') = p;
exception when others then
  return false;
end $$;

create or replace function app.arg_date(p_value text, p_field text) returns date
language plpgsql immutable set search_path = '' as $$
begin
  if p_value is null then return null; end if;
  if not app.is_calendar_date(p_value) then
    perform app.invalid('Use a yyyy-MM-dd date', p_field);
  end if;
  return p_value::date;
end $$;

create or replace function app.arg_request_id(p_value text) returns text
language plpgsql immutable set search_path = '' as $$
begin
  if p_value is null or p_value !~ '^[A-Za-z0-9_-]{8,64}$' then
    perform app.invalid('Invalid request id', 'requestId');
  end if;
  return p_value;
end $$;

create or replace function app.is_uuid(p text) returns boolean
language sql immutable set search_path = '' as $$
  select p ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
$$;

/** A JSON number that is a safe integer (Number.isSafeInteger), else null. */
create or replace function app.json_safe_int(p jsonb) returns numeric
language plpgsql immutable set search_path = '' as $$
declare v numeric;
begin
  if p is null or jsonb_typeof(p) <> 'number' then return null; end if;
  v := p::numeric;
  if v <> trunc(v) or abs(v) > 9007199254740991 then return null; end if;
  return v;
end $$;
