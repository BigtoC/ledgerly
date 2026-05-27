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
- [`CLAUDE.md`](CLAUDE.md) / `AGENTS.md` are quick references that link into the above.
- [`README.md`](README.md) is useful for day-to-day commands and CI expectations, but some status/setup notes lag the committed scaffold; trust the checked-in tree when they differ.
- `docs/superpowers/specs/2026-04-14-ledgerly-design.md` is historical context only. If it conflicts with `PRD.md`, follow `PRD.md`.

## Project status

- **MVP is complete.** The Phase 2 slices shipped on `main` are: recurring transactions + Home pending approval, transaction search, multi-currency conversion (with `exchange_rates` cache + FX-converted display), basic charts (pie + daily bar) with slice drill-down, and the splash display-text rework.
- **Drift schema is at v5** (`exchange_rates` was introduced in v5 after `recurring_rules` + `pending_transactions` in v4); snapshots are committed in `drift_schemas/drift_schema_v1.json`–`v5.json`.
- **Live feature slices:** `lib/features/splash/`, `lib/features/categories/`, `lib/features/accounts/`, `lib/features/analysis/`, `lib/features/settings/`, `lib/features/transactions/`, `lib/features/shopping_list/`, `lib/features/home/`, `lib/features/recurring/`.
- **Runtime entry:** `lib/main.dart` awaits `bootstrap()` in `lib/app/bootstrap.dart`; `lib/app/app.dart` renders `MaterialApp.router`; `lib/app/router.dart` wires the route table; `lib/app/widgets/adaptive_shell.dart` owns the 600dp nav switch. Full bootstrap flow: see [`docs/architecture/bootstrap.md`](docs/architecture/bootstrap.md).
- Remaining Phase 2 work: wallet sync (Ankr integration), CSV import, credit-card / transfer flows.

## Architecture

Detailed agent-facing rules live under [`docs/architecture/`](docs/architecture/README.md):

- [`layers.md`](docs/architecture/layers.md) — 3-layer rules: SSOT on repositories, Drift inside repos, controller pattern, reactive defaults, typed errors. Includes the chart drill-down as a worked example of how UI selection state is kept out of the data layer.
- [`data-model.md`](docs/architecture/data-model.md) — Money in minor units, immutable category `type`, `l10n_key` identity, archive-instead-of-delete, indirect icons/colors, `pending_transactions` staging, pagination cap.
- [`ui-and-layout.md`](docs/architecture/ui-and-layout.md) — Required layout primitives, 600dp adaptive breakpoint, 2× text scale, reference live screens.
- [`bootstrap.md`](docs/architecture/bootstrap.md) — First-run + bootstrap order, splash redirect, route table.
- [`testing.md`](docs/architecture/testing.md) — Test organization by layer; repository/controller/golden/migration patterns; per-slice coverage map.
- [`dependencies.md`](docs/architecture/dependencies.md) — `import_lint ^0.1.6` and base `app_zh.arb` pins.

## Commands and workflows

> When verifying changes, run `dart format .` before any `flutter test` or `flutter analyze` command.

- `flutter pub get`
- `flutter run`
- `dart format .` (run before `flutter test` or `flutter analyze` whenever verifying changes)
- `flutter analyze` (runs analyzer + `custom_lint` / `riverpod_lint`)
- `dart run import_lint` (reads the regex rules in the root `import_analysis_options.yaml`)
- `dart run build_runner build --delete-conflicting-outputs`
- `dart run build_runner watch --delete-conflicting-outputs`
- `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
- `flutter test` / e.g. `flutter test test/widget/features/transactions/transaction_form_screen_test.dart` / `flutter test test/unit/repositories/migration_test.dart` / `flutter test test/integration/bootstrap_to_home_test.dart`

### CI workflows

- `.github/workflows/check.yml` — package resolution → `dart run import_lint` → codegen → format check → `flutter analyze` → `flutter test`, then builds Android APKs on pushes/PRs to `main` (signed release if signing secrets are present, otherwise debug), passing `FOREX_API_URL` via `--dart-define`.
- `.github/workflows/android-release.yml` — builds split signed release APKs on version tags, generates SHA-256 checksums, uploads APK assets to the GitHub Release.
- `.github/workflows/github-pages.yml` — builds and deploys the Astro site from `site/`. `.github/workflows/site-check.yml` runs Yarn install/audit/test/check/build whenever site-related files change.
- `.github/workflows/ios-nightly.yml` — currently a manual `workflow_dispatch` iOS debug build (`flutter build ios --no-codesign --debug`), not a scheduled nightly.

If you touch `site/`, use `corepack enable` plus `yarn --cwd site install --immutable`, `yarn --cwd site test`, `yarn --cwd site check`, `yarn --cwd site build`.

l10n codegen is configured in `l10n.yaml`; generated output lands in `lib/l10n/`. Bare `zh` resolves to English at runtime — see [`docs/architecture/dependencies.md`](docs/architecture/dependencies.md) for why the `app_zh.arb` fallback shim must stay.

## Testing

See [`docs/architecture/testing.md`](docs/architecture/testing.md) for the layer layout, canonical harness (`test/support/test_app.dart`), and per-slice coverage map. The non-obvious rule when writing new tests: any Drift-backed setup or direct repository write that happens **before the first `pump`** must run inside `tester.runAsync(...)` — see `test/widget/smoke_test.dart` and `test/integration/bootstrap_to_home_test.dart`.

## Security and agent hints

See [`PRD.md` → *Security & Privacy*](PRD.md#security--privacy). Operational specifics for this repo:

- MVP is fully local-first and currently has no secrets.
- In Phase 2, the Ankr API key must flow only through `data/services/secure_storage_service.dart` → `data/repositories/api_key_repository.dart`. Nothing else may read or write it.
- Exchange-rate fetching uses `String.fromEnvironment('FOREX_API_URL')` in `lib/data/services/exchange_rate_service.dart`; pass it via `--dart-define` in app/build workflows instead of hardcoding URLs.
- Keep failure logs sanitized (exception type only, no transaction data or request payloads). **Do not log financial data** (transactions, memos, balances, wallet data).

## Skills Available

Three Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.
- `flutter-animating-apps` — animation / transition guidance for feature polish work.

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

- `docs/solutions/` is a searchable prior-solutions store organized by category (`best-practices/`, `database-issues/`, `logic-errors/`, `runtime-errors/`, `test-failures/`, `ui-bugs/`); solution docs use YAML frontmatter like `module`, `tags`, and `problem_type`.
- `/ce:plan` auto-searches `docs/solutions/` at planning time to surface relevant prior solutions before implementation begins.
- Each solution document includes: problem description, root cause, fix applied, and tags for search.

When to invoke `/ce:compound`:
- After a tricky bug is fixed (especially build/CI failures, async issues, borrow-checker patterns)
- After establishing a new architectural pattern or workflow convention
- After integrating a new dependency or provider that required non-obvious configuration
