# Shopping List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a draft shopping list anchored in Accounts. Users can capture a future expense from the transaction form, review drafts from Accounts, open an existing draft into the existing transaction form, save draft changes without converting, and convert the draft into a real transaction when ready.

**Architecture:** Add a new `shopping_list_items` Drift table (schema v3) plus a matching repository. Keep discovery in Accounts for this iteration. Draft creation remains in the existing `/home/add` transaction form only. Reuse `TransactionFormScreen` and `TransactionFormController` for shopping-list draft editing and conversion so date, currency, keypad, validation, and adaptive layout stay consistent with the existing transaction flow. `ShoppingListController` powers only the dedicated `/accounts/shopping-list` screen (list + delete/undo). Accounts preview uses lightweight providers, shows the three newest drafts, and routes into `/accounts/shopping-list` for full review. Each `shopping_list_items` row represents one future transaction draft; this iteration does not introduce list-native grouping or multi-item workflows.

**Tech Stack:** Flutter, Drift (SQLite ORM), Riverpod (`riverpod_annotation`), Freezed, go_router, flutter_slidable, mocktail, fake_async

---

## Review-Driven Changes

- Accounts remains the primary review surface. A Home shopping-list FAB button (Task 8) is now in scope.
- The Accounts card "Add" affordance (Task 8) is now in scope — the non-empty card header always shows an "Add" icon button.
- The plan no longer introduces `ShoppingListFormController`, `ShoppingListItemController`, or `ShoppingListItemScreen`.
- Shopping-list drafts now always preserve the planned `date`; they preserve `displayCurrency` only when an amount is stored, while zero-amount drafts intentionally reseed visible currency from the selected account on re-open.
- Shopping-list rows participate in hard-delete guards for accounts/categories, while existing transaction-based `isReferenced` affordances remain unchanged in this iteration.
- Accounts preview rows are no longer swipe-delete surfaces; delete + undo live only on the dedicated shopping-list screen.
- Draft creation stays in the existing transaction add flow; Accounts does not introduce a separate `/accounts/shopping-list/new` route.
- Preview/full-list rows now use a non-empty fallback label policy instead of rendering memo-only blank rows.

---

## File Structure

**New files:**
- `lib/data/database/tables/shopping_list_items_table.dart`
- `lib/data/database/daos/shopping_list_dao.dart`
- `lib/data/models/shopping_list_item.dart`
- `lib/data/repositories/shopping_list_repository.dart`
- `drift_schemas/drift_schema_v3.json` _(auto-generated)_
- `test/unit/repositories/_harness/generated/schema.dart` _(auto-generated)_
- `test/unit/repositories/_harness/generated/schema_v3.dart` _(auto-generated)_
- `lib/features/shopping_list/shopping_list_state.dart`
- `lib/features/shopping_list/shopping_list_controller.dart`
- `lib/features/shopping_list/shopping_list_providers.dart`
- `lib/features/shopping_list/shopping_list_screen.dart`
- `lib/features/shopping_list/widgets/shopping_list_card.dart`
- `test/unit/repositories/shopping_list_repository_test.dart`
- `test/unit/controllers/shopping_list_controller_test.dart`
- `test/unit/controllers/transaction_form_shopping_list_test.dart`
- `test/widget/features/shopping_list/shopping_list_card_test.dart`
- `test/widget/features/shopping_list/shopping_list_screen_test.dart`
- `test/widget/features/transactions/transaction_form_shopping_list_button_test.dart`
- `test/widget/features/transactions/transaction_form_shopping_list_mode_test.dart`
- `test/integration/shopping_list_path_test.dart`

**New files (Task 8):**
- `test/widget/features/home/home_shopping_list_fab_test.dart`
- `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart`

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

**Goal:** Create durable storage for shopping-list drafts and preserve the planned transaction date plus any amount-backed draft currency when a form is saved as a draft.

**Files:**
- Create: `lib/data/database/tables/shopping_list_items_table.dart`
- Create: `lib/data/database/daos/shopping_list_dao.dart`
- Create: `lib/data/models/shopping_list_item.dart`
- Modify: `lib/data/database/app_database.dart`
- Modify: `test/unit/repositories/migration_test.dart`
- Regenerate: `test/unit/repositories/_harness/generated/schema.dart`
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
- [ ] Treat `draft_amount_minor_units` + `draft_currency_code` as an all-or-nothing nullable pair. Both fields are null for zero-amount drafts, or both are non-null for amount-bearing drafts. A non-null currency code must resolve through the existing `currencies` table.
- [ ] Add DAO helpers for the main CRUD/read paths plus `countByAccount` and `countByCategory`, because account/category repositories need them for shopping-list-specific delete guards.
- [ ] Register the table and DAO in `AppDatabase`, bump `schemaVersion` to 3, and create the table in `onUpgrade` for `from < 3`.
- [ ] Regenerate Drift/codegen artifacts and the full migration harness artifacts for schema v3, including the helper aggregator in `test/unit/repositories/_harness/generated/schema.dart`.
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

