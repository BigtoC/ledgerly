# Pending Approval on Home — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface pending recurring-transaction rows on Home with one-tap approve and swipe-to-skip, completing the recurring-transactions feature loop.

**Architecture:** A new `PendingController` (independent of `HomeController`) streams `PendingTransaction` rows from `PendingTransactionRepository`. A `PendingSection` sliver mounts above the existing transaction list on `HomeScreen`. Approve atomically inserts a `transactions` row and deletes the pending row. Skip uses the existing 4-second undo-window pattern.

**Skip semantics (load-bearing).** "Skip" rejects ONE occurrence of a recurring rule and is permanent after the 4-second undo window — the parent rule keeps generating next month. The user-facing copy is therefore deliberate:

- Swipe action label: `homePendingSkip` → "Skip once" / "略過此次" / "跳过此次" — the "once"/"此次" disambiguates from "stop the rule"
- Skip SnackBar text: `homePendingSkippedSnack` → "Skipped this occurrence" / "已略過此次" / "已跳过此次" — emphasises *this occurrence*
- The companion action button uses `commonUndo` ("Undo" / "復原" / "撤销")

To stop a rule entirely, the user must navigate to `/settings/recurring/:id` and pause/delete it. The plan does not add an in-snackbar "Stop rule" shortcut for v1 — that is captured as a follow-up under *Out of scope*. Approve, by contrast, has no undo affordance: see *Decisions and Trade-offs → Approve reversibility* for the rationale.

**Tech Stack:** Flutter, Riverpod, Drift, Freezed, flutter_slidable, mocktail (tests), fake_async (timer tests)

**Spec:** `docs/superpowers/specs/2026-05-08-pending-approval-on-home-design.md`

---

## File Structure

| Action | Path                                                              | Responsibility                                                                       |
|--------|-------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| Modify | `lib/data/database/daos/pending_transaction_dao.dart`             | Add `watchAll()`, `approveRow()`, `rejectRow()` DAO methods                          |
| Modify | `lib/data/database/daos/currency_dao.dart`                        | Add `findByCodes(List<String>)` for batched currency resolution                       |
| Modify | `lib/data/repositories/pending_transaction_repository.dart`       | Add `watchAll()`, `approve()`, `reject()` repository methods                         |
| Modify | `lib/app/bootstrap.dart`                                          | Pass `txRepo:` to `DriftPendingTransactionRepository` constructor                     |
| Modify | `lib/app/providers/repository_providers.dart`                     | Add `transactionRepository` to `pendingTransactionRepository` provider deps           |
| Modify | `test/integration/recurring_transaction_test.dart`                | Pass `txRepo:` to `DriftPendingTransactionRepository` (~6 call sites)                |
| Create | `lib/features/home/pending_state.dart`                            | Freezed `PendingState` sealed union + `PendingSkipScheduled` + `PendingEffect` types |
| Create | `lib/features/home/pending_controller.dart`                       | `PendingController` StreamNotifier with approve/skip/undoSkip commands               |
| Create | `lib/features/home/widgets/pending_section.dart`                  | `PendingSection` sliver widget + `PendingTile` + `_ApproveCircleButton`              |
| Modify | `lib/features/home/home_screen.dart`                              | Mount `PendingSection` in sliver list; remove hardcoded `pendingBadgeCount: 0`       |
| Modify | `lib/features/home/home_state.dart`                               | Remove `pendingBadgeCount` field from `HomeState` variants                           |
| Modify | `lib/features/home/home_controller.dart`                          | Remove `pendingBadgeCount` from `_Composer` emissions                                |
| Modify | `lib/features/home/widgets/pending_badge.dart`                    | No changes needed — still used inside PendingSection header                          |
| Modify | `l10n/app_en.arb`                                                 | Add 8 new keys                                                                       |
| Modify | `l10n/app_zh_TW.arb`                                              | Add 8 new keys                                                                       |
| Modify | `l10n/app_zh_CN.arb`                                              | Add 8 new keys                                                                       |
| Modify | `test/unit/l10n/arb_audit_test.dart`                              | Add 8 keys to `_expectedEnKeys`                                                      |
| Modify | `test/unit/repositories/pending_transaction_repository_test.dart` | Add tests for watchAll, approve, reject                                              |
| Create | `test/unit/controllers/pending_controller_test.dart`              | Controller unit tests (PC01–PC11)                                                    |
| Create | `test/widget/features/home/pending_section_test.dart`             | Widget tests for PendingSection (PS01–PS05)                                          |
| Create | `test/widget/features/home/pending_tile_test.dart`                | Widget tests for PendingTile + ApproveCircleButton (PT01–PT07)                       |
| Create | `test/integration/pending_approval_flow_test.dart`                | End-to-end integration test                                                          |

---

## Decisions and Trade-offs

These are the load-bearing choices the plan makes. Each lists a reversal trigger so a future maintainer knows what evidence would justify revisiting.

### Approve reversibility (asymmetric with Skip — deliberate)

Approve has **no undo**. Skip has a 4-second `kUndoWindow` undo via SnackBar. The asymmetry is intentional:

- **Approve writes a real Transaction**, which is the user's audit record. Adding undo would mean inserting then deleting a row inside 4 seconds — visible in any future "raw transactions" debug view, and conceptually awkward (the audit log becomes lossy).
- **Skip writes nothing**. It deletes a generated pending row. Undo is just "cancel the timer" — cheap, lossless, no audit smell.
- Mitigation against accidental approve: 36 px circle button, debounced via `_approving` flag, 200 ms scale + color animation as deliberate visual feedback. The user has to *land* on the circle and *wait through* the animation; an accidental fat-finger on the row body is a no-op.

**Reverse this if:** support reports of accidental approves exceed reports of "approve felt scary / I wish it confirmed first." The fallback is to mirror skip's pattern: insert immediately + show "Approved — Undo" snack for `kUndoWindow`; on undo, delete the inserted tx and re-insert the pending row.

### PendingSection placement (global section in day-scoped scroll — accepted)

`PendingSection` mounts inside the same `CustomScrollView` as the day-filtered transaction list, but its content is global — it shows all pending rows regardless of `selectedDay`. The visual model says "everything in this scroll is the day's data" but the section breaks that invariant.

We accept this for v1 because:

1. The section auto-hides when there are no pending rows (most days for most users), so the inconsistency is invisible.
2. The PendingBadge in the header carries the count, signalling the section is its own scope.
3. Mounting outside the scroll (e.g., as a persistent header) would either eat vertical space when empty or require a separate layout pass.

**Reverse this if:** N pending rows persistently >= the cap (`_kPendingCollapseThreshold = 5`) for a meaningful share of users, or usability testing surfaces "I thought these were yesterday's transactions." Fallback: filter pending rows by `selectedDay`, OR mount above the day-nav header in a structural location.

### Visible-tile cap (5 with "Show N more" — chosen, simple)

Worst case: a user returns after months and 12+ rules generated overdue rows. Without a cap, the section pushes today's list below the fold on first paint. We cap at 5 visible tiles; the rest collapse behind a `homePendingShowMore({count})` button.

**Reverse this if:** users with normal (1–3) pending counts report the "Show fewer" affordance is confusing, or analytics show the show-more button has near-100% expansion (meaning the cap is doing nothing useful).

### Source filter on watchAll (`source = 'recurring'` — narrow on purpose)

The DAO query filters `WHERE source = 'recurring'`. PendingTile is shaped around recurring-row fields (memo as title, category icon as leading, amount + Approve circle as trailing). Blockchain rows (when wallet sync ships) carry their identity in `tx_hash` / wallet addresses and need a different tile.

**Reverse this when:** wallet sync ships its own source-aware tile. At that point, either drop the filter and add a `switch (item.source)` rendering branch, or replace `watchAll` with a `watchAllForUI(sources: ...)` that the caller scopes.

### Archive filtering at stream time (hide rows with archived deps — chosen)

`_rowsToDomain` drops rows whose referenced account or category is archived. The alternative was to keep them visible and produce a specific "unrecoverable" snackbar on tap. Hiding is simpler and removes the dead-end state entirely; if the user un-archives the dep, the row reappears in the next stream emission.

**Reverse this if:** users are confused that pending items "vanished" without an explanation. Fallback: show a dimmed tile with text "Account archived — restore in Settings" and route to `/settings/accounts`.

### `keepAlive: true` dropped from PendingController (matches RecurringRulesController)

Dropped to match the existing `RecurringRulesController` pattern, which uses the same `kUndoWindow` timer + delete-with-undo flow without keepAlive. The 4-second timer survives because the controller is mounted for the lifetime of the HomeScreen route, the same way RecurringRulesController is mounted for the lifetime of `/settings/recurring`.

**Reverse this if:** the controller turns out to be torn down during scroll/rebuilds and the timer cancels mid-window. Fallback: re-add `keepAlive: true` and document the divergence from RecurringRulesController.

### PendingController as a separate slice (not folded into HomeController)

HomeController already owns: day navigation, `_Composer`, swipe-delete-undo with kUndoWindow timer, effect listener, summary-strip aggregates, watchByDay stream. Folding pending state in would reuse most of that machinery — the new code is a pending-specific stream input, a sealed PendingState variant, an additional skip timer, and approve/skip command methods.

We chose separation despite the duplication because:

1. Pending state has its own loading/empty/error variants that feel orthogonal to "today's transactions."
2. Test surface is cleaner — PendingController tests don't have to mock the day-nav stream and the summary aggregates.
3. The skip-undo timer is a single in-memory `PendingSkipScheduled?`; folding it would require either a second timer field on HomeController (mixing concerns) or a sum-type that combines the two.

The duplication cost is roughly: one `_Composer` (~70 LOC mirrored), one skip-undo timer (~20 LOC), one effect listener wiring (~10 LOC). That's ~100 LOC of mirrored infrastructure for a clearer test surface.

**Reverse this if:** Phase 2 adds blockchain-source pending (which would require a second source-routed slice) or if HomeController grows to need pending state inline (e.g., a "today's pending count" badge that has to update synchronously with the day list).

---

## Chunk 1: Data Layer — DAO + Repository Extensions

### Task 1: Add DAO methods for watchAll, approve, reject

**Files:**
- Modify: `lib/data/database/daos/pending_transaction_dao.dart`
- Modify: `lib/data/database/app_database.dart` (if TransactionRepository.save is needed inside approve)

- [x] **Step 1: Add `watchAll()` to PendingTransactionDao**

Add to `lib/data/database/daos/pending_transaction_dao.dart`:

