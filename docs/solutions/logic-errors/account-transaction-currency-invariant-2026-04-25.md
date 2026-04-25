---
title: Account and transaction currency invariants for derived balances
date: 2026-04-25
category: logic-errors
module: transactions
problem_type: logic_error
component: database
symptoms:
  - Transactions could be saved with a currency that did not match the referenced account currency.
  - Account currency could be edited after transactions already referenced the account.
  - Derived account balances depended on assumptions that were not fully enforced in repository write paths.
root_cause: logic_error
resolution_type: code_fix
severity: high
related_components:
  - accounts
  - transaction_repository
  - account_repository
  - reactive_balance_streams
tags:
  - flutter
  - dart
  - ledger
  - currency
  - money
  - repository
  - drift
  - regression-test
---

# Account and transaction currency invariants for derived balances

## Problem

`AccountRepository.watchBalanceMinorUnits()` was intended to expose a trustworthy native-currency balance for each account. That was only true if transaction and account currencies stayed aligned, but the repository layer did not fully enforce that invariant.

## Symptoms

- `watchBalanceMinorUnits()` summed `transactions.amount_minor_units` for an account without independently proving those rows shared the account currency.
- Non-UI writers could bypass the form rule that transaction currency is inherited from the selected account.
- Editing category metadata such as `icon` caused balance streams to re-emit even though the numeric result had not changed.
- The balance-stream contract documented account-row reactivity and missing-account `0` fallback, but those paths were not regression-tested.

## What Didn't Work

- Relying on UI behavior alone was not enough. The transaction form inherited the account currency, but repository write paths still accepted mismatched currency rows from non-UI callers.
- Broad `readsFrom` coverage on `categories` avoided one theoretical stale-stream path, but it caused false-positive emissions on irrelevant metadata edits.

## Solution

The fix moved the currency and balance assumptions into repository-level enforcement and locked the behavior with regression tests.

1. Reject transaction/account currency mismatches in `TransactionRepository.save()`.

`lib/data/repositories/transaction_repository.dart`

```dart
final account = await _accountDao.findById(tx.accountId);
if (account != null && account.currency != tx.currency.code) {
  throw TransactionAccountCurrencyMismatchException(
    accountId: tx.accountId,
    accountCurrencyCode: account.currency,
    transactionCurrencyCode: tx.currency.code,
  );
}
```

2. Reject account currency changes after transactions already reference that account.

`lib/data/repositories/account_repository.dart`

```dart
final stored = await _dao.findById(account.id);
if (stored.currency != account.currency.code && await isReferenced(account.id)) {
  throw AccountRepositoryException(
    'Account ${account.id} currency cannot change after transactions exist',
  );
}
```

3. Narrow `watchBalanceMinorUnits()` invalidation to the tables that actually change the computed value at runtime: `accounts` and `transactions`.

`lib/data/repositories/account_repository.dart`

```dart
readsFrom: {_db.accounts, _db.transactions}
```

This keeps opening-balance edits and transaction writes reactive while ignoring irrelevant category metadata changes.

4. Add regression tests for the cases that should and should not re-emit.

- `T-currency-fk-02`: transaction/account currency mismatch is rejected
- `AC11b`: referenced account currency cannot change
- `ACB07b`: opening-balance edits re-emit
- `ACB07c`: missing account emits `0`
- `ACB07d`: unrelated category metadata edits do not re-emit

## Why This Works

- The balance aggregate is only meaningful if every transaction on the account uses the account currency and if the account currency cannot later drift.
- Enforcing both rules in repository write paths makes the repository layer the source of truth instead of trusting higher-level form behavior.
- Restricting `readsFrom` to `accounts` and `transactions` matches the real mutable inputs to the computed balance, so category metadata updates no longer trigger spurious emissions.
- The added tests lock down the previously uncovered invariant gaps so future refactors are more likely to fail in tests than silently corrupt money semantics.

## Prevention

- When a derived query depends on a domain invariant, enforce that invariant in the repository that owns the write path rather than relying on UI conventions.
- Only include a table in Drift `readsFrom` if writes to that table can change the emitted value in supported runtime flows.
- Add regression tests for both:
  - writes that must trigger re-emission
  - writes that must not trigger re-emission
  - invalid persisted states that must be rejected

Keep these regression cases in place:

- transaction/account currency mismatch is rejected
- referenced account currency cannot change
- opening-balance edits re-emit
- missing account emits `0`
- unrelated category metadata edits do not re-emit

Verification that passed for this fix:

- `flutter analyze`
- `flutter test`

## Related Issues

- `docs/solutions/logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md` — related on stream/reactivity testing patterns, but not the same problem.
- `docs/solutions/database-issues/drift-schema-v1-snapshot-drift-2026-04-23.md` — adjacent on Drift/data-contract correctness.
- `docs/solutions/database-issues/flat-category-schema-contract-2026-04-22.md` — another contract-drift prevention example.
