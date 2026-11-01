# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- Always use the `superpowers:test-driven-development` skill when writing code: write a failing test, watch it fail, then write the minimal code that makes it pass.

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

## Source precedence

- Read [`PRD.md`](PRD.md) first. It is the authoritative source for architecture, schema, routing, layout primitives, bootstrap order, and dependency choices.
- [`docs/architecture/`](docs/architecture/README.md) is the agent-facing summary of `PRD.md`, broken down by topic.
- `AGENTS.md` (this file) is the quick reference that links into the above. [`CLAUDE.md`](CLAUDE.md) only imports this file — edit guidance here, not there.
- [`README.md`](README.md) is useful for day-to-day commands and CI expectations, but some status/setup notes lag the committed scaffold; trust the checked-in tree when they differ.
- `docs/superpowers/specs/` (including `2026-04-14-ledgerly-design.md`) is historical design context only. If it conflicts with `PRD.md`, follow `PRD.md`.
- Wave planning for the M5 slice set lives in [`docs/plans/m5-ui-feature-slices/`](docs/plans/m5-ui-feature-slices/); newer Phase 2 plans live in [`docs/superpowers/plans/`](docs/superpowers/plans/).

## Project status

- **MVP is complete.** The Phase 2 slices shipped on `main` are: recurring transactions + Home pending approval, transaction search, multi-currency conversion (with `exchange_rates` cache + FX-converted display), basic charts (pie + daily bar) with slice drill-down, the splash display-text rework, Fortune City CSV import (`lib/features/settings/csv_import/`, `/settings/import`), and date-range CSV export (`lib/features/settings/csv_export/`, `/settings/export`); both live in Settings' Data Management section.
- **Drift schema is at v7** (v7 is data-only: it backfills the seeded `category.investment` expense row and retires `category.personal`, deleting it when unused and archiving it otherwise; v6 adds the nullable `transactions.amount_formula` column; `exchange_rates` was introduced in v5 after `recurring_rules` + `pending_transactions` in v4); snapshots are committed in `drift_schemas/drift_schema_v1.json`–`v7.json`.
- **Live feature slices:** `lib/features/splash/`, `lib/features/categories/`, `lib/features/accounts/`, `lib/features/analysis/`, `lib/features/settings/`, `lib/features/transactions/`, `lib/features/shopping_list/`, `lib/features/home/`, `lib/features/recurring/`.
- **Runtime entry:** `lib/main.dart` awaits `bootstrap()` in `lib/app/bootstrap.dart`; `lib/app/app.dart` renders `MaterialApp.router`; `lib/app/router.dart` wires the route table; `lib/app/widgets/adaptive_shell.dart` owns the 600dp nav switch. Full bootstrap flow: see [`docs/architecture/bootstrap.md`](docs/architecture/bootstrap.md).
- Remaining Phase 2 work: wallet sync (Ankr integration), credit-card / transfer flows.
- Top-level layout: `pubspec.yaml`, `analysis_options.yaml`, `import_analysis_options.yaml`, `l10n/` (`app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`), `lib/`, `test/`, `drift_schemas/`, `docs/`, `.github/workflows/`. Match the folder layout and package list in `PRD.md` when extending the scaffold — do not default to a generic `flutter create` shape.

## Commits and Pull Requests

Commits and PR titles follow **different** conventions on purpose: a commit subject names the change, a PR title names the problem that motivated it. Never use one form where the other belongs.