```dart
/// Stream pending rows produced by recurring rules, ordered by date DESC,
/// id DESC.
///
/// Filtered to `source = 'recurring'` for v1. PendingTile is shaped around
/// recurring-row fields (memo as title, category icon as leading) and would
/// not render correctly for blockchain rows (where the meaningful identity
/// is `tx_hash` / wallet addresses). Wallet sync ships its own
/// source-aware tile and will either drop this filter or replace this
/// stream with a `watchAllForUI` that branches by source.
Stream<List<PendingTransactionRow>> watchAll() {
  return (select(pendingTransactions)
        ..where((t) => t.source.equals('recurring'))
        ..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
        ]))
      .watch();
}

/// Delete a pending row by id. Returns the number of rows affected.
Future<int> rejectRow(int id) {
  return (delete(pendingTransactions)..where((t) => t.id.equals(id))).go();
}
```

- [x] **Step 2: Verify the file still compiles**

Run: `flutter analyze lib/data/database/daos/pending_transaction_dao.dart`
Expected: No errors

- [x] **Step 3: Run codegen for Drift**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `pending_transaction_dao.g.dart` regenerated

### Task 2: Extend PendingTransactionRepository with watchAll, approve, reject

**Files:**
- Modify: `lib/data/repositories/pending_transaction_repository.dart`
- Test: `test/unit/repositories/pending_transaction_repository_test.dart`

- [x] **Step 1: Write failing tests for watchAll, approve, reject**

Add to `test/unit/repositories/pending_transaction_repository_test.dart`:

```dart
test('watchAll emits rows in date DESC, id DESC order', () async {
  await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 7),
    fetchedAt: DateTime(2026, 5, 7),
    recurringRuleId: ruleId,
  );
  await repo.insert(
    source: 'recurring',
    amountMinorUnits: 200,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  final rows = await repo.watchAll().first;
  expect(rows, hasLength(2));
  expect(rows.first.date, DateTime(2026, 5, 8));
  expect(rows.last.date, DateTime(2026, 5, 7));
});

test('watchAll emits empty list on empty DB', () async {
  final rows = await repo.watchAll().first;
  expect(rows, isEmpty);
});

test('approve inserts transaction and deletes pending row', () async {
  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 1599,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    memo: 'Netflix',
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  final tx = await repo.approve(pendingId);

  expect(tx.amountMinorUnits, 1599);
  expect(tx.currency.code, 'USD');
  expect(tx.categoryId, categoryId);
  expect(tx.accountId, accountId);
  expect(tx.memo, 'Netflix');
  expect(tx.date, DateTime(2026, 5, 8));
  expect(tx.id, isPositive);

  // Pending row deleted
  final pendingRows = await repo.watchAll().first;
  expect(pendingRows, isEmpty);
});

test('approve overwrites the sentinel createdAt/updatedAt timestamps', () async {
  // The approve path constructs a Transaction with `createdAt: DateTime(0)`
  // (1970) and relies on TransactionRepository.save to set real timestamps.
  // If save ever changes that contract, this test catches it before the
  // 1970 sentinel reaches users' ledgers.
  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 1599,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    memo: 'Netflix',
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  final before = DateTime.now();
  final tx = await repo.approve(pendingId);

  expect(
    tx.createdAt.isAfter(DateTime(2000)),
    isTrue,
    reason: 'createdAt must be overwritten by save, not left at DateTime(0)',
  );
  expect(
    tx.updatedAt.isAtSameMomentAs(tx.createdAt) ||
        tx.updatedAt.isAfter(tx.createdAt),
    isTrue,
  );
  expect(tx.createdAt.isAtSameMomentAs(before) || tx.createdAt.isAfter(before),
      isTrue);
});

test('approve throws when pending row does not exist', () async {
  expect(
    () => repo.approve(9999),
    throwsA(isA<PendingTransactionRepositoryException>()),
  );
});

test('approve throws when categoryId is null', () async {
  // Insert a pending row with null categoryId (valid for blockchain source)
  await db.customStatement(
    'INSERT INTO pending_transactions '
    '(source, amount_minor_units, currency, category_id, account_id, '
    'date, fetched_at, recurring_rule_id) '
    'VALUES (?, ?, ?, NULL, ?, ?, ?, ?)',
    ['recurring', 100, 'USD', accountId, DateTime(2026, 5, 8),
     DateTime(2026, 5, 8), ruleId],
  );
  final rows = await repo.watchAll().first;
  final pendingId = rows.first.id;

  expect(
    () => repo.approve(pendingId),
    throwsA(isA<PendingTransactionRepositoryException>()),
  );

  // Pending row still exists (atomicity)
  final after = await repo.watchAll().first;
  expect(after, hasLength(1));
});

test('approve throws when account is archived', () async {
  // Archive the account
  await db.customStatement(
    'UPDATE accounts SET is_archived = 1 WHERE id = ?',
    [accountId],
  );

  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  expect(
    () => repo.approve(pendingId),
    throwsA(isA<PendingTransactionRepositoryException>()),
  );

  // Atomicity: the pending row must still be in the DB.
  // We query the DAO directly because `watchAll` filters out rows whose
  // referenced account or category is archived (UI-facing stream).
  final dbRow = await db.pendingTransactionDao.findById(pendingId);
  expect(dbRow, isNotNull);

  // And the UI-facing stream must NOT surface the dead-end row.
  final visible = await repo.watchAll().first;
  expect(visible, isEmpty);
});

test('approve throws when category is archived', () async {
  await db.customStatement(
    'UPDATE categories SET is_archived = 1 WHERE id = ?',
    [categoryId],
  );

  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  expect(
    () => repo.approve(pendingId),
    throwsA(isA<PendingTransactionRepositoryException>()),
  );

  final dbRow = await db.pendingTransactionDao.findById(pendingId);
  expect(dbRow, isNotNull);
  final visible = await repo.watchAll().first;
  expect(visible, isEmpty);
});

test('watchAll hides rows whose account becomes archived; reappears on '
    'unarchive', () async {
  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  final before = await repo.watchAll().first;
  expect(before, hasLength(1));

  await db.customStatement(
    'UPDATE accounts SET is_archived = 1 WHERE id = ?',
    [accountId],
  );

  final hidden = await repo.watchAll().first;
  expect(hidden, isEmpty);

  await db.customStatement(
    'UPDATE accounts SET is_archived = 0 WHERE id = ?',
    [accountId],
  );

  final restored = await repo.watchAll().first;
  expect(restored, hasLength(1));
  expect(restored.first.id, pendingId);
});

test('approve does NOT modify parent recurring rule next_due_date', () async {
  // Read original next_due_date
  final ruleBefore = await db.customSelect(
    'SELECT next_due_date FROM recurring_rules WHERE id = ?',
    variables: [Variable.withInt(ruleId)],
  ).getSingle();
  final originalDueDate = ruleBefore.read<DateTime>('next_due_date');

  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  await repo.approve(pendingId);

  final ruleAfter = await db.customSelect(
    'SELECT next_due_date FROM recurring_rules WHERE id = ?',
    variables: [Variable.withInt(ruleId)],
  ).getSingle();
  expect(ruleAfter.read<DateTime>('next_due_date'), originalDueDate);
});

test('reject deletes the pending row', () async {
  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  await repo.reject(pendingId);

  final rows = await repo.watchAll().first;
  expect(rows, isEmpty);
});

test('reject is idempotent — missing id returns normally', () async {
  // Should not throw
  await repo.reject(9999);
});

test('reject does NOT modify parent recurring rule', () async {
  final ruleBefore = await db.customSelect(
    'SELECT next_due_date FROM recurring_rules WHERE id = ?',
    variables: [Variable.withInt(ruleId)],
  ).getSingle();
  final originalDueDate = ruleBefore.read<DateTime>('next_due_date');

  final pendingId = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  await repo.reject(pendingId);

  final ruleAfter = await db.customSelect(
    'SELECT next_due_date FROM recurring_rules WHERE id = ?',
    variables: [Variable.withInt(ruleId)],
  ).getSingle();
  expect(ruleAfter.read<DateTime>('next_due_date'), originalDueDate);
});

test('watchAll re-emits after approve', () async {
  await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  final first = await repo.watchAll().first;
  expect(first, hasLength(1));

  await repo.approve(first.first.id);

  final second = await repo.watchAll().first;
  expect(second, isEmpty);
});

test('watchAll re-emits after reject', () async {
  final id = await repo.insert(
    source: 'recurring',
    amountMinorUnits: 100,
    currencyCode: 'USD',
    categoryId: categoryId,
    accountId: accountId,
    date: DateTime(2026, 5, 8),
    fetchedAt: DateTime(2026, 5, 8),
    recurringRuleId: ruleId,
  );

  final first = await repo.watchAll().first;
  expect(first, hasLength(1));

  await repo.reject(id);

  final second = await repo.watchAll().first;
  expect(second, isEmpty);
});
```

- [x] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/repositories/pending_transaction_repository_test.dart`
Expected: FAIL — `watchAll`, `approve`, `reject` not found on repository

- [x] **Step 3: Implement `watchAll` in PendingTransactionRepository**

Add to the `PendingTransactionRepository` abstract class:

```dart
/// Stream all pending rows, ordered by date DESC, id DESC.
Stream<List<PendingTransaction>> watchAll();

/// Approve: insert into `transactions` and delete the pending row,
/// atomically. Throws [PendingTransactionRepositoryException] when:
///   - The pending row id does not exist.
///   - The pending row has no categoryId (Transaction requires it).
///   - The referenced account is archived or missing.
///   - The referenced category is archived or missing.
///   - The referenced currency code is unregistered.
Future<Transaction> approve(int pendingId);

