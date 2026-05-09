---
title: Home pending recurring approval visibility, undo lifecycle, and feedback coordination
date: 2026-05-09
category: logic-errors
module: home
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Pending recurring rows on Home were unreachable when the selected day had no transaction history.
  - Skip-once undo state could be lost if the pending controller disposed before the undo timer completed.
  - Failed skip commits could leave a pending row hidden locally instead of restoring visibility.
  - Snackbar feedback could collide between skip-undo and approve-success actions in the pending section.
  - A repository reactivity regression test stayed red even after the production fixes landed.
root_cause: logic_error
resolution_type: code_fix
severity: high
related_components:
  - home_screen
  - pending_controller
  - pending_section
  - pending_transaction_dao
  - pending_transaction_repository_test
tags:
  - flutter
  - riverpod
  - home
  - pending-transactions
  - recurring
  - undo
  - drift
  - regression-test
---

# Home pending recurring approval visibility, undo lifecycle, and feedback coordination

## Problem

The Home pending-approval flow treated transaction history, controller lifetime, and optimistic row hiding as separate concerns. That let recurring pending rows disappear in the exact cases where the user still needed to act on them: empty-history Home days, mid-undo navigation/disposal, and failed skip commits.

## Symptoms

- Home showed the generic empty state even when recurring pending rows existed for the selected day.
- A skip-once undo window could be lost if `PendingController` was disposed before its timer fired.
- If `reject()` failed after a skip, the row could remain hidden with only generic failure feedback.
- Approve-success feedback could replace the skip undo snackbar, making the pending section feel noisy or contradictory.
- The last failing repository reactivity test suggested a production bug, but the real problem was a test-side raw SQL update that never notified Drift watchers.

## What Didn't Work

- Rendering the pending section only from the `HomeData` branch. That guaranteed pending rows were unreachable whenever Home emitted `HomeEmpty`.
- Letting `PendingController` use normal provider disposal semantics even though it owned an in-memory undo timer.
- Treating the final repository-test failure as more production DAO breakage. The production stream was already correct; the test was mutating `accounts` with `customStatement(...)`, which bypassed Drift's watcher notification path.

## Solution

1. Keep `PendingController` alive across screen disposal and let failed skip commits restore visibility automatically.

`lib/features/home/pending_controller.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [pendingTransactionRepository])
class PendingController extends _$PendingController {
  ...

  Future<void> _commitSkip(int pendingId) async {
    _skipScheduled = null;
    _composer?.notifySkipChanged();
    try {
      await ref.read(pendingTransactionRepositoryProvider).reject(pendingId);
    } catch (error, stackTrace) {
      _effectListener?.call(PendingSkipFailedEffect(error, stackTrace));
    }
  }
}
```

`keepAlive` keeps the undo timer and hidden-row bookkeeping alive while the screen is rebuilt or temporarily disposed. Clearing `_skipScheduled` before the repository call makes the row visible again immediately; if `reject()` succeeds, the repository stream removes it for real, and if `reject()` fails the row stays visible instead of getting stuck hidden.

2. Let Home's empty-state branch render pending approvals when there is no transaction history.

`lib/features/home/home_screen.dart`

```dart
final pendingState = ref.watch(pendingControllerProvider);
final hasVisiblePending = switch (pendingState) {
  AsyncData<PendingState>(value: final PendingData data) => data.items.any(
    (item) => item.id != data.skipScheduled?.pendingId,
  ),
  _ => false,
};

AsyncData<HomeState>(value: final HomeEmpty empty) =>
    hasVisiblePending
        ? _PendingOnlyBody(selectedDay: empty.selectedDay)
        : _EmptyState(onAdd: () => _onAddPressed(context)),
```

This keeps pending approvals reachable even when `HomeController` has no day activity and would otherwise choose the empty state.

3. Separate skip-undo feedback from approve-success feedback, and make the joined pending query explicitly reactive to archive changes.

`lib/features/home/widgets/pending_section.dart`

```dart
case PendingSkipStartedEffect():
  _skipUndoVisible = true;
  messenger
    ..clearSnackBars()
    ..showSnackBar(...).closed.then((_) {
      if (mounted) {
        _skipUndoVisible = false;
      }
    });
case PendingApproveSucceededEffect(:final ruleName):
  if (_skipUndoVisible) {
    return;
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(l10n.homePendingApprovedSnack(ruleName))),
    );
```