- **Commit messages follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):** `<type>[(scope)][!]: <description>`, then a blank line, the body, a blank line, and any footers.
  - **Types used here:** `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `build`, `perf`, `style`, `ci`.
  - **Scope** is a feature directory under `lib/features/` (`accounts`, `analysis`, `categories`, `home`, `recurring`, `settings`, `shopping-list`, `splash`, `transactions`) or a layer or area (`app`, `core`, `data`, `l10n`, `deps`, `test`). Separate scopes with a comma when a change really spans two, as in `refactor(home,data):`.
  - **Breaking changes** take `!` before the colon, a `BREAKING CHANGE:` footer, or both. That token is the one part of the format that must be uppercase.
  - **Footers are git trailers** (`Token: value`, with hyphens rather than spaces). The `Co-Authored-By:` trailer belongs there, after a blank line, never attached to the body.
- **PR titles start with `Problem`.** Write `Problem: <the problem>`, or `Problem(scope): <the problem>` when scoped. State what is wrong, not what you did. For example, `Problem: Forex rate is not fetched right after transaction saved`, not "fetch rate on save". The reviewer then reads the diff as an answer to a question rather than a claim to audit, and the merge commit records why the work happened. GitHub appends `(#NN)` itself, so do not add it.
- **Each commit should analyze and test on its own**, so a regression can be bisected. Split by concern, not by file count. If two files cannot compile apart, keep them in one commit and say so in the body rather than shipping a commit that does not build.

## Architecture

Detailed agent-facing rules live under [`docs/architecture/`](docs/architecture/README.md):

- [`layers.md`](docs/architecture/layers.md) — 3-layer rules: SSOT on repositories, Drift inside repos, controller pattern, reactive defaults, typed errors. Includes the chart drill-down as a worked example of how UI selection state is kept out of the data layer.
- [`data-model.md`](docs/architecture/data-model.md) — Money in minor units, immutable category `type`, `l10n_key` identity, archive-instead-of-delete, indirect icons/colors, `pending_transactions` staging, pagination cap.
- [`ui-and-layout.md`](docs/architecture/ui-and-layout.md) — Required layout primitives, 600dp adaptive breakpoint, 2× text scale, reference live screens.
- [`bootstrap.md`](docs/architecture/bootstrap.md) — First-run + bootstrap order, splash redirect, route table.
- [`testing.md`](docs/architecture/testing.md) — Test organization by layer; repository/controller/migration patterns; per-slice coverage map.
- [`dependencies.md`](docs/architecture/dependencies.md) — layer-boundary check (replaced `import_lint`), base `app_zh.arb` requirement, Android and iOS build toolchains.

Code generation is required whenever a `@freezed`, `@riverpod`, or Drift `@DriftDatabase`/`@DataClassName` annotation changes — the build fails loudly if generated files are stale.

## Performance rules

These rules come from a performance audit covering rendering, memory, startup and package size. Measure before restructuring anything for speed: run `flutter run --profile` and use DevTools. Never break an architecture rule for a gain you have not measured.

- **Render user-data lists lazily.** A list whose length depends on the user's data uses `ListView.builder` / `SliverList.builder`, or caps rendered rows behind a "Show N more" control (`PendingSection`, and `SelectedSliceItemsList` with `_kDrilldownPageSize`). Never map unbounded rows into a `Column` inside a `SingleChildScrollView`. Home's single-day `Column` is a deliberate exception: its row count is bounded. Don't set `itemExtent` on rows that contain text, because it breaks the 2× text-scale requirement. The same goes for a fixed grid `mainAxisExtent`: derive the text's share from `MediaQuery.textScalerOf(context)` (see `category_picker.dart`). A `FittedBox` label hides the problem by shrinking the text instead of overflowing, so assert rendered size at 2×, not just no exception.
- **Keep `build()` and controller emit paths free of side effects.** No I/O, no controller or stream creation, no logging, and no new `NumberFormat`/`DateFormat` built per row. Format money with `MoneyFormatter.format`/`formatBare`, which cache their formats. Older per-call formatters remain in `date_helpers.dart` and `PendingSection`. A recompute path such as `ChartsController._emitIfReady` must not start a network call or DB write on every emission. Track what has already been requested, because a write can make the same stream emit again and loop.
- **Don't add trace logs to shipped code.** `debugPrint` runs in release builds. Never log amounts, totals, balances, currency sets or memos. Error logs carry `${e.runtimeType}` only.
- **Never put `keepAlive: true` on a Riverpod family.** Every argument set would keep its state and Drift subscription for the rest of the session. If a provider must outlive its screen during an undo window:
  - take a `ref.keepAlive()` link only while the undo is pending, and close it on commit or undo;
  - make calls after dispose no-ops, for example by nulling the emitter in `onDispose`.

  `CategorySearchDetailController` is the reference implementation.
- **Regenerate whenever you edit a file that has a generated part.** `riverpod_generator` embeds a hash of the provider's source (comments excluded), so any code edit inside a provider leaves the committed `.g.dart` stale, even when no annotation changed. Run `build_runner` and commit the regenerated file in the same commit.
- **Call `setState` only when something changed.** In high-frequency callbacks (fl_chart `touchCallback`, gesture and scroll handlers), compare the new value with the current one before calling `setState`. After an `await` or a platform callback (WebView, timers), check `mounted` first.
- **Give each animated chart its own `RepaintBoundary`.** fl_chart adds none, so `_ChartBody` wraps each one. Don't add boundaries elsewhere unless a DevTools repaint trace shows the need.
- **Before `runApp`, `bootstrap()` does only what the first frame needs:** opening the database, the first-run seed, and reading theme, locale, the splash gate, the default currency (read after the seed) and intl date data. Run everything else after the first frame, the way recurring generation does. Don't reorder the documented bootstrap steps to save milliseconds.
- **Ship only what the app uses.**
  - Any dependency that ships fonts or assets must be referenced from `lib/`, because Flutter bundles those files whether or not you use them. The unused `material_symbols_icons` added about 34 MB of fonts, about 15.6 MB once compressed.
  - Dependencies with nothing to ship, such as `path_provider` (pulled in by `drift_flutter`) and `json_annotation`, cost nothing and can stay.
  - List assets by file, not by directory.
  - Don't give light and dark native-splash entries the same image, because each entry gets its own copy.
  - After adding a package or asset, check the size with `flutter build apk --analyze-size` or `unzip -l` on the APK.
- **These are already decided, so don't "optimise" them:**
  - R8 and resource shrinking are Flutter's release defaults, so don't add Gradle flags.
  - Drift runs on a background isolate through `driftDatabase()`.
  - The existing Drift indexes cover the hot queries.
  - Home's `_Composer` batches its stream emissions in microtasks.
  - The charts use `skipLoadingOnReload`.
  - The box-shadow colour is randomised on each build.
  - There are no deferred components, because APKs ship through GitHub Releases rather than Play.

### CI workflows

- `.github/workflows/check.yml` — three parallel jobs on pushes/PRs to `main`, each resolving packages from the committed lockfile (`--enforce-lockfile`). **Analyse:** codegen, failing if the committed generated files are stale → format check → `dart analyze --fatal-infos` (enforces `riverpod_lint`). **Test:** layer-boundary check (`flutter test test/unit/architecture/`) → `flutter test`. **Android APK builds:** signed release if signing secrets are present, otherwise debug, passing `FOREX_API_URL` via `--dart-define`. Test and Android use the committed generated files without rerunning codegen.
- `.github/workflows/android-release.yml` — builds split signed release APKs on version tags, generates SHA-256 checksums, uploads APK assets to the GitHub Release.
- `.github/workflows/github-pages.yml` — builds and deploys the Astro site from `site/`. `.github/workflows/site-check.yml` runs Yarn install/audit/test/check/build whenever site-related files change.
- `.github/workflows/ios-nightly.yml` — iOS debug build (`flutter build ios --no-codesign --debug`) that also checks the build did not create `ios/Podfile` (plugins come in through Swift Package Manager; no CocoaPods) and that `sqlite3.framework` is embedded. Runs on PRs to `main` that touch `pubspec.yaml`, `pubspec.lock` or `ios/`, and via `workflow_dispatch`; not a scheduled nightly.

If you touch `site/`, use `corepack enable` plus `yarn --cwd site install --immutable`, `yarn --cwd site test`, `yarn --cwd site check`, `yarn --cwd site build`.

l10n codegen is configured in `l10n.yaml`; generated output lands in `lib/l10n/`. Bare `zh` resolves to English at runtime — see [`docs/architecture/dependencies.md`](docs/architecture/dependencies.md) for why the `app_zh.arb` fallback shim must stay.

## Testing

See [`docs/architecture/testing.md`](docs/architecture/testing.md) for the layer layout, canonical harness (`test/support/test_app.dart`), and per-slice coverage map. 

The non-obvious rule when writing new tests: any Drift-backed setup or direct repository write that happens **before the first `pump`** must run inside `tester.runAsync(...)` — see `test/widget/smoke_test.dart` and `test/integration/bootstrap_to_home_test.dart`.

## Security and agent hints

See [`PRD.md` → *Security & Privacy*](PRD.md#security--privacy). Operational specifics for this repo:

- MVP is fully local-first and currently has no secrets.
- In Phase 2, the Ankr API key must flow only through `data/services/secure_storage_service.dart` → `data/repositories/api_key_repository.dart`. Nothing else may read or write it.
- Currency-price requests send only currency pairs and conversion metadata — never memos, categories, or any other transaction text.
- Exchange-rate fetching uses `String.fromEnvironment('FOREX_API_URL')` in `lib/data/services/exchange_rate_service.dart`; pass it via `--dart-define` in app/build workflows instead of hardcoding URLs.
- Keep failure logs sanitized (exception type only, no transaction data or request payloads). **Do not log financial data** (transactions, memos, balances, wallet data).

## Skills Available

Four Flutter skills from `flutter/agent-plugins` are installed with `npx skills` at `.agents/skills/`, symlinked into `.claude/skills/` and pinned in `skills-lock.json`. They are written for a generic Flutter app, so read each one with its notes below. Where a skill disagrees with `PRD.md` or `docs/architecture/`, those win.

- `flutter-apply-architecture-best-practices` — layered architecture (UI, optional domain, data). Invoke it when structuring a new feature.
- `flutter-build-responsive-layout` — layouts that adapt to the window size. Invoke it when building or refining UI.
- `flutter-add-widget-test` — `WidgetTester` tests of one widget's rendering and interactions. Invoke it when writing a widget test.
- `flutter-add-integration-test` — end-to-end flow tests. Invoke it when writing a flow test; only its test-authoring advice applies.

### `flutter-apply-architecture-best-practices`

Take the layers and the order of work: models → services → repositories → optional use case → view model → view. Don't take its folder tree, state management, dependency injection or error handling. Map its terms like this:

- **Project structure** → keep the `PRD.md` tree (`lib/app/`, `lib/core/`, `lib/data/`, `lib/features/<feature>/`). The move to the skill's `lib/{data,domain,ui}/` tree is tracked in issue #87; don't start it in feature work.
- **ViewModel extending `ChangeNotifier`** → a `@riverpod` controller in `lib/features/<feature>/*_controller.dart`. It holds immutable Freezed state, usually a sealed `*_state.dart`, and exposes commands as methods. Slice-local helper providers go in `*_providers.dart`; only these two kinds of feature file may import `app/providers/repository_providers.dart`.
- **View with `ListenableBuilder`** → `*_screen.dart` and the slice's `widgets/`. A widget that reads state is a `ConsumerWidget` or `ConsumerStatefulWidget` that `ref.watch`es the controller and calls commands through `ref.read(...Provider.notifier)`; other widgets take constructor arguments.
- **Constructor injection, `provider` / `get_it` (Step 7)** → Riverpod providers in `lib/app/providers/`: `repository_providers.dart` builds repositories and use cases, and `service_providers.dart` builds services. Controllers `ref.watch` them and tests override them. Run `build_runner` after adding or editing a provider.
- **Services return API models or `Result`** → services return plain Dart values (records, primitives, SDK types) and repositories map them to the Freezed models in `lib/data/models/`. Repositories throw typed exceptions rather than return results, because Drift rolls back a `db.transaction` only when an exception escapes it. Controllers expose reads as `AsyncValue` and return a Freezed sealed outcome from each command that can fail ([`PRD.md` → *Error Handling Pattern*](PRD.md#error-handling-pattern)). Never add a generic `Result` wrapper.
- **Use cases (Step 4)** → only when the work coordinates several repositories, in `lib/data/use_cases/` (see `PRD.md`).
- **Step 8 (tests)** → write the failing test first (TDD rule above), in the layer folders of `docs/architecture/testing.md`.

### `flutter-build-responsive-layout`

Take its advice on measuring space (`MediaQuery.sizeOf`, `LayoutBuilder` on the parent's constraints), on `Expanded` and `Flexible`, on lazy builders and on not locking orientation. Then:

- **Breakpoint** → Ledgerly has one: a width of 600dp or more is wide (`>= 600`; the skill's `>` would put exactly 600 on the narrow side). Reuse the existing switches instead of writing a new one:
  - A modal form route goes inside `_AdaptiveFormRoute` in `lib/app/router.dart`, which shows it as a dialog at most 560dp wide on wide windows.
  - A picker or sheet checks `MediaQuery.sizeOf(context).width >= 600` and opens a constrained `Dialog` or a modal bottom sheet, as `category_picker.dart` and `account_picker_sheet.dart` do.
- **New layouts** → beyond those patterns, don't add a breakpoint, an in-screen layout switch or a list-to-grid conversion without changing `PRD.md` first. PRD's *Adaptive Layouts* table also lists a Home two-pane, marked pending: Home is single-pane at every width. Ask before building it.
- **Large screens** → skip the skill's *Optimizing for Large Screens* workflow and its `Center`/`ConstrainedBox` width caps. Form routes and pickers already get their width limit from their dialog, and screen bodies stay full width.
- **Widget trees** → follow the required trees in `docs/architecture/ui-and-layout.md`, such as Home's slivers and the transaction form's fixed keypad.
- **Text scale** → the skill doesn't cover it. Every scrollable region must survive 2× text scale. Fixed-height widgets, such as the keypad, clamp at 1.5× (`textScaler.clamp(maxScaleFactor: 1.5)`) or reflow. See also the `itemExtent` and grid `mainAxisExtent` rules under *Performance rules*.
- **Verifying** → instead of resizing a window, write a widget test on each side of 600 (for example 390 and 1000 wide). Routes use `tester.binding.setSurfaceSize` (`test/unit/app/router_test.dart`). Picker and sheet helpers use a `MediaQuery(data: MediaQueryData(size: ...))` host.

### `flutter-add-widget-test`

Take its `WidgetTester`, `Finder` and pump workflow, and skip its setup step: `flutter_test` and `mocktail` are already dev dependencies. Then:

- **Location** → `test/widget/features/<feature>/`, or `test/widget/app/` for `lib/app/` widgets; never the root of `test/`.
- **Building the widget** → wrap it in a `MaterialApp` with `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales`. Without `supportedLocales`, a `zh_TW` test silently renders English. A test of the whole app shell uses `test/support/test_app.dart` instead.
- **Navigation** → if the widget calls `context.go`, `push` or `pop`, use `MaterialApp.router` with a local `GoRouter` whose other routes are stubs, as `test/widget/features/home/home_screen_test.dart` does.
- **Providers** → prefer an `UncontrolledProviderScope` whose container you dispose with `addTearDown(container.dispose)`, so Drift's stream timers don't fail the test at teardown. Override repositories with `mocktail` mocks or the controller with a fake. Pass `retry: noProviderRetry` when a provider is meant to fail, as production does.
- **`@Dependencies`** → `main()` and every helper or test-only widget that pumps a widget annotated with `@Dependencies`, or reads a scoped provider, needs `@Dependencies([...])`. That covers most feature screens, because every repository provider is scoped. Copy the names from the lint's "Missing dependencies" message (`docs/architecture/testing.md`).
- **Drift** → most widget tests mock repositories. A test that uses a database runs every Drift query inside `tester.runAsync(...)`: the seed, inserts and lookups, and reads after the flow. Creating the database and the container can stay outside.
- **`pumpAndSettle`** → don't use it while a loading spinner is on screen, whatever the skill says about async updates. It times out if the spinner stays, and if the spinner ends after a delay it silently advances fake time past it, which can hide timing bugs. Step time explicitly: `await tester.pump(); await tester.pump(const Duration(seconds: 1));`.
- **Text scale** → for text in a scrollable or fixed-size region, add a 2× case through `MaterialApp.builder` (`MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2))`). Check the rendered size, not only that nothing threw.
- **Goldens** → none run today; the splash golden test was deleted in 3947f73. Ask before adding `matchesGoldenFile`.
- **Verify** → after `flutter test <file>`, run `dart format` on it and `dart analyze --fatal-infos`. Only `dart analyze` reliably reports riverpod_lint's missing-`@Dependencies` warnings, and CI fails on them.

### `flutter-add-integration-test`

Ledgerly's integration tests are host-side flow tests in `test/integration/`. They run under `flutter test` against an in-memory Drift database, and CI runs them with the rest of the suite. Most pump the app through `test/support/test_app.dart`. A flow that needs no UI drives a `ProviderContainer` in a plain `test()`, as `amount_formula_flow_test.dart` does. Run one with `flutter test test/integration/<name>_test.dart`. The widget-test notes above apply here too. From the skill:

- **Setup** → skip it. There is no `integration_test` package, `integration_test/` or `test_driver/` folder, Flutter Driver or `flutter drive` step. Skip `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` too. Instead of `pumpWidget(MyApp())`, pump `buildTestApp(container: makeTestContainer(db: db))`, or `buildBootstrappedTestApp(db: db)` when the flow covers bootstrap.
- **MCP exploration** (`launch_app`, `get_widget_tree`) → skip it; no Dart MCP server is configured. Find widgets from the screen source and the existing tests instead.
- **Execution targets** → ignore its Chrome, web-server and Firebase Test Lab targets and its `traceAction` perf driver. For performance, follow *Performance rules*.
- **On-device tests** → ask before adding them. They need new dev dependencies and a CI job with a device or emulator. On a device, HTTP isn't mocked and `bootstrap()` opens the real database, so such tests must still override `appDatabaseProvider` and the exchange-rate service.
- **Driver extension** → never call `enableFlutterDriverExtension()` from a file under `lib/`, including the skill's `lib/main_test.dart`. There, the `flutter_driver` import fails CI's `dart analyze --fatal-infos` (`depend_on_referenced_packages`), and in `lib/main.dart` it would also ship in release builds.

## Knowledge Consolidation

After resolving a non-trivial problem, run `/ce:compound` to persist the solution for future reference.

- `docs/solutions/` is a searchable prior-solutions store organized by category (`architecture-patterns/`, `best-practices/`, `database-issues/`, `design-patterns/`, `logic-errors/`, `performance-issues/`, `runtime-errors/`, `test-failures/`, `ui-bugs/`); solution docs use YAML frontmatter like `module`, `tags`, and `problem_type`.
- `/ce:plan` auto-searches `docs/solutions/` at planning time to surface relevant prior solutions before implementation begins.
- Each solution document includes: problem description, root cause, fix applied, and tags for search.

When to invoke `/ce:compound`:
- After a tricky bug is fixed (especially build/CI failures, async issues, borrow-checker patterns)
- After establishing a new architectural pattern or workflow convention
- After integrating a new dependency or provider that required non-obvious configuration
