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
- Allow mixed-currency transactions within a single account during MVP. This
  enables users who pay in a foreign currency from a domestic account (e.g. a
  EUR charge on a USD card) to record it accurately without creating a separate
  account per currency. The account's own currency remains the
  opening-balance currency; Phase 2 will add FX-rate-derived unified totals on
  top.
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
- The summary strip reflects the totals for `selectedDay` and the
  month-to-date net for `selectedDay`'s month. When `selectedDay` differs from
  today, a **Jump to today** button is visible to reset it. The strip always
  shows `selectedDay`'s context — there is no separate today-anchored summary.
- Prev and next navigation step exactly one calendar day backward or forward.
- The next button is capped at today in MVP; browsing future dates is not
  supported. The prev button follows the date picker's lower bound.
- Horizontal Home swipes use the same one-day calendar stepping rule. Swiping
  left advances to the next day (new content enters from the right); swiping
  right retreats to the previous day (new content enters from the left). Prev
  and next buttons follow the same spatial convention.
- Rapid swipes accumulate pending steps. Each animation cycle advances one
  calendar day and decrements the counter; swiping during a running animation
  increments or decrements the pending count without cancelling the in-flight
  step.
- Calendar-day navigation uses the date picker's lower bound (year 1900). Prev
  and next remain available until those hard bounds are reached, even if
  intermediate days are empty.
- When the selected day is empty, render a transaction-style card inside a
  `SliverToBoxAdapter` (matching the height of a single transaction card) with
  the text from localization key `homeEmptyDayMessage` (English: `No
  transaction`) instead of the current text-only gap-day empty state.
- When a transaction is added for that day, replace the empty card with the
  normal transaction list card.
- Apply a horizontal transition to the Home day-content area so swipe,
  prev/next, and date-picker changes all feel like the same day-switch action.
  Date-picker jumps use the same transition; the direction is forward (content
  enters from the right) when the picked date is later than the current
  `selectedDay`, and backward when earlier.
- The Home transition should run only when the visible day actually changes. A
  save round-trip that returns to the same `selectedDay` should update in place
  without a day-switch animation. This rule applies whether the list gained,
  lost, or changed a transaction.
- Add Transaction launched from a gap day prefills `date` to that gap day. Save
  returns to Home with `selectedDay` pinned to the saved date, replacing the
  empty card with the new transaction card.
- All new Home widgets (empty-day card, multi-currency summary rows) must
  survive 2× text scale. The empty-day card follows transaction-row reflow rules
  (reflows at 1.5×).

### Transaction Currency Behavior

- Transaction currency becomes an explicit field in add, edit, and duplicate
  flows.
- The currency field renders as a tappable row showing the currency code and
  name. Tapping opens a bottom sheet with a searchable list of ISO 4217
  currencies, displaying code + full name per row.
- Add and duplicate flows seed currency from the selected account's default
  currency. The user can change it independently.
- Add flow tracks a `currencyTouched` flag. If the user changes account before
  manually changing currency, currency re-seeds from the new account's default.
  Once the user has explicitly changed currency, subsequent account changes
  leave it unchanged.
- Duplicate flow follows the same seeding rule as Add: currency seeds from the
  selected account's default, not from the original transaction's currency. The
  `currencyTouched` flag rule applies identically.
- Edit flow hydrates and saves the stored transaction currency directly.
- Changing currency with a non-zero amount requires confirmation. The
  confirmation dialog shows: title **Change currency?**, body **The amount
  entered will be cleared**, a destructive-tinted **Change and Clear** confirm
  button, and a **Cancel** button. Tapping Cancel reverts the currency selector
  to its previous value. Tapping Change and Clear empties the amount field and
  keeps the new currency. After clearing, the amount field shows placeholder
  text **Enter amount in [currency code]** so the cleared state is visible.
- MVP never auto-converts the amount when currency changes.
- Account changes and currency changes are no longer a hard-coupled pair. The
  only coupling remaining is the `currencyTouched` re-seed rule described above.

### Account Behavior

- `accounts.currency` is the account's opening-balance currency and the default
  seed for new transactions. It is not a hard restriction on every attached
  transaction. `accounts.currency` is immutable once an account is created;
  the opening-balance currency cannot change after the fact. This preserves the
  integer minor-unit integrity of `opening_balance_minor_units` across
  currencies with different decimal scales.
- Opening balance remains associated with the account's own currency.
- Accounts may contain transactions in multiple currencies.
- In MVP, account totals are shown grouped by transaction currency rather than
  forced into a single synthetic balance.
