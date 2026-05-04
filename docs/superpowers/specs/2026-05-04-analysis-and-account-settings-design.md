# Analysis Tab And Settings-Owned Account Management — Design Spec

**Date:** 2026-05-04  
**Status:** Draft  
**Scope:** Rename the Accounts tab to Analysis, move account management into `Settings > General > Default account`, make shopping list a Home-owned flow, and update `PRD.md` / `README.md` to match.

## Overview

Ledgerly's current middle tab mixes two unrelated MVP concerns:

- account management
- shopping-list access

This refactor separates them more cleanly.

The middle shell destination becomes `Analysis`, which is intentionally empty in MVP and reserved for Phase 2 charts. Account management moves under `Settings > General > Default account`, where the user can view accounts, choose the default account, create accounts, edit accounts, and perform archive/delete actions from the same flow. Shopping list stops living under the former Accounts area and becomes a Home-owned flow entered only from the shopping-cart button on Home.

The change is an information-architecture refactor, not a data-model refactor. Existing repository ownership, account invariants, and shopping-list storage remain intact.

## Goals

- Rename the middle shell destination from `Accounts` to `Analysis`.
- Change the middle-tab route from `/accounts` to `/analysis`.
- Keep `Analysis` empty in MVP with a simple Phase 2 placeholder.
- Remove shopping-list access from the former account page.
- Make the Home shopping-cart button the only shopping-list entry point.
- Ensure leaving the shopping-list screen returns the user to `Home`.
- Move account display and account management into `Settings > General > Default account`.
- Render `lib/features/accounts/widgets/account_tile.dart` inside the default-account picker instead of plain `ListTile`s.
- Preserve existing account rules for default selection, archive guards, delete guards, and grouped balance display.
- Update `PRD.md` and `README.md` so the documented product matches the shipped UX.

## Non-Goals

- Do not add charts, totals, or analytics content to `Analysis` in MVP.
- Do not add a separate `Settings > Accounts` entry.
- Do not change the Drift schema or account/shopping-list repositories for this refactor alone.
- Do not add backward-compatibility redirects from the old `/accounts*` paths unless implementation uncovers an internal-only need.
- Do not add a second shopping-list shortcut anywhere outside Home.

## 1. Navigation And Routing

### 1.1 Shell destinations

The app keeps the existing three-tab shell, but the middle branch changes from `Accounts` to `Analysis`.

- `/home`
- `/analysis`
- `/settings`

User-facing changes:

- the shell label becomes `Analysis`
- the shell title for the middle screen becomes `Analysis`
- the shell icon changes from the current wallet/account icon to an analysis-oriented icon such as `Icons.analytics_outlined`

`Accounts` remains an internal feature slice name for account logic and widgets. The user should no longer see `Accounts` as a top-level destination.

### 1.2 Analysis route

Add a dedicated `AnalysisScreen` at `/analysis`.

Behavior:

- no FAB
- no account list
- no shopping-list preview
- no fake chart data
- centered placeholder copy explaining that analysis/charts are planned for Phase 2

This screen exists so the shell reflects the future product structure without prematurely shipping partial analytics behavior.

### 1.3 Shopping-list routes become Home-owned

Shopping list moves under the Home branch:

- `/home/shopping-list`
- `/home/shopping-list/:itemId`

Behavior:

- the shopping-cart button on Home opens `/home/shopping-list`
- Home must use `push`, not `go`, for this entry so the back button pops to `/home`
- the shopping-list screen app bar back button also pops to `/home`
- tapping a shopping-list row opens `/home/shopping-list/:itemId`

Route presentation:

- `/home/shopping-list` is a normal page in the Home branch
- `/home/shopping-list/:itemId` keeps the current root-modal behavior so the list stays mounted underneath the draft editor

Old routes are removed from the product surface:

- `/accounts/shopping-list`
- `/accounts/shopping-list/:itemId`

### 1.4 Account form routes become Settings-owned

Account create/edit routes move under Settings-owned paths:

- `/settings/default-account/new`
- `/settings/default-account/:id`

These routes are modal/root-navigator routes presented above the Settings screen and above the default-account picker when it is open.

Old routes are removed from the product surface:

- `/accounts/new`
- `/accounts/:id`

## 2. Analysis Screen

Create a new `features/analysis/analysis_screen.dart`.

This screen is intentionally small:

- `Scaffold`
- `AppBar(title: Analysis)`
- centered empty-state style placeholder

Recommended placeholder behavior:

- title line such as `Analysis is coming in Phase 2`
- short supporting copy mentioning charts/summaries

No stub charts, tabs, or filters should be added. A plain placeholder is the correct MVP behavior.

## 3. Settings-Owned Account Management

### 3.1 Default account becomes the main account-management surface

`Settings > General > Default account` stops being a simple picker and becomes the single MVP surface for account management.

It owns:

- viewing active accounts
- viewing archived accounts
- choosing the default account
- creating a new account
- editing an existing account
- archive/delete actions

There is no separate top-level account-management screen after this refactor.

### 3.2 Presentation model

