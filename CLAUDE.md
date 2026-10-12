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

Ledgerly is a local-first Flutter expense tracker. **MVP is complete.** Several Phase 2 slices have shipped on `main`: recurring transactions + pending approval on Home, transaction search, extended multi-currency conversion, basic charts (pie + daily bar) with slice drill-down, and the splash display-text rework. Drift schema is at **v5**; snapshots live in `drift_schemas/`.

The spec in [`PRD.md`](PRD.md) is the **authoritative source of truth** — read it before making any architectural or data-model decision. Earlier design thinking in `docs/superpowers/specs/` has been superseded by `PRD.md` wherever they conflict. Wave planning for the M5 slice set lives in [`docs/plans/m5-ui-feature-slices/`](docs/plans/m5-ui-feature-slices/); newer Phase 2 plans live in [`docs/superpowers/plans/`](docs/superpowers/plans/).

The repo contains: `pubspec.yaml`, `analysis_options.yaml`, `import_analysis_options.yaml`, `l10n/` (`app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`), `lib/`, `test/`, `drift_schemas/`, `docs/`, and `.github/workflows/`. Match the folder layout and package list in `PRD.md` when extending the scaffold — do not default to a generic `flutter create` shape.

## Common Commands

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

Detailed agent-facing rules live under [`docs/architecture/`](docs/architecture/README.md). When in doubt, read [`PRD.md`](PRD.md) — these docs summarize it.

- [`layers.md`](docs/architecture/layers.md) — 3-layer rules: SSOT on repositories, Drift inside repos, controller pattern, reactive defaults, typed errors.
- [`data-model.md`](docs/architecture/data-model.md) — Money in minor units, immutable category `type`, `l10n_key` identity, archive-instead-of-delete, indirect icons/colors, `pending_transactions`, pagination cap.
- [`ui-and-layout.md`](docs/architecture/ui-and-layout.md) — Required layout primitives, 600dp adaptive breakpoint, 2× text scale.
- [`bootstrap.md`](docs/architecture/bootstrap.md) — First-run + bootstrap order, splash redirect, route table.
- [`testing.md`](docs/architecture/testing.md) — Test organization by layer; repository/controller/golden/migration patterns.
- [`dependencies.md`](docs/architecture/dependencies.md) — `import_lint ^0.1.6` and base `app_zh.arb` pins.

## Security & Secrets

MVP ships with **no secrets** — everything is local. Phase 2 introduces the Ankr API key, which must flow through `SecureStorageService` → `ApiKeyRepository`; nothing else may read or write it. Phase 2 currency-price requests send only currency pairs and conversion metadata — never memos, categories, or any other transaction text. **Financial data must never be written to logs.** See [`PRD.md` → *Security & Privacy*](PRD.md#security--privacy).

## Skills Available

Three Flutter-specific skills are installed at `.agents/skills/` and symlinked into `.claude/skills/`:

- `flutter-architecting-apps` — recommended layered structure; aligns with the stricter version in `PRD.md`.
- `flutter-building-layouts` — Flutter constraint/layout guidance for building the screens above.
- `flutter-animating-apps` — animation / transition guidance for feature polish work.

When the user asks to structure a new feature, invoke `flutter-architecting-apps`; when building or refining UI, invoke `flutter-building-layouts`; when adding transitions or motion, invoke `flutter-animating-apps`.

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
