-- Business Ledger on Supabase Postgres — 5/7: shared machinery of the RPCs.
--
-- Ports of functions/src/lib/{idempotency,roles,audit,stats,transaction}.ts,
-- currency.ts and templates.ts. Called only from the security-definer RPCs.

-- ---------------------------------------------------------------------------
-- Idempotency (lib/idempotency.ts `once`)
-- ---------------------------------------------------------------------------

/**
 * Stored result of (uid, request_id), or null when it is new. A transaction
 * lock on the pair makes a concurrent duplicate wait for the first and then
 * read its result. A different op under the same id → already-exists.
 */
create or replace function app.request_begin(p_uid text, p_request_id text, p_op text) returns jsonb
language plpgsql set search_path = '' as $$
declare r record;
begin
  perform pg_advisory_xact_lock(hashtextextended('ledger-request:' || p_uid || ':' || p_request_id, 0));
  select q.op, q.result into r from public.requests q where q.uid = p_uid and q.request_id = p_request_id;
  if not found then return null; end if;
  if r.op <> p_op then
    perform app.fail('already-exists', 'This request id was already used for another action.', 'requestReused');
  end if;
  return coalesce(r.result, 'null'::jsonb);
end $$;

create or replace function app.request_end(p_uid text, p_request_id text, p_op text, p_result jsonb) returns jsonb
language plpgsql set search_path = '' as $$
begin
  insert into public.requests (uid, request_id, op, result) values (p_uid, p_request_id, p_op, p_result);
  return p_result;
end $$;

-- ---------------------------------------------------------------------------
-- Roles (lib/roles.ts)
-- ---------------------------------------------------------------------------

create or replace function app.require_role(p_business_id uuid, p_min app.member_role) returns app.member_role
language plpgsql stable set search_path = '' as $$
declare v_role app.member_role;
begin
  select m.role into v_role from public.members m
  where m.business_id = p_business_id and m.user_id = app.uid() and m.deleted_at is null;
  if v_role is null then
    -- Same answer as a missing business: do not reveal which exists.
    perform app.fail('permission-denied', 'You do not have access to this business.', 'notMember');
  end if;
  if v_role < p_min then
    perform app.fail('permission-denied', format('This needs the %s role or higher.', p_min), 'role',
      jsonb_build_object('required', p_min));
  end if;
  return v_role;
end $$;

/** Admins manage editors and viewers; only the owner manages admins. */
create or replace function app.can_manage(p_actor app.member_role, p_target app.member_role) returns boolean
language sql immutable set search_path = '' as $$
  select p_actor = 'owner' or p_actor > p_target
$$;

-- ---------------------------------------------------------------------------
-- Audit (lib/audit.ts)
-- ---------------------------------------------------------------------------

create or replace function app.audit(
  p_business_id uuid, p_entity text, p_entity_id text, p_action text, p_actor text,
  p_before jsonb default null, p_after jsonb default null, p_note text default null
) returns void language sql set search_path = '' as $$
  insert into public.audit_log (business_id, entity, entity_id, action, actor, before, after, note)
  values (p_business_id, p_entity, p_entity_id, p_action, p_actor, p_before, p_after, p_note)
$$;

/** Only the keys whose values differ, as {before, after}. */
create or replace function app.changed_keys(p_before jsonb, p_after jsonb) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'before', coalesce(jsonb_object_agg(k, coalesce(p_before->k, 'null'::jsonb)), '{}'::jsonb),
    'after', coalesce(jsonb_object_agg(k, coalesce(p_after->k, 'null'::jsonb)), '{}'::jsonb))
  from (
    select k from jsonb_object_keys(p_before) k
    union
    select k from jsonb_object_keys(p_after) k
  ) keys
  where (p_before->k) is distinct from (p_after->k)
$$;

-- ---------------------------------------------------------------------------
-- Stats (lib/stats.ts writeStats): applies a delta as increments
-- ---------------------------------------------------------------------------

create or replace function app.jsonb_increment(p_obj jsonb, p_key text, p_side text, p_amount numeric) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_set(coalesce(p_obj, '{}'::jsonb), array[p_key],
    coalesce(p_obj->p_key, '{}'::jsonb)
      || jsonb_build_object(p_side, coalesce((p_obj->p_key->>p_side)::numeric, 0) + p_amount))
$$;

create or replace function app.apply_stats(p_business_id uuid, p_delta jsonb) returns void
language plpgsql set search_path = '' as $$
declare
  v_day record;
  v_item record;
  s public.daily_stats;
  v_parts text[];
