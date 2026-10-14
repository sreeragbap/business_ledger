# Build progress / handoff

Spec: the original project brief (12 sections). Design: [ARCHITECTURE.md](ARCHITECTURE.md).
Reference conventions: `/Users/sreeragkm/Documents/projects/easify_crm_flutter`
(read its `README.md`, `docs/DEVELOPER_GUIDE.md`, `docs/TEAM_ONBOARDING.md`,
`examples/login_feature/`).

## Decisions made with the user

- App lives here: `/Users/sreeragkm/Documents/sreeragkm/business_ledger`
  (package `business_ledger`, bundle prefix `com.iocod`).
- Firebase project: `busineedger-ab7a1` ("businessledger"), reachable with the
  CLI account `sreeragk136@gmail.com` (`--account sreeragk136@gmail.com`).
  No apps registered yet. **Cloud Firestore API is not enabled yet**, and
  Functions need the Blaze plan: both are console steps for the user.
  Until then everything is verified against the emulators.
- Sign-in: Google + Apple (social), plus biometric app lock (local_auth).
- Pacing: continue through stages, verify each with analyze + tests.

## Reference conventions (summary)

- Feature folders `features/<f>/{domain/{const,models,repository,services},logic,screens,widgets,index.dart}`.
- `XRepository` = abstract contract; `XService` = `@LazySingleton(as: XRepository)` impl.
- Results: sealed `AppResult<T>` (`Success`/`Failure(AppException)`) — never throw.
- Blocs/Cubits `@injectable`, provided per route via `AutoRouteWrapper` + `getIt`.
- State: hand-written Equatable + `copyWith`, one `Status` per operation
  (copy `core/bloc/status.dart` from the reference). No freezed.
- Models: json_serializable + Equatable. Enums: enhanced, with `key` + `label` + `fromKey`.
- Tokens: `abstract final class AppColors/AppSpacing/AppRadius/AppTextStyles`,
  flutter_screenutil `.w/.h/.r/.sp`, design size 393x852.
- `main_dev.dart` / `main_prod.dart` → `bootstrap(Flavor)`; `main.dart` throws.
- `package:` imports only; barrels `index.dart` with relative exports.
- Tests: bloc_test + hand-written stub repositories; mocktail where simpler.

## Stages

1. [x] Inspect reference project
2. [x] Architecture + Firestore model (ARCHITECTURE.md)
3. [x] Ledger rules: `lib/core/money`, `lib/core/ledger`, `shared/ledger_cases.json`,
       tests in `test/core` (45 passing)
4. [x] Cloud Functions (`functions/`): `ledger.ts` mirror (41 fixture tests shared with
       Dart, incl. search tokens), roles, idempotency (`requests/{uid_requestId}`),
       stats deltas, all handlers, Firestore/Storage rules, indexes, firebase.json.
       `npm test` (unit) and `npm run test:emulator` (26 rules + integration tests:
       isolation, concurrency, duplicates, refunds, cancel/void, numbering) pass.
       Callable contract: [FUNCTIONS_API.md](FUNCTIONS_API.md).
5. [x] Flutter core: bootstrap/flavors (Dart-only, `-t lib/main_dev.dart`), emulator
       switch (`--dart-define=USE_EMULATOR=true`), DI module, auto_route + AuthGuard,
       dark theme tokens (AA contrast tested), App* widgets, AppResult/AppException
       (maps functions `details.reason/violation/field`), CallableClient (offline-guarded),
       SearchTokens (shared fixtures), Google/Apple auth, biometric app lock.
       137 Dart tests pass, analyze clean. Firebase options are placeholders until
       `flutterfire configure` (stage 10); iOS needs REVERSED_CLIENT_ID URL scheme,
       Android needs SHA fingerprints, Apple sign-in capability + provider enabled.
6. [ ] Businesses (create/switch/settings/members), categories, fields, parties, projects
7. [ ] Transactions: drafts (offline), confirm, edit, cancel, search/filter
8. [ ] Payments/refunds/credits, dashboard & reports, PDF documents
9. [ ] UI polish + animations, tests, error handling
10. [ ] `flutterfire configure` against busineedger-ab7a1, device verification
