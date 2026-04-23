# M5 Wave 1 — Accounts Slice

**Source of truth:** [`PRD.md`](../../../../PRD.md) → *MVP Screens → Accounts*, *accounts / account_types schema*, *Default Account Types*, *Management Rules*. Contracts inherited from [`wave-0-contracts-plan.md`](../wave-0-contracts-plan.md).

Accounts owns the `/accounts` tab: a list of user accounts with native-currency tracked balances, an add/edit flow, inline account-type creation, set-default, and archive.

Balance rendering depends on `AccountRepository.watchBalanceMinorUnits(int)`, which is added in Wave 0 (see [`wave-0-contracts-plan.md`](../wave-0-contracts-plan.md) §2.8). This slice has no Platform prerequisites beyond the Wave 0 PR merging — every contract it reads, including the new balance stream, is on main before the Accounts agent starts.

---

## 1. Goal

Replace the M4 placeholder at `lib/features/accounts/accounts_screen.dart` with a full list screen, new-account form, inline account-type creation, set-default, and archive affordances. All balances render in the account's native currency per PRD → *accounts* notes.

---

## 2. Inputs

| Dependency                          | Purpose                                                             | Import path                                  |
|-------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `accountRepositoryProvider`         | `watchAll`, `save`, `archive`, `delete`, `isReferenced`, `watchBalanceMinorUnits` (added in Wave 0 §2.8) | `app/providers/repository_providers.dart`    |
| `accountTypeRepositoryProvider`     | List account types for picker; create custom account type inline   | `app/providers/repository_providers.dart`    |
| `currencyRepositoryProvider`        | List currencies for the currency picker                            | `app/providers/repository_providers.dart`    |
| `userPreferencesRepositoryProvider` | Read `default_currency`, read/write `default_account_id`           | `app/providers/repository_providers.dart`    |
| `money_formatter.dart`              | Render minor-unit balances as localized strings                    | `core/utils/money_formatter.dart`            |
| `icon_registry.dart` / `color_palette.dart` | Render tile icon/color                                      | `core/utils/*.dart`                          |

The slice **does not** directly read transactions. Balance rendering goes exclusively through `watchBalanceMinorUnits`, which Wave 0 §2.8 added to `AccountRepository`.

---

## 3. Deliverables

### 3.1 Files (under `lib/features/accounts/`)

- `accounts_screen.dart` — replaces the M4 placeholder.
- `accounts_controller.dart` — `@riverpod class AccountsController extends _$AccountsController`. Commands: `setDefault(id)`, `archive(id)`, `delete(id)`, `unarchive(id)`.
- `accounts_state.dart` — Freezed sealed union (`Loading | Data(accounts: List<AccountWithBalance>, defaultAccountId: int?) | Error`). `AccountWithBalance` is a controller-owned view model (Freezed) pairing the domain `Account` with its derived balance minor units.
- `account_form_screen.dart` — full-page or bottom-sheet form for new account / edit account.
- `widgets/account_tile.dart` — list row (icon, name, account-type chip, balance right-aligned, swipe actions).
- `widgets/account_type_picker_sheet.dart` — select an existing account type OR create a new one inline (inline form returns a newly-saved `AccountType`).
- `widgets/currency_picker_sheet.dart` — filter/search over `currencies`.
- (optional) `widgets/amount_minor_units_field.dart` — numeric input for `opening_balance_minor_units` respecting the chosen currency's `decimals`.

### 3.2 ARB keys

Prefix: `accounts*` (UI). Do **not** add keys under `accountType*` — that prefix is reserved for seeded account-type display names (already present).

Minimum new keys: `accountsListTitle`, `accountsAddCta`, `accountsEmptyTitle`, `accountsEmptyCta`, `accountsSetDefaultAction`, `accountsDefaultBadge`, `accountsArchiveAction`, `accountsDeleteAction`, `accountsFormName`, `accountsFormType`, `accountsFormCurrency`, `accountsFormOpeningBalance`, `accountsFormIcon`, `accountsFormColor`, `accountsTypeCreateInlineCta`, `accountsTypeFormName`, `accountsTypeFormDefaultCurrency`. Full list discovered during implementation; all four ARBs updated in the same PR.

