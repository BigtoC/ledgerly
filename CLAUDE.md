# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

Ledgerly is a local-first Flutter expense tracker currently in **M0 scaffolding** on `feature/m0-scaffold-app`. The spec in [`PRD.md`](PRD.md) is the authoritative source of truth — read it before making any architectural or data-model decision. Earlier design thinking lives in `docs/superpowers/specs/` but has been superseded by `PRD.md` wherever they conflict.

The repo now contains: `pubspec.yaml`, `analysis_options.yaml`, `l10n/` (`app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`), `lib/`, `test/`, `drift_schemas/`, and `.github/workflows/`. Match the folder layout and package list in `PRD.md` exactly when extending the scaffold — they encode decisions (layered folder split, `domain/` only in Phase 2, etc.) that are easy to get wrong by defaulting to a generic `flutter create` shape.

## Common Commands (after scaffold exists)

```bash
flutter pub get
flutter run                                           # run on attached device/emulator
flutter test                                          # all tests
flutter test test/unit/repositories/foo_test.dart    # single file
flutter test --name 'category type is locked'        # single test by name
dart run build_runner build --delete-conflicting-outputs   # Drift + Freezed + riverpod_generator
dart run build_runner watch --delete-conflicting-outputs   # code-gen while developing
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/   # snapshot schema
flutter analyze                                      # runs custom_lint + import_lint + riverpod_lint
dart format .
```

Code generation is required whenever a `@freezed`, `@riverpod`, or Drift `@DriftDatabase`/`@DataClassName` annotation changes — the build will fail loudly if generated files are stale.

## Architecture — Non-Negotiables

Ledgerly uses a strict **3-layer architecture** (Data → UI; plus a `domain/` use-case layer in Phase 2 only). See `PRD.md` → *Architecture* for the full rule table. The rules that trip up generic Flutter code:

- **SSOT on repositories.** Only `data/repositories/*` write to Drift or `flutter_secure_storage`. Controllers and widgets never construct Drift `Insertable` rows, never call DAO `.insert()`, never touch secure storage. Layer-boundary rules are declared in `import_analysis_options.yaml` at the repo root (the pinned `import_lint ^0.1.6` only reads from that filename, not from `analysis_options.yaml`); enforcement is best-effort under that pin (see *Dependency Pins* below), so reviewer discipline matters more than the linter here.
- **Drift stays inside repositories.** Repositories map Drift data classes into Freezed domain models in `data/models/` and return those. Controllers and widgets must never see a Drift row type — that is the seam that protects the UI from schema churn.
- **Controllers expose state + commands, not data access.** Each `*_controller.dart` owns an immutable Freezed sealed state (`loading | empty | data(...) | error`) and typed command methods. Widgets read state and call commands; no data transformation in `build()`.
- **Reactive by default.** Repositories return `Stream<T>` backed by Drift `.watch()`; controllers consume via Riverpod `StreamNotifier` / `AsyncNotifier`. Avoid manual refresh patterns.
- **Error propagation is typed.** Services throw typed exceptions, repositories re-throw or wrap, use cases translate to domain failures, controllers expose `AsyncValue`. No `try/catch` in widgets. No unhandled `Future`.

## Data-Model Invariants

These are easy to violate and expensive to retrofit:

- **Money is stored as integer minor units.** `amount_minor_units`, `opening_balance_minor_units`, etc. — never doubles. The scaling factor comes from `currencies.decimals` (2 for USD, 0 for JPY, 18 for ETH). All decimal formatting goes through `core/utils/money_formatter.dart` at the UI boundary only. Phase 2 exchange rates are stored as `numerator/denominator` integer fractions for the same reason.
- **Category `type` is immutable after first use.** Once a transaction references a category, its `type` (expense/income) is frozen — users needing the opposite type create a new category. Enforce this in `CategoryRepository`, not in the UI.
- **Seeded categories are identified by `l10n_key`, not by display name.** Renames write `custom_name` but keep `l10n_key` so locale changes do not duplicate or orphan rows. Users can rename any seeded category; auto-translation is not applied after a rename.
- **Archive-instead-of-delete** for any category or account that has transactions. Hard-delete is only allowed for unused custom rows.
- **Icons and colors are indirect.** `categories.icon` is a string key resolved via `core/utils/icon_registry.dart`; `categories.color` is an **index** into the append-only `core/utils/color_palette.dart`. Never store raw `IconData` symbols or ARGB ints in the DB — both break across Flutter/Material updates and across backup/restore.
- **Phase 2 `pending_transactions` is a universal staging table** for both blockchain and recurring sources, discriminated by `source`. Shared columns are always populated; source-specific columns (e.g. `tx_hash`, `recurring_rule_id`) are nullable. Approve = insert into `transactions` + delete from `pending_transactions`, preserving the original `currency` and `amount_minor_units`.

