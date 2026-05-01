# Shopping List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a draft shopping list anchored in Accounts. Users can capture a future expense from the transaction form, review drafts from Accounts, open a draft into the existing transaction form, save draft changes without converting, and convert the draft into a real transaction when ready.

**Architecture:** Add a new `shopping_list_items` Drift table (schema v3) plus a matching repository. Keep discovery in Accounts for this iteration; do **not** add a Home badge/FAB shortcut. Reuse `TransactionFormScreen` and `TransactionFormController` for shopping-list draft editing and conversion so date, currency, keypad, validation, and adaptive layout stay consistent with the existing transaction flow. `ShoppingListController` powers only the dedicated `/accounts/shopping-list` screen (list + delete/undo). Accounts preview uses lightweight providers, shows the three newest drafts, and exposes a non-empty header CTA plus overflow footer CTA into `/accounts/shopping-list`.

**Tech Stack:** Flutter, Drift (SQLite ORM), Riverpod (`riverpod_annotation`), Freezed, go_router, flutter_slidable, mocktail, fake_async

---

## Review-Driven Changes

- Accounts remains the only discovery surface in this version; the Home shortcut was removed from scope.
- The plan no longer introduces `ShoppingListFormController`, `ShoppingListItemController`, or `ShoppingListItemScreen`.
- Shopping-list drafts now preserve both the original `displayCurrency` and planned `date` from the transaction form.
- Account/category lifecycle rules explicitly treat shopping-list rows as references.
- Accounts preview rows are no longer swipe-delete surfaces; delete + undo live only on the dedicated shopping-list screen.
- Preview/full-list rows now use a non-empty fallback label policy instead of rendering memo-only blank rows.

---

## File Structure

**New files:**
- `lib/data/database/tables/shopping_list_items_table.dart`
- `lib/data/database/daos/shopping_list_dao.dart`
- `lib/data/models/shopping_list_item.dart`
- `lib/data/repositories/shopping_list_repository.dart`
- `drift_schemas/drift_schema_v3.json` _(auto-generated)_
- `test/unit/repositories/_harness/generated/schema_v3.dart` _(auto-generated)_
- `lib/features/shopping_list/shopping_list_state.dart`
- `lib/features/shopping_list/shopping_list_controller.dart`
- `lib/features/shopping_list/shopping_list_providers.dart`
- `lib/features/shopping_list/shopping_list_screen.dart`
- `lib/features/shopping_list/widgets/shopping_list_card.dart`
- `test/unit/repositories/shopping_list_repository_test.dart`
- `test/unit/controllers/shopping_list_controller_test.dart`
- `test/unit/controllers/transaction_form_shopping_list_test.dart`
- `test/widget/shopping_list_card_test.dart`
- `test/widget/shopping_list_screen_test.dart`
- `test/widget/transaction_form_shopping_list_button_test.dart`
- `test/widget/transaction_form_shopping_list_mode_test.dart`
- `test/unit/app/router_test.dart`
- `test/integration/shopping_list_path_test.dart`

**Modified files:**
- `lib/data/database/app_database.dart`
- `lib/app/providers/repository_providers.dart`
- `lib/data/repositories/account_repository.dart`
- `lib/data/repositories/category_repository.dart`
- `test/unit/repositories/account_repository_test.dart`
- `test/unit/repositories/category_repository_test.dart`
- `lib/features/accounts/accounts_screen.dart`
- `lib/features/transactions/transaction_form_controller.dart`
- `lib/features/transactions/transaction_form_state.dart`
- `lib/features/transactions/transaction_form_screen.dart`
- `lib/app/router.dart`
- `test/unit/app/router_test.dart`
- `test/unit/repositories/migration_test.dart`
- `l10n/app_en.arb`
- `l10n/app_zh.arb`
- `l10n/app_zh_TW.arb`
- `l10n/app_zh_CN.arb`

---

## Task 1: Schema, DAO, and Migration

**Goal:** Create durable storage for shopping-list drafts and preserve the original transaction date/currency when a form is saved as a draft.

**Files:**
- Create: `lib/data/database/tables/shopping_list_items_table.dart`
- Create: `lib/data/database/daos/shopping_list_dao.dart`
- Create: `lib/data/models/shopping_list_item.dart`
- Modify: `lib/data/database/app_database.dart`
- Modify: `test/unit/repositories/migration_test.dart`
- Regenerate: `drift_schemas/drift_schema_v3.json`
- Regenerate: `test/unit/repositories/_harness/generated/schema_v3.dart`

