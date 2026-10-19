# Business Ledger — Architecture

A multi-business digital ledger. Flutter (Android + iOS) over **Supabase
Postgres** for data, with **Firebase** kept for sign-in (Auth) and crash
reports (Crashlytics). The app stores **text only**: there is no file
storage (no attachments); invoices, bills and receipts are rendered on the
device from a stored text snapshot whenever needed.

> Migration status (2026-10): Phase B moved the app's data layer from
> Firestore + Cloud Functions to Supabase (`supabase/README.md`) with an
> on-device SQLite store (drift). `functions/`, `firestore.rules` and
> `firestore.indexes.json` are still in the repo until Phase C removes
> them; nothing in `lib/` uses them any more. Sections 4–9 describe rules
> that did not change; where they name Firestore paths or Cloud Functions,
> read the Postgres table / RPC of the same name (`supabase/README.md`).

Conventions are taken from `easify_crm_flutter` (see
[Conventions](#conventions)); deviations are listed with the reason.

---

## 1. Layering

```
lib/
├── app/            bootstrap, flavors, AppConfig (Firebase options, Supabase URL/key)
├── core/           knows nothing about features/
│   ├── bloc/       Status
│   ├── database/   drift (SQLite): tables, LocalStore, RowCodec, SyncTable
│   ├── di/         get_it + injectable
│   ├── domain/     AppResult / AppException, JsonRead (row readers)
│   ├── firebase/   connectivity, Crashlytics, Auth emulator setup, RequestIds
│   ├── supabase/   SupabaseSetup, RemoteTables, RemoteRpc, RpcClient
│   ├── money/      Money, Currency            ◀ the only place money is maths
│   ├── ledger/     LedgerMath, rules           ◀ pure, unit-tested
│   ├── router/     auto_route, AuthGuard
│   ├── sync/       Cloud sync switch, outbox, LocalWriter, SyncEngine,
│   │               SyncPuller, SyncQueue, ProfileSync (§2)
│   ├── theme/      dark tokens
│   └── widgets/    App* components
└── features/<name>/{domain/{const,models,repository,services},logic,screens,widgets}
```

```
 Screens ─► Cubits ─► XRepository (abstract)
                         │
                         ▼  XService
      reads ◄── drift streams (watch) ◄── on-device SQLite ◄── SyncPuller ◄─┐
                                               ▲                            │
      drafts / settings ─► LocalWriter ────────┘ + outbox (upsert/update) ─┤
      money actions ─────► SyncQueue ── RPC now, or outbox (rpc) ──────────┤
      online-only ───────► RpcClient ── RPC (create business, members…) ──┤
                                                                            │
                                     SyncEngine ── push FIFO / pull ── Supabase
                                     (PostgREST, Firebase ID token as bearer)
```

* A screen never touches the network or SQL. Cubits depend on
  `XRepository` (abstract); `XService` implements it over the on-device
  store (reads), `LocalWriter` (drafts, configuration, settings) and
  `RpcClient` / `SyncQueue` (everything the server must decide).
* **Every read is a drift stream** over the local SQLite copy, so every
  screen works fully offline and updates the moment a pull or a local write
  lands.
* Every repository call returns `AppResult<T>` and never throws.
* No financial arithmetic in widgets or blocs: they call `LedgerMath`.
  Receivables/payables are summed by SQLite in integers.
* The domain models are unchanged; only their (de)serialisation moved:
  `X.fromRow(row)` reads a Postgres row (snake_case columns; jsonb keeps
  camelCase keys), `toRow()` produces what the client may write.

### Rows, everywhere the same shape (`core/database/row_codec.dart`)

A row is a `Map<String, dynamic>` keyed by the Postgres column names:
uuids, dates (`yyyy-MM-dd`) and timestamps (ISO-8601) as strings, money
and counters as `int` (minor units), jsonb objects/arrays and Postgres
arrays as maps/lists. drift is configured (`build.yaml`) to serialise its
data classes with the SQL column names, and `RowCodec.serializer` is
lenient (a missing column becomes its zero value), so a pulled row becomes
a drift row with `fromJson` and a stored one turns back into the same map
with `toJson`. JSON columns are stored as JSON text with type converters.
`SyncTable` lists every mirrored table with its primary key, whether it is
pulled per business, and whether the client may write it.

Local-only columns and tables: `local_pending` on client-writable tables
(a change made here and not pushed yet), `sync_cursors(business_id,
table_name, seq)`, and `local_meta` (whose data the store holds; whether a
full pull has completed since).

## 2. Trust boundary

| Operation | Path | Why |
|---|---|---|
| Create / edit / delete (soft) a **draft** transaction | Client → `transactions` (RLS: drafts only, `app.valid_draft`) | Works offline; drafts carry no money effect. |
| Categories, fields, parties, projects (create, edit, reorder, archive) | Client → their tables (RLS: editor+) | Configuration, offline-friendly. |
| Business details / settings, archive | Client → `businesses` update (column privileges: name, description, timezone, settings; owner: archived) | Settings, offline-friendly. |
| Own profile (name, photo, last business) | Client → `profiles` upsert (own row; email from the token) | Needed before anyone can add you. |
| Create business, members & roles | RPC (`create_business`, `add_member`, `update_member_role`, `remove_member`) | Atomic writes, seeding, role rules. |
| Confirm, edit confirmed, cancel | RPC | Changes balances and stats. |
| Record payment / refund / credit | RPC | Idempotency + row locks on balances. |
| Delete category | RPC `delete_category` | Must prove no transaction references it. |
| Issue invoice / bill / receipt number | RPC `issue_document` | Gap-free, unique numbering per business. |

Row level security and column privileges make the server path mandatory:
clients **cannot** write a non-draft transaction, settlement, audit entry,
stats row, counter, document or membership (`supabase/README.md`).

**Identity.** Firebase Auth signs people in (Google, Apple, the emulator
test account). Supabase *third-party auth* verifies the Firebase ID token,
which the Supabase client sends as the bearer token on every request
(`SupabaseSetup`: `accessToken: () => currentUser?.getIdToken()`); the
database reads the caller from it (`app.uid()`). Supabase Auth is never
used.

**Errors.** RPCs refuse with SQLSTATE `PTnnn` and a JSON `details`
(`{code, reason, violation?, field?}`); `AppException.fromPostgrest` maps
it to the same `AppErrorKind`s the cubits always used. `42501` (RLS) is
permission-denied; `23xxx`/`22xxx` invalid input; JWT errors
unauthenticated; deadlocks, timeouts and 5xx are transient; socket /
HTTP-client errors are offline.

### Offline behaviour

**Cloud sync switch.** Settings › Sync has a per-device *Cloud sync* switch
(default on, `SyncSettings`, stored in shared_preferences). Off, the app
works entirely from this device: the sync engine neither pushes nor pulls,
and online-only actions are refused. "The cloud is reachable"
(`CloudAvailability`) means *device online **and** sync on **and** signed
in*; everything that used to ask "am I online?" asks that instead.

**The local store** (`AppDatabase`, drift/SQLite in the app support
directory) holds the user's copy of every table they can read: their
profile, businesses, members, categories, custom fields, parties,
projects, transactions, settlements, documents, daily stats and (admins
only) the audit log. It belongs to one user: the first time a different
uid signs in it is wiped (`LocalStore.claimFor`), and signing out wipes it
(`ProfileSync.forgetDevice`), so nothing of one person stays for the next.

**Drafts and configuration** go through `LocalWriter`: the row is written
to SQLite at once (marked `local_pending`, visible on every screen) **and**
queued in the outbox as an `upsert` (a new row, whole) or `update`
(`{match: primary key, values}`; edits, reorders, archives, soft deletes,
business settings). The UI reports success immediately. A draft saved
right before a confirm is sent with `awaitServer` when the cloud is
reachable and nothing is queued: pushed first, stored locally once the
server has it (so the confirm can run directly); offline it falls back to
the queued path.

**Money actions are queued, not applied locally.** Confirm, record
settlement, edit confirmed and cancel go through `SyncQueue`:

* cloud reachable and nothing of this user waiting in the outbox → the RPC
  is called directly; when it succeeds a pull runs before the result is
  returned, so the screen shows the server's new figures;
* offline, sync off, anything of this user still queued (the queue is one
  FIFO: a draft's upsert always lands before the confirm queued after it),
  or a direct call failing with offline / timeout → the action is appended
  to the **outbox** and the UI shows it as *Pending sync*. Nothing about it
  is reflected in balances until the server applies it: there is no
  optimistic money maths.

The outbox (`core/sync/`) is a JSON file in the app support directory,
written atomically (temp file + rename); an unreadable file is moved aside
and the queue starts empty. A money entry holds the owner `uid`, business,
action, payload (camelCase, with its `requestId`; `RpcClient` maps it to
the RPC's `p_*` parameters), transaction, a human label ("Payment
₹1,200.00 · Cement bags"), status (pending / syncing / failed), attempts,
last error and, for edits, the version the user edited. A row-write entry
holds `{table, rows}` or `{table, updates}` and, for drafts, the
transaction id (so a failed draft holds back its confirm).

**Push** (`SyncEngine`, started by `App`) runs while a user is signed in,
sync is on and the device is online. It sends that user's entries oldest
first, one at a time (other users' entries stay dormant: the server's
idempotency record is per user):

* row writes through PostgREST (`RemoteTables.upsert` / `update`); an
  UPDATE that RLS filters out changes 0 rows without an error, which is
  treated as a definitive refusal;
* money actions through their RPC (`RpcClient`).
* **Replay safety.** A money entry keeps its original `requestId`. A replay
  of an action that did land returns the stored result instead of applying
  it again (`requests` table). Resending a row upsert is harmless.
* **Version chaining.** A queued `expectedVersion` would be stale, so it is
  omitted where optional (confirm, settle, cancel). An edit requires it:
  it is sent as the version the user edited plus the number of earlier
  queued money actions on the same transaction that have since succeeded
  (every server write bumps `version` by exactly 1). If the server still
  answers `aborted`, someone else changed the transaction: the entry fails
  with "Changed by someone else — review and retry".
* **Success** clears the rows' `local_pending` mark (unless another queued
  entry still writes them) and asks for a pull.
* **Failures.** A definitive refusal (invalid-argument,
  failed-precondition, permission-denied (RLS included), not-found,
  already-exists, aborted, unauthenticated) marks the entry *failed* with
  the server's user-safe message and holds back later entries for **the
  same transaction** (they likely depend on it); other entries continue. A
  transient one (unavailable, deadline, internal, deadlock, 5xx, network)
  keeps it pending with exponential backoff (5 s doubling to 5 min); a
  reconnect or "Sync now" retries at once. The user can retry a failed
  entry (same `requestId`) or discard it, together with its dependents
  after confirmation. Discarding a row write drops the local row and
  resets that table's cursor, so the next pull restores the server's
  version (or nothing, for a row the server never had).

**Pull** (`SyncPuller`, `supabase/README.md` Sync contract):

1. the user's `profiles` row;
2. every `businesses` row RLS returns (= their memberships). A business
   stored locally but no longer returned (left, removed) is wiped from the
   device with all its rows and cursors;
3. per business and table, rows with `seq` greater than the stored cursor,
   ordered by `seq`, 500 per page, until a short page. Each page is upserted
   and its cursor moved **in one SQLite transaction**; tombstones
   (`deleted_at`: removed members, deleted drafts and categories) are
   deleted locally. Rows with `local_pending` are skipped (checked inside
   the same transaction), so a pull never overwrites a change still waiting
   to be pushed; the push gives the row a new `seq` and a later pull brings
   the merged result. `audit_log` is pulled only while the user is admin or
   owner (and dropped on demotion).

Triggers: app start, sign-in, reconnect, Cloud sync switched on, after
every push or direct RPC that applied something, "Sync now",
pull-to-refresh (`SyncEngine.refresh`, which completes when the pull has),
the app returning to the foreground, and every 60 s while foregrounded.
Pulls are serialised; one asked for during another runs once more
afterwards. Next step: Supabase Realtime (or `pg_notify`) to replace the
60 s poll.

Before the first completed pull on a device, "not in the local store"
means "not known yet": single-row streams (the current business, the
user's own membership, one transaction) wait instead of answering "gone",
so a fresh sign-in never drops the user out of a business
(`LocalStreams.single`).

**Never queued** (they need the server's answer now): create business,
member changes, delete category, issue document. Offline or with sync off
they are refused with "Needs a connection and sync turned on". After they
succeed, a pull brings their rows before the call returns.

**Status.** `SyncStatus` = sync on, online, syncing, pending and failed
counts, `localChanges` (row writes waiting: exact, they are outbox entries)
and the last time a push or pull completed.

**Client pre-validation counts the queue.** The balance shown is always
the server's, but a *new* settlement is checked as if this user's queued
actions on the transaction (pending or syncing, not failed) had applied
(`PendingSettlements`): payments and credits against outstanding minus
queued payments and credits; refunds against refundable minus queued
refunds (queued payments are not refundable until applied). A queued cancel
blocks further settlements; a draft with a queued confirm can be settled,
checked against its total as if confirmed (fully paid if the confirm is
"as paid"). The settlement sheet's preview then reads "After this and
pending actions".

**Sign-out is blocked** while the signed-in user has outbox entries (they
could only be replayed by signing back in as that user). The dialog offers
"Sync now" (enabled only when the cloud is reachable; it closes by itself
once the outbox is empty and sign-out proceeds), "Discard and sign out"
(after a second confirmation: drops that user's entries), or Cancel.
Signing out then wipes the local store.

**Emulator mode** (`--dart-define=USE_EMULATOR=true`) still signs in to
the Firebase **Auth** emulator ("Continue with test account"). Supabase
does not accept the emulator's unsigned tokens, so against the hosted
project that mode shows no data and RPCs answer "Sign in to continue". A
full local stack needs a local Supabase (`npx supabase start`) configured
to trust the Auth emulator's tokens, plus an app setting pointing at it —
not built yet.

## 3. Data model

The tables, columns, keys, row level security, RPC signatures, error
contract and sync contract are in **`supabase/README.md`** (and the
migrations in `supabase/migrations/`). In short: `profiles`, `businesses`,
`members`, `categories`, `custom_fields`, `parties`, `projects`,
`transactions`, `settlements`, `documents`, `audit_log`, `daily_stats`
(+ server-only `counters`, `requests`). Columns are snake_case; JSON
payloads (`settings`, `line_items`, `custom_fields`, document `snapshot`,
settlement `balance_after`, audit `before`/`after`) and RPC results keep
the camelCase keys the app uses. Every business-scoped row has a global
`seq` (stamped on insert/update) for the pull; rows that must disappear
from other devices are soft-deleted (`deleted_at`).

Money is stored as **integer minor units** (`bigint`, `*_minor`) with the
business currency's `decimals`. No floating point ever touches a stored
amount (on the device: SQLite `INTEGER`, Dart `int`).

Dates: `date` and `due_date` are calendar dates (`yyyy-MM-dd`; SQL `date`
on the server, text on the device, compared and sorted as text). A
transaction date is a day, not an instant; this keeps it stable across
time zones. Ids of rows the device creates (drafts, configuration) are v4
uuids generated on the device, so they can be created offline.

<details>
<summary>Superseded: the Firestore data model (before Phase B)</summary>

```
users/{uid}
  displayName, email, photoUrl, createdAt, lastBusinessId

businesses/{bid}
  name, description, currency {code, decimals, symbol}, timezone,
  template, ownerId, memberUids[] (for list queries),
  settings {enabledStandardFields[], invoicePrefix, billPrefix,
            receiptPrefix, address, phone, email, taxId},
  createdAt, updatedAt, archived

businesses/{bid}/members/{uid}          role: owner|admin|editor|viewer
businesses/{bid}/categories/{cid}       name, kind(income|expense|any),
                                        fieldIds[], sortOrder, archived,
                                        colour, icon, createdAt, updatedAt
businesses/{bid}/fields/{fid}           label, type, options[], required,
                                        sortOrder, archived
businesses/{bid}/parties/{pid}          name, kind(customer|supplier|both),
                                        phone, email, address, archived
businesses/{bid}/projects/{pid}         name, code, archived
businesses/{bid}/transactions/{tid}     see §4
businesses/{bid}/transactions/{tid}/settlements/{requestId}
                                        kind(payment|refund|credit),
                                        amountMinor, date, method, note,
                                        createdBy, createdAt, voided
businesses/{bid}/documents/{docId}      type(invoice|bill|receipt),
                                        number, transactionId,
                                        settlementId?, snapshot{...},
                                        issuedAt, voided
businesses/{bid}/audit/{id}             entity, entityId, action, actor,
                                        before, after, at
businesses/{bid}/stats/{yyyy-MM-dd}     daily aggregates, see §6
businesses/{bid}/counters/{docType}     next, year
requests/{requestId}                    idempotency records (functions only)
```

Money is stored as **integer minor units** (`amountMinor`) with the
business currency's `decimals`. No floating point ever touches a
stored amount.

Dates: `date` and `dueDate` are calendar dates stored as `yyyy-MM-dd`
strings (plus `dateTs` Timestamp at UTC midnight for range queries).
A transaction date is a day, not an instant; this keeps it stable
across time zones.

</details>

## 4. Transaction

| Field | Notes |
|---|---|
| `type` | income · expense · sale · purchase · payment · refund · adjustment |
| `direction` | `in` or `out`, derived from type (payment/adjustment choose) |
| `status` | draft · confirmed · cancelled |
| `categoryId`, `categoryName` | name snapshot kept for history |
| `partyId`, `partyName`, `projectId`, `projectName` | optional, snapshots |
| `description`, `reference`, `notes`, `paymentMethod` | |
| `date`, `dueDate?` | calendar dates |
| `lineItems[]` | {description, quantityMilli, rateMinor, amountMinor} |
| `totalMinor` | sum of lines, or entered directly |
| `paidMinor`, `refundedMinor`, `creditedMinor` | maintained by functions only |
| `outstandingMinor` | derived, stored for queries |
| `paymentStatus` | unpaid · partiallyPaid · paid · refunded · partiallyRefunded · notApplicable |
| `isOpen` | `status == confirmed && outstanding > 0` (for overdue queries) |
| `customFields` | `{fieldId: value}` |
| `linkedTransactionId`, `linkKind` | refund/adjustment → original |
| `searchTokens[]` | lowercase word prefixes for search |
| `version` | optimistic concurrency, bumped on every server write |
| `createdBy`, `createdAt`, `updatedAt`, `confirmedAt`, `cancelledAt` | |

## 5. Financial rules

Notation: **T** total, **P** payments, **R** refunds, **C** credits
(discounts/credit notes) — all non-negative integers in minor units.

```
payable      = T − C
netPaid      = P − R
effective    = T − C − R           (recognised income/expense)
outstanding  = T − C − P           (refund does not reopen the balance)
```

A refund returns money **and** reduces the effective amount (goods
returned / service reversed), so it never makes a settled transaction
owe money again. Each amount counts exactly once.

### Invariants (enforced in functions, re-checked in client)

1. `T > 0`, `0 ≤ C`, `0 ≤ P`, `0 ≤ R`.
2. `P + C ≤ T` — no overpayment, no credit beyond what is unpaid.
3. `R ≤ P` — only money received/paid can be refunded.
4. Settlements only on `confirmed` transactions.
5. Editing a confirmed `T` requires `T_new ≥ P + C`.
6. Cancel requires `netPaid == 0` (refund first). Cancelling voids any
   issued documents.
7. A `requestId` is applied at most once.
8. Every server write checks `expectedVersion` when the client provided
   one; mismatch → `conflict`, the client reloads.

### Payment status (stored, recomputed on each write)

```
if type is not settleable (adjustment)           → notApplicable
if R > 0:  R == P   → refunded
           else     → partiallyRefunded
if P + C ≥ T        → paid           (T−C == 0 also counts: fully credited)
if P > 0            → partiallyPaid
else                → unpaid
```

**Overdue** is never stored. It is computed: `confirmed ∧ outstanding > 0
∧ dueDate < today` and rendered/filtered on top of the payment status.

### Immediate settlement

`confirmTransaction(..., settleNow: true)` confirms and records a payment
of the full amount in one atomic write (cash expense → Paid).

### Type behaviour

| Type | direction | settleable | counts as |
|---|---|---|---|
| income | in | yes | income |
| sale | in | yes | income, receivable |
| expense | out | yes | expense |
| purchase | out | yes | expense, payable |
| payment | in/out | settled on confirm | cash only (advance / transfer) |
| adjustment | in/out | no | income or expense correction |
| refund | — | — | not created directly; see below |

A refund is a **settlement** of kind `refund` on the original, and a
linked `refund` transaction is created for the ledger list so the
movement is visible as its own entry. The linked entry has no money
effect of its own (it is excluded from stats); the original carries it.

### Rounding

All arithmetic is integer. Quantity × rate uses `quantityMilli`
(3 dp) and rounds **half away from zero** to the currency's minor unit,
per line; the total is the sum of rounded lines.

## 6. Reports

The RPCs maintain `daily_stats` (one row per business and day) in the
**same database transaction** as the financial write (`app.apply_stats`),
and the app reads the pulled rows from the local store:

```
incomeMinor, expenseMinor            by transaction date (effective amount)
cashInMinor, cashOutMinor            by settlement date
byCategory  {cid: {in, out}}
byProject   {pid: {in, out}}
byType      {type: {in, out}}
```

Every operation applies a *delta* (confirm adds, edit applies the
difference, cancel subtracts, refund subtracts from income/expense on
the original date and moves cash on the refund date). Drafts never touch
stats. Weekly/monthly views sum the daily rows in range.

Receivables / payables = `SUM(outstanding_minor)` by direction over the
open confirmed transactions in the local store, computed by SQLite in
integers (`ReportsService.receivablesAndPayables`); works offline, as of
the last pull.

The dashboard always shows **cash received / paid** separately from
**income / expense**, and labels outstanding money as such.

## 7. Documents

* invoice → sale/income, bill → purchase/expense, receipt → a payment
  settlement (shows paid-to-date and remaining balance).
* `issue_document` allocates `PREFIX-YYYY-NNNN` from `counters` under a
  row lock, and stores a snapshot. The same
  `(transactionId, settlementId, type)` returns the existing document.
* The PDF is rendered on device from the snapshot (`pdf` package),
  previewed, shared and printed with `printing`. It is rendered on demand
  every time and **never stored**: the stored snapshot is enough to
  reproduce it exactly. Issued documents are read-only to clients (RLS
  allows no client write).
* Cancelled transactions cannot issue documents; existing ones render
  with a **VOID** watermark.

## 8. Security

* Membership is a `members` row (business_id, user_id); RLS policies call
  `app.is_member` / `app.has_role`. Roles: owner > admin > editor > viewer.
* viewer: read. editor: drafts + config. admin: + financial ops +
  members. owner: + archive business / transfer ownership.
* RPCs are `security definer` and re-check membership and role inside
  (RLS does not apply to them). See `supabase/README.md`.

## 9. Testing

* Dart: `LedgerMath`, `Money`, status transitions, blocs (bloc_test +
  hand-written stub repositories).
* Functions: the ledger core (pure TS) with shared JSON fixtures
  (`test/fixtures/ledger_cases.json`) also run by the Dart suite, so
  both implementations agree.
* Rules: `@firebase/rules-unit-testing` against the emulator (until
  Phase C).
* Database: `supabase/tests` runs every migration in PGlite (in-process
  Postgres): RLS, RPCs and the shared money fixtures (`npm test`).
* Data layer: drift DAO tests on an in-memory SQLite
  (`NativeDatabase.memory()`), the pull engine, push replay, RPC mapping
  and the PostgREST error mapping, all against fakes of the app's own
  `RemoteTables` / `RemoteRpc` interfaces (no network).

## Conventions

Copied from easify_crm_flutter: feature folders, `XRepository` /
`XService`, `@injectable` blocs per route via `AutoRouteWrapper`,
`Status` per operation, hand-written Equatable states with `copyWith`,
json_serializable models, `abstract final class` token holders,
flutter_screenutil scaling, `package:` imports, very_good_analysis,
`main_dev.dart` / `main_prod.dart` + `bootstrap()`.

### Deviations

| Reference | Here | Reason |
|---|---|---|
| `ApiResult` / `ApiException` (HTTP) | `AppResult` / `AppException` | Errors come from PostgREST (the RPC error contract, SQLSTATEs) and Firebase Auth, normalised to codes (`permission-denied`, `aborted`, `unavailable`…). Same sealed shape and `when`. |
| Token store + guard | `FirebaseAuth.authStateChanges` + guard | Firebase owns the session. |
| Light theme only | Dark theme as the primary theme | Product requirement. |
| Models parsed from JSON strings loosely | Hand-written row readers (`JsonRead`, `JsonReader`) over Postgres rows | Our own schema; a malformed row falls back field by field (lists) or fails loudly (documents). |
| Floating-point money (`ValueFormat.money(num)`) | `Money` over integer minor units | Financial correctness. |
| Brief §3/§8 optional attachments + stored documents | Not implemented | User decision: text-only data; documents are reproducible from the stored snapshot. |
