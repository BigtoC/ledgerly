# M5 Wave 0 — Shared Contracts

**Source of truth:** [`PRD.md`](../../../PRD.md). Sequenced by [`implementation-plan.md`](../implementation-plan.md) → *M5 Feature slices* → *Agent execution waves*. Where this plan is silent, defer to those two.

Wave 0 freezes every cross-slice contract **before** any Wave 1 slice starts. One agent, one PR. No feature logic lands here.

---

## 1. Goal

Eliminate the rebase bill that would otherwise hit Wave 2 (Transactions) and Wave 4 (Integration). By end of Wave 0:

- The `CategoryPicker` call-site API is locked. Transactions can write its category-selection code against a skeleton that won't change shape when Categories implements the internals.
- ARB namespacing is written down, so four parallel Wave 1 agents can add keys without stepping on each other.
- Cross-slice ownership (duplicate flow, archive affordance, manage-categories link) is assigned. No slice re-litigates these at review time.
- The "do-not-touch" surface is enumerated, so slice agents don't edit the router, bootstrap, or repositories in passing.

---

## 2. Deliverables

### 2.1 `CategoryPicker` API skeleton

**File:** `lib/features/categories/widgets/category_picker.dart` — new file, compiling stub.

**Frozen API:**

```dart
import 'package:flutter/material.dart';

import '../../../data/models/category.dart';

/// Opens the category picker sheet and resolves with the user's selection.
/// Returns null if the user dismisses the sheet without choosing.
///
/// `type` filters by expense/income per PRD §Add/Edit Interaction Rules.
/// Archived categories are always excluded from the picker.
/// Categories are sorted by `sortOrder` (nulls last) then by display name.
///
/// Renders as ModalBottomSheet → CustomScrollView → SliverGrid per
/// PRD.md → Layout Primitives → Category picker. Must survive 2× text
/// scale per PRD.md → Layout Primitives → Constraint rule.
///
/// Implementation lands in Wave 1 (Categories slice owner).
Future<Category?> showCategoryPicker(
  BuildContext context, {
  required CategoryType type,
});
```

**Non-negotiables:**
- Signature is exactly `Future<Category?> showCategoryPicker(BuildContext, {required CategoryType type})`. No positional overloads, no `onSelected` callback variant, no extra named params in Wave 0.
- Data source is `categoryRepositoryProvider.watchAll(type: type, includeArchived: false)`. Picker never opens its own Drift session.
- Widget class (if any) lives in the same file and is library-private (`_CategoryPickerSheet`). Call sites only see the top-level `show*` function.
- Stub body: `throw UnimplementedError('Wave 1: Categories slice owner')`. File compiles; tests for it land in Wave 1.

**Why freeze the function, not the widget:** `showModalBottomSheet` + Future-return composes with Transactions' form (`final picked = await showCategoryPicker(...); if (picked != null) controller.selectCategory(picked);`). A `ConsumerWidget` with `onSelected` callback forces the caller to manage the sheet lifecycle — rejected.

**Forward-compat notes (do not implement in Wave 0):** If Wave 1 needs additional filtering (e.g. exclude a specific category id for "change category" flows), add named params with defaults that preserve the current behavior. Never change the required positional signature.

### 2.2 ARB namespace contract

Existing keys in `l10n/app_en.arb` already follow `<slice><Concept>` camelCase (e.g. `homeEmptyTitle`, `settingsSplashEnabled`). Wave 0 codifies the rule:

| Prefix                 | Owner                     | Notes                                                                                                                                                             |
|------------------------|---------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `common*`              | Shared / Wave 4           | Cancel/Save/Delete/Undo/Archive/Edit/Add/Done/Discard already reserved. New `common*` keys require a note in the PR that two+ slices need them.                   |
| `nav*`                 | M4 shell (frozen)         | Do not add.                                                                                                                                                       |
| `errorSnackbarGeneric` | Shared                    | Do not add slice-specific generic errors; reuse this.                                                                                                             |
| `splash*`              | Splash slice              |                                                                                                                                                                   |
| `home*`                | Home slice                |                                                                                                                                                                   |
| `tx*`                  | Transactions slice        | Use `tx` (not `transaction`) to keep keys short. `transactionType*` already reserved for segmented control.                                                       |
| `category*` (display)  | Categories slice / seeded | Display names for seeded rows already reserved (`categoryFood`, `categoryIncomeSalary`, …). New seeded category display names match the DB `l10n_key` convention. |
| `categories*` (UI)     | Categories slice          | Screen labels, section headers, CTAs (`categoriesListTitle`, `categoriesAddCta`, …). Distinct from `category*` display names.                                     |
| `account*` (display)   | Accounts slice / seeded   | Already reserved: `accountTypeCash`, `accountTypeInvestment`.                                                                                                     |
| `accounts*` (UI)       | Accounts slice            | Screen labels, CTAs, form fields.                                                                                                                                 |
| `settings*`            | Settings slice            | Splash subsection keys already reserved (`settingsSplash*`).                                                                                                      |