- [ ] Add the `shopping_list_items` table with:
  - `id`
  - `category_id` FK → `categories.id`
  - `account_id` FK → `accounts.id`
  - nullable `memo`
  - nullable `draft_amount_minor_units`
  - nullable `draft_currency_code` FK → `currencies.code`
  - non-null `draft_date`
  - `created_at`
  - `updated_at`
- [ ] Keep `draft_date` required so a saved draft round-trips the planned transaction date instead of silently switching to `DateTime.now()` later.
- [ ] Keep `draft_currency_code` nullable only when `draft_amount_minor_units` is null. A non-null currency code must resolve through the existing `currencies` table.
- [ ] Add DAO helpers for the main CRUD/read paths plus `countByAccount` and `countByCategory`, because account/category repositories need them for shopping-list-specific delete guards.
- [ ] Register the table and DAO in `AppDatabase`, bump `schemaVersion` to 3, and create the table in `onUpgrade` for `from < 3`.
- [ ] Regenerate Drift/codegen artifacts and the migration harness snapshot for schema v3.
- [ ] Extend migration tests to cover:
  - seeded v2 → v3 upgrade
  - empty v2 → v3 upgrade
  - `PRAGMA foreign_keys = ON` after upgrade

**Patterns to follow:**
- `lib/data/database/app_database.dart`
- `test/unit/repositories/migration_test.dart`

**Test scenarios:**
- Happy path: seeded v2 data survives upgrade and `shopping_list_items` exists empty after migration.
- Edge case: empty v2 database upgrades cleanly to live schema v3.
- Integration: foreign keys remain enabled after v2 → v3 migration.

**Verification:**
- Drift schema snapshot and harness files include v3.
- Migration tests explicitly exercise both seeded and empty upgrade paths.

---

## Task 2: ShoppingListRepository and Reference Semantics

**Goal:** Implement the shopping-list repository and make account/category lifecycle rules count shopping-list drafts as references.

**Files:**
- Create: `lib/data/repositories/shopping_list_repository.dart`
- Modify: `lib/app/providers/repository_providers.dart`
- Modify: `lib/data/repositories/account_repository.dart`
- Modify: `lib/data/repositories/category_repository.dart`
- Create: `test/unit/repositories/shopping_list_repository_test.dart`
- Modify: `test/unit/repositories/account_repository_test.dart`
- Modify: `test/unit/repositories/category_repository_test.dart`

- [ ] Implement `ShoppingListRepository` as the SSOT for draft CRUD with these capabilities:
  - `watchAll()`
  - `getById(int id)`
  - `insert(...)`
  - `update(...)`
  - `delete(int id)`
- [ ] Enforce the cross-column invariant already implied by the original plan: `draft_amount_minor_units != null` requires `draft_currency_code != null`.
- [ ] Add explicit shopping-list-aware delete guards to `AccountRepository.delete` and `CategoryRepository.delete`, but **do not** broaden `isReferenced` / `watchIsReferenced`. Existing transaction-backed affordance and mutation semantics stay unchanged for now.
- [ ] Update repository tests so an account/category with shopping-list rows but no transactions still cannot hard-delete, while existing `isReferenced`-driven affordances continue to mean "referenced by transactions" only.

**Patterns to follow:**
- `lib/data/repositories/account_repository.dart`
- `lib/data/repositories/category_repository.dart`
- `test/unit/repositories/account_repository_test.dart`
- `test/unit/repositories/category_repository_test.dart`

**Test scenarios:**
- Happy path: insert/update/delete round-trip a shopping-list item with memo, amount, currency, and date intact.
- Error path: inserting an amount without a currency throws `ShoppingListRepositoryException`.
- Integration: deleting an account referenced only by shopping-list drafts throws the same in-use exception path used for transactions.
- Integration: deleting a category referenced only by shopping-list drafts is blocked and reported as referenced.

**Verification:**
- Shopping-list repository tests cover CRUD and invariants.
- Account/category repository tests prove shopping-list rows participate in "in use" checks.

---

## Task 3: Accounts Preview Card

