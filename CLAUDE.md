# Business Ledger

A digital ledger for small businesses. One user can run several businesses
(a construction firm, a shop…), each with its own categories, fields, members,
transactions and reports. Flutter app for **Android and iOS only**.

- **Data**: Supabase Postgres (tables, row-level security, SQL functions).
- **On the phone**: SQLite via drift — every screen reads from it, so the app
  works fully offline, and a sync engine keeps it in step with Supabase.
- **Firebase**: only Google/Apple **sign-in**, Crashlytics, and (planned) push
  notifications. Supabase trusts Firebase ID tokens (Third-party Auth).
- **Receipt scanning**: on-device OCR (iOS VisionKit + Vision, Android ML Kit
  document scanner + text recognition, platform channel
  `business_ledger/receipt_scanner`), then Claude reads the text into fields
  through the Supabase Edge Function `scan-receipt`; offline the on-device
  `ReceiptParser` (total, date, shop, bill no., items, seller GSTIN/contact)
  stands in. Only text leaves the phone. A new shop becomes a supplier;
  the receipt's date goes to `receipt_date` (shown under "When" only when
  scanned), never to the transaction date.

This file is the starting context for every session. Deeper detail:

| Doc | Read it when |
|---|---|
| `supabase/README.md` | schema, RLS, RPC signatures, error contract, sync/pull contract |
| `docs/ARCHITECTURE.md` | layering, offline/sync design, money rules, reports, documents |
| `docs/PROGRESS.md` | deciding what to work on next |
| `docs/FUNCTIONS_API.md` | historical: the Cloud Functions contract the RPCs replaced |

---

## 1. Rules for working in this repo

These come from the user. Follow them every time.

1. **Ask before every commit and push.** Show the files and the commit message,
   wait for a clear "yes". Background agents must be told: *no git commands
   that change state*.
2. **Ask before changing anything live**: Supabase migrations (`db push`),
   Supabase/Firebase settings, deploys. The permission system blocks
   `npx supabase db push` for Claude — the user runs it.
