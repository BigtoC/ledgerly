# Analysis Tab And Settings-Owned Account Management — Design Spec

**Date:** 2026-05-04
**Status:** Draft (revision 2 — incorporates document review feedback 2026-05-04)
**Scope:** Rename the Accounts tab to Analysis, move account management into `Settings > Manage accounts`, make shopping list a Home-owned flow, and update `PRD.md` / `README.md` to match.

## Overview

Ledgerly's current middle tab mixes two unrelated MVP concerns:

- account management
- shopping-list access

This refactor separates them.

The middle shell destination becomes `Analysis`, which is intentionally empty in MVP and reserved for Phase 2 charts. Account management becomes a Settings-launched sub-surface called `Manage accounts`, where the user can view accounts, create accounts, edit accounts, choose the default account, and perform archive/delete actions. Shopping list stops living under the former Accounts area and becomes a Home-owned flow entered only from the shopping-cart button on Home.

The change is an information-architecture refactor, not a data-model refactor. Existing repository ownership, account invariants, and shopping-list storage remain intact.

### Open product risks acknowledged but accepted

The document review surfaced two product-level concerns that this spec accepts rather than resolves:

- **Empty `Analysis` tab in MVP may signal incompleteness.** First-run users will see one of three primary destinations as a "coming in Phase 2" placeholder. Mitigation deferred to Phase 2.
- **Account management is two taps deep from primary nav** (Settings → Manage accounts). The new surface is at least named correctly for what it does, and a brand-new user with one seeded `Cash` account can complete a transaction without visiting it. Multi-account users do pay a discoverability cost.

Both concerns are tracked in the PRD update and may be revisited if user feedback shows they bite.

## Goals

