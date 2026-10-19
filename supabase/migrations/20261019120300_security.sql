-- Business Ledger on Supabase Postgres — 4/7: privileges and row level security.
--
-- Port of firestore.rules. Firebase ID tokens carry no `role` claim, so
-- PostgREST may run a signed-in user as `anon`; every grant and policy
-- therefore names both `anon` and `authenticated`, and every policy
-- requires app.uid() (a verified token from our Firebase project).
--
-- Client writes allowed (everything else only through RPCs, 5–7/7):
--   profiles                         own row
--   businesses                       admin: name, description, timezone, settings; owner: archived
--   categories/custom_fields/
--   parties/projects                 editor+: insert / update (no delete; archive instead)
--   transactions                     editor+: drafts only (insert / update / soft delete)

-- Supabase grants ALL on new public tables to anon/authenticated by default:
-- start from nothing and grant exactly what each table needs.
revoke all on table
  public.profiles, public.businesses, public.members, public.categories, public.custom_fields,
  public.parties, public.projects, public.transactions, public.settlements, public.documents,
  public.audit_log, public.daily_stats, public.counters, public.requests
from anon, authenticated, public;

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.members enable row level security;
alter table public.categories enable row level security;
alter table public.custom_fields enable row level security;
alter table public.parties enable row level security;
alter table public.projects enable row level security;
alter table public.transactions enable row level security;
alter table public.settlements enable row level security;
alter table public.documents enable row level security;
alter table public.audit_log enable row level security;
alter table public.daily_stats enable row level security;
alter table public.counters enable row level security;   -- no policies: server only
alter table public.requests enable row level security;   -- no policies: server only

-- ---------------------------------------------------------------------------
-- Helpers RLS policies call (run as the client role)
-- ---------------------------------------------------------------------------

/**
 * validDraft from firestore.rules: a client may only ever store a draft,
 * with every server-maintained figure at its initial value.
 */
create or replace function app.valid_draft(t public.transactions) returns boolean
language sql stable set search_path = '' as $$
  select coalesce(
    t.status = 'draft'
    and t.type in ('income', 'sale', 'expense', 'purchase', 'payment', 'adjustment')
    and t.paid_minor = 0 and t.refunded_minor = 0 and t.credited_minor = 0
    and t.effective_minor = 0 and t.outstanding_minor = 0
    and t.payment_status is null and not t.is_open
    and t.confirmed_at is null and t.confirmed_by is null
    and t.cancelled_at is null and t.cancelled_by is null and t.cancel_reason is null
    and t.linked_transaction_id is null and t.link_kind is null and t.settlement_id is null
    and t.version = 0
    and t.total_minor between 0 and app.max_minor()
    and length(t.description) <= 200 and length(t.reference) <= 80
    and length(t.notes) <= 2000 and length(t.payment_method) <= 40
    and jsonb_array_length(t.line_items) <= 200
    and coalesce(array_length(t.search_tokens, 1), 0) <= 200,
    false)
$$;

revoke execute on all functions in schema app from public, anon, authenticated;
grant execute on function
  app.firebase_project(), app.claims(), app.uid(), app.is_client(), app.role_in(uuid), app.is_member(uuid),
  app.has_role(uuid, app.member_role), app.valid_draft(public.transactions), app.max_minor(),
  app.fail(text, text, text, jsonb), app.invalid(text, text), app.error_state(text)
to anon, authenticated;

-- ---------------------------------------------------------------------------
-- profiles: own row
-- ---------------------------------------------------------------------------
grant select, insert, update on public.profiles to anon, authenticated;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to anon, authenticated
  using (id = app.uid());
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to anon, authenticated
  with check (id = app.uid());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to anon, authenticated
  using (id = app.uid()) with check (id = app.uid());

-- ---------------------------------------------------------------------------
-- businesses: members read; admins edit details; owner archives.
-- Column privileges keep currency, owner, template… out of client reach.
-- ---------------------------------------------------------------------------
grant select on public.businesses to anon, authenticated;
grant update (name, description, timezone, settings, archived) on public.businesses to anon, authenticated;