**Goal:** Implement the shopping-list repository and make account/category hard-delete guards count shopping-list drafts.

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
  - `convertToTransaction(...)`
- [ ] Wire `shoppingListRepositoryProvider` from `lib/app/providers/repository_providers.dart` with the shared `AppDatabase` plus the minimal same-layer collaborators needed for validation and conversion so draft CRUD and transaction conversion run against the same database instance.
- [ ] Explicitly document one narrow repository-composition exception for this feature: `ShoppingListRepository` may depend on `TransactionRepository` for conversion because both live in the data layer and share the same `AppDatabase` override. This exception exists only to preserve transaction-write invariants in one place; it does not broaden controller/widget access or permit arbitrary cross-layer writes.
- [ ] Enforce the cross-column invariant: `draft_amount_minor_units` and `draft_currency_code` must either both be null or both be non-null.
- [ ] Define one canonical zero-amount mapping for draft persistence:
  - when the current form amount is `0`, persist `draft_amount_minor_units = null`
  - when the current form amount is `0`, persist `draft_currency_code = null`
  - only persist amount + currency together when `amount > 0`
  - when hydrating a draft with null amount/currency, reseed the visible `displayCurrency` from the selected account until the user enters an amount or manually changes currency
  - this is the intentional boundary for currency preservation in this iteration: zero-amount drafts preserve account/category/date/memo only, not a separate preferred currency
- [ ] Add explicit shopping-list-aware delete guards to `AccountRepository.delete` and `CategoryRepository.delete`, but **do not** broaden `isReferenced` / `watchIsReferenced`. Existing transaction-backed affordance and mutation semantics stay unchanged for now.
- [ ] Explicitly decide that shopping-list drafts also participate in category-type locking for this iteration. Update the category repository guard/tests so a category referenced by either a transaction or a shopping-list draft cannot change from expense to income (or vice versa).
- [ ] Make expense-only a repository-owned invariant too: `ShoppingListRepository.insert/update` must reject non-expense categories even if a caller bypasses the form-level guard.
- [ ] Re-check conversion-only invariants in the repository too: `ShoppingListRepository.convertToTransaction(...)` must reject missing or archived account/category refs before calling `TransactionRepository.save(...)`, because the existing transaction repository does not own archive validation.
- [ ] Make `ShoppingListRepository.convertToTransaction(...)` the single owner of draft conversion. Define the composition explicitly:
  - the API accepts `shoppingListItemId` plus the current validated form snapshot, so `Save to transaction` converts the in-memory form state and does **not** require a preceding `saveDraft()` write
  - inside one `AppDatabase.transaction`, first confirm the draft row still exists, then build a new domain `Transaction(id: 0, ...)` from the supplied snapshot
  - call the injected `TransactionRepository.save(...)` to create the real transaction row so currency FK checks, timestamp behavior, read-back semantics, and future transaction-write fixes remain centralized in one place
  - after `TransactionRepository.save(...)` succeeds, delete the draft row by id inside the same DB transaction; treat a zero-row delete as a failure that aborts the whole transaction
  - return the saved `Transaction` from `convertToTransaction(...)`
  - do **not** duplicate transaction insert SQL, timestamp logic, or row-to-domain mapping inside `ShoppingListRepository`
- [ ] Update repository tests so an account/category with shopping-list rows but no transactions still cannot hard-delete, while existing `isReferenced`-driven affordances continue to mean "referenced by transactions" only.

**Patterns to follow:**
- `lib/data/repositories/account_repository.dart`
- `lib/data/repositories/category_repository.dart`
- `lib/data/repositories/transaction_repository.dart`
- `test/unit/repositories/account_repository_test.dart`
- `test/unit/repositories/category_repository_test.dart`
- `test/unit/repositories/transaction_repository_test.dart`

