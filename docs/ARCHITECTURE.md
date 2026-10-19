# Business Ledger — Architecture

A multi-business digital ledger. Flutter (Android + iOS) over Firebase
(Auth, Firestore, Cloud Functions). The app stores **text only**: there is
no file storage (no Cloud Storage, no attachments); invoices, bills and
receipts are rendered on the device from Firestore data whenever needed.

Conventions are taken from `easify_crm_flutter` (see
[Conventions](#conventions)); deviations are listed with the reason.

---

## 1. Layering

```
lib/
├── app/            bootstrap, flavors, AppConfig, App widget
├── core/           knows nothing about features/
│   ├── bloc/       Status
│   ├── di/         get_it + injectable
│   ├── domain/     AppResult / AppException, shared models
│   ├── firebase/   FirestoreRefs, CallableClient, Crashlytics, SocialAuth
│   ├── money/      Money, Currency            ◀ the only place money is maths
│   ├── ledger/     LedgerMath, rules           ◀ pure, unit-tested
│   ├── router/     auto_route, AuthGuard
│   ├── sync/       Cloud sync switch, outbox, SyncEngine (§2)
│   ├── theme/      dark tokens
│   └── widgets/    App* components
└── features/<name>/{domain/{const,models,repository,services},logic,screens,widgets}
```

* A screen never touches Firestore. Blocs depend on `XRepository`
  (abstract); `XService` implements it over Firestore / Functions. There
  is no Cloud Storage layer: every record is text in Firestore.
* Every repository call returns `AppResult<T>` and never throws.
* No financial arithmetic in widgets or blocs: they call `LedgerMath`.

## 2. Trust boundary

| Operation | Path | Why |
|---|---|---|
| Create / edit / delete a **draft** transaction | Client → Firestore (rules-checked) | Works offline; drafts carry no money effect. |
| Categories, fields, parties, projects (create, edit, reorder, archive) | Client → Firestore (rules-checked) | Configuration, offline-friendly. |
| Create business, members & roles | Callable function | Must write business + membership atomically and seed templates. |
| Confirm, edit confirmed, cancel | Callable function | Changes balances and stats. |
| Record payment / refund / credit | Callable function | Idempotency + concurrency on balances. |
| Delete category | Callable function | Must prove no transaction references it. |
| Issue invoice / bill / receipt number | Callable function | Gap-free, unique numbering per business. |

Rules make the server path mandatory: clients **cannot** write a
non-draft transaction, settlement, audit entry, stats doc, counter,
document record or membership.

### Offline behaviour

**Cloud sync switch.** Settings › Sync has a per-device *Cloud sync* switch
(default on, `SyncSettings`, stored in shared_preferences). Off, the app
works entirely from this device: `FirebaseFirestore.disableNetwork()` is
applied (also at bootstrap, before the first screen), reads come from the
persistent cache (unlimited size), and every change waits locally until it is
switched back on. "The cloud is reachable" (`CloudAvailability`) means
*device online **and** sync on*; everything that used to ask "am I online?"
asks that instead, so sync-off behaves exactly like offline.

**Drafts and configuration** are plain Firestore writes, queued by the SDK
and reported as saved at once (`LocalFirstWriter`); a rules rejection that
arrives later is shown as a snack bar.

**Money actions are queued, not applied locally.** Confirm, record
settlement, edit confirmed and cancel go through `SyncQueue`:

* cloud reachable → called directly (the `RequestTracker` retry rules
  still apply);
* offline, sync off, an earlier action for the same transaction still
  queued, local Firestore writes not acknowledged within a few seconds, or a
  direct call failing with unavailable / deadline-exceeded / no network →
  the action is appended to the **outbox** and the UI shows it as *Pending
  sync* (not an error). Nothing about it is reflected in balances until the
  server applies it: there is no optimistic money maths.

The outbox (`core/sync/`) is a JSON file in the app support directory,
written atomically (temp file + rename); an unreadable file is moved aside
and the queue starts empty. An entry holds the owner `uid`, business,
callable, payload (with its `requestId`), transaction, a human label
("Payment ₹1,200.00 · Cement bags"), status (pending / syncing / failed),
attempts, last error and, for edits, the version the user edited.

**Replay** (`SyncEngine`, started by `App`) runs while a user is signed in,
sync is on and the device is online. It sends that user's entries oldest
first, one at a time (other users' entries stay dormant: the server's
idempotency record is per user):

* Before each entry it awaits `waitForPendingWrites()` with a timeout, so a
  draft created or edited offline is on the server before
  `confirmTransaction` reads it; on timeout nothing is sent and it retries
  later.
* **Replay safety.** The entry keeps its original `requestId`. A replay of
  an action that did land (the app died mid-call, a timeout) returns the
  stored result instead of applying it again (`requests/{uid}_{requestId}`).
* **Version chaining.** A queued `expectedVersion` would be stale, so it is
  omitted where optional (confirm, settle, cancel). An edit requires it:
  it is sent as the version the user edited plus the number of earlier
  queued actions on the same transaction that have since succeeded (every
  server write bumps `version` by exactly 1). If the server still answers
  `aborted`, someone else changed the transaction: the entry fails with
  "Changed by someone else — review and retry".
* **Failures.** A definitive refusal (invalid-argument, failed-precondition,
  permission-denied, not-found, already-exists, aborted, unauthenticated)
  marks the entry *failed* with the server's user-safe message and holds
  back later entries for **the same transaction** (they likely depend on
  it); other transactions continue. A transient one (unavailable,
  deadline-exceeded, internal, resource-exhausted, network) keeps it pending
  with exponential backoff (5 s doubling to 5 min); a reconnect or "Sync
  now" retries at once. The user can retry a failed entry (same
  `requestId`) or discard it, together with its dependents after
  confirmation.

Why queuing money is safe now (the earlier rule refused financial callables
offline): replays are idempotent by `requestId`; the server re-validates
every rule against the current balance at replay time, so a payment that no
longer fits is refused rather than applied; and the pending state is always
visible (sync banner, *Pending sync* on rows and under the balance, the Sync
screen), with refusals flagged for the user.

The outbox holds callables only (confirm, settle, edit, cancel). There are
no file uploads to queue: the app stores text only. An entry of an unknown
kind (e.g. an `upload` left by an older build) is skipped when the outbox
is read.

**Never queued** (they need the server's answer now): create business,
member changes, delete category, issue document. Offline or with sync off
they are disabled with "Needs a connection and sync turned on".

**Status.** `SyncStatus` = sync on, online, syncing, pending and failed
counts, last sync time and `firestoreHasPendingWrites`. Firestore has no
pending-write count, so the latter is a heuristic: writes this session
handed to the queue without an acknowledgement (`LocalFirstWriter` →
`PendingWritesTracker`), plus a `waitForPendingWrites()` probe at start and
on reconnect that has not finished within a grace period (covers writes
left by an earlier session).

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
(after a second confirmation: drops that user's entries and staged files),
or Cancel.

## 3. Firestore data model

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

Functions maintain `stats/{yyyy-MM-dd}` in the **same Firestore
transaction** as the financial write:

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
stats. Weekly/monthly views sum the daily docs in range.

Receivables / payables = sum aggregate over open confirmed
transactions (`sum(outstandingMinor)` aggregate query by direction).

The dashboard always shows **cash received / paid** separately from
**income / expense**, and labels outstanding money as such.

## 7. Documents

* invoice → sale/income, bill → purchase/expense, receipt → a payment
  settlement (shows paid-to-date and remaining balance).
* `issueDocument` allocates `PREFIX-YYYY-NNNN` from
  `counters/{type}` in a transaction, and stores a snapshot. The same
  `(transactionId, settlementId, type)` returns the existing document.
* The PDF is rendered on device from the snapshot (`pdf` package),
  previewed, shared and printed with `printing`. It is rendered on demand
  every time and **never stored**: the stored snapshot is enough to
  reproduce it exactly. Issued documents are read-only to clients (rules
  allow no client write).
* Cancelled transactions cannot issue documents; existing ones render
  with a **VOID** watermark.

## 8. Security

* Membership is `businesses/{bid}/members/{uid}`; rules use
  `exists()/get()` on it. Roles: owner > admin > editor > viewer.
* viewer: read. editor: drafts + config. admin: + financial ops +
  members. owner: + delete business / transfer ownership.
* Functions re-check membership and role for every call (rules do not
  apply to the Admin SDK).

## 9. Testing

* Dart: `LedgerMath`, `Money`, status transitions, blocs (bloc_test +
  hand-written stub repositories).
* Functions: the ledger core (pure TS) with shared JSON fixtures
  (`test/fixtures/ledger_cases.json`) also run by the Dart suite, so
  both implementations agree.
* Rules: `@firebase/rules-unit-testing` against the emulator.

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
| `ApiResult` / `ApiException` (HTTP) | `AppResult` / `AppException` | No REST backend; errors come from Firestore/Functions codes (`permission-denied`, `aborted`, `unavailable`…). Same sealed shape and `when`. |
| Token store + guard | `FirebaseAuth.authStateChanges` + guard | Firebase owns the session. |
| Light theme only | Dark theme as the primary theme | Product requirement. |
| Models parsed from JSON strings loosely | Strict typed Firestore converters | Our own schema; drift is a bug to surface, not absorb. |
| Floating-point money (`ValueFormat.money(num)`) | `Money` over integer minor units | Financial correctness. |
| Brief §3/§8 optional attachments + stored documents | Not implemented | User decision: text-only data; documents are reproducible from the stored snapshot. |
