-- Business Ledger on Supabase Postgres — transactions.receipt_date.
--
-- The date printed on the receipt or bill, kept beside the transaction's
-- own date (the day it was entered). A receipt scan fills it; the user can
-- change or clear it. It never counts in stats, overdue or documents.
-- Client-writable on drafts like the other draft columns (the table grant
-- covers every column; app.valid_draft has nothing to bound on a date).
-- editConfirmedTransaction accepts `receiptDate` (null clears it) and the
-- audit before/after includes it.

alter table public.transactions
  add column if not exists receipt_date date
    check (receipt_date >= date '2000-01-01');

/** camelCase view of the editable fields, for audit before/after. */
create or replace function app.tx_doc(t public.transactions) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'description', t.description, 'reference', t.reference, 'notes', t.notes,
    'paymentMethod', t.payment_method, 'date', to_char(t.date, 'YYYY-MM-DD'),
    'dueDate', to_char(t.due_date, 'YYYY-MM-DD'), 'receiptDate', to_char(t.receipt_date, 'YYYY-MM-DD'),
    'categoryId', t.category_id,
    'partyId', t.party_id, 'projectId', t.project_id, 'lineItems', t.line_items,
    'totalMinor', t.total_minor, 'customFields', t.custom_fields, 'categoryName', t.category_name,
    'partyName', t.party_name, 'projectName', t.project_name)
$$;

/**
 * Validates and normalises editConfirmed `changes` (schemas.ts, strict).
 * Keys: description, reference, notes, paymentMethod, date, dueDate, receiptDate,
 * categoryId, partyId, projectId, lineItems, totalMinor, customFields.
 */
create or replace function app.edit_changes(p_changes jsonb) returns jsonb
language plpgsql immutable set search_path = '' as $$
declare
  v_out jsonb := '{}'::jsonb;
  v_key text;
  v jsonb;
  v_line jsonb;
  v_lines jsonb;
  v_index integer;
  v_max integer;
  v_text text;
