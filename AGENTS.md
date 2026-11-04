# AGENTS.md

General behaviour rules come first, then Ledgerly-specific rules. They favour caution over speed; on trivial tasks, use judgment.

## 1. Think before coding

- State your assumptions. If the request is unclear or can be read more than one way, name the readings and ask. Don't pick one silently.
- If a simpler approach exists, say so, and push back when it's warranted.
- Always use the `superpowers:test-driven-development` skill when writing code: write a failing test, watch it fail, then write the minimal code that makes it pass.

## 2. Less code for the same features

Write the minimum code that solves the problem. Add no features, single-use abstractions, configurability or error handling for impossible cases unless someone asked for them. If 200 lines could be 50, rewrite it.

PR #135 removed 2,831 lines (1,614 hand-written `lib/` lines) without changing behaviour. The habits below are what created that code. The full write-up is in [`docs/solutions/workflow-issues/safe-redundant-code-removal-with-adversarial-verification.md`](docs/solutions/workflow-issues/safe-redundant-code-removal-with-adversarial-verification.md).

**Don't write:**

- **A second copy.** Before writing a helper, mapper, query, dialog, sheet or snackbar, search for an existing one. Look in:
  - `lib/core/utils/` (`MoneyFormatter`, `DateHelpers`)
  - `lib/ui/core/widgets/` (`showAdaptiveSheet`, `showConfirmDialog`, `showUndoSnackBar`)
  - the repositories (`currencyFromRow`, `RepositoryException`)
  - `test/support/` (`test_app.dart`, `textScaleBuilder`)

  If one almost fits, extend it rather than copy it, but only when the extended helper plus your call is shorter than a local copy (count after `dart format`). Don't add a flag that only one caller sets just to merge an existing copy.
- **What Dart, Flutter or Drift already does.** Use:
  - `table.count(where:)`, not hand-rolled COUNT queries
  - `math.pow`, not loops
  - `DateTime(y, m + 1)` to roll month 13 into January, with no December special case. It rolls an overflowing day too, so clamp the day first, as `_clampDay` in `recurring_rules_repository.dart` does.
  - `DateTime.parse`, not substring parsing
  - `Locale.toString()`
  - Freezed `==` instead of revision counters
  - `AppLocalizations.localizationsDelegates` instead of listing the delegates by hand

  Don't pass `ThemeData` arguments that equal the defaults.