drop policy if exists businesses_select on public.businesses;
create policy businesses_select on public.businesses for select to anon, authenticated
  using (app.is_member(id));
drop policy if exists businesses_update on public.businesses;
create policy businesses_update on public.businesses for update to anon, authenticated
  using (app.has_role(id, 'admin')) with check (app.has_role(id, 'admin'));

-- ---------------------------------------------------------------------------
-- Read-only to members (written by RPCs only)
-- ---------------------------------------------------------------------------
grant select on public.members, public.settlements, public.documents, public.daily_stats, public.audit_log
  to anon, authenticated;

drop policy if exists members_select on public.members;
create policy members_select on public.members for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists settlements_select on public.settlements;
create policy settlements_select on public.settlements for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists documents_select on public.documents;
create policy documents_select on public.documents for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists daily_stats_select on public.daily_stats;
create policy daily_stats_select on public.daily_stats for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists audit_log_select on public.audit_log;
create policy audit_log_select on public.audit_log for select to anon, authenticated
  using (app.has_role(business_id, 'admin'));

-- ---------------------------------------------------------------------------
-- Configuration: editor+ insert/update, never delete
-- ---------------------------------------------------------------------------
grant select, insert, update on public.categories, public.custom_fields, public.parties, public.projects
  to anon, authenticated;

drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists categories_insert on public.categories;
create policy categories_insert on public.categories for insert to anon, authenticated
  with check (app.has_role(business_id, 'editor'));
drop policy if exists categories_update on public.categories;
create policy categories_update on public.categories for update to anon, authenticated
  using (app.has_role(business_id, 'editor') and deleted_at is null)
  with check (app.has_role(business_id, 'editor'));

drop policy if exists custom_fields_select on public.custom_fields;
create policy custom_fields_select on public.custom_fields for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists custom_fields_insert on public.custom_fields;
create policy custom_fields_insert on public.custom_fields for insert to anon, authenticated
  with check (app.has_role(business_id, 'editor'));
drop policy if exists custom_fields_update on public.custom_fields;
create policy custom_fields_update on public.custom_fields for update to anon, authenticated
  using (app.has_role(business_id, 'editor')) with check (app.has_role(business_id, 'editor'));

drop policy if exists parties_select on public.parties;
create policy parties_select on public.parties for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists parties_insert on public.parties;
create policy parties_insert on public.parties for insert to anon, authenticated
  with check (app.has_role(business_id, 'editor'));
drop policy if exists parties_update on public.parties;
create policy parties_update on public.parties for update to anon, authenticated
  using (app.has_role(business_id, 'editor')) with check (app.has_role(business_id, 'editor'));

drop policy if exists projects_select on public.projects;
create policy projects_select on public.projects for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists projects_insert on public.projects;
create policy projects_insert on public.projects for insert to anon, authenticated
  with check (app.has_role(business_id, 'editor'));
drop policy if exists projects_update on public.projects;
create policy projects_update on public.projects for update to anon, authenticated
  using (app.has_role(business_id, 'editor')) with check (app.has_role(business_id, 'editor'));

-- ---------------------------------------------------------------------------
-- Transactions: drafts only. Delete = set deleted_at (soft), drafts only.
-- ---------------------------------------------------------------------------
grant select, insert, update on public.transactions to anon, authenticated;

drop policy if exists transactions_select on public.transactions;
create policy transactions_select on public.transactions for select to anon, authenticated
  using (app.is_member(business_id));
drop policy if exists transactions_insert on public.transactions;
create policy transactions_insert on public.transactions for insert to anon, authenticated
  with check (app.has_role(business_id, 'editor') and created_by = app.uid() and app.valid_draft(transactions));
drop policy if exists transactions_update on public.transactions;
create policy transactions_update on public.transactions for update to anon, authenticated
  using (app.has_role(business_id, 'editor') and status = 'draft' and deleted_at is null)
  with check (app.has_role(business_id, 'editor') and app.valid_draft(transactions));
