-- Business Ledger on Supabase Postgres — 7/7: money RPCs and documents.
--
-- Ports of functions/src/handlers/{transactions,documents}.ts. Each runs in
-- one transaction: the transaction row is locked (select … for update), the
-- balance re-read and re-checked, and the row, settlement, stats delta and
-- audit entry written together. Idempotent by (uid, request id).

/**
 * Validates a draft and makes it count. With p_settle_now (and always for
 * a payment entry) the full amount is settled in the same write.
 * → {transactionId, version, paymentStatus, settlementId}
 */
create or replace function public.confirm_transaction(
  p_business_id uuid,
  p_transaction_id uuid,
  p_request_id text,
  p_expected_version integer default null,
  p_settle_now boolean default null,
  p_settle_date text default null,
  p_settle_method text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_prior jsonb;
  v_settle_date date;
  v_settle_method text;
  t public.transactions;
  n public.transactions;
  v_direction text;
  v_total numeric;
  v_violation text;
  v_refs record;
  v_settle boolean;
  m app.money;
  v_extra jsonb := '{}'::jsonb;
  v_settlement_id text;
  v_date date;
begin
  perform app.arg_request_id(p_request_id);
  if p_expected_version < 0 then perform app.invalid('Invalid version', 'expectedVersion'); end if;
  v_settle_date := app.arg_date(p_settle_date, 'settleDate');
  v_settle_method := app.arg_text(p_settle_method, 40, 'settleMethod');

  v_prior := app.request_begin(v_uid, p_request_id, 'confirmTransaction');
  if v_prior is not null then return v_prior; end if;
  perform app.require_role(p_business_id, 'admin');
  t := app.load_tx(p_business_id, p_transaction_id, p_expected_version);
  if t.status <> 'draft' then perform app.violation('draftOnly'); end if;

  if not app.type_creatable(t.type) then perform app.invalid('Choose a transaction type.', 'type'); end if;
  v_direction := app.direction_of(t.type, t.direction);
  if v_direction is null then
    perform app.invalid('Choose whether money is coming in or going out.', 'direction');
  end if;
  perform app.check_dates(t.date, t.due_date);
  v_total := app.total_of(t.line_items, t.total_minor);
  v_violation := app.check_total_edit(0, 0, 0, 0, v_total);
  if v_violation is not null then perform app.violation(v_violation); end if;

  select * into v_refs from app.read_references(
    p_business_id, t.type, t.category_id, t.party_id, t.project_id, v_direction);
  perform app.check_required_fields(t.custom_fields, v_refs.required);

  v_settle := t.type = 'payment' or coalesce(p_settle_now, false);
  m := app.money_fields(t.type, 'confirmed', v_total::bigint,
                        case when v_settle then v_total::bigint else 0 end, 0, 0);

  update public.transactions set
    status = 'confirmed', direction = v_direction,
    category_name = v_refs.category_name, party_name = v_refs.party_name, project_name = v_refs.project_name,
    total_minor = m.total_minor, paid_minor = m.paid_minor, refunded_minor = m.refunded_minor,
    credited_minor = m.credited_minor, effective_minor = m.effective_minor,
    outstanding_minor = m.outstanding_minor, payment_status = m.payment_status, is_open = m.is_open,
    version = t.version + 1, confirmed_at = now(), confirmed_by = v_uid, updated_by = v_uid,
    search_tokens = app.search_tokens(array[t.description, t.reference, v_refs.party_name,
                                            v_refs.category_name, v_refs.project_name])
  where id = t.id
  returning * into n;

  if v_settle then
    v_date := coalesce(v_settle_date, t.date);
    v_settlement_id := p_request_id;
    insert into public.settlements (
      business_id, transaction_id, id, kind, amount_minor, date, method, note, balance_after, created_by)
    values (
      p_business_id, t.id, v_settlement_id, 'payment', m.total_minor, v_date,
      coalesce(v_settle_method, t.payment_method, ''), '', app.money_json(m), v_uid);
    v_extra := app.stats_cash('payment', v_direction, m.total_minor, to_char(v_date, 'YYYY-MM-DD'));
  end if;

  perform app.apply_stats(p_business_id, app.stats_diff(null, app.tx_state(n), v_extra));
  perform app.audit(p_business_id, 'transaction', t.id::text,
    case when v_settle then 'confirmAndSettle' else 'confirm' end, v_uid, null,
    jsonb_build_object('totalMinor', m.total_minor, 'paymentStatus', m.payment_status));
  return app.request_end(v_uid, p_request_id, 'confirmTransaction', jsonb_build_object(
    'transactionId', t.id, 'version', n.version, 'paymentStatus', m.payment_status,
    'settlementId', v_settlement_id));
end $$;

/**
 * Validates and normalises editConfirmed `changes` (schemas.ts, strict).
 * Keys: description, reference, notes, paymentMethod, date, dueDate,
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
      when 'dueDate' then
        if jsonb_typeof(v) <> 'null' and (jsonb_typeof(v) <> 'string' or not app.is_calendar_date(v #>> '{}')) then
          perform app.invalid('Use a yyyy-MM-dd date', 'changes.dueDate');
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

/**
 * Voids a confirmed entry: it stays in history, drops out of every figure,
 * and its documents are marked void. Money must be refunded first.
 * → {transactionId, version, voidedDocuments}
 */
create or replace function public.cancel_transaction(
  p_business_id uuid,
  p_transaction_id uuid,
  p_request_id text,
  p_expected_version integer default null,
  p_reason text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_prior jsonb;
  v_reason text;
  t public.transactions;
  n public.transactions;
  v_violation text;
  m app.money;
  v_voided integer;
begin
  perform app.arg_request_id(p_request_id);
  if p_expected_version < 0 then perform app.invalid('Invalid version', 'expectedVersion'); end if;
  v_reason := app.arg_text(p_reason, 500, 'reason');

  v_prior := app.request_begin(v_uid, p_request_id, 'cancelTransaction');
  if v_prior is not null then return v_prior; end if;
  perform app.require_role(p_business_id, 'admin');
  t := app.load_tx(p_business_id, p_transaction_id, p_expected_version);
  if t.status = 'draft' then
    perform app.fail('failed-precondition', 'Drafts are deleted, not cancelled.', 'violation');
  end if;
  if t.link_kind = 'refund' then
    perform app.fail('failed-precondition', 'A refund entry cannot be cancelled on its own.', 'violation');
  end if;
  v_violation := app.check_cancel(t.paid_minor, t.refunded_minor, t.status);
  if v_violation is not null then perform app.violation(v_violation); end if;

  m := app.money_fields(t.type, 'cancelled', t.total_minor, t.paid_minor, t.refunded_minor, t.credited_minor);
  update public.transactions set
    status = 'cancelled',
    total_minor = m.total_minor, paid_minor = m.paid_minor, refunded_minor = m.refunded_minor,
    credited_minor = m.credited_minor, effective_minor = m.effective_minor,
    outstanding_minor = m.outstanding_minor, payment_status = m.payment_status, is_open = m.is_open,
    cancel_reason = coalesce(v_reason, ''), cancelled_at = now(), cancelled_by = v_uid,
    version = t.version + 1, updated_by = v_uid
  where id = t.id
  returning * into n;

  update public.documents set voided = true, voided_at = now()
    where business_id = p_business_id and transaction_id = t.id;
  get diagnostics v_voided = row_count;

  perform app.apply_stats(p_business_id, app.stats_diff(app.tx_state(t), app.tx_state(n)));
  perform app.audit(p_business_id, 'transaction', t.id::text, 'cancel', v_uid,
    jsonb_build_object('status', 'confirmed'), jsonb_build_object('status', 'cancelled'), v_reason);
  return app.request_end(v_uid, p_request_id, 'cancelTransaction', jsonb_build_object(
    'transactionId', t.id, 'version', n.version, 'voidedDocuments', v_voided));
end $$;

/**
 * Records a payment, refund or credit. The request id is the settlement id.
 * A refund also creates a linked `refund` entry for the list (no money
 * effect of its own: stats exclude it, the original carries it).
 * → {settlementId, transactionId, linkedTransactionId, version, paymentStatus, outstandingMinor}
 */
create or replace function public.record_settlement(
  p_business_id uuid,
  p_transaction_id uuid,
  p_request_id text,
  p_kind text,
  p_amount_minor bigint,
  p_date text,
  p_method text default null,
  p_note text default null,
  p_expected_version integer default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_prior jsonb;
  v_date date;
  v_method text;
  v_note text;
  t public.transactions;
  n public.transactions;
  v_violation text;
  m app.money;
  rm app.money;
  v_linked uuid;
  v_before_outstanding bigint;
begin
  perform app.arg_request_id(p_request_id);
  if p_expected_version < 0 then perform app.invalid('Invalid version', 'expectedVersion'); end if;
  if p_kind is null or p_kind not in ('payment', 'refund', 'credit') then
    perform app.invalid('Choose payment, refund or credit.', 'kind');
  end if;
  if p_amount_minor is null then perform app.invalid('Enter an amount.', 'amountMinor'); end if;
  if p_date is null then perform app.invalid('Use a yyyy-MM-dd date', 'date'); end if;
  v_date := app.arg_date(p_date, 'date');
  v_method := app.arg_text(p_method, 40, 'method');
  v_note := app.arg_text(p_note, 500, 'note');

  v_prior := app.request_begin(v_uid, p_request_id, 'recordSettlement');
  if v_prior is not null then return v_prior; end if;
  perform app.require_role(p_business_id, 'admin');
  t := app.load_tx(p_business_id, p_transaction_id, p_expected_version);

  v_violation := app.check_settlement(p_kind, t.total_minor, t.paid_minor, t.refunded_minor, t.credited_minor,
                                      p_amount_minor, t.status, app.type_settleable(t.type));
  if v_violation is not null then perform app.violation(v_violation); end if;

  v_before_outstanding := (app.money_fields(t.type, 'confirmed', t.total_minor, t.paid_minor,
                                            t.refunded_minor, t.credited_minor)).outstanding_minor;
  m := app.money_fields(t.type, 'confirmed', t.total_minor,
    t.paid_minor + case when p_kind = 'payment' then p_amount_minor else 0 end,
    t.refunded_minor + case when p_kind = 'refund' then p_amount_minor else 0 end,
    t.credited_minor + case when p_kind = 'credit' then p_amount_minor else 0 end);
  update public.transactions set
    paid_minor = m.paid_minor, refunded_minor = m.refunded_minor, credited_minor = m.credited_minor,
    effective_minor = m.effective_minor, outstanding_minor = m.outstanding_minor,
    payment_status = m.payment_status, is_open = m.is_open,
    version = t.version + 1, updated_by = v_uid
  where id = t.id
  returning * into n;

  if p_kind = 'refund' then
    v_linked := gen_random_uuid();
    rm := app.money_fields('refund', 'confirmed', p_amount_minor, 0, 0, 0);
    insert into public.transactions (
      id, business_id, type, direction, status, description, reference, notes, payment_method,
      category_id, category_name, party_id, party_name, project_id, project_name, date, due_date,
      line_items, total_minor, paid_minor, refunded_minor, credited_minor, effective_minor,
      outstanding_minor, payment_status, is_open, custom_fields, linked_transaction_id, link_kind,
      settlement_id, search_tokens, version, created_by, confirmed_at, confirmed_by)
    values (
      v_linked, p_business_id, 'refund', case when t.direction = 'in' then 'out' else 'in' end, 'confirmed',
      'Refund · ' || coalesce(nullif(t.description, ''), nullif(t.category_name, ''), 'transaction'),
      t.reference, coalesce(v_note, ''), coalesce(v_method, ''),
      t.category_id, t.category_name, t.party_id, t.party_name, t.project_id, t.project_name, v_date, null,
      '[]'::jsonb, rm.total_minor, rm.paid_minor, rm.refunded_minor, rm.credited_minor, rm.effective_minor,
      rm.outstanding_minor, rm.payment_status, rm.is_open, '{}'::jsonb, t.id, 'refund',
      p_request_id,
      app.search_tokens(array['Refund · ' || coalesce(nullif(t.description, ''), nullif(t.category_name, ''),
                              'transaction'), t.reference, t.party_name, t.category_name, t.project_name]),
      1, v_uid, now(), v_uid);
  end if;

  insert into public.settlements (
    business_id, transaction_id, id, kind, amount_minor, date, method, note, balance_after,
    linked_transaction_id, created_by)
  values (
    p_business_id, t.id, p_request_id, p_kind, p_amount_minor, v_date, coalesce(v_method, ''),
    coalesce(v_note, ''), app.money_json(m), v_linked, v_uid);

  perform app.apply_stats(p_business_id, app.stats_diff(app.tx_state(t), app.tx_state(n),
    app.stats_cash(p_kind, t.direction, p_amount_minor, to_char(v_date, 'YYYY-MM-DD'))));
  perform app.audit(p_business_id, 'settlement', p_request_id, p_kind, v_uid,
    jsonb_build_object('outstandingMinor', v_before_outstanding),
    jsonb_build_object('amountMinor', p_amount_minor, 'outstandingMinor', m.outstanding_minor,
                       'transactionId', t.id));
  return app.request_end(v_uid, p_request_id, 'recordSettlement', jsonb_build_object(
    'settlementId', p_request_id, 'transactionId', t.id, 'linkedTransactionId', v_linked,
    'version', n.version, 'paymentStatus', m.payment_status, 'outstandingMinor', m.outstanding_minor));
end $$;

/**
 * Issues an invoice, bill or receipt with a gap-free PREFIX-YYYY-NNNN
 * number (per business, type and year in the business time zone) and a
 * text snapshot the device renders the PDF from. The id is derived from
 * what it documents, so asking twice returns the same document.
 * → {documentId, number, created}
 */
create or replace function public.issue_document(
  p_business_id uuid,
  p_transaction_id uuid,
  p_type text,
  p_request_id text,
  p_settlement_id text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_prior jsonb;
  v_document_id text;
  d public.documents;
  t public.transactions;
  b public.businesses;
  s public.settlements;
  p public.parties;
  v_counter public.counters;
  v_year integer;
  v_next integer;
  v_prefix text;
  v_seq text;
  v_number text;
  v_party jsonb;
  v_snapshot jsonb;
begin
  if p_type is null or p_type not in ('invoice', 'bill', 'receipt') then
    perform app.invalid('Choose invoice, bill or receipt.', 'type');
  end if;
  if p_settlement_id is not null and p_settlement_id !~ '^[^/]{1,128}$' then
    perform app.invalid('Invalid id', 'settlementId');
  end if;
  perform app.arg_request_id(p_request_id);

  v_prior := app.request_begin(v_uid, p_request_id, 'issueDocument');
  if v_prior is not null then return v_prior; end if;
  perform app.require_role(p_business_id, 'editor');
  v_document_id := p_type || '-' || p_transaction_id || '-' || coalesce(p_settlement_id, 'main');

  select * into d from public.documents where business_id = p_business_id and id = v_document_id;
  if found and not d.voided then
    return app.request_end(v_uid, p_request_id, 'issueDocument',
      jsonb_build_object('documentId', v_document_id, 'number', d.number, 'created', false));
  end if;

  -- Shared lock: a concurrent cancel (which voids documents) waits for us.
  t := app.load_tx(p_business_id, p_transaction_id, null, 'share');
  if t.status = 'cancelled' then
    perform app.fail('failed-precondition', 'Cancelled transactions cannot issue documents.', 'violation');
  end if;
  if t.status <> 'confirmed' then
    perform app.fail('failed-precondition', 'Confirm the transaction before issuing a document.', 'violation');
  end if;

  if p_type = 'receipt' then
    if p_settlement_id is null then
      perform app.fail('invalid-argument', 'Choose the payment to issue a receipt for.', 'validation');
    end if;
    select * into s from public.settlements where transaction_id = t.id and id = p_settlement_id;
    if not found then perform app.fail('not-found', 'That payment was not found.', 'notFound'); end if;
    if s.kind <> 'payment' or s.voided then
      perform app.fail('failed-precondition', 'Receipts are issued for recorded payments only.', 'violation');
    end if;
  elsif app.type_document(t.type) is distinct from p_type then
    perform app.fail('failed-precondition', format('A %s does not produce a %s.', t.type, p_type), 'violation');
  end if;

  if t.party_id is not null then
    select * into p from public.parties where id = t.party_id and business_id = p_business_id;
  end if;
  select * into b from public.businesses where id = p_business_id;

  insert into public.counters (business_id, doc_type, year, next) values (p_business_id, p_type, 0, 1)
    on conflict (business_id, doc_type) do nothing;
  select * into v_counter from public.counters
    where business_id = p_business_id and doc_type = p_type for update;
  v_year := extract(year from app.today_in(b.timezone))::integer;
  v_next := case when v_counter.year = v_year then v_counter.next else 1 end;
  v_prefix := app.trim_text(coalesce(nullif(b.settings->>(p_type || 'Prefix'), ''), upper(p_type)));
  v_seq := v_next::text;
  v_number := v_prefix || '-' || v_year || '-' || case when length(v_seq) >= 4 then v_seq else lpad(v_seq, 4, '0') end;

  v_party := case
    when p.id is not null then jsonb_build_object('name', coalesce(p.name, ''), 'address', coalesce(p.address, ''),
                                                  'phone', coalesce(p.phone, ''), 'email', coalesce(p.email, ''))
    when nullif(t.party_name, '') is not null then jsonb_build_object('name', t.party_name, 'address', '',
                                                                      'phone', '', 'email', '')
  end;
  v_snapshot := jsonb_build_object(
    'business', jsonb_build_object(
      'name', b.name, 'address', coalesce(b.settings->>'address', ''), 'phone', coalesce(b.settings->>'phone', ''),
      'email', coalesce(b.settings->>'email', ''), 'taxId', coalesce(b.settings->>'taxId', ''),
      'currency', jsonb_build_object('code', b.currency_code, 'decimals', b.currency_decimals,
                                     'symbol', b.currency_symbol)),
    'party', v_party,
    'transaction', jsonb_build_object(
      'type', t.type, 'direction', t.direction, 'description', t.description, 'reference', t.reference,
      'date', to_char(t.date, 'YYYY-MM-DD'), 'dueDate', to_char(t.due_date, 'YYYY-MM-DD'),
      'categoryName', t.category_name, 'projectName', t.project_name, 'paymentMethod', t.payment_method,
      'notes', t.notes, 'lineItems', t.line_items, 'totalMinor', t.total_minor,
      'creditedMinor', t.credited_minor, 'paidMinor', t.paid_minor, 'refundedMinor', t.refunded_minor,
      'outstandingMinor', t.outstanding_minor, 'paymentStatus', t.payment_status),
    -- For a receipt, the balance as it stood right after this payment.
    'settlement', case when s.id is not null then jsonb_build_object(
      'amountMinor', s.amount_minor, 'date', to_char(s.date, 'YYYY-MM-DD'), 'method', s.method,
      'note', s.note, 'paidToDateMinor', s.balance_after->'paidMinor',
      'remainingMinor', s.balance_after->'outstandingMinor') end);

  update public.counters set year = v_year, next = v_next + 1
    where business_id = p_business_id and doc_type = p_type;
  insert into public.documents (business_id, id, type, number, transaction_id, settlement_id, snapshot, issued_by)
  values (p_business_id, v_document_id, p_type, v_number, t.id, p_settlement_id, v_snapshot, v_uid)
  on conflict (business_id, id) do update set
    number = excluded.number, snapshot = excluded.snapshot, issued_at = now(),
    issued_by = excluded.issued_by, voided = false, voided_at = null;

  perform app.audit(p_business_id, 'document', v_document_id, 'issue', v_uid, null,
    jsonb_build_object('number', v_number, 'transactionId', t.id));
  return app.request_end(v_uid, p_request_id, 'issueDocument',
    jsonb_build_object('documentId', v_document_id, 'number', v_number, 'created', true));
end $$;

-- ---------------------------------------------------------------------------
-- Function privileges (final)
-- ---------------------------------------------------------------------------

-- Internal helpers: only the RLS helpers are callable by client roles.
revoke execute on all functions in schema app from public, anon, authenticated;
grant execute on function
  app.firebase_project(), app.claims(), app.uid(), app.is_client(), app.role_in(uuid), app.is_member(uuid),
  app.has_role(uuid, app.member_role), app.valid_draft(public.transactions), app.max_minor(),
  app.fail(text, text, text, jsonb), app.invalid(text, text), app.error_state(text)
to anon, authenticated;

-- RPCs: callable by both client roles (each requires a verified Firebase uid).
do $$
declare f regprocedure;
begin
  for f in
    select p.oid::regprocedure from pg_catalog.pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname in ('create_business', 'add_member', 'update_member_role', 'remove_member',
                        'delete_category', 'confirm_transaction', 'edit_confirmed_transaction',
                        'cancel_transaction', 'record_settlement', 'issue_document')
  loop
    execute format('revoke execute on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated, service_role', f);
  end loop;
end $$;