**Test scenarios:**
- Happy path: insert/update/delete round-trip a shopping-list item with memo, amount, currency, and date intact.
- Edge case: zero-amount draft persists as null amount/null currency and rehydrates with account-seeded display currency.
- Error path: inserting an amount without a currency throws `ShoppingListRepositoryException`.
- Error path: inserting/updating a draft with an income category is rejected at the repository layer.
- Error path: converting a missing/deleted draft throws a typed repository error and leaves `transactions` unchanged.
- Integration: `convertToTransaction(...)` converts the current form snapshot without requiring a prior draft-save, and the returned row round-trips through `TransactionRepository.getById` with the supplied date/currency/memo/account/category intact.
- Integration: deleting an account referenced only by shopping-list drafts throws the same in-use exception path used for transactions.
- Integration: deleting a category referenced only by shopping-list drafts is blocked and reported as referenced.
- Integration: changing a category type that is referenced only by shopping-list drafts is blocked by the same repository invariant used for transaction-backed categories.
- Integration: conversion is atomic; if draft deletion would fail, neither the new transaction nor the draft mutation commits.

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
- Create: `test/widget/features/shopping_list/shopping_list_card_test.dart`

- [ ] Add slice-local providers for:
  - preview rows
  - archived-safe account/category label hydration
  - derived row text (primary label, secondary metadata, date + optional amount)
- [ ] Keep the Accounts card as the first sliver even when there are no accounts; move the account empty state into an inline sliver below it.
- [ ] Make preview rows tap-only. Do **not** attach swipe-delete or undo behavior to the Accounts card.
- [ ] Define the non-empty card IA explicitly:
  - sort by newest `created_at` first
  - show at most 3 preview rows
  - row tap routes to `/accounts/shopping-list`
  - header CTA (`View all`) routes to `/accounts/shopping-list`
  - footer overflow CTA uses `shoppingListItemsMore(count)` and also routes to `/accounts/shopping-list`
- [ ] Use a single, explicit row-content rule everywhere the plan references preview/full-list rows:
  - primary label: `memo` when present, otherwise category name
  - secondary metadata: category + account names
  - trailing metadata: always show the stored draft date; append formatted amount when present
- [ ] Keep the empty-card CTA routed to `/home/add` so draft creation still starts in the existing transaction form.
- [ ] Keep the card chrome visible in all preview states:
  - loading: inline progress inside the card body
  - error: inline generic error copy inside the card body, with the card still tappable to `/accounts/shopping-list`
- [ ] Keep cross-screen delete state simple: Accounts preview stays on repository truth only. During the dedicated-list undo window, the preview may still show a row until delete commits or undo resolves.

**Patterns to follow:**
- `lib/features/accounts/accounts_screen.dart`
- `lib/features/accounts/accounts_providers.dart`

**Test scenarios:**
- Happy path: Accounts always renders the shopping-list card before the account section.
- Edge case: preview row falls back to category name when memo is empty.
- Edge case: archived account/category still resolve names for preview rows.
- Edge case: a row pending delete on `ShoppingListScreen` can remain visible in Accounts preview until the repository delete commits.
- Integration: preview shows 3 newest rows and the overflow CTA text/count for additional rows.
- Integration: tapping a non-empty preview row opens `/accounts/shopping-list`, not the draft form directly.
- Integration: tapping the empty CTA opens `/home/add`.

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
- Create: `test/widget/features/shopping_list/shopping_list_screen_test.dart`

- [ ] Keep `ShoppingListController` focused on the dedicated screen only. Implement it as a route-owned `@riverpod` auto-dispose notifier that watches all rows, manages a 4-second delete/undo window, and exposes one listener/effect path because only `ShoppingListScreen` owns it.
- [ ] Do not register `ShoppingListController` from `ShoppingListCard`; the preview card should stay on lightweight providers.
- [ ] Reuse the same derived row-content policy from Task 3 so the dedicated list and preview card cannot drift.
- [ ] Keep swipe-delete + undo snackbar only on `ShoppingListScreen`, and add a visible non-swipe delete affordance (for example an overflow/menu action) so delete is not gesture-only.
- [ ] Keep `ShoppingListController` screen-scoped to the dedicated shopping-list route, and define the lifetime contract explicitly around `StatefulShellRoute.indexedStack`:
  - `/accounts/shopping-list` is the **only** route that watches the controller; Accounts preview and the nested draft-edit modal never create their own controller instance
  - the auto-dispose lifetime is safe here because `StatefulShellRoute.indexedStack` keeps `/accounts/shopping-list` mounted while switching shell tabs, and the child `/accounts/shopping-list/:id` modal is presented on `_rootNavigatorKey`, leaving the list route mounted underneath
  - while `/accounts/shopping-list` remains in the branch stack, the controller/timer survive ordinary rebuilds, tab switches, and the child `/accounts/shopping-list/:id` modal sitting above it
  - pending delete is guaranteed to cancel only when the shopping-list route itself is popped/replaced and the controller disposes
  - switching tabs or obscuring the route with preserved shell state does **not** implicitly cancel the timer
  - `ShoppingListScreen` attaches and clears the controller effect listener from `initState` / `dispose`, mirroring `HomeScreen`, so snackbar ownership remains exclusive to the dedicated list
  - add router/widget coverage that the controller is not disposed on tab switch or while `/accounts/shopping-list/:id` is open
  - if the product later wants tab-switch cancellation, that needs a separate route-visibility hook outside this iteration