**Goal:** Show shopping-list drafts in Accounts without adding a second delete surface or blank rows.

**Files:**
- Create: `lib/features/shopping_list/shopping_list_providers.dart`
- Create: `lib/features/shopping_list/widgets/shopping_list_card.dart`
- Modify: `lib/features/accounts/accounts_screen.dart`
- Create: `test/widget/shopping_list_card_test.dart`

- [ ] Add slice-local providers for:
  - preview rows
  - archived-safe account/category label hydration
  - derived row text (primary label, secondary metadata, date + optional amount)
- [ ] Keep the Accounts card as the first sliver even when there are no accounts; move the account empty state into an inline sliver below it.
- [ ] Make preview rows tap-only. Do **not** attach swipe-delete or undo behavior to the Accounts card.
- [ ] Define the non-empty card IA explicitly:
  - sort by newest `created_at` first
  - show at most 3 preview rows
  - row tap opens the reused draft form for that row
  - header CTA (`View all`) routes to `/accounts/shopping-list`
  - footer overflow CTA uses `shoppingListItemsMore(count)` and also routes to `/accounts/shopping-list`
- [ ] Use a single, explicit row-content rule everywhere the plan references preview/full-list rows:
  - primary label: `memo` when present, otherwise category name
  - secondary metadata: category + account names
  - trailing metadata: always show the stored draft date; append formatted amount when present
- [ ] Keep the empty-card CTA routed to `/accounts/shopping-list/new`.

**Patterns to follow:**
- `lib/features/accounts/accounts_screen.dart`
- `lib/features/accounts/accounts_providers.dart`

**Test scenarios:**
- Happy path: Accounts always renders the shopping-list card before the account section.
- Edge case: preview row falls back to category name when memo is empty.
- Edge case: archived account/category still resolve names for preview rows.
- Integration: preview shows 3 newest rows and the overflow CTA text/count for additional rows.
- Integration: tapping the empty CTA opens the new-draft route.

**Verification:**
- Accounts preview is always visible.
- The preview card never owns delete timers or snackbars.

---

## Task 4: Dedicated ShoppingListScreen and Delete/Undo

**Goal:** Keep list review and delete/undo behavior in one dedicated surface.

**Files:**
- Create: `lib/features/shopping_list/shopping_list_state.dart`
- Create: `lib/features/shopping_list/shopping_list_controller.dart`
- Create: `lib/features/shopping_list/shopping_list_screen.dart`
- Modify: `lib/features/shopping_list/shopping_list_providers.dart`
- Create: `test/unit/controllers/shopping_list_controller_test.dart`
- Create: `test/widget/shopping_list_screen_test.dart`

- [ ] Keep `ShoppingListController` focused on the dedicated screen only. It should watch all rows, manage a 4-second delete/undo window, and expose one listener/effect path because only `ShoppingListScreen` owns it.
- [ ] Do not register `ShoppingListController` from `ShoppingListCard`; the preview card should stay on lightweight providers.
- [ ] Reuse the same derived row-content policy from Task 3 so the dedicated list and preview card cannot drift.
- [ ] Keep swipe-delete + undo snackbar only on `ShoppingListScreen`, and add a visible non-swipe delete affordance (for example an overflow/menu action) so delete is not gesture-only.
- [ ] Preserve `keepAlive: true` only if the list screen still needs the timer to survive brief route overlays from its own draft-form push; do not rely on it for cross-screen Accounts/list coordination anymore.
- [ ] Use the same delayed-delete model as `HomeController`: hide immediately, commit repository delete only when the timer expires, and make undo clear pending state before delete runs. Do not add reinsertion-based undo behavior to the repository API.

**Patterns to follow:**
- `lib/features/home/home_controller.dart`
- `lib/features/home/home_screen.dart`

**Test scenarios:**
- Happy path: deleting a row hides it immediately and commits repository delete after the undo window expires.
- Happy path: undo restores the row before repository delete runs.
- Error path: repository delete failure surfaces one error event/snackbar on `ShoppingListScreen`.
- Edge case: the screen empty state CTA opens `/accounts/shopping-list/new`.
- Integration: rows expose a non-gesture delete path in addition to swipe.
- Integration: preview rows do not subscribe to the controller and therefore cannot clear or steal its effect listener.

