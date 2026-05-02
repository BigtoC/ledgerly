# Shopping List — Design Spec

**Date:** 2026-05-01  
**Status:** Draft  
**Scope:** Add a draft shopping list anchored in Accounts, with a count shortcut on Home and a dedicated item editor/completion screen.

## Overview

This feature adds a lightweight shopping list to Ledgerly. Users can capture future expense items from the transaction form without creating real transactions, review those drafts from the Accounts tab, and later convert a draft into an actual expense transaction.

Shopping list items are always expense-oriented draft records. They are intentionally separate from real transactions so Ledgerly keeps its current transaction invariants unchanged:
- real transactions always use integer minor-unit amounts
- `transactions` never store draft-only zero-amount placeholders
- Home continues to render only committed transactions for a selected day

The shopping list is modeled as a new draft table, a new repository, a full list screen, and an item editor screen. The Accounts tab hosts a 3-item card preview; a dedicated `ShoppingListScreen` hosts the full scrollable list and swipe-delete surface. Home only exposes a count shortcut when drafts exist.

## 1. User Flow

### 1.1 Add draft from transaction form

From `Add Transaction`:
- The form gains a secondary action below `Memo`: **Add to shopping list**
- Tapping it immediately creates a shopping-list draft and closes the form
- The action does **not** create a transaction

Saved draft fields:
- category
- account
- memo
- optional draft amount if one was already entered
- optional draft currency if a non-account currency was already selected

Product rules:
- shopping-list items are always expense entries
- category must be an expense-type category; income categories are blocked at validation with an inline hint
- category and account are required to save a draft
- memo may be empty
- draft amount may be empty/zero
- rapid repeated taps on `Add to shopping list` should be guarded against duplicate inserts by disabling the action or serializing the save; the same duplicate-insert guard applies to `Save draft` on the item screen

Repository behavior:

- insert a `shopping_list_items` row
- return success/failure to the controller

Screen behavior:
- on success, close the form immediately
- on failure, remain on form and surface a snackbar

### 1.2 Home shortcut

Home shows a circular count shortcut to the left of the existing extended FAB only when the shopping-list count is greater than zero.

Behavior:
- count == 0 -> shortcut hidden
- count > 0 -> circular button visible with the item count
- tapping the shortcut navigates to `/accounts/shopping-list` (the full shopping list screen)

Home must not render shopping-list item rows. The count shortcut should reactively update from a separate `shoppingListCountProvider` (`@Riverpod(keepAlive: false, dependencies: [shoppingListRepository]) Stream<int>`) backed by `ShoppingListRepository.watchCount()`. `HomeController` and its `_Composer` are not modified; `HomeScreen` watches `shoppingListCountProvider` directly and renders the circular button conditionally.

### 1.3 Edit existing draft

The shopping-list item screen opens with:
- category
- account
- memo
- optional draft amount

Separate actions:
- `Save draft` updates only the shopping-list row
- `Save to transaction` converts the draft into a real transaction

### 1.4 Draft amount and currency

If the user enters a draft amount in a different currency from the selected account, the shopping-list item should preserve that chosen currency alongside the draft amount.

Therefore:
- `draftAmountMinorUnits` may be null
- `draftCurrencyCode` may be null, but must be present whenever draft amount is present

This keeps the feature aligned with Ledgerly's existing minor-unit money policy while still allowing the user to capture the intended transaction currency.

On the item screen, the explicit draft currency is sticky — it persists until the user selects a different account, at which point the currency is re-inferred from the new account and the draft currency is overwritten. This avoids exposing a separate currency picker while still preserving a currency captured in the transaction form.

The cross-column invariant (non-null currency required when amount is non-null) is enforced in `ShoppingListRepository.insert()` and `ShoppingListRepository.update()` only. The Drift table definition does not include a database-level CHECK constraint because Drift's type-safe DSL does not support cross-column nullable constraints.

### 1.5 Convert to transaction

Conversion should build a normal `Transaction` from the shopping-list item.

Required fields on conversion:
- amount > 0
- category
- account
- currency (use draft currency when present, otherwise infer from account)
- date = current local date automatically

Repository boundary:
- `ShoppingListRepository` owns shopping-list CRUD and count/watch APIs
- `TransactionRepository` remains the only writer for real transactions
- the final transaction write should go through `TransactionRepository.save(...)`, the same standard save path used for normal transactions