begin
  for v_day in select key, value from jsonb_each(coalesce(p_delta, '{}'::jsonb)) order by key loop
    insert into public.daily_stats (business_id, date) values (p_business_id, v_day.key::date)
      on conflict (business_id, date) do nothing;
    select * into s from public.daily_stats
      where business_id = p_business_id and date = v_day.key::date for update;
    for v_item in select key, value::numeric as amount from jsonb_each_text(v_day.value) loop
      v_parts := string_to_array(v_item.key, '.');
      case v_parts[1]
        when 'income_minor' then s.income_minor := s.income_minor + v_item.amount;
        when 'expense_minor' then s.expense_minor := s.expense_minor + v_item.amount;
        when 'cash_in_minor' then s.cash_in_minor := s.cash_in_minor + v_item.amount;
        when 'cash_out_minor' then s.cash_out_minor := s.cash_out_minor + v_item.amount;
        when 'by_type' then s.by_type := app.jsonb_increment(s.by_type, v_parts[2], v_parts[3], v_item.amount);
        when 'by_category' then s.by_category := app.jsonb_increment(s.by_category, v_parts[2], v_parts[3], v_item.amount);
        when 'by_project' then s.by_project := app.jsonb_increment(s.by_project, v_parts[2], v_parts[3], v_item.amount);
      end case;
    end loop;
    update public.daily_stats set
      income_minor = s.income_minor, expense_minor = s.expense_minor,
      cash_in_minor = s.cash_in_minor, cash_out_minor = s.cash_out_minor,
      by_type = s.by_type, by_category = s.by_category, by_project = s.by_project
    where business_id = p_business_id and date = v_day.key::date;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Transactions (lib/transaction.ts, handlers/transactions.ts helpers)
-- ---------------------------------------------------------------------------

/** The parts of a transaction the stats reason about. */
create or replace function app.tx_state(t public.transactions) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'type', t.type, 'direction', t.direction, 'status', t.status,
    'date', to_char(t.date, 'YYYY-MM-DD'), 'categoryId', t.category_id, 'projectId', t.project_id,
    'total', t.total_minor, 'paid', t.paid_minor, 'refunded', t.refunded_minor, 'credited', t.credited_minor)
$$;

/** camelCase view of the editable fields, for audit before/after. */
create or replace function app.tx_doc(t public.transactions) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'description', t.description, 'reference', t.reference, 'notes', t.notes,
    'paymentMethod', t.payment_method, 'date', to_char(t.date, 'YYYY-MM-DD'),
    'dueDate', to_char(t.due_date, 'YYYY-MM-DD'), 'categoryId', t.category_id,
    'partyId', t.party_id, 'projectId', t.project_id, 'lineItems', t.line_items,
    'totalMinor', t.total_minor, 'customFields', t.custom_fields, 'categoryName', t.category_name,
    'partyName', t.party_name, 'projectName', t.project_name)
$$;

/** Locks and returns the transaction; not-found / aborted (stale version). */
create or replace function app.load_tx(
  p_business_id uuid, p_transaction_id uuid, p_expected_version integer, p_lock text default 'update'
) returns public.transactions
language plpgsql set search_path = '' as $$
declare t public.transactions;
begin
  if p_lock = 'share' then
    select * into t from public.transactions
      where id = p_transaction_id and business_id = p_business_id and deleted_at is null for share;
  else
    select * into t from public.transactions
      where id = p_transaction_id and business_id = p_business_id and deleted_at is null for update;
  end if;
  if not found then
    perform app.fail('not-found', 'That transaction was not found.', 'notFound');
  end if;
  if p_expected_version is not null and t.version <> p_expected_version then
    perform app.fail('aborted', 'This record was changed by someone else. Reload and try again.', 'conflict');
  end if;
  return t;
end $$;

/** Totals come from rounded lines when there are lines (§5 Rounding). */
create or replace function app.total_of(p_lines jsonb, p_total bigint) returns numeric
language plpgsql immutable set search_path = '' as $$
declare
  v_line record;
  v_quantity numeric;
  v_rate numeric;
  v_amount numeric;
  v_sum numeric := 0;