**Rules:**
- One PR per slice adds its own keys. Each new key lands in **all four** ARB files (`app_en`, `app_zh`, `app_zh_TW`, `app_zh_CN`) in the same PR — never leave a locale behind.
- `app_zh.arb` remains the bare-fallback file and only carries `appTitle` plus anything explicitly marked "fallback-only." Full translations live in `app_zh_TW.arb` and `app_zh_CN.arb`.
- Every new key needs an `@<key>` description block. PRD line references preferred when the key corresponds to a PRD-specified label.
- If two slices discover they need the same label, promote to `common*` — but require reviewer sign-off, don't do it reflexively.
- User-entered strings (custom category names, custom splash text) are **not** localized — see `PRD.md` → *Internationalization*.

**Pre-reserved keys from M4 (not to be redefined):** see `l10n/app_en.arb`. Full list authoritative there; this plan does not mirror it to avoid drift.

### 2.3 Cross-slice ownership contract

| Concern                               | Owner (UI)                                          | Owner (behavior / state) | Contract                                                                                                                                                                                                                                                                                               |
|---------------------------------------|-----------------------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Duplicate transaction                 | Home                                                | Transactions             | Home owns swipe / overflow affordance and navigates to `/home/add` with a duplicate-source argument (route extra). Transactions reads the arg in its controller, prefills amount / category / account / memo, leaves `date` defaulting to today (user can adjust). Save path identical to a fresh add. |
| Swipe-to-delete / archive             | Each list-owning slice (Home, Categories, Accounts) | Same slice's controller  | Controller decides delete-vs-archive per repository rules (`isReferenced` → archive). Affordance is a `flutter_slidable` action on the row. Each slice implements its own; no shared `SlidableRow` widget in Wave 0 — extract only if three divergent copies emerge in Wave 4.                         |
| Undo after delete                     | Slice that deleted                                  | Same slice's controller  | SnackBar with `commonUndo` action. Controller exposes `undoLastDelete()` as a typed command. Timeout = platform default.                                                                                                                                                                               |
| Manage Categories entry point         | Settings                                            | Categories               | Settings renders a tile that `context.go('/settings/categories')`. Categories owns the screen and its state.                                                                                                                                                                                           |
| Splash settings controls              | Settings                                            | Settings                 | Settings reads/writes `user_preferences` keys `splash_enabled`, `splash_start_date`, `splash_display_text`, `splash_button_label` via `UserPreferencesRepository`. Splash reads the same keys; no cross-call between the two controllers.                                                              |
| Default account / default currency    | Settings                                            | Settings                 | Settings writes `default_account_id` and `default_currency`. Transactions / Accounts read them via repo. Changes propagate via Riverpod stream; no direct notifications.                                                                                                                               |
| Pending badge count (Phase 2 stub)    | Home                                                | Home                     | Home's controller reads a constant `0` in MVP. Do not wire a real stream; Phase 2 replaces the source.                                                                                                                                                                                                 |
| Account currency indicator in tx form | Transactions                                        | Transactions             | Transactions reads the selected account's `currency` and renders the ISO code beside the amount. Accounts slice has no part in this.                                                                                                                                                                   |

**Record any cross-slice concern that surfaces mid-M5 as an addendum here,** not as a decision inside a slice PR. "We decided in review" is how contracts rot.

### 2.4 Do-not-touch list for Wave 1–3 slice agents

The following are frozen. Any change requires a dedicated PR and owner sign-off — **not** a passing edit from a slice PR.

