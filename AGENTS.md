# AGENTS.md
## Source precedence
- Read `PRD.md` first. It is the authoritative source for architecture, schema, routing, layout primitives, bootstrap order, and dependency choices.
- `CLAUDE.md` captures agent-facing repo rules and current status; use it as the quick summary.
- `README.md` is useful for day-to-day commands and CI expectations, but some status/setup notes lag the committed scaffold; trust the checked-in tree when they differ.
- `docs/superpowers/specs/2026-04-14-ledgerly-design.md` is historical context only. If it conflicts with `PRD.md`, follow `PRD.md`.
## Current repo state
- This repository is now in **M0 scaffolding**: `pubspec.yaml`, `analysis_options.yaml`, `l10n/`, `lib/`, `test/`, `drift_schemas/`, `.github/workflows/`, and native platform folders are all present in the workspace.
- The current runtime is still a placeholder shell: `lib/app/bootstrap.dart` only does `WidgetsFlutterBinding.ensureInitialized()` + `runApp(const App())`, `lib/app/app.dart` renders a bare `MaterialApp`, and most files under `lib/data/` / `lib/features/` are milestone-tagged TODO stubs.
- When extending the scaffold, match the folder layout and package list in `PRD.md` exactly; do not default to a generic `flutter create` structure.
- In particular, `domain/` exists only in **Phase 2**. MVP is primarily `app/`, `core/`, `data/`, and `features/`.
## Architecture rules to preserve
- Ledgerly uses a strict 3-layer flow: **Data → UI**, with `domain/` use cases added only for Phase 2 orchestration.
- Only `data/repositories/*` may write to Drift or `flutter_secure_storage`. Controllers/widgets must not call DAOs, build Drift `Insertable`s, or touch secure storage.
- Drift data classes stay inside repositories; repositories map them into Freezed domain models in `data/models/` before returning anything upstream.
- Each `features/*/*_controller.dart` exposes immutable state + typed commands. Widgets render state and call commands; they do not aggregate, format, or group data in `build()`.
- Reactive updates are the default: repositories expose Drift-backed `Stream<T>`; controllers consume with Riverpod `StreamNotifier` / `AsyncNotifier`.
## Data-model invariants
- Money is always stored as integer minor units (`amount_minor_units`, `opening_balance_minor_units`, etc.). Never use doubles for persisted money.
- Currency scaling comes from `currencies.decimals`; formatting happens only at the UI boundary via `core/utils/money_formatter.dart`.
- Category `type` becomes immutable after first use; enforce this in `CategoryRepository`, not in the UI.
- Seeded categories are identified by `l10n_key`; user renames go into `custom_name` without changing the key.
- Used categories/accounts are archived instead of deleted. Hard-delete is only for unused custom rows.
- Category icons/colors are indirect: `categories.icon` is a key for `core/utils/icon_registry.dart`; `categories.color` is an index into append-only `core/utils/color_palette.dart`.
- Phase 2 keeps all auto-generated items in `pending_transactions`; approve means insert into `transactions` and delete the pending row while preserving original currency and minor units.
## UI, routing, and layout constraints
- Preserve the bootstrap order from `PRD.md`: open DB → init locale → read prefs → seed if empty → inject `appDatabaseProvider` override → `runApp`.
- Root routing uses a `go_router` `redirect:` that reads `splash_enabled`; when disabled, the app should not visit a splash route at all.
- At M0 these are not wired into the runtime yet: `lib/app/router.dart` is still a TODO stub and `App` boots a plain `MaterialApp`. Follow `PRD.md` when implementing, but do not assume the route tree or shell primitives already exist in code.
- Required layout primitives from `PRD.md`: Home uses `CustomScrollView` + slivers; Add/Edit Transaction uses `Scaffold(resizeToAvoidBottomInset: false)` with a fixed bottom keypad; Category picker uses a `ModalBottomSheet` with `CustomScrollView`, `SliverGrid`, and `SliverList`.
- The only adaptive breakpoint is **600dp** at the shell level (`BottomNavigationBar` → `NavigationRail`, modal → constrained dialog/side sheet).
## Commands and workflows
- `flutter pub get`
- `flutter run`
- `flutter analyze` (currently clean; runs analyzer + `custom_lint` / `riverpod_lint`)
- `dart run import_lint` is referenced in `README.md` and `.github/workflows/ci.yml`, but the current repo has no root `import_analysis_options.yaml`, so that command fails locally as-is.
- `dart run build_runner build --delete-conflicting-outputs`
- `dart run build_runner watch --delete-conflicting-outputs`
- `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
- `flutter test` / `flutter test test/widget/smoke_test.dart` / `flutter test --name 'M0 smoke'`
- `dart format .`
- `.github/workflows/ci.yml` currently runs package resolution → `dart run import_lint` → codegen → format check → `flutter analyze` → `flutter test` → Android debug build on pushes/PRs to `main`.
- `.github/workflows/ios-nightly.yml` is currently a manual `workflow_dispatch` iOS debug build (`flutter build ios --no-codesign --debug`), not a scheduled nightly job.
- Regenerate code whenever a `@freezed`, `@riverpod`, or Drift database/table annotation changes.
## Testing expectations
- Current M0 reality: `test/widget/smoke_test.dart` is the only passing meaningful test, `test/unit/repositories/migration_test.dart` is a skipped harness stub, and `test/widget_test.dart` is still the default Flutter counter template and currently fails against `App`.
- When adding coverage now, replace or remove `test/widget_test.dart` instead of extending it; use `test/widget/smoke_test.dart` as the pattern for boot-through-`main()` tests.
- Tests are organized by layer, not feature: `test/unit/{services,repositories,use_cases,controllers,utils}`, then `test/widget/`, then `test/integration/`.
- Repository tests use Drift in-memory DBs and should assert rules like category type locking, archive-instead-of-delete, FK integrity, and reactive stream emissions.
- Controller tests use Riverpod `ProviderContainer` overrides with `mocktail`.
- Splash screen visuals require golden tests.
- Migration tests run against every committed snapshot in `drift_schemas/`; never rewrite an existing migration in place.
- Ankr API calls are always mocked in tests; no live network calls in the suite.
## Security and agent hints
- MVP is fully local-first and currently has no secrets.
- In Phase 2, the Ankr API key must flow only through `data/services/secure_storage_service.dart` → `data/repositories/api_key_repository.dart`.
- Do not log financial data (transactions, memos, balances, wallet data).
- If asked to structure a new feature, consult `.claude/skills/flutter-architecting-apps/SKILL.md`; for UI/layout work, consult `.claude/skills/flutter-building-layouts/SKILL.md`.

## Skills Available

Two Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.

When the user asks to structure a new feature, invoke `flutter-architecting-apps`; when building or refining UI, invoke `flutter-building-layouts`.

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

- `docs/solutions/` is not present in the current scaffold; create it alongside the first consolidated solution doc if you need to persist a non-trivial fix.
- Keep future solution docs under `docs/solutions/` so planning/review workflows have a stable place to search.
- Each solution document includes: problem description, root cause, fix applied, and tags for search

When to invoke `/ce:compound`:
- After a tricky bug is fixed (especially build/CI failures, async issues, borrow-checker patterns)
- After establishing a new architectural pattern or workflow convention
- After integrating a new dependency or provider that required non-obvious configuration