begin
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then
    return coalesce(p_total, 0);
  end if;
  for v_line in select value, ordinality from jsonb_array_elements(p_lines) with ordinality loop
    v_quantity := app.json_safe_int(v_line.value->'quantityMilli');
    if v_quantity is null or v_quantity <= 0 then
      perform app.invalid(format('Line %s: enter a quantity above zero.', v_line.ordinality), 'lineItems');
    end if;
    v_rate := app.json_safe_int(v_line.value->'rateMinor');
    if v_rate is null or v_rate < 0 then
      perform app.invalid(format('Line %s: enter a valid rate.', v_line.ordinality), 'lineItems');
    end if;
    v_amount := app.line_amount(v_quantity, v_rate);
    if (v_line.value->'amountMinor') is null or jsonb_typeof(v_line.value->'amountMinor') <> 'number'
       or (v_line.value->'amountMinor')::numeric <> v_amount then
      perform app.invalid(format('Line %s: amount does not match quantity × rate.', v_line.ordinality), 'lineItems');
    end if;
    v_sum := v_sum + v_amount;
  end loop;
  return v_sum;
end $$;

create or replace function app.check_dates(p_date date, p_due_date date) returns void
language plpgsql immutable set search_path = '' as $$
begin
  if p_date is null then perform app.invalid('Choose a date.', 'date'); end if;
  if p_due_date is not null and p_due_date < p_date then
    perform app.invalid('The due date cannot be before the transaction date.', 'dueDate');
  end if;
end $$;

/**
 * Reads the category, party and project an entry points at, checks the
 * category fits the direction, and returns fresh name snapshots plus the
 * category's required custom fields [{id, label}].
 */
create or replace function app.read_references(
  p_business_id uuid, p_type text, p_category_id uuid, p_party_id uuid, p_project_id uuid, p_direction text,
  out category_name text, out party_name text, out project_name text, out required jsonb
) language plpgsql stable set search_path = '' as $$
declare c public.categories;
begin
  required := '[]'::jsonb;
  if p_category_id is null then
    if p_type <> 'payment' then perform app.invalid('Choose a category.', 'categoryId'); end if;
  else
    select * into c from public.categories
      where id = p_category_id and business_id = p_business_id and deleted_at is null;
    if not found then perform app.invalid('That category no longer exists.', 'categoryId'); end if;
    if c.archived then perform app.invalid('That category is archived. Choose another.', 'categoryId'); end if;
    if (c.kind = 'income' and p_direction = 'out') or (c.kind = 'expense' and p_direction = 'in') then
      perform app.invalid(format('"%s" is an %s category.', c.name, c.kind), 'categoryId');
    end if;
    category_name := c.name;
    select coalesce(jsonb_agg(jsonb_build_object('id', f.id, 'label', f.label) order by u.ord), '[]'::jsonb)
      into required
      from unnest(c.field_ids) with ordinality as u(fid, ord)
      join public.custom_fields f on f.id = u.fid and f.business_id = p_business_id
      where f.required and not f.archived;
  end if;
  if p_party_id is not null then
    select p.name into party_name from public.parties p where p.id = p_party_id and p.business_id = p_business_id;
    if not found then perform app.invalid('That customer or supplier no longer exists.', 'partyId'); end if;
  end if;
  if p_project_id is not null then
    select p.name into project_name from public.projects p where p.id = p_project_id and p.business_id = p_business_id;
    if not found then perform app.invalid('That project no longer exists.', 'projectId'); end if;
  end if;
end $$;

create or replace function app.check_required_fields(p_values jsonb, p_required jsonb) returns void
language plpgsql immutable set search_path = '' as $$
declare
  f jsonb;
  v jsonb;
begin
  for f in select value from jsonb_array_elements(coalesce(p_required, '[]'::jsonb)) loop
    v := coalesce(p_values, '{}'::jsonb)->(f->>'id');
    if v is null or v = 'null'::jsonb or v = '""'::jsonb or v = '[]'::jsonb then
      perform app.invalid(format('%s is required.', f->>'label'), 'customFields.' || (f->>'id'));
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Currencies and templates (currency.ts, templates.ts)
-- ---------------------------------------------------------------------------

/** Mirrors Currency.supported (Dart) / CURRENCIES (TS). */
create or replace function app.currency(p_code text) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object('code', c.code, 'decimals', c.decimals, 'symbol', c.symbol)
  from (values
    ('INR', 2, '₹'), ('USD', 2, '$'), ('EUR', 2, '€'), ('GBP', 2, '£'), ('AED', 2, 'AED '),
    ('SAR', 2, 'SAR '), ('JPY', 0, '¥'), ('KWD', 3, 'KWD ')
  ) as c(code, decimals, symbol)
  where c.code = p_code