**Verification:**
- `ShoppingListScreen` is the only screen that owns delete/undo effect wiring.
- No shared controller listener remains between Accounts and the dedicated list screen.

---

## Task 5: Reuse TransactionForm for Shopping-List Drafts

**Goal:** Reuse the existing transaction form for shopping-list creation, editing, and conversion so date/currency behavior stays identical to the existing transaction flow.

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`
- Modify: `lib/features/transactions/transaction_form_state.dart`
- Modify: `lib/features/transactions/transaction_form_screen.dart`
- Create: `test/unit/controllers/transaction_form_shopping_list_test.dart`
- Create: `test/widget/transaction_form_shopping_list_button_test.dart`
- Create: `test/widget/transaction_form_shopping_list_mode_test.dart`

- [ ] Extend `TransactionFormController` hydration modes so it can open in:
  - normal add
  - duplicate
  - edit existing transaction
  - new shopping-list draft
  - edit existing shopping-list draft
- [ ] Store shopping-list draft context inside `TransactionFormState` so the form knows whether it is editing a real transaction or a shopping-list draft.
- [ ] Add draft-save commands directly to `TransactionFormController` instead of using a separate `ShoppingListFormController`.
- [ ] Define the minimum valid shopping-list draft explicitly:
  - required: selected account, selected expense category, draft date
  - optional together: amount + currency
  - optional: memo
  - invalid: missing account, missing category, income category, amount without currency, currency without amount
- [ ] In normal transaction mode, disable the "Add to shopping list" action until the minimum valid draft fields are present.
- [ ] Show the income-category blocked hint only when the user is on an income category/type state and the shopping-list action is unavailable for that reason.
- [ ] Preserve `TransactionFormData.displayCurrency` and `TransactionFormData.date` when saving/updating drafts.
- [ ] When hydrating an existing draft, resolve the draft currency with `CurrencyRepository.getByCode(draftCurrencyCode)` instead of re-inferring decimals from the selected account.
- [ ] When converting a draft to a transaction:
  - save the transaction with the draft's `displayCurrency`
  - save the transaction with the draft's `date`
  - delete the draft only after `TransactionRepository.save` succeeds
  - return the saved `Transaction` to the caller with the same `context.pop(saved)` pattern used by the existing transaction form when a caller is awaiting a result
  - otherwise route back to `/accounts/shopping-list` as the fallback success destination for direct-entry shopping-list routes
- [ ] In shopping-list edit mode, show explicit inline warning text for archived account/category references. Keep the picker controls tappable so the user can replace archived references. Draft save stays allowed; conversion stays disabled until archived references are replaced.
- [ ] Define mode-specific transaction-form presentation so reuse stays understandable:
  - normal add/edit transaction modes keep existing title + save action
  - new shopping-list draft mode uses shopping-list title/copy and primary action = save draft
  - edit shopping-list draft mode offers save draft + save to transaction, with delete available only for existing drafts
  - all shopping-list modes keep the secondary/additional actions near the memo field or app-bar in one consistent location

**Patterns to follow:**
- `lib/features/transactions/transaction_form_controller.dart`
- `lib/features/transactions/transaction_form_screen.dart`
- `lib/features/home/home_screen.dart` for `context.push<T>()` / `context.pop(saved)` result flow

**Test scenarios:**
- Happy path: ordinary add-transaction form saves a draft and returns to the caller without creating a transaction.
- Happy path: shopping-list edit mode hydrates memo, amount, currency, date, account, and category from an existing draft.
- Happy path: saving a draft preserves a user-selected currency that differs from the selected account currency.
- Happy path: converting a draft creates a transaction with the stored date/currency and removes the draft afterward.
- Error path: conversion failure leaves the draft untouched.
- Error path: invalid draft states keep the shopping-list action disabled or rejected with the documented inline hint.
- Edge case: archived category/account shows warning text, allows draft save, and blocks conversion.
- Edge case: no active account still uses the existing transaction-form empty-state CTA.
- Integration: no visible expense categories still follow the existing picker redirect to category management instead of creating a shopping-list-specific dead-end.
- Integration: direct-entry draft routes fall back to `/accounts/shopping-list` after successful save/convert when no caller is awaiting a typed result.

**Verification:**
- The plan has one source of truth for keypad, date, currency, and form validation.
- `ShoppingListFormController`, `ShoppingListItemController`, and `ShoppingListItemScreen` are no longer part of the implementation.

---

## Task 6: Routing and Localization

**Goal:** Route shopping-list flows through the existing adaptive transaction-form shell and keep localization keys aligned with real UI behavior.

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`