## Layout Primitives (required widget shapes)

`PRD.md` → *Layout Primitives* specifies the widget tree for screens with known unbounded-constraint or keyboard hazards. Follow them:

- **Home:** `CustomScrollView` with `SliverToBoxAdapter` (summary strip) + `SliverList` (days). Never nest `ListView` in `Column`.
- **Add/Edit Transaction:** `Scaffold(resizeToAvoidBottomInset: false)` → `SafeArea` → `Column` with scrollable form `Expanded` above a fixed-height `CalculatorKeypad`. The keypad must not be covered by the soft keyboard.
- **Category picker:** `ModalBottomSheet` → `CustomScrollView` with `SliverGrid` + `SliverList`.
- All scrollable regions must survive **2× text scale**; fixed-height widgets (keypad, splash day counter) clamp at 1.5× or reflow.

Adaptive breakpoint is a single threshold at **600dp**, switched at the shell level via `LayoutBuilder` (bottom nav → `NavigationRail`, modal → constrained dialog).

## First-Run & Bootstrap

`app/bootstrap.dart` runs the ordered async init before `runApp`. The sequence (open DB → init locale → read prefs → seed-if-empty → build `ProviderScope` with overrides) is specified in `PRD.md` → *Bootstrap Sequence* and must be preserved: the first-run seed (currencies, default categories, one `Cash` account, `default_currency` from device locale) runs only when the DB is empty, and the `appDatabaseProvider` is injected via override rather than constructed inside the provider.

Root route uses a `go_router` `redirect:` that reads `splash_enabled` from `user_preferences` — there is no splash route visited when it is disabled.

## Testing

Tests are organized **by architectural layer, not by feature** (`test/unit/{services,repositories,use_cases,controllers,utils}`, `test/widget/`, `test/integration/`). Repository tests use Drift's in-memory database; controller tests use Riverpod `ProviderContainer` overrides with `mocktail`; the splash screen has golden tests because its visual design is a product requirement. Migration tests run `onUpgrade` against every committed snapshot in `drift_schemas/` on both empty and seeded DBs — never rewrite a merged migration in place; add a new schema version instead.

Ankr API calls are mocked in every test; no live network calls in the suite.

## Dependency Pins

Tested versions live in `pubspec.yaml` and in `PRD.md` → *Dependencies*. Two non-obvious pins to preserve when bumping:

- **`import_lint: ^0.1.6`** — the 2.x line pulls `analyzer ^12.1.0` → `meta ^1.18.0`, but Flutter 3.41.7 pins `meta 1.17.0`. The 0.9.x–1.0.x band needs `analyzer ^5.2.0`, which conflicts with `freezed >=2.5.3`. Only `^0.1.6` resolves under the current SDK. Revisit when Flutter ships `meta 1.18+`. **Config-file quirk:** 0.1.6 reads rules from `import_analysis_options.yaml` at the repo root and uses a regex schema (`search_file_path_reg_exp`, `not_allow_import_reg_exps`). An `import_lint:` block inside `analysis_options.yaml` is silently ignored, and the glob-based `target_file_path`/`not_allow_imports` keys belong to 2.x — do not port them back.
- **Chinese ARBs require a base `app_zh.arb`.** `flutter_localizations` fails codegen with "Arb file for a fallback, zh, does not exist" when only `app_zh_CN.arb` / `app_zh_TW.arb` are present. Keep `app_zh.arb` in `l10n/` even if it only contains `appTitle` — removing it breaks `flutter pub get`.

## Pagination Cap

MVP renders up to **10,000 transactions** via Drift streams + `ListView.builder` / slivers. This is a documented, accepted limit — don't preemptively add pagination in MVP, but don't claim the app scales past it either. Cursor pagination lands in Phase 2 (`TransactionRepository.watchPage`).

## Skills Available

Two Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.

When the user asks to structure a new feature, invoke `flutter-architecting-apps`; when building or refining UI, invoke `flutter-building-layouts`.

## Security & Secrets

MVP ships with **no secrets** — everything is local. Phase 2 introduces the Ankr API key, which must flow through `SecureStorageService` → `ApiKeyRepository`; nothing else may read or write it. Phase 2 currency-price requests send only currency pairs and conversion metadata — never memos, categories, or any other transaction text. Financial data must never be written to logs.

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

- `docs/solutions/` — documented solved problems (bug fixes, best practices, workflow patterns), organized by category
- `/ce:plan` auto-searches `docs/solutions/` at planning time to surface relevant prior solutions before implementation begins
- Each solution document includes: problem description, root cause, fix applied, and tags for search

When to invoke `/ce:compound`:
- After a tricky bug is fixed (especially build/CI failures, async issues, borrow-checker patterns)
- After establishing a new architectural pattern or workflow convention
- After integrating a new dependency or provider that required non-obvious configuration