3. **Git identity**: push to `git@github-personal:sreeragbap/business_ledger.git`
   (SSH alias for the user's personal GitHub). Repo-local identity
   `sreeragbap <72739970+sreeragbap@users.noreply.github.com>`. Never use the
   global work identity. `gh` CLI is not logged in.
4. **Firebase CLI**: always add `--account sreeragk136@gmail.com`.
5. Before saying something works: `flutter analyze` (zero issues),
   `flutter test`, and for database changes `cd supabase/tests && npm test`.

---

## 2. How it works

```
 Phone                                               Cloud
 ─────                                               ─────
 Screens ─► Cubits ─► Repositories
                         │ read: drift streams (watch)
                         ▼
                    SQLite (drift) ◄──── SyncPuller ◄──── Supabase tables
                         ▲              (rows with seq > cursor,   (RLS)
                         │               per business, 500/page)
                         │ write
                    LocalWriter ──► Outbox (JSON file, FIFO) ──► SyncEngine
                                     upsert / update rows   ──► PostgREST
                                     rpc (money actions)    ──► SQL functions
 Firebase Auth ── ID token ──► Supabase client accessToken
```

- **Reads** always come from SQLite, never straight from the network.
- **Drafts and settings** are written to SQLite at once and queued as
  `upsert`/`update` outbox entries.
- **Money actions** call SQL functions (RPCs): directly when online and nothing
  is queued, otherwise queued behind earlier entries (so a draft's upsert lands
  before its confirm). Each keeps its `requestId` → replays never apply twice.
- **Pull**: profile → businesses (ones you lost access to are wiped locally) →
  each table by `seq` cursor. Runs on start, sign-in, reconnect, sync on,
  after pushes, pull-to-refresh, foreground, and every 60 s in foreground.
- **Cloud sync switch** (Settings › Sync) gates the engine. `CloudAvailability`
  = online && sync on && signed in. Refused entries → "Needs attention"
  (retry/discard). Sign-out is blocked while entries are pending, and
  sign-out (or a different user signing in) wipes the local store.
- **Online-only** RPCs: `create_business`, member changes, `delete_category`,
  `issue_document` — they need the server's answer immediately.

**Life of a transaction**
1. Form → **draft** row in SQLite → upserted to Supabase. Drafts never count.
2. **Confirm** → `confirm_transaction`: validates, computes the balance, writes
   the row, `daily_stats` delta and audit row in one database transaction.
   "Confirm as paid" also records the full payment.
3. **Payment / refund / credit** → `record_settlement`: locks the row, so two
   people paying at once can't overpay. A refund adds a linked "refund" entry
   (no money of its own). Queued settlements also count in on-phone checks.
4. **Edit** a confirmed one → `edit_confirmed_transaction` with the version the
   user saw; newer on the server = "changed by someone else, reload".
5. **Cancel** → `cancel_transaction`, only after money is refunded; voids its
   documents; stays in history.
6. **Invoice / bill / receipt** → `issue_document`: gap-free
   `PREFIX-YYYY-NNNN` number + stored text snapshot; the PDF is drawn on the
   phone whenever needed (nothing is stored as a file).

---

## 3. Money rules (the part that must never break)

Amounts are **integers in minor units** (paise/cents) everywhere — `Money`,
`*_minor` columns (bigint). No doubles for money, ever.

With T = total, P = paid, R = refunded, C = credited (discounts):

```
outstanding = T − C − P        what is still owed
effective   = T − C − R        income/expense actually recognised
```

- A refund reduces income and returns cash, but never re-opens what's owed.
- Payments + credits ≤ total; refunds ≤ payments; cancel only when net paid = 0
  (also enforced by table CHECKs).
- **Overdue** is calculated (confirmed, owed > 0, due date passed) — never stored.
- Drafts and cancelled entries never count in totals.
- Line amount = quantity × rate, rounded half away from zero, per line.

The rules exist **twice** and must stay identical: Dart
`lib/core/ledger/ledger_math.dart` (on-phone checks and previews) and SQL
`supabase/migrations/*_ledger_rules.sql` (the authority). Both run the shared
fixtures `shared/ledger_cases.json` (`flutter test`, `supabase/tests`).
**Change a rule → change both + the fixtures** (as a new migration). Same for
search tokens. `functions/src/ledger.ts` is legacy until Phase C removes it.

---

## 4. Decisions already made (don't reopen without the user)

| Decision | Why |
|---|---|
| **Supabase Postgres** for all data; Firestore and Cloud Functions are being removed | User's decision (2026-10). Project `unvpyjnotaukdxgmpytr` (Mumbai), URL `https://unvpyjnotaukdxgmpytr.supabase.co`, publishable key in `AppConfig` |
| **Firebase stays for sign-in** (Google/Apple), Crashlytics and push notifications | User's decision; Supabase accepts Firebase ID tokens (`iss`/`aud` = `busineedger-ab7a1`), no `role` claim needed |
| Money logic in **Postgres functions** (RPC), one transaction each, row locks, `requests` idempotency | Strongest guarantees for balances; no Firebase Blaze plan needed |
| **Offline = SQLite (drift) + own sync** (outbox push, pull by `seq`) | Supabase has no offline cache; keeps the Cloud sync switch and pending-sync UX |
| **Text only — no file storage** (no attachments, no stored PDFs) | User's choice; documents re-drawn from their snapshot (deviation from brief §3/§8) |
| **Receipt scan: on-device OCR + Claude Haiku 5.5 on the text** (Edge Function `scan-receipt`), fills the form immediately | User asked for AI-supported scanning that fills at once (2026-10); text-only keeps photos on the phone, fast and cheap; offline falls back to `ReceiptParser` |
| Clients write only drafts and configuration; everything that moves money goes through RPCs | RLS enforces it; a modified app can't fake balances |
| Not queueable: create business, members, delete category, issue document | Need the server's answer immediately |
| Flavors are Dart-only: `-t lib/main_dev.dart` / `lib/main_prod.dart` | `lib/main.dart` throws on purpose; prod uses the same backends for now |

---

## 5. Where things live

```
lib/
  app/             bootstrap, flavors, AppConfig (Supabase URL/key), Firebase options
  core/
    ledger/ money/ money rules and Money type (pure, unit-tested)
    database/      drift tables, AppDatabase, LocalStore DAO, row codec
    supabase/      Supabase setup, RemoteTables / RemoteRpc interfaces, RpcClient
    sync/          outbox, SyncEngine, SyncPuller, LocalWriter, profile sync,
                   Cloud sync switch, CloudAvailability, status
    domain/        AppResult / AppException (fromPostgrest), JsonRead; bloc/ Status
    router/ di/    auto_route + guards; get_it/injectable (generated files)
    theme/ widgets/ dark design tokens and App* components
  features/
    auth/          Firebase Google + Apple sign-in (+ emulator test account)
    app_lock/      biometric lock
    business/      businesses, members, roles, BusinessScopeCubit
    categories/ parties/ projects/   per-business configuration
    receipt_scan/  scanner channel, OCR → ReceiptParser / AI (scan-receipt)
    transactions/  list, form, detail, settlements, pending-sync display
    reports/ dashboard/   daily stats, receivables/payables, charts
    documents/     invoice/bill/receipt PDFs from snapshots
    sync/          Sync screen, status banner, sign-out guard
supabase/
  migrations/      schema, RLS, RPCs, ledger rules (apply in order)
  functions/       Edge Functions (scan-receipt: receipt text → fields, Claude)
  tests/           PGlite + vitest: fixtures, RPC scenarios, RLS
shared/ledger_cases.json   money-rule fixtures used by Dart and SQL
functions/ firestore.*     legacy — removed in Phase C
```

**Conventions** (from the reference app
`/Users/sreeragkm/Documents/projects/easify_crm_flutter`): feature folders
`domain/{const,models,repository,services}, logic, screens, widgets,
index.dart`; `XRepository` (abstract) + `XService`
(`@LazySingleton(as: XRepository)`); `@injectable` cubits provided per route
via `AutoRouteWrapper`; Equatable states with `copyWith` and a `Status` per
operation; repositories return `AppResult<T>` and never throw; `package:`
imports; very_good_analysis clean; tokens `AppColors/AppSpacing/AppRadius/
AppTextStyles` with ScreenUtil (393×852). Models map Postgres rows with
`fromRow`/`toRow` (snake_case columns; JSON columns keep camelCase keys).
In widget tests, don't await `cubit.close()` inside fake-async.

---

## 6. Common tasks

- **Add a column** (e.g. to transactions): new migration in
  `supabase/migrations/` (never edit an applied one) + RLS/`app.valid_draft` if
  clients write it + RPC changes if the server writes it + supabase test;
  drift table column (`lib/core/database/tables.dart`) + model
  `fromRow`/`toRow`; run build_runner.
- **Change a money rule**: §3 — Dart + SQL migration + fixtures + tests.
- **Add an RPC**: migration (security definer, empty `search_path`, role
  check, `requests` idempotency if it moves money, audit), test in
  `supabase/tests`, entry in `RpcClient`, and decide: queueable through the
  outbox or online-only. Document it in `supabase/README.md`.
- **New screen query**: write it as a drift query (SQL on the phone); no
  server indexes needed for reads.
- **Generated code**: after changing drift tables or injectable/auto_route
  annotations, run `dart run build_runner build`.

---

## 7. Commands

```bash
# App
dart run build_runner build
dart format lib test            # CI rejects unformatted code
flutter analyze                 # must report no issues
flutter test
flutter run -t lib/main_dev.dart        # real Firebase sign-in + Supabase
./build.sh                      # interactive APK/AAB/IPA builds; prod release
                                # runs a checklist, obfuscates, offers the
                                # Crashlytics Dart-symbol upload
dart run flutter_launcher_icons   # app icons from assets/icon (then revert its
                                  # pbxproj SWIFT_ASSET_SYMBOL_EXTENSIONS change)

# Database (no Docker needed: tests run Postgres in-process via PGlite)
cd supabase/tests && npm test
npx supabase migration list             # local vs remote (read-only)
npx supabase db push --dry-run          # what would be applied (read-only)
npx supabase db push                    # user runs this (live change)
npx supabase functions deploy scan-receipt   # user runs this (live change)
npx supabase secrets set ANTHROPIC_API_KEY=… # user runs this, once
```

Emulator mode (`--dart-define=USE_EMULATOR=true`) now only emulates Firebase
Auth; hosted Supabase rejects emulator tokens, so it shows no data until a
local Supabase setup exists. VS Code launch configs: Dev, Dev (emulators), Prod.

---

## 8. Project state

**Supabase** `unvpyjnotaukdxgmpytr`: CLI logged in and linked.
Migrations up to `20261020090000` are applied;
`20261027090000_receipt_date.sql` is waiting for `db push` — check with
`npx supabase migration list`. The user must also enable **Authentication →
Third-party Auth → Firebase** (project id `busineedger-ab7a1`).

**Firebase** `busineedger-ab7a1`: iOS app `com.iocod.businessLedger` and
Android app `com.iocod.business_ledger` registered; config files generated;
Google sign-in enabled; iOS URL scheme set; this Mac's debug SHA-1/SHA-256 on
the Android app. Firestore and Storage are **not** used (no database created —
"Firestore NOT_FOUND" logs come only from old builds). Apple sign-in still
needs the Firebase provider + Apple Developer capability + Xcode team.
Release/Play signing will need its own SHA fingerprints. Android release
builds sign with `android/key.properties` (not in git: storeFile relative
to `android/app`, storePassword, keyAlias, keyPassword); without it they use
the debug key, which Play rejects.

**Gotchas**
- Re-running `flutterfire configure` brings back its Crashlytics
  "upload symbols" build phase, which breaks debug builds. Re-apply the guard
  in `ios/Runner.xcodeproj/project.pbxproj` (Release only, never fail), copy
  the dev options over prod, re-indent `firebase.json`. It may also put back
  old Gradle plugin versions in `android/settings.gradle.kts`: Crashlytics
  below 3.x fails release builds on Gradle 9 (`groovy/util/XmlSlurper` in
  `uploadCrashlyticsMappingFileRelease`); keep Crashlytics 3.0.8 and
  google-services 4.5.0 or newer.
- iOS Google Sign-In crashes natively without a client id + URL scheme;
  `AuthService` refuses with a message instead.
- "No AppCheckProvider installed" in logs is a harmless warning.
- Debug launch stuck on a black screen at "Waiting for VM Service port"
  (seen on a vivo phone, which drops app log lines above 50/s, sometimes
  the VM service's "listening" line): stop it, open the app, run the VS Code
  config "Attach (if launch is stuck)". Android debug builds serve the VM
  service at a fixed `http://127.0.0.1:43210/` without auth code
  (`android/app/src/debug/AndroidManifest.xml`).
- iOS simulator builds may fail inside a sandbox on the SwiftPM cache; build
  outside it.
- A receipt that scans wrongly: debug builds keep the last scan's OCR lines
  (text and boxes, no image) in the cache. Pull them with
  `adb exec-out run-as com.iocod.business_ledger cat cache/last_scan_ocr.json`,
  redact the buyer, add them under `test/fixtures/receipts/` and replay them in
  `receipt_real_receipt_test.dart`.

---

## 9. What's next

Supabase migration:
- **Phase A** ✅ database (`supabase/`), committed.
- **Phase B** ✅ app on drift + Supabase (pending commit). Adds migration
  `20261020090000_project_description.sql`.
- **Live checks** after the user applies migrations and enables Firebase
  third-party auth: first sign-in upserts `profiles`; `create_business` works
  and the pull brings the business; draft → confirm → settle balances;
  `PTnnn` errors arrive with JSON `details`; a role-less Firebase token runs
  as `anon`.
- **Phase C** — remove `functions/`, `firestore.rules`, `firestore.indexes.json`,
  emulator tests and CI jobs; update docs.
- **Phase D** — push notifications: FCM tokens in Supabase, sent from a
  Supabase Edge Function; agree on events first.

Known gaps: no import of old Firestore data (none exists in production);
emulator mode shows no data; foreground polling ≈ 2 + 10 × businesses
requests/min (Realtime could replace it later).

Then: Stage 9 (polish, error handling, end-to-end tests) and Stage 10 (device
verification). Unpushed commits: `git log origin/main..main` — ask before pushing.
