---
title: PendingSection on Home rendered cross-day, causing approve-date misperception
date: 2026-05-09
category: ui-bugs
module: home
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - User on a past-day Home view saw a today-dated pending recurring tile and assumed it belonged to the selected past day.
  - Approving from a past-day view produced a today-dated transaction (correct given the underlying pending.date) but felt wrong to the user.
  - User reported "all daily pending transactions are gone after approving one" — actually each rule had a single today-dated pending, and approves correctly removed one at a time.
  - Original plan documented PendingSection as global, masking the day-scoping requirement until a user hit the pre-declared reversal trigger.
root_cause: scope_issue
resolution_type: code_fix
severity: high
related_components:
  - features/home/home_controller
  - features/home/home_state
  - data/repositories/pending_transaction_repository
  - data/use_cases/recurring_generation_use_case
tags:
  - flutter
  - riverpod
  - pending-transactions
  - recurring
  - home-screen
  - day-scoping
  - misperception-bug
  - plan-reversal
  - tdd
---

# PendingSection on Home rendered cross-day, causing approve-date misperception

## Problem

`PendingSection` on the Home screen rendered every pending recurring row regardless of which day the user had navigated to with the day-nav arrows. A today-dated pending tile was therefore visible while viewing a past day. Users approved that tile expecting a past-dated transaction and saw the (correct) today-dated transaction land on today's day list, concluding the date was "wrong" — when in fact the data layer had always preserved `pending.date` end-to-end.

## Symptoms

- "When I approve a pending transaction in the past, it should record the transaction in that day, not today."
- "After I create a daily recurring transaction, I will see that pending transaction appear everyday in the past days."
- "Today is 9th, I approved 7th pending transaction, all daily pending transaction are gone, which is wrong."
- "The approved 7th date transaction is not display in 7th, it appear in today."
- After an earlier UX-fix attempt (`pinDay` after approve), the user reported the bug was still present.

## What Didn't Work

1. **Repository-level unit test asserting `tx.date == past pending.date`** in `test/unit/repositories/pending_transaction_repository_test.dart`. **Passed immediately on first run** — the repository already preserved `pending.date`, so there was no failing behavior to drive a fix. Per TDD discipline, the test was deleted because it didn't capture a real defect (a test that passes on first write is not a regression test for the bug under investigation).

2. **Full-stack integration regression test** `'approve on a yesterday-dated pending row records the transaction with yesterday's date, not today's'` in `test/integration/recurring_transaction_test.dart`. Also passed on first run. Reconfirmed the data layer was sound but did not explain the user's reported symptom. (Kept as an invariant lock since it reads the persisted `transactions` row directly to bypass any in-memory transformation.)

3. **UX hypothesis: post-approve `pinDay(item.date)`.** Assumed Home stayed on today after approving a past-dated row, hiding the new tx off-screen. Added `pinDay(item.date)` in `pending_section.dart` plus a RED→GREEN test asserting Home pins to the approved row's day. Shipped. The user responded the bug persisted, proving the hypothesis was wrong — past-dated approves were not actually happening because past-dated *pending rows* were not what the user was tapping.

The breakthrough came only after the user shared their `ledgerly.sqlite` and SQL queries against it (`SELECT id, datetime(date, 'unixepoch', 'localtime'), datetime(created_at, 'unixepoch', 'localtime'), memo FROM transactions ORDER BY id`) showed:

- Rule `每天` (id 13): created `2026-05-09 01:43:53`, `frequency='daily'`, `next_due_date=2026-05-10`.
- Tx 17 `每天`: `date=2026-05-09 00:00:00`, `created_at=2026-05-09 01:44:30`.
- **Every transaction in the DB had `date == created_at`'s day.** No past-dated approve had ever occurred — the user had been tapping today-dated pending tiles that were rendered onto past-day Home views.

## Solution

**Day-scope `PendingSection` to `homeControllerProvider`'s `selectedDay`.** Single-file change in `lib/features/home/widgets/pending_section.dart`.

Imports added:

```dart
import '../../../core/utils/date_helpers.dart';
import '../home_state.dart';
```

Filter inside `_buildData`:

```dart
final selectedDay = _selectedDay(ref);
final skipId = data.skipScheduled?.pendingId;
final visible = data.items
    .where((item) {
      if (item.id == skipId) return false;
      if (selectedDay != null &&
          !DateHelpers.isSameDay(item.date, selectedDay)) {
        return false;
      }
      return true;
    })
    .toList(growable: false);
```

Selector helper added to the same widget state:

```dart
DateTime? _selectedDay(WidgetRef ref) {
  final s = ref.watch(homeControllerProvider);
  if (s is AsyncData<HomeState>) {
    return switch (s.value) {
      HomeData(:final selectedDay) => selectedDay,
      HomeEmpty(:final selectedDay) => selectedDay,
      _ => null,
    };
  }
  return null;
}
```

**Plan-doc decision reversal** at `docs/superpowers/plans/2026-05-08-pending-approval-on-home.md`: the original "PendingSection placement (global section in day-scoped scroll — accepted)" trade-off was flipped to "PendingSection scopes to selectedDay (REVERSED 2026-05-09 — was global)" with rationale linking to the user report. The original plan had pre-declared the exact reversal trigger ("usability testing surfaces 'I thought these were yesterday's transactions.'") which fired here.

**Tests:**