$$;

/** Starting structures for a new business (no attachments: text-only app). */
create or replace function app.template(p_key text) returns jsonb
language sql immutable set search_path = '' as $$
  select ($json$
  {
    "general": {
      "standardFields": ["party", "paymentMethod", "dueDate", "reference", "notes", "lineItems"],
      "fields": [],
      "categories": [
        {"name": "Sales", "kind": "income", "icon": "sell", "colour": "green"},
        {"name": "Other income", "kind": "income", "icon": "savings", "colour": "teal"},
        {"name": "Purchases", "kind": "expense", "icon": "shopping", "colour": "amber"},
        {"name": "Rent", "kind": "expense", "icon": "home", "colour": "purple"},
        {"name": "Salaries", "kind": "expense", "icon": "people", "colour": "blue"},
        {"name": "Other expenses", "kind": "expense", "icon": "receipt", "colour": "grey"}
      ]
    },
    "retail": {
      "standardFields": ["party", "paymentMethod", "dueDate", "reference", "notes", "lineItems"],
      "fields": [{"key": "sku", "label": "SKU / item code", "type": "text"}],
      "categories": [
        {"name": "Product sales", "kind": "income", "icon": "sell", "colour": "green", "fields": ["sku"]},
        {"name": "Stock purchases", "kind": "expense", "icon": "inventory", "colour": "amber", "fields": ["sku"]},
        {"name": "Supplier payments", "kind": "expense", "icon": "payments", "colour": "orange"},
        {"name": "Rent", "kind": "expense", "icon": "home", "colour": "purple"},
        {"name": "Utilities", "kind": "expense", "icon": "bolt", "colour": "blue"},
        {"name": "Other expenses", "kind": "expense", "icon": "receipt", "colour": "grey"}
      ]
    },
    "construction": {
      "standardFields": ["party", "paymentMethod", "dueDate", "reference", "notes", "lineItems", "project"],
      "fields": [
        {"key": "site", "label": "Site", "type": "text"},
        {"key": "unit", "label": "Unit", "type": "select", "options": ["bags", "kg", "tonnes", "m³", "ft", "nos", "days", "hours"]},
        {"key": "vehicle", "label": "Vehicle no.", "type": "text"}
      ],
      "categories": [
        {"name": "Contract income", "kind": "income", "icon": "sell", "colour": "green"},
        {"name": "Materials", "kind": "expense", "icon": "inventory", "colour": "amber", "fields": ["site", "unit"]},
        {"name": "Labour", "kind": "expense", "icon": "people", "colour": "blue", "fields": ["site"]},
        {"name": "Transport", "kind": "expense", "icon": "truck", "colour": "orange", "fields": ["vehicle"]},
        {"name": "Equipment rental", "kind": "expense", "icon": "build", "colour": "purple", "fields": ["site"]},
        {"name": "Contractor payments", "kind": "expense", "icon": "payments", "colour": "teal"},
        {"name": "Other expenses", "kind": "expense", "icon": "receipt", "colour": "grey"}
      ]
    },
    "services": {
      "standardFields": ["party", "paymentMethod", "dueDate", "reference", "notes", "lineItems", "project"],
      "fields": [{"key": "hours", "label": "Hours", "type": "number"}],
      "categories": [
        {"name": "Service fees", "kind": "income", "icon": "sell", "colour": "green", "fields": ["hours"]},
        {"name": "Retainers", "kind": "income", "icon": "savings", "colour": "teal"},
        {"name": "Software", "kind": "expense", "icon": "laptop", "colour": "blue"},
        {"name": "Travel", "kind": "expense", "icon": "flight", "colour": "orange"},
        {"name": "Subcontractors", "kind": "expense", "icon": "people", "colour": "purple"},
        {"name": "Other expenses", "kind": "expense", "icon": "receipt", "colour": "grey"}
      ]
    },
    "blank": {
      "standardFields": ["party", "paymentMethod", "dueDate", "reference", "notes"],
      "fields": [],
      "categories": []
    }
  }
  $json$::jsonb)->p_key
$$;

/** Today's calendar day in a time zone (UTC when the zone is unknown). */
create or replace function app.today_in(p_timezone text) returns date
language plpgsql stable set search_path = '' as $$
begin
  return (now() at time zone p_timezone)::date;
exception when others then
  return (now() at time zone 'UTC')::date;
end $$;