| Path / surface                                           | Frozen by | Owner for changes                                                         |
|----------------------------------------------------------|-----------|---------------------------------------------------------------------------|
| `lib/app/bootstrap.dart`                                 | M4        | Platform (Wave 4 Integration)                                             |
| `lib/app/app.dart`                                       | M4        | Platform                                                                  |
| `lib/app/router.dart` (route tree)                       | M4        | Platform (Wave 4 replaces placeholders)                                   |
| `lib/app/providers/repository_providers.*`               | M4        | Platform                                                                  |
| `lib/data/database/**`                                   | M1        | Platform                                                                  |
| `lib/data/models/**`                                     | M1        | Platform                                                                  |
| `lib/data/repositories/**` (signatures)                  | M3        | Platform — new methods need an RFC, not a drive-by addition               |
| `drift_schemas/**`                                       | M1        | Platform (only Phase 2 adds v2)                                           |
| `lib/core/utils/color_palette.dart`                      | M2        | Append-only; no reorder, ever                                             |
| `lib/core/utils/icon_registry.dart`                      | M2        | Append-only; additions fine, removals / renames require cross-slice audit |
| `lib/core/utils/money_formatter.dart`                    | M2        | Platform                                                                  |
| `lib/core/utils/date_helpers.dart`                       | M2        | Platform                                                                  |
| `lib/core/theme/**`                                      | M2        | Platform                                                                  |
| `pubspec.yaml`                                           | M0        | Platform — new deps require PR review citing `PRD.md` → *Dependencies*    |
| `analysis_options.yaml` / `import_analysis_options.yaml` | M0        | Platform                                                                  |

**Slice agents may freely edit:**
- Their own `lib/features/<slice>/` folder (screen, controller, state, `widgets/`).
- All four ARB files for keys under their reserved prefixes (see §2.2).
- Their own `test/unit/controllers/<slice>_controller_test.dart` and `test/widget/features/<slice>/` folders.

**Placeholder screens in `lib/features/<slice>/*_screen.dart` are expected to be fully replaced** by the slice owner. Corresponding placeholder tests in `test/widget/` that were scaffolded in M4 may be replaced by real widget tests per slice — the slice owner owns test replacement for their slice.

### 2.5 Shared widget directory convention

- Intra-slice widgets live at `lib/features/<slice>/widgets/`. Example: `lib/features/categories/widgets/category_picker.dart`, `lib/features/transactions/widgets/calculator_keypad.dart`.
- **No `lib/core/widgets/` folder in MVP.** If the same widget is genuinely needed by two slices, it lives under the slice that *owns the concept* (e.g. `CategoryPicker` is owned by Categories, consumed by Transactions). Consumers import across slice boundaries — `import_lint` does not forbid that (the layer boundary is widget↔repository, not slice↔slice).
- A widget graduates to `core/widgets/` only after three slices need it and its API has survived one round of review. MVP has no such widget.

### 2.6 State / controller conventions (reminder, not new)

These are already specified in `PRD.md` → *Controller Contract* and *Domain Models vs Drift Data Classes*, and already follow in the M4 placeholder files. Restated here only so slice agents don't invent variants:

- State class: Freezed sealed union (`@freezed sealed class <Slice>State`) with variants `loading`, `empty`, `data(...)`, `error(...)`. Additional variants allowed per-slice (e.g. `splash.needsStartDate`); keep the four base variants spelled exactly this way.
- Controller: Riverpod `@riverpod class <Slice>Controller extends _$<Slice>Controller` with `build()` returning the initial state. Stream-backed controllers override `build` to return the first emission and re-emit via `state = AsyncData(...)`.
- Commands: typed methods on the controller class. No `.read(provider.notifier).someUntypedMethod(dynamic)` patterns.
- Widgets never call repositories directly. Widgets never call `NumberFormat`/`DateFormat`/`groupBy`/`fold` inside `build()`.

### 2.7 Codegen hygiene (l10n.yaml + app_zh.arb)

Running `flutter run` currently surfaces two codegen warnings that will clutter every Wave 1–3 developer's terminal if not resolved in Wave 0:

```
l10n.yaml: The argument "synthetic-package" no longer has any effect and should be removed.
    See http://flutter.dev/to/flutter-gen-deprecation
"zh": 50 untranslated message(s).
    To see a detailed report, use the untranslated-messages-file option in the l10n.yaml file:
    untranslated-messages-file: desiredFileName.txt
```

Both are resolved here so slice agents don't chase false signals while verifying their own build output.

**Issue A — `synthetic-package` deprecation.** `l10n.yaml` currently carries `synthetic-package: false`. Flutter has removed the flag entirely; it's a no-op under the current SDK pin. The header comment in `l10n.yaml` also still describes the old `package:flutter_gen/gen_l10n/...` import path, which is stale — real output goes to `lib/l10n/app_localizations.dart` and is imported via `package:ledgerly/l10n/...`.

