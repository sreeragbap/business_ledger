-- Business Ledger on Supabase Postgres — 6/7: business, member and category RPCs.
--
-- Ports of functions/src/handlers/{business,members,categories}.ts. Every
-- RPC: security definer, empty search_path, one transaction, role checked
-- inside, user-safe errors (README §Error contract). Results keep the
-- callable result shapes (camelCase keys).
--
-- Lock order (avoids deadlocks with client writes): the client-writable row
-- an RPC changes (business, category, transaction) is locked FIRST, before
-- the first write takes the per-business sync lock in app.stamp().

/**
 * Creates the business, its owner membership and the template's categories
 * and fields in one transaction. Idempotent by request id.
 * → {businessId}
 */
create or replace function public.create_business(
  p_request_id text,
  p_name text,
  p_currency_code text,
  p_timezone text,
  p_template text,
  p_description text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_claims jsonb := app.claims();
  v_prior jsonb;
  v_name text;
  v_description text;
  v_currency jsonb;
  v_template jsonb;
  v_business_id uuid := gen_random_uuid();
  v_field jsonb;
  v_category jsonb;
  v_field_ids jsonb := '{}'::jsonb;
  v_field_id uuid;
  v_index integer;
begin
  perform app.arg_request_id(p_request_id);
  v_name := app.arg_text(p_name, 80, 'name');
  if v_name is null or v_name = '' then perform app.invalid('Enter a business name', 'name'); end if;
  v_description := app.arg_text(p_description, 500, 'description');
  if p_currency_code is null or length(p_currency_code) <> 3 then
    perform app.invalid('Choose a supported currency.', 'currencyCode');
  end if;
  if p_timezone is null or length(p_timezone) not between 1 and 64 then
    perform app.invalid('Unknown time zone.', 'timezone');
  end if;
  if p_template is null or length(p_template) not between 1 and 32 then
    perform app.invalid('Choose a template.', 'template');
  end if;
  v_currency := app.currency(p_currency_code);
  if v_currency is null then perform app.invalid('Choose a supported currency.', 'currencyCode'); end if;
  v_template := app.template(p_template);
  if v_template is null then perform app.invalid('Choose a template.', 'template'); end if;
  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_timezone) then
    perform app.invalid('Unknown time zone.', 'timezone');
  end if;

  v_prior := app.request_begin(v_uid, p_request_id, 'createBusiness');
  if v_prior is not null then return v_prior; end if;

  insert into public.businesses (
    id, name, description, currency_code, currency_decimals, currency_symbol, timezone, template,
    owner_id, settings
  ) values (
    v_business_id, v_name, coalesce(v_description, ''), v_currency->>'code',
    (v_currency->>'decimals')::integer, v_currency->>'symbol', p_timezone, p_template, v_uid,
    jsonb_build_object(
      'enabledStandardFields', v_template->'standardFields',
      'invoicePrefix', 'INV', 'billPrefix', 'BILL', 'receiptPrefix', 'RCPT',
      'address', '', 'phone', '', 'email', coalesce(v_claims->>'email', ''), 'taxId', '')
  );
  insert into public.members (business_id, user_id, role, email, display_name, photo_url, added_by)
  values (v_business_id, v_uid, 'owner', lower(coalesce(v_claims->>'email', '')),
          coalesce(v_claims->>'name', ''), coalesce(v_claims->>'picture', ''), v_uid);

  for v_field, v_index in
    select value, (ordinality - 1)::integer from jsonb_array_elements(v_template->'fields') with ordinality
  loop
    v_field_id := gen_random_uuid();
    v_field_ids := v_field_ids || jsonb_build_object(v_field->>'key', v_field_id);
    insert into public.custom_fields (id, business_id, label, type, options, required, sort_order)
    values (
      v_field_id, v_business_id, v_field->>'label', v_field->>'type',
      coalesce(array(select jsonb_array_elements_text(v_field->'options')), '{}'::text[]),
      coalesce((v_field->>'required')::boolean, false), v_index);
  end loop;

  for v_category, v_index in
    select value, (ordinality - 1)::integer from jsonb_array_elements(v_template->'categories') with ordinality
  loop
    insert into public.categories (id, business_id, name, kind, icon, colour, field_ids, sort_order)
    values (
      gen_random_uuid(), v_business_id, v_category->>'name', v_category->>'kind',
      v_category->>'icon', v_category->>'colour',
      coalesce(array(
        select (v_field_ids->>key)::uuid
        from jsonb_array_elements_text(coalesce(v_category->'fields', '[]'::jsonb)) with ordinality as f(key, ord)
        where v_field_ids ? key
        order by ord), '{}'::uuid[]),
      v_index);
  end loop;

  insert into public.profiles (id, email, display_name, photo_url, last_business_id)
  values (v_uid, coalesce(v_claims->>'email', ''), coalesce(v_claims->>'name', ''),
          coalesce(v_claims->>'picture', ''), v_business_id)
  on conflict (id) do update set last_business_id = excluded.last_business_id;

  perform app.audit(v_business_id, 'business', v_business_id::text, 'create', v_uid, null,
    jsonb_build_object('name', v_name, 'currency', v_currency->>'code', 'template', p_template));
  return app.request_end(v_uid, p_request_id, 'createBusiness', jsonb_build_object('businessId', v_business_id));
