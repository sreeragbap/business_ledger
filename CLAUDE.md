# Business Ledger

A digital ledger for small businesses. One user can run several businesses
(a construction firm, a shop…), each with its own categories, fields, members,
transactions and reports. Flutter app for **Android and iOS only**, backed by
**Firebase** (Auth, Firestore, Cloud Functions).

This file is the starting context for every session. Deeper detail lives in:

| Doc | Read it when |
|---|---|
| `docs/ARCHITECTURE.md` | changing data shapes, money rules, security, offline behaviour |
| `docs/FUNCTIONS_API.md` | calling or changing a Cloud Function |
| `docs/PROGRESS.md` | deciding what to work on next |

---

## 1. Rules for working in this repo

These come from the user. Follow them every time.

1. **Ask before every commit and push.** Show the files and the commit message,
   wait for a clear "yes". Background agents must be told: *no git commands
   that change state*.
2. **Ask before deploying** anything to Firebase (rules, indexes, functions):
   it changes the live project.
3. **Git identity**: push to `git@github-personal:sreeragbap/business_ledger.git`
   (SSH alias for the user's personal GitHub). The repo-local identity is
   `sreeragbap <72739970+sreeragbap@users.noreply.github.com>`. Never use the
   global work identity. `gh` CLI is not logged in.
4. **Firebase CLI**: always add `--account sreeragk136@gmail.com`; the default
   login is a different (work) account.
5. Before saying something works: `flutter analyze` (zero issues),
   `flutter test`, and for server changes `npm test` + `npm run test:emulator`.

---

## 2. How it works, in one picture

```
 Phone (Flutter)                                Firebase
 ───────────────                                ────────
 Screens ─► Cubits ─► Repositories ─┬─► Firestore SDK ──────► Firestore
                                    │   (drafts, settings;      (rules allow
                                    │    local cache, works      drafts/config
                                    │    offline)                only)
                                    │
                                    └─► CallableClient ──────► Cloud Functions
                                        (money actions)         asia-south1
                                          │                     (validate, apply,
                                          └─ offline / sync off  update stats,
                                             → Outbox (JSON on   audit, numbers)
                                               device), replayed
                                               later in order
```

**Life of a transaction**
1. User fills the form → saved as a **draft** straight to Firestore (works
   offline). Drafts never count in any total.
2. **Confirm** → callable `confirmTransaction`. The server checks required
   fields, computes the balance, writes the transaction, that day's
   `stats/{date}` totals and an audit entry — all in one Firestore transaction.
   "Confirm as paid" also records the full payment.
3. **Payments / refunds / credits** → `recordSettlement`. Re-reads the balance
   inside the transaction, so two people paying at once can't overpay. A refund
   also creates a linked "refund" entry for the list (it carries no money of
   its own; the original does).
4. **Edit** a confirmed one → `editConfirmedTransaction` with the version the
   user saw; a newer version on the server = "changed by someone else, reload".
5. **Cancel** → only after money is refunded; voids its documents; stays in
   history.
6. **Invoice / bill / receipt** → `issueDocument` gives a gap-free number and
   stores a text snapshot; the PDF is drawn on the phone whenever needed.

Every money call carries a `requestId`. Sending the same one twice returns the
first result — that is what makes retries and offline replay safe.

---

## 3. Money rules (the part that must never break)

Amounts are **integers in minor units** (paise/cents) everywhere — `Money`,
`amountMinor`. No doubles for money, ever.

With T = total, P = paid, R = refunded, C = credited (discounts):

```
outstanding = T − C − P        what is still owed
effective   = T − C − R        income/expense actually recognised
```

- A refund reduces income and returns cash, but never re-opens what's owed.
- Payments + credits ≤ total; refunds ≤ payments; cancel only when net paid = 0.
- **Overdue** is calculated (confirmed, owed > 0, due date passed) — never stored.
- Drafts and cancelled entries never count in totals.
- Line amount = quantity × rate, rounded half away from zero, per line.

The rules exist **twice** and must stay identical:
`lib/core/ledger/ledger_math.dart` (phone, for previews) and
`functions/src/ledger.ts` (server, the authority). Both run the shared fixtures
in `shared/ledger_cases.json`. **Change a rule → change both + the fixtures.**
The same applies to search tokens (`search_tokens.dart` / `searchTokens()`).

---

## 4. Decisions already made (don't reopen without the user)

| Decision | Why |
|---|---|
| **Migrating data to Supabase (Postgres)** — in progress. Firebase stays for **Google/Apple sign-in, push notifications (FCM) and Crashlytics**; Firestore, Cloud Functions and their rules/tests will be removed | User's decision (2026-10). Supabase project `unvpyjnotaukdxgmpytr` (Mumbai), URL `https://unvpyjnotaukdxgmpytr.supabase.co`, publishable key in app config. Supabase trusts Firebase ID tokens (Third-party Auth → Firebase) |
| Money logic moves to **Postgres functions** (RPC) with row locks + `requests` idempotency | Replaces the 10 Cloud Functions; no Firebase Blaze plan needed |
| Offline = **on-device SQLite (drift) + own sync** (outbox push, pull rows by `seq` cursor) | Supabase has no offline cache; keeps the Cloud sync switch and pending-sync UX |
| **Text only — no file storage** (no attachments, no Cloud Storage, no stored PDFs) | User's choice; documents are re-drawn from their stored snapshot (deviation from brief §3/§8) |
| Server decides all money changes; phone writes only drafts and settings | Security rules enforce it; a modified app can't fake balances |
| **Local-first sync** with a per-device *Cloud sync* switch (Settings › Sync) | Works with no network; money actions queue as "Pending sync" and replay in order; refusals shown for retry/discard; queued payments count in on-phone checks; sign-out blocked while unsynced |
| Not queueable: create business, members, delete category, issue document | They need the server's answer immediately (e.g. document numbers) |
| Firestore in **asia-south1**, Functions in **asia-south1** | Users are in India |
| Prod uses the same Firebase project as dev for now | Only one project exists |
| Flavors are Dart-only: `-t lib/main_dev.dart` / `lib/main_prod.dart` | `lib/main.dart` throws on purpose |

---

## 5. Where things live

```
lib/
  app/             bootstrap, flavors, AppConfig, Firebase options
  core/
    ledger/ money/ the money rules and Money type (pure, unit-tested)
    firebase/      FirestoreRefs, CallableClient, tolerant readers, local-first writer
    sync/          Cloud sync switch, outbox, SyncEngine (offline replay)
    domain/        AppResult / AppException; bloc/ Status
    router/ di/    auto_route + guards; get_it/injectable (generated files)
    theme/ widgets/ dark design tokens and App* components
  features/
    auth/          Google + Apple sign-in (+ emulator test account)
    app_lock/      biometric lock
    business/      businesses, members, roles, BusinessScopeCubit (current business)
    categories/ parties/ projects/   per-business configuration
    transactions/  list, form, detail, settlements, pending-sync display
    reports/ dashboard/   stats, receivables/payables, charts
    documents/     invoice/bill/receipt PDFs from snapshots
    sync/          Sync screen, status banner, sign-out guard
functions/src/     ledger.ts, schemas.ts, handlers/*, lib/* (roles, idempotency, stats…)
firestore.rules  firestore.indexes.json  shared/ledger_cases.json
```

**Conventions** (copied from the reference app
`/Users/sreeragkm/Documents/projects/easify_crm_flutter`):
feature folders `domain/{const,models,repository,services}, logic, screens,
widgets, index.dart`; `XRepository` (abstract) + `XService`
(`@LazySingleton(as: XRepository)`); `@injectable` cubits provided per route
via `AutoRouteWrapper`; Equatable states with `copyWith` and a `Status` per
operation; repositories return `AppResult<T>` and never throw; `package:`
imports; very_good_analysis clean; tokens `AppColors/AppSpacing/AppRadius/
AppTextStyles` with ScreenUtil (393×852). Firestore models use hand-written
tolerant converters (`core/firebase/firestore_read.dart`), not json_serializable.

---

## 6. Common tasks

- **Add a field to transactions**: model + `toMap` (`features/transactions/
  domain/models`), form/detail UI, `validDraft` in `firestore.rules` if clients
  write it, server handler/schema if the server writes or validates it, rules
  test, docs §3/§4.
- **Change a money rule**: §3 above — both implementations + fixtures + tests.
- **Add a callable**: schema in `functions/src/schemas.ts`, handler using
  `handler()` + `once()` (idempotency) + `requireRole()`, export in `index.ts`,
  integration test, `docs/FUNCTIONS_API.md`, then the Dart repository call
  (decide: queueable through the outbox or online-only).
- **New query with filters**: add the composite index to
  `firestore.indexes.json` (only deployed with the user's OK).
- **Generated code**: after changing injectable/auto_route annotations run
  `dart run build_runner build`.

---

## 7. Commands

```bash
# App
dart run build_runner build
dart format lib test            # CI rejects unformatted code
flutter analyze                 # must report no issues
flutter test
flutter run -t lib/main_dev.dart                                   # real Firebase
flutter run -t lib/main_dev.dart --dart-define=USE_EMULATOR=true   # local emulators
#   physical phone + emulators: add --dart-define=EMULATOR_HOST=<Mac LAN IP>
#   emulator mode shows "Continue with test account"

# Server (cd functions)
npm run lint && npm run build && npm test   # includes the shared money fixtures
npm run test:emulator                       # rules + integration tests (needs Java)
npm run serve                               # build + start emulators for the app
```

VS Code launch configs: **Dev**, **Dev (Firebase emulators)**, **Prod**.

---

## 8. Firebase project `busineedger-ab7a1` — current state

Done: iOS app `com.iocod.businessLedger` and Android app
`com.iocod.business_ledger` registered; config files generated
(`lib/app/firebase_options_*.dart`, `google-services.json`,
`GoogleService-Info.plist`); Google sign-in enabled; iOS URL scheme set; this
Mac's debug SHA-1/SHA-256 added to the Android app.

**Still to do by the user** (console): upgrade to **Blaze** (needed for
Functions), **create the Firestore database in asia-south1**, Apple sign-in
(Firebase provider + Apple Developer capability + Xcode team). Then, with the
user's OK, deploy rules + indexes + functions. Release / Play signing will need
its own SHA fingerprints.

**Known gotchas**
- Re-running `flutterfire configure` brings back its Crashlytics
  "upload symbols" build phase, which breaks debug builds. Re-apply our guard
  in `ios/Runner.xcodeproj/project.pbxproj` (Release only, never fail), copy
  the dev options file over the prod one, and re-indent `firebase.json`.
- iOS Google Sign-In crashes the app natively without a client id + URL scheme;
  `AuthService` refuses with a message instead.
- "No AppCheckProvider installed" in logs is a harmless warning.

---

## 9. What's next

Supabase migration plan:
- **Phase A** — `supabase/`: schema, RLS, RPCs, SQL ledger rules, tests in
  PGlite (`cd supabase/tests && npm test`). Nothing applied remotely without OK.
- **Phase B** — app data layer on drift + Supabase client (Firebase ID token as
  access token), sync engine pull/push, error mapping from Postgres errors.
- **Phase C** — remove Firestore, Cloud Functions, rules, indexes, emulator
  tests; update CI/docs/this file.
- **Phase D** — push notifications via FCM, sent from a Supabase Edge Function.

Until Phase C lands, sections 2–8 still describe the Firestore implementation.


- Stage 9: polish, error handling, an end-to-end test against the emulators.
- Stage 10: deploy (after console steps + OK), test on real devices.
- Unpushed local commits: check `git log origin/main..main` and ask before pushing.
