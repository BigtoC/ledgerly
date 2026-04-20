# Ledgerly MVP Implementation Plan

**Source of truth:** [`PRD.md`](../../PRD.md). This plan sequences the PRD — it does not extend it. Where this plan is silent, defer to `PRD.md`. Phase 2 work is explicitly out of scope here.

---

## 1. Plan Shape at a Glance

Seven milestones, in order:

```text
M0  Scaffold ──▶ M1  Data foundations ──▶ M2  Core utilities ──▶ M3  Repositories + seed
                                                                          │
                                                                          ▼
                                                           M4  App shell (bootstrap + router)
                                                                          │
                                                                          ▼
                                                            M5  Feature slices  (PARALLEL)
                                                                          │
                                                                          ▼
                                                           M6  Integration + polish
```

- **M0–M4 are a single critical path.** Parallelism inside each is narrow (see §5).
- **M5 is where 80% of the work happens in parallel.** One developer per feature slice.
- **M6 is serial polish.** No new features.

The goal of the first four milestones is to freeze every contract a feature slice would otherwise have to invent: import rules, schema, domain models, repositories, formatters, router, theme, provider overrides. Once those are frozen, six screens fall out near-independently.

---

## 2. Principles That Shape the Order

1. **Contracts before code.** `import_lint` rules, Freezed domain models, repository signatures, and state classes are frozen before any widget is built. Changing a contract after three screens exist is rebase hell.
2. **Tests ride alongside their layer.** Repository tests ship with M3, not M6. Widget tests ship with each M5 slice, not later. If the harness doesn't exist when the layer lands, it never will.
3. **Money is an integer, end-to-end.** Any `double` near the word `amount` / `balance` / `rate` is a bug, caught at review and by a pre-merge grep.
4. **Stub only at the edges.** Stub `LocaleService`, `flutter_native_splash` assets, and placeholder screens. Never stub a repository signature or a schema column type.
5. **Parallel by feature, not by layer.** One dev owning both controller and widget of a feature avoids hand-off bugs. Splitting a feature across devs during first implementation breaks every time.

---

## 3. Milestone Summary

| # | Milestone | Purpose | Parallelism |
|---|---|---|---|
| M0 | Repo scaffold & toolchain | Runnable empty app, lint rules wired, CI green | Sequential (one person) |
| M1 | Data foundations | Drift v1 + DAOs + Freezed models + service stubs | Narrow (2 streams, day-1 field-name agreement) |
| M2 | Core utilities | `money_formatter`, `icon_registry`, `color_palette`, `date_helpers`, theme, ARBs | Narrow (3 streams) |
| M3 | Repositories + seed | SSOT API + first-run seeding | 3 repo streams, same merge window |
| M4 | App shell | `bootstrap.dart`, `router.dart`, theme/locale providers, placeholder screens | Sequential (single PR) |
| M5 | Feature slices | All 6 MVP screens | **Maximum — one owner per slice** |
| M6 | Integration + polish | E2E flows, a11y, release prep | Serial |

Rough sizing: ~8 weeks with 2–3 devs. Not a commitment — scope the tail (a11y, splash goldens, tablet adaptive passes) against the shipping calendar.

---

## 4. Dependency Graph

What blocks what. Nothing below this line starts before the thing above it is green.

```text
M0 lint + CI + folder skeleton
      │
      ├──▶ Drift tables (M1-A) ─────┐
      │                             │
      └──▶ Freezed models (M1-B) ───┤   (field-name agreement day 1)
                                    │
                                    ▼
                              Core utils (M2) ──▶ Repositories (M3) ──▶ Seed (M3) ──▶ Bootstrap (M4)
                                                                                          │
                                                                                          ▼
                            ┌───────────────┬─────────────┬─────────────────┬──────────────┬───────────────┐
                            │  Splash       │  Home       │  Add/Edit Tx    │  Categories  │  Accounts     │  Settings
                            │               │             │                 │              │               │
                            └───────────────┴─────────────┴─────────────────┴──────────────┴───────────────┘
                                                                                          │
                                                                                          ▼
                                                                                   M6 Integration
```

**Allowed stubs:** `LocaleService` returns fixed `"en"` until M6; placeholder screens in M4 return `Scaffold(body: Center(child: Text('Home')))`; native-splash assets default config until M6 regeneration.

