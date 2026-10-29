# Supabase Postgres backend (Phase A: database)

The Firestore + Cloud Functions backend ported to **Supabase Postgres**, with
**Firebase Auth kept for sign-in**. Supabase *third-party auth* verifies the
Firebase ID token on every request; the database reads the caller's uid from
the token (`auth.jwt()->>'sub'`). Nothing here has been applied to the remote
project yet. Phase B moves the Flutter app over.

The server code in `functions/src` is the spec this ports; rule, message and
result shapes are kept identical so the app's error handling and money rules
carry over.

```
supabase/
  config.toml                  CLI config (third-party auth: Firebase busineedger-ab7a1)
  migrations/
    20261019120000_foundation.sql   schema app, identity (app.uid), errors, argument checks
    20261019120100_ledger_rules.sql the money rules + stats deltas (port of ledger.ts / stats.ts)
    20261019120200_tables.sql       tables, indexes, sync stamp + guard triggers, role helpers
    20261019120300_security.sql     grants + row level security (port of firestore.rules)
    20261019120400_rpc_support.sql  idempotency, roles, audit, stats apply, templates, currencies
    20261019120500_rpc_business.sql create_business, add/update/remove member, delete_category
    20261019120600_rpc_ledger.sql   confirm / edit / cancel / settle, issue_document, final grants
    20261020090000_project_description.sql  projects.description (Phase B: the app's project form has one)
  tests/                       vitest + PGlite (in-process Postgres): no Docker needed
    supabase_stub.sql          roles, auth.jwt(), default grants Supabase provides (tests only)
    test/ledger_cases.test.ts  shared/ledger_cases.json against the SQL rules
    test/rpc.test.ts           port of functions/test/integration/ledger.test.ts
    test/rls.test.ts           port of functions/test/rules/rules.test.ts + sync/profile checks
```

## Testing locally

```bash
cd supabase/tests
npm install        # project-local: vitest, @electric-sql/pglite
npm test
```

Each test file starts a fresh in-memory Postgres (PGlite, Postgres 18 in
WASM), loads `supabase_stub.sql`, then every migration in filename order,
exactly as `supabase db push` would. Calls run like PostgREST requests: one
transaction each, `set local role anon` (or `authenticated`) and the JWT
claims in `request.jwt.claims`.

