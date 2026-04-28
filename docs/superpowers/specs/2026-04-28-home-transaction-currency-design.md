# Ledgerly Home Day Navigation And Transaction Currency Design

## Context

Ledgerly's current Home and Transactions flows are close to the requested
behavior, but three product rules are still misaligned with the desired MVP:

- Home can land on a manually picked gap day, but it renders a centered text
  empty state instead of a transaction-style card.
- Home navigation buttons are still modeled around days with activity, while the
  requested behavior is calendar-day browsing, including empty days.
- Transactions currently inherit currency from the selected account, and the
  repository enforces that account and transaction currencies always match.

The user also wants Phase 2 planning in `PRD.md` to explicitly cover fetched FX
rates and default-currency aggregation.

## Goals

- Show a transaction-style empty card on Home when the selected day has no
  transactions.
- Make Home date navigation move across real calendar days, not only days with
  activity.
- Add a horizontal swipe transition animation for Home date changes.
- Promote transaction currency to a true transaction-level field in add, edit,
  and duplicate flows.
- Allow mixed-currency transactions within a single account during MVP.
- Clarify the Phase 2 FX-rate roadmap in `PRD.md`.

## Non-Goals

- Do not add FX conversion, rate entry, or default-currency total calculation in
  MVP.
- Do not silently convert or reinterpret amounts when currency changes.
- Do not replace the first-run Home onboarding CTA with the new empty-day card.
- Do not introduce hidden account auto-switching when a transaction currency is
  changed.

## Approved Design

### Home Behavior

- Preserve the current first-run empty state when the app has no transaction
  history at all.
- Once the user has transaction history, treat `selectedDay` as a true calendar
  day pointer.
- Keep the summary strip semantics unchanged: it continues to show actual-today
  totals and month-to-date net for the current month, even while the user browses
  a different `selectedDay` below it.
- Prev and next navigation step exactly one calendar day backward or forward.
- Horizontal Home swipes use the same one-day calendar stepping rule.
- Calendar-day navigation uses the same broad date limits as the Home date
  picker. Prev and next remain available until those hard bounds are reached,
  even if intermediate days are empty.
- When the selected day is empty, render a transaction-style card with the text
  `No transaction` instead of the current text-only gap-day empty state, backed
  by a localized string rather than hard-coded English copy.
- When a transaction is added for that day, replace the empty card with the
  normal transaction list card.
- Apply a horizontal transition to the Home day-content area so swipe,
  prev/next, and date-picker changes all feel like the same day-switch action.
- The Home transition should run only when the visible day actually changes. A
  save round-trip that returns to the same `selectedDay` should update in place
  without a day-switch animation.

### Transaction Currency Behavior

- Transaction currency becomes an explicit field in add, edit, and duplicate
  flows.
- Add flow still seeds sensible defaults, but the user can change currency
  independently of the selected account.
- Add flow should seed currency from the initially selected account, then allow
  the user to override it.
- Duplicate flow copies the original transaction currency by default, even when
  that currency differs from the duplicated transaction's account currency.
- Edit flow hydrates and saves the stored transaction currency directly.
- Changing currency with a non-zero amount requires confirmation and clears the
  entered amount if the user proceeds.
- MVP never auto-converts the amount when currency changes.
- Account changes and currency changes are no longer a hard-coupled pair. If the
  user changes account after currency has been seeded or manually changed, the
  selected transaction currency stays as-is unless the user explicitly changes it
  again.

### Account Behavior

- `accounts.currency` remains meaningful, but it becomes the account's default
  or preferred currency rather than a hard restriction on every attached
  transaction.
- Opening balance remains associated with the account's own currency.
- Accounts may contain transactions in multiple currencies.
- In MVP, account totals are shown grouped by transaction currency rather than
  forced into a single synthetic balance.
- The account's own currency group is the only group that includes
  `opening_balance_minor_units`; it is combined with the net of same-currency
  transactions.
- All other rendered currency groups are transaction-net-only groups.
- Single-currency accounts should continue to render compactly.
- Mixed-currency accounts should show a grouped balance summary rather than a
  fake converted total.
- Zero-value groups should not render.

### MVP Currency Policy

- `transactions.currency` is the source of truth for transaction-level currency.
- `accounts.currency` defines account defaults and opening-balance currency, not
  a transaction-currency invariant.
- Home and Accounts summaries remain grouped by original currency in MVP.
- Planning should assume grouped account totals are represented as per-currency
  minor-unit nets keyed by currency code rather than a single scalar balance.
- Phase 2 may derive unified totals in the user's default currency, but only as
  additive display data backed by fetched FX rates.

## Error Handling And Edge Cases

- Ignore overlapping swipe gestures while the Home day transition animation is
  already in flight.
- Keep the existing save and delete failure behavior on the transaction form:
  stay on screen and surface snackbar feedback.
- Never hide mixed-currency account state behind a misleading single-number
  balance in MVP.
- Keep add, edit, and duplicate aligned on the same transaction-currency rule so
  the form stays predictable.

## PRD Follow-Up

`PRD.md` should be updated to reflect these approved product decisions:

- Home screen description: Home browses real calendar days, including empty
  days, and renders a transaction-style `No transaction` card on gap days.
- Home screen states: first-run onboarding CTA remains distinct from the
  per-day empty card.
- Add/Edit Transaction rules: currency is a transaction-level field available in
  add, edit, and duplicate flows.
- Accounts behavior: account totals are grouped by transaction currency in MVP
  when an account contains mixed-currency activity.
- MVP currency policy: grouped-by-original-currency summaries remain the MVP
  behavior.
- Phase 2 roadmap: explicitly call out fetching FX rates and computing
  default-currency totals for Home, Accounts, and other summary surfaces while
  preserving original transaction amounts and currencies.

## Affected Product Surfaces

- `lib/features/home/home_screen.dart`
- `lib/features/home/home_controller.dart`
- `lib/features/home/home_state.dart`
- `lib/features/home/widgets/transaction_tile.dart`
- `lib/features/transactions/transaction_form_screen.dart`
- `lib/features/transactions/transaction_form_controller.dart`
- `lib/features/accounts/accounts_controller.dart`
- `lib/features/accounts/widgets/account_tile.dart`
- `lib/data/repositories/transaction_repository.dart`
- `lib/data/repositories/account_repository.dart`
- `PRD.md`

## Testing Expectations

- Unit tests for Home date navigation across calendar days, including gap days.
- Widget tests for the Home empty-day card, first-run CTA preservation, and
  visible day-content switching.
- Controller and repository tests for independent transaction currency in add,
  edit, and duplicate flows.
- Repository and Accounts tests for grouped per-currency account totals.
- Coverage for the non-conversion rule when transaction currency changes.

## Deferred To Planning

- Exact motion primitive for the Home day transition.
- Exact mixed-currency balance presentation within the existing Accounts row
  layout.
- Whether grouped account totals should include labels, chips, or stacked text
  treatment when more than one currency is present.