- [ ] Resolve the modal-vs-undo interaction explicitly: do **not** allow opening `/accounts/shopping-list/:id` while a pending delete window is active on `ShoppingListScreen`. Whole-row taps are disabled until the timer commits or undo clears the pending delete, so the undo snackbar always remains actionable on the visible list surface.
- [ ] Use the same delayed-delete model as `HomeController`: hide immediately, commit repository delete only when the timer expires, and make undo clear pending state before delete runs. Do not add reinsertion-based undo behavior to the repository API.
- [ ] Make the dedicated list the only place that opens an existing draft into the reused transaction form.
- [ ] Define the dedicated-list interaction model explicitly:
  - sort by newest `created_at` first
  - whole-row tap opens `/accounts/shopping-list/:id`
  - delete uses swipe or the visible overflow/menu affordance, but never row tap
- [ ] Define non-data states for the dedicated list explicitly:
  - loading: centered progress
  - empty: empty-state CTA to `/home/add`
  - error: full-screen generic error copy with a primary Retry action; standard app-bar back navigation remains available

**Patterns to follow:**
- `lib/features/home/home_controller.dart`
- `lib/features/home/home_screen.dart`

**Test scenarios:**
- Happy path: deleting a row hides it immediately and commits repository delete after the undo window expires.
- Happy path: undo restores the row before repository delete runs.
- Error path: repository delete failure surfaces one error event/snackbar on `ShoppingListScreen`.
- Error path: repository delete failure restores the hidden row to the dedicated list so the UI returns to repository truth after the failed commit.
- Error path: the dedicated-list error surface offers Retry and resumes streaming rows when the retry succeeds.
- Edge case: the screen empty state CTA opens `/home/add`.
- Edge case: while a pending delete window is active, row taps are disabled and cannot open the draft modal.
- Integration: rows expose a non-gesture delete path in addition to swipe.
- Integration: preview rows do not subscribe to the controller and therefore cannot clear or steal its effect listener.
- Integration: popping the shopping-list route during the undo window cancels the pending delete; switching tabs does not rely on disposal-based cancellation.
- Integration: the controller/provider is still alive after a shell tab switch and while the nested draft-edit modal is open.

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
- Create: `test/widget/features/transactions/transaction_form_shopping_list_button_test.dart`
- Create: `test/widget/features/transactions/transaction_form_shopping_list_mode_test.dart`

- [ ] Extend `TransactionFormController` hydration modes so it can open in:
  - normal add
  - duplicate
  - edit existing transaction
  - edit existing shopping-list draft
- [ ] Replace ad-hoc route parsing with one typed form-mode contract passed from `router.dart` into `_AdaptiveTransactionFormRoute` and then `TransactionFormScreen`:
  - add transaction (`initialDate` optional)
  - duplicate transaction (`sourceTransactionId`)
  - edit transaction (`transactionId`)
  - edit shopping-list draft (`shoppingListItemId`)
- [ ] Derive hydration entrypoint, title, app-bar actions, inline shopping-list actions, delete visibility, and not-found handling from that single mode object instead of mixing `transactionId`, `widget.isEdit`, and raw `GoRouterState.extra` checks inside the screen.
- [ ] Store shopping-list draft context inside `TransactionFormState` so the form knows whether it is editing a real transaction or a shopping-list draft.
- [ ] Add draft-save commands directly to `TransactionFormController` instead of using a separate `ShoppingListFormController`.
- [ ] Add explicit action-level capability flags and commands so draft and transaction validity cannot drift:
  - `canSaveTransaction`
  - `canSaveDraft`
  - `canConvertDraft`
  - `saveTransaction()`
  - `saveDraft()`
  - `convertDraft()`
