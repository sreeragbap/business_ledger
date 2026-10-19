# Business Ledger

A multi-business, customizable digital ledger. One user can run several
businesses, each with its own currency, categories, custom fields, parties,
projects, members and roles. Transactions move from offline-friendly drafts to
server-confirmed entries with payments, refunds, credits, and gap-free
invoice/bill/receipt numbers.

- **App:** Flutter (Android + iOS), bloc, get_it/injectable, auto_route
- **Backend:** Firebase Auth, Cloud Firestore, Cloud Functions (TypeScript). Text only: no file storage; documents are rendered on device.
- **Money:** integer minor units only; the ledger rules are implemented twice
  (Dart and TypeScript) and checked against one shared fixture file

Design and rules: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ·
Callable API: [docs/FUNCTIONS_API.md](docs/FUNCTIONS_API.md) ·
Build status: [docs/PROGRESS.md](docs/PROGRESS.md)

## Repository layout

```
lib/
  app/                 flavors, AppConfig, Firebase options per flavor
  core/                money, ledger rules, DI, router, theme, shared widgets
  features/<name>/     domain / logic / screens / widgets per feature
  main_dev.dart        dev entrypoint
  main_prod.dart       prod entrypoint
test/                  Dart tests (bloc_test, mocktail)
functions/             Cloud Functions (TypeScript, Node 22)
  src/                 handlers, ledger.ts (mirror of lib/core/ledger), schemas
  test/unit/           ledger fixture tests (no emulator)
  test/rules/          Firestore rules tests (emulator)
  test/integration/    callable integration tests (emulator)
shared/
  ledger_cases.json    ledger fixtures used by BOTH Dart and TypeScript tests
firestore.rules, firestore.indexes.json, firebase.json
docs/                  architecture, functions contract, progress
```

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.44 (Dart 3.12) |
| Node.js | 22 |
| Firebase CLI | `npm i -g firebase-tools` |
| Java | 21 (needed by the Firestore emulator) |

## Setup

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # json / injectable / auto_route code
cd functions && npm ci
```

`lib/app/firebase_options_dev.dart` and `firebase_options_prod.dart` are
placeholders until `flutterfire configure` is run against `busineedger-ab7a1`
(the command is in each file's header). Until then the app throws at startup
with that instruction.

## Running the app

There is no default entrypoint; pick a flavor:

```sh
flutter run -t lib/main_dev.dart
flutter run -t lib/main_prod.dart

# Dev flavor against the local emulators
flutter run -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
# Physical device: point it at your machine's LAN address
flutter run -t lib/main_dev.dart --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.x.y
```

Start the emulators (builds functions first, project `demo-business-ledger`,
UI on http://localhost:4000):

```sh
cd functions && npm run serve
```

## Tests

```sh
# Dart
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

# Cloud Functions
cd functions
npm run lint            # tsc --noEmit
npm test                # unit tests incl. shared ledger fixtures
npm run test:emulator   # rules + integration tests; needs Firebase CLI and Java
```

CI runs the same commands (`.github/workflows/`).

## Deploying

Requires the **Blaze plan** and the **Cloud Firestore API** enabled on the
Firebase project `busineedger-ab7a1` (default in `.firebaserc`).

```sh
firebase login
firebase deploy --only firestore:rules,firestore:indexes           # rules + indexes
firebase deploy --only functions                                    # builds via predeploy
```

Functions deploy to region `asia-south1`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