**Never stub:** repository method signatures, schema column types, `categories.color` palette indices.

---

## 5. Milestone Detail

### M0 — Repo scaffold & toolchain

**Goal:** runnable empty app; `flutter analyze`, `build_runner`, and CI all green on main.

**Deliverables**
- `pubspec.yaml` matching the MVP dependency table in `PRD.md` exactly. No `dio`, no `flutter_secure_storage`, no `fl_chart`.
- `analysis_options.yaml` wires `flutter_lints`, `custom_lint`, `riverpod_lint`, and `import_lint` with the layer-boundary rules from `PRD.md` → *Layer Boundaries*.
- `l10n.yaml` configured for `flutter_localizations` codegen.
- `flutter_native_splash` configured to a themed static splash (assets regenerate in M6).
- CI pipeline: `flutter pub get` → `build_runner build --delete-conflicting-outputs` → `flutter analyze` → `flutter test`. Android build on every PR; iOS nightly.
- Folder skeleton from `PRD.md` → *Folder Structure* in place (empty files with `// TODO(M<n>): ...` header comments are fine).

**Exit criteria**
- Fresh clone → `flutter run` launches a placeholder splash and exits cleanly.
- Intentional layer-violation PR (widget importing `AppDatabase`) fails CI.

**Parallel?** No. One person scaffolds; others write issue tickets from `PRD.md`.

---

### M1 — Data foundations

**Goal:** Drift schema v1 compiles, DAOs work, Freezed domain models exist, service stubs are usable.

**Deliverables**
- All MVP tables in `data/database/tables/` — `currencies`, `transactions`, `categories`, `accounts`, `user_preferences` — with the columns and constraints in `PRD.md` → *Database Schema*.
- `AppDatabase` declares `schemaVersion = 1`.
- First schema snapshot committed to `drift_schemas/drift_schema_v1.json` (from `drift_dev schema dump`).
- Per-entity DAOs in `data/database/daos/`: thin SQL wrappers only, no business rules.
- Freezed domain models in `data/models/`: `Transaction`, `Category`, `Account`, `Currency`. Amount fields typed `int`, not `double`.
- `LocaleService` in `data/services/`: stub that returns `Platform.localeName`.

**Exit criteria**
- `flutter test` passes (no behavioural tests yet; compilation only).
- `drift_dev` round-trips without errors.
- Grep `double.*amount|double.*balance|double.*rate` in `lib/` returns zero hits.