- The account's own currency group is the only group that includes
  `opening_balance_minor_units`; it is combined with the net of same-currency
  transactions.
- All other rendered currency groups are transaction-net-only groups.
- Single-currency accounts continue to render compactly (one total line).
- Mixed-currency accounts render a stacked plain-text summary: one line per
  currency group (`[code]: [formatted amount]`). When more than three currency
  groups are present, the first two groups are shown and a `+N more` indicator
  is appended. Zero-value groups do not render.
- Mixed-currency account rows must survive 2× text scale; rows expand rather
  than clip as currency groups are added.
- All per-category and other cross-transaction aggregations follow the same
  grouped-by-currency rule in MVP, with zero-value groups suppressed.

### Repository Contract Changes

- `AccountRepository.watchBalanceByCurrency(int accountId) → Stream<Map<String, int>>`
  is introduced for the Accounts display surface. The map key is the ISO 4217
  currency code; the value is the net minor-unit amount for that currency group,
  including `opening_balance_minor_units` for the account's own currency group.
  The frozen Wave 0 scalar `watchBalanceMinorUnits` is deliberately superseded
  by this new signature.
- The `TransactionAccountCurrencyMismatchException` guard in
  `TransactionRepository.save` is removed. Transactions may now record any
  currency regardless of the account's default.
- The `accounts.currency` immutability guard in `AccountRepository.save`
  (prevents changing `accounts.currency` after an account exists) is **kept** to
  protect `opening_balance_minor_units` integrity.
- `TransactionFormState.displayCurrency` becomes the user-controlled transaction
  currency, no longer a mirror of `selectedAccount.currency`. A new
  `selectCurrency(Currency)` command is added, which owns the
  confirm-and-clear gate. `selectAccount` is decoupled from currency mutation
  and only triggers a re-seed when `currencyTouched` is false. `save()` persists
  `state.displayCurrency` rather than `state.selectedAccount.currency`.
- No Drift schema migration is required. `transactions.currency` is already a
  non-null FK column and is the SSOT. `schemaVersion` stays at its current
  value; no new file under `drift_schemas/` is needed for this change.

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

- Rapid swipe steps accumulate; the animation processes one day per cycle without
  dropping pending steps (see Home Behavior above).
- Keep the existing save and delete failure behavior on the transaction form:
  stay on screen and surface snackbar feedback.
- Never hide mixed-currency account state behind a misleading single-number
  balance in MVP.
- Keep add, edit, and duplicate aligned on the same transaction-currency rule so
  the form stays predictable.

## PRD Follow-Up

`PRD.md` should be updated to reflect these approved product decisions:

- Home screen description: Home browses real calendar days, including empty
  days, and renders a transaction-style `No transaction` card on gap days. The
  summary strip follows `selectedDay`; a **Jump to today** button appears when
  `selectedDay` differs from today.
- Home screen states: first-run onboarding CTA remains distinct from the
  per-day empty card.
- Add/Edit Transaction rules: currency is a transaction-level field available in
  add, edit, and duplicate flows, seeded from the selected account's default and
  independently overridable.
- Accounts behavior: account totals are grouped by transaction currency in MVP
  when an account contains mixed-currency activity, using stacked plain-text
  rows with a `+N more` indicator when more than three groups are present.
- MVP currency policy: grouped-by-original-currency summaries remain the MVP
  behavior for all aggregations including Home, Accounts, and category totals.
- Phase 2 roadmap: explicitly call out fetching FX rates and computing
  default-currency totals for Home, Accounts, and other summary surfaces while
  preserving original transaction amounts and currencies. FX rates are stored in
  a separate `exchange_rates(date, base_code, quote_code, numerator, denominator)`
  table joined at read time; transaction rows are never mutated retroactively.

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
- Widget tests for the **Jump to today** button: visible when `selectedDay` ≠
  today, hidden when `selectedDay` = today.
- Controller and repository tests for independent transaction currency in add,
  edit, and duplicate flows.
- Controller tests for the `currencyTouched` flag: account change before
  user-initiated currency change re-seeds; account change after does not.
- Repository and Accounts tests for `watchBalanceByCurrency`: opening-balance
  inclusion only in the account's own currency group, zero-group suppression,
  and correct net per group.
- Coverage for the non-conversion rule when transaction currency changes.
- Tests confirming `TransactionAccountCurrencyMismatchException` no longer fires
  when transaction currency differs from account currency.

## Deferred To Planning

- Exact motion primitive (easing curve, duration) for the Home day transition.