- New RED→GREEN regression: `'PendingSection only shows pending rows whose date matches the selected day on Home'` in `test/integration/pending_approval_flow_test.dart` — guards the day-scope filter.
- New regression: `'catch-up: 3-day-stale daily rule generates 3 dated pending rows; approving the oldest leaves the other two intact and dated correctly'` in `test/integration/recurring_transaction_test.dart` — locks the data-layer invariant the misperception was about.
- Updated `'approving one of N pending rows on the same day leaves the others on screen'` to seed today-dated pending rows (past-dated tiles are now correctly hidden on today's view).
- Updated `WH02b: no-history Home still shows pending section when rows exist` in `test/widget/features/home/home_screen_test.dart` to use today's date for the seeded pending row.
- Removed the now-redundant `pinDay`-after-approve test from the third investigation attempt.

889 tests pass; `flutter analyze` clean.

## Why This Works

The data layer was always correct — `PendingTransactionRepository.approve` (`lib/data/repositories/pending_transaction_repository.dart:125-178`) preserved `pending.date` end-to-end through `Transaction(id: 0, ..., date: pending.date, ...)` and `TransactionRepository.save`'s `_toCompanion` (`lib/data/repositories/transaction_repository.dart:377-393`) wrote `date: Value(tx.date)` verbatim. The defect was an **information-display mismatch**: `PendingSection` was a global sliver inside a day-scoped scroll, so a today-dated pending tile rendered identically on a May-7 Home view and a May-9 Home view. The user, viewing May 7, reasonably interpreted the tile as "May 7's pending row," approved it, and got a May-9-dated transaction (the truthful pending date) which appeared on May 9's view, not May 7's.

Filtering `data.items` by `DateHelpers.isSameDay(item.date, selectedDay)` aligns the visible tiles with the day context the user is reading them in. The date the user sees on the tile and the date that gets written to `transactions` always match the day they're standing on. The previously-shipped `pinDay(item.date)` call after approve becomes a defensive no-op (since `item.date == selectedDay` always holds when approve is reachable through the day-scoped section) and is kept for robustness against future code paths that might surface pending tiles outside the day-scoped view (e.g., a future "All pending" sheet).

## Prevention

1. **Day-scoped sections in day-scoped scrolls.** When Home (or any day-paginated screen) renders a sliver tied to dated rows, filter by `selectedDay` from the controller — never render a global list inside a day-scoped scroll. The new RED test in `test/integration/pending_approval_flow_test.dart` is the regression guard; do not delete it without removing day-scoping from `PendingSection`.

2. **Plan-doc trade-off triggers are contracts.** `docs/superpowers/plans/2026-05-08-pending-approval-on-home.md` had pre-declared the reversal trigger for this exact decision ("usability testing surfaces 'I thought these were yesterday's transactions.'"). When a user report matches a documented reversal trigger, treat that as authoritative and execute the reversal instead of hypothesizing alternative root causes. The reversed-decision note in the plan doc now records this so future readers see the contract was honored.

3. **When tests pass but the user disagrees, read the user's actual data first.** Two test layers (repository unit + full-stack integration) both passed on first run for the assumed bug. That should have been the signal to stop writing more tests against the *assumed* failure mode and instead pull the user's `ledgerly.sqlite` and run SQL queries directly:

   ```sql
   -- Drift stores DateTime as Unix-seconds. Use 'unixepoch' + 'localtime'
   -- to read column values, or you'll see raw integers (e.g. 1778256000)
   -- and misread the data.
   SELECT id, datetime(date, 'unixepoch', 'localtime') AS d,
                 datetime(created_at, 'unixepoch', 'localtime') AS c,
                 memo
   FROM transactions ORDER BY id;
   ```

   The mismatch between "tests green" and "user red" almost always means the bug is one layer up from where you're looking — usually presentation/perception, not data. Bake this into the debugging order: **test → if test passes, inspect user data → if user data matches tests, look at the UI rendering boundary**.

4. **TDD discipline: a test that passes on first write is not a regression test for the bug under investigation.** The first investigation attempt's deleted test is the canonical example. If the test you wrote to drive a fix passes immediately, the bug isn't where you think it is — delete the test (or move it to a separate "invariant lock" suite with clear naming, like the 3-day-stale catch-up test) and re-locate the actual failure.

5. **Riverpod selector pattern for cross-controller widget filters.** The `_selectedDay(WidgetRef ref)` helper in `pending_section.dart` is a reusable shape for "widget owned by controller A needs to filter by state from controller B": narrow the watch to the specific field via a sealed-state `switch`, return `null` for non-`AsyncData` states, and let the filter no-op when null. This avoids both rebuild storms and null-handling churn at the call site.

6. **Drift `DateTime` is stored as Unix-seconds (UTC) by default.** When inspecting the device DB with `sqlite3`, always wrap date columns with `datetime(col, 'unixepoch', 'localtime')` — a raw `SELECT date FROM transactions` shows integers and is easy to misread (especially comparing `created_at` vs `date` integers and concluding "the date is wrong"). Add this to the debugging playbook for any future "the date looks wrong" report.

## Related Issues

- `docs/solutions/logic-errors/home-pending-recurring-approval-visibility-and-undo-coordination-2026-05-09.md` — sibling fix on the same feature/branch, addressing pending visibility on empty-history Home views and skip-undo lifecycle. The empty-state visibility fix from that doc is a prerequisite for day-scoping to be safe — without it, scoping pending tiles to `selectedDay` while only rendering from `HomeData` would re-introduce the unreachable-pending bug on first-run / no-history days.
- `docs/superpowers/plans/2026-05-08-pending-approval-on-home.md` — feature plan, which now records the reversed "PendingSection placement" decision.
- `docs/solutions/logic-errors/home-calendar-day-navigation-2026-04-29.md` — earlier doc on Home `selectedDay` semantics; same controller-state truth source used by this fix.