- [ ] Add `/accounts/shopping-list`, `/accounts/shopping-list/new`, and `/accounts/shopping-list/:id` before the existing `/accounts/:id` catch-all.
- [ ] Reuse the same adaptive modal/dialog behavior already used by `_AdaptiveTransactionFormRoute` instead of creating a separate shopping-list-only screen shell.
- [ ] Add only the keys that remain necessary after this revision. At minimum, keep coverage for:
  - screen/card titles
  - add-to-shopping-list action
  - save-draft action
  - view-all / overflow CTA copy
  - empty-state text + CTA
  - delete undo snackbar
  - archived account/category warnings
  - `shoppingListItemsMore`
  - income-category blocked hint
- [ ] Include `app_zh.arb` alongside `app_zh_TW.arb` and `app_zh_CN.arb` so l10n generation stays valid.
- [ ] Do not reuse a conversion-specific failure string for draft-save or delete failures. Reuse `txSaveFailedSnackbar` for transaction-save failures and `errorSnackbarGeneric` or a new generic shopping-list save-failed key for non-conversion failures.

**Patterns to follow:**
- `lib/app/router.dart`
- `lib/features/transactions/transaction_form_screen.dart`

**Test scenarios:**
- Happy path: `/accounts/shopping-list/new` and `/accounts/shopping-list/:id` route before `/accounts/:id`.
- Edge case: invalid `shopping-list/:id` redirects back to `/accounts/shopping-list`.
- Integration: wide layouts render shopping-list draft routes in the same constrained dialog treatment as `/home/add`.
- Integration: router tests cover both pushed-caller and direct-entry shopping-list draft routes.
- Integration: l10n generation succeeds with `app_zh.arb` present.

**Verification:**
- Router path precedence is explicit and tested.
- No stale or misleading shopping-list-only error copy remains in the plan.

---

## Task 7: Integration Coverage and Final Verification

**Goal:** Prove the revised flow end-to-end and keep the plan's test inventory aligned with the work actually being described.

**Files:**
- Create: `test/integration/shopping_list_path_test.dart`

- [ ] Add an integration path that covers:
  - Home → Add Transaction → Add to shopping list
  - return to caller
  - navigate to Accounts
  - Accounts preview shows the saved draft row
  - open dedicated shopping-list screen
  - open draft into the reused transaction form
  - convert draft to transaction
  - return to caller/list screen
  - draft disappears from the shopping list
  - manual navigation to Home shows the new transaction
- [ ] Add a second row-display assertion path for a draft with no memo so the category-name fallback is tested explicitly.
- [ ] Add an Accounts-preview assertion path that verifies preview ordering, 3-row truncation, and the overflow CTA into `/accounts/shopping-list`.
- [ ] Keep the file inventory aligned with the tasks above; do not list test files that are never authored.
- [ ] Run full verification after codegen/formatting:
  - format
  - targeted unit/widget/integration tests
  - full `flutter test`
  - `flutter analyze`
- [ ] Manual smoke test checklist:
  - Add Transaction → Add to shopping list → form closes → Accounts card shows draft
  - Accounts preview rows are tap-only and never show swipe actions
  - Shopping list screen supports swipe-delete + undo
  - Open draft → save draft changes without conversion
  - Open draft → save to transaction → draft disappears from shopping list
  - Navigate to Home and verify the created transaction appears on the correct date

**Patterns to follow:**
- `test/integration/bootstrap_to_home_test.dart`
- `lib/features/home/home_screen.dart` result-return + pin-day flow

**Test scenarios:**
- Happy path: end-to-end capture → draft → convert flow succeeds.
- Edge case: preview/full-list row content stays consistent for memo and no-memo drafts.
- Integration: preview overflow CTA and dedicated list entry behave as documented.
- Integration: conversion returns to the caller instead of forcing implicit navigation to Home.

**Verification:**
- The plan's file inventory matches the actual implementation units.
- Final smoke checklist matches the revised route behavior.

---

**Plan complete and revised in `docs/superpowers/plans/2026-05-01-shopping-list.md`.**
