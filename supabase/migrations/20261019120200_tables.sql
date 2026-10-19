-- Business Ledger on Supabase Postgres — 3/7: tables, sync stamps, guards.
--
-- Port of the Firestore model (ARCHITECTURE.md §3/§4). Columns are
-- snake_case; JSON payloads (settings, line_items, custom_fields, snapshot,
-- balance_after, audit before/after) keep the camelCase keys the app
-- already reads. Money is bigint minor units, 0 ≤ x ≤ 10^13. Text only: no
-- file or attachment columns.
--
-- Ids of client-created rows (drafts, categories, custom fields, parties,
-- projects) are uuids generated on the device so they can be created
-- offline. References from transactions to categories/parties/projects are
-- deliberately not foreign keys: a draft may reach the server before the
-- category created offline next to it; they are validated on confirm.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id text primary key check (length(id) between 1 and 128),
  -- Always the verified email from the Firebase token (see profile trigger),
  -- lower-cased: add_member finds people by it.
  email text not null default '' check (length(email) <= 320),
  display_name text not null default '' check (length(display_name) <= 200),
  photo_url text not null default '' check (length(photo_url) <= 2048),
  last_business_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists profiles_email_idx on public.profiles (email);

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) between 1 and 80),
  description text not null default '' check (length(description) <= 500),
  currency_code text not null check (currency_code ~ '^[A-Z]{3}$'),
  currency_decimals integer not null check (currency_decimals between 0 and 4),
  currency_symbol text not null check (length(currency_symbol) <= 8),
  timezone text not null check (length(timezone) between 1 and 64),
  template text not null check (length(template) <= 32),
  owner_id text not null,
  -- {enabledStandardFields[], invoicePrefix, billPrefix, receiptPrefix,
  --  address, phone, email, taxId}
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  seq bigint not null default 0
);

create table if not exists public.members (
  business_id uuid not null references public.businesses (id) on delete cascade,
  user_id text not null check (length(user_id) between 1 and 128),
  role app.member_role not null,
  email text not null default '',
  display_name text not null default '',
  photo_url text not null default '',
  added_by text,
  added_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Removal is a soft delete so other members' devices see it when syncing.
  deleted_at timestamptz,
  seq bigint not null default 0,
  primary key (business_id, user_id)
);
create index if not exists members_user_idx on public.members (user_id) where deleted_at is null;
create unique index if not exists members_one_owner_idx on public.members (business_id)
  where role = 'owner' and deleted_at is null;

create table if not exists public.categories (
  id uuid primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null check (length(name) between 1 and 60),
  kind text not null check (kind in ('income', 'expense', 'any')),
  icon text not null default '' check (length(icon) <= 40),
  colour text not null default '' check (length(colour) <= 40),
  field_ids uuid[] not null default '{}',
  sort_order integer not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Set only by delete_category (which proves nothing uses it).
  deleted_at timestamptz,
  seq bigint not null default 0
);

create table if not exists public.custom_fields (
  id uuid primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  label text not null check (length(label) <= 60),
  type text not null check (type in ('text', 'number', 'date', 'select', 'checkbox')),
  options text[] not null default '{}',
  required boolean not null default false,
  sort_order integer not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  seq bigint not null default 0
);

create table if not exists public.parties (
  id uuid primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null check (length(name) <= 120),
  kind text not null check (kind in ('customer', 'supplier', 'both')),
  phone text not null default '' check (length(phone) <= 40),
  email text not null default '' check (length(email) <= 320),
  address text not null default '' check (length(address) <= 1000),
  sort_order integer not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  seq bigint not null default 0
);

create table if not exists public.projects (
  id uuid primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null check (length(name) <= 120),
  code text not null default '' check (length(code) <= 40),
  sort_order integer not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  seq bigint not null default 0
);

