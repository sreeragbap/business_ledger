# Contributing

## Branches

Branch from `main`, open a PR back into `main`:

- `feat/<short-topic>` — new behaviour
- `fix/<short-topic>` — bug fixes
- `chore/<short-topic>` — tooling, deps, CI
- `docs/<short-topic>` — documentation only

## Commits

Conventional-ish, imperative, present tense:

```
feat(transactions): confirm with immediate settlement
fix(rules): reject drafts that set paidMinor
chore(ci): cache firebase emulators
```

Scope is the feature or area (`ledger`, `functions`, `rules`, `ui`, …).
Keep commits focused; don't mix formatting churn with behaviour changes.

## Conventions

Code layout, layering, state and naming follow
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) (see its *Conventions* section).
In short: screens never touch Firestore, repositories return `AppResult<T>`
and never throw, and no money arithmetic happens outside `LedgerMath` /
`Money`.

## The ledger rule: change both sides

The financial rules exist twice — `lib/core/ledger` (Dart) and
`functions/src/ledger.ts` (TypeScript) — and must agree exactly. Any change to
them must:

1. update **both** implementations in the same PR,
2. add or update cases in `shared/ledger_cases.json`, which both
   `flutter test` and `cd functions && npm test` run against,
3. run `npm run test:emulator` if `firestore.rules` changed.

## Before opening a PR

```sh
dart format lib test && flutter analyze && flutter test
cd functions && npm run lint && npm test
```

CI runs these on every PR; keep it green.
