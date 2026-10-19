-- Business Ledger on Supabase Postgres — 2/7: the ledger rules.
--
-- Port of functions/src/ledger.ts (and lib/transaction.ts moneyFields). Pure,
-- immutable functions; the test suite runs shared/ledger_cases.json against
-- them, the same fixtures the Dart and TypeScript implementations run.
-- Change a rule → change all three + the fixtures. ARCHITECTURE.md §5.
--
--   payable     = T − C          outstanding = T − C − P
--   netPaid     = P − R          effective   = T − C − R

create or replace function app.max_minor() returns bigint
language sql immutable set search_path = '' as $$ select 10000000000000::bigint $$;

-- ---------------------------------------------------------------------------
-- Transaction types (TYPE_INFO)
-- ---------------------------------------------------------------------------

/** 'in'/'out' when the type fixes it; null when chosen per entry. */
create or replace function app.type_fixed_direction(p_type text) returns text
language sql immutable set search_path = '' as $$
  select case p_type
    when 'income' then 'in' when 'sale' then 'in'
    when 'expense' then 'out' when 'purchase' then 'out'
  end
$$;

create or replace function app.type_settleable(p_type text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(p_type in ('income', 'sale', 'expense', 'purchase', 'payment'), false)
$$;

create or replace function app.type_creatable(p_type text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(p_type in ('income', 'sale', 'expense', 'purchase', 'payment', 'adjustment'), false)
$$;

/** Whether its effective amount is income/expense (vs. cash only). */
create or replace function app.type_recognised(p_type text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(p_type in ('income', 'sale', 'expense', 'purchase', 'adjustment'), false)
$$;

/** invoice / bill / null. Receipts come from settlements. */
create or replace function app.type_document(p_type text) returns text
language sql immutable set search_path = '' as $$
  select case p_type
    when 'income' then 'invoice' when 'sale' then 'invoice'
    when 'expense' then 'bill' when 'purchase' then 'bill'
  end
$$;

create or replace function app.direction_of(p_type text, p_chosen text) returns text
language sql immutable set search_path = '' as $$
  select coalesce(app.type_fixed_direction(p_type), p_chosen)
$$;

-- ---------------------------------------------------------------------------
-- Balance arithmetic
-- ---------------------------------------------------------------------------

create or replace function app.outstanding(p_total numeric, p_paid numeric, p_refunded numeric, p_credited numeric)
returns numeric language sql immutable set search_path = '' as $$
  select p_total - p_credited - p_paid
$$;

create or replace function app.effective(p_total numeric, p_paid numeric, p_refunded numeric, p_credited numeric)
returns numeric language sql immutable set search_path = '' as $$
  select p_total - p_credited - p_refunded
$$;

create or replace function app.net_paid(p_paid numeric, p_refunded numeric)
returns numeric language sql immutable set search_path = '' as $$
  select p_paid - p_refunded
$$;

create or replace function app.violation_message(p_key text) returns text
language sql immutable set search_path = '' as $$
  select case p_key
    when 'nonPositiveAmount' then 'Enter an amount greater than zero.'
    when 'amountTooLarge' then 'That amount is too large.'
    when 'notConfirmed' then 'Only confirmed transactions can be settled.'
    when 'notSettleable' then 'This type of transaction does not take payments.'
    when 'overpayment' then 'That is more than the outstanding balance.'
    when 'overRefund' then 'That is more than has been paid.'
    when 'overCredit' then 'A credit cannot exceed the outstanding balance.'
    when 'totalBelowSettled' then 'The total cannot be less than what has already been paid or credited.'
    when 'cancelWithMoney' then 'Refund the payments on this transaction before cancelling it.'
    when 'alreadyCancelled' then 'This transaction is already cancelled.'
    when 'draftOnly' then 'Only drafts can be changed this way.'
  end
$$;

/** Raises failed-precondition with the violation's user-safe message. */
create or replace function app.violation(p_key text) returns void
language plpgsql immutable set search_path = '' as $$
begin
  perform app.fail('failed-precondition', app.violation_message(p_key), 'violation',
    jsonb_build_object('violation', p_key));
end $$;

create or replace function app.payment_status_of(
  p_total numeric, p_paid numeric, p_refunded numeric, p_credited numeric, p_settleable boolean
) returns text language sql immutable set search_path = '' as $$
  select case
    when not p_settleable then 'notApplicable'
    when p_refunded > 0 then case when p_refunded >= p_paid then 'refunded' else 'partiallyRefunded' end
    when app.outstanding(p_total, p_paid, p_refunded, p_credited) <= 0 then 'paid'
    when p_paid > 0 or p_credited > 0 then 'partiallyPaid'
    else 'unpaid'
  end
$$;

create or replace function app.is_overdue(p_status text, p_outstanding numeric, p_due_date date, p_today date)
returns boolean language sql immutable set search_path = '' as $$
  select p_status = 'confirmed' and p_outstanding > 0 and p_due_date is not null and p_due_date < p_today
$$;

/** Violation key or null. Non-integers count as non-positive, like Number.isSafeInteger. */
create or replace function app.check_amount(p_amount numeric) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_amount is null or p_amount <> trunc(p_amount) or p_amount <= 0 then 'nonPositiveAmount'
    when p_amount > app.max_minor() then 'amountTooLarge'
  end
$$;

create or replace function app.check_settlement(
  p_kind text, p_total numeric, p_paid numeric, p_refunded numeric, p_credited numeric,
  p_amount numeric, p_status text, p_settleable boolean
) returns text language sql immutable set search_path = '' as $$
  select coalesce(
    app.check_amount(p_amount),
    case
      when p_status is distinct from 'confirmed' then 'notConfirmed'
      when not p_settleable then 'notSettleable'
      when p_kind = 'payment' and p_amount > app.outstanding(p_total, p_paid, p_refunded, p_credited) then 'overpayment'
      when p_kind = 'credit' and p_amount > app.outstanding(p_total, p_paid, p_refunded, p_credited) then 'overCredit'
      when p_kind = 'refund' and p_amount > app.net_paid(p_paid, p_refunded) then 'overRefund'
    end
  )
$$;

create or replace function app.check_total_edit(
  p_total numeric, p_paid numeric, p_refunded numeric, p_credited numeric, p_new_total numeric
) returns text language sql immutable set search_path = '' as $$
  select coalesce(
    app.check_amount(p_new_total),
    case when p_new_total < p_paid + p_credited then 'totalBelowSettled' end
  )
$$;

create or replace function app.check_cancel(p_paid numeric, p_refunded numeric, p_status text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_status = 'cancelled' then 'alreadyCancelled'
    when app.net_paid(p_paid, p_refunded) <> 0 then 'cancelWithMoney'
  end
$$;

/**
 * quantity (thousandths) × rate (minor units), rounded half away from zero
 * to a whole minor unit. numeric, so a huge product never loses precision.
 */
create or replace function app.line_amount(p_quantity_milli numeric, p_rate_minor numeric) returns numeric
language sql immutable set search_path = '' as $$
  select sign(p_quantity_milli * p_rate_minor) * floor((abs(p_quantity_milli * p_rate_minor) + 500) / 1000)
$$;

/**
 * Lowercase word prefixes (max 15 chars per word, 200 tokens, sorted by
 * code point) for search. Mirrors searchTokens() / SearchTokens.of.
 * Word characters: [[:alnum:]] (Unicode letters and digits in a UTF-8
 * database), the SQL spelling of /[\p{L}\p{N}]/u.
 */
create or replace function app.search_tokens(p_parts text[]) returns text[]
language sql immutable set search_path = '' as $$
  select coalesce(array_agg(tok order by tok), '{}'::text[])
  from (
    select distinct left(w, i) collate "C" as tok
    from unnest(p_parts) as p(part)
    cross join lateral regexp_split_to_table(lower(p.part), '[^[:alnum:]]+') as w
    cross join lateral generate_series(1, least(length(w), 15)) as i
    where p.part is not null and w <> ''
    order by tok
    limit 200
  ) s
$$;

-- ---------------------------------------------------------------------------
-- Stored money figures (lib/transaction.ts moneyFields)
-- ---------------------------------------------------------------------------

do $$ begin
  create type app.money as (
    total_minor bigint,
    paid_minor bigint,
    refunded_minor bigint,
    credited_minor bigint,
    effective_minor bigint,
    outstanding_minor bigint,
    payment_status text,
    is_open boolean
  );
exception when duplicate_object then null; end $$;

/** Every stored figure that follows from the balance. Written together. */
create or replace function app.money_fields(
  p_type text, p_status text, p_total bigint, p_paid bigint, p_refunded bigint, p_credited bigint
) returns app.money language sql immutable set search_path = '' as $$
  select row(
    p_total, p_paid, p_refunded, p_credited,
    app.effective(p_total, p_paid, p_refunded, p_credited)::bigint,
    owed::bigint,
    app.payment_status_of(p_total, p_paid, p_refunded, p_credited, app.type_settleable(p_type)),
    p_status = 'confirmed' and owed > 0
  )::app.money
  from (select case when app.type_settleable(p_type)
                    then app.outstanding(p_total, p_paid, p_refunded, p_credited) else 0 end as owed) s
$$;

/** camelCase JSON of money fields (settlement balance_after, receipts). */
create or replace function app.money_json(m app.money) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'totalMinor', m.total_minor, 'paidMinor', m.paid_minor, 'refundedMinor', m.refunded_minor,
    'creditedMinor', m.credited_minor, 'effectiveMinor', m.effective_minor,
    'outstandingMinor', m.outstanding_minor, 'paymentStatus', m.payment_status, 'isOpen', m.is_open)
$$;

-- ---------------------------------------------------------------------------
-- Stats deltas (lib/stats.ts): {"yyyy-MM-dd": {"path": amount}}
-- paths: income_minor, expense_minor, cash_in_minor, cash_out_minor,
--        by_type.<type>.<in|out>, by_category.<id>.<in|out>, by_project.<id>.<in|out>
-- A tx state is jsonb {type, direction, status, date, categoryId, projectId,
-- total, paid, refunded, credited}.
-- ---------------------------------------------------------------------------

create or replace function app.stats_add(p_delta jsonb, p_date text, p_path text, p_amount numeric) returns jsonb
language sql immutable set search_path = '' as $$
  select case when p_amount = 0 then p_delta else
    jsonb_set(p_delta, array[p_date],
      coalesce(p_delta->p_date, '{}'::jsonb)
        || jsonb_build_object(p_path, coalesce((p_delta->p_date->>p_path)::numeric, 0) + p_amount))
  end
$$;

/** What a transaction adds to income/expense by its own date. */
create or replace function app.stats_recognised(s jsonb) returns jsonb
language plpgsql immutable set search_path = '' as $$
declare
  d jsonb := '{}'::jsonb;
  v_amount numeric;
  v_side text;
  v_date text;
begin
  if s is null or s->>'status' is distinct from 'confirmed'
     or not app.type_recognised(s->>'type') or s->>'direction' is null then
    return d;
  end if;
  v_amount := app.effective((s->>'total')::numeric, (s->>'paid')::numeric,
                            (s->>'refunded')::numeric, (s->>'credited')::numeric);
  v_side := s->>'direction';
  v_date := s->>'date';
  d := app.stats_add(d, v_date, case v_side when 'in' then 'income_minor' else 'expense_minor' end, v_amount);
  d := app.stats_add(d, v_date, 'by_type.' || (s->>'type') || '.' || v_side, v_amount);
  if nullif(s->>'categoryId', '') is not null then
    d := app.stats_add(d, v_date, 'by_category.' || (s->>'categoryId') || '.' || v_side, v_amount);
  end if;
  if nullif(s->>'projectId', '') is not null then
    d := app.stats_add(d, v_date, 'by_project.' || (s->>'projectId') || '.' || v_side, v_amount);
  end if;
  return d;
end $$;

/** Cash moved by one settlement on its date; a refund flows the other way, a credit moves none. */
create or replace function app.stats_cash(p_kind text, p_direction text, p_amount numeric, p_date text) returns jsonb
language sql immutable set search_path = '' as $$
  select case
    when p_kind = 'credit' then '{}'::jsonb
    else app.stats_add('{}'::jsonb, p_date,
      case when (case when p_kind = 'payment' then p_direction
                      when p_direction = 'in' then 'out' else 'in' end) = 'in'
           then 'cash_in_minor' else 'cash_out_minor' end,
      p_amount)
  end
$$;

create or replace function app.stats_merge(p_into jsonb, p_from jsonb, p_sign integer) returns jsonb
language plpgsql immutable set search_path = '' as $$
declare
  d jsonb := p_into;
  r record;
begin
  for r in
    select day.key as date, item.key as path, item.value::numeric as amount
    from jsonb_each(coalesce(p_from, '{}'::jsonb)) as day
    cross join lateral jsonb_each_text(day.value) as item
  loop
    d := app.stats_add(d, r.date, r.path, p_sign * r.amount);
  end loop;
  return d;
end $$;

/** after − before, plus extra deltas; zero entries and empty days dropped. */
create or replace function app.stats_diff(p_before jsonb, p_after jsonb, p_extra jsonb default '{}'::jsonb)
returns jsonb language sql immutable set search_path = '' as $$
  select coalesce(jsonb_object_agg(date, day), '{}'::jsonb)
  from (
    select day.key as date, jsonb_object_agg(item.key, item.value) as day
    from jsonb_each(
      app.stats_merge(app.stats_merge(app.stats_merge('{}'::jsonb,
        app.stats_recognised(p_after), 1), app.stats_recognised(p_before), -1), p_extra, 1)) as day
    cross join lateral jsonb_each(day.value) as item
    where item.value::numeric <> 0
    group by day.key
  ) s
$$;