- [ ] Add an explicit submission-state contract for form actions:
  - track `submissionAction = none | saveTransaction | saveDraft | convertDraft`
  - while a submission is in flight, disable app-bar save, inline shopping-list actions, picker taps, and back/discard pop
  - show progress only on the active CTA and ignore repeated taps until the async action resolves
- [ ] Define the minimum valid shopping-list draft explicitly:
  - required: selected account, selected expense category, draft date
  - optional together: amount + currency
  - optional: memo
  - invalid: missing account, missing category, income category, amount without currency, currency without amount
- [ ] Keep validation and hint rules mode-aware:
  - transaction save continues to use the existing `amount > 0` contract and is the only path that drives `txAmountRequired`
  - draft save uses `canSaveDraft` and must not show transaction-only amount-required copy when a zero-amount draft is otherwise valid
  - draft conversion uses `canConvertDraft` and layers archived-reference blocking on top of normal transaction validity
- [ ] In brand-new add-transaction mode (`/home/add` without duplicate/edit context), disable the "Add to shopping list" action until the minimum valid draft fields are present.
- [ ] Keep duplicate and edit-existing-transaction flows unchanged for this iteration; they do **not** expose the shopping-list action.
- [ ] Show the income-category blocked hint only when the user is on an income category/type state and the shopping-list action is unavailable for that reason.
- [ ] Preserve `TransactionFormData.date` on every draft save/update and draft conversion.
- [ ] Preserve `TransactionFormData.displayCurrency` only when saving/updating a draft with `amount > 0`; zero-amount drafts intentionally persist no amount/currency pair and therefore rehydrate visible currency from the selected account on next load.
- [ ] When hydrating an existing draft with non-null `draft_currency_code`, resolve it with `CurrencyRepository.getByCode(draftCurrencyCode)` instead of re-inferring decimals from the selected account.
- [ ] When hydrating an existing draft with null amount/currency, seed the visible currency from the selected account until the user enters an amount or manually changes currency.
- [ ] Split missing-target handling by mode:
  - missing transaction edit/duplicate targets keep using the existing `TransactionFormEmptyReason.notFound` / `TransactionFormEmpty` flow
  - parsable-but-missing shopping-list draft ids do **not** render the empty state; they emit a one-shot draft-missing result token instead
  - define that token explicitly as a shopping-list-edit modal result distinct from `Transaction?` success and from ordinary `null` cancel/dismiss
  - `TransactionFormScreen` pops with that dedicated result token, and the parent `/accounts/shopping-list` screen awaits/interprets it to show the generic not-found snackbar after the modal closes
- [ ] Use one exact router-to-form contract for shopping-list draft editing:
  - `/accounts/shopping-list` is the parent review route
  - `/accounts/shopping-list/:id` is a child modal route under that parent
  - the router passes `shoppingListItemId` via constructor args into `_AdaptiveTransactionFormRoute`, then into `TransactionFormScreen`
  - shopping-list draft routes do **not** use `GoRouterState.extra`; `extra` remains reserved for existing add/duplicate transaction flows
  - because the draft-edit route is nested under `/accounts/shopping-list`, successful `context.pop()` always returns to the dedicated list
- [ ] Define one explicit result/exit contract for every shopping-list-related action:
  - `Add to shopping list` from `/home/add` or any other caller that pushed the add form: persists the draft, then `context.pop()` with no `Transaction` result so the route simply returns to the surface that opened it
  - `Save draft` while editing `/accounts/shopping-list/:id`: persists the draft, then `context.pop(ShoppingListEditResult.savedDraft)` back to `/accounts/shopping-list`
  - `Save to transaction` while editing `/accounts/shopping-list/:id`: converts the current in-memory form snapshot atomically without an intermediate draft-save, then `context.pop(ShoppingListEditResult.savedTransaction(savedTransaction))` back to `/accounts/shopping-list`
  - cancel/discard from `/home/add`: keep existing transaction-form discard behavior and return to the caller unchanged
  - cancel/discard from `/accounts/shopping-list/:id`: close the modal with `null`, which remains the ordinary no-mutation dismiss result
  - parsable-but-missing draft id on `/accounts/shopping-list/:id`: `context.pop(ShoppingListEditResult.missingDraft)` and let the parent list show the generic not-found feedback
