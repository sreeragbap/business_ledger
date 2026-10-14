# Business Ledger — Architecture

A multi-business digital ledger. Flutter (Android + iOS) over Firebase
(Auth, Firestore, Storage, Cloud Functions).

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
│   ├── theme/      dark tokens
│   └── widgets/    App* components
└── features/<name>/{domain/{const,models,repository,services},logic,screens,widgets}
```

* A screen never touches Firestore. Blocs depend on `XRepository`
  (abstract); `XService` implements it over Firestore / Functions.
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

* Firestore persistence is on; all reads are served from cache when
  offline, and the UI shows an "offline" banner.
* Draft and configuration writes queue locally and sync on reconnect.
* Financial callables require connectivity. The UI disables them
  offline with a clear message instead of queuing — a payment silently
  replayed hours later is worse than one the user must retry.
* Every callable carries a client-generated `requestId`; a retry after
  a timeout returns the original result instead of applying twice.

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
| `attachments[]` | Storage paths |
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
  previewed/shared with `printing`, optionally uploaded to Storage.
* Cancelled transactions cannot issue documents; existing ones render
  with a **VOID** watermark.

## 8. Security

* Membership is `businesses/{bid}/members/{uid}`; rules use
  `exists()/get()` on it. Roles: owner > admin > editor > viewer.
* viewer: read. editor: drafts + config. admin: + financial ops +
  members. owner: + delete business / transfer ownership.
* Storage paths `businesses/{bid}/...` mirror the same membership check;
  attachments ≤ 10 MB, images/PDF only.
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
