---
title: Recurring generation timing, schedule recomputation, and recurring-reference guards
date: 2026-05-08
category: logic-errors
module: recurring-transactions
problem_type: logic_error
component: recurring_generation
symptoms:
  - Editing a recurring rule's schedule kept the old `next_due_date`.
  - Catch-up capping could persist a still-due `next_due_date`, causing repeated due-state on the next run.
  - Cold-start recurring generation blocked startup because bootstrap awaited it before `runApp`.
  - Accounts and categories referenced by active recurring rules could still be hard-deleted or archived.
  - The recurring form screen read `accountRepositoryProvider` directly instead of using a slice-local provider.
root_cause: logic_error
resolution_type: code_fix
severity: high
related_components:
  - bootstrap
  - recurring_rules_repository
  - recurring_generation_use_case
  - account_repository
  - category_repository
  - recurring_rule_form_screen
tags:
  - flutter
  - riverpod
  - drift
  - recurring-rules
  - bootstrap
  - next-due-date
  - archive-guard
  - regression-test
---

# Recurring generation timing, schedule recomputation, and recurring-reference guards

## Problem

The recurring-transactions slice had several connected integrity bugs: schedule edits preserved stale due dates, catch-up capping left rules still due, startup blocked on generation work, and account/category lifecycle guards ignored active recurring-rule references.

## Symptoms

- Editing a monthly or yearly rule could leave `next_due_date` on the pre-edit schedule.
- A stale daily rule that hit the catch-up cap could still be due immediately after generation completed.
- `bootstrapFor()` awaited recurring generation before `runApp`, turning due-rule work into startup latency.
- Deleting an account referenced only by recurring rules hit a raw SQLite FK failure instead of the typed repository guard.
- Archiving an account or category referenced by an active recurring rule succeeded, leaving a logically invalid active rule behind.
- The recurring form screen violated the repo's UI/provider boundary by watching `accountRepositoryProvider` directly.

## What Didn't Work

- Reusing `stored.nextDueDate` in `RecurringRulesRepository.update()` was only safe for memo/amount edits, not schedule edits.
- Fast-forwarding to the most recent occurrence during catch-up capping was not enough by itself; persisting that date meant the rule was still due.
- Letting bootstrap do generation inline preserved first-paint pending rows, but it violated the startup contract and made app launch depend on recurring work.
- Relying on the database FK for recurring-rule references produced opaque delete failures and let archive flows bypass the intended repository invariants.

## Solution

1. Recompute `next_due_date` when a rule's schedule fields change.

`lib/data/repositories/recurring_rules_repository.dart`

```dart
final scheduleChanged = stored.frequency != draft.frequency ||
    stored.dayOfWeek != draft.dayOfWeek ||
    stored.dayOfMonth != draft.dayOfMonth ||
    stored.monthOfYear != draft.monthOfYear;
final nextDueDate = scheduleChanged
    ? _computeInitialNextDue(draft, effectiveToday)
    : stored.nextDueDate;
```

This keeps future-only edit semantics while ensuring future generations follow the new schedule immediately.

2. Advance past the capped occurrence before persisting.

`lib/data/use_cases/recurring_generation_use_case.dart`

```dart
if (generated == catchUpCap && !_isAfter(currentDue, today)) {
  currentDue = recurringRepo.fastForwardToRecent(
    rule,
    today,
    safetyCap: _fastForwardSafetyCap,
  );
  currentDue = recurringRepo.advanceDateByFrequency(rule, currentDue);
  capped = true;
}
```

After capping, `next_due_date` now points to the first un-generated occurrence after today instead of a still-due row.

3. Move recurring generation off the bootstrap critical path.

`lib/app/bootstrap.dart`

```dart
child: App(
  onFirstFrame: () {
    unawaited(() async {
      try {
        await runRecurringGenerationFn(db);
      } on Object {
        // Generation failures must not crash or block startup.
      }
    }());
  },
),
```

`lib/app/app.dart`

```dart
widget.schedulePostFrameCallback(_runFirstFrameCallback);

void _runFirstFrameCallback() {
  if (_ranFirstFrameCallback || !mounted) return;
  _ranFirstFrameCallback = true;
  widget.onFirstFrame?.call();
}
```