The settings entry point remains a settings widget, but the account-management content should stay owned by the accounts slice.

Recommended structure:

- `DefaultAccountTile` stays in `features/settings/widgets/`
- `showDefaultAccountPickerSheet(...)` remains the Settings-owned entry API
- the picker content delegates to a reusable accounts-slice widget such as `AccountsManagementPane`
- that accounts-slice widget consumes `AccountsController` / `AccountsState` and renders `AccountTile`

This preserves a clean boundary:

- Settings owns the entry point and the preference write for `default_account_id`
- the accounts slice owns account display state, row affordances, and account actions

### 3.3 Adaptive picker container

The `Default account` surface should follow the repo's existing 600dp breakpoint rule.

- below 600dp: modal bottom sheet
- 600dp and above: dialog

The content inside both containers is the same.

### 3.4 Picker layout

The picker should include, in order:

1. title: `Pick default account`
2. visible `Create account` CTA
3. active account section rendered with `AccountTile`
4. archived account section rendered with `AccountTile` when archived rows exist

The create CTA should remain visible even when accounts already exist. The empty state should also keep a create CTA.

### 3.5 AccountTile behavior inside the picker

The picker must display `lib/features/accounts/widgets/account_tile.dart`, but its interaction model changes from the old screen.

#### Active rows

- tapping the main tile body selects that account as the default account
- after a successful default write, the picker closes
- the current default row still shows the default badge

#### Archived rows

- archived rows are visible in a separate archived section
- archived rows are not selectable as the default account
- tapping the main tile body should do nothing for archived rows

#### Overflow actions

Because row tap is now used for selection, edit must move into the overflow menu.

`AccountTile` should be extended so the picker can surface:

- `Edit` for active rows
- `Edit` for archived rows
- `Set as default` for active non-default rows
- `Archive` or `Delete` for active rows according to the existing affordance rules

Archived rows only need `Edit` in the overflow menu. They should not expose default-selection, archive, or delete actions from that menu.

### 3.6 Create and edit flows

From the picker:

- `Create account` opens `/settings/default-account/new`
- `Edit` opens `/settings/default-account/:id`

These forms open above the picker and return to the still-open picker when dismissed or saved.

After save:

- the picker remains open
- the accounts list updates reactively
- the newly created account is not auto-selected as default; the user explicitly taps it if they want to make it default

### 3.7 Existing account rules stay unchanged

The move into Settings must not weaken current account rules.

Keep current behavior for:

- blocking archive of the last active account
- blocking archive/delete of the current default account
- only allowing hard-delete for unused zero-opening-balance accounts where the repository already permits it
- grouped balance display by currency
- archived section rendering

The surface changes, but the business rules do not.

## 4. Data Ownership And Component Boundaries

### 4.1 Settings controller stays preference-only

`SettingsController` should continue owning only settings/preferences data.

It keeps responsibility for:

- theme
- locale
- default currency
- default account preference writes
- splash settings

It should not absorb account-list composition, account affordance logic, or account archive/delete behavior.

### 4.2 Accounts controller stays the account-management SSOT

`AccountsController` and `AccountsState` remain the source of truth for the account list surface shown inside the picker.

That state already contains what the picker needs:

- active rows
- archived rows
- default account id
- grouped balances by currency
- row affordances

This avoids duplicating the same logic in Settings.

### 4.3 Reusable accounts-slice view

Because the old top-level `AccountsScreen` goes away, its current row-action plumbing should be extracted into a reusable accounts-slice widget instead of staying trapped inside a removed screen file.

That reusable view should own:

- account-type label lookups
- account row callbacks
- archive/delete/default dialogs and snackbars
- active/archived section rendering

The Settings picker hosts that view. `AnalysisScreen` does not reuse it.

### 4.4 No data-model change required

This refactor does not require:

- new tables
- schema migration
- repository API redesign
- new domain-layer use cases

The work is routing, UI composition, interaction behavior, localization, and documentation.

## 5. Shopping List As A Home Flow

### 5.1 Entry point

The Home shopping-cart button becomes the only shopping-list entry point in MVP.

Behavior:

- the shopping-cart button remains visible on Home even when the list is empty
- the badge label still appears only when count > 0
- tapping the button opens `/home/shopping-list`

No shopping-list entry remains in:

- `Analysis`
- `Settings`
- any account-management surface

### 5.2 Removing the old account-page preview

The shopping-list preview card is removed from the former account page flow entirely.

Implications:

- `ShoppingListCard` is no longer rendered from account-management UI
- any screen/layout code that assumed a shopping-list card above the account list is removed
- any docs/test expectations about shopping-list preview on the middle tab are updated

### 5.3 Back behavior

Back behavior is a product requirement for this refactor.

Expected flow:

- `Home` -> tap shopping-cart button -> `Shopping list`
- app bar back or system back -> `Home`

This is why Home must open the route with `push` and why the route itself now lives under the Home branch.

### 5.4 Draft editing flow

The draft editor remains available from the shopping-list screen.

Behavior:

