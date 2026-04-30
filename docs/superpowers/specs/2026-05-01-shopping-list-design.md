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

The shopping list is modeled as a new draft table, a new repository, and a new item editor screen. The Accounts tab hosts the primary list preview, while Home only exposes a count shortcut when drafts exist.

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
- category and account are required to save a draft
- memo may be empty
- draft amount may be empty/zero
- rapid repeated taps on `Add to shopping list` should be guarded against duplicate inserts by disabling the action or serializing the save

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
- tapping the shortcut navigates into the shopping list entry surface anchored under Accounts

Home must not render shopping-list item rows. The count shortcut should reactively update from a Drift-backed stream.

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
- the final transaction write should go through `TransactionRepository.save(...)`

Deletion rule:
- delete the shopping-list draft only after the transaction save succeeds
- never delete the draft first

## 2. Architecture

Shopping list should be implemented as a dedicated feature slice, not as ad hoc logic inside `accounts/`.

Recommended structure:
- new data model: `ShoppingListItem`
- new Drift table + DAO + repository: `shopping_list_items`
- new feature slice: `lib/features/shopping_list/`
- `AccountsScreen` remains the primary list host surface, but renders the shopping-list card from shopping-list providers/controllers
- `HomeScreen` only reads a lightweight shopping-list count provider for the circle shortcut
- the item editor/completion flow lives in its own screen/route

Why this shape is preferred:
- `AccountsScreen` already has enough responsibility; adding item editing ownership there would tangle unrelated concerns
- import rules forbid features from reaching into repositories directly, so a dedicated shopping-list controller/provider keeps the same boundary pattern as the rest of the repo
- `TransactionFormController` should remain focused on real transaction save/edit/duplicate flows; adding a second mutation path for shopping drafts would fight its current `canSave` contract
- a shopping-list-specific editor can still reuse visual widgets where sensible, while keeping commands explicit:
  - `saveDraft()`
  - `saveToTransaction()`
  - `delete()`

Screen boundaries:
- `Home`: count shortcut only
- `Accounts`: shopping-list card + list preview
- `ShoppingListItemScreen`: create/edit/complete one item
- Router: add concrete routes under the `/accounts` branch, such as `/accounts/shopping-list/new` and `/accounts/shopping-list/:id`

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

The controller should validate enough to save a shopping-list item:
- category required
- account required
- memo may be empty
- amount may be empty/zero
- rapid repeated taps on `Add to shopping list` should be guarded against duplicate inserts by disabling the action or serializing the save

Repository behavior:
- insert a `shopping_list_items` row
- return success/failure to the controller

Screen behavior:
- on success, close the form immediately
- on failure, remain on form and surface a snackbar

### 3.2 Edit existing draft

The shopping-list item screen opens with:
- category
- account
- memo
- optional draft amount

The shopping-list item screen should not expose a separate currency picker. When a draft amount is entered without an explicit draft currency from the transaction form, the screen should infer the draft currency from the selected account. The user should be able to save edits back to the shopping-list item independently from conversion.

### 3.3 Draft amount and currency

If the user enters a draft amount in a different currency from the selected account, the shopping-list item should preserve that chosen currency alongside the draft amount.

Therefore:
- `draftAmountMinorUnits` may be null
- `draftCurrencyCode` may be null, but must be present whenever draft amount is present

This keeps the feature aligned with Ledgerly's existing minor-unit money policy while still allowing the user to capture the intended transaction currency.

### 3.4 Convert to transaction

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

## 4. UI, Errors, and Testing

### 4.1 Home UI

Home keeps the existing extended FAB.

When shopping-list count > 0:
- render a small circular action immediately to the left of the FAB
- display only the count
- tap navigates into the shopping list entry surface under Accounts

When count == 0:
- hide the circle completely

Home must not become a second shopping-list surface.

### 4.2 Accounts UI

Insert a shopping-list card above the active-accounts card in the Accounts `CustomScrollView`.

Card should show:
- title
- item count
- compact item preview list (show up to 3 items, then truncate with a remaining-count label or overflow affordance)
- empty state when no items exist

Row interactions:
- tap row -> open shopping-list item screen
- swipe left -> open shopping-list item screen
- swipe right -> delete item

The card should respect the repo's existing card padding constants so it visually fits the Accounts layout.

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
- `Save draft` requires category and account
- `Save to transaction` requires category, account, and amount > 0; when amount is present, a resolved draft currency must also be available (inferred from explicit draft currency or account)

Because completion date is automatic, the screen should not expose a date picker.

### 4.4 Error handling

Add-to-shopping-list from transaction form:
- if category/account missing, block save and show inline hints
- if repository fails, show snackbar and remain on form

Delete from shopping list:
- optimistic-with-undo is preferred; surface repository failures via snackbar
- if optimistic delete is not practical, use confirm-before-delete and still surface failures via snackbar

Convert to transaction:
- if transaction save fails, keep the shopping-list item intact
- remove the draft only after successful transaction persistence

Missing / deleted item:
- show recoverable not-found state and return user to the prior surface

Archived / invalid references:
- if a referenced category or account becomes archived or otherwise unavailable, the shopping-list item should remain visible
- conversion should be blocked until the user selects a valid replacement category/account
- the archived or missing dependency should be surfaced clearly in the item UI

### 4.5 Testing expectations

Repository tests:
- create / update / delete shopping-list item
- count and watch streams re-emit correctly
- draft amount and currency invariants
- conversion does not delete item when transaction save fails

Controller tests:
- add-to-shopping-list validation differs from real transaction save
- `saveDraft()` vs `saveToTransaction()` behavior
- Home count provider reacts to changes
- error propagation stays typed and observable

Widget tests:
- Home shortcut hidden at zero and visible otherwise
- Accounts top card ordering and empty state
- row tap and swipe affordances
- item screen action enablement rules

Integration / path tests:
- Add Transaction -> Add to shopping list -> Accounts card shows item -> open item -> Save to transaction -> item disappears -> transaction appears on Home

## 5. Open Decisions

- `Add to shopping list` should be rendered as a secondary text-style action rather than a filled primary button; exact widget type can be finalized during implementation.
- the shopping-list card on Accounts should remain visible even when empty, using the card's empty state rather than appearing only after the first item exists

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
- conversion creates a real expense transaction and removes the draft atomically on success
- repository, controller, widget, and path tests cover the critical flows above