create table if not exists public.transactions (
  id uuid primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  type text not null check (type in ('income', 'sale', 'expense', 'purchase', 'payment', 'adjustment', 'refund')),
  direction text check (direction in ('in', 'out')),
  status text not null default 'draft' check (status in ('draft', 'confirmed', 'cancelled')),
  category_id uuid,
  category_name text check (length(category_name) <= 60),
  party_id uuid,
  party_name text check (length(party_name) <= 120),
  project_id uuid,
  project_name text check (length(project_name) <= 120),
  -- 200 for users; a linked refund entry adds a "Refund · " prefix.
  description text not null default '' check (length(description) <= 220),
  reference text not null default '' check (length(reference) <= 80),
  notes text not null default '' check (length(notes) <= 2000),
  payment_method text not null default '' check (length(payment_method) <= 40),
  date date,
  due_date date,
  -- [{description, quantityMilli, rateMinor, amountMinor}]
  line_items jsonb not null default '[]'::jsonb check (jsonb_typeof(line_items) = 'array'),
  total_minor bigint not null default 0 check (total_minor between 0 and 10000000000000),
  paid_minor bigint not null default 0 check (paid_minor between 0 and 10000000000000),
  refunded_minor bigint not null default 0 check (refunded_minor between 0 and 10000000000000),
  credited_minor bigint not null default 0 check (credited_minor between 0 and 10000000000000),
  effective_minor bigint not null default 0 check (effective_minor between 0 and 10000000000000),
  outstanding_minor bigint not null default 0 check (outstanding_minor between 0 and 10000000000000),
  payment_status text check (payment_status in
    ('unpaid', 'partiallyPaid', 'paid', 'partiallyRefunded', 'refunded', 'notApplicable')),
  is_open boolean not null default false,
  -- {fieldId: value}
  custom_fields jsonb not null default '{}'::jsonb check (jsonb_typeof(custom_fields) = 'object'),
  linked_transaction_id uuid,
  link_kind text check (link_kind in ('refund')),
  settlement_id text,
  search_tokens text[] not null default '{}',
  version integer not null default 0 check (version >= 0),
  created_by text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text,
  confirmed_at timestamptz,
  confirmed_by text,
  cancelled_at timestamptz,
  cancelled_by text,
  cancel_reason text check (length(cancel_reason) <= 500),
  -- Soft delete of drafts (clients); never set on confirmed entries.
  deleted_at timestamptz,
  seq bigint not null default 0,
  -- §5 invariants: no overpayment, refunds only of money paid.
  constraint transactions_settled_le_total check (paid_minor + credited_minor <= total_minor),
  constraint transactions_refund_le_paid check (refunded_minor <= paid_minor),
  constraint transactions_deleted_drafts_only check (deleted_at is null or status = 'draft')
);
create index if not exists transactions_date_idx on public.transactions (business_id, date desc);
create index if not exists transactions_open_idx on public.transactions (business_id, direction, due_date)
  where is_open;
create index if not exists transactions_category_idx on public.transactions (business_id, category_id);
create index if not exists transactions_party_idx on public.transactions (business_id, party_id, date desc);
create index if not exists transactions_project_idx on public.transactions (business_id, project_id, date desc);
create index if not exists transactions_status_idx on public.transactions (business_id, status, date desc);
create index if not exists transactions_linked_idx on public.transactions (linked_transaction_id)
  where linked_transaction_id is not null;
create index if not exists transactions_search_idx on public.transactions using gin (search_tokens);

create table if not exists public.settlements (
  business_id uuid not null references public.businesses (id) on delete cascade,
  transaction_id uuid not null references public.transactions (id) on delete cascade,
  -- = the request id of the call that recorded it
  id text not null check (id ~ '^[A-Za-z0-9_-]{8,64}$'),
  kind text not null check (kind in ('payment', 'refund', 'credit')),
  amount_minor bigint not null check (amount_minor between 1 and 10000000000000),
  date date not null,
  method text not null default '',
  note text not null default '',
  -- money_json() of the transaction right after this settlement
  balance_after jsonb not null,
  linked_transaction_id uuid,
  created_by text not null,
  created_at timestamptz not null default now(),
  voided boolean not null default false,
  updated_at timestamptz not null default now(),
  seq bigint not null default 0,
  primary key (transaction_id, id)
);