- [ ] Define one exact launch contract for every CTA that opens `/home/add` for draft creation:
  - Home FAB already uses `context.push<Transaction>` and remains unchanged
  - Accounts empty-card CTA must also use push-style navigation so saving or discarding the form returns the user to Accounts
  - ShoppingListScreen empty-state CTA must use push-style navigation so saving or discarding the form returns the user to `/accounts/shopping-list`
  - when those non-Home callers use the normal transaction save path instead of draft save, the route still pops `Transaction`; the caller intentionally ignores that typed result and simply returns to the originating Accounts surface without auto-navigating to Home
- [ ] When converting a draft to a transaction:
  - call the repository-owned `ShoppingListRepository.convertToTransaction(...)` API from the form layer with the current in-memory form snapshot and `shoppingListItemId`
  - let `ShoppingListRepository.convertToTransaction(...)` compose on top of `TransactionRepository.save(...)` instead of re-implementing transaction-row writes
  - re-check archived/missing account/category refs in the repository immediately before conversion so UI gating is not the only enforcement layer
  - save the transaction with the draft's current `displayCurrency`
  - save the transaction with the draft's `date`
  - let the repository own the atomic DB transaction and rollback semantics
- [ ] In shopping-list edit mode, show explicit inline warning text for archived account/category references. Keep the picker controls tappable so the user can replace archived references. Draft save stays allowed; conversion stays disabled until archived references are replaced.
- [ ] Define the archived-account recovery path explicitly, mirroring the category escape hatch:
  - if the draft references an archived account but active accounts still exist, the existing account picker remains the replacement path
  - if the account picker has no active accounts to offer, keep the draft form mounted, replace the account picker body/CTA with inline recovery copy plus a `/accounts/new` launch action, and preserve `Save draft` while conversion remains disabled
  - do **not** fall back to `TransactionFormEmptyReason.noActiveAccount` for this archived-draft case; that full-screen empty state remains reserved for add/duplicate flows that truly cannot hydrate any account context at all
  - after `/accounts/new` closes, do **not** call the full retry-hydration path; instead re-check active-account availability and rebind only the account-specific fields/recovery state so in-progress memo/date/category/currency edits remain intact
  - if `/accounts/new` returns a saved account id, auto-select that new active account for the still-open draft form and clear the archived-account warning; if the route returns `null`, keep the archived account selected and leave conversion disabled until the user resolves it manually
- [ ] Define mode-specific transaction-form presentation so reuse stays understandable:
  - normal add/edit/duplicate transaction modes keep the existing app-bar title + app-bar `Save` as the primary transaction CTA
  - brand-new add-transaction mode keeps that app-bar `Save` for transaction creation and adds a secondary inline `Add to shopping list` action
  - edit shopping-list draft mode uses a shopping-list-specific title, removes the app-bar save/delete actions, and uses `Save to transaction` (primary) plus `Save draft` (secondary) in the inline action row as the only submit surface
  - delete is **not** available in the reused form; deletion stays exclusive to `ShoppingListScreen`
  - all shopping-list-specific actions live in one exact place: an inline action row directly below `MemoField`
  - brand-new add-transaction mode uses that inline row for a single `Add to shopping list` action
  - edit shopping-list draft mode uses that same inline row for `Save draft` and `Save to transaction`

**Patterns to follow:**
- `lib/features/transactions/transaction_form_controller.dart`
- `lib/features/transactions/transaction_form_screen.dart`
- `lib/features/home/home_screen.dart` for `context.push<T>()` / `context.pop(saved)` result flow