- **Code only tests call.** No public method, parameter or mode in `lib/` should exist only so a test can reach it. Test through the production path.
- **Variants, states or branches nothing produces.** Don't add `loading`/`error` variants that the outer `AsyncValue` already covers. PRD's `HomeState` shape is the exception.
- **Guards for the impossible.** Examples:
  - a read-back check that the row "disappeared" right after a write
  - a re-entry flag on a callback that fires once
  - a null check the types already rule out (delete it; don't add `!`)
  - a dedupe of rows the code itself just created

  Where the type is nullable but the logic guarantees a value, such as reading back a row you just wrote, use `!` instead of a throw. Guards against things that can happen stay: the already-requested set and the post-dispose no-ops in *Performance rules*, and `mounted` checks after `await`.
- **State you can derive.** Don't store a count, a flag, a mirror or a "last requested" copy that other state already determines. Compute it.
- **A wrapper around one value.** A class or sealed type that holds one id or one message should just be an `int?` or a `String`. Inline helpers that have one caller.
- **Parameters that never vary.** Drop a parameter when every caller passes the same value or when it repeats the widget's own field. Give Freezed fields defaults instead of repeating `false`/`null` at every call site.
- **Parallel query pairs.** Write one DAO method with a parameter (`watchAll(type:)`, `watchAll(includeArchived:)`) rather than a filtered twin, and have `get…` and `watch…` share one `Selectable`.

**Don't "simplify" these away.** Each one was a rejected cleanup finding:

- **What PRD or the docs name.** This covers:
  - a seam with no caller yet (the Duplicate flow, whose removal is open as #134; `CurrencyRepository.updateCustomName`)
  - a named state shape
  - a documented guard or decision (exhaustive `switch` over sealed outcomes, explicit enum wire mappers)

  Search `PRD.md`, `docs/` and `docs/solutions/` before you delete.
- **Code that only looks equivalent.** Read the pinned library source and look for a counterexample:
  - Drift `Value.absent()` keeps the stored value under `replace`, but `Value(null)` writes NULL.
  - A `keepAlive` provider has a different lifetime.
  - Riverpod's dispose can run `_stop` twice, overlapping itself.
- **A merge that doesn't shrink the code.** Run `dart format` and count the lines, generated ones included. A shared widget or flag that serves one call site doesn't pay. When a new shared helper does pay, list it in PRD and `docs/architecture/` in the same change.
- **Copies that differ on purpose:**
  - the mockup typography
  - the dedicated search-result row (not Home's `TransactionTile`)
  - the non-dismissible Manage-accounts sheet
- **References grep can't see.** Before calling something dead, check:
  - generated provider names and `@Dependencies` lists
  - Drift accessors
  - `l10n_key` strings and registry keys stored in the DB
  - route `extra` keys
  - ARB keys in every locale file

## 3. Surgical changes

- Every changed line traces to the request. Don't reformat, re-comment or refactor adjacent code that works, and match the existing style.
- Remove the imports, variables and functions that your own change left unused. Mention pre-existing dead code, and delete it only when asked: a cleanup is its own task, as #135 was.

## 4. Goal-driven execution

- Turn the task into a check you can loop on: a test that reproduces the bug, tests for invalid input, or tests that pass before and after a refactor.
- For a multi-step task, state a short plan with a check for each step: `1. [step] → verify: [check]`.

## Source precedence

- Read [`PRD.md`](PRD.md) first. It is authoritative for architecture, schema, routing, layout, bootstrap order and dependencies. [`docs/architecture/`](docs/architecture/README.md) summarises it by topic. When they conflict, follow `PRD.md`.
- `AGENTS.md` is the quick reference. [`CLAUDE.md`](CLAUDE.md) only imports it, so edit guidance here.
- [`README.md`](README.md) and PRD's *Project Status* block can lag the tree. Trust the checked-in code when they differ.
- `docs/superpowers/specs/`, `docs/superpowers/plans/` and `docs/plans/` are historical design context. If they conflict with `PRD.md`, follow `PRD.md`.

## Project status

- The MVP is complete and Phase 2 is in progress. The shipped slices are listed under *Project Status* in `PRD.md`, and the code is under `lib/ui/features/`. Still to do: wallet sync (Ankr) and credit-card / transfer flows.
- The Drift schema is at v7 (`schemaVersion` in `lib/data/database/app_database.dart`). Version history and migration rules are in [`data-model.md`](docs/architecture/data-model.md).
- Extend the scaffold with the folder layout and package list in `PRD.md` (see *Project structure* below), not a generic `flutter create` shape.

## Commits and Pull Requests

A commit subject names the change. A PR title names the problem that motivated it. Never swap the two forms.

- **Commits follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):** `<type>[(scope)][!]: <description>`, then a blank line, the body, a blank line and the footers.
  - **Types:** `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `build`, `perf`, `style`, `ci`.
  - **Scope:** a directory under `lib/ui/features/` (`shopping_list/` is written `shopping-list`), or a layer or area (`app`, `core`, `data`, `domain`, `ui`, `l10n`, `deps`, `test`). A change that really spans two scopes separates them with a comma: `refactor(home,data):`.
  - **Breaking changes** take `!` before the colon, a `BREAKING CHANGE:` footer, or both. `BREAKING CHANGE` is the one token that must be uppercase.
  - **Footers are git trailers** (`Token: value`, with hyphens rather than spaces), placed after a blank line and never attached to the body.
- **PR titles are `Problem: <the problem>`** or `Problem(scope): <the problem>`. State what is wrong, not what you did: `Problem: Forex rate is not fetched right after transaction saved`, not "fetch rate on save". GitHub appends `(#NN)`, so don't add it.
- **Each commit must analyse and test on its own**, so a regression can be bisected. Split by concern, not by file count. If two files can't compile apart, keep them in one commit and say so in the body.

## Architecture

The detailed rules live in [`docs/architecture/`](docs/architecture/README.md):

- [`layers.md`](docs/architecture/layers.md): repositories as the single source of truth, Drift only inside repositories, controllers, reactive defaults and typed errors. The chart drill-down is the worked example.
- [`data-model.md`](docs/architecture/data-model.md): money in minor units, immutable category `type`, `l10n_key` identity, archive instead of delete, `pending_transactions` and the pagination cap.
- [`ui-and-layout.md`](docs/architecture/ui-and-layout.md): required layout primitives, the 600dp breakpoint, 2× text scale and the reference screens.
- [`bootstrap.md`](docs/architecture/bootstrap.md): bootstrap order, the splash redirect and the route table.
- [`testing.md`](docs/architecture/testing.md): test layout by layer, the harness and the per-slice coverage map.
- [`dependencies.md`](docs/architecture/dependencies.md): the layer-boundary check, the `app_zh.arb` shim, the committed `pubspec.lock`, and the Android and iOS toolchains.

**Regenerate after any edit to a file with a generated part** (`@freezed`, `@riverpod`, Drift), not only after an annotation changes. `riverpod_generator` hashes the provider's source (comments excluded), so any code edit leaves the committed `.g.dart` stale. Run `dart run build_runner build --delete-conflicting-outputs` and commit the result in the same commit.

l10n: the ARBs are in `l10n/` and the config is in `l10n.yaml`. `flutter pub get` generates them into `lib/l10n/`. Never delete the `app_zh.arb` shim, because codegen needs it ([`dependencies.md`](docs/architecture/dependencies.md#chinese-arbs-require-a-base-app_zharb)).

### CI workflows

- **`check.yml`** runs on PRs and pushes to `main`, except changes only under `docs/**`, `**/*.md`, `site/**` or the two site workflows. It runs three parallel jobs, all on `flutter pub get --enforce-lockfile`:
  - **Analyse:** `build_runner`, failing if the committed generated files change → `dart format --set-exit-if-changed .` → `dart analyze --fatal-infos`, which also fails if the riverpod_lint plugin doesn't load.
  - **Test:** `flutter test test/unit/architecture/` → `flutter test`.
  - **Android:** an arm64 APK, signed release if the signing secrets exist and debug otherwise, built with `--dart-define=FOREX_API_URL`.
- **`android-release.yml`** runs on a `vX.Y.Z` tag. It fails unless the tag matches `version:` in `pubspec.yaml`, so bump that first. It then builds split signed APKs with SHA-256 checksums and uploads them to the GitHub Release.
- **`ios-nightly.yml`** is not scheduled. It runs on PRs that touch `pubspec.yaml`, `pubspec.lock` or `ios/`, and on `workflow_dispatch`. It runs `flutter build ios --no-codesign --debug` and fails if the build creates `ios/Podfile` (plugins are Swift Package Manager only) or doesn't embed `sqlite3.framework`.
- **`site-check.yml` and `github-pages.yml`** check and deploy the Astro site in `site/`. If you touch `site/`, run `corepack enable`, then `yarn --cwd site install --immutable`, `yarn --cwd site test`, `yarn --cwd site check` and `yarn --cwd site build`.

## Performance rules

Measure before restructuring anything for speed (`flutter run --profile` with DevTools), and never break an architecture rule for a gain you haven't measured. The audit behind these rules, including the ideas it rejected, is in [`docs/solutions/performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`](docs/solutions/performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md).

- **Render user-data lists lazily.** Use `ListView.builder` / `SliverList.builder`, or cap the rows behind a "Show N more" control (`PendingSection`, and `SelectedSliceItemsList` with `_kDrilldownPageSize`). Never map unbounded rows into a `Column` inside a `SingleChildScrollView`. Home's single-day `Column` is the exception, because its row count is bounded.
  - Don't set `itemExtent` on rows that contain text, and don't give a grid a fixed `mainAxisExtent`. Derive the text's share from `MediaQuery.textScalerOf(context)` (see `category_picker.dart`).
  - A `FittedBox` hides overflow by shrinking the text, so assert the rendered size at 2×.
- **Keep `build()` and controller emit paths free of side effects:** no I/O, no controller or stream creation, no logging, and no `NumberFormat`/`DateFormat` built per row. `MoneyFormatter.format`/`formatBare` cache their formats. `DateHelpers` and `PendingSection`'s date label still build a `DateFormat` on every call, so don't call them per row in a long list. A recompute path such as `ChartsController._emitIfReady` must track what it has already requested, because its own network call or DB write can make the stream emit again and loop.
- **No trace logs in shipped code:** `debugPrint` runs in release builds. What logs may contain is under *Security*.
- **Never put `keepAlive: true` on a Riverpod family**, because every argument set would keep its state and Drift subscription for the rest of the session. If a provider must outlive its screen during an undo window:
  - hold a `ref.keepAlive()` link only while the undo is pending, and close it on commit or undo;
  - make calls after dispose no-ops by nulling the emitter in `onDispose`.

  `CategorySearchDetailController` is the reference implementation.
- **Call `setState` only when something changed.** In high-frequency callbacks (fl_chart `touchCallback`, gesture and scroll handlers), compare the new value with the current one first. Check `mounted` after an `await`, a timer or a WebView callback.
- **Give each animated chart its own `RepaintBoundary`**, because fl_chart adds none. `CategoryPieChart` gets one in `_ChartBody` and `DailyBarChart` gets one in `ChartsTrendCard`. Add none elsewhere without a DevTools repaint trace.
- **Before `runApp`, `bootstrap()` does only what the first frame needs:** opening the DB, the first-run seed, reading theme, locale and the splash gate, reading the default currency after the seed, and loading intl date data. Everything else runs after the first frame, the way recurring generation does. Don't reorder the documented steps ([`bootstrap.md`](docs/architecture/bootstrap.md)).
- **Ship only what the app uses.** Flutter bundles a dependency's fonts and assets even if `lib/` never uses them; the unused `material_symbols_icons` cost about 34 MB.
  - List assets by file, not by directory.
  - Don't give the light and dark native-splash entries the same image, because each entry gets its own copy.
  - Packages that ship nothing, such as `json_annotation`, cost no size and can stay.
  - After adding a package or asset, run `flutter build apk --analyze-size --target-platform android-arm64` (size analysis needs a single ABI), or `unzip -l` the built APK.
- **Already decided, so don't "optimise" these:**
  - Gradle R8 and resource-shrink flags (Flutter's release defaults)
  - Drift's background isolate (`driftDatabase()`)
  - extra Drift indexes
  - the microtask batching in Home's `_Composer`
  - `skipLoadingOnReload` on the charts
  - the box-shadow colour randomised on each build
  - deferred components (APKs ship through GitHub Releases)

## Testing

See [`docs/architecture/testing.md`](docs/architecture/testing.md) for the test layout by layer, the canonical harness (`test/support/test_app.dart`) and the per-slice coverage map. The Drift `tester.runAsync` rule is under *`flutter-add-widget-test`* below.

## Security

The rules live in [`PRD.md` → *Security & Privacy*](PRD.md#security--privacy). For this repo:

- **Never log financial data:** transactions, amounts, totals, balances, currency sets, memos, wallet data or request payloads. Error logs carry `${e.runtimeType}` only.
- The Ankr API key (Phase 2 wallet sync, not built yet) must flow only through `lib/data/services/secure_storage_service.dart` → `lib/data/repositories/api_key_repository.dart`. Nothing else may read or write it.
- Exchange-rate requests send only currency pairs and conversion metadata, never memos, categories or other transaction text. The URL comes from `String.fromEnvironment('FOREX_API_URL')` in `lib/data/services/exchange_rate_service.dart`, set with `--dart-define`. Never hardcode it.

## Skills Available

Four Flutter skills from `flutter/agent-plugins` live in `.agents/skills/`, symlinked into `.claude/skills/` and pinned in `skills-lock.json`. They target a generic Flutter app, so read each one with its notes below. Where a skill disagrees with `PRD.md` or `docs/architecture/`, those win.

### `flutter-apply-architecture-best-practices` (structuring a feature)

Take its layers and its order of work: models → services → repositories → optional use case → view model → view → tests (TDD, in the layer folders of `docs/architecture/testing.md`). Don't take its state management, dependency injection or error handling. Map its terms like this:

- **Project structure** → its `lib/{ui,domain,data}/` tree plus `app/` and `core/`, as in [`layers.md` → *Folder layout*](docs/architecture/layers.md#folder-layout). Each slice has flat `view_models/` and `views/` folders with no `widgets/` subfolder. Sub-slices nest under their parent. No widgets go in `lib/core/`.
- **ViewModel extending `ChangeNotifier`** → a `@riverpod` controller in `view_models/*_controller.dart`. It holds immutable Freezed state, usually a sealed `*_state.dart`, and exposes commands as methods. Slice-local helper providers go in `view_models/*_providers.dart`, with pure helpers beside them.
- **View with `ListenableBuilder`** → `views/`, where routed screens are `*_screen.dart`. A widget that reads state is a `ConsumerWidget` or `ConsumerStatefulWidget` that `ref.watch`es the controller and calls commands through `ref.read(...Provider.notifier)`. Other widgets take constructor arguments.
- **Constructor injection, `provider` / `get_it`** → Riverpod providers in `lib/app/providers/` (`repository_providers.dart`, `service_providers.dart`). Controllers `ref.watch` them and tests override them. Which UI files may import them is in [`layers.md` → *Where things live*](docs/architecture/layers.md#where-things-live).
- **API models / `Result`** → never add a generic `Result` wrapper.
  - Services return records, primitives or SDK types.
  - Repositories map those to `lib/domain/models/` and throw typed exceptions, because Drift rolls back a `db.transaction` only when an exception escapes it.
  - Controllers expose reads as `AsyncValue` and return a sealed outcome from each command that can fail ([`PRD.md` → *Error Handling Pattern*](PRD.md#error-handling-pattern)).
- **Use cases** → only for work that coordinates several repositories. Their import limits are in [`layers.md` → *Where things live*](docs/architecture/layers.md#where-things-live).
- **`lib/data/models/`** → don't create it unless an external payload is nested or large and needs `fromJson`/`toJson`, or several services or repositories share it (e.g. Ankr wallet sync). Only services and repositories may import it. Update `PRD.md` and the ban in `import_analysis_options.yaml` first.

### `flutter-build-responsive-layout` (building UI)

Take its advice on measuring space (`MediaQuery.sizeOf`, `LayoutBuilder`), on `Expanded`/`Flexible`, on lazy builders and on not locking orientation. Then:

- **Breakpoint** → there is one: a width `>= 600` is wide (the skill's `>` puts 600 on the narrow side). Reuse the switches in [`ui-and-layout.md` → *Adaptive Breakpoint*](docs/architecture/ui-and-layout.md#adaptive-breakpoint):
  - `_AdaptiveFormRoute` in `lib/app/router.dart` for modal form routes
  - `showAdaptiveSheet` (`lib/ui/core/widgets/adaptive_sheet.dart`) for pickers and sheets
- **New layouts** → don't add a breakpoint, an in-screen layout switch or a list-to-grid conversion without changing `PRD.md` first. Home stays single-pane; ask before building the pending two-pane layout PRD lists.
- **Large screens** → skip its *Optimizing for Large Screens* workflow and its `Center`/`ConstrainedBox` width caps. Dialogs already cap their width, and screen bodies stay full width.
- **Widget trees and text scale** → follow [`ui-and-layout.md`](docs/architecture/ui-and-layout.md): Home's slivers, the bottom-pinned keypad, 2× text scale for scrollable regions, and the 1.5× clamp for fixed-height widgets (`textScaler.clamp(maxScaleFactor: 1.5)`). Also follow the `itemExtent`/`mainAxisExtent` rules under *Performance rules*.
- **Verifying** → write a widget test on each side of 600 (for example 390 and 1000 wide). Routes use `tester.binding.setSurfaceSize` (`test/unit/app/router_test.dart`). Sheets use a `MediaQuery(data: MediaQueryData(size: ...))` host (`test/widget/app/adaptive_sheet_test.dart`).

### `flutter-add-widget-test` (writing a widget test)

Take its `WidgetTester`, `Finder` and pump workflow, and skip its setup step: `flutter_test` and `mocktail` are already dev dependencies. Then:

- **Location** → `test/widget/features/<feature>/`, or `test/widget/app/` for `lib/app/` and `lib/ui/core/widgets/`. Never the root of `test/`.
- **Host** → a `MaterialApp` with `localizationsDelegates` and `supportedLocales` from `AppLocalizations`. Without `supportedLocales`, a `zh_TW` test silently renders English. If the widget navigates, use `MaterialApp.router` with a local `GoRouter` whose other routes are stubs (`home_screen_test.dart`). For the whole shell, use `test/support/test_app.dart`.
- **Providers** → an `UncontrolledProviderScope` with `addTearDown(container.dispose)`; otherwise Drift's stream timers fail the teardown. Mock repositories with `mocktail` or fake the controller. Pass `retry: noProviderRetry` when a provider is meant to fail.
- **`@Dependencies`** → required on `main()` and on any helper or test-only widget that pumps a scoped widget or reads a scoped provider, which covers most feature screens. Copy the names from the lint's "Missing dependencies" message ([`testing.md` → *Patterns*](docs/architecture/testing.md#patterns)). CI fails without them.
- **Drift** → run every Drift query inside `tester.runAsync(...)`: the seed, inserts, lookups and reads after the flow. Creating the database and the container can stay outside.
- **`pumpAndSettle`** → never use it while a spinner is on screen. It times out, or it silently advances fake time past a delay and hides timing bugs. Step time explicitly: `await tester.pump(); await tester.pump(const Duration(seconds: 1));`.
- **Text scale** → for text in a scrollable or fixed-size region, add a 2× case with `MaterialApp.builder: textScaleBuilder(2)` (`test/support/text_scale.dart`). Assert the rendered size, not just that nothing threw.
- **Test font** → the default test font is about twice as wide as Roboto, so text wraps in tests where it fits on a phone. A test of fit to a width or a phone's height loads Roboto from `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/` with a `FontLoader` in `setUpAll`. The font then stays loaded, so put that group last in the file (see `compact form (issue #100)` in `transaction_form_screen_test.dart`).
- **Goldens** → none run today (removed in 3947f73). Ask before adding `matchesGoldenFile`.
- **Verify** → run `flutter test <file>`, then `dart format` and `dart analyze --fatal-infos`. Only `dart analyze` reliably reports missing `@Dependencies`.

### `flutter-add-integration-test` (writing a flow test)

Flow tests are host-side `flutter test` files in `test/integration/` that run against an in-memory Drift database, and CI runs them with the rest of the suite. Only the skill's test-authoring advice applies, and the widget-test notes above apply too.

- **Setup** → skip it. There is no `integration_test` package or folder, no `test_driver/`, no Flutter Driver, no `flutter drive` and no `IntegrationTestWidgetsFlutterBinding`. Pump `buildTestApp(container: makeTestContainer(db: db))`, or `buildBootstrappedTestApp(db: db)` when the flow covers bootstrap. A flow with no UI drives a `ProviderContainer` in a plain `test()` (`amount_formula_flow_test.dart`).
- **MCP exploration, Chrome/web/Firebase targets and `traceAction`** → skip them; no Dart MCP server is configured. Find widgets from the screen source and the existing tests. For performance, follow *Performance rules*.
- **On-device tests** → ask first. They need new dev dependencies and a CI job with a device, and they must still override `appDatabaseProvider` and the exchange-rate service.
- **Driver extension** → never call `enableFlutterDriverExtension()` from a file under `lib/`, including the skill's `lib/main_test.dart`. The `flutter_driver` import fails `dart analyze --fatal-infos` (`depend_on_referenced_packages`), and from `main.dart` it would ship in release builds.

## Knowledge Consolidation

`docs/solutions/` holds documented fixes and lessons from past work, in one subfolder per category, each with YAML frontmatter (`module`, `tags`, `problem_type`). It is relevant when you implement, debug or clean up code in an area it covers.

After a tricky fix (build or CI failures, async or stream timing), a new architectural or workflow convention, or a dependency that needed non-obvious configuration, run `/ce-compound` to add a doc.