begin
  if p_changes is null or jsonb_typeof(p_changes) <> 'object' then
    perform app.invalid('Invalid changes.', 'changes');
  end if;
  for v_key, v in select key, value from jsonb_each(p_changes) loop
    case v_key
      when 'description', 'reference', 'notes', 'paymentMethod' then
        v_max := case v_key when 'description' then 200 when 'reference' then 80
                            when 'notes' then 2000 else 40 end;
        if jsonb_typeof(v) <> 'string' then perform app.invalid('Invalid value.', 'changes.' || v_key); end if;
        v_out := v_out || jsonb_build_object(v_key, app.arg_text(v #>> '{}', v_max, 'changes.' || v_key));
      when 'date' then
        if jsonb_typeof(v) <> 'string' or not app.is_calendar_date(v #>> '{}') then
          perform app.invalid('Use a yyyy-MM-dd date', 'changes.date');
        end if;
        v_out := v_out || jsonb_build_object(v_key, v);
      when 'dueDate', 'receiptDate' then
        if jsonb_typeof(v) <> 'null' and (jsonb_typeof(v) <> 'string' or not app.is_calendar_date(v #>> '{}')) then
          perform app.invalid('Use a yyyy-MM-dd date', 'changes.' || v_key);
        end if;
        v_out := v_out || jsonb_build_object(v_key, v);
      when 'categoryId', 'partyId', 'projectId' then
        if not (jsonb_typeof(v) = 'null' and v_key <> 'categoryId')
           and (jsonb_typeof(v) <> 'string' or not app.is_uuid(v #>> '{}')) then
          perform app.invalid('Invalid id', 'changes.' || v_key);
        end if;
        v_out := v_out || jsonb_build_object(v_key, v);
      when 'lineItems' then
        if jsonb_typeof(v) <> 'array' or jsonb_array_length(v) > 200 then
          perform app.invalid('Use at most 200 lines.', 'changes.lineItems');
        end if;
        v_lines := '[]'::jsonb;
        for v_line, v_index in select value, (ordinality - 1)::integer from jsonb_array_elements(v) with ordinality loop
          if jsonb_typeof(v_line) <> 'object' or jsonb_typeof(v_line->'description') is distinct from 'string'
             or app.json_safe_int(v_line->'quantityMilli') is null
             or (v_line->>'quantityMilli')::numeric not between 1 and app.max_minor()
             or app.json_safe_int(v_line->'rateMinor') is null
             or (v_line->>'rateMinor')::numeric not between 0 and app.max_minor()
             or app.json_safe_int(v_line->'amountMinor') is null
             or (v_line->>'amountMinor')::numeric not between 0 and app.max_minor() then
            perform app.invalid(format('Line %s is not valid.', v_index + 1), 'changes.lineItems.' || v_index);
          end if;
          v_text := app.arg_text(v_line->>'description', 200, 'changes.lineItems.' || v_index || '.description');
          v_lines := v_lines || jsonb_build_array(jsonb_build_object(
            'description', v_text, 'quantityMilli', v_line->'quantityMilli',
            'rateMinor', v_line->'rateMinor', 'amountMinor', v_line->'amountMinor'));
        end loop;
        v_out := v_out || jsonb_build_object(v_key, v_lines);
      when 'totalMinor' then
        if app.json_safe_int(v) is null or v::numeric not between 0 and app.max_minor() then
          perform app.invalid('Invalid amount.', 'changes.totalMinor');
        end if;
        v_out := v_out || jsonb_build_object(v_key, v);
      when 'customFields' then
        if jsonb_typeof(v) <> 'object' then perform app.invalid('Invalid value.', 'changes.customFields'); end if;
        v_out := v_out || jsonb_build_object(v_key, v);
      else
        perform app.invalid(format('Unrecognized key: "%s"', v_key), 'changes');
    end case;
  end loop;
  return v_out;
end $$;

/**
 * Changes a confirmed entry. Type and direction are fixed; stats move by
 * the difference; before/after go to the audit log. p_changes keeps the
 * camelCase keys of editConfirmedTransaction.
 * → {transactionId, version, paymentStatus}
 */
create or replace function public.edit_confirmed_transaction(
  p_business_id uuid,
  p_transaction_id uuid,
  p_request_id text,
  p_expected_version integer,
  p_changes jsonb
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_prior jsonb;
  c jsonb;
  t public.transactions;
  mg public.transactions;
  n public.transactions;
  v_refs record;
  v_total numeric;
  v_violation text;
  m app.money;
  v_tracked text[];
  v_before jsonb;
  v_after jsonb;
  v_diff jsonb;
begin
  perform app.arg_request_id(p_request_id);
  if p_expected_version is null or p_expected_version < 0 then
    perform app.invalid('Invalid version', 'expectedVersion');
  end if;
  c := app.edit_changes(p_changes);

  v_prior := app.request_begin(v_uid, p_request_id, 'editConfirmedTransaction');
  if v_prior is not null then return v_prior; end if;
  perform app.require_role(p_business_id, 'admin');
  t := app.load_tx(p_business_id, p_transaction_id, p_expected_version);
  if t.status <> 'confirmed' then
    perform app.fail('failed-precondition', 'Only confirmed transactions can be edited this way.', 'violation');
  end if;
  if t.link_kind = 'refund' then
    perform app.fail('failed-precondition', 'A refund entry changes through its original transaction.', 'violation');
  end if;

  mg := t;
  if c ? 'description' then mg.description := c->>'description'; end if;
  if c ? 'reference' then mg.reference := c->>'reference'; end if;
  if c ? 'notes' then mg.notes := c->>'notes'; end if;
  if c ? 'paymentMethod' then mg.payment_method := c->>'paymentMethod'; end if;
  if c ? 'date' then mg.date := (c->>'date')::date; end if;
  if c ? 'dueDate' then mg.due_date := (c->>'dueDate')::date; end if;
  if c ? 'receiptDate' then mg.receipt_date := (c->>'receiptDate')::date; end if;
  if c ? 'categoryId' then mg.category_id := (c->>'categoryId')::uuid; end if;
  if c ? 'partyId' then mg.party_id := (c->>'partyId')::uuid; end if;
  if c ? 'projectId' then mg.project_id := (c->>'projectId')::uuid; end if;
  if c ? 'lineItems' then mg.line_items := c->'lineItems'; end if;
  if c ? 'totalMinor' then mg.total_minor := (c->>'totalMinor')::bigint; end if;
  if c ? 'customFields' then mg.custom_fields := c->'customFields'; end if;

  perform app.check_dates(mg.date, mg.due_date);
  select * into v_refs from app.read_references(
    p_business_id, t.type, mg.category_id, mg.party_id, mg.project_id, t.direction);
  perform app.check_required_fields(mg.custom_fields, v_refs.required);

  v_total := app.total_of(mg.line_items, mg.total_minor);
  v_violation := app.check_total_edit(t.total_minor, t.paid_minor, t.refunded_minor, t.credited_minor, v_total);
  if v_violation is not null then perform app.violation(v_violation); end if;
  if t.type = 'payment' and v_total <> t.total_minor then
    perform app.fail('failed-precondition',
      'A payment entry''s amount cannot change. Cancel it and record a new one.', 'violation');
  end if;

  m := app.money_fields(t.type, 'confirmed', v_total::bigint, t.paid_minor, t.refunded_minor, t.credited_minor);
  update public.transactions set
    description = mg.description, reference = mg.reference, notes = mg.notes,
    payment_method = mg.payment_method, date = mg.date, due_date = mg.due_date,
    receipt_date = mg.receipt_date,
    category_id = mg.category_id, party_id = mg.party_id, project_id = mg.project_id,
    line_items = mg.line_items, custom_fields = mg.custom_fields,
    category_name = v_refs.category_name, party_name = v_refs.party_name, project_name = v_refs.project_name,
    total_minor = m.total_minor, paid_minor = m.paid_minor, refunded_minor = m.refunded_minor,
    credited_minor = m.credited_minor, effective_minor = m.effective_minor,
    outstanding_minor = m.outstanding_minor, payment_status = m.payment_status, is_open = m.is_open,
    version = t.version + 1, updated_by = v_uid,
    search_tokens = app.search_tokens(array[mg.description, mg.reference, v_refs.party_name,
                                            v_refs.category_name, v_refs.project_name])
  where id = t.id
  returning * into n;

  perform app.apply_stats(p_business_id, app.stats_diff(app.tx_state(t), app.tx_state(n)));

  v_tracked := array(select jsonb_object_keys(c)) || array['totalMinor', 'categoryName', 'partyName', 'projectName'];
  select coalesce(jsonb_object_agg(k, coalesce(app.tx_doc(t)->k, 'null'::jsonb)), '{}'::jsonb),
         coalesce(jsonb_object_agg(k, coalesce(app.tx_doc(n)->k, 'null'::jsonb)), '{}'::jsonb)
    into v_before, v_after
    from (select distinct unnest(v_tracked) as k) keys;
  v_diff := app.changed_keys(v_before, v_after);
  perform app.audit(p_business_id, 'transaction', t.id::text, 'edit', v_uid, v_diff->'before', v_diff->'after');

  return app.request_end(v_uid, p_request_id, 'editConfirmedTransaction', jsonb_build_object(
    'transactionId', t.id, 'version', n.version, 'paymentStatus', m.payment_status));
end $$;
