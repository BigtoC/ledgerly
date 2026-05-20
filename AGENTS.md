# AGENTS.md
## Source precedence
- Read `PRD.md` first. It is the authoritative source for architecture, schema, routing, layout primitives, bootstrap order, and dependency choices.
- `CLAUDE.md` captures agent-facing repo rules and current status; use it as the quick summary.
- `README.md` is useful for day-to-day commands and CI expectations, but some status/setup notes lag the committed scaffold; trust the checked-in tree when they differ.
- `docs/superpowers/specs/2026-04-14-ledgerly-design.md` is historical context only. If it conflicts with `PRD.md`, follow `PRD.md`.
## Current repo state
- The full M5 UI slice set is on `main`: `lib/features/splash/`, `lib/features/categories/`, `lib/features/accounts/`, `lib/features/analysis/`, `lib/features/settings/`, `lib/features/transactions/`, `lib/features/shopping_list/`, `lib/features/home/`, and `lib/features/recurring/`. Drift schema is at v5 (`exchange_rates` was introduced in v5 after `recurring_rules` + `pending_transactions` in v4); snapshots are committed in `drift_schemas/drift_schema_v1.json`–`v5.json`.
- Inline approve/skip-once for pending recurring rows on Home is live: `lib/features/home/pending_state.dart`, `lib/features/home/pending_controller.dart`, and `lib/features/home/widgets/pending_section.dart` (mounted between the day-nav header and the day's transaction list). `PendingTransactionRepository` exposes `watchAll()` / `approve()` / `reject()`; approve runs in a Drift transaction (`save` + `rejectRow`), and `_rowsToDomain` filters out rows whose account or category is archived. Plan: `docs/superpowers/plans/2026-05-08-pending-approval-on-home.md`.
- Multi-currency conversion is also live: `lib/data/services/exchange_rate_service.dart` is the only HTTP client in the app, `lib/data/repositories/exchange_rate_repository.dart` owns the `exchange_rates` cache + refresh orchestration, and `lib/app/providers/repository_providers.dart` exposes `exchangeRateRepositoryProvider` / `exchangeRatesProvider` for UI consumers.
- The runtime is live: `lib/main.dart` awaits `bootstrap()`; `lib/app/bootstrap.dart` opens Drift, initializes `intl` date data, eagerly reads theme/locale/splash preferences, seeds first-run data before `runApp`, and schedules `RecurringGenerationUseCase.execute()` from the App's first-frame callback (failures are swallowed so startup is not blocked); `lib/app/app.dart` renders `MaterialApp.router` and eagerly reads `exchangeRateRepositoryProvider` so DAO/default-currency listeners start on first build; `lib/app/router.dart` wires `/splash`, `/splash/preview`, `/home`, `/home/add`, `/home/edit/:id`, `/home/shopping-list`, `/home/shopping-list/:itemId`, `/analysis`, `/analysis/search/:categoryId`, `/settings`, `/settings/about`, `/settings/categories`, `/settings/recurring`, `/settings/recurring/new`, `/settings/recurring/:id`, `/settings/manage-accounts/new`, and `/settings/manage-accounts/:id`. Account management opens from Settings via the `ManageAccountsTile` sheet/dialog flow. `lib/app/widgets/adaptive_shell.dart` owns the 600dp nav switch.
- When extending the scaffold, match the folder layout and package list in `PRD.md` exactly; do not default to a generic `flutter create` structure.
- In particular, `domain/` exists only in **Phase 2**. MVP is primarily `app/`, `core/`, `data/`, and `features/`. `lib/data/use_cases/recurring_generation_use_case.dart` is the one MVP exception — the recurring-rules generation engine — and it lives in `data/` because it orchestrates a single repository pair rather than crossing layered boundaries.
## Architecture rules to preserve
- Ledgerly uses a strict 3-layer flow: **Data → UI**, with `domain/` use cases added only for Phase 2 orchestration.
- Only `data/repositories/*` may write to Drift or `flutter_secure_storage`. Controllers/widgets must not call DAOs, build Drift `Insertable`s, or touch secure storage.
- Drift data classes stay inside repositories; repositories map them into Freezed domain models in `data/models/` before returning anything upstream.
- App-layer construction lives in providers: `lib/app/providers/repository_providers.dart` builds the concrete `Drift*Repository` implementations, and `appDatabaseProvider` is intentionally a required override from `bootstrap()` or `test/support/test_app.dart`.
- External I/O follows the same boundary: `lib/data/services/exchange_rate_service.dart` owns Dio calls, `lib/data/repositories/exchange_rate_repository.dart` owns `exchange_rates` persistence/refresh, and widgets/controllers should consume `exchangeRatesProvider` or repository commands instead of instantiating HTTP clients.
- Feature slices also co-locate read-only helper providers for view models and hydration seeds — see `lib/features/home/home_providers.dart`, `lib/features/accounts/accounts_providers.dart`, `lib/features/settings/settings_providers.dart`, and `lib/features/transactions/transactions_providers.dart`. Prefer those slice-local providers over reaching into DB internals from widgets.
- Each `features/*/*_controller.dart` exposes immutable state + typed commands. Widgets render state and call commands; they do not aggregate, format, or group data in `build()`.
- Reactive updates are the default: repositories expose Drift-backed `Stream<T>`; controllers consume with Riverpod `StreamNotifier` / `AsyncNotifier`.
## Data-model invariants
- Money is always stored as integer minor units (`amount_minor_units`, `opening_balance_minor_units`, etc.). Never use doubles for persisted money.
- Currency scaling comes from `currencies.decimals`; formatting happens only at the UI boundary via `core/utils/money_formatter.dart`.
- Category `type` becomes immutable after first use; enforce this in `CategoryRepository`, not in the UI.
- Seeded categories are identified by `l10n_key`; user renames go into `custom_name` without changing the key.
- Used categories/accounts are archived instead of deleted. Hard-delete is only for unused custom rows.
- Category icons/colors are indirect: `categories.icon` is a key for `core/utils/icon_registry.dart`; `categories.color` is an index into append-only `core/utils/color_palette.dart`.
- `pending_transactions` is a universal staging table discriminated by `source`. The `recurring` source is live in MVP — populated by `RecurringGenerationUseCase` on cold start, surfaced on Home via `PendingSection`, and approved/skipped inline. The `blockchain` source lands in Phase 2. Approve = insert into `transactions` + delete from `pending_transactions` atomically (`Drift.transaction { _txRepo.save() ; _dao.rejectRow() }`), preserving original currency and minor units. Skip rejects ONE occurrence — the parent `recurring_rules` row keeps generating.
- Exchange-rate cache rows are stored in `exchange_rates` as positive `rate_scaled_e9` integers (`round(rate × 10^9)`), keyed by `(base_currency, quote_currency)`. The table stores forward rates only (foreign → default); treat them as advisory display data, not persisted money values.
## UI, routing, and layout constraints
- Preserve the bootstrap order from `PRD.md`: open DB → init locale → read prefs → seed if empty → inject `appDatabaseProvider` override → `runApp`.
- Root routing is live in `lib/app/router.dart`: `routerProvider` builds a `GoRouter`, `SplashGateSnapshot` in `lib/app/providers/splash_redirect_provider.dart` bridges preference streams into the synchronous `redirect:`, and splash-disabled launches redirect straight to `/home` without constructing `SplashScreen`.
- The current reference UI slices are `lib/features/splash/`, `lib/features/categories/`, `lib/features/accounts/`, `lib/features/analysis/`, `lib/features/settings/`, `lib/features/transactions/`, `lib/features/shopping_list/`, `lib/features/home/`, and `lib/features/recurring/`. Use `transaction_form_screen.dart`, `home_screen.dart`, `account_form_screen.dart`, `recurring_rules_screen.dart`, and `widgets/category_picker.dart` as the live examples of the PRD layout primitives rather than older plan placeholders. `lib/features/home/widgets/pending_section.dart` is the canonical example of the delete-with-undo pattern for an in-page section (mirrors `recurring_rules_controller.dart`). The bottom-nav Analysis tab (`/analysis`) now hosts memo-based transaction search, and `lib/features/analysis/search/category_search_detail_screen.dart` is the reference route for `/analysis/search/:categoryId?q=...&c=...`; account management has moved to `lib/features/settings/widgets/manage_accounts_sheet.dart` and `manage_accounts_tile.dart`, opened from Settings via the ManageAccountsTile. Shopping-list routes are now under the Home branch (`/home/shopping-list`, `/home/shopping-list/:itemId`) and are accessed via the Home shopping-cart FAB; there is no longer a ShoppingListCard on the Analysis tab. Recurring-rules management lives at `/settings/recurring`, `/settings/recurring/new`, and `/settings/recurring/:id`, and tapping the version label at the bottom of `settings_screen.dart` opens `lib/features/settings/about_screen.dart` at `/settings/about`.
- Required layout primitives from `PRD.md`: Home uses `CustomScrollView` + slivers; Add/Edit Transaction uses `Scaffold(resizeToAvoidBottomInset: false)` with a fixed bottom keypad; Category picker uses a `ModalBottomSheet` with `CustomScrollView`, `SliverGrid`, and `SliverList`.
- The only adaptive breakpoint is **600dp**. `lib/app/widgets/adaptive_shell.dart` switches `NavigationBar` ↔ `NavigationRail`, `lib/app/router.dart` wraps `/home/add` + `/home/edit/:id` in `_AdaptiveTransactionFormRoute` so wide layouts render inside a constrained dialog, and `lib/features/categories/widgets/category_picker.dart` switches bottom sheet ↔ dialog at the same threshold.

## Commands and workflows
> When verifying changes, run `dart format .` before any `flutter test` or `flutter analyze` command.
- `flutter pub get`
- `flutter run`
- `dart format .` (run before `flutter test` or `flutter analyze` whenever verifying changes)
- `flutter analyze` (currently clean; runs analyzer + `custom_lint` / `riverpod_lint`)
- `dart run import_lint` (works locally; reads the regex rules in the root `import_analysis_options.yaml`)
- `dart run build_runner build --delete-conflicting-outputs`
- `dart run build_runner watch --delete-conflicting-outputs`
- `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
- `flutter test` / `flutter test test/widget/features/transactions/transaction_form_screen_test.dart` / `flutter test test/unit/app/router_test.dart` / `flutter test test/unit/repositories/migration_test.dart` / `flutter test test/integration/bootstrap_to_home_test.dart` / `flutter test test/integration/currency_conversion_flow_test.dart`
- If you touch `site/`, use `corepack enable` plus `yarn --cwd site install --immutable`, `yarn --cwd site test`, `yarn --cwd site check`, and `yarn --cwd site build`.
- `.github/workflows/ci.yml` currently runs package resolution → `dart run import_lint` → codegen → format check → `flutter analyze` → `flutter test`, then builds Android APKs on pushes/PRs to `main` (signed release if signing secrets are present, otherwise debug), passing `FOREX_API_URL` via `--dart-define`.
- `.github/workflows/android-release.yml` builds split signed release APKs on version tags, generates SHA-256 checksums, and uploads the APK assets to the GitHub Release.
- `.github/workflows/github-pages.yml` builds and deploys the Astro site from `site/`; `.github/workflows/site-check.yml` runs Yarn install/audit/test/check/build whenever site-related files change.
- `.github/workflows/ios-nightly.yml` is currently a manual `workflow_dispatch` iOS debug build (`flutter build ios --no-codesign --debug`), not a scheduled nightly job.
- Regenerate code whenever a `@freezed`, `@riverpod`, or Drift database/table annotation changes.
- l10n codegen is configured in `l10n.yaml`; generated output lands in `lib/l10n/`, and the fallback shim `l10n/app_zh.arb` must stay in the repo even though bare `zh` resolves to English at runtime.

## Testing expectations
- Current test coverage spans unit tests (`app`, `controllers`, `l10n`, `providers`, `repositories`, `seed`, `services`, `use_cases`, `utils`), widget tests (`app/`, `theme/`, `smoke/`, `features/*` including `analysis/`, `home/`, `transactions/`, `recurring/`, `accounts/`, `categories/`, `settings/`, `shopping_list/`, `splash/`), and integration (`bootstrap_to_home_test.dart`, `archive_flow_test.dart`, `currency_conversion_flow_test.dart`, `duplicate_flow_test.dart`, `edit_delete_flow_test.dart`, `first_launch_flow_test.dart`, `multi_currency_flow_test.dart`, `pending_approval_flow_test.dart`, `recurring_transaction_test.dart`, `shopping_list_path_test.dart`, `transaction_mutation_flow_test.dart`).
- Use `test/support/test_app.dart` as the canonical app-shell harness: `newTestAppDatabase()`, `runTestSeed(db)`, `makeTestContainer(...)`, `buildTestApp(...)`, and `buildBootstrappedTestApp(...)` cover the standard in-memory DB + ProviderScope setup patterns.
- Tests are organized by layer first: `test/unit/{app,controllers,l10n,providers,repositories,seed,services,use_cases,utils}`, then `test/widget/{app,features,smoke,theme}`, then `test/integration/`. `test/unit/use_cases/` covers the recurring-generation use case (the one MVP exception to the "domain/ is Phase 2 only" rule — see *Current repo state*).
- Drift-backed setup and direct repository writes that happen before the first `pump` must run inside `tester.runAsync(...)`; see `test/widget/smoke_test.dart` and `test/integration/bootstrap_to_home_test.dart` for the correct pattern.
- Repository tests use Drift in-memory DBs and should assert rules like category type locking, archive-instead-of-delete, FK integrity, and reactive stream emissions.
- Controller tests use Riverpod `ProviderContainer` overrides with `mocktail`.
- Splash widget coverage lives in `test/widget/features/splash/splash_screen_test.dart`; route-level splash redirect coverage lives in `test/unit/app/router_test.dart`.
- Conversion coverage lives in `test/unit/services/exchange_rate_service_test.dart`, `test/widget/features/home/summary_strip_conversion_test.dart`, `test/widget/features/home/transaction_tile_conversion_test.dart`, `test/widget/features/accounts/account_tile_conversion_test.dart`, and `test/integration/currency_conversion_flow_test.dart`; stub `ExchangeRateService` or override `exchangeRatesProvider` / `exchangeRateRepositoryProvider` rather than making live network calls.
- Migration tests are live in `test/unit/repositories/migration_test.dart` and currently validate the committed v1/v2/v3/v4/v5 generated schema helpers (`test/unit/repositories/_harness/generated/schema_v{1,2,3,4,5}.dart`), seeded and empty DB opens, and `PRAGMA foreign_keys` after upgrade. Snapshots `drift_schema_v1.json`–`v5.json` exist on disk; when adding schema v6, regenerate the v5 helper and extend the test. The v4 upgrade adds `recurring_rules`, `pending_transactions`, and the partial UNIQUE index `idx_pending_recurring_unique_partial` (declared imperatively because Drift cannot express the partial WHERE clause); the v5 upgrade adds `exchange_rates` plus the unique pair index `idx_exchange_rates_pair`.
- Ankr API calls are always mocked in tests; no live network calls in the suite.
## Security and agent hints
- MVP is fully local-first and currently has no secrets.
- In Phase 2, the Ankr API key must flow only through `data/services/secure_storage_service.dart` → `data/repositories/api_key_repository.dart`.
- Exchange-rate fetching uses `String.fromEnvironment('FOREX_API_URL')` in `lib/data/services/exchange_rate_service.dart`; pass it via `--dart-define` in app/build workflows instead of hardcoding URLs, and keep failure logs sanitized (exception type only, no transaction data or request payloads).
- Do not log financial data (transactions, memos, balances, wallet data).
- If asked to structure a new feature, consult `.claude/skills/flutter-architecting-apps/SKILL.md`; for UI/layout work, consult `.claude/skills/flutter-building-layouts/SKILL.md`; for motion/transition work, consult `.claude/skills/flutter-animating-apps/SKILL.md`.

## Skills Available

Three Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-animating-apps` — animation / transition guidance for feature polish work.
- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.

When the user asks to structure a new feature, invoke `flutter-architecting-apps`; when building or refining UI, invoke `flutter-building-layouts`; when adding motion or transitions, invoke `flutter-animating-apps`.

## Work Mode
> Based on the complexity of the tasks, choose the appropriate work mode

### Direct Execution Model (Default)

Trigger: bug fixes, small features, <30 line changes
Behavior: write code directly, do not invoke any skills

### Full Development Mode

Trigger: user explicitly says "full flow" or uses one of the `/full` command.
Behavior: follow this sequence strictly:
1. `/superpowers:brainstorming` — requirements exploration
2. `/ce:plan` — technical plan, auto-search `docs/solutions/`
3. `/superpowers:test-driven-development` — TDD implementation
4. `/ce:review` — multi-agent code review.
5. `/ce:compound` — knowledge consolidation

### Coding Mode

Trigger: User explicitly says "write code".
1. `/superpowers:test-driven-development` — TDD implementation
2. `/ce:review` — multi-agent code review.
3. `/ce:compound` — knowledge consolidation

## Knowledge Consolidation

After resolving a non-trivial problem, run `/ce:compound` to persist the solution for future reference.

- `docs/solutions/` is already present; keep future solution docs there (current subfolders include `database-issues/` and `logic-errors/`).
- Keep future solution docs under `docs/solutions/` so planning/review workflows have a stable place to search.
- `docs/solutions/` is a searchable prior-solutions store organized by category; solution docs use YAML frontmatter like `module`, `tags`, and `problem_type`, which is useful when implementing or debugging in documented areas.
- Each solution document includes: problem description, root cause, fix applied, and tags for search

When to invoke `/ce:compound`:
- After a tricky bug is fixed (especially build/CI failures, async issues, borrow-checker patterns)
- After establishing a new architectural pattern or workflow convention
- After integrating a new dependency or provider that required non-obvious configuration