**Parallel window**
| Stream | Owner | Deliverables |
|---|---|---|
| A: Drift tables + DAOs + `AppDatabase` | Data | tables/, daos/, app_database.dart, schema snapshot |
| B: Freezed domain models | Data or Core | data/models/*.dart |

**Critical sync:** Agree field names between Drift tables and Freezed models on **day 1**. A 30-minute sync captured as a comment block in `data/models/README.md` (or similar). Without that, regeneration churn cascades into M2 formatters and M3 seeds.

---

### M2 — Core utilities

**Goal:** the render-time primitives every UI screen depends on.

**Deliverables**
- `core/utils/money_formatter.dart` — integer minor units → localized display string via `NumberFormat.currency`, using `currencies.decimals` from the domain model. Unit-tested against USD (2), JPY (0), ETH (18), TWD (2).
- `core/utils/icon_registry.dart` — `Map<String, IconData>` with fallback to `Symbols.category`. Document the "unknown key" contract.
- `core/utils/color_palette.dart` — append-only ordered `List<Color>`. Comment block at top declaring palette indices are **never reordered** across app versions.
- `core/utils/date_helpers.dart` — day-boundary math, locale-aware formatting, splash day-count helper per `PRD.md` → *Splash Screen*.
- `core/theme/app_theme.dart` + `color_schemes.dart` — `lightTheme` / `darkTheme` via `ColorScheme.fromSeed()`.
- `l10n/app_{en,zh_TW,zh_CN}.arb` — populated with seeded-category `l10n_key`s, splash defaults (`splash.enter`, `splash.sinceDate`), and any shared UI labels the screens will need.

**Exit criteria**
- `test/unit/utils/money_formatter_test.dart` covers 4 currencies × (positive / negative / zero).
- `test/unit/utils/date_helpers_test.dart` covers day-boundary math across locales.
- Theme preview builds (manual verification).

**Parallel window**
| Stream | Owner | Deliverables |
|---|---|---|
| A: `money_formatter` + `date_helpers` + tests | Core | utils + unit tests |
| B: `icon_registry` + `color_palette` | Core or Features | utils + sample usage |
| C: Theme + ARBs | Shell | theme/ + l10n/ |

Stream B must not start its seed icon/color choices until the `Category` domain model is final from M1 — otherwise indices churn.

---

### M3 — Repositories + first-run seed

**Goal:** the data layer exposes the final API controllers will consume; first launch produces a usable DB.

**Deliverables**
- All MVP repositories in `data/repositories/`:
  - `transaction_repository.dart`
  - `category_repository.dart`
  - `account_repository.dart`
  - `currency_repository.dart`
  - `user_preferences_repository.dart`
- Each exposes:
  - `Stream<T>` / `Stream<List<T>>` for list queries (backed by Drift `.watch()`).
  - Typed command methods for writes (`save`, `delete`, `archive`, `update`).
  - Drift → Freezed mapping inside the repository. Drift types do not escape.
- Business rules enforced inside repositories:
  - Category `type` locked after first referencing transaction.
  - Archive-instead-of-delete for categories/accounts with references.
  - Integer minor-unit math on every amount.
  - Currency FK integrity on every insert.
- First-run seed routine (idempotent, callable from `bootstrap.dart`):
  - Seeds `currencies` with USD, EUR, JPY, TWD, CNY, HKD, GBP.
  - Seeds every default category from `PRD.md` → *Default Categories* using stable `l10n_key`s.
  - Seeds one `Cash` account with `opening_balance_minor_units = 0`.
  - Resolves `default_currency` via `LocaleService` (falls back to USD).
- Migration test harness exists (even with only v1 defined) — Phase 2 inherits it without retrofitting.

**Exit criteria**
- `test/unit/repositories/*_test.dart` — one per repository, using Drift in-memory DB.
- Required tests per repository: happy path, archive-instead-of-delete, reactive stream emissions on insert/update/delete, FK enforcement.
- `category_repository_test.dart` explicitly asserts "reject `type` change after first referencing transaction".
- Seed routine is idempotent (running twice doesn't duplicate rows).

**Parallel window**
| Stream | Owner | Deliverables |
|---|---|---|
| A: `transaction_repository` + `category_repository` | Data | repos + rule tests |
| B: `account_repository` + `currency_repository` | Data | repos + rule tests |
| C: `user_preferences_repository` + seed routine + migration harness | Data | repo + seed module + harness |

Streams overlap the same Drift transaction API — merge within a tight window (same week, ideally same PR stack) to avoid rebase churn.

---

### M4 — App shell: bootstrap, routing, theme wiring

**Goal:** the empty shell runs end-to-end with real providers and real seeding.

**Deliverables**
- `app/bootstrap.dart` implements `PRD.md` → *Bootstrap Sequence* exactly:
  1. `WidgetsFlutterBinding.ensureInitialized()`
  2. Open `AppDatabase`
  3. Initialize `LocaleService`
  4. Read `user_preferences`
  5. First-run seed (idempotent)
  6. Build `ProviderScope` overrides injecting the opened DB
  7. `runApp`
- `app/app.dart` wires `MaterialApp.router`, theme provider watching `user_preferences`, and locale provider.
- `app/router.dart` defines the route tree from `PRD.md` → *Routing Structure*:
  - `StatefulShellRoute` for Home / Accounts / Settings
  - Root `redirect:` on `splash_enabled`
  - Fade `CustomTransitionPage` for splash → Home
  - Add/Edit Transaction as a modal push
- Placeholder screens in every `features/*/` folder so routing is navigable end-to-end.
- Adaptive breakpoint (`BottomNavigationBar` ↔ `NavigationRail` at 600dp) wired at the shell level.
- `main.dart` is a three-liner: `bootstrap().then(runApp)`.

**Exit criteria**
- Cold launch on a clean device: splash → Home placeholder.
- Toggling `splash_enabled = false` in `user_preferences` skips splash entirely (no flash).
- A smoke widget test builds `app.dart` with a `ProviderScope` override injecting in-memory `AppDatabase` — this becomes the template for all M5 widget tests.
- One end-to-end integration test: cold start → empty Home. Keeps the integration harness green from day 1 instead of piling up at M6.

**Parallel?** Better as a single PR — shell concerns couple tightly.

---

### M5 — Feature slices (PARALLEL)

**Goal:** every MVP screen implemented per `PRD.md`, with controllers owning state and widgets rendering only.

Six slices, each a self-contained folder under `features/`:

| Slice | Key concerns | Depends on | Parallel-safe against |
|---|---|---|---|
| **Splash** | Day counter, hnotes-style visual, date-picker redirect when unconfigured. Golden tests mandatory. | `user_preferences_repository`, `date_helpers` | All others |
| **Home** | Currency-grouped summary strip, sliver day list, FAB, swipe-to-delete + undo, pending badge (Phase 2 stub). | `transaction_repository`, `money_formatter` | All others |
| **Transactions (Add/Edit)** | Full-screen modal, calculator keypad, expense/income toggle, category picker, account selector, memo, date. | `transaction_repository`, `category_repository`, `account_repository`, **shared `CategoryPicker` widget** | All others, except it shares `CategoryPicker` with Categories |
| **Categories** | List by type, add/edit/archive/reorder, subcategory management, uses the same `CategoryPicker`. | `category_repository`, `icon_registry`, `color_palette` | All others |
| **Accounts** | List with native-currency balances, add account, set default, archive. | `account_repository`, `currency_repository` | All others |
| **Settings** | Theme, language, default account, default currency, splash settings, manage categories entry. | `user_preferences_repository`, theme provider | All others |

**Each slice delivers:**
- `features/<slice>/<slice>_screen.dart` — lean widget, renders state, invokes commands. No `groupBy` / `fold` / `NumberFormat` / `DateFormat` inside `build()`.
- `features/<slice>/<slice>_controller.dart` — Riverpod `AsyncNotifier` / `StreamNotifier`. Owns presentation transformation.
- `features/<slice>/<slice>_state.dart` — Freezed sealed union (`Loading | Empty | Data | Error`).
- `test/unit/controllers/<slice>_controller_test.dart` — uses `ProviderContainer` overrides + `mocktail` to assert state transitions and command side-effects.
- `test/widget/features/<slice>/` — widget tests per state variant, including text-scale ≤ 2×.

**Shared widget contract (freeze on day 1 of M5):**
```dart
// features/categories/widgets/category_picker.dart
class CategoryPicker extends ConsumerWidget {
  final CategoryType type;                          // expense | income
  final void Function(Category) onSelected;
  // Renders as ModalBottomSheet + CustomScrollView per PRD.md → Layout Primitives.
}
```
Both Transactions and Categories consume this. Extracting it later causes divergent implementations.

**Layout primitives to follow (non-negotiable, per `PRD.md` → Layout Primitives):**
- Home: `CustomScrollView` + slivers. Never `ListView` inside `Column`.
- Add/Edit: `Scaffold(resizeToAvoidBottomInset: false)`. Fixed keypad at bottom, scroll above.
- Category picker: `ModalBottomSheet` + `CustomScrollView` + `SliverGrid`.

**Entry criterion for any M5 slice:** M4 shell is merged and the smoke widget test is green.

**Parallel strategy**
- One developer per slice. Do **not** split controller vs widget across devs — the state contract is too fluid during first implementation.
- When team size < 6, prioritize by dependency fan-out: Categories + Accounts first (Transactions needs them), then Transactions, then Home (needs data to exist), then Settings + Splash last.

---

### M6 — Integration & polish

**Goal:** end-to-end flows pass; release candidate built.

**Deliverables**
- `test/integration/` covers every flow in `PRD.md` → *Primary User Flow*, *Quick Repeat Flow*, plus:
  - First-launch flow (seeded defaults → splash date picker → Home → add transaction → DB row).
  - Subsequent launch with splash enabled / disabled.
  - Duplicate flow.
  - Multi-currency flow (two accounts, two currencies, grouped summary).
  - Archive flow (used category/account hidden from pickers, visible in management).
- Migration test harness verified against v1 snapshot (so Phase 2 v1→v2 slots in).
- Accessibility pass: 2× text scale on Home / Add / Category; `Semantics` on every icon-only button; 48×48dp tap targets; screen reader order verified on Home and Add.
- Manual device matrix: Android phone + Android tablet + iOS phone + iOS tablet.
- `flutter_native_splash` assets regenerated for all platforms.
- Release build produced; smoke-tested on signed-build devices.

**Exit criteria**
- All integration tests green on CI.
- `flutter analyze` clean.
- a11y audit doc committed to `docs/`.
- Store listing copy drafted (TBD owner).

---

## 6. Clean-Code Guardrails (Enforceable)

Each rule maps to a PRD section and has a specific enforcement point.

| # | Rule | Enforcement |
|---|---|---|
| G1 | Only repositories write to the DB / secure storage | `import_lint` blocks `data/database/daos/*` imports outside `data/repositories/` |
| G2 | Drift types never cross the repository boundary | `import_lint` blocks `data/database/**` imports inside `features/**` + `domain/**` |
| G3 | Controllers own presentation transformation (grouping, formatting) | Review: `groupBy` / `fold` / `NumberFormat` / `DateFormat` inside `build()` is blocked |
| G4 | Money is `int` minor units end-to-end | Pre-merge grep: `double.*(amount\|balance\|rate\|price)` must return zero hits outside `money_formatter` |
| G5 | Category `type` locked after first use | `CategoryRepository.update` rejects type changes with a typed exception; tested both branches |
| G6 | Archive-instead-of-delete for referenced rows | Repository throws typed exception on delete-with-references; tested both branches |
| G7 | Seeded categories identified by `l10n_key`; renames write `custom_name` only | `CategoryRepository.rename` only writes `custom_name`; seeding checks `l10n_key` for idempotency |
| G8 | Icons / colors are string keys + palette indices, never raw `IconData` / ARGB | Column types `TEXT` / `INTEGER`; no serializer for `IconData` or `Color` exists |
| G9 | Bootstrap sequence matches PRD exactly | All `await` lives inside `bootstrap.dart`; any `await` in `main.dart` outside `bootstrap()` is blocked at review |
| G10 | Router `redirect:` reads `splash_enabled`; no flag inside `SplashScreen` | Splash-disabled integration test asserts no splash render on launch |
| G11 | Layout primitives match PRD | No `ListView` inside `Column` on Home; `resizeToAvoidBottomInset: false` on Add/Edit; widget tests exercise 2× text-scale |
| G12 | Tests organized by layer, not by feature | CI fails if `*_test.dart` lands outside the `test/unit/{services,repositories,controllers,utils}/` or `test/widget/` or `test/integration/` layout |

Guardrails exist to be automated. Anything that falls to "review catches it" will, eventually, not be caught.

---

## 7. Testing Rollout

Tests land **as each layer lands**, not at the end.

| Milestone | Tests that land |
|---|---|
| M0 | CI runs `flutter test` on the generated sample test. Migration harness skeleton stubbed. |
| M1 | None (no behaviour to assert). DAOs are covered transitively by M3 repository tests. |
| M2 | `test/unit/utils/money_formatter_test.dart` (USD / JPY / ETH / TWD, positive / negative / zero). `date_helpers_test.dart`. Splash day-count helper test. |
| M3 | `test/unit/repositories/*_test.dart` — one per repo, in-memory Drift. Mandatory: happy path, archive-instead-of-delete, category type lock, currency FK, reactive stream emissions. Migration harness activated against v1 snapshot. |
| M4 | Smoke widget test: `app.dart` builds with a `ProviderScope` override. One integration test: cold-start → empty Home. |
| M5 | Per slice: `test/unit/controllers/<slice>_controller_test.dart` + `test/widget/features/<slice>/`. Splash golden tests land here. |
| M6 | Full `test/integration/` flows. Accessibility audit. |

**Non-negotiables**
- Ankr API calls are mocked (Phase 2 consideration, but don't add `http` to test deps in MVP).
- Migration tests run against every snapshot in `drift_schemas/` — v1 passes trivially in MVP; Phase 2 gets v1→v2 for free.
- Goldens are refreshed deliberately (`flutter test --update-goldens`), never auto-accepted.

---

## 8. Parallelism Playbook

### 2-developer split (minimum)

| Dev              | Owns                                                                              |
|------------------|-----------------------------------------------------------------------------------|
| Dev A — Platform | M0, M1, M3 repositories, M4 shell, migration harness, `analysis_options.yaml`, CI |
| Dev B — Product  | M2 utilities (after A lands models), M5 feature slices, M6 integration + a11y     |

Overlap window: during M3, both are active — A finishes repos, B writes `money_formatter` against the finalized `Currency` model.

### 3-developer split (recommended)

| Dev                  | Owns                                                                                                                                         |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| Dev A — Data         | M1 schema + DAOs, M3 repositories, migration harness, `test/unit/repositories/*`                                                             |
| Dev B — Core + Shell | M2 utilities, M2 theme + ARBs, M4 bootstrap + router + providers, smoke tests                                                                |
| Dev C — Features     | M5 feature slices (starts after M4). During M0–M4, writes tickets, implements `CategoryPicker` API contract, authors golden-test scaffolding |

Inside M5, Dev C can pull A or B for unblockers. Slice ownership stays one-dev-per-slice.

### 4+-developer split (when M5 is the critical path)

Keep A, B on platform. Split features by **family**, not by layer:
- C1: Splash + Settings (low-data, preferences-heavy).
- C2: Home + Transactions (tightly coupled via repository streams and `CategoryPicker`).
- C3: Accounts + Categories (share archive-vs-delete UX rules).

Never split a single feature across two devs during first implementation.

### Cross-cutting ownership

| Concern                                | Owner                                                             |
|----------------------------------------|-------------------------------------------------------------------|
| `analysis_options.yaml` and lint rules | Dev A (review required)                                           |
| `pubspec.yaml` changes                 | Dev A (review required)                                           |
| ARB file keys                          | Author adds keys in all three files in the same PR; Dev B reviews |
| `drift_schemas/` snapshots             | Dev A                                                             |
| Native splash regen + release build    | Dev B                                                             |

---

## 9. Top Risks

1. **Drift types leak to UI.** Someone passes a `TransactionsCompanion` to a widget "just temporarily." Prevent with `import_lint` from M0; catch via G2.
2. **`double` for money sneaks in.** One field drifts through every call site. Keep every money field `int` in Freezed; grep for `double.*(amount|balance|rate|price)` pre-merge.
3. **Color palette index reorder.** Reordering `color_palette` retroactively remaps every user's category colors. Enforce append-only in M2 with a header comment block.
4. **Seeding before schema is final.** Re-seeding duplicates rows. Gate seed behind empty-DB check; keep seed code out of the tree until M3.
5. **Category type unlocked by accident.** Easy regression. Write "reject type change on referenced category" test **before** writing `CategoryRepository.update`.
6. **`resizeToAvoidBottomInset` default.** Flutter defaults to `true`; the keypad gets covered by soft keyboard. Set `false` explicitly; regression-test with keyboard open.
7. **Router redirect leaks splash.** If splash visibility is checked inside `SplashScreen`, users still see a flash. Implement `redirect:` at root per `PRD.md`.
8. **Locale resolution at the wrong time.** `LocaleService` must resolve before first-run seed so `default_currency` is correct. Bootstrap-order test asserts the sequence.
9. **`CategoryPicker` diverges.** Two devs write it twice and it forks. Extract to `features/categories/widgets/` on day 1 of M5 and freeze the API.
10. **Building Phase 2 shapes "just in case."** No `domain/` folder, no `ApiKeyRepository`, no `pending_transactions` in MVP. Resist.
11. **Integration tests piling up at M6.** Add one in M4 (cold start → empty Home). Harness stays green as features land.
12. **iOS-only breakage at release time.** Run nightly iOS build from M0.

---

## 10. One-Page Order of Work

For the impatient:

1. **M0** — scaffold, lint rules, CI. One person. Green main.
2. **M1** — Drift tables + Freezed models, agreed field names. Snapshot v1.
3. **M2** — `money_formatter`, icon/color registries, theme, ARBs. Tests land here.
4. **M3** — 5 repositories + seed routine. Repository tests land here. Migration harness turns on.
5. **M4** — `bootstrap.dart`, `router.dart`, `ProviderScope`, placeholder screens. One smoke widget test + one integration test.
6. **M5** — 6 feature slices in parallel, one owner each. Controller + widget tests per slice. Freeze `CategoryPicker` API on day 1.
7. **M6** — integration flows, a11y, device matrix, native splash regen, release build.

Any deviation from this order means either a scope shortcut (fine, document it) or a rebase bill (expensive, avoid).

---

*When this plan conflicts with `PRD.md`, `PRD.md` wins. When both are silent, ask — don't invent.*