### 3.3 Tests

- `test/unit/controllers/accounts_controller_test.dart` — state transitions; `setDefault` updates `userPreferences`; `archive` flips `isArchived`; balance stream emission propagates into `AccountWithBalance`.
- `test/widget/features/accounts/accounts_screen_test.dart` — empty state CTA visible only when all accounts archived; default-badge rendering; swipe archive → undo snackbar; FAB opens form.
- `test/widget/features/accounts/account_form_screen_test.dart` — create account with seeded type, create account with inline new type, validation (name required, currency required, type required); opening balance respects currency decimals.

---

## 4. Screen layout

Accounts tab (bottom-nav at <600dp, NavigationRail at ≥600dp — already wired in M4 shell):

- `Scaffold` → `CustomScrollView` with:
  - `SliverToBoxAdapter` — header / title + default-account summary.
  - `SliverList` — `AccountTile` per account, ordered by `sortOrder` (nulls last) → name ascending. Archived accounts rendered at the bottom under a collapsible "Archived" section (per PRD → *Management Rules*: archived rows are hidden from pickers but visible in management screens).
  - `SliverPadding` — FAB clearance.
- FAB label: "Add account" — opens `account_form_screen` in Add mode.

Each tile shows: icon + color chip, account name, account type display, balance formatted via `money_formatter` in native currency, default badge if applicable. Swipe:
- Leading (or overflow): "Set as default" — only if not currently default.
- Trailing: Archive if `isReferenced(id)` OR if this is the only non-archived account (prevent leaving the user with zero active accounts — see §7); else Delete (only for unreferenced custom accounts with `opening_balance_minor_units == 0`).

---

## 5. Add/Edit account form (`account_form_screen.dart`)

Modal push per PRD → *Routing Structure* (`/accounts/new`, `/accounts/:id`).

Fields:
- **Name** — `TextField`. Required, non-empty.
- **Account type** — tap opens `account_type_picker_sheet`. Required. Inline "Create new account type" option opens a nested form (name, icon, color, default currency) that saves via `accountTypeRepositoryProvider.save` and returns the new `AccountType` to the outer form (Wave 0 §2.3 — this slice owns the inline creation flow).
- **Currency** — tap opens `currency_picker_sheet`. Defaults to `accountType.default_currency ?? userPreferences.default_currency`. User can override.
- **Opening balance** — numeric field respecting `currency.decimals`. Stored as minor units. Defaults to 0.
- **Icon** — string key (shared with Categories icon picker? — no; each slice owns its own widget, but both consume `iconRegistry`).
- **Color** — palette index.

Save enabled when: name non-empty, account type selected, currency selected. Save calls `accountRepositoryProvider.save(Account(...))`; the repository assigns the id and currency FK integrity is already enforced.

---

## 6. Set-default mechanics

`userPreferencesRepositoryProvider.setDefaultAccountId(id)` writes `default_account_id` in the `user_preferences` table. Accounts slice owns the trigger (overflow action + swipe option); Transactions slice reads the preference via the same repository in Wave 2.

The default-account row shows a visible badge. Setting a new default clears the badge on the previous default (reactively, via the stream).

Cannot set an archived account as default — the affordance is hidden on archived rows.

---

## 7. Archive and delete policy