`lib/data/database/daos/pending_transaction_dao.dart`

```dart
return customSelect(
  'SELECT p.* '
  'FROM pending_transactions p '
  'LEFT JOIN accounts a ON a.id = p.account_id '
  'LEFT JOIN categories c ON c.id = p.category_id '
  "WHERE p.source = 'recurring' "
  'ORDER BY p.date DESC, p.id DESC',
  readsFrom: {pendingTransactions, accounts, categories},
).watch().map(
  (rows) => rows.map((row) => pendingTransactions.map(row.data)).toList(),
);
```

The first change prevents snackbar collisions while the skip undo window is still visible. The second tells Drift that the pending list depends on archive state in `accounts` and `categories`, not just on rows in `pending_transactions`.

4. Fix the repository reactivity test to use Drift-tracked updates instead of raw SQL side effects.

`test/unit/repositories/pending_transaction_repository_test.dart`

```dart
await db.customUpdate(
  'UPDATE accounts SET is_archived = 1 WHERE id = ?',
  variables: [Variable.withInt(accountId)],
  updates: {db.accounts},
);
```

That final red test was a harness problem, not a production defect. `customStatement(...)` changed the row, but it did not notify Drift's stream-query store, so the active `watchAll()` subscription never re-emitted.

5. Lock the behavior in with regression coverage.

- `test/unit/controllers/pending_controller_test.dart` now proves failed skip commits make the row visible again.
- `test/widget/features/home/home_screen_test.dart` covers the no-history Home path with pending rows still visible.
- `test/widget/features/home/pending_section_test.dart` keeps the section's loading, empty, data, tap-noop, and error rendering contracts covered.
- `test/widget/features/home/pending_tile_test.dart` strengthens row metadata coverage.
- `test/integration/pending_approval_flow_test.dart` now exercises the no-history approval path by seeding the first test's pending row inside `tester.runAsync(...)` with no historical transaction seed, while a second test keeps coverage for multi-row approval behavior on a non-empty Home screen.

## Why This Works

- Home now decides between `_EmptyState` and `_PendingOnlyBody` from combined UI truth: transaction history plus visible pending rows.
- `PendingController` owns a timer-backed workflow, so `keepAlive` matches provider lifetime to the workflow rather than to the screen widget lifecycle.
- Clearing `_skipScheduled` before `reject()` gives skip-once optimistic hiding a correct rollback path on failure.
- Drift invalidation only works when custom queries and custom updates declare their table dependencies. `readsFrom` fixes the production query, and `updates: {db.accounts}` fixes the test to exercise the real reactivity contract.

## Prevention

- If a screen can be empty in one data source but still actionable from another, make the empty-state branch watch both sources explicitly.
- Keep providers alive when they own timers or other in-memory workflow state that must survive widget disposal.
- For optimistic hide/remove flows, add a regression test for the failed persistence path, not just the success path.
- For Drift `customSelect` joins, declare every participating table in `readsFrom`.
- In reactivity tests, do not use `customStatement(...)` when the assertion depends on watchers re-emitting; use Drift APIs that report `updates: {...}`.

Verification that passed for this fix:

- `dart format .`
- `flutter analyze`
- `flutter test test/unit/controllers/pending_controller_test.dart`
- `flutter test test/unit/repositories/pending_transaction_repository_test.dart`
- `flutter test test/widget/features/home/pending_section_test.dart`
- `flutter test test/widget/features/home/pending_tile_test.dart`
- `flutter test test/widget/features/home/home_screen_test.dart`
- `flutter test test/integration/pending_approval_flow_test.dart`

## Related Issues

- `docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md` — closest prior Home timer/undo coordination fix.
- `docs/solutions/logic-errors/home-calendar-day-navigation-2026-04-29.md` — another Home reactive-timing issue driven by stale UI assumptions.
- `docs/solutions/logic-errors/recurring-generation-and-reference-guards-2026-05-08.md` — upstream recurring pending-row generation and bootstrap timing context.
- `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md` — broader controller/state ownership guidance behind this fix.