Deletion rule:
- delete the shopping-list draft only after the transaction save succeeds
- never delete the draft first
- this is intentionally sequential, not atomic: if a crash occurs between the two steps, the user is left with both a committed transaction and a surviving draft; the draft can be safely deleted manually and cannot create a duplicate transaction without an explicit user action

## 2. Architecture

Shopping list should be implemented as a dedicated feature slice, not as ad hoc logic inside `accounts/`.

Recommended structure:
- new data model: `ShoppingListItem`
- new Drift table + DAO + repository: `shopping_list_items`
- new feature slice: `lib/features/shopping_list/`
- `AccountsScreen` remains the primary list host surface, but renders the shopping-list card from shopping-list providers/controllers
- `HomeScreen` watches `shoppingListCountProvider` directly for the circle shortcut; `HomeController` is not modified
- the item editor/completion flow lives in its own screen/route
- `ShoppingListFormController`: lives in `lib/features/shopping_list/shopping_list_form_controller.dart`; annotated `@Riverpod(dependencies: [transactionFormController, shoppingListRepository])`; reads form state (category, account, amount, currency) from existing providers, owns `addToShoppingList()`, and emits a typed navigation effect on success — the transaction form screen listens via `ref.listen` and calls `context.pop()`; does not modify `TransactionFormController`

Implementation notes:
- register `ShoppingListItems` table and `ShoppingListDao` in the `@DriftDatabase` annotation in `lib/data/database/app_database.dart`, then run `dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`
- register `DriftShoppingListRepository` in `lib/app/providers/repository_providers.dart` as `@Riverpod(keepAlive: true, dependencies: [appDatabase])` and reference `shoppingListRepositoryProvider` in every controller that reads it

Why this shape is preferred:
- `AccountsScreen` already has enough responsibility; adding item editing ownership there would tangle unrelated concerns
- import rules forbid features from reaching into repositories directly, so a dedicated shopping-list controller/provider keeps the same boundary pattern as the rest of the repo
- `TransactionFormController` should remain focused on real transaction save/edit/duplicate flows; adding a second mutation path for shopping drafts would fight its current `canSave` contract
- a shopping-list-specific editor can still reuse visual widgets from `lib/features/transactions/widgets/` (category picker, account picker, memo field, calculator keypad) where sensible, while keeping commands explicit:
  - `ShoppingListFormController.addToShoppingList()` (transaction form only)
  - `ShoppingListItemController.saveDraft()`
  - `ShoppingListItemController.saveToTransaction()`
  - `ShoppingListItemController.delete()`

Screen boundaries:
- `Home`: count shortcut only (taps → `/accounts/shopping-list`)
- `Accounts`: shopping-list card + 3-item preview only
- `ShoppingListScreen`: full scrollable list of all items at `/accounts/shopping-list`; includes a FAB to create a new item; this is the primary swipe-delete surface for all items
- `ShoppingListItemScreen`: create/edit/complete one item
- Router: declare `/accounts/shopping-list`, `/accounts/shopping-list/new`, and `/accounts/shopping-list/:id` **before** the existing `/accounts/:id` catch-all route to avoid `go_router` matching `shopping-list` as an integer account ID; item routes use `parentNavigatorKey: _rootNavigatorKey` for modal presentation, matching the existing `/accounts/new` pattern; both item routes resolve to `ShoppingListItemScreen` — `/new` opens with blank fields, `/:id` loads the existing item by ID