Not covered by PGlite (single connection): truly concurrent sessions. The
RPCs take `select … for update` row locks and advisory locks (see
[Concurrency](#concurrency)); the tests check serial correctness. Re-run the
concurrency case against a real Postgres later (`npx supabase start`, which
needs Docker, or a Supabase branch).

## Applying to the Supabase project (later, with the user's OK)

1. **Dashboard → Authentication → Sign In / Providers → Third-party Auth →
   Add provider → Firebase**, Firebase project id `busineedger-ab7a1`. This
   makes the API accept Firebase ID tokens (issuer
   `https://securetoken.google.com/busineedger-ab7a1`, audience
   `busineedger-ab7a1`).
2. Push the migrations (from the repo root; asks for the database password):

   ```bash
   npx supabase link --project-ref unvpyjnotaukdxgmpytr
   npx supabase db push            # applies supabase/migrations/* in order
   ```

   `tests/supabase_stub.sql` is never pushed: the real project already has
   those roles and `auth.jwt()`.
3. Optional checks: Dashboard → Database → Advisors (the RPCs are
   intentionally `security definer` in `public`; every one checks the caller
   itself).

**The Firebase `role` claim.** Supabase's guide suggests adding a custom
claim `role: "authenticated"` to Firebase users (a blocking function, which
needs Identity Platform). It is **not needed here**: a token without a role
claim runs as `anon`, and every grant and policy is written for both `anon`
and `authenticated`, always requiring `app.uid()` (a verified token from our
Firebase project). Requests also need the project's anon key as `apikey`
header, as with any Supabase client.

## Identity

`app.uid()` returns `auth.jwt()->>'sub'` only when `iss` is
`https://securetoken.google.com/busineedger-ab7a1` **and** `aud` is
`busineedger-ab7a1`; otherwise null. No token, the bare anon key, a Supabase
Auth token or another Firebase project's token → null → no rows, no writes,
RPCs answer `unauthenticated`.

## Schema

All in `public` (exposed by PostgREST); helpers live in `app` (not exposed).
Columns are snake_case. JSON payloads keep the camelCase keys the app already
uses: `settings`, `line_items`, `custom_fields`, document `snapshot`,
settlement `balance_after`, audit `before`/`after`, and RPC results.

| table | key | notes |
|---|---|---|
| `profiles` | `id` = uid | email (from the token, lower-cased), display_name, photo_url, last_business_id. The app upserts its row at sign-in. |
| `businesses` | `id` uuid | name, description, currency_code/decimals/symbol, timezone, template, owner_id, settings jsonb, archived |
| `members` | (business_id, user_id) | role enum `viewer < editor < admin < owner`, email, display_name, photo_url, added_by/at; soft-deleted on removal; one owner per business (unique index) |
| `categories` | `id` uuid (client) | name, kind, icon, colour, field_ids uuid[], sort_order, archived; soft-deleted only by `delete_category` |
| `custom_fields` | `id` uuid (client) | label, type, options[], required, sort_order, archived |
| `parties` | `id` uuid (client) | name, kind, phone, email, address, sort_order, archived |
| `projects` | `id` uuid (client) | name, code, description (≤ 500, added by `20261020090000_project_description.sql`), sort_order, archived |
| `transactions` | `id` uuid (client) | ARCHITECTURE §4: type, direction, status, category/party/project id + name snapshot, description, reference, notes, payment_method, date, due_date, receipt_date (printed on the scanned receipt; the entry keeps its own `date`), line_items, total/paid/refunded/credited/effective/outstanding `_minor`, payment_status, is_open, custom_fields, linked_transaction_id, link_kind, settlement_id, search_tokens text[], version, created_by, confirmed_*, cancelled_*, cancel_reason, updated_by, deleted_at (drafts) |
| `settlements` | (transaction_id, id) | id = request id; kind, amount_minor, date, method, note, balance_after, linked_transaction_id, voided |
| `documents` | (business_id, id) | id = `<type>-<transactionId>-<settlementId or main>`; number unique per business+type; snapshot; voided |
| `audit_log` | identity | entity, entity_id, action, actor, before, after, note, at |
| `daily_stats` | (business_id, date) | income/expense/cash_in/cash_out `_minor`, by_category/by_project/by_type `{id: {in, out}}` |
| `counters` | (business_id, doc_type) | year, next — server only |
| `requests` | (uid, request_id) | op, result — idempotency, server only |

Money: bigint minor units, CHECK 0 ≤ x ≤ 10^13, plus
`paid + credited ≤ total` and `refunded ≤ paid` on every transaction row.
Text only: no file or attachment columns anywhere.

Ids of rows the device creates (drafts and configuration) are uuids made on
the device, so they can be created offline. A transaction's
category/party/project ids are not foreign keys (a draft may arrive before
the category made offline beside it); they are checked on confirm.

## Row level security (client access)

| table | read | client write |
|---|---|---|
| profiles | own row | insert/update own row (email always taken from the token) |
| businesses | members | admin: `name, description, timezone, settings` (column privileges); owner: `archived`; never insert/delete |
| members, settlements, documents, daily_stats | members | none (RPCs) |
| audit_log | admin+ | none |
| categories, custom_fields, parties, projects | members | editor+: insert/update; no delete (archive; categories via `delete_category`); `id, business_id` (and a category's `deleted_at`) cannot change; `created_at` is server-set |
| transactions | members | editor+: **drafts only** — insert with `created_by` = caller; update/soft-delete (`deleted_at`) only while draft and not deleted; every server-maintained field must stay initial (`app.valid_draft`: status draft, type not refund, paid/refunded/credited/effective/outstanding 0, payment_status null, not open, no confirmed/cancelled/link fields, version 0, description ≤ 200, reference ≤ 80, notes ≤ 2000, payment_method ≤ 40, ≤ 200 lines, ≤ 200 search tokens); `id, business_id, created_by` cannot change; `created_at` is server-set |
| counters, requests | none | none |

Internal `app.*` functions are not executable by clients except the few RLS
helpers. A refused client write shows up as SQLSTATE `42501` (RLS or
privilege), `23514` (CHECK) or `PT403/PT400` (guard trigger); an UPDATE of a
row the caller may not change simply matches no rows (PostgREST returns `[]`).

## RPCs

`POST /rest/v1/rpc/<name>` with named JSON arguments (`supabase.rpc(name,
params: {...})`). All are `security definer` with an empty `search_path`,
check the caller's role inside, run in one transaction, and return `jsonb`
with the same shape as the callable they replace. Dates are `yyyy-MM-dd`
strings. Money actions are idempotent by `(uid, p_request_id)`: a repeat
returns the stored result; the same id for another action → `already-exists`.

| RPC (callable) | arguments | result | min role |
|---|---|---|---|
| `create_business` (createBusiness) | p_request_id, p_name, p_currency_code, p_timezone, p_template, p_description? | {businessId} | signed in |
| `add_member` (addMember) | p_business_id, p_email, p_role (`admin`/`editor`/`viewer`) | {uid} | admin (owner for admins) |
| `update_member_role` (updateMemberRole) | p_business_id, p_uid, p_role (`owner` = transfer) | {uid, role} | admin |
| `remove_member` (removeMember) | p_business_id, p_uid (self = leave) | {uid} | admin / self |
| `confirm_transaction` (confirmTransaction) | p_business_id, p_transaction_id, p_request_id, p_expected_version?, p_settle_now?, p_settle_date?, p_settle_method? | {transactionId, version, paymentStatus, settlementId} | admin |
| `edit_confirmed_transaction` (editConfirmedTransaction) | p_business_id, p_transaction_id, p_request_id, p_expected_version, p_changes {description, reference, notes, paymentMethod, date, dueDate, receiptDate, categoryId, partyId, projectId, lineItems, totalMinor, customFields} | {transactionId, version, paymentStatus} | admin |
| `cancel_transaction` (cancelTransaction) | p_business_id, p_transaction_id, p_request_id, p_expected_version?, p_reason? | {transactionId, version, voidedDocuments} | admin |
| `record_settlement` (recordSettlement) | p_business_id, p_transaction_id, p_request_id, p_kind (`payment`/`refund`/`credit`), p_amount_minor, p_date, p_method?, p_note?, p_expected_version? | {settlementId, transactionId, linkedTransactionId, version, paymentStatus, outstandingMinor} | admin |
| `delete_category` (deleteCategory) | p_business_id, p_category_id | {categoryId} | editor |
| `issue_document` (issueDocument) | p_business_id, p_transaction_id, p_type (`invoice`/`bill`/`receipt`), p_request_id, p_settlement_id? | {documentId, number, created} | editor |

`add_member` finds the person by the email of their `profiles` row, which the
app creates at sign-in: not found → "No account uses that email yet. Ask them
to sign in to the app once, then add them." Members are soft-deleted on
removal and revived when added again.

`issue_document` numbers are `PREFIX-YYYY-NNNN`, gap-free per business, type
and year (the year in the business's time zone), allocated under a row lock
on `counters` in the same transaction that stores the document.

## Error contract (for Phase B: PostgrestException → AppException)

RPCs (and the few guard triggers) raise with a custom SQLSTATE, a user-safe
MESSAGE and JSON in DETAIL. PostgREST turns `PTnnn` into HTTP status `nnn`
and returns `{"code": "PT412", "message": "...", "details": "<json>", "hint": null}`;
`PostgrestException.details` is that JSON string.

| SQLSTATE | details.code | details.reason | meaning |
|---|---|---|---|
| `PT400` | `invalid-argument` | `validation` | bad input; `details.field` names it (`categoryId`, `customFields.<id>`, `changes.date`, …) |
| `PT401` | `unauthenticated` | `unauthenticated` | no verified Firebase token |
| `PT403` | `permission-denied` | `notMember` / `role` (+`required`) / `immutable` (+`field`) | |
| `PT404` | `not-found` | `notFound` | |
| `PT409` | `aborted` | `conflict` | `p_expected_version` stale: reload and retry |
| `PT412` | `failed-precondition` | `violation` (+`violation` key, e.g. `overpayment`) / `inUse` / `role` | ledger rule; message = ledger.ts `VIOLATIONS` text |
| `PT422` | `already-exists` | `requestReused` / `validation` | request id used for another action; member exists |

Anything else (e.g. `42501` from RLS on a direct table write, `23514` CHECK,
`40P01` deadlock, network) is not part of the contract: map `42501` to
permission-denied and the rest to internal/unavailable. The outbox's
"definitive vs transient" split stays as today, keyed on `details.code`.

## Sync (pull) contract — built in Phase B

Every business-scoped table has `seq bigint`, stamped from one global
sequence on **every insert and update** (trigger `app.stamp`), and an index
on `(business_id, seq)` (`businesses`: `seq`). Rows the app needs to see
disappear are soft-deleted (`deleted_at`): draft transactions, members,
categories. Nothing a client can read is hard-deleted.

Per business and table the device keeps a cursor and pulls

```
GET /rest/v1/<table>?business_id=eq.<bid>&seq=gt.<cursor>&order=seq.asc&limit=500
```

(`businesses`: `?seq=gt.<cursor>`, RLS limits it to the caller's), upserts
the rows locally by primary key (tombstones included), sets the cursor to the
last `seq`, and repeats until fewer than `limit` rows come back.

Why a cursor never skips a row: `app.stamp` takes a per-business
transaction-scoped advisory lock before `nextval`, so writes to one business
commit in `seq` order. Once a reader sees seq N for a business, every row of
that business with a lower seq is already committed and visible.

Removal from a business is not visible through that business's tables (RLS
hides them at once): on each sync, list `businesses` / own `members` rows and
drop local data of businesses no longer returned. `audit_log` is readable by
admins only; `counters` and `requests` are never synced.

Pushes: drafts and configuration are plain inserts/updates or PostgREST
upserts on the uuid primary key (resending the whole row is fine: unchanged
immutable columns pass the guard, `created_at` is kept). Do not send `seq`,
`updated_at` or other server columns for `businesses` (column privileges
refuse them);
money actions are the RPCs above with their request ids, replayed from the
outbox exactly as today.

## Concurrency

* Each money RPC locks its transaction row (`select … for update`) before
  re-reading the balance, so two concurrent payments cannot overpay; the
  second waits and then fails `overpayment`.
* A duplicate request id waits on an advisory lock for the first call and
  then returns its stored result.
* Lock order is always: the client-writable row the RPC changes (transaction,
  category, business) → the per-business sync lock (taken by the first
  write) → server-only rows (stats, counters, documents). Client writes take
  their row lock, then the sync lock, so the two cannot deadlock on a single
  row. A multi-row client UPDATE racing an RPC on one of those rows can still
  deadlock; Postgres aborts one side with `40P01` (retry).
* Writes to one business are serialised by the sync lock (short: one
  statement or one RPC). Different businesses never wait on each other.

## Edge Function: `scan-receipt` (receipt scanning with AI)

`functions/scan-receipt/` turns a receipt's text into ledger fields with
Claude (`claude-haiku-5-5`, structured JSON output). The phone does the OCR
itself (Apple Vision / Google ML Kit) and sends **only the text**; no image
reaches the server and nothing is stored. Offline, or when this function
fails, the app falls back to its on-device parser.

* **Auth**: `verify_jwt = false` in `config.toml`, because the gateway does
  not know Firebase tokens. The function verifies the caller's Firebase ID
  token itself against Google's public keys (issuer/audience
  `busineedger-ab7a1`) and answers `401` otherwise.
* **Request** (`POST`, JSON): `text` (≤ 12,000 chars), `currency` (ISO),
  `today` (`yyyy-MM-dd`), `categories: [{id, name}]` (the ones the entry may
  use, ≤ 300).
* **Response** `200`: `merchant`, `date`, `total` (decimal string),
  `currency`, `reference`, `paymentMethod` (one of the app's five),
  `categoryId` (only an id from the request), `description`,
  `lineItems: [{description, quantity, rate}]`, `sellerGstin`,
  `sellerPhone`, `sellerEmail`, `sellerAddress`; every field may be null. The
  app turns amounts into minor units with its own `Money` rules, drops a
  total in a foreign currency, and keeps line items only when they add up
  to the total exactly.
* **Errors**: `400 invalid-argument`, `401 unauthenticated`,
  `422 unreadable` (refusal / malformed answer), `503 busy` (rate limit),
  `504 timeout`, `502 upstream`.
* Pure helpers (`receipt.ts`) are tested in `tests/test/scan_receipt.test.ts`.

**Deploy (live change: the user runs these):**

```bash
npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-...   # once
npx supabase functions deploy scan-receipt
```

## Differences from the Firestore version

* Removing a member, deleting a draft and deleting a category are soft
  deletes (`deleted_at`) so other devices learn about them when syncing.
* `memberUids` is gone; listing businesses is `select * from businesses`
  (RLS returns the caller's).
* `profiles.email` is always the verified token email: a client cannot claim
  another person's address to be added in their place.
* No `dateTs` columns: `date`/`due_date` are SQL `date`s.
* `issue_document` takes a shared lock on the transaction, so a concurrent
  cancel cannot slip between the check and the numbered document.
* Search tokens split on `[^[:alnum:]]` (Postgres' Unicode letters + digits)
  instead of `/[^\p{L}\p{N}]/u`; identical on the fixtures, may differ on rare
  scripts (combining marks, `\p{No}` digits).

## Not verified locally

* PostgREST itself with real Firebase tokens: role selection when the token
  has no `role` claim (expected: `anon`), the third-party JWKS verification,
  and the `PTnnn` → HTTP status mapping. Check against the project once the
  provider is enabled (one sign-in + one `rpc('create_business')`).
* Real concurrency (PGlite is single-connection): row locks, the request
  lock and the sync lock behave as described on a real Postgres 17.
* `lower()` / `[[:alnum:]]` on the hosted database's locale (PGlite uses
  `C.UTF-8`; Supabase uses a UTF-8 libc/ICU locale; both handle the
  fixtures' `Électricité`).