end $$;

/**
 * Adds an existing user (found by the email of their profile, created when
 * they first sign in) with role admin/editor/viewer. → {uid}
 */
create or replace function public.add_member(p_business_id uuid, p_email text, p_role text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_actor app.member_role;
  v_email text := lower(app.trim_text(coalesce(p_email, '')));
  v_profile public.profiles;
  v_existing public.members;
begin
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or length(v_email) > 320 then
    perform app.invalid('Invalid email address', 'email');
  end if;
  if p_role is null or p_role not in ('admin', 'editor', 'viewer') then
    perform app.invalid('Choose a role.', 'role');
  end if;
  -- Role first: a non-admin must not learn which emails have accounts.
  select m.role into v_actor from public.members m
    where m.business_id = p_business_id and m.user_id = v_uid and m.deleted_at is null;
  if v_actor is null or v_actor < 'admin' then
    perform app.fail('permission-denied', 'This needs the admin role or higher.', 'role',
      jsonb_build_object('required', 'admin'));
  end if;
  if not app.can_manage(v_actor, p_role::app.member_role) then
    perform app.fail('permission-denied', 'Only the owner can add admins.', 'role');
  end if;

  select * into v_profile from public.profiles where email = v_email order by updated_at desc limit 1;
  if not found then
    perform app.fail('not-found',
      'No account uses that email yet. Ask them to sign in to the app once, then add them.', 'notFound');
  end if;

  select * into v_existing from public.members
    where business_id = p_business_id and user_id = v_profile.id for update;
  if found and v_existing.deleted_at is null then
    perform app.fail('already-exists', 'That person is already a member.', 'validation');
  end if;
  insert into public.members (business_id, user_id, role, email, display_name, photo_url, added_by, added_at, deleted_at)
  values (p_business_id, v_profile.id, p_role::app.member_role, v_profile.email, v_profile.display_name,
          v_profile.photo_url, v_uid, now(), null)
  on conflict (business_id, user_id) do update set
    role = excluded.role, email = excluded.email, display_name = excluded.display_name,
    photo_url = excluded.photo_url, added_by = excluded.added_by, added_at = excluded.added_at,
    deleted_at = null;

  perform app.audit(p_business_id, 'member', v_profile.id, 'add', v_uid, null, jsonb_build_object('role', p_role));
  return jsonb_build_object('uid', v_profile.id);
end $$;

/** Changes a member's role; role 'owner' transfers ownership (caller becomes admin). → {uid, role} */
create or replace function public.update_member_role(p_business_id uuid, p_uid text, p_role text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_actor app.member_role;
  v_current app.member_role;
begin
  if p_uid is null or length(p_uid) not between 1 and 128 then perform app.invalid('Invalid id', 'uid'); end if;
  if p_role is null or p_role not in ('owner', 'admin', 'editor', 'viewer') then
    perform app.invalid('Choose a role.', 'role');
  end if;
  v_actor := app.require_role(p_business_id, 'admin');
  perform 1 from public.businesses where id = p_business_id for update;

  select m.role into v_current from public.members m
    where m.business_id = p_business_id and m.user_id = p_uid and m.deleted_at is null for update;
  if v_current is null then perform app.fail('not-found', 'That member was not found.', 'notFound'); end if;
  if p_uid = v_uid then perform app.fail('failed-precondition', 'You cannot change your own role.', 'role'); end if;
  if v_current = 'owner' then
    perform app.fail('failed-precondition', 'The owner''s role changes only by a transfer.', 'role');
  end if;

  if p_role = 'owner' then
    if v_actor <> 'owner' then
      perform app.fail('permission-denied', 'Only the owner can transfer ownership.', 'role');
    end if;
    -- Old owner steps down first: one owner per business at any moment.
    update public.members set role = 'admin' where business_id = p_business_id and user_id = v_uid;
    update public.businesses set owner_id = p_uid where id = p_business_id;
  elsif not app.can_manage(v_actor, v_current) or not app.can_manage(v_actor, p_role::app.member_role) then
    perform app.fail('permission-denied', 'Only the owner can manage admins.', 'role');
  end if;
  update public.members set role = p_role::app.member_role where business_id = p_business_id and user_id = p_uid;

  perform app.audit(p_business_id, 'member', p_uid,
    case when p_role = 'owner' then 'transferOwnership' else 'changeRole' end, v_uid,
    jsonb_build_object('role', v_current), jsonb_build_object('role', p_role));
  return jsonb_build_object('uid', p_uid, 'role', p_role);
end $$;

/** Removes a member (admin+), or leaves (p_uid = caller). The owner must transfer first. → {uid} */
create or replace function public.remove_member(p_business_id uuid, p_uid text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  v_leaving boolean := p_uid = v_uid;
  v_actor app.member_role;
  v_target app.member_role;
begin
  if p_uid is null or length(p_uid) not between 1 and 128 then perform app.invalid('Invalid id', 'uid'); end if;
  v_actor := app.require_role(p_business_id, case when v_leaving then 'viewer' else 'admin' end::app.member_role);
  select m.role into v_target from public.members m
    where m.business_id = p_business_id and m.user_id = p_uid and m.deleted_at is null for update;
  if v_target is null then perform app.fail('not-found', 'That member was not found.', 'notFound'); end if;
  if v_target = 'owner' then
    perform app.fail('failed-precondition', 'Transfer ownership before the owner leaves.', 'role');
  end if;
  if not v_leaving and not app.can_manage(v_actor, v_target) then
    perform app.fail('permission-denied', 'Only the owner can remove admins.', 'role');
  end if;
  update public.members set deleted_at = now() where business_id = p_business_id and user_id = p_uid;
  perform app.audit(p_business_id, 'member', p_uid, case when v_leaving then 'leave' else 'remove' end, v_uid,
    jsonb_build_object('role', v_target), null);
  return jsonb_build_object('uid', p_uid);
end $$;

/**
 * Deletes (soft: deleted_at) a category only when no transaction in any
 * status uses it; otherwise the answer is "archive". → {categoryId}
 */
create or replace function public.delete_category(p_business_id uuid, p_category_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid text := app.require_uid();
  c public.categories;
begin
  perform app.require_role(p_business_id, 'editor');
  select * into c from public.categories
    where id = p_category_id and business_id = p_business_id and deleted_at is null for update;
  if not found then perform app.fail('not-found', 'That category was not found.', 'notFound'); end if;
  if exists (select 1 from public.transactions t
             where t.business_id = p_business_id and t.category_id = p_category_id and t.deleted_at is null) then
    perform app.fail('failed-precondition',
      'Transactions use this category, so it cannot be deleted. Archive it instead.', 'inUse');
  end if;
  update public.categories set deleted_at = now() where id = p_category_id;
  perform app.audit(p_business_id, 'category', p_category_id::text, 'delete', v_uid,
    jsonb_build_object('name', c.name), null);
  return jsonb_build_object('categoryId', p_category_id);
end $$;