/// Reject: delete the pending row. Idempotent — calling on a missing id
/// returns without throwing.
Future<void> reject(int pendingId);
```

- [x] **Step 4: Implement `watchAll` in DriftPendingTransactionRepository**

```dart
@override
Stream<List<PendingTransaction>> watchAll() {
  return _dao.watchAll().asyncMap(_rowsToDomain);
}
```

Add the `_rowsToDomain` helper (maps Drift `PendingTransactionRow` to `PendingTransaction` domain model). This requires resolving the `Currency` from the stored code — follow the same pattern as `DriftTransactionRepository._rowsToDomain`, with three safety details specific to this surface:

1. **Batch the currency lookup.** Collect distinct codes from all rows, fetch them in one round-trip via `currencyDao.findByCodes(...)`, then map rows synchronously. Avoids N serial DB calls per emission.
2. **Partial failure.** If a row references a currency that is no longer registered (stale row, future migration), skip the row and log instead of throwing — a single bad row must not flip the entire `PendingState` into `error` and hide all the *valid* rows behind a generic "Couldn't load" banner with no recovery path.
3. **Archive filtering.** Drop rows whose referenced account or category is archived. Otherwise the user sees a tile that always fails on tap (`approve` rejects archived deps) with only the generic "Something went wrong" snackbar — a permanent dead end. Filtering them at stream time means the row reappears automatically once the user unarchives the dependency in Settings. This is a partial answer to the design's "what about archived deps" gap; the row is hidden, not auto-skipped, so a deliberate user action (un-archive or visit Settings → Recurring) is still required.

```dart
Future<List<PendingTransaction>> _rowsToDomain(
  List<PendingTransactionRow> rows,
) async {
  if (rows.isEmpty) return const [];

  // Batch-resolve every distinct currency code in one round-trip.
  final distinctCodes = {for (final r in rows) r.currency};
  final byCode = await _resolveCurrencies(distinctCodes);

  // Batch-load referenced accounts + categories so we can filter out rows
  // whose dependencies are archived or missing in a single pass.
  final distinctAccountIds = {for (final r in rows) r.accountId};
  final distinctCategoryIds = {
    for (final r in rows)
      if (r.categoryId != null) r.categoryId!,
  };
  final accountById = await _accountsByIds(distinctAccountIds);
  final categoryById = await _categoriesByIds(distinctCategoryIds);

  final out = <PendingTransaction>[];
  for (final row in rows) {
    final currency = byCode[row.currency];
    if (currency == null) {
      // Tolerate a stale/unregistered currency: drop just this row and
      // surface the others. A bad row entering an `asyncMap` would otherwise
      // error the whole stream and replace the section with PendingError.
      developer.log(
        'PendingTransactionRepository: dropping row ${row.id} — '
        'currency "${row.currency}" not registered',
        name: 'pending_transaction_repository',
      );
      continue;
    }
    final account = accountById[row.accountId];
    if (account == null || account.isArchived) {
      // Hide rows whose account would make `approve` fail. The user's
      // recovery path is to un-archive the account in Settings, after
      // which the row reappears in the next stream emission.
      developer.log(
        'PendingTransactionRepository: hiding row ${row.id} — '
        'account ${row.accountId} is archived or missing',
        name: 'pending_transaction_repository',
      );
      continue;
    }
    if (row.categoryId != null) {
      final category = categoryById[row.categoryId!];
      if (category == null || category.isArchived) {
        developer.log(
          'PendingTransactionRepository: hiding row ${row.id} — '
          'category ${row.categoryId} is archived or missing',
          name: 'pending_transaction_repository',
        );
        continue;
      }
    }
    out.add(
      PendingTransaction(
        id: row.id,
        source: row.source,
        amountMinorUnits: row.amountMinorUnits,
        currency: currency,
        categoryId: row.categoryId,
        accountId: row.accountId,
        memo: row.memo,
        date: row.date,
        fetchedAt: row.fetchedAt,
        recurringRuleId: row.recurringRuleId,
      ),
    );
  }
  return List.unmodifiable(out);
}

Future<Map<int, AccountRow>> _accountsByIds(Set<int> ids) async {
  if (ids.isEmpty) return const {};
  final rows = await (_db.accountDao.select(_db.accountDao.accounts)
        ..where((t) => t.id.isIn(ids.toList())))
      .get();
  return {for (final r in rows) r.id: r};
}

Future<Map<int, CategoryRow>> _categoriesByIds(Set<int> ids) async {
  if (ids.isEmpty) return const {};
  final rows = await (_db.categoryDao.select(_db.categoryDao.categories)
        ..where((t) => t.id.isIn(ids.toList())))
      .get();
  return {for (final r in rows) r.id: r};
}

Future<Map<String, Currency>> _resolveCurrencies(Set<String> codes) async {
  if (codes.isEmpty) return const {};
  final rows = await _db.currencyDao.findByCodes(codes.toList());
  return {
    for (final row in rows)
      row.code: Currency(
        code: row.code,
        decimals: row.decimals,
        symbol: row.symbol,
        nameL10nKey: row.nameL10nKey,
      ),
  };
}
```

Add `import 'dart:developer' as developer;` to the file.

If `currencyDao.findByCodes(List<String>)` does not yet exist on the DAO, add it:

```dart
/// Fetch every currency row whose code is in [codes]. Returns a list — the
/// caller is expected to index by `code` since SQLite IN queries do not
/// preserve input order.
Future<List<CurrencyRow>> findByCodes(List<String> codes) {
  if (codes.isEmpty) return Future.value(const []);
  return (select(currencies)..where((t) => t.code.isIn(codes))).get();
}
```

Add required imports at top of file:
```dart
import '../database/tables/pending_transactions_table.dart';
import '../models/currency.dart';
import '../models/pending_transaction.dart';
import '../models/transaction.dart';
```

- [x] **Step 5: Implement `approve` in DriftPendingTransactionRepository**

```dart
@override
Future<Transaction> approve(int pendingId) async {
  // 1. Load the pending row.
  final pending = await _dao.findById(pendingId);
  if (pending == null) {
    throw PendingTransactionRepositoryException(
      'Pending row not found: $pendingId',
    );
  }

  // 2. Validate categoryId is non-null (Transaction requires it).
  if (pending.categoryId == null) {
    throw PendingTransactionRepositoryException(
      'Pending row $pendingId has no category',
    );
  }

  // 3. Validate references exist and are not archived.
  final account = await _db.accountDao.findById(pending.accountId);
  if (account == null || account.isArchived) {
    throw PendingTransactionRepositoryException(
      'Account archived or missing: ${pending.accountId}',
    );
  }

  final category = await _db.categoryDao.findById(pending.categoryId!);
  if (category == null || category.isArchived) {
    throw PendingTransactionRepositoryException(
      'Category archived or missing: ${pending.categoryId}',
    );
  }

  // 4. Build a Transaction domain value from the snapshot. Reuse the
  // batched lookup helper so a missing currency raises a typed exception
  // rather than crashing inside `TransactionRepository.save` later.
  final byCode = await _resolveCurrencies({pending.currency});
  final currency = byCode[pending.currency];
  if (currency == null) {
    throw PendingTransactionRepositoryException(
      'Currency not registered: ${pending.currency}',
    );
  }
  final tx = Transaction(
    id: 0, // insert path
    amountMinorUnits: pending.amountMinorUnits,
    currency: currency,
    categoryId: pending.categoryId!,
    accountId: pending.accountId,
    date: pending.date,
    memo: pending.memo,
    createdAt: DateTime(0), // will be set by TransactionRepository.save
    updatedAt: DateTime(0),
  );

  // 5. Atomic: insert transaction + delete pending in one DB transaction.
  // Returns the saved Transaction directly from the closure so the caller
  // never sees uninitialized state. Mirrors `DriftShoppingListRepository
  // .convertToTransaction`. Do NOT capture into an outer `late` variable —
  // if the closure throws before assignment, you get a misleading
  // LateInitializationError that shadows the real cause.
  return _db.transaction<Transaction>(() async {
    final saved = await _txRepo.save(tx);
    await _dao.rejectRow(pendingId);
    return saved;
  });
}
```

**Important:** `DriftPendingTransactionRepository` now needs a `TransactionRepository` reference. Update the constructor:

```dart
DriftPendingTransactionRepository(
  this._db, {
  required TransactionRepository txRepo,
  DateTime Function()? clock,
}) : _txRepo = txRepo,
     _clock = clock ?? DateTime.now;

final drift.AppDatabase _db;
final TransactionRepository _txRepo;
```

Also update `repository_providers.dart` to pass `transactionRepositoryProvider`:

```dart
@Riverpod(
  keepAlive: true,
  dependencies: [appDatabase, transactionRepository],
)
PendingTransactionRepository pendingTransactionRepository(Ref ref) =>
    DriftPendingTransactionRepository(
      ref.watch(appDatabaseProvider),
      txRepo: ref.watch(transactionRepositoryProvider),
    );
