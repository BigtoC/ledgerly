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

- **MVP is complete.** The Phase 2 slices shipped on `main` are: recurring transactions + Home pending approval, transaction search, multi-currency conversion (with `exchange_rates` cache + FX-converted display), basic charts (pie + daily bar) with slice drill-down, and the splash display-text rework.
- **Drift schema is at v7** (v7 is data-only: it backfills the seeded `category.investment` expense row; v6 adds the nullable `transactions.amount_formula` column; `exchange_rates` was introduced in v5 after `recurring_rules` + `pending_transactions` in v4); snapshots are committed in `drift_schemas/drift_schema_v1.json`–`v7.json`.
- **Live feature slices:** `lib/features/splash/`, `lib/features/categories/`, `lib/features/accounts/`, `lib/features/analysis/`, `lib/features/settings/`, `lib/features/transactions/`, `lib/features/shopping_list/`, `lib/features/home/`, `lib/features/recurring/`.
- **Runtime entry:** `lib/main.dart` awaits `bootstrap()` in `lib/app/bootstrap.dart`; `lib/app/app.dart` renders `MaterialApp.router`; `lib/app/router.dart` wires the route table; `lib/app/widgets/adaptive_shell.dart` owns the 600dp nav switch. Full bootstrap flow: see [`docs/architecture/bootstrap.md`](docs/architecture/bootstrap.md).
- Remaining Phase 2 work: wallet sync (Ankr integration), CSV import, credit-card / transfer flows.
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
- [`testing.md`](docs/architecture/testing.md) — Test organization by layer; repository/controller/golden/migration patterns; per-slice coverage map.
- [`dependencies.md`](docs/architecture/dependencies.md) — layer-boundary check (replaced `import_lint`), base `app_zh.arb` requirement, Android and iOS build toolchains.

Code generation is required whenever a `@freezed`, `@riverpod`, or Drift `@DriftDatabase`/`@DataClassName` annotation changes — the build fails loudly if generated files are stale.

## Performance rules

These rules come from a performance audit covering rendering, memory, startup and package size. Measure before restructuring anything for speed: run `flutter run --profile` and use DevTools. Never break an architecture rule for a gain you have not measured.

- **Render user-data lists lazily.** A list whose length depends on the user's data uses `ListView.builder` / `SliverList.builder`, or caps rendered rows behind a "Show N more" control (`PendingSection`, and `SelectedSliceItemsList` with `_kDrilldownPageSize`). Never map unbounded rows into a `Column` inside a `SingleChildScrollView`. Home's single-day `Column` is a deliberate exception: its row count is bounded. Don't set `itemExtent` on rows that contain text, because it breaks the 2× text-scale requirement.
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

- `.github/workflows/check.yml` — package resolution from the committed lockfile (`--enforce-lockfile`) → layer-boundary check (`flutter test test/unit/architecture/`) → codegen → format check → `dart analyze --fatal-infos` (enforces `riverpod_lint`) → `flutter test`, then builds Android APKs on pushes/PRs to `main` (signed release if signing secrets are present, otherwise debug), passing `FOREX_API_URL` via `--dart-define`.
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

Three Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.
- `flutter-animating-apps` — animation / transition guidance for feature polish work.

When the user asks to structure a new feature, invoke `flutter-architecting-apps`; when building or refining UI, invoke `flutter-building-layouts`; when adding motion or transitions, invoke `flutter-animating-apps`.

## Knowledge Consolidation

After resolving a non-trivial problem, run `/ce:compound` to persist the solution for future reference.

- `docs/solutions/` is a searchable prior-solutions store organized by category (`best-practices/`, `database-issues/`, `design-patterns/`, `logic-errors/`, `performance-issues/`, `runtime-errors/`, `test-failures/`, `ui-bugs/`); solution docs use YAML frontmatter like `module`, `tags`, and `problem_type`.
- `/ce:plan` auto-searches `docs/solutions/` at planning time to surface relevant prior solutions before implementation begins.
- Each solution document includes: problem description, root cause, fix applied, and tags for search.

When to invoke `/ce:compound`:
- After a tricky bug is fixed (especially build/CI failures, async issues, borrow-checker patterns)
- After establishing a new architectural pattern or workflow convention
- After integrating a new dependency or provider that required non-obvious configuration