create table if not exists public.documents (
  business_id uuid not null references public.businesses (id) on delete cascade,
  -- <type>-<transactionId>-<settlementId|main>: asking twice gives the same one
  id text not null,
  type text not null check (type in ('invoice', 'bill', 'receipt')),
  number text not null,
  transaction_id uuid not null references public.transactions (id) on delete cascade,
  settlement_id text,
  snapshot jsonb not null,
  issued_at timestamptz not null default now(),
  issued_by text not null,
  voided boolean not null default false,
  voided_at timestamptz,
  updated_at timestamptz not null default now(),
  seq bigint not null default 0,
  primary key (business_id, id),
  unique (business_id, type, number)
);
create index if not exists documents_transaction_idx on public.documents (business_id, transaction_id);

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  business_id uuid not null references public.businesses (id) on delete cascade,
  entity text not null,
  entity_id text not null,
  action text not null,
  actor text not null,
  before jsonb,
  after jsonb,
  note text,
  at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  seq bigint not null default 0
);
create index if not exists audit_log_entity_idx on public.audit_log (business_id, entity_id, at);

create table if not exists public.daily_stats (
  business_id uuid not null references public.businesses (id) on delete cascade,
  date date not null,
  income_minor bigint not null default 0 check (income_minor >= 0),
  expense_minor bigint not null default 0 check (expense_minor >= 0),
  cash_in_minor bigint not null default 0 check (cash_in_minor >= 0),
  cash_out_minor bigint not null default 0 check (cash_out_minor >= 0),
  -- {id: {in, out}}
  by_category jsonb not null default '{}'::jsonb,
  by_project jsonb not null default '{}'::jsonb,
  by_type jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  seq bigint not null default 0,
  primary key (business_id, date)
);

create table if not exists public.counters (
  business_id uuid not null references public.businesses (id) on delete cascade,
  doc_type text not null check (doc_type in ('invoice', 'bill', 'receipt')),
  year integer not null,
  next integer not null check (next >= 1),
  primary key (business_id, doc_type)
);

-- Idempotency records: the first result of (uid, request_id).
create table if not exists public.requests (
  uid text not null,
  request_id text not null,
  op text not null,
  result jsonb,
  created_at timestamptz not null default now(),
  primary key (uid, request_id)
);

-- Sync pulls: rows with seq > cursor, per business.
create index if not exists businesses_seq_idx on public.businesses (seq);
create index if not exists members_seq_idx on public.members (business_id, seq);
create index if not exists categories_seq_idx on public.categories (business_id, seq);
create index if not exists custom_fields_seq_idx on public.custom_fields (business_id, seq);
create index if not exists parties_seq_idx on public.parties (business_id, seq);
create index if not exists projects_seq_idx on public.projects (business_id, seq);
create index if not exists transactions_seq_idx on public.transactions (business_id, seq);
create index if not exists settlements_seq_idx on public.settlements (business_id, seq);
create index if not exists documents_seq_idx on public.documents (business_id, seq);
create index if not exists audit_log_seq_idx on public.audit_log (business_id, seq);
create index if not exists daily_stats_seq_idx on public.daily_stats (business_id, seq);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

/**
 * Sync stamp: every insert/update of a business-scoped row takes the next
 * global seq and sets updated_at. A per-business transaction-scoped lock is
 * taken first, so for one business seq order = commit order: a client that
 * has seen seq N can never later find a committed row of that business
 * with a lower seq. TG_ARGV[0] names the business id column.
 */
create or replace function app.stamp() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_business text := to_jsonb(new)->>tg_argv[0];
begin
  perform pg_advisory_xact_lock(hashtextextended('ledger-sync:' || v_business, 0));
  new.seq := nextval('app.sync_seq');
  new.updated_at := now();
  return new;
end $$;

/**
 * Client writes (anon/authenticated, i.e. not through an RPC): the server
 * sets created_at (insert) and keeps it (update), so a PostgREST upsert that
 * resends the row is harmless; the columns named in TG_ARGV can never change.
 */