**Test scenarios:**
- Happy path: ordinary add-transaction form saves a draft and returns to the caller without creating a transaction.
- Happy path: Accounts empty-card CTA opens `/home/add` via push semantics and returns to Accounts after save/discard.
- Happy path: ShoppingListScreen empty-state CTA opens `/home/add` via push semantics and returns to `/accounts/shopping-list` after save/discard.
- Happy path: shopping-list edit mode hydrates memo, amount, currency, date, account, and category from an existing draft.
- Happy path: saving a draft preserves a user-selected currency that differs from the selected account currency.
- Happy path: converting a draft creates a transaction with the stored date/currency and removes the draft afterward.
- Happy path: typed route mode drives the correct hydration path, title, CTA set, and delete visibility for add, duplicate, edit-transaction, and edit-draft flows.
- Happy path: `/accounts/shopping-list/:id` returns `ShoppingListEditResult.savedDraft` and `ShoppingListEditResult.savedTransaction(...)` distinctly from ordinary `null` dismiss.
- Error path: conversion failure leaves the draft untouched.
- Error path: invalid draft states keep the shopping-list action disabled or rejected with the documented inline hint.
- Error path: while `submissionAction` is active, repeat taps and pop/discard attempts are ignored until the action resolves.
- Edge case: archived category/account shows warning text, allows draft save, and blocks conversion.
- Edge case: archived account with no active replacements routes the user through `/accounts/new`; a returned account id is auto-selected without wiping in-progress edits, while a `null` return leaves the archived account selected and conversion disabled.
- Edge case: no active account still uses the existing transaction-form empty-state CTA.
- Edge case: valid route id with a missing/deleted draft returns to `/accounts/shopping-list` with parent-surface not-found feedback instead of rendering the generic empty form.
- Integration: no visible expense categories still follow the existing picker redirect to category management instead of creating a shopping-list-specific dead-end.
- Integration: `/accounts/shopping-list/:id` opens the reused form through constructor-arg draft mode and returns to `/accounts/shopping-list` on `context.pop()`.
- Integration: the parent shopping-list screen distinguishes `null` dismiss from `ShoppingListEditResult.missingDraft` and only shows the not-found snackbar for the latter.
- Integration: `Add to shopping list`, `Save draft`, and `Save to transaction` each follow the documented pop/result contract exactly.

**Verification:**
- The plan has one source of truth for keypad, date, currency, and form validation.
- The plan has one source of truth for form mode selection; the screen no longer invents mode from scattered route checks.
- `ShoppingListFormController`, `ShoppingListItemController`, and `ShoppingListItemScreen` are no longer part of the implementation.
- Delete ownership is unambiguous: only `ShoppingListScreen` deletes drafts.

---

## Task 6: Routing and Localization

**Goal:** Route shopping-list flows through the existing adaptive transaction-form shell and keep localization keys aligned with real UI behavior.

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `test/unit/app/router_test.dart`
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`

- [ ] Add `/accounts/shopping-list` and nested `/accounts/shopping-list/:id` routes before the existing `/accounts/:id` catch-all.
- [ ] Reuse the same adaptive modal/dialog behavior already used by `_AdaptiveTransactionFormRoute` instead of creating a separate shopping-list-only screen shell.
- [ ] Make navigator ownership explicit:
  - `/accounts/shopping-list` stays on the Accounts branch navigator
  - `/accounts/shopping-list/:id` uses `parentNavigatorKey: _rootNavigatorKey` and `_AdaptiveTransactionFormRoute(shoppingListItemId: ...)` so wide layouts reuse the existing dialog treatment and the dedicated list route remains mounted underneath
- [ ] Split bad-id handling explicitly:
  - non-parsable `/accounts/shopping-list/:id` values redirect in the router back to `/accounts/shopping-list`
  - parsable-but-missing ids are handled by the form-mode draft-missing effect described in Task 5, with `/accounts/shopping-list` owning the snackbar after the modal returns
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
- Happy path: `/accounts/shopping-list` and nested `/accounts/shopping-list/:id` route before `/accounts/:id`.
- Edge case: invalid `shopping-list/:id` redirects back to `/accounts/shopping-list`.
- Integration: wide layouts render shopping-list draft routes in the same constrained dialog treatment as `/home/add`.
- Integration: router tests cover the nested `/accounts/shopping-list/:id` stack returning to `/accounts/shopping-list` on pop.
- Integration: router/widget tests prove `/accounts/shopping-list` stays mounted under the root-navigator modal route.
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
  - open dedicated shopping-list screen from the Accounts card
  - open draft into the reused transaction form from the dedicated list
  - convert draft to transaction
  - return to dedicated list screen
  - draft disappears from the shopping list
  - manual navigation to Home shows the new transaction
- [ ] Add a second row-display assertion path for a draft with no memo so the category-name fallback is tested explicitly.
- [ ] Add an Accounts-preview assertion path that verifies preview ordering, 3-row truncation, and the overflow CTA into `/accounts/shopping-list`.
- [ ] Add one route-state assertion path for a deleted/missing draft id so the app returns cleanly to `/accounts/shopping-list`.
- [ ] Keep the file inventory aligned with the tasks above; do not list test files that are never authored.
- [ ] Run full verification after codegen/formatting:
  - format
  - targeted unit/widget/integration tests
  - full `flutter test`
  - `flutter analyze`
- [ ] Manual smoke test checklist:
  - Add Transaction → Add to shopping list → form closes → navigate to Accounts → Accounts card shows draft
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
- Integration: each shopping-list-related form action follows its documented exit/result behavior.

**Verification:**
- The plan's file inventory matches the actual implementation units.
- Final smoke checklist matches the revised route behavior.

---

## Task 8: Home Shopping-List FAB and Card Add Button

**Goal:** Let users reach and create shopping-list drafts without navigating away from their current surface — a persistent count button on Home and an always-visible "Add" affordance on the Accounts card.

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/shopping_list/widgets/shopping_list_card.dart`
- Modify: `lib/features/shopping_list/shopping_list_providers.dart`
- Create: `test/widget/features/home/home_shopping_list_fab_test.dart`
- Create: `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart`

