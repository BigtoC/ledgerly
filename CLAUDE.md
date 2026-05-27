# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Project Status

Ledgerly is a local-first Flutter expense tracker. **MVP is complete** and several Phase 2 slices have shipped on `main`: recurring transactions + pending approval on Home (2026-05-08), transaction search (2026-05-10), extended multi-currency conversion (2026-05-17), basic charts — pie + daily bar with animations and interactive selection (2026-05-20), and chart slice drill-down (2026-05-22). The active branch `feature/default-splash-page-display` (2026-05-23) reworks the splash display text: the default template is now `'On {date} start using Ledgerly'`, the `{date}` substitution renders inline with the rainbow gradient (the standalone gradient-date widget has been removed so the date never appears twice), and `SplashController._resolveTemplate` auto-prepends `{date} ` to any user-entered template that lacks it so the start date is always visible. `DateHelpers.applySplashTemplateSegments` returns `List<SplashTextSegment>` so the widget can style date spans independently from surrounding plain text. Selection on the chart drill-down is hoisted into a typed `SelectedSlice` (sealed: category | account | currency) on `ChartsSelectionController`; the data layer stays filter-based — `ChartsController` translates the active selection into plain `{categoryId, accountId, currencyCode}` filters before calling the repository. Drift schema is at **v5** (`exchange_rates` table added in v5; `recurring_rules` + `pending_transactions` were introduced in v4); snapshots live in `drift_schemas/`. Neither the drill-down nor the splash-text slice changed the schema. Wave planning for the M5 slice set lives in [`docs/plans/m5-ui-feature-slices/`](docs/plans/m5-ui-feature-slices/); newer Phase 2 plans live in [`docs/superpowers/plans/`](docs/superpowers/plans/). The spec in [`PRD.md`](PRD.md) is the authoritative source of truth — read it before making any architectural or data-model decision. Earlier design thinking lives in `docs/superpowers/specs/` but has been superseded by `PRD.md` wherever they conflict.

The repo contains: `pubspec.yaml`, `analysis_options.yaml`, `import_analysis_options.yaml`, `l10n/` (`app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`), `lib/`, `test/`, `drift_schemas/`, `docs/`, and `.github/workflows/`. Match the folder layout and package list in `PRD.md` exactly when extending the scaffold — they encode decisions (layered folder split, `domain/` only in Phase 2, etc.) that are easy to get wrong by defaulting to a generic `flutter create` shape.

## Common Commands (after scaffold exists)

```bash
flutter pub get
flutter run                                           # run on attached device/emulator
dart format .                                        # run before test or analyze
flutter test                                          # all tests
flutter test test/unit/repositories/foo_test.dart    # single file
flutter test --name 'category type is locked'        # single test by name
dart run build_runner build --delete-conflicting-outputs   # Drift + Freezed + riverpod_generator
dart run build_runner watch --delete-conflicting-outputs   # code-gen while developing
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/   # snapshot schema
flutter analyze                                      # runs custom_lint + import_lint + riverpod_lint
```

When verifying changes, run `dart format .` before any `flutter test` or `flutter analyze` command.

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

- **Money is stored as integer minor units.** `amount_minor_units`, `opening_balance_minor_units`, etc. — never doubles. The scaling factor comes from `currencies.decimals` (2 for USD, 0 for JPY, 18 for ETH). All decimal formatting goes through `core/utils/money_formatter.dart` at the UI boundary only. `exchange_rates` rows (shipped in v5) store rates as `numerator/denominator` integer fractions for the same reason.
- **Category `type` is immutable after first use.** Once a transaction references a category, its `type` (expense/income) is frozen — users needing the opposite type create a new category. Enforce this in `CategoryRepository`, not in the UI.
- **Seeded categories are identified by `l10n_key`, not by display name.** Renames write `custom_name` but keep `l10n_key` so locale changes do not duplicate or orphan rows. Users can rename any seeded category; auto-translation is not applied after a rename.
- **Archive-instead-of-delete** for any category or account that has transactions. Hard-delete is only allowed for unused custom rows.
- **Icons and colors are indirect.** `categories.icon` is a string key resolved via `core/utils/icon_registry.dart`; `categories.color` is an **index** into the append-only `core/utils/color_palette.dart`. Never store raw `IconData` symbols or ARGB ints in the DB — both break across Flutter/Material updates and across backup/restore.
- **`pending_transactions` is a universal staging table** for both blockchain and recurring sources, discriminated by `source`. Shared columns are always populated; source-specific columns (e.g. `tx_hash`, `recurring_rule_id`) are nullable. The `recurring` source shipped 2026-05-08 via `RecurringGenerationUseCase` (cold-start generation) + `PendingSection` on Home (inline approve/skip-once); the `blockchain` source is still Phase 3 / pending. Approve = insert into `transactions` + delete from `pending_transactions` atomically, preserving the original `currency` and `amount_minor_units`. Skip rejects ONE occurrence (4-second undo window via `kUndoWindow`); the parent `recurring_rules` row is untouched.

## Layout Primitives (required widget shapes)

`PRD.md` → *Layout Primitives* specifies the widget tree for screens with known unbounded-constraint or keyboard hazards. Follow them:

- **Home:** `CustomScrollView` with `SliverToBoxAdapter` (summary strip) + `SliverToBoxAdapter` (day-nav header with prev/next) + `PendingSection` sliver (auto-hides when no pending rows; cap at 5 visible tiles, rest behind "Show N more") + `SliverList` (selected day's transaction rows). Home shows one day at a time — there is no combined infinite day-list. Never nest `ListView` in `Column`.
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

Three Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.
- `flutter-animating-apps` — animation / transition guidance for feature polish work.

When the user asks to structure a new feature, invoke `flutter-architecting-apps`; when building or refining UI, invoke `flutter-building-layouts`; when adding transitions or motion, invoke `flutter-animating-apps`.

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