Bootstrap still seeds before launch, but recurring generation now runs from the app's first-frame callback instead of blocking `runApp`.

4. Extend account/category lifecycle guards to include active recurring rules.

`lib/data/database/daos/recurring_rule_dao.dart`

```dart
Future<int> countActiveByAccount(int accountId) async { ... }
Future<int> countActiveByCategory(int categoryId) async { ... }
```

`lib/data/repositories/account_repository.dart`

```dart
final recurringCount = await _recurringDao.countActiveByAccount(id);
if (recurringCount > 0) throw AccountInUseException(id);
```

```dart
if (recurringCount > 0) {
  throw AccountHasRecurringRuleException(id);
}
```

`lib/data/repositories/category_repository.dart`

```dart
final recurringCount = await _recurringDao.countActiveByCategory(id);
if (recurringCount > 0) {
  throw CategoryInUseException(id);
}
```

```dart
if (recurringCount > 0) {
  throw CategoryHasRecurringRuleException(id);
}
```

Delete now returns typed in-use failures instead of SQLite FK errors, and archive is blocked when it would leave an active recurring rule pointing at an archived dependency.

5. Keep recurring form reads inside slice-local providers.

`lib/features/recurring/recurring_rules_providers.dart`

```dart
final recurringActiveAccountsProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAll();
});
```

`lib/features/recurring/recurring_rule_form_screen.dart`

```dart
final asyncAccounts = ref.watch(recurringActiveAccountsProvider);
```

That preserves the repo rule that widgets consume feature-local provider surfaces instead of repository implementations directly.

6. Add regression coverage around the recurring save, guard, and bootstrap paths.

- `test/unit/repositories/recurring_rules_repository_test.dart`
- `test/unit/use_cases/recurring_generation_use_case_test.dart`
- `test/unit/repositories/account_repository_test.dart`
- `test/unit/repositories/category_repository_test.dart`
- `test/unit/controllers/recurring_rule_form_controller_test.dart`
- `test/unit/app/bootstrap_order_test.dart`
- `test/integration/recurring_transaction_test.dart`

## Why This Works

- Schedule edits are a repository-owned invariant, so recomputing the due date there keeps the UI and use case simple.
- Catch-up capping is only correct if the persisted due date represents the next un-generated occurrence, not the last dropped one.
- Startup remains responsive when generation runs after first paint; the recurring engine still benefits from reactive pending-row updates once it finishes.
- Repository lifecycle guards are the only place that can consistently protect delete/archive behavior across all callers.
- Slice-local providers keep widgets aligned with the repo's `Data -> UI` architecture and avoid repository reads inside screen code.

## Prevention

- If a repository method changes scheduling fields, explicitly decide whether persisted denormalized dates must be recomputed.
- For capped generation loops, assert that the stored date is after the processed window, not merely aligned to the last matching occurrence.
- Treat bootstrap work as startup-critical only when the first frame truly depends on it; otherwise schedule it post-frame and cover that contract with a test.
- When introducing a new referencing table, update both hard-delete guards and archive semantics in the owning repositories.
- Keep feature widgets on slice-local providers even when the repository call looks read-only or convenient.

Verification that passed for this fix:

- `dart format .`
- `flutter analyze`
- `flutter test test/unit/app/bootstrap_order_test.dart test/unit/repositories/recurring_rules_repository_test.dart test/unit/use_cases/recurring_generation_use_case_test.dart test/unit/repositories/account_repository_test.dart test/unit/repositories/category_repository_test.dart test/unit/controllers/recurring_rule_form_controller_test.dart test/widget/features/recurring/recurring_rule_form_screen_test.dart test/widget/features/recurring/recurring_rules_screen_test.dart test/integration/recurring_transaction_test.dart`

## Related Issues

- `docs/solutions/logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md` — prior first-frame/bootstrap timing work in the app shell.
- `docs/solutions/logic-errors/transaction-form-workflow-integrity-2026-04-25.md` — similar controller/widget workflow-integrity pattern for form flows.