- Rename the middle shell destination from `Accounts` to `Analysis`.
- Change the middle-tab route from `/accounts` to `/analysis`.
- Keep `Analysis` empty in MVP with a simple Phase 2 placeholder.
- Remove shopping-list access from the former account page.
- Make the Home shopping-cart button the only shopping-list entry point.
- Ensure leaving the shopping-list screen returns the user to `Home`.
- Move account display and account management into a Settings-launched surface named `Manage accounts`.
- Render `lib/features/accounts/widgets/account_tile.dart` inside `Manage accounts` instead of plain `ListTile`s.
- Preserve existing account rules for default selection, archive guards, delete guards, and grouped balance display.
- Migrate every in-repo `/accounts*` caller (including non-Settings flows like Add Transaction's create-account recovery) to the new routes.
- Update `PRD.md` and `README.md` so the documented product matches the shipped UX.

## Non-Goals

- Do not add charts, totals, or analytics content to `Analysis` in MVP.
- Do not add a separate top-level `Accounts` destination in primary navigation.
- Do not change the Drift schema or account/shopping-list repositories for this refactor alone.
- Do not add backward-compatibility redirects from the old `/accounts*` paths. All in-repo callers migrate in the same change.
- Do not add a second shopping-list shortcut anywhere outside Home.
- Do not introduce a `pickerMode` flag on `AccountTile`. The widget keeps its current interaction model.

## 1. Navigation And Routing

### 1.1 Shell destinations

The app keeps the existing three-tab shell, but the middle branch changes from `Accounts` to `Analysis`.

- `/home`
- `/analysis`
- `/settings`

User-facing changes:

- the bottom-nav label becomes `Analysis`
- the AppBar title for the middle screen becomes `Analysis`
- the bottom-nav icon changes from the current wallet/account icon to an analysis-oriented icon such as `Icons.analytics_outlined`

`Accounts` remains an internal feature-slice name for account logic and widgets. The user should no longer see `Accounts` as a top-level destination.

> **Terminology note.** Throughout this spec: `bottom-nav label` = `BottomNavigationBarItem.label` (also rendered next to the rail destination on tablet); `AppBar title` = `AppBar.title` of the destination screen.

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

- `/home/shopping-list` — normal in-branch route, pushed onto the Home branch's nested navigator
- `/home/shopping-list/:itemId` — root-navigator modal route presented above whatever Home stack is current

Behavior:

- the shopping-cart button on Home opens `/home/shopping-list` via `context.push`, not `context.go`, so the back button pops to `/home`
- the shopping-list screen app bar back button also pops to `/home`
- tapping a shopping-list row opens `/home/shopping-list/:itemId`

Old routes are removed from the product surface:

- `/accounts/shopping-list`
- `/accounts/shopping-list/:itemId`

#### 1.3.1 Cross-tab return behavior (resolved decision)

Because shopping-list is `push`'d on the Home branch and `StatefulShellRoute.indexedStack` preserves each branch's stack across tab switches, the following flow is correct and intended:

1. User is on Home → taps shopping-cart → lands on `/home/shopping-list` (Home branch stack: `[Home, ShoppingList]`).
2. User taps the `Analysis` tab → Home branch is preserved, Analysis renders.
3. User taps the `Home` tab again → Home branch returns to whatever was on top, which is `/home/shopping-list`.

This matches `StatefulShellRoute.indexedStack` semantics and is consistent with how Home's `add` / `edit` flows already behave when the user backgrounds them via tab switch. Re-tapping the active `Home` tab while shopping-list is on top **does not** reset the Home stack — that is documented standard behavior, and the user can reach Home with one back gesture.

Router tests must include:

- back from `/home/shopping-list` returns to `/home`
- tab-switch and return preserves `/home/shopping-list` on the Home branch (this is `StatefulShellRoute.indexedStack` semantics for the in-branch route)

> **Caveat about `/home/shopping-list/:itemId`.** This child route uses `parentNavigatorKey: _rootNavigatorKey` and therefore lives **above** the entire `StatefulShellRoute`, not inside the Home branch. While the draft modal is mounted, switching tabs does not hide it — it continues to cover whatever tab is active. This matches the existing `/accounts/shopping-list/:itemId` behavior today (`router.dart:138`) and is intentional: the user finishes the draft, the modal pops, and the underlying Home branch (which still has `/home/shopping-list` on top) re-appears. Do not write a test asserting the modal "rides along on the Home branch under indexed-stack" — that is not how root-navigator routes behave. Instead, test that opening the modal, tapping another tab, and tapping back to Home reveals the same modal still on top, with `/home/shopping-list` underneath when it pops.

### 1.4 Account form routes become Settings-owned

Account create/edit routes move under Settings-owned paths:

- `/settings/manage-accounts/new`
- `/settings/manage-accounts/:id`

These routes are root-navigator modal routes (`parentNavigatorKey: _rootNavigatorKey`, `fullscreenDialog: true`) presented above the Settings screen and above the `Manage accounts` surface when it is open.

Old routes are removed from the product surface:

- `/accounts/new`
- `/accounts/:id`

#### 1.4.1 Non-Settings callers must migrate in the same change

`/accounts/new` is currently called from at least four call sites that are **not** in the Settings flow. Every one of these must be updated in lockstep, and tests must cover each one:

| File | Line | Today's call | Replace with |
|------|------|--------------|--------------|
| `lib/features/home/home_screen.dart` | 162 | `context.go('/accounts/shopping-list')` (Home `FloatingActionButton`, key `homeShoppingListFab`) | `context.push('/home/shopping-list')` — note: existing widget is a FAB, not an AppBar IconButton; §5.1 wording is corrected accordingly |
| `lib/features/shopping_list/shopping_list_screen.dart` | 112 | `await context.push<ShoppingListEditResult?>('/accounts/shopping-list/$id')` (row-tap handler) | `await context.push<ShoppingListEditResult?>('/home/shopping-list/$id')` |
| `lib/features/transactions/transaction_form_screen.dart` | 694 | `context.push('/accounts/new').then(...)` | `context.push('/settings/manage-accounts/new')` — preserves the awaited `int?` return contract |
| `lib/features/transactions/widgets/account_picker_sheet.dart` | 50 | `await context.push<int>('/accounts/new')` | `await context.push<int>('/settings/manage-accounts/new')` — preserves the auto-select-on-return contract |
| `lib/features/settings/widgets/default_account_picker_sheet.dart` (existing) | 65–66 | `Navigator.of(context).pop(); context.go('/accounts/new')` | `context.push('/settings/manage-accounts/new')` — see §3.4 for the new CTA contract (no pre-pop) |
| `lib/features/accounts/accounts_screen.dart` (FAB + empty state) | n/a | `context.go('/accounts/new')` | screen is deleted (see §4.3); test fixtures referencing it must be updated |
| `lib/features/shopping_list/widgets/shopping_list_card.dart` | 66, 82, 150, 195 | `context.go('/accounts/shopping-list')` | widget is deleted (see §5.2) |
| `lib/features/accounts/account_form_screen.dart` | 144–153 (`_NotFoundSurface.onDismiss`), 299–308 (Cancel button) | `context.go('/accounts')` (TWO sites) | both must change to `context.go('/settings')` — see §6.2 |

The PR must include a `grep -rn "'/accounts" lib/ test/` run that returns zero matches for product-route paths (excluding the `accounts` feature-slice directory name and Drift-generated identifiers). This is a release-gate criterion — see §10.

#### 1.4.2 Per-call-site `await` / type-param contract

`AccountFormScreen` calls `context.pop(savedId)` on save where `savedId` is `int?`. Different call sites consume that return value differently — implementers must use the exact signatures below to avoid type drift:

| Caller | Required signature | Why |
|--------|-------------------|-----|
| `account_picker_sheet.dart:50` (Add Transaction inline picker) | `final id = await context.push<int>('/settings/manage-accounts/new');` | Auto-selects the just-created account in the transaction form. `int` (not `int?`) is the existing contract; preserve it. |
| `transaction_form_screen.dart:694` (recovery flow) | `await context.push('/settings/manage-accounts/new').then((_) { /* refresh */ });` | The recovery flow does not consume the id; just awaits completion to re-evaluate state. |
| `manage_accounts_sheet.dart` (new Create CTA, §3.4 step 4) | `context.push('/settings/manage-accounts/new');` (no `await`, no type param) | The CTA is fire-and-forget; the surface picks up the new account reactively via the Drift stream. The id is dropped at the type-system level so future maintainers don't accidentally try to use it. |
| `manage_accounts_sheet.dart` (Edit row body-tap / overflow `Edit`) | `context.push('/settings/manage-accounts/$id');` (no `await`) | Same reasoning. |

## 2. Analysis Screen

Create a new `lib/features/analysis/analysis_screen.dart`.

This screen is intentionally small:

- `Scaffold`
- `AppBar(title: 'Analysis')`
- centered empty-state placeholder

Recommended placeholder behavior:

- title line: `Analysis is coming in Phase 2`
- short supporting copy: `Charts and summaries will appear here once Phase 2 lands.`

No stub charts, tabs, filters, or "where do I manage accounts" deep-links should be added. A plain placeholder is the correct MVP behavior.

## 3. Settings-Owned Account Management (`Manage accounts`)

> **Terminology note for §3.** "Surface" is the abstract presentation. "Sheet" refers to the `showModalBottomSheet` instantiation (<600dp). "Dialog" refers to the `showDialog` instantiation (≥600dp). When the spec says "the surface remains open" it means whichever container is currently mounted, sheet or dialog.

### 3.1 Naming and entry point

The Settings entry point is renamed from `Default account` to `Manage accounts` and becomes the single MVP surface for account management.

It owns:

- viewing active accounts (with default badge on the current default)
- viewing archived accounts
- creating a new account
- editing an existing account
- setting the default account
- archive/delete actions

There is no separate top-level account-management screen after this refactor.

### 3.2 Presentation model

The Settings entry-point row stays a Settings-owned widget; the surface content stays owned by the accounts slice. Concretely:

- `lib/features/settings/widgets/manage_accounts_tile.dart` — the Settings list row (renamed from `default_account_tile.dart`). Subtitle is **count-aware**, biased toward affordance preview rather than status:
  - 1 active account: subtitle is the account's display name (e.g. `Cash`)
  - N active accounts (N≥2): subtitle is `<default-name> +<N-1> more` (e.g. `Cash +2 more`)
  - 0 active accounts (rare; only after deleting the seeded `Cash`): subtitle is `Add an account`
  - The "Default:" prefix used in the prior revision is dropped — the surface is no longer default-pivoted, so leading with status is misleading.
- `lib/features/settings/widgets/manage_accounts_sheet.dart` — the Settings-owned entry API (`showManageAccountsSheet(context)`), renamed from `default_account_picker_sheet.dart`.
- `lib/features/accounts/widgets/manage_accounts_body.dart` — the body content rendered inside the sheet/dialog. **This is a file relocation, not a new widget API.** The private classes from the deleted `accounts_screen.dart` (`_AccountsBody`, `_AccountTileWithLookups`, `_AccountListCard`) move into this file. No `AccountsManagementPane` public widget type is introduced.
  - **Why a separate file vs. inlining into `manage_accounts_sheet.dart`:** the relocated `_AccountsBody` plus its private helpers are roughly 230 lines. Inlining would make `manage_accounts_sheet.dart` a >300-line file mixing the entry-point shell (`showManageAccountsSheet` + sheet/dialog presentation logic) with body composition. The split keeps the sheet file focused on the Settings entry API and keeps the body file focused on accounts-slice rendering. If the body file shrinks below ~80 lines after the relocation (e.g. because some helpers were dead code), inline.

Boundary:

- Settings owns the entry tile and the preference write for `default_account_id` (via `SettingsController`).
- The accounts slice owns the body composition, `AccountTile` rendering, action callbacks, and the dialogs/snackbars for archive/delete/default.

### 3.3 Adaptive container

The `Manage accounts` surface follows the repo's existing 600dp breakpoint (mirroring `category_picker.dart:43-65` and `account_picker_sheet.dart:22-44`):

- below 600dp: `showModalBottomSheet` with the body content
- 600dp and above: `showDialog` with the same body content in a constrained `AlertDialog` / `Dialog`

The body content (account list, CTA, error/loading/empty states) is identical between the two containers. Container chrome differs naturally: the bottom sheet shows a drag handle and renders the `Manage accounts` title as the first content row; the dialog renders the title via the standard `AlertDialog`/`Dialog` title slot.

#### 3.3.1 Navigator host (`useRootNavigator`) — resolved decision

To make "form opens above the still-open `Manage accounts` surface and returns to it on dismiss" work identically on phone and tablet:

- `showModalBottomSheet` keeps its default `useRootNavigator: false`. The sheet lives on the shell's branch navigator. The form route, with `parentNavigatorKey: _rootNavigatorKey`, stacks **above** the sheet on the root navigator. On form pop, the sheet remains.
- `showDialog` must be called with **`useRootNavigator: false`**. This puts the dialog on the same branch navigator as the sheet path, so the form route (root navigator) can stack above it identically. Without this override, the dialog and form share the root stack and back-gesture order becomes ambiguous.

Implementation note (not a release gate, just a non-default to remember): both phone (sheet) and tablet (dialog) paths must show identical "open form, save, return to still-open surface" behavior. A widget test that opens the form from each path and asserts the surface is still mounted after pop covers it.

### 3.4 Layout

The `Manage accounts` body, in order:

1. Title — rendered as the dialog's title slot in the dialog form, or as the first content row (after the drag handle) in the bottom-sheet form. Text: `Manage accounts`.
2. Active accounts section — a list of `AccountTile` rows, one per active account. The default account is rendered with the existing default badge in-place; this badge is the **only** in-surface indicator of which account is default (no separate header strip).
3. Archived accounts section — only rendered when archived rows exist; section header reads `Archived`.
4. **`Create account` CTA** — visible at all times (empty state and populated state). Tapping it pushes `/settings/manage-accounts/new` (the surface stays mounted; see §3.6).

The CTA is always visible — the existing `default_account_picker_sheet.dart` renders the CTA only in the empty state, and the new behavior is a deliberate change. The `Manage accounts` surface no longer pops itself before navigating to create — see §3.6.

> **Why no "Default account: <name>" header strip.** An earlier revision proposed a status header restating the default. Cut: the in-place badge already conveys which account is default, the Settings tile subtitle (§3.2) repeats it pre-tap, and the strip would not be tappable (default change happens via the row's overflow / swipe). Two display sites for the same datum without an action is overhead.

#### 3.4.1 Loading and error states

The body subscribes to `AccountsController` (an `AsyncNotifier<AccountsState>`).

**Layout skeleton.** Because the title and CTA must stay visible across loading/error/data states, the body uses a fixed three-zone layout:

```
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Title row (or AlertDialog title slot)        // fixed height
    Flexible(child: <state switcher>),           // loading | error | empty | data
    CreateAccountCta(),                          // fixed height, pinned to bottom of the body
  ],
)
```

The state switcher swaps between four child widgets without disturbing the title or CTA. This is a new pattern in this codebase — existing screens (`accounts_screen.dart`, `settings_screen.dart`, `splash_screen.dart`) all use full-body spinners. Implementer should not copy those; they belong to screens that don't need a header/footer to remain stable.

**State contents:**

- **Loading** (initial Drift stream emission pending): a small `CircularProgressIndicator` centered in the Flexible body region. Title and CTA remain visible — the user can still create even while existing accounts load.
- **Error** (`AsyncError` from the controller): an inline error placeholder — icon, single-line copy `Couldn't load accounts.`, and a `Retry` button. Title and CTA remain visible. Surface does not auto-dismiss.
- **Empty** (loaded with zero active and zero archived rows): the empty-state copy `No accounts yet. Create one to get started.` rendered above the CTA inside the Flexible body region.
- **Data**: the section list described in §3.4 steps 2–3 inside the Flexible body region.

**Retry behavior:**

- Tapping `Retry` calls `ref.invalidate(accountsControllerProvider)`, which transitions the state back to Loading; while Loading is rendering, the Retry button is **disabled** (visually grayed and `onPressed: null`) so the user cannot stack invalidations.
- Before showing any error SnackBar in §6.1, the body calls `ScaffoldMessenger.of(context).clearSnackBars()` so a persistent failure does not stack identical snackbars.
- No max-retry guard is added in MVP. A persistent error keeps the placeholder + Retry visible; the user can dismiss the surface and reopen it later.

### 3.5 AccountTile interaction model inside `Manage accounts`

`AccountTile` is **not** extended with a picker mode. Its current callback contract is sufficient to drive the surface. The `Manage accounts` surface uses the **existing AccountsScreen interaction model** (which is being relocated, not redesigned). Specifically, the relocated `_AccountsBody` preserves these behaviors from `accounts_screen.dart` today:

- the row callback wiring at `accounts_screen.dart:152–186` (`_AccountTileWithLookups`)
- the dialog/snackbar plumbing for archive/delete/default actions invoked from `_AccountsBody`
- the Slidable + PopupMenuButton trailing actions inside `account_tile.dart:65–306`
- the default badge rendering rules

The only call-site behavioral changes this spec introduces are: (a) row body-tap navigates to `/settings/manage-accounts/:id` instead of `/accounts/:id`, and (b) archived rows gain a single `Edit` overflow item (see below).

#### Active rows

- body tap → `onTap` callback opens `/settings/manage-accounts/:id` (Edit form)
- swipe (Slidable) — start pane: `Set as default` (hidden when row is already default); end pane: `Archive` or `Delete` per affordance rules
- overflow `PopupMenuButton` — `Edit`, `Set as default` (when not already default), `Archive` or `Delete` per affordance rules

The default row shows the existing default badge in-place. There is no separate "select" gesture — body-tap goes to Edit, exactly as in the relocated `accounts_screen.dart` today.

#### Archived rows

Archived rows currently render `SizedBox.shrink()` from `_TrailingActions` (no overflow menu at all). This refactor extends `_TrailingActions` to render a `PopupMenuButton` for archived rows containing a single item:

- `Edit` (opens `/settings/manage-accounts/:id`)

Archived rows also gain an `onTap` body-tap that opens the same Edit form. They do **not** expose `Set as default`, `Archive`, or `Delete` actions — those are blocked by repository invariants and would surface as confusing snackbars.

**Archived-row Edit form scope.** When an Edit form is opened for an archived account, the form renders the **same fields** as for an active account (Name, Account type, Currency, Opening balance, Icon, Color). No fields are read-only, no archive-status banner is added, and no AppBar copy changes — the form is unmodified. The repository's existing guards apply: if a field change is rejected for an archived account, the existing generic error snackbar fires. This is the path of least change. Rationale: the most common edit on an archived row is renaming or recoloring it for posterity; locking down fields would add complexity for a corner-case write that is already repository-guarded.

The Slidable wrapper must suppress both panes for archived rows. Today this is implemented in `account_tile.dart` by gating the action lists with `if (!a.isArchived)` (see lines 65–104) and passing the panes as `null` when the lists are empty (lines 105–121). There is no `enabled` flag in the current `Slidable(...)` constructor — the suppression mechanism is empty-action-lists, not a flag. Preserve this gating pattern; in particular, do **not** unconditionally populate the action lists and rely on per-action guards inside `onPressed` callbacks. A widget test should assert that `Slidable.startActionPane` and `Slidable.endActionPane` are both `null` for archived rows.

#### Minimal `AccountTile` API change

The only widget-level change to `AccountTile` is in `_TrailingActions`: replace the early-return `SizedBox.shrink()` for archived rows with a PopupMenuButton that emits an `Edit` item via a new optional `onEdit` callback. Active rows already have a PopupMenuButton; the same `onEdit` callback gets surfaced as a new menu item there.

> **Note on shared-widget reach.** `AccountTile` is currently rendered only by `accounts_screen.dart` (which this refactor deletes — the rendering moves into `manage_accounts_body.dart`). It is **not** rendered by `lib/features/transactions/widgets/account_picker_sheet.dart`; that picker uses plain `ListTile` rows (account_picker_sheet.dart:99–110). So the `onEdit` callback's reach after this refactor is exactly one caller: `manage_accounts_body.dart`. The optional-with-default-null typing is still the right shape — it documents the contract for any future second caller — but no widget test against the Add Transaction picker is needed (its `ListTile` rows are unaffected by `AccountTile` changes).

No `pickerMode: bool` flag, no subclass, no behavior switch.

#### Set-as-default completion behavior

After a successful `Set as default` write (via overflow menu or swipe action):

- the surface remains open
- the default badge moves to the newly-default row reactively (no manual scroll)
- a `SnackBar` confirms the change with text such as `<name> is now the default account.`

After a failed write:

- a `SnackBar` shows `Couldn't change default account. Try again.`
- the surface remains open

#### Archive / delete completion behavior

After a successful `Archive` or `Delete`:

- the surface remains open
- the row disappears from the active section reactively
- archived rows appear in the Archived section reactively

After a blocked `Archive` (last active account, or current default account): the existing blocking dialog from `_AccountsBody` is reused unchanged. Focus returns to the surface; the surface remains open.

### 3.6 Create and edit flows

From the `Manage accounts` surface:

- `Create account` CTA → `context.push('/settings/manage-accounts/new')`
- Row body-tap or overflow `Edit` → `context.push('/settings/manage-accounts/:id')`

These forms open above the surface (root navigator, see §3.3.1) and return to the still-open surface when dismissed or saved.

After save:

- the surface remains open
- the accounts list updates reactively via `AccountsController`'s Drift stream
- **the newly-created account is auto-selected as default if and only if no active default currently exists at save time.**
  - Steady-state case (one or more active defaults already exist): the new account is **not** auto-selected. Rationale: the user explicitly opens `Manage accounts` to manage many things, not to set the default. Auto-selecting on every create would silently change the default whenever the user adds a second card / cash account.
  - Empty-state case (zero active accounts before save, e.g. after deleting the seeded `Cash`): the newly-created account **is** auto-set as default in the same write transaction. Without this, the user would land in a partially-configured state with no default at all (Settings tile would have nothing to display, Add Transaction would have no preselected account).
  - The user can always change the default later via the row's overflow `Set as default`.
- a brief `SnackBar` confirms the save (`<name> created.` or `<name> saved.`)

The Add-Transaction inline `account_picker_sheet.dart` flow (§1.4.1) is unaffected by this rule — it still awaits the `int?` return value and auto-selects the just-created account into the transaction form, because that is a different picker with different intent.

#### 3.6.1 Picker scroll position after form return

When the user opens an Edit form from row N and returns to the surface, the surface's `ListView` / `CustomScrollView` scroll position is preserved — the list rebuilds reactively but the controller's offset survives because the route was pushed (not branch-switched). Implementers should verify by manual test on a list with 8+ accounts.

When the user creates a new account, the new row appears at the **end** of the active section (existing repository ordering by `created_at`). The surface does not auto-scroll to it. Rationale: auto-scroll would lose the user's place if they were inspecting another row first.

#### 3.6.2 Cold-start invariant

`/settings/manage-accounts/new` and `/settings/manage-accounts/:id` are valid deep-link / cold-start destinations. When entered with no `Manage accounts` surface beneath them:

- on save or cancel, `AccountFormScreen`'s fallback applies (see §6.2): `context.go('/settings')`. The user lands on Settings with **no `Manage accounts` surface open**. This is acceptable; the user can reopen it manually.
- **bad-id case:** when `/settings/manage-accounts/9999` (id not in repo) is opened on cold start, `_NotFoundSurface`'s post-frame callback runs `context.go('/settings')` immediately. The form's brief "couldn't load" UI flashes once before the redirect. The user lands silently on Settings; this is the same behavior as the existing `/accounts/:id` cold-start-with-bad-id path today and is **acceptable for MVP** (per §6.2). Adding a transient SnackBar was considered and rejected: the bad-id path is reachable only via stale deep-links, the redirect is fast, and routing a one-shot message through a new Riverpod state provider would add an architectural seam (side-channel state between routes) that the spec's controllers-expose-typed-state principle discourages.

The "form returns to still-open surface" guarantee in §3.6 holds **only when the form was pushed from an open `Manage accounts` surface in the same session**. When in doubt, `AccountFormScreen` checks `context.canPop()`: if true, `pop` (returns to whatever pushed it); if false, `go('/settings')`.

#### 3.6.3 Three-layer modal back / scrim contract

When all three layers are stacked — Settings (layer 0, in shell) → `Manage accounts` sheet/dialog (layer 1) → Account form (layer 2, root-navigator modal):

| Gesture | Behavior |
|---------|----------|
| Tap scrim of layer 2 (form) | dismisses the form only; layer 1 surface remains open |
| Tap scrim of layer 1 (sheet/dialog), with form not present | dismisses the surface; user lands on Settings |
| Tap scrim of layer 1 while form is present | scrim is not reachable — form covers it |
| Hardware/system back, form present | dismisses form first; surface remains open |
| Hardware/system back, surface present without form | dismisses surface; user lands on Settings |
| Hardware/system back, neither present | standard Settings/shell back behavior |
| Drag-to-dismiss the bottom sheet, form present or not | **disabled** — the sheet is launched with `isDismissible: false` and `enableDrag: false`. The sheet has an explicit close button in its title row (a leading `IconButton(icon: Icons.close, ...)` that calls `Navigator.of(context).pop()`) for users who want to dismiss without using the system back |
| Tap scrim of layer 1 (sheet/dialog), with form not present | scrim tap is also gated by `isDismissible: false` — does nothing. Use the close button or system back |
| Device rotation while sheet/dialog is open (form may also be present) | rotation tears down both layers and the user lands back on Settings (layer 0). Any unsaved form input is treated like a Cancel. This is a known MVP limitation; persistent form-state-across-rotation is out of scope |

`AccountFormScreen` inside the form route does not consume the back gesture except via its standard Cancel/Save buttons. Existing `WillPopScope` / `PopScope` guards inside the form (e.g., dirty-state confirmation) follow current behavior unchanged.

**Why `isDismissible: false`.** This is the simpler of two options. The alternative — let the user drag-dismiss the sheet while the form is on top — collapses several edge cases into the spec: the sheet's exit animation runs (~250ms, not "one frame") with the form still visible above; the awaited `Future` returned by `showManageAccountsSheet` resolves before the form pops, leaving any caller-side post-await logic to run while the user is still typing; and the auto-default empty-state read in §3.6 has to survive the body-widget being unmounted. Locking the sheet's drag-dismiss closes all three at once at the cost of one extra widget (the close button) on the sheet's title row.

The dialog form (≥600dp) does not have a drag affordance; the equivalent rule there is to also pass `barrierDismissible: false` to `showDialog` and rely on the same close button.

### 3.7 SnackBar copy and l10n keys

**Reuse takes precedence over namespace consistency.** Before adding any key, grep for an existing key with the same English string. If one exists, reuse it — duplicate strings across two ARB keys drift on subsequent locale updates. The `manageAccounts*` namespace applies only to genuinely new strings with no existing analog.

Confirmed reuses (do **not** add new keys):

- `Retry` button label — reuse `shoppingListScreenRetry` (already exists in `app_en.arb` with the exact same English string)
- `<name> created.` / `<name> saved.` SnackBar — grep `app_en.arb` for existing form save/create keys; if `accountSaved` / `accountCreated` (or similar) exist, reuse them directly
- archive-failed / delete-failed copy — reuse whatever keys exist on the current `accounts_screen.dart`; those move with the relocated `_AccountsBody`

Genuinely new keys (no equivalent exists; add to all four locales — `app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`):

| ARB key | Parameters | English copy | Triggered by |
|---------|------------|--------------|---------------|
| `manageAccountsSetDefaultSuccess` | `String name` | `{name} is now the default account.` | §3.5 successful Set as default |
| `manageAccountsSetDefaultFailed` | (none) | `Couldn't change default account. Try again.` | §3.5 / §6.1 failed Set as default |
| `manageAccountsLoadError` | (none) | `Couldn't load accounts.` | §3.4.1 inline error placeholder |
| `manageAccountsTileSubtitleMore` | `int count` (ICU plural) | `{count, plural, =1{ +1 more} other{ +{count} more}}` (concatenated after the default name in §3.2 N≥2 case) | §3.2 Settings tile subtitle |
| `manageAccountsTileSubtitleAddCta` | (none) | `Add an account` | §3.2 Settings tile subtitle when zero active accounts |
| `manageAccountsBodyEmpty` | (none) | `No accounts yet. Create one to get started.` | §3.4.1 empty state |

### 3.8 Existing account rules stay unchanged

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

`SettingsController` continues owning only settings/preferences data: theme, locale, default currency, default-account preference writes, splash settings. It must not absorb account list composition, account affordance logic, or account archive/delete behavior.

### 4.2 Accounts controller stays the account-management SSOT

`AccountsController` and `AccountsState` remain the source of truth for the `Manage accounts` body. State exposes:

- active rows
- archived rows
- default account id
- grouped balances by currency
- per-row `affordance` (canArchive / canDelete / etc.)

#### 4.2.1 Account-type label lookup

`AccountTile` requires a `String accountTypeLabel` constructor argument. `AccountsState` does **not** include this field. Today it is resolved per-row in `_AccountTileWithLookups` via the separate `accountTypeByIdProvider(view.account.accountTypeId)` Riverpod family.

When `_AccountTileWithLookups` is relocated to `manage_accounts_body.dart` (§3.2), this per-row provider lookup moves with it. **No state-shape change is required.** The "no schema/repo change" claim holds, but readers should not assume `AccountsState` alone is enough — the provider family is a real second dependency.

### 4.3 The old AccountsScreen is deleted

`lib/features/accounts/accounts_screen.dart` is deleted. Its private classes (`_AccountsBody`, `_AccountTileWithLookups`, `_AccountListCard`) move into `lib/features/accounts/widgets/manage_accounts_body.dart` as package-internal classes. No new public widget API is introduced.

The router entry for `/accounts` (and all its child routes) is removed — see §1.4.1 for the migration scope.

`AnalysisScreen` does not import or reuse `manage_accounts_body.dart`.

### 4.4 No data-model change required

This refactor does not require:

- new tables
- schema migration
- repository API redesign
- new domain-layer use cases

The work is routing, UI composition, file relocation, interaction-model preservation (not change), localization, and documentation.

## 5. Shopping List As A Home Flow

### 5.1 Entry point

The Home shopping-cart button becomes the only shopping-list entry point in MVP.

Behavior:

- the shopping-cart `FloatingActionButton` (key `homeShoppingListFab`) remains visible on Home even when the list is empty
  - **zero-count visual treatment:** full-opacity icon, no badge. Same icon, no muted styling. The user is not penalized for having an empty list.
  - **count > 0:** small numeric badge on the icon's top-right, using the existing badge widget's surface/onSurface tokens.
- tapping the button calls `context.push('/home/shopping-list')`

No shopping-list entry remains in:

- `Analysis`
- `Settings`
- any account-management surface

> **Accepted dead end: changing default account from inside Add Transaction.** The Add Transaction inline `account_picker_sheet` has a `Create account` recovery path but **no** path to change which account is the default from inside the transaction form. A user who wants to change their default while logging a transaction must dismiss the form, navigate to `Settings > Manage accounts`, and return. This is acknowledged and accepted for MVP; not added because (a) changing the default from inside Add Transaction would compete with the row-level "select this account for *this* transaction" affordance, conflating two different intents, and (b) the Manage-accounts entry is one tap away from any screen via the Settings tab. If user feedback shows this dead end is friction, revisit in Phase 2.

### 5.2 Removing the old account-page preview

The shopping-list preview card is removed from the former account page flow entirely.

`ShoppingListCard` (`lib/features/shopping_list/widgets/shopping_list_card.dart`) currently has four hardcoded calls to `/accounts/shopping-list` (lines 66, 82, 150, 195). The widget is used **only** by the deleted `accounts_screen.dart`.

**Decision: delete `ShoppingListCard` in this refactor.** Rationale: keeping it as a Phase 2 candidate creates a dead widget with stale routes; the cost to recreate a similar preview later (if needed) is small. The associated tests (`test/widget/features/shopping_list/shopping_list_card_test.dart`, `shopping_list_card_add_button_test.dart`) are deleted in the same change.

**Pre-deletion audit step:** before deleting, run `grep -rn "shoppingListItemsProvider\\|shopping_list.*Provider" lib/` and confirm Home's cart-button badge consumer is independent of any provider that `ShoppingListCard` was the sole keep-alive consumer for. If the card is the only warming consumer of a narrower computed provider that Home derives from, either keep that warming via a tiny invisible consumer in `HomeScreen` or document the cold-start latency as accepted. This is a low-risk audit but cheap to add.

### 5.3 Back behavior

- `Home` -> tap shopping-cart button -> `Shopping list`
- app bar back or system back -> `Home`

This requires Home to open the route with `context.push` and the route to live under the Home branch. Cross-tab return preserves the shopping-list state per §1.3.1.

### 5.4 Draft editing flow

The draft editor remains available from the shopping-list screen.

- tap a shopping-list row -> open `/home/shopping-list/:itemId` (root-navigator modal)
- closing the draft editor returns to the shopping-list screen underneath
- closing the shopping-list screen returns to Home
- tab-switching with the draft modal mounted leaves the modal on top of every tab (root-navigator route, see §1.3.1 caveat); on draft pop, the user lands on whichever Home branch state was beneath

The data model and transaction-form reuse for draft editing do not change.

## 6. Error Handling And Edge Cases

### 6.1 `Manage accounts` action failures

- default write failure → `SnackBar`: `Couldn't change default account. Try again.` Surface remains open.
- archive last active account → existing blocking dialog (no change)
- archive/delete current default account → existing blocking dialog (no change)
- generic action failure → `SnackBar` with action-specific copy. Surface remains open.
- `AccountsController` stream error mid-interaction → see §3.4.1; surface shows inline error placeholder with `Retry`. Surface does not auto-dismiss.

### 6.2 AccountFormScreen fallback behavior — TWO sites

`AccountFormScreen` currently has **two** hardcoded `/accounts` fallbacks, not one. Both must be updated:

- **`account_form_screen.dart:299-308`** (Cancel `OutlinedButton`): `if (context.canPop()) { context.pop(); } else { context.go('/accounts'); }` at line 306 — change the `else` branch to `context.go('/settings')`.
- **`account_form_screen.dart:144-153`** (`_NotFoundSurface.onDismiss`, called via `WidgetsBinding.instance.addPostFrameCallback` at line 425): `context.go('/accounts')` at line 150 — change to `context.go('/settings')`.

The post-frame auto-pop in `_NotFoundSurface` fires when the form is mounted with a `:id` that the repository can't find. The user lands on Settings; no error toast is shown (the form's normal "couldn't load" UI flashes briefly first, which is acceptable for a deep-link-with-bad-id corner case).

After the refactor, `grep -n "/accounts" lib/features/accounts/account_form_screen.dart` should return zero matches outside import statements / generated code.

### 6.3 Removed-route safety

All in-repo callers and tests are updated to the new paths in this change. The success criterion in §10 is `grep -rn "'/accounts" lib/ test/` returns zero matches for product-route paths.

No compatibility redirect is added.

## 7. Documentation Updates

### 7.1 PRD

`PRD.md` references `Accounts` as a top-level concept in many places beyond the obvious sections. The implementer must update **every match**, not just the section list below. To enforce this, the success criterion is a literal grep:

```
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
```

After the refactor, this should return **only**:

- the internal feature-slice name (e.g., "the accounts feature slice")
- `Manage accounts` (the new Settings entry-point name)
- intentional historical references (e.g., changelog entries)

> **The grep is a manual review checkpoint, not an automated CI gate.** The regex emits all matches; a human must read each one and confirm it falls in the allowed-list above. A line that says "users can find Accounts in the Analysis tab" matches the regex AND is wrong — the grep cannot tell. If you want CI enforcement, maintain a `docs/.accounts-allowed-mentions.txt` allowlist and have CI compare against it; that is out of scope for this refactor.

PRD locations identified during review that are NOT obvious from section names (line numbers approximate, may shift):

- `~670` — `"Navigation uses go_router with a StatefulShellRoute for the bottom navigation, so Home / Accounts / Settings preserve independent state when switching tabs."`
- `~680-684` — hardcoded route table with `/accounts/new`, `/accounts/shopping-list`, etc.
- `~692` — route-stacking explanation that names `/accounts/shopping-list/:itemId`
- `~702` — `"Bottom navigation on phone: Home, Accounts, Settings"`
- `~711` — `"without requiring a visit to the Accounts screen"`
- `~714` — `"without visiting Accounts, Categories, or Settings"`
- `~721` — `"Accounts Screen — Always shows a shopping-list preview card..."`
- `~746` — `"Accounts: if no active account exists, show Create account CTA"`
- `~770` — `"Accounts tab → shopping-list preview card shows newest drafts"` (the current Shopping List Draft Flow section)

Sections that obviously change:

- phased roadmap text that describes shopping-list access
- routing structure (`/analysis`, `/home/shopping-list`, `/settings/manage-accounts/*`)
- MVP screens list
- navigation description
- Home screen description
- Settings screen description
- any account-page description that still implies top-level account management or shopping-list preview

Required wording changes:

- rename the middle destination from `Accounts` to `Analysis`
- describe `Analysis` as Phase 2 chart placeholder in MVP
- rewrite the Settings description to include `Manage accounts` as the account-management entry
- describe shopping list as Home-owned via the shopping-cart button
- update the `Shopping List Draft Flow` section to reference Home, not Accounts

### 7.2 README

`README.md` should match the same user-facing structure. Run the same grep:

```
grep -nE "Accounts(/| |$|\.|,|:)" README.md
```

Remaining matches after the refactor should be: feature-slice name in the project layout, or `Manage accounts` (the Settings entry).

The README should explain that:

- `Analysis` exists but is intentionally empty in MVP
- accounts are managed from `Settings > Manage accounts`
- shopping list is entered from the Home shopping-cart button

## 8. Affected Product Surfaces

Source files:

- `lib/app/router.dart`
- `lib/app/widgets/adaptive_shell.dart`
- `lib/features/analysis/analysis_screen.dart` (new)
- `lib/features/home/home_screen.dart`
- `lib/features/shopping_list/shopping_list_screen.dart`
- `lib/features/shopping_list/widgets/shopping_list_card.dart` (deleted, see §5.2)
- `lib/features/settings/widgets/manage_accounts_tile.dart` (renamed from `default_account_tile.dart`)
- `lib/features/settings/widgets/manage_accounts_sheet.dart` (renamed from `default_account_picker_sheet.dart`)
- `lib/features/accounts/accounts_screen.dart` (deleted)
- `lib/features/accounts/widgets/manage_accounts_body.dart` (new — relocated private classes from the deleted screen)
- `lib/features/accounts/widgets/account_tile.dart` (minimal change: `_TrailingActions` for archived rows + `onEdit` callback wiring)
- `lib/features/accounts/account_form_screen.dart` (two fallback updates)
- `lib/features/transactions/transaction_form_screen.dart` (one route update)
- `lib/features/transactions/widgets/account_picker_sheet.dart` (one route update)
- `lib/l10n/*.arb` (new keys per §3.7, plus `Manage accounts` / `Analysis` nav labels; reuse existing keys where possible — see §3.7)
- `PRD.md`
- `README.md`

Test files (non-exhaustive — driven by the grep success criterion):

- `test/unit/app/router_test.dart` (route assertions migrate from `/accounts*` to `/settings/manage-accounts/*` and `/home/shopping-list*`)
- `test/widget/features/home/home_shopping_list_fab_test.dart`
- `test/widget/features/shopping_list/shopping_list_card_test.dart` (deleted)
- `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart` (deleted)
- new tests per §9

## 9. Testing Expectations

Tests are organized below by behavior, not by widget class. The architectural-layer test directory layout (per `CLAUDE.md`) is unchanged.

### 9.1 Routing — what each route does

- `/analysis` renders the `AnalysisScreen` placeholder
- `/settings/manage-accounts/new` renders `AccountFormScreen` as a root-navigator modal route, regardless of cold-start vs in-session entry
- `/settings/manage-accounts/:id` with an invalid id renders `_NotFoundSurface` and post-frame-redirects to `/settings` silently (§3.6.2)
- `/home/shopping-list` renders the shopping-list screen on the Home branch
- `/home/shopping-list/:itemId` uses the root navigator for draft editing
- `grep -rn "'/accounts" lib/ test/` returns zero matches for product-route paths after the refactor

### 9.2 Navigation behaviors

- tapping the shopping-cart button on Home navigates to `/home/shopping-list`
- back from `/home/shopping-list` returns to Home
- tab-switching from Home (with shopping-list pushed) to Analysis and back preserves `/home/shopping-list` on top of the Home branch
- a draft modal at `/home/shopping-list/:itemId` (root-navigator modal) covers all tabs while mounted; on pop the user lands on whichever Home branch state was beneath
- drag-dismissing the bottom sheet while the form route is on top of it pops the sheet first; subsequent form pop lands the user on `/settings` via the §6.2 fallback
- tapping `Manage accounts` in Settings opens the `Manage accounts` sheet (<600dp) or dialog (≥600dp)
- back / scrim on the form route while `Manage accounts` is open returns to the still-open surface (§3.6.3)
- back / scrim on the surface while no form is open returns to Settings
- cold-start `/settings/manage-accounts/new` cancel/save lands on `/settings`

### 9.3 `Manage accounts` interaction behaviors

(Behavior tests, not widget-internal tests. They drive the surface widget; they do not assert on `AccountTile`'s mode.)

- the body renders `AccountTile` rows for active accounts (assert via `find.byType(AccountTile)` count)
- the default account row shows the default badge in-place
- tapping an active row's body navigates to `/settings/manage-accounts/:id`
- the active row overflow menu exposes `Edit`, `Set as default` (when not default), and `Archive` or `Delete` per affordance
- the archived row overflow menu exposes only `Edit`
- tapping an archived row's body navigates to `/settings/manage-accounts/:id`
- `Set as default` from overflow keeps the surface open and shows a `SnackBar`
- `Set as default` from the start-pane swipe action behaves identically to the overflow item
- `Archive` of the last active account triggers the existing blocking dialog; surface remains open
- `Archive`/`Delete` of the current default account triggers the existing blocking dialog
- successful `Archive` removes the row from the active section and adds it to the archived section reactively
- the `Create account` CTA is visible in both empty and populated states
- tapping the CTA pushes `/settings/manage-accounts/new` without dismissing the surface
- after a successful create when at least one active default already exists, the surface remains open, the new account appears, and the existing default is unchanged
- after a successful create when zero active accounts existed before save, the surface remains open and the new account becomes the default (auto-default empty-state boundary, §3.6)
- after a successful edit, the surface remains open and the edited row reflects the change

### 9.4 `Manage accounts` loading and error states

- while the controller is loading, the body shows a `CircularProgressIndicator`; the title and CTA remain visible (three-zone Column skeleton, §3.4.1)
- when the controller emits `AsyncError`, the body shows the inline error placeholder with a `Retry` button
- tapping `Retry` invalidates the provider, transitions to Loading, and disables the Retry button until the next emission
- repeated taps on Retry while a previous invalidate is in-flight have no effect (button is `onPressed: null`)
- error-path SnackBars from §6.1 do not stack — each call clears prior SnackBars first
- when the user's account list is empty, the empty-state copy renders above the CTA

### 9.5 `AccountTile` widget tests

- `AccountTile` overflow menu emits the `onEdit` callback when its menu item is selected (active row)
- `AccountTile` overflow menu emits the `onEdit` callback for archived rows (new — replaces the prior `SizedBox.shrink()` behavior)
- archived rows' `Slidable` panes are suppressed
- existing balance / default badge rendering is unchanged

### 9.6 Add-Transaction inline create-account flow

- from the transaction-form's `account_picker_sheet`, tapping `Create account` pushes `/settings/manage-accounts/new`
- on save, the returned `int?` account id auto-selects in the transaction form
- on cancel, the transaction form's selected account is unchanged

### 9.7 Documentation and localization verification

- `grep -nE "Accounts(/| |$|\.|,|:)" PRD.md` returns only allowed matches (feature-slice name, `Manage accounts`, intentional historical refs)
- `grep -nE "Accounts(/| |$|\.|,|:)" README.md` returns only allowed matches
- `grep -rn "'/accounts" lib/ test/` returns zero matches for product-route paths
- bottom-nav label says `Analysis`, not `Accounts`
- account-specific strings inside Settings and the account form remain correct

## 10. Success Criteria

This refactor is successful when:

- the middle shell destination is `Analysis` at `/analysis`
- `Analysis` is intentionally empty for MVP and clearly framed as a Phase 2 placeholder
- shopping list is entered only from the Home shopping-cart button, returns to Home on back, and survives tab-switch via `StatefulShellRoute.indexedStack`
- `Settings > Manage accounts` shows `AccountTile` rows in an adaptive sheet/dialog and is the only MVP account-management surface
- account create / edit / archive / delete / default flows are all available from `Manage accounts`, and all in-repo callers (including Add Transaction's create-account flow) reach the new routes
- existing account business rules still hold (last-active archive guard, default archive/delete guard, hard-delete invariants, grouped balances)
- `AccountTile`'s archived-row overflow menu exposes `Edit`
- `grep -rn "'/accounts" lib/ test/` returns zero matches for product-route paths
- `grep -nE "Accounts(/| |$|\.|,|:)" PRD.md README.md` returns only allowed matches
- `PRD.md` and `README.md` describe the new structure accurately