- tap a shopping-list row -> open `/home/shopping-list/:itemId`
- closing that draft editor returns to the shopping-list screen underneath
- closing the shopping-list screen itself returns to Home

The data model and transaction-form reuse for draft editing do not change as part of this IA refactor.

## 6. Error Handling And Edge Cases

### 6.1 Default-account picker actions

Failure behavior should match the current account screen as closely as possible.

- default write failure -> generic snackbar
- archive last active account -> blocked message
- archive/delete current default account -> existing blocking dialog behavior
- generic account action failure -> generic snackbar

The picker should remain open after non-selection actions, including archive/delete failures and create/edit round-trips.

### 6.2 Account form fallback behavior

`AccountFormScreen` currently falls back to `/accounts` when it cannot pop.

That fallback must be updated to a Settings-owned destination.

New behavior:

- cancel from create/edit returns to the previous route when possible
- when a direct fallback is needed, return to `/settings`
- not-found behavior must never try to send the user back to the removed `/accounts` route

### 6.3 Archived rows in the picker

Archived rows remain visible but not selectable as default.

This prevents confusing behavior where a user could accidentally set an archived account as the default account.

### 6.4 Removed route safety

The implementation should update all in-repo callers and tests to the new paths.

No compatibility redirect is required for the removed `/accounts*` product paths unless implementation uncovers a concrete internal call site that cannot be migrated in the same change.

## 7. Documentation Updates

### 7.1 PRD

`PRD.md` should be updated to reflect the approved product structure.

Sections to update:

- phased roadmap text that describes shopping-list access
- routing structure (`/analysis`, `/home/shopping-list`, Settings-owned account-form routes)
- MVP screens list
- navigation description
- Home screen description
- Settings screen description
- any account-page description that still implies top-level account management or shopping-list preview

Required product-level wording changes:

- rename the middle destination/page from `Accounts` to `Analysis`
- describe `Analysis` as Phase 2 chart placeholder in MVP
- move account-management description under `Settings > General > Default account`
- describe shopping list as Home-owned via the shopping-cart button

### 7.2 README

`README.md` should match the same user-facing structure.

Update:

- main screens section
- Settings description
- shopping-list access description
- project layout if it mentions `Accounts` as a top-level screen rather than `Analysis`

The README should explain that:

- `Analysis` exists but is intentionally empty in MVP
- accounts are managed from Settings
- shopping list is entered from Home

## 8. Affected Product Surfaces

- `lib/app/router.dart`
- `lib/app/widgets/adaptive_shell.dart`
- `lib/features/analysis/analysis_screen.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/shopping_list/shopping_list_screen.dart`
- `lib/features/settings/widgets/default_account_tile.dart`
- `lib/features/settings/widgets/default_account_picker_sheet.dart`
- extracted accounts-slice management view/widget(s)
- `lib/features/accounts/widgets/account_tile.dart`
- `lib/features/accounts/account_form_screen.dart`
- `lib/l10n/*.arb`
- `PRD.md`
- `README.md`

## 9. Testing Expectations

### 9.1 Router tests

Add or update tests for:

- `/analysis` renders the placeholder screen
- `/settings/default-account/new` renders `AccountFormScreen` as a root modal route
- `/settings/default-account/:id` rejects invalid ids safely
- `/home/shopping-list` renders the shopping-list screen
- `/home/shopping-list/:itemId` uses the root navigator for draft editing
- removed `/accounts*` assumptions are eliminated from tests

### 9.2 Settings widget tests

Add or update tests for:

- tapping `Default account` opens the richer picker
- picker renders `AccountTile`, not plain `ListTile` rows
- active row tap selects default and closes
- archived rows are visible but not selectable
- overflow menu exposes `Edit` plus the existing applicable actions
- create CTA opens the Settings-owned account-create route

### 9.3 Account widget tests

Add or update tests for:

- `AccountTile` supports picker mode with body-tap selection
- `AccountTile` overflow menu can include `Edit`
- archived rows in picker mode expose `Edit` but not selection/default actions
- existing balance/default badge rendering remains intact

### 9.4 Home and shopping-list tests

Add or update tests for:

- the shopping-cart button still renders on Home when count is zero
- badge label appears only when count is greater than zero
- tapping the shopping-cart button navigates to `/home/shopping-list`
- back from shopping-list returns to Home
- draft row tap navigates to `/home/shopping-list/:itemId`

### 9.5 Documentation and localization verification

Verify:

- navigation labels say `Analysis`, not `Accounts`
- account-specific strings remain correct inside Settings/account forms
- `PRD.md` and `README.md` match the implemented IA

## 10. Success Criteria

This refactor is successful when:

- the middle shell destination is `Analysis` at `/analysis`
- `Analysis` is intentionally empty for MVP and clearly framed as a Phase 2 placeholder
- shopping list is entered only from the Home shopping-cart button
- leaving shopping list returns the user to Home
- `Settings > General > Default account` shows `AccountTile` rows and becomes the only MVP account-management surface
- account create/edit/archive/delete/default flows remain available from that Settings-owned surface
- existing account business rules still hold
- `PRD.md` and `README.md` describe the new structure accurately