*Fix:*
1. Delete the `synthetic-package: false` line from `l10n.yaml`.
2. Update the header comment in `l10n.yaml` to reflect the actual output: `output-dir: lib/l10n`, import path `package:ledgerly/l10n/app_localizations.dart`. Remove the `flutter_gen` mention.

**Issue B — `app_zh.arb` untranslated-messages spam.** `app_zh.arb` intentionally carries only `appTitle` per CLAUDE.md → *Dependency Pins* (it is a bare-fallback shim required by `flutter_localizations` codegen; removing it breaks `flutter pub get`). Runtime locale resolution maps bare `zh` to English per PRD → *Internationalization*, so the file is never served at runtime — translations live only in `app_zh_TW.arb` and `app_zh_CN.arb`. The codegen warning is therefore always a false alarm, but it scales with every new ARB key added in Waves 1–3 (50 → 70 → …), obscuring real warnings.

*Fix (approved):* redirect the untranslated report to a file so stdout stays quiet.
1. Add to `l10n.yaml`: `untranslated-messages-file: untranslated-messages.txt`.
2. Add `untranslated-messages.txt` (and `l10n/untranslated-messages.txt`, whichever path gen_l10n writes to under the project's `arb-dir: l10n` / `output-dir: lib/l10n` config — verify at run time) to the repo root `.gitignore`.
3. Add a one-line comment in `l10n.yaml` next to the new key explaining *why* the file is intentionally empty in git (points at PRD → *Internationalization* + CLAUDE.md → *Dependency Pins*).

*Rejected alternatives, do not pursue:*
- **Mirror `app_en.arb` keys into `app_zh.arb` with English values.** Silences codegen but adds a 4th ARB file that must be updated on every future key addition. Violates CLAUDE.md's "keep `app_zh.arb` minimal" pin and creates a maintenance burden that compounds over every Wave 1–3 slice.
- **Delete `app_zh.arb` entirely.** Breaks `flutter pub get` with `Arb file for a fallback, zh, does not exist`. Explicitly ruled out in CLAUDE.md → *Dependency Pins*.
- **Populate `app_zh.arb` with zh_CN values.** Contradicts the PRD runtime policy that bare `zh` falls back to English, not zh_CN.

### 2.8 `AccountRepository.watchBalanceMinorUnits` (new method)

Wave 1 Accounts requires a tracked-balance stream per `PRD.md` → *accounts* notes ("Tracked balance is derived in the account's native currency from transactions assigned to that account"). The current `AccountRepository` surface cannot compute this:

```dart
Stream<List<Account>> watchAll({bool includeArchived = false});
Stream<Account?> watchById(int id);
Future<int> save(Account account);
Future<void> archive(int id);
Future<void> delete(int id);
Future<bool> isReferenced(int id);
```

And `TransactionRepository.watchForAccount(accountId, {limit = 200})` only exposes the most recent N rows — insufficient for a complete sum. This is a contract gap, and Wave 0 is where contract gaps close. §2.4's "repository signatures frozen" rule applies to Wave 1+ slice agents; Wave 0 is allowed to extend the contract surface.

**Add to `lib/data/repositories/account_repository.dart`:**

```dart
/// Sum of all transactions for `accountId` in the account's native
/// currency, expressed as minor units. Expense transactions subtract
/// from the balance; income transactions add. `opening_balance_minor_units`
/// is included. Emits on every insert / update / delete of a transaction
/// that references this account, and on changes to the account row itself
/// (opening balance edits). No cross-currency conversion — the transaction
/// form enforces that transactions on an account use the account's
/// currency, per PRD.md → Add/Edit Interaction Rules. Archived accounts
/// still compute a balance (accounts-plan.md §4).
Stream<int> watchBalanceMinorUnits(int accountId);
```

**Implementation notes:**
- Backed by a Drift SQL aggregate over `transactions` joined with `categories.type` for sign, plus `accounts.opening_balance_minor_units` for the base. Use Drift's `.watch()` to emit reactively.
- Sign convention derived from the linked category: `CategoryType.expense` → subtract, `CategoryType.income` → add. Do not introduce a separate `transaction_type` column (PRD explicitly rejects a third type value).

**Test coverage** — extends `test/unit/repositories/account_repository_test.dart`:
- Empty account (no transactions, `opening_balance_minor_units = 0`) → emits `0`.
- Only opening balance → emits opening balance.
- Single expense → emits `opening - amount`.
- Single income → emits `opening + amount`.
- Mixed expense + income → correct net.
- Transactions on a *different* account do not affect this account's balance.
- Stream re-emits on insert / update / delete of a transaction for this account.
- Archived account still emits its balance.

This addition is the **only** repository surface change in Wave 0. If Wave 2/3 (Transactions / Home) discover their own gaps during their plan authoring, those additions land in the respective wave's contracts step, not retroactively here.

---

## 3. Exit Criteria

- `lib/features/categories/widgets/category_picker.dart` exists with the frozen signature from §2.1 and throws `UnimplementedError` in its body.
- `AccountRepository.watchBalanceMinorUnits(int)` (§2.8) is implemented in `DriftAccountRepository`, exported from the `AccountRepository` abstract class, and covered by the eight tests enumerated in §2.8. Every Wave 1 Accounts agent can consume it on day 1 with no follow-up Platform PR.
- `flutter analyze` clean.
- `flutter test` green, including the new §2.8 tests in `test/unit/repositories/account_repository_test.dart`.
- `flutter run` from a clean `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs` path no longer prints the `synthetic-package` deprecation warning or the `"zh": NN untranslated message(s).` line (§2.7).
- This plan doc is committed in the same PR.
- `docs/plans/implementation-plan.md` → M5 → *Agent execution waves (approved)* table links to this plan.

---

## 4. Not in Scope (defer to later waves)

- Picker rendering, SliverGrid layout, icon/color rendering per category — **Wave 1 Categories owner** implements.
- Any ARB key additions beyond what already exists — **each Wave 1–3 slice** adds its own under §2.2 namespaces.
- Router changes (replacing placeholder routes with real screens) — **Wave 4 Integration**.
- Shared row / swipe / undo widget — **not extracted in MVP**; each slice implements locally per §2.3.
- Golden test scaffolding for Splash — **Wave 1 Splash owner**.
- `CalculatorKeypad` API — internal to Transactions; no cross-slice freeze needed, so not part of Wave 0.

---

## 5. Sequencing

Single agent, single PR, sequential within the PR:

1. Add `lib/features/categories/widgets/category_picker.dart` with the §2.1 skeleton.
2. Implement §2.8 — add `watchBalanceMinorUnits(int)` to the `AccountRepository` abstract class and `DriftAccountRepository` implementation. Extend `test/unit/repositories/account_repository_test.dart` with the eight test cases enumerated in §2.8. Run the repository test file in isolation until green.
3. Apply §2.7 codegen hygiene fixes:
   - Remove `synthetic-package: false` from `l10n.yaml`; refresh the stale header comment to match the real output path.
   - Add `untranslated-messages-file: untranslated-messages.txt` to `l10n.yaml` with an explanatory comment.
   - Add the resulting untranslated-messages file path to `.gitignore`.
4. Re-run `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter run` once to confirm the two warnings no longer appear.
5. Run `flutter analyze` and the full `flutter test`; fix nothing else.
6. Commit + confirm `implementation-plan.md` links this doc from the waves table (already linked as of the previous edit — just verify).
7. Open PR titled `chore(m5): wave 0 shared contracts`.

Wave 1 slice agents do **not** start until this PR merges.

---

## 6. Risks

1. **Agent invents extra picker params.** Enforced by §2.1 "Non-negotiables." Reviewer rejects additions in Wave 0; Wave 1 agent adds via forward-compat defaults only.
2. **Slice agent edits router.dart to "see their screen work."** Caught by §2.4 + Wave 4 reconciliation. Slice agents validate via widget tests against their own screen widget, not by running the full app.
3. **ARB conflict between two parallel Wave 1 slices.** Prevented by §2.2 prefix ownership. If a genuine `common*` candidate emerges, raise in review rather than duplicating under two slice prefixes.
4. **Duplicate flow ownership forgotten.** Home PR lands a navigation call that Transactions hasn't wired yet. Mitigation: Home owner stubs the route-extra producer; Transactions owner stubs the route-extra consumer; integration is in Wave 2 when Transactions lands.
5. **`import_lint` false-positive on intra-slice imports.** The pinned 0.1.6 config at `import_analysis_options.yaml` governs layer boundaries only. Slice-to-slice widget imports (e.g. Transactions importing `CategoryPicker` from Categories) are allowed. If the lint trips, fix the config, not the import — and loop in Platform.

---

*When this plan conflicts with `PRD.md` or `implementation-plan.md`, they win. When all three are silent, ask — don't invent.*