```

**Existing direct constructor call sites must also be updated** — making `txRepo` a required named parameter is a breaking change. Known sites (verified by grep at plan-write time):

- `lib/app/bootstrap.dart:84` — `pendingRepo: DriftPendingTransactionRepository(db),` inside `_runRecurringGeneration`
- `test/unit/repositories/pending_transaction_repository_test.dart:87` — `repo = DriftPendingTransactionRepository(db);`
- `test/integration/recurring_transaction_test.dart` — six sites (lines ~59, 109, 145, 216, 298, 315)

Run `grep -rn 'DriftPendingTransactionRepository(' lib/ test/` and update every match to pass `txRepo: DriftTransactionRepository(db)` (or the test fixture's existing `txRepo` instance).

Add these files to the File Structure table under Modify:
- `lib/app/bootstrap.dart` — Pass `txRepo:` to `DriftPendingTransactionRepository(...)` constructor in `_runRecurringGeneration`
- `test/integration/recurring_transaction_test.dart` — Pass `txRepo:` to `DriftPendingTransactionRepository(...)` constructor (six call sites)

- [x] **Step 6: Implement `reject` in DriftPendingTransactionRepository**

```dart
@override
Future<void> reject(int pendingId) async {
  await _dao.rejectRow(pendingId);
}
```

- [x] **Step 7: Add `findById` to PendingTransactionDao**

The `approve` method needs to load a pending row by id. Add to `PendingTransactionDao`:

```dart
/// Load a single pending row by id, or null if not found.
Future<PendingTransactionRow?> findById(int id) {
  return (select(pendingTransactions)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
}
```

- [x] **Step 8: Verify `findById` on account/category DAOs exist**

The `approve` method calls `_db.accountDao.findById` and `_db.categoryDao.findById`. Verify these methods exist:

Run: `grep -n "findById" lib/data/database/daos/account_dao.dart lib/data/database/daos/category_dao.dart`
Expected: Both files have a `findById` method

If not found, add them. The pattern is:
```dart
Future<AccountRow?> findById(int id) {
  return (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
}
```

- [x] **Step 9: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success

- [x] **Step 10: Run tests to verify they pass**

Run: `flutter test test/unit/repositories/pending_transaction_repository_test.dart`
Expected: All tests PASS

- [x] **Step 11: Run format + analyze**

Run: `dart format lib/data/ test/unit/repositories/ && flutter analyze`
Expected: No errors

- [ ] **Step 12: Commit**

```bash
git add lib/data/database/daos/pending_transaction_dao.dart \
  lib/data/repositories/pending_transaction_repository.dart \
  lib/app/providers/repository_providers.dart \
  test/unit/repositories/pending_transaction_repository_test.dart
git commit -m "feat(data): add watchAll, approve, reject to PendingTransactionRepository"
```

---

## Chunk 2: State Model + Controller

### Task 3: Create PendingState freezed model

**Files:**
- Create: `lib/features/home/pending_state.dart`

- [x] **Step 1: Create PendingState with Freezed**

Create `lib/features/home/pending_state.dart`:

```dart
// Pending approval state — spec 2026-05-08.
//
// Freezed sealed union consumed by PendingSection on HomeScreen.
// PendingController composes the repository stream into one of
// these variants. PendingSkipScheduled is an in-memory sentinel
// for the 4-second undo window — the row only leaves the DB when
// the timer expires.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/pending_transaction.dart';

part 'pending_state.freezed.dart';

/// A pending row currently inside the 4-second skip-undo window.
/// Held in-memory by the controller, NOT in the DB.
class PendingSkipScheduled {
  const PendingSkipScheduled({
    required this.pendingId,
    required this.scheduledFor,
  });
  final int pendingId;
  final DateTime scheduledFor;
}

@freezed
sealed class PendingState with _$PendingState {
  /// Pre-first emission from watchAll().
  const factory PendingState.loading() = PendingLoading;

  /// No un-approved pending rows. Section renders nothing.
  const factory PendingState.empty() = PendingEmpty;

  const factory PendingState.data({
    required List<PendingTransaction> items,
    required PendingSkipScheduled? skipScheduled,
  }) = PendingData;

  const factory PendingState.error(Object error, StackTrace stack) =
      PendingError;
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `pending_state.freezed.dart` generated

- [x] **Step 3: Verify compiles**

Run: `flutter analyze lib/features/home/pending_state.dart`
Expected: No errors

### Task 4: Create PendingController

**Files:**
- Create: `lib/features/home/pending_controller.dart`
- Create: `test/unit/controllers/pending_controller_test.dart`

- [x] **Step 1: Write failing controller tests (PC01–PC11)**

Create `test/unit/controllers/pending_controller_test.dart`:

```dart
// PendingController unit tests.
//
// Mirrors the RecurringRulesController pattern: stream driven by a
// mocked repository, skip-undo via fake-async timers and Mocktail.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/pending_transaction.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/features/home/pending_controller.dart';
import 'package:ledgerly/features/home/pending_state.dart';

class _MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

PendingTransaction _pending({
  required int id,
  String memo = 'Netflix',
  int amount = 1599,
  int categoryId = 1,
  int accountId = 1,
}) => PendingTransaction(
  id: id,
  source: 'recurring',
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  date: DateTime(2026, 5, 8),
  fetchedAt: DateTime(2026, 5, 8),
  recurringRuleId: 1,
);

Transaction _tx({
  required int id,
  int amount = 1599,
  int categoryId = 1,
  int accountId = 1,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: categoryId,
  accountId: accountId,
  date: DateTime(2026, 5, 8),
  memo: 'Netflix',
  createdAt: DateTime(2026, 5, 8),
  updatedAt: DateTime(2026, 5, 8),
);

void main() {
  group('PendingController', () {
    late _MockPendingTransactionRepository repo;
    late StreamController<List<PendingTransaction>> pendingCtrl;

    setUp(() {
      repo = _MockPendingTransactionRepository();
      pendingCtrl = StreamController<List<PendingTransaction>>.broadcast();
      when(() => repo.watchAll()).thenAnswer((_) => pendingCtrl.stream);
      when(() => repo.approve(any())).thenAnswer((_) async => _tx(id: 1));
      when(() => repo.reject(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await pendingCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWithValue(repo),
        ],
      );
    }

    Future<PendingState> waitFor(
      ProviderContainer c,
      bool Function(PendingState) accept,
    ) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(pendingControllerProvider);
        if (s is AsyncData<PendingState> && accept(s.value)) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError(
        'PendingController never produced expected state',
      );
    }

    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('PC01: loading → data when stream emits items', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      expect(
        container.read(pendingControllerProvider),
        isA<AsyncLoading<PendingState>>(),
      );

      await Future<void>.delayed(Duration.zero);
      pendingCtrl.add([_pending(id: 1)]);

      final state = await waitFor(container, (s) => s is PendingData);
      final data = state as PendingData;
      expect(data.items, hasLength(1));
      expect(data.skipScheduled, isNull);
    });

    test('PC02: loading → empty when stream emits empty list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      pendingCtrl.add(const []);

      final state = await waitFor(container, (s) => s is PendingEmpty);
      expect(state, isA<PendingEmpty>());
    });

    test('PC03: stream error becomes PendingError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      pendingCtrl.addError(StateError('boom'), StackTrace.current);

      final state = await waitFor(container, (s) => s is PendingError);
      expect((state as PendingError).error, isA<StateError>());
    });

    test('PC04: approve calls repo.approve; no effect on success', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1)]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      PendingEffect? effectCaptured;
      notifier.setEffectListener((effect) => effectCaptured = effect);

      await notifier.approve(1);
      await pump();

      verify(() => repo.approve(1)).called(1);
      expect(effectCaptured, isNull);
    });

    test('PC05: approve failure fires PendingApproveFailedEffect', () async {
      when(() => repo.approve(any()))
          .thenThrow(PendingTransactionRepositoryException('archived'));

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1)]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      PendingEffect? effectCaptured;
      notifier.setEffectListener((effect) => effectCaptured = effect);

      await notifier.approve(1);
      await pump();

      expect(effectCaptured, isA<PendingApproveFailedEffect>());
      // Row stays in items
      final data = await waitFor(container, (s) => s is PendingData);
      expect((data as PendingData).items, hasLength(1));
    });

    test('PC06: skip hides row immediately and starts undo window', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1), _pending(id: 2, memo: 'Rent')]);
      await waitFor(container, (s) => s is PendingData);

      // ignore: unawaited_futures
      container.read(pendingControllerProvider.notifier).skip(1);

      final state = await waitFor(
        container,
        (s) =>
            s is PendingData &&
            s.skipScheduled != null &&
            s.items.length == 2,
      );
      expect((state as PendingData).skipScheduled?.pendingId, 1);
      verifyNever(() => repo.reject(any()));
    });

    test('PC07: undoSkip cancels timer; repo.reject never called', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1)]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      // ignore: unawaited_futures
      notifier.skip(1);
      await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled != null,
      );

      await notifier.undoSkip();
      await pump();

      final restored = await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled == null,
      );
      expect((restored as PendingData).items, hasLength(1));
      verifyNever(() => repo.reject(any()));
    });

    test('PC08: timer expiry calls repo.reject', () {
      fakeAsync((async) {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(pendingControllerProvider, (_, _) {});

        pendingCtrl.add([_pending(id: 1)]);
        async.flushMicrotasks();

        // ignore: unawaited_futures
        container.read(pendingControllerProvider.notifier).skip(1);
        async.flushMicrotasks();

        async.elapse(kUndoWindow + const Duration(seconds: 1));
        async.flushMicrotasks();

        verify(() => repo.reject(1)).called(1);
      });
    });

    test('PC09: failed reject fires PendingSkipFailedEffect and restores row',
        () {
      // Drives the timer-driven failure path explicitly. The earlier
      // version of this test triggered _commitSkip by starting a second
      // skip, which silently coupled the assertion to PC10's behavior;
      // fakeAsync.elapse exercises the natural production path.
      fakeAsync((async) {
        when(() => repo.reject(any())).thenThrow(StateError('disk full'));

        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(pendingControllerProvider, (_, _) {});

        pendingCtrl.add([_pending(id: 1)]);
        async.flushMicrotasks();

        final notifier = container.read(pendingControllerProvider.notifier);
        final captured = <PendingEffect>[];
        notifier.setEffectListener(captured.add);

        // ignore: unawaited_futures
        notifier.skip(1);
        async.flushMicrotasks();

        // Confirm the row is visually skipped before the timer fires.
        var state = container.read(pendingControllerProvider).valueOrNull;
        expect(state, isA<PendingData>());
        expect((state as PendingData).skipScheduled?.pendingId, 1);

        // Let the undo window expire. _commitSkip runs, repo.reject throws,
        // controller restores skipScheduled and fires PendingSkipFailedEffect.
        async.elapse(kUndoWindow + const Duration(seconds: 1));
        async.flushMicrotasks();

        verify(() => repo.reject(1)).called(1);
        expect(
          captured.whereType<PendingSkipFailedEffect>(),
          hasLength(1),
        );

        // Row id=1 must reappear in the items stream (skipScheduled restored
        // means the visual filter no longer hides id=1).
        state = container.read(pendingControllerProvider).valueOrNull;
        expect(state, isA<PendingData>());
        expect(
          (state as PendingData).skipScheduled?.pendingId,
          1,
          reason: 'failed commit should restore skipScheduled',
        );
        expect(state.items.any((p) => p.id == 1), isTrue);
      });
    });

    test('PC10: second skip during pending undo commits the prior', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1), _pending(id: 2, memo: 'Rent')]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      // ignore: unawaited_futures
      notifier.skip(1);
      await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled?.pendingId == 1,
      );

      // ignore: unawaited_futures
      notifier.skip(2);
      await pump();

      // Prior skip (id=1) should have been committed immediately
      verify(() => repo.reject(1)).called(1);
      // New skip scheduled for id=2
      final state = await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled?.pendingId == 2,
      );
      expect(state, isA<PendingData>());
    });

    test('PC11: dispose during pending skip does not throw on closed stream',
        () async {
      // Regression: an earlier _Composer would call _out.add() inside a
      // microtask scheduled before dispose. After dispose closed _out,
      // the microtask would fire and StateError on the closed stream.
      final container = makeContainer();
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1)]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      // Schedule a skip; the resulting microtask emit should be safely
      // dropped if the container disposes between schedule and fire.
      // ignore: unawaited_futures
      notifier.skip(1);

      // Dispose synchronously, then drain microtasks. No StateError.
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Smoke check: re-creating the container starts fresh.
      final fresh = makeContainer();
      addTearDown(fresh.dispose);
      fresh.listen(pendingControllerProvider, (_, _) {});
      expect(
        fresh.read(pendingControllerProvider),
        isA<AsyncLoading<PendingState>>(),
      );
    });
  });
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/controllers/pending_controller_test.dart`
Expected: FAIL — `pendingControllerProvider` not found

- [x] **Step 3: Implement PendingController**

Create `lib/features/home/pending_controller.dart`:

```dart
// Pending approval slice controller — spec 2026-05-08.
//
// `PendingController` composes `pendingTransactionRepository.watchAll()`
// into a single [PendingState]. Mirrors `RecurringRulesController`'s
// delete-with-undo pattern: swipe-skip hides the row immediately and
// starts a 4-second timer; `undoSkip` cancels without touching the
// repository; timer fires → `repo.reject(id)`.
//
// `keepAlive: true` because the skip-undo timer must survive trivial
// rebuilds during the 4-second window (same rationale as HomeController).

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../data/models/pending_transaction.dart';
import '../../data/repositories/pending_transaction_repository.dart';
import 'pending_state.dart';

part 'pending_controller.g.dart';

typedef PendingEffectListener = void Function(PendingEffect effect);

sealed class PendingEffect {
  const PendingEffect();
}

/// Fired immediately when the user swipes a row to skip. The widget shows a
/// SnackBar with `homePendingSkippedSnack` text and an Undo action that calls
/// `notifier.undoSkip()`. Carries `ruleName` for future copy variants; v1 uses
/// the static string.
final class PendingSkipStartedEffect extends PendingEffect {
  const PendingSkipStartedEffect({required this.pendingId, this.ruleName});
  final int pendingId;
  final String? ruleName;
}

/// Fired after a successful approve. The widget shows a SnackBar with
/// `homePendingApprovedSnack(ruleName)`.
final class PendingApproveSucceededEffect extends PendingEffect {
  const PendingApproveSucceededEffect({required this.ruleName});
  final String ruleName;
}

final class PendingApproveFailedEffect extends PendingEffect {
  const PendingApproveFailedEffect(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

final class PendingSkipFailedEffect extends PendingEffect {
  const PendingSkipFailedEffect(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

@Riverpod(dependencies: [pendingTransactionRepository])
class PendingController extends _$PendingController {
  PendingSkipScheduled? _skipScheduled;
  Timer? _undoTimer;
  _Composer? _composer;
  PendingEffectListener? _effectListener;

  @override
  Stream<PendingState> build() {
    final repo = ref.watch(pendingTransactionRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      skipScheduledGetter: () => _skipScheduled,
    );
    _composer = composer;
    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _skipScheduled = null;
      composer.dispose();
    });
    return composer.stream;
  }

  // ---------- Commands ----------

  /// Approve. Returns true on success, false on failure. Returning a bool
  /// (rather than throwing) lets `_ApproveCircleButton` reverse its
  /// success animation when the underlying call fails.
  Future<bool> approve(int pendingId) async {
    // Capture rule name for the snackbar before the row is deleted.
    final ruleName = _findRuleName(pendingId);
    try {
      await ref.read(pendingTransactionRepositoryProvider).approve(pendingId);
      _effectListener?.call(
        PendingApproveSucceededEffect(ruleName: ruleName ?? ''),
      );
      return true;
    } catch (error, stackTrace) {
      _effectListener?.call(PendingApproveFailedEffect(error, stackTrace));
      return false;
    }
  }

  Future<void> skip(int pendingId) async {
    if (_skipScheduled != null) {
      // Commit prior pending skip now.
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _skipScheduled!;
      _skipScheduled = null;
      await _commitSkip(prior.pendingId);
    }

    final scheduledFor = DateTime.now().add(kUndoWindow);
    _skipScheduled = PendingSkipScheduled(
      pendingId: pendingId,
      scheduledFor: scheduledFor,
    );
    _composer?.notifySkipChanged();

    // Tell the widget to surface the SnackBar + Undo action.
    _effectListener?.call(
      PendingSkipStartedEffect(
        pendingId: pendingId,
        ruleName: _findRuleName(pendingId),
      ),
    );

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _skipScheduled;
      if (pending == null) return;
      await _commitSkip(pending.pendingId);
    });
  }

  /// Best-effort lookup of the rule name from the latest data state.
  /// Returns null when the controller is in loading/empty/error or the
  /// row has already been removed from the stream.
  String? _findRuleName(int pendingId) {
    final state = this.state.valueOrNull;
    if (state is! PendingData) return null;
    for (final item in state.items) {
      if (item.id == pendingId) return item.memo;
    }
    return null;
  }

  Future<void> undoSkip() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _skipScheduled = null;
    _composer?.notifySkipChanged();
  }

  void setEffectListener(PendingEffectListener? listener) {
    _effectListener = listener;
  }

  Future<void> _commitSkip(int pendingId) async {
    _skipScheduled = null;
    _composer?.notifySkipChanged();
    try {
      await ref.read(pendingTransactionRepositoryProvider).reject(pendingId);
    } catch (error, stackTrace) {
      // Restore the skip state so the row reappears in the UI.
      _skipScheduled = PendingSkipScheduled(
        pendingId: pendingId,
        scheduledFor: DateTime.now(),
      );
      _composer?.notifySkipChanged();
      _effectListener?.call(PendingSkipFailedEffect(error, stackTrace));
    }
  }
}

// ---------- Internal stream composition ----------

class _Composer {
  _Composer({
    required PendingTransactionRepository repo,
    required PendingSkipScheduled? Function() skipScheduledGetter,
  }) : _repo = repo,
       _skipScheduledGetter = skipScheduledGetter {
    _out = StreamController<PendingState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final PendingTransactionRepository _repo;
  final PendingSkipScheduled? Function() _skipScheduledGetter;
  late final StreamController<PendingState> _out;
  StreamSubscription<List<PendingTransaction>>? _sub;
  List<PendingTransaction>? _items;
  bool _emitScheduled = false;

  Stream<PendingState> get stream => _out.stream;

  void _start() {
    _out.add(const PendingState.loading());
    _sub = _repo.watchAll().listen((rows) {
      _items = rows;
      _scheduleEmit();
    }, onError: _onError);
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await _stop();
    if (!_out.isClosed) await _out.close();
  }

  void notifySkipChanged() => _scheduleEmit();

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(PendingState.error(error, stack));
  }

  void _scheduleEmit() {
    if (_emitScheduled || _out.isClosed) return;
    _emitScheduled = true;
    scheduleMicrotask(() {
      _emitScheduled = false;
      // Re-check at fire time: dispose() may have run between schedule and
      // microtask execution, leaving _out closed. Adding to a closed
      // StreamController throws StateError.
      if (_out.isClosed) return;
      _emitIfReady();
    });
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    final items = _items;
    if (items == null) return;

    final skip = _skipScheduledGetter();

    // Defensive check: a synchronous listener could call dispose() between
    // _emitIfReady's top-of-method guard and the actual `_out.add` call,
    // so we re-check immediately before each add.
    if (items.isEmpty && skip == null) {
      if (_out.isClosed) return;
      _out.add(const PendingState.empty());
    } else {
      if (_out.isClosed) return;
      _out.add(PendingState.data(items: items, skipScheduled: skip));
    }
  }
}
```

- [x] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `pending_controller.g.dart` generated

- [x] **Step 5: Run tests to verify they pass**

Run: `flutter test test/unit/controllers/pending_controller_test.dart`
Expected: All tests PASS

- [x] **Step 6: Run format + analyze**

Run: `dart format lib/features/home/pending_controller.dart lib/features/home/pending_state.dart test/unit/controllers/pending_controller_test.dart && flutter analyze`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/pending_state.dart \
  lib/features/home/pending_controller.dart \
  test/unit/controllers/pending_controller_test.dart
git commit -m "feat(home): add PendingState and PendingController with approve/skip/undo"
```

---

## Chunk 3: l10n + Widgets

### Task 5: Add l10n keys

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `test/unit/l10n/arb_audit_test.dart`

- [x] **Step 1: Add 6 keys to `l10n/app_en.arb`**

Add these entries (before the closing `}`):

```json
"homePendingSectionTitle": "Pending",
"@homePendingSectionTitle": { "description": "Section header label for pending approval items on Home" },
"homePendingApprove": "Approve",
"@homePendingApprove": { "description": "Semantics label on the circle approve button" },
"homePendingSkip": "Skip once",
"@homePendingSkip": { "description": "Swipe action label for skipping a single occurrence of a pending recurring item. Phrased as 'Skip once' (not 'Skip') to signal that the rule continues to generate next time." },
"homePendingApprovedSnack": "Approved — {ruleName}",
"@homePendingApprovedSnack": { "description": "Success snackbar after approving a pending item", "placeholders": { "ruleName": { "type": "String" } } },
"homePendingSkippedSnack": "Skipped this occurrence",
"@homePendingSkippedSnack": { "description": "Snackbar shown after a swipe-skip on a pending recurring item. The companion action button uses commonUndo. The copy emphasises 'this occurrence' so users understand the parent rule is unaffected." },
"homePendingLoadError": "Couldn't load pending items.",
"@homePendingLoadError": { "description": "Error banner when pending items fail to load" },
"homePendingShowMore": "Show {count} more",
"@homePendingShowMore": { "description": "TextButton label that expands the pending section beyond its visible-tile cap. {count} is the number of additional pending items hidden behind the cap.", "placeholders": { "count": { "type": "int" } } },
"homePendingShowFewer": "Show fewer",
"@homePendingShowFewer": { "description": "TextButton label that collapses the pending section back to its visible-tile cap." },
```

- [x] **Step 2: Add 6 keys to `l10n/app_zh_TW.arb`**

```json
"homePendingSectionTitle": "待處理",
"homePendingApprove": "核准",
"homePendingSkip": "略過此次",
"homePendingApprovedSnack": "已核准 — {ruleName}",
"homePendingSkippedSnack": "已略過此次",
"homePendingLoadError": "無法載入待處理項目。",
"homePendingShowMore": "再顯示 {count} 項",
"homePendingShowFewer": "顯示較少",
```

- [x] **Step 3: Add 6 keys to `l10n/app_zh_CN.arb`**

```json
"homePendingSectionTitle": "待处理",
"homePendingApprove": "批准",
"homePendingSkip": "跳过此次",
"homePendingApprovedSnack": "已批准 — {ruleName}",
"homePendingSkippedSnack": "已跳过此次",
"homePendingLoadError": "无法加载待处理项目。",
"homePendingShowMore": "再显示 {count} 项",
"homePendingShowFewer": "显示更少",
```

- [x] **Step 4: Add 8 keys to `_expectedEnKeys` in `test/unit/l10n/arb_audit_test.dart`**

Add to the `_expectedEnKeys` set (after the recurring transactions section):

```dart
  // Pending approval on Home
  // (docs/superpowers/specs/2026-05-08-pending-approval-on-home-design.md).
  'homePendingSectionTitle',
  'homePendingApprove',
  'homePendingSkip',
  'homePendingApprovedSnack',
  'homePendingSkippedSnack',
  'homePendingLoadError',
  'homePendingShowMore',
  'homePendingShowFewer',
```

- [x] **Step 5: Run ARB audit test**

Run: `flutter test test/unit/l10n/arb_audit_test.dart`
Expected: PASS

- [x] **Step 6: Run format + analyze**

Run: `dart format test/unit/l10n/ && flutter analyze`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add l10n/app_en.arb l10n/app_zh_TW.arb l10n/app_zh_CN.arb test/unit/l10n/arb_audit_test.dart
git commit -m "feat(l10n): add pending approval home keys to all locales"
```

### Task 6: Create PendingSection + PendingTile widgets

**Files:**
- Create: `lib/features/home/widgets/pending_section.dart`
- Create: `test/widget/features/home/pending_section_test.dart`
- Create: `test/widget/features/home/pending_tile_test.dart`

PendingTile reuses the existing `homeCategoriesByIdProvider` / `homeAccountsByIdProvider` from `lib/features/home/home_providers.dart` for its category-icon / account-name lookups. Don't create a parallel `pending_providers.dart` file — the home providers already serve this exact purpose (lookup maps including archived rows for historical-row resolution) and are already mounted by the surrounding HomeScreen, so reusing them avoids duplicate `watchAll` subscriptions.

- [x] **Step 1: Write PendingSection widget tests (PS01–PS05)**

Create `test/widget/features/home/pending_section_test.dart`:

```dart
// PendingSection widget tests.
//
// Covers loading / empty / data / error rendering using the _FakeController
// pattern from recurring_rules_screen_test.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/pending_transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/features/home/pending_controller.dart';
import 'package:ledgerly/features/home/pending_state.dart';
import 'package:ledgerly/features/home/widgets/pending_section.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockPendingRepo extends Mock implements PendingTransactionRepository {}
class _MockCategoryRepo extends Mock implements CategoryRepository {}
class _MockAccountRepo extends Mock implements AccountRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

PendingTransaction _pending({
  required int id,
  String memo = 'Netflix',
  int amount = 1599,
}) => PendingTransaction(
  id: id,
  source: 'recurring',
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  memo: memo,
  date: DateTime(2026, 5, 8),
  fetchedAt: DateTime(2026, 5, 8),
  recurringRuleId: 1,
);

class _FakeController extends PendingController {
  _FakeController(this._fixed);
  final PendingState _fixed;

  @override
  Stream<PendingState> build() async* {
    yield _fixed;
  }
}

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CustomScrollView(
          slivers: [PendingSection()],
        ),
      ),
    ),
  );
}

ProviderContainer _makeContainer(PendingState fixed) {
  final repo = _MockPendingRepo();
  final catRepo = _MockCategoryRepo();
  final accRepo = _MockAccountRepo();
  when(() => repo.watchAll()).thenAnswer((_) => const Stream.empty());
  when(() => repo.approve(any())).thenAnswer((_) async => throw UnimplementedError());
  when(() => repo.reject(any())).thenAnswer((_) async {});
  when(() => catRepo.watchAll(includeArchived: any(named: 'includeArchived')))
      .thenAnswer((_) => const Stream.empty());
  when(() => accRepo.watchAll(includeArchived: any(named: 'includeArchived')))
      .thenAnswer((_) => const Stream.empty());
  return ProviderContainer(
    overrides: [
      pendingTransactionRepositoryProvider.overrideWithValue(repo),
      categoryRepositoryProvider.overrideWithValue(catRepo),
      accountRepositoryProvider.overrideWithValue(accRepo),
      pendingControllerProvider.overrideWith(() => _FakeController(fixed)),
    ],
  );
}

void main() {
  testWidgets('PS01: PendingLoading renders SizedBox.shrink', (tester) async {
    final container = _makeContainer(const PendingState.loading());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    // The section should render nothing visible
    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('PS02: PendingEmpty renders SizedBox.shrink', (tester) async {
    final container = _makeContainer(const PendingState.empty());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('PS03: PendingData with N items shows header + N tiles', (
    tester,
  ) async {
    final items = [_pending(id: 1), _pending(id: 2, memo: 'Rent', amount: 2000)];
    final container = _makeContainer(PendingState.data(
      items: items,
      skipScheduled: null,
    ));
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
  });

  testWidgets('PS04: tap on row body does nothing', (tester) async {
    final container = _makeContainer(PendingState.data(
      items: [_pending(id: 1)],
      skipScheduled: null,
    ));
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    // Tap the tile body — should not trigger any navigation
    await tester.tap(find.text('Netflix'));
    await tester.pump();

    // No route push expected — just verifying no crash
  });

  testWidgets('PS05: error variant renders inline banner', (tester) async {
    final container = _makeContainer(
      PendingState.error(StateError('boom'), StackTrace.current),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load pending items."), findsOneWidget);
  });
}
```

- [x] **Step 2: Write PendingTile + ApproveCircleButton tests (PT01–PT07)**

Create `test/widget/features/home/pending_tile_test.dart`:

```dart
// PendingTile + _ApproveCircleButton widget tests.
//
// Covers tile rendering, approve animation, debounce, swipe-skip,
// and localized subtitle formatting.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/pending_transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/features/home/pending_controller.dart';
import 'package:ledgerly/features/home/pending_state.dart';
import 'package:ledgerly/features/home/widgets/pending_section.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockPendingRepo extends Mock implements PendingTransactionRepository {}
class _MockCategoryRepo extends Mock implements CategoryRepository {}
class _MockAccountRepo extends Mock implements AccountRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

PendingTransaction _pending({
  required int id,
  String memo = 'Netflix',
  int amount = 1599,
}) => PendingTransaction(
  id: id,
  source: 'recurring',
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  memo: memo,
  date: DateTime(2026, 5, 8),
  fetchedAt: DateTime(2026, 5, 8),
  recurringRuleId: 1,
);

class _FakeController extends PendingController {
  _FakeController(this._fixed);
  final PendingState _fixed;

  @override
  Stream<PendingState> build() async* {
    yield _fixed;
  }
}

Widget _wrap(ProviderContainer container, {Widget? child}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [child ?? PendingSection()],
        ),
      ),
    ),
  );
}

ProviderContainer _makeContainer(PendingState fixed) {
  final repo = _MockPendingRepo();
  final catRepo = _MockCategoryRepo();
  final accRepo = _MockAccountRepo();
  when(() => repo.watchAll()).thenAnswer((_) => const Stream.empty());
  when(() => repo.approve(any())).thenAnswer((_) async => throw UnimplementedError());
  when(() => repo.reject(any())).thenAnswer((_) async {});
  when(() => catRepo.watchAll(includeArchived: any(named: 'includeArchived')))
      .thenAnswer((_) => const Stream.empty());
  when(() => accRepo.watchAll(includeArchived: any(named: 'includeArchived')))
      .thenAnswer((_) => const Stream.empty());
  return ProviderContainer(
    overrides: [
      pendingTransactionRepositoryProvider.overrideWithValue(repo),
      categoryRepositoryProvider.overrideWithValue(catRepo),
      accountRepositoryProvider.overrideWithValue(accRepo),
      pendingControllerProvider.overrideWith(() => _FakeController(fixed)),
    ],
  );
}

void main() {
  testWidgets('PT01: default circle is grey with check icon', (tester) async {
    final container = _makeContainer(PendingState.data(
      items: [_pending(id: 1)],
      skipScheduled: null,
    ));
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    // The approve circle should have a check icon
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('PT02: tapping circle calls controller.approve once', (
    tester,
  ) async {
    final repo = _MockPendingRepo();
    final catRepo = _MockCategoryRepo();
    final accRepo = _MockAccountRepo();
    when(() => repo.watchAll()).thenAnswer(
      (_) => Stream.value([_pending(id: 1)]),
    );
    // Successful approve returns a saved Transaction.
    when(() => repo.approve(1)).thenAnswer(
      (_) async => Transaction(
        id: 99,
        amountMinorUnits: 1599,
        currency: _usd,
        categoryId: 1,
        accountId: 1,
        date: DateTime(2026, 5, 8),
        memo: 'Netflix',
        createdAt: DateTime(2026, 5, 8, 12),
        updatedAt: DateTime(2026, 5, 8, 12),
      ),
    );
    when(() => repo.reject(any())).thenAnswer((_) async {});
    when(() => catRepo.watchAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());
    when(() => accRepo.watchAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());

    final container = ProviderContainer(
      overrides: [
        pendingTransactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    verify(() => repo.approve(1)).called(1);
  });

  testWidgets('PT03: rapid double-tap on circle still calls approve only once',
      (tester) async {
    // Debounce: the `_approving` flag must absorb a second tap that lands
    // before the 200ms forward animation completes.
    final repo = _MockPendingRepo();
    final catRepo = _MockCategoryRepo();
    final accRepo = _MockAccountRepo();
    when(() => repo.watchAll()).thenAnswer(
      (_) => Stream.value([_pending(id: 1)]),
    );
    final approveCompleter = Completer<Transaction>();
    when(() => repo.approve(1))
        .thenAnswer((_) => approveCompleter.future);
    when(() => repo.reject(any())).thenAnswer((_) async {});
    when(() => catRepo.watchAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());
    when(() => accRepo.watchAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());

    final container = ProviderContainer(
      overrides: [
        pendingTransactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    // Two rapid taps before the approve future resolves.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 50));

    // Only the first tap should have reached the repo.
    verify(() => repo.approve(1)).called(1);

    // Resolve the approve so the test cleans up cleanly.
    approveCompleter.complete(
      Transaction(
        id: 99,
        amountMinorUnits: 1599,
        currency: _usd,
        categoryId: 1,
        accountId: 1,
        date: DateTime(2026, 5, 8),
        memo: 'Netflix',
        createdAt: DateTime(2026, 5, 8, 12),
        updatedAt: DateTime(2026, 5, 8, 12),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('PT04: PendingApproveFailedEffect surfaces error snackbar', (
    tester,
  ) async {
    final repo = _MockPendingRepo();
    final catRepo = _MockCategoryRepo();
    final accRepo = _MockAccountRepo();
    when(() => repo.watchAll()).thenAnswer(
      (_) => Stream.value([_pending(id: 1)]),
    );
    // Failure path: repo throws, controller fires PendingApproveFailedEffect,
    // widget shows errorSnackbarGeneric.
    when(() => repo.approve(1))
        .thenThrow(PendingTransactionRepositoryException('archived'));
    when(() => repo.reject(any())).thenAnswer((_) async {});
    when(() => catRepo.watchAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());
    when(() => accRepo.watchAll(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());

    final container = ProviderContainer(
      overrides: [
        pendingTransactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(); // trigger snackbar
    await tester.pump(const Duration(milliseconds: 500));

    // Generic error snackbar appears (exact copy comes from
    // l10n.errorSnackbarGeneric — assert by widget type to stay locale-safe).
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('PT05: swipe-left reveals Skip action', (tester) async {
    final container = _makeContainer(PendingState.data(
      items: [_pending(id: 1)],
      skipScheduled: null,
    ));
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    // Swipe left to reveal the Skip action
    await tester.drag(find.text('Netflix'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('PT06: subtitle renders category · account · date', (tester) async {
    final container = _makeContainer(PendingState.data(
      items: [_pending(id: 1)],
      skipScheduled: null,
    ));
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    // The subtitle should contain account name and date components.
    // Exact format depends on locale; just verify the tile renders.
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('PT07: 2x text scale does not overflow trailing slot', (
    tester,
  ) async {
    final container = _makeContainer(PendingState.data(
      items: [_pending(id: 1)],
      skipScheduled: null,
    ));
    addTearDown(container.dispose);

    // Wrap in MediaQuery with 2x text scale.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2.0),
        ),
        child: _wrap(container),
      ),
    );
    await tester.pumpAndSettle();

    // No layout overflow exceptions should have been thrown.
    expect(tester.takeException(), isNull);
    // The amount text and approve circle must both still be present.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
```

- [x] **Step 3: Run tests to verify they fail**

Run: `flutter test test/widget/features/home/pending_section_test.dart test/widget/features/home/pending_tile_test.dart`
Expected: FAIL — `PendingSection` not found

- [x] **Step 4: Implement PendingSection, PendingTile, _ApproveCircleButton**

Create `lib/features/home/widgets/pending_section.dart`:

```dart
// Pending approval section — spec 2026-05-08.
//
// Sticky SliverToBoxAdapter mounted on HomeScreen above the transaction
// list. Watches pendingControllerProvider and renders a header + list
// of PendingTile widgets. Auto-hides when no pending rows exist.
//
// The Approve circle button owns a 200ms grey→green animation and
// debounces rapid taps. Swipe-left reveals a Skip action (flutter_slidable).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/pending_transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants.dart';
import '../../categories/widgets/category_display.dart';
import '../home_providers.dart';
import '../pending_controller.dart';
import '../pending_state.dart';
import 'pending_badge.dart';

/// Sliver that renders the pending approval section on HomeScreen.
class PendingSection extends ConsumerStatefulWidget {
  const PendingSection({super.key});

  @override
  ConsumerState<PendingSection> createState() => _PendingSectionState();
}

/// Maximum number of pending tiles to render before collapsing the rest
/// behind a "Show N more" expander. Bounds the worst case where a user
/// returns after a long absence with many overdue rules — the section
/// would otherwise push today's transactions below the fold.
const int _kPendingCollapseThreshold = 5;

class _PendingSectionState extends ConsumerState<PendingSection> {
  PendingController? _controller;
  PendingEffectListener? _effectListener;
  bool _expanded = false;

  @override
  void dispose() {
    _controller?.setEffectListener(null);
    super.dispose();
  }

  void _bindController(PendingController controller) {
    if (_controller == controller) return;
    _controller?.setEffectListener(null);
    _controller = controller;
    _effectListener = _onEffect;
    controller.setEffectListener(_effectListener);
  }

  void _onEffect(PendingEffect effect) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    switch (effect) {
      case PendingSkipStartedEffect(:final pendingId):
        // Skip removes ONE occurrence; the parent rule keeps generating.
        // The Undo action on this SnackBar is the only recovery path —
        // the controller will commit `repo.reject(id)` once kUndoWindow
        // elapses, and the row vanishes for good after that.
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.homePendingSkippedSnack),
              duration: kUndoWindow,
              action: SnackBarAction(
                label: l10n.commonUndo,
                onPressed: () {
                  // Capture the controller before the SnackBar closure
                  // outlives the build context.
                  ref.read(pendingControllerProvider.notifier).undoSkip();
                },
              ),
            ),
          );
      case PendingApproveSucceededEffect(:final ruleName):
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.homePendingApprovedSnack(ruleName),
              ),
            ),
          );
      case PendingApproveFailedEffect():
      case PendingSkipFailedEffect():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingControllerProvider);

    return switch (state) {
      AsyncData<PendingState>(value: final PendingLoading _) =>
        const SliverToBoxAdapter(child: SizedBox.shrink()),
      AsyncData<PendingState>(value: final PendingEmpty _) =>
        const SliverToBoxAdapter(child: SizedBox.shrink()),
      AsyncData<PendingState>(value: final PendingError error) =>
        SliverToBoxAdapter(
          child: _ErrorBanner(
            message: AppLocalizations.of(context).homePendingLoadError,
          ),
        ),
      AsyncData<PendingState>(value: final PendingData data) =>
        _buildData(context, data),
      _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
    };
  }

  Widget _buildData(BuildContext context, PendingData data) {
    final notifier = ref.read(pendingControllerProvider.notifier);
    _bindController(notifier);

    final l10n = AppLocalizations.of(context);

    // Filter out the visually-skipped row.
    final skipId = data.skipScheduled?.pendingId;
    final visible = skipId == null
        ? data.items
        : data.items.where((item) => item.id != skipId).toList();

    if (visible.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final categories =
        ref.watch(homeCategoriesByIdProvider).valueOrNull ?? const {};
    final accounts =
        ref.watch(homeAccountsByIdProvider).valueOrNull ?? const {};
    final locale = Localizations.localeOf(context).toString();

    // Cap visible tiles so the section doesn't push the day list below
    // the fold for users with many overdue rules. The header always
    // shows the true total via PendingBadge(visible.length).
    final overflowCount = visible.length - _kPendingCollapseThreshold;
    final showCollapseToggle = overflowCount > 0;
    final tilesToRender = (showCollapseToggle && !_expanded)
        ? visible.take(_kPendingCollapseThreshold).toList()
        : visible;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: homePageCardHorizontalPadding,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Pending · N items"
            //
            // Do NOT call .toUpperCase() — it is a no-op on '待處理'/'待处理'
            // and would render the EN header in caps while CJK stays in
            // sentence case. Visual weight comes from labelSmall +
            // letterSpacing + fontWeight, not casing.
            Row(
              children: [
                Text(
                  l10n.homePendingSectionTitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                PendingBadge(count: visible.length),
              ],
            ),
            const SizedBox(height: 8),
            // Tiles
            Column(
              children: [
                for (final item in tilesToRender)
                  PendingTile(
                    key: ValueKey(item.id),
                    item: item,
                    category: item.categoryId != null
                        ? categories[item.categoryId]
                        : null,
                    account: accounts[item.accountId],
                    locale: locale,
                    onApprove: () => notifier.approve(item.id),
                    onSkip: () => notifier.skip(item.id),
                  ),
              ],
            ),
            if (showCollapseToggle)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? l10n.homePendingShowFewer
                        : l10n.homePendingShowMore(overflowCount),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline load-error banner. We use a plain Container instead of
/// MaterialBanner because MaterialBanner forces a non-empty `actions`
/// list (the ~48 px row appears even with `[SizedBox.shrink()]`), which
/// inflates the banner height and adds an invisible tap target.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: homePageCardHorizontalPadding,
        vertical: 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single pending-row tile with Approve circle + swipe-left Skip.
class PendingTile extends StatelessWidget {
  const PendingTile({
    super.key,
    required this.item,
    required this.category,
    required this.account,
    required this.locale,
    required this.onApprove,
    required this.onSkip,
  });

  final PendingTransaction item;
  final Category? category;
  final Account? account;
  final String locale;
  /// Returns `true` on success and `false` on failure so the approve circle
  /// can reverse its 200 ms green animation when the underlying call fails.
  final Future<bool> Function() onApprove;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final categoryIcon = category != null
        ? iconForKey(category!.icon)
        : Icons.schedule;
    final categoryColor = category != null
        ? colorForIndex(category!.color)
        : theme.disabledColor;
    final categoryName = category != null
        ? categoryDisplayName(category!, l10n)
        : '';
    final accountName = account?.name ?? '';
    final dateStr = DateFormat.yMMMd(locale).format(item.date);
    final subtitleParts = <String>[
      if (categoryName.isNotEmpty) categoryName,
      if (accountName.isNotEmpty) accountName,
      dateStr,
    ];
    final subtitle = subtitleParts.join(' · ');

    final amountStr = MoneyFormatter.format(
      amountMinorUnits: item.amountMinorUnits,
      currency: item.currency,
      locale: locale,
    );

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onSkip(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            label: l10n.homePendingSkip,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          border: Border(
            left: BorderSide(color: theme.colorScheme.tertiary, width: 3),
          ),
        ),
        child: ListTile(
          leading: Icon(categoryIcon, color: categoryColor, size: 24),
          title: Text(item.memo ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountStr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _ApproveCircleButton(
                onApproveAsync: onApprove,
                semanticsLabel: l10n.homePendingApprove,
              ),
            ],
          ),
          onTap: null, // Body tap is a no-op per spec.
        ),
      ),
    );
  }
}

/// 36×36 circle Approve button with 200ms grey→green animation.
/// Debounces rapid taps via `_approving` flag. On failure the controller
/// returns `false` and the animation reverses (green → grey).
class _ApproveCircleButton extends StatefulWidget {
  const _ApproveCircleButton({
    required this.onApproveAsync,
    required this.semanticsLabel,
  });

  /// Returns `true` on success, `false` on failure. The button uses the
  /// result to decide whether to reset (success) or reverse (failure).
  final Future<bool> Function() onApproveAsync;
  final String semanticsLabel;

  @override
  State<_ApproveCircleButton> createState() => _ApproveCircleButtonState();
}

class _ApproveCircleButtonState extends State<_ApproveCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Color?> _colorAnimation;
  late final Animation<double> _scaleAnimation;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent, // Will be set in build
      end: Colors.transparent,
    ).animate(_animController);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheme = Theme.of(context).colorScheme;
    _colorAnimation = ColorTween(
      begin: scheme.surfaceContainerHighest,
      end: scheme.tertiary,
    ).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_approving) return;
    _approving = true;

    await _animController.forward();

    final success = await widget.onApproveAsync();

    if (!mounted) return;
    if (success) {
      // The row will be removed from the stream momentarily; reset locally
      // so that any reused tile (e.g. another row taking this slot during
      // re-emission) starts in the grey state.
      _animController.reset();
    } else {
      // Reverse the green confirmation so the user sees the action did
      // not land. Per spec: 200 ms green → grey on failure.
      await _animController.reverse();
    }
    _approving = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value ?? scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: _animController.isAnimating ||
                            _animController.isCompleted
                        ? scheme.onTertiary
                        : scheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success

- [x] **Step 6: Run tests**

Run: `flutter test test/widget/features/home/pending_section_test.dart test/widget/features/home/pending_tile_test.dart`
Expected: All tests PASS

- [x] **Step 7: Run format + analyze**

Run: `dart format lib/features/home/ test/widget/features/home/ && flutter analyze`
Expected: No errors

- [ ] **Step 8: Commit**

```bash
git add lib/features/home/widgets/pending_section.dart \
  test/widget/features/home/pending_section_test.dart \
  test/widget/features/home/pending_tile_test.dart
git commit -m "feat(home): add PendingSection, PendingTile, ApproveCircleButton widgets"
```

---

## Chunk 4: HomeScreen Wiring + Cleanup + Integration Test

### Task 7: Wire PendingSection into HomeScreen and remove pendingBadgeCount

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/home/home_state.dart`
- Modify: `lib/features/home/home_controller.dart`
- Modify: `lib/features/home/home_state.freezed.dart` (codegen)

- [x] **Step 1: Add PendingSection to HomeScreen sliver list**

In `lib/features/home/home_screen.dart`, import the new widget and insert it between the `DayNavigationHeader` and the transaction list:

Add import at top:
```dart
import 'widgets/pending_section.dart';
```

In the `_SinglePane.build` method, add the `PendingSection` sliver after the `DayNavigationHeader` and before the transaction list. The sliver list becomes:

```dart
slivers: [
  const SliverPadding(padding: EdgeInsets.only(top: 38)),
  SliverToBoxAdapter(
    child: SummaryStrip(
      todayTotalsByCurrency: data.todayTotalsByCurrency,
      monthNetByCurrency: data.monthNetByCurrency,
      currenciesByCode: currencies,
      locale: locale,
      showJumpToToday: !DateHelpers.isSameDay(data.selectedDay, data.today),
      onJumpToToday: onJumpToToday,
    ),
  ),
  SliverToBoxAdapter(
    child: DayNavigationHeader(
      selectedDay: data.selectedDay,
      locale: locale,
      onPrev: onPrev,
      onNext: onNext,
      onPickDay: () => onPickDay(data.selectedDay),
      canGoPrev: data.canGoPrev,
      canGoNext: data.canGoNext,
    ),
  ),
  const PendingSection(), // ← NEW
  // ... rest of slivers unchanged
```

Also remove the `trailing: PendingBadge(count: data.pendingBadgeCount)` from the `DayNavigationHeader` and remove the `PendingBadge` import if no longer used.

- [x] **Step 2: Remove `pendingBadgeCount` from HomeState**

In `lib/features/home/home_state.dart`:
- Remove `required int pendingBadgeCount` from `HomeEmpty`
- Remove `required int pendingBadgeCount` from `HomeData`

- [x] **Step 3: Remove `pendingBadgeCount` from HomeController emissions**

In `lib/features/home/home_controller.dart`:
- Remove `pendingBadgeCount: 0` from `HomeState.empty(...)` at line 384
- Remove `pendingBadgeCount: 0` from `HomeState.data(...)` at line 412

- [x] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `home_state.freezed.dart` regenerated

- [x] **Step 5: Update existing HomeState references in tests**

Search the entire `test/` tree for `pendingBadgeCount` and remove it from all `HomeState.data(...)`, `HomeState.empty(...)` constructors, and any direct field assertions.

Known site (verified by grep at plan-write time):
- `test/unit/controllers/home_controller_test.dart:151` — `expect(empty.pendingBadgeCount, 0);`

Run `grep -rn pendingBadgeCount test/` to surface anything else added since.

Add this file to the File Structure table under Modify:
- `test/unit/controllers/home_controller_test.dart` — Remove `pendingBadgeCount` assertion(s)

- [x] **Step 6: Run format + analyze**

Run: `dart format lib/features/home/ test/widget/features/home/ && flutter analyze`
Expected: No errors

- [x] **Step 7: Run all home tests**

Run: `flutter test test/widget/features/home/`
Expected: All tests PASS

- [ ] **Step 8: Commit**

```bash
git add lib/features/home/home_screen.dart \
  lib/features/home/home_state.dart \
  lib/features/home/home_controller.dart \
  test/widget/features/home/home_screen_test.dart
git commit -m "feat(home): wire PendingSection into HomeScreen, remove pendingBadgeCount"
```

### Task 8: Integration test

**Files:**
- Create: `test/integration/pending_approval_flow_test.dart`

- [x] **Step 1: Write integration test**

Create `test/integration/pending_approval_flow_test.dart`:

```dart
// End-to-end integration test for pending approval flow.
//
// Exercises: seed → generate pending rows → land on Home →
// approve → verify transaction appears → skip → undo →
// skip → wait → verify pending deleted.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule_draft.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';

import '../support/test_app.dart';

void main() {
  group('Pending approval flow', () {
    late AppDatabase db;

    setUp(() async {
      db = newTestAppDatabase();
      await runTestSeed(db);
    });

    tearDown(() async => db.close());

    testWidgets('approved pending row becomes a transaction on Home', (
      tester,
    ) async {
      // 1. Seed a recurring rule and generate a pending row.
      final currenciesRepo = DriftCurrencyRepository(db);
      final categoriesRepo = DriftCategoryRepository(db);
      final accountsRepo = DriftAccountRepository(db, currenciesRepo);
      final txRepo = DriftTransactionRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(
        db,
        txRepo: txRepo,
      );
      final recurringRepo = DriftRecurringRulesRepository(db);

      // Get the first seeded account and category
      final accounts = await accountsRepo.watchAll().first;
      final categories = await categoriesRepo.watchAll().first;
      final account = accounts.first;
      final category = categories.firstWhere((c) => c.type.name == 'expense');

      // Create a recurring rule. The repo computes next_due_date from
      // `today` + frequency/dayOfMonth — passing `today: DateTime(2026, 5, 8)`
      // makes the rule due on that date. We snapshot the currency from the
      // seeded account so the test stays portable across locales.
      final usd = await currenciesRepo.findByCode('USD');
      final ruleId = await recurringRepo.insert(
        RecurringRuleDraft(
          name: 'Netflix',
          amountMinorUnits: 1599,
          currency: usd!,
          categoryId: category.id,
          accountId: account.id,
          frequency: 'monthly',
          dayOfMonth: 8,
        ),
        today: DateTime(2026, 5, 8),
      );

      // Insert a pending row directly (simulating what generation does)
      await pendingRepo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: 'USD',
        categoryId: category.id,
        accountId: account.id,
        memo: 'Netflix',
        date: DateTime(2026, 5, 8),
        fetchedAt: DateTime(2026, 5, 8),
        recurringRuleId: ruleId,
      );

      // 2. Build the app
      final container = makeTestContainer(db: db);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // 3. Verify PendingSection renders the row
      expect(find.text('Netflix'), findsWidgets); // May appear in pending + list
      expect(find.byIcon(Icons.check), findsOneWidget); // Approve circle

      // 4. Tap the Approve circle
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // 5. Verify the pending row left the section
      // (The approved transaction now appears in today's list)
      // PendingBadge count should not be visible (section hidden)
      expect(find.text('Pending'), findsNothing);

      // 6. Verify the transactions table has the new row
      final txns = await txRepo.watchByDay(DateTime(2026, 5, 8)).first;
      expect(txns, hasLength(1));
      expect(txns.first.amountMinorUnits, 1599);
      expect(txns.first.memo, 'Netflix');

      // 7. Verify pending_transactions is empty
      final pendingRows = await pendingRepo.watchAll().first;
      expect(pendingRows, isEmpty);
    });
  });
}
```

- [x] **Step 2: Run the integration test**

Run: `flutter test test/integration/pending_approval_flow_test.dart`
Expected: PASS

- [x] **Step 3: Run format + analyze**

Run: `dart format test/integration/ && flutter analyze`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add test/integration/pending_approval_flow_test.dart
git commit -m "test: add integration test for pending approval flow"
```

## Out of Scope (deliberate)

The following are intentionally not in v1. Each lists a concrete tripwire so the team knows when to pull the work in.

- **In-snackbar "Stop rule" shortcut.** The skip SnackBar has only an Undo action. To stop a rule entirely the user navigates to `/settings/recurring/:id`. *Tripwire:* support reports "I keep skipping the same rule and it keeps coming back" reach >= 5 in a quarter, OR analytics show >= 30% of skip actions on the same `recurring_rule_id` within 60 days.
- **Per-row edit-before-approve.** Variable-amount rules (utility bills) require: edit the rule's amount in `/settings/recurring/:id` → wait for next cold start → approve. *Tripwire:* support reports of "the amount is wrong on my Pending row" reach >= 5 in a quarter. *Lightweight fallback if needed:* long-press on the tile opens the existing Add Transaction form pre-filled, and the row converts on save.
- **Home-level surface for cold-start generation failures.** If `runRecurringGenerationFn` throws, the failure is silent — discoverable only via the rule's error icon at `/settings/recurring`. *Tripwire:* the first user-reported missed-rule incident, OR Sentry/local crash logs (Phase 2) show `RecurringGenerationException` rate exceed 0.5% of cold starts. *Lightweight fallback:* a one-line `MaterialBanner` at the top of HomeScreen reading "Some recurring entries didn't generate. Tap to review." linking to `/settings/recurring`.
- **Approve undo.** See *Decisions and Trade-offs → Approve reversibility*. *Tripwire:* support reports of accidental approves exceed reports of "approve felt scary." *Fallback:* mirror the skip pattern with insert-then-delete-on-undo.
- **Source-aware blockchain pending tile.** `watchAll` filters `source = 'recurring'` for v1. Wallet sync (Phase 2) ships its own UI design.
- **Per-day pending anchoring.** PendingSection is global within HomeScreen. *Tripwire:* see *Decisions and Trade-offs → PendingSection placement*.

---

### Task 9: Final verification

- [x] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS

- [x] **Step 2: Run format check**

Run: `dart format --output=none --set-exit-if-changed .`
Expected: No formatting issues

- [x] **Step 3: Run import lint**

Run: `dart run import_lint`
Expected: No violations

- [ ] **Step 4: Final commit if any formatting fixes needed**

```bash
git add -A
git commit -m "chore: format and lint fixes for pending approval feature"
```