create or replace function app.client_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_column text;
begin
  if not app.is_client() then return new; end if;
  if tg_op = 'INSERT' then
    -- Keys that are not columns of this table are ignored.
    new := jsonb_populate_record(new, jsonb_build_object('created_at', now(), 'deleted_at', null));
    return new;
  end if;
  new := jsonb_populate_record(new, jsonb_build_object('created_at', to_jsonb(old)->'created_at'));
  foreach v_column in array tg_argv loop
    if (to_jsonb(new)->v_column) is distinct from (to_jsonb(old)->v_column) then
      perform app.fail('permission-denied', format('%s cannot be changed.', v_column), 'immutable',
        jsonb_build_object('field', v_column));
    end if;
  end loop;
  return new;
end $$;

/** Profiles: email always comes from the verified token, never the client. */
create or replace function app.profile_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if app.is_client() then
    new.email := lower(coalesce(app.claims()->>'email', ''));
    if tg_op = 'INSERT' then new.created_at := now(); else new.created_at := old.created_at; end if;
  else
    new.email := lower(new.email);
  end if;
  new.updated_at := now();
  return new;
end $$;

/** Business details from a client: archive is owner-only, time zone must exist. */
create or replace function app.business_client_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if not app.is_client() then return new; end if;
  if new.archived is distinct from old.archived and app.role_in(new.id) is distinct from 'owner' then
    perform app.fail('permission-denied', 'Only the owner can archive a business.', 'role',
      jsonb_build_object('required', 'owner'));
  end if;
  if new.timezone is distinct from old.timezone
     and not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
    perform app.invalid('Unknown time zone.', 'timezone');
  end if;
  return new;
end $$;

-- Role of the caller in a business (null = not a member). Security definer:
-- RLS on members itself calls it.
create or replace function app.role_in(p_business_id uuid) returns app.member_role
language sql stable security definer set search_path = '' as $$
  select m.role from public.members m
  where m.business_id = p_business_id and m.user_id = app.uid() and m.deleted_at is null
$$;

create or replace function app.is_member(p_business_id uuid) returns boolean
language sql stable set search_path = '' as $$
  select app.uid() is not null and app.role_in(p_business_id) is not null
$$;

create or replace function app.has_role(p_business_id uuid, p_min app.member_role) returns boolean
language sql stable set search_path = '' as $$
  select app.uid() is not null and coalesce(app.role_in(p_business_id) >= p_min, false)
$$;

do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('businesses', 'id'), ('members', 'business_id'), ('categories', 'business_id'),
      ('custom_fields', 'business_id'), ('parties', 'business_id'), ('projects', 'business_id'),
      ('transactions', 'business_id'), ('settlements', 'business_id'), ('documents', 'business_id'),
      ('audit_log', 'business_id'), ('daily_stats', 'business_id')
    ) as t(tbl, col)
  loop
    execute format('drop trigger if exists t90_stamp on public.%I', r.tbl);
    execute format('create trigger t90_stamp before insert or update on public.%I
                    for each row execute function app.stamp(%L)', r.tbl, r.col);
  end loop;
end $$;

drop trigger if exists t10_client_guard on public.categories;
create trigger t10_client_guard before insert or update on public.categories
  for each row execute function app.client_guard('id', 'business_id', 'deleted_at');
drop trigger if exists t10_client_guard on public.custom_fields;
create trigger t10_client_guard before insert or update on public.custom_fields
  for each row execute function app.client_guard('id', 'business_id');
drop trigger if exists t10_client_guard on public.parties;
create trigger t10_client_guard before insert or update on public.parties
  for each row execute function app.client_guard('id', 'business_id');
drop trigger if exists t10_client_guard on public.projects;
create trigger t10_client_guard before insert or update on public.projects
  for each row execute function app.client_guard('id', 'business_id');
drop trigger if exists t10_client_guard on public.transactions;
create trigger t10_client_guard before insert or update on public.transactions
  for each row execute function app.client_guard('id', 'business_id', 'created_by');
drop trigger if exists t10_client_guard on public.businesses;
create trigger t10_client_guard before update on public.businesses
  for each row execute function app.business_client_guard();
drop trigger if exists t10_profile_guard on public.profiles;
create trigger t10_profile_guard before insert or update on public.profiles
  for each row execute function app.profile_guard();
