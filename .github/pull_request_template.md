## Summary

<!-- What does this change and why? -->

## Stage

<!-- Which stage in docs/PROGRESS.md does this belong to? e.g. "6 — Businesses" -->

## Checklist

- [ ] `flutter analyze` is clean and `dart format lib test` leaves no changes
- [ ] `flutter test` passes
- [ ] `cd functions && npm run lint && npm test` passes (if `functions/` changed)
- [ ] `cd functions && npm run test:emulator` passes (if `firestore.rules`, `storage.rules` or functions changed)
- [ ] Ledger rules changed? Both sides updated — `lib/core/ledger` **and** `functions/src/ledger.ts` — and `shared/ledger_cases.json` extended so both test suites cover it
- [ ] Docs updated where behaviour changed (`docs/ARCHITECTURE.md`, `docs/FUNCTIONS_API.md`, `docs/PROGRESS.md`)