Per PRD → *Management Rules* + *accounts* notes:
- Any account with `isReferenced(id) == true` can only be archived, not deleted.
- Unused custom accounts (no transactions, `opening_balance_minor_units == 0`) can be hard-deleted.
- Accounts are **never** deleted if they are the user's currently-set `default_account_id` — the slice must first require the user to pick a new default (surface a dialog).
- MVP invariant: there must always be at least one non-archived account. The controller refuses to archive the last active account; the widget surfaces this with a disabled swipe + tooltip. (PRD does not state this invariantly but the screen-state rule in *MVP Screens → Accounts* — "if no active account exists, show `Create account` CTA and block transaction save" — assumes the user can reach that state; we accept it but gate archive regardless.)

Undo snackbar on archive (`commonUndo`). Delete is final, preceded by a confirm dialog.

---

## 8. Cross-slice contract adherence (Wave 0)

- §2.3 — Accounts writes `default_account_id`; Transactions (Wave 2) reads it to preselect the account on Add Transaction. Accounts never inspects Transactions state directly.
- §2.3 — Splash settings live in Settings slice. Accounts never reads `splash_*` prefs.
- §2.4 — Do not edit `router.dart`, Drift tables, or the schema. `watchBalanceMinorUnits` is the only repository surface Accounts depends on beyond M3; it is already added in Wave 0 §2.8 and must not be re-edited here.
- §2.5 — All sub-widgets under `lib/features/accounts/widgets/`. `CurrencyPickerSheet` stays here (Accounts owns it for MVP — not promoted to `core/widgets/` unless Transactions also needs it, in which case Wave 2 requests promotion).

---

## 9. Out of scope (defer)

- Transfers between accounts — Phase 2.
- Credit-card payoff flows — Phase 2.
- Reconciliation — Phase 2.
- Auto-converted multi-currency totals — Phase 2 (PRD → *Extended multi-currency*).
- Wallet-linked accounts — Phase 2 (Ankr integration).

---

## 10. Exit criteria

- `accounts_screen.dart` renders `Loading`, `Data`, `Error`, and handles the "only archived accounts" edge case with an empty-state CTA.
- Create account, create inline account type, set default, archive, delete all work end-to-end against the in-memory Drift harness.
- Balance renders in the account's native currency via `money_formatter` (verified with USD + JPY + TWD fixtures).
- 2× text scale survives on list + form.
- `flutter analyze` clean.
- `flutter test` green, including the three tests from §3.3.

---

## 11. Sequencing

Single agent, single PR. Entry criterion: Wave 0 PR merged (so `watchBalanceMinorUnits` is on main).

1. Implement `accounts_state.dart` + `accounts_controller.dart` against the Wave 0 balance stream.
2. Implement `widgets/account_tile.dart`, `widgets/account_type_picker_sheet.dart`, `widgets/currency_picker_sheet.dart`.
3. Implement `account_form_screen.dart` including inline account-type creation.
4. Implement `accounts_screen.dart`, wiring swipe + overflow + default badge.
5. Add ARB keys (§3.2) across all four ARB files.
6. Write controller + screen + form widget tests.
7. Run `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`.
8. Open PR titled `feat(m5): accounts slice`.

---

## 12. Risks

1. **Raw SQL in controller.** Tempting when you want a quick extra aggregate the Wave 0 balance stream doesn't cover. Forbidden — any new aggregate goes through a repository method, not inline SQL. `import_lint` should catch `package:drift` imports under `features/`; reviewer vigilance backs it up.
2. **Archiving the default account.** Leaves the user in an invalid state (Transactions form cannot preselect). Guard: force a default-change dialog before archive if the target is the current default.
3. **Archiving the last active account.** Breaks first-run UX guarantees. Guard as described in §7.
4. **Currency picker performance.** With ~11 fiat currencies + future token rows, a simple `ListView` works. Do not introduce client-side search until Phase 2 token set lands.
5. **Inline account-type creation save failure.** The outer form should not lose its state when the inline flow errors. Keep the nested form in its own controller; propagate errors inline.
6. **Opening balance precision.** Users entering "100.5" into a JPY account (`decimals = 0`) must be rejected or rounded. The `amount_minor_units_field` widget snaps to the currency's decimals.