Localization: add ARB keys to `app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, and `app_zh_TW.arb` for all new strings before running `build_runner` (e.g. `shoppingListAddToDrafts`, `shoppingListSaveDraft`, `shoppingListSaveToTransaction`, `shoppingListCardTitle`, `shoppingListEmptyState`, `shoppingListScreenTitle`).

## 3. Data Model and Lifecycle

Shopping-list items should be first-class draft records, not disguised transactions.

Recommended model fields:
- `id`
- `categoryId`
- `accountId`
- `memo`
- `draftAmountMinorUnits` (nullable)
- `draftCurrencyCode` (nullable; required when draft amount exists; inferred from account on the item screen if absent)
- `createdAt`
- `updatedAt`

Notable omissions:
- no `type` field, because these items are always expense drafts by product rule
- no `date`, because the real transaction date is the completion date
- no embedded account/category/currency objects in the base model; repositories can map IDs/codes into richer view models upstream as needed

### 3.1 Create draft from transaction form

See Section 1.1 for validation rules, repository behavior, and screen behavior for this flow.

Controller guard: `ShoppingListFormController.addToShoppingList()` reads `TransactionFormController`'s current state via its provider. If the form is not in a `TransactionFormData` state, the method returns immediately without side effects.

### 3.2 Edit existing draft

See Section 1.3 for the fields and actions available on the item screen.

The item screen must not expose a separate currency picker. The draft currency is sticky: an explicit draft currency captured from the transaction form persists until the user changes the account, at which point the currency is re-inferred from the new account and overwrites the previous value. When no explicit draft currency exists, the currency is always inferred from the selected account. The user may save edits back to the shopping-list item independently from conversion.

### 3.3 Draft amount and currency

See Section 1.4 for the draft amount and currency invariants.

### 3.4 Convert to transaction

See Section 1.5 for conversion requirements, repository boundary, and deletion rule.

### 3.5 Schema migration

Adding `shopping_list_items` requires a Drift schema version bump:
- increment `schemaVersion` to 3 in `lib/data/database/app_database.dart`
- add a `from < 3` branch in `onUpgrade` that calls `m.createTable(shoppingListItems)`
- run `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/` to commit the v3 snapshot
- add a migration test covering the v2 → v3 path on both empty and seeded databases

## 4. UI, Errors, and Testing

### 4.1 Home UI

Home keeps the existing extended FAB.

When shopping-list count > 0:
- render a small circular action immediately to the left of the FAB (minimum 44×44dp touch target); `Scaffold.floatingActionButton` accepts a single widget — wrap both buttons in a `Row` with `mainAxisSize: MainAxisSize.min` and assign a distinct non-null `heroTag` to each to prevent the default hero animation conflict
- display only the count; if count exceeds 99, display `99+`
- tap navigates to `/accounts/shopping-list`
- accessibility: semantic label must read "{count} shopping list items"

When count == 0:
- hide the circle completely

The circle is driven by `HomeScreen` watching `shoppingListCountProvider` directly. `HomeController` is not modified.

Home must not become a second shopping-list surface.

### 4.2 Accounts UI

Insert a shopping-list card as the first sliver in the Accounts `CustomScrollView`, before the empty-account guard (the guard at `accounts_screen.dart:67-91` returns a full-screen empty state when no active accounts exist; the shopping-list card must be inserted before that check so it renders regardless of account count).

Card should show:
- title
- item count
- compact item preview list (show up to 3 items, then a tappable remaining-count label, e.g. `+ 4 more`; tapping navigates to `/accounts/shopping-list`; the card title area is also tappable to `/accounts/shopping-list` when items exist)
- each preview row shows: category name + memo if non-empty, or category name only if memo is empty; draft amount shown if present
- loading state: skeleton placeholder (same style as existing account card loading state) before the stream emits
- empty state: the card is always rendered; when no items exist, display a placeholder message and a faint "Add item" affordance; tapping the empty card navigates to `/accounts/shopping-list/new`

Row interactions:
- tap row -> open shopping-list item screen
- swipe left -> delete item (triggers optimistic delete with undo snackbar; see Section 4.4)

The card should respect the repo's existing card padding constants so it visually fits the Accounts layout. Swipe rows must sit inside the existing `SlidableAutoCloseBehavior` scope already wrapping `AccountsScreen`.

### 4.3 Shopping-list item screen

The item screen is the single place for:
- creating a draft
- editing a draft
- converting a draft into a transaction

Fields:
- category
- account
- memo
- optional amount/currency

Primary actions:
- `Save draft`
- `Save to transaction`

Enablement:
- `Save draft` requires category and account (expense-type category only)
- `Save to transaction` requires category, account, and amount > 0; when amount is present, a resolved draft currency must also be available (inferred from explicit draft currency or account)
- when `Save to transaction` is disabled (amount missing or zero), it renders visually greyed out; tapping shows an inline hint below the amount field indicating what is required

Currency display: the draft currency is sticky — an explicit draft currency persists until the user changes the account. Changing the account re-infers the currency from the new account and overwrites the previous draft currency immediately (no warning dialog required).

Layout: uses `Scaffold(resizeToAvoidBottomInset: false)` → `SafeArea` → `Column` with a scrollable form `Expanded` above a fixed-height `CalculatorKeypad`, following the Add/Edit Transaction layout primitive from CLAUDE.md. The amount field displays the value driven by the keypad, not a text input.

Archived references: if a referenced category or account is archived, display a warning badge next to the affected field. `Save draft` remains allowed. `Save to transaction` is blocked until the user selects a valid replacement category or account.

Back navigation: if the user navigates back with unsaved edits, discard changes silently (no confirmation dialog). The draft is not auto-saved.

Because completion date is automatic, the screen should not expose a date picker.

### 4.4 Error handling

Add-to-shopping-list from transaction form:
- if category/account missing, block save and show inline hints
- if repository fails, show snackbar and remain on form

Delete from shopping list:
- swipe-left on a row triggers optimistic delete with a 4-second undo snackbar
- if the user taps undo, re-insert the item via `insertOnConflictUpdate` (upsert by primary key) to restore the original item ID; if the undo window expires, finalize deletion
- surface repository failures via snackbar

Convert to transaction (failure):
- if `TransactionRepository.save()` fails, keep the shopping-list item intact and remain on the item screen
- surface the failure as a snackbar; the user may retry by tapping `Save to transaction` again
- do not delete the draft on failure

Missing / deleted item:
- show recoverable not-found state and return user to the prior surface

Archived / invalid references:
- if a referenced category or account becomes archived or otherwise unavailable, the shopping-list item remains visible
- `Save to transaction` is blocked; show a warning badge on the affected field so the user can select a valid replacement
- `Save draft` remains allowed with an archived reference

### 4.5 Testing expectations

Repository tests:
- create / update / delete shopping-list item
- count and watch streams re-emit correctly
- draft amount and currency invariants
- conversion does not delete item when transaction save fails

Controller tests:
- `ShoppingListFormController.addToShoppingList()`: blocks on income-type category; blocks when controller is not in data state; disables action after first tap until result returns
- `ShoppingListItemController.saveDraft()` vs `saveToTransaction()` behavior
- `ShoppingListItemController.saveToTransaction()` leaves draft intact when `TransactionRepository.save()` fails
- archived category/account blocks `saveToTransaction()` but not `saveDraft()`
- `shoppingListCountProvider` reacts to create/delete changes
- error propagation stays typed and observable

Widget tests:
- Home shortcut hidden at zero and visible otherwise; count label shows `99+` at 100; tapping shortcut navigates to `/accounts/shopping-list`; FAB Row renders without hero animation conflict (distinct heroTags)
- Accounts card ordering (shopping-list above accounts), loading state, empty state tappable, compact preview content
- Accounts card `+ N more` label is tappable and navigates to `/accounts/shopping-list`
- `ShoppingListScreen`: all items listed; swipe-left delete triggers undo snackbar; undo re-inserts item
- item screen: `Save to transaction` greyed out when amount is zero; archived reference shows warning badge; `Save draft` still enabled with archived reference
- back navigation discards changes silently

Integration / path tests:
- Add Transaction -> Add to shopping list -> Accounts card shows item -> open item -> Save to transaction -> item disappears -> transaction appears on Home

## 5. Open Decisions

- `Add to shopping list` should be rendered as a secondary text-style action rather than a filled primary button; exact widget type can be finalized during implementation.

## 6. Out of Scope

The following are explicitly out of scope for this feature:
- no date field stored on shopping-list items
- no manual completion-date picker on convert
- no multi-item batch convert
- no shopping-list rows on Home
- no reuse of Phase 2 pending-transactions table for shopping-list drafts
- no changes to existing transaction save invariants

## 7. Success Criteria

The feature is successful when:
- users can save a shopping-list draft directly from the transaction form
- Home shows a count shortcut only when drafts exist
- Accounts shows a shopping list top card with preview, edit, delete, and convert paths
- users can update a draft independently from converting it
- conversion creates a real expense transaction and removes the draft in sequence on success (transaction saved first, draft deleted only after save confirms)
- repository, controller, widget, and path tests cover the critical flows above