### Shopping-list count button on Home

- [x] Add a provider `shoppingListTotalCountProvider` in `shopping_list_providers.dart` that watches the total row count from `ShoppingListRepository` and exposes `AsyncValue<int>`. Reuse the repository's `watchAll()` stream and derive the count from `list.length` — do not add a new DAO query.
- [x] In `HomeScreen`, render a mini `FloatingActionButton` to the **left** of the existing extended FAB using a `Row` with `mainAxisSize: MainAxisSize.min` as the `floatingActionButton` widget. Keep the same `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat` (the default).
  - The mini FAB uses `heroTag: 'home_shopping_list_fab'`.
  - Icon: `Icons.shopping_cart_outlined` (or similar cart icon).
  - When the total count is `> 0`, overlay a `Badge` (Material 3 `Badge` widget) on the icon showing the count. Clamp the displayed number at 99 — show `"99+"` for counts above 99.
  - When the total count is `0`, show no badge (render the icon without a `Badge` wrapper, or use `Badge(isLabelVisible: false, ...)`).
  - While the count is loading (`AsyncLoading`), show the icon without a badge (treat loading as 0 for badge visibility; do not show a spinner on the FAB).
  - On tap: `context.go('/accounts/shopping-list')`.
  - Maintain an 8 dp horizontal gap between the mini FAB and the extended FAB.
- [x] Do **not** remove, resize, or reposition the existing extended FAB. The layout must not break at the adaptive ≥600 dp breakpoint (both FABs remain visible in the wide layout).

### "Add" icon button in the non-empty ShoppingListCard header

- [x] In `ShoppingListCard`, add an `IconButton` (icon: `Icons.add`) to the card header row — positioned **between** the title and the `TextButton("View all")` — in **all** card states: loading, error, empty, and non-empty.
  - The button is always rendered (not conditional on `preview.isEmpty`).
  - On tap: `context.push('/home/add')` (push semantics, identical to the existing empty-state CTA).
  - Tooltip: `l10n.shoppingListEmptyCta` (reuse existing key; it already reads "Add to shopping list" or equivalent).
- [x] Keep the "View all" `TextButton` at the far right; the add `IconButton` sits immediately to its left.
- [x] Keep the `_EmptyBody` section intact — it provides body-level copy and CTA when no drafts exist; the header button is a supplementary shortcut, not a replacement.

**Patterns to follow:**
- `lib/features/home/home_screen.dart` — FAB wiring and `floatingActionButtonLocation`
- `lib/features/shopping_list/widgets/shopping_list_card.dart` — existing header `Row` layout
- `lib/features/shopping_list/shopping_list_providers.dart` — existing preview provider pattern

**Test scenarios:**
- Happy path: when `shoppingListTotalCountProvider` emits `3`, the Home FAB badge shows "3".
- Happy path: when count is `0`, the Home FAB renders with no visible badge label.
- Happy path: when count exceeds 99, the badge label shows "99+".
- Happy path: tapping the Home shopping-list FAB navigates to `/accounts/shopping-list`.
- Happy path: the `Add` icon button in the `ShoppingListCard` header is always present regardless of preview state (empty, loading, non-empty).
- Happy path: tapping the card header "Add" button opens `/home/add` via push (returns to Accounts on pop).
- Integration: Home FAB `Row` layout does not overlap or displace the existing extended FAB at narrow or wide breakpoints.

**Verification:**
- Both FABs are visible simultaneously on the Home screen.
- The "Add" icon appears in the card header in all preview states.
- No new DAO SQL queries are introduced; `shoppingListTotalCountProvider` derives its value from the existing `watchAll()` stream.

---

**Plan complete and revised in `docs/superpowers/plans/2026-05-01-shopping-list.md`.**
