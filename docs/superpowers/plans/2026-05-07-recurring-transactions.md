# Recurring Transactions Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can define recurring transaction rules (daily/weekly/monthly/yearly); the app generates pending rows on cold start; pending rows surface inline on Home alongside approved transactions for one-tap approval.

**Architecture:** A `RecurringGenerationUseCase` (lives in `lib/data/use_cases/`, not the Phase-2-only `domain/` layer) scans active rules during the bootstrap sequence, creates pending rows in `pending_transactions`, and advances `next_due_date`. The feature adds two new Drift tables (`recurring_rules`, `pending_transactions`) via a v3→v4 schema migration. UI follows the existing controller+state+screen pattern with a dedicated form screen.

**Wave-3 coordination (Home):** Approval happens on Home, not on a separate Pending Transactions screen. This plan ships the rule-management UI, the v4 `pending_transactions` schema, and the minimal repository methods needed by the generation engine (`existsForRuleAndDate`, `insert`). The Home Wave-3 plan will extend `PendingTransactionRepository` with whatever query and approve/reject methods it needs (e.g., `watchPendingForDay`, `approve`, `reject`); those methods do not ship here. All Pending-row UI copy ships with its consumer in Wave 3.

**Tech Stack:** Flutter, Drift (SQLite ORM), Riverpod (`riverpod_annotation`), Freezed, go_router, flutter_slidable, mocktail, fake_async

---

## File Structure

**New files:**

| File                                                                  | Responsibility                                                     |
|-----------------------------------------------------------------------|--------------------------------------------------------------------|
| `lib/data/database/tables/recurring_rules_table.dart`                 | Drift table for `recurring_rules`                                  |
| `lib/data/database/tables/pending_transactions_table.dart`            | Drift table for `pending_transactions`                             |
| `lib/data/database/daos/recurring_rule_dao.dart`                      | Thin SQL wrapper for `recurring_rules`                             |
| `lib/data/database/daos/pending_transaction_dao.dart`                 | Thin SQL wrapper for `pending_transactions`                        |
| `lib/data/models/recurring_rule.dart`                                 | Freezed domain model                                               |
| `lib/data/models/recurring_rule_draft.dart`                           | Freezed form-input value object                                    |
| `lib/data/models/pending_transaction.dart`                            | Freezed domain model                                               |
| `lib/data/repositories/recurring_rules_repository.dart`               | SSOT for `recurring_rules` + exception types                       |
| `lib/data/repositories/pending_transaction_repository.dart`           | Minimal SSOT for `pending_transactions` (insert + existence check) |
| `lib/data/use_cases/recurring_generation_use_case.dart`               | Scans rules, creates pending items, advances dates                 |
| `lib/features/recurring/recurring_rules_controller.dart`              | List state + pause/resume/delete commands                          |
| `lib/features/recurring/recurring_rules_state.dart`                   | Freezed state (loading/empty/data/error)                           |
| `lib/features/recurring/recurring_rule_form_controller.dart`          | Form state + save commands                                         |
| `lib/features/recurring/recurring_rule_form_state.dart`               | Freezed form state                                                 |
| `lib/features/recurring/recurring_rules_screen.dart`                  | Management list screen                                             |
| `lib/features/recurring/recurring_rule_form_screen.dart`              | Dedicated create/edit form                                         |
| `lib/features/recurring/recurring_rules_providers.dart`               | Slice-local helper providers                                       |
| `test/unit/repositories/recurring_rules_repository_test.dart`         | Repository unit tests                                              |
| `test/unit/repositories/pending_transaction_repository_test.dart`     | Pending txn repo tests                                             |
| `test/unit/use_cases/recurring_generation_use_case_test.dart`         | Use case unit tests                                                |
| `test/unit/controllers/recurring_rules_controller_test.dart`          | List controller tests                                              |
| `test/unit/controllers/recurring_rule_form_controller_test.dart`      | Form controller tests                                              |
| `test/widget/features/recurring/recurring_rules_screen_test.dart`     | Management screen widget tests                                     |
| `test/widget/features/recurring/recurring_rule_form_screen_test.dart` | Form screen widget tests                                           |
| `test/integration/recurring_transaction_test.dart`                    | End-to-end integration tests                                       |

**Modified files:**

| File                                          | Change                                                                                   |
|-----------------------------------------------|------------------------------------------------------------------------------------------|
| `lib/data/database/app_database.dart`         | Add 2 tables + 2 DAOs, bump schemaVersion to 4                                           |
| `lib/app/providers/repository_providers.dart` | Add `recurringRulesRepositoryProvider`, `pendingTransactionRepositoryProvider`           |
| `lib/app/bootstrap.dart`                      | Run `RecurringGenerationUseCase` during the bootstrap sequence (post-seed, pre-`runApp`) |
| `lib/app/router.dart`                         | Add `/settings/recurring`, `/settings/recurring/new`, `/settings/recurring/:id`          |
| `lib/features/settings/settings_screen.dart`  | Add "Recurring Transactions" tile                                                        |
| `test/unit/repositories/migration_test.dart`  | Extend for v3→v4 migration                                                               |
| `l10n/app_en.arb`                             | Add recurring-related strings                                                            |
| `l10n/app_zh_TW.arb`                          | Add recurring-related strings                                                            |
| `l10n/app_zh_CN.arb`                          | Add recurring-related strings                                                            |

---

## Chunk 1: Data Layer Foundation

### Task 1: Schema — `pending_transactions` Table

**Files:**
- Create: `lib/data/database/tables/pending_transactions_table.dart`
- Test: `test/unit/repositories/migration_test.dart` (extend later in Task 3)

- [x] **Step 1: Create the `PendingTransactions` Drift table definition**

```dart
// lib/data/database/tables/pending_transactions_table.dart
import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';
import 'recurring_rules_table.dart';

// The partial UNIQUE index `idx_pending_recurring_unique_partial` is added
// imperatively in the migration (and on fresh installs) — see Task 3 Step 4.
// Drift cannot express the partial WHERE clause declaratively, so we do
// not annotate it here to avoid a name collision with the customStatement
// version that would land a stricter (non-partial) constraint at fresh
// install time.
@DataClassName('PendingTransactionRow')
@TableIndex(name: 'idx_pending_source', columns: {#source})
@TableIndex(name: 'idx_pending_account', columns: {#accountId})
class PendingTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'blockchain' or 'recurring'.
  TextColumn get source => text()();

  IntColumn get amountMinorUnits => integer().named('amount_minor_units')();
  TextColumn get currency => text().references(Currencies, #code)();
  IntColumn get categoryId =>
      integer().named('category_id').nullable().references(Categories, #id)();
  IntColumn get accountId =>
      integer().named('account_id').references(Accounts, #id)();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get fetchedAt => dateTime().named('fetched_at')();

  // Blockchain-specific (nullable).
  TextColumn get tokenName => text().named('token_name').nullable()();
  TextColumn get tokenSymbol => text().named('token_symbol').nullable()();
  IntColumn get tokenDecimals => integer().named('token_decimals').nullable()();
  TextColumn get contractAddress =>
      text().named('contract_address').nullable()();
  TextColumn get fromAddress => text().named('from_address').nullable()();
  TextColumn get toAddress => text().named('to_address').nullable()();
  TextColumn get txHash => text().named('tx_hash').nullable().unique()();
  TextColumn get blockchain => text().nullable()();

  /// FK → `recurring_rules.id`. Null for blockchain items.
  IntColumn get recurringRuleId => integer()
      .named('recurring_rule_id')
      .nullable()
      .references(RecurringRules, #id)();
}
```

- [x] **Step 2: Verify the file compiles**

Run: `dart analyze lib/data/database/tables/pending_transactions_table.dart`
Expected: No errors (will warn about unused import of RecurringRules until Task 2)

- [x] **Step 3: Commit**

```bash
git add lib/data/database/tables/pending_transactions_table.dart
git commit -m "feat: add pending_transactions Drift table definition"
```

---

### Task 2: Schema — `recurring_rules` Table

**Files:**
- Create: `lib/data/database/tables/recurring_rules_table.dart`

- [x] **Step 1: Create the `RecurringRules` Drift table definition**

```dart
// lib/data/database/tables/recurring_rules_table.dart
import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';

@DataClassName('RecurringRuleRow')
@TableIndex(name: 'idx_recurring_active_due', columns: {#isActive, #nextDueDate})
@TableIndex(name: 'idx_recurring_archived', columns: {#isArchived})
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// User-friendly label ("Netflix", "Rent").
  TextColumn get name => text()();

  /// Fixed amount per occurrence, in minor units.
  IntColumn get amountMinorUnits => integer().named('amount_minor_units')();

  /// FK → `currencies.code`.
  TextColumn get currency => text().references(Currencies, #code)();

  /// FK → `categories.id`.
  IntColumn get categoryId =>
      integer().named('category_id').references(Categories, #id)();

  /// FK → `accounts.id`.
  IntColumn get accountId =>
      integer().named('account_id').references(Accounts, #id)();

  /// Optional memo pre-filled on each generated item.
  TextColumn get memo => text().nullable()();

  /// 'daily', 'weekly', 'monthly', 'yearly'.
  TextColumn get frequency => text()();

  /// 0=Sun..6=Sat. Required when frequency='weekly'.
  IntColumn get dayOfWeek => integer().named('day_of_week').nullable()();

  /// 1-31. Required when frequency='monthly' or 'yearly'.
  IntColumn get dayOfMonth => integer().named('day_of_month').nullable()();

  /// 1-12. Required when frequency='yearly'.
  IntColumn get monthOfYear => integer().named('month_of_year').nullable()();

  /// false = paused.
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();

  /// true = soft-deleted.
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();

  /// Denormalized for fast "which rules are due?" queries.
  DateTimeColumn get nextDueDate => dateTime().named('next_due_date')();

  /// Most recent generation failure for this rule, or null if the last
  /// generation pass succeeded. Surfaced as a warning badge on the rule
  /// tile and inside the form. Cleared on the next successful pass.
  TextColumn get lastError => text().named('last_error').nullable()();

  /// When [lastError] was recorded. Null when [lastError] is null.
  DateTimeColumn get lastErrorAt =>
      dateTime().named('last_error_at').nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
```

- [x] **Step 2: Verify the file compiles**

Run: `dart analyze lib/data/database/tables/recurring_rules_table.dart`
Expected: No errors

- [x] **Step 3: Commit**

```bash
git add lib/data/database/tables/recurring_rules_table.dart
git commit -m "feat: add recurring_rules Drift table definition"
```

---

### Task 3: Migration v4 — Register Tables, DAOs, Bump Schema

**Files:**
- Create: `lib/data/database/daos/recurring_rule_dao.dart`
- Create: `lib/data/database/daos/pending_transaction_dao.dart`
- Modify: `lib/data/database/app_database.dart`
- Modify: `test/unit/repositories/migration_test.dart`

- [x] **Step 1: Create `RecurringRuleDao`**

```dart
// lib/data/database/daos/recurring_rule_dao.dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurring_rules_table.dart';

part 'recurring_rule_dao.g.dart';

@DriftAccessor(tables: [RecurringRules])
class RecurringRuleDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRuleDaoMixin {
  RecurringRuleDao(super.db);

  /// All non-archived rules, sorted: active first by next_due_date ASC,
  /// then paused by name ASC.
  Stream<List<RecurringRuleRow>> watchActive() {
    return (select(recurringRules)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isActive, mode: OrderingMode.desc),
            (t) => OrderingTerm(
                  expression: t.nextDueDate,
                  mode: OrderingMode.asc,
                ),
            (t) =>
                OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Active, non-archived rules whose next_due_date <= [today].
  Future<List<RecurringRuleRow>> findDue(DateTime today) {
    return (select(recurringRules)
          ..where(
            (t) =>
                t.isActive.equals(true) &
                t.isArchived.equals(false) &
                t.nextDueDate.isSmallerOrEqualValue(today),
          ))
        .get();
  }

  /// One-shot read by id.
  Future<RecurringRuleRow?> findById(int id) {
    return (select(
      recurringRules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new row. Returns the new id.
  Future<int> insert(RecurringRulesCompanion row) {
    return into(recurringRules).insert(row);
  }

  /// Replace row by PK.
  Future<bool> updateRow(RecurringRulesCompanion row) {
    return update(recurringRules).replace(row);
  }

  /// Archive by id: sets is_archived=true, is_active=false.
  Future<void> archiveById(int id) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      const RecurringRulesCompanion(
        isArchived: Value(true),
        isActive: Value(false),
      ),
    );
  }

  /// Set active flag.
  Future<void> setActive(int id, {required bool active}) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(isActive: Value(active)),
    );
  }

  /// Advance next_due_date after generation.
  Future<void> updateNextDueDate(int id, DateTime newDate, DateTime updatedAt) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(
        nextDueDate: Value(newDate),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Record a generation failure on the rule. Used by the use case's
  /// per-rule catch handler. Repository delegates here — the `update(table)`
  /// builder is only available on `DatabaseAccessor` subclasses.
  Future<void> recordFailure(
    int id,
    String message,
    DateTime at,
    DateTime updatedAt,
  ) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(
        lastError: Value(message),
        lastErrorAt: Value(at),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Clear a previously-recorded failure. Used after a successful pass
  /// or when the rule's next_due_date is in the future (skipped branch).
  Future<void> clearFailure(int id, DateTime updatedAt) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(
        lastError: const Value(null),
        lastErrorAt: const Value(null),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Hard-delete by id.
  Future<int> deleteById(int id) {
    return (delete(recurringRules)..where((t) => t.id.equals(id))).go();
  }
}
```

- [x] **Step 2: Create `PendingTransactionDao`**

```dart
// lib/data/database/daos/pending_transaction_dao.dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/pending_transactions_table.dart';

part 'pending_transaction_dao.g.dart';

@DriftAccessor(tables: [PendingTransactions])
class PendingTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$PendingTransactionDaoMixin {
  PendingTransactionDao(super.db);

  /// Check if a pending row already exists for the given rule + date.
  /// Used by the generation engine's fast-path idempotency skip.
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date) async {
    final countExp = pendingTransactions.id.count();
    final row = await (selectOnly(pendingTransactions)
          ..addColumns([countExp])
          ..where(
            pendingTransactions.recurringRuleId.equals(ruleId) &
                pendingTransactions.date.equals(date) &
                pendingTransactions.source.equals('recurring'),
          ))
        .getSingle();
    return (row.read(countExp) ?? 0) > 0;
  }

  /// Insert a new pending row. Returns the new id.
  Future<int> insert(PendingTransactionsCompanion row) {
    return into(pendingTransactions).insert(row);
  }

  /// Count pending rows for a specific recurring rule.
  /// Used by the form screen's inline notice.
  Future<int> countByRecurringRule(int ruleId) async {
    final countExp = pendingTransactions.id.count();
    final row = await (selectOnly(pendingTransactions)
          ..addColumns([countExp])
          ..where(
            pendingTransactions.recurringRuleId.equals(ruleId) &
                pendingTransactions.source.equals('recurring'),
          ))
        .getSingle();
    return row.read(countExp) ?? 0;
  }
}
```

- [x] **Step 3: Run codegen for the new DAOs**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `recurring_rule_dao.g.dart` and `pending_transaction_dao.g.dart`

- [x] **Step 4: Update `AppDatabase` — register tables, DAOs, bump schema, add migration**

In `lib/data/database/app_database.dart`:
- Import the two new table files and two new DAO files
- Add `PendingTransactions` and `RecurringRules` to the `tables` list in `@DriftDatabase`
- Add `PendingTransactionDao` and `RecurringRuleDao` to the `daos` list
- Bump `schemaVersion` from `3` to `4`
- Extract the partial-index `customStatement` into a shared helper so it runs on **both** fresh installs (`onCreate`) and upgrades (`onUpgrade`):

```dart
Future<void> _addRecurringPartialUniqueIndex() {
  // Partial UNIQUE index for recurring-source idempotency.
  // Drift cannot express the partial WHERE clause declaratively, so we
  // add it imperatively. The `_partial` suffix avoids any future name
  // collision if Drift ever supports `@TableIndex(partial: ...)`.
  return customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_recurring_unique_partial '
    'ON pending_transactions(recurring_rule_id, date) '
    "WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL",
  );
}
```

- Update `onCreate` to call the helper after `m.createAll()`:

```dart
onCreate: (m) async {
  await m.createAll();
  await _addRecurringPartialUniqueIndex();
},
```

- Add migration logic in `onUpgrade` for `from < 4`:

```dart
if (from < 4) {
  // Create recurring_rules FIRST (pending_transactions FK references it).
  await m.createTable(recurringRules);
  await m.createIndex(recurringRulesActiveDueIdx);
  await m.createIndex(recurringRulesArchivedIdx);

  // Create pending_transactions.
  await m.createTable(pendingTransactions);
  await m.createIndex(pendingTransactionsSourceIdx);
  await m.createIndex(pendingTransactionsAccountIdx);

  // Apply the partial UNIQUE index — same helper as onCreate.
  await _addRecurringPartialUniqueIndex();
}
```

- [x] **Step 5: Update migration tests**

In `test/unit/repositories/migration_test.dart`:
- Update `expect(db.schemaVersion, 3)` → `expect(db.schemaVersion, 4)`
- Add v3→v4 upgrade test (seeded and empty)
- Add test that `PRAGMA foreign_keys = ON` still fires after v4 upgrade

```dart
test('current schemaVersion matches the latest committed snapshot', () {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async => db.close());
  expect(db.schemaVersion, 4);
  expect(GeneratedHelper.versions, contains(db.schemaVersion));
  expect(GeneratedHelper.versions.last, db.schemaVersion);
});

test('upgrades v3 DBs to v4 and preserves rows', () async {
  final verifier = SchemaVerifier(GeneratedHelper());
  final schema = await verifier.schemaAt(3);
  final legacyDb = v3.DatabaseAtV3(schema.newConnection());
  addTearDown(() async => legacyDb.close());

  // Seed some v3 data.
  await legacyDb.customStatement(
    "INSERT INTO currencies (code, decimals, symbol, name_l10n_key, is_token, sort_order) "
    "VALUES (?, ?, ?, ?, 0, ?)",
    <Object?>['USD', 2, r'$', 'currency.usd', 1],
  );
  await legacyDb.close();

  final db = AppDatabase(schema.newConnection());
  addTearDown(() async => db.close());

  await verifier.migrateAndValidate(db, db.schemaVersion);

  final rows = await db.select(db.currencies).get();
  expect(rows, hasLength(1));
  expect(rows.single.code, 'USD');
});
```

- [x] **Step 6: Regenerate Drift schema snapshot and harness**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/unit/repositories/_harness/generated/
```

Expected: `drift_schemas/drift_schema_v4.json` created, harness files updated.

- [x] **Step 7: Run migration tests to verify**

Run: `flutter test test/unit/repositories/migration_test.dart`
Expected: PASS

- [x] **Step 8: Commit**

```bash
git add lib/data/database/ lib/data/database/daos/ lib/data/database/tables/ \
  drift_schemas/ test/unit/repositories/_harness/ test/unit/repositories/migration_test.dart
git commit -m "feat: add v4 schema migration with pending_transactions and recurring_rules tables"
```

---

### Task 4: Domain Models — `RecurringRule`, `RecurringRuleDraft`, `PendingTransaction`

**Files:**
- Create: `lib/data/models/recurring_rule.dart`
- Create: `lib/data/models/recurring_rule_draft.dart`
- Create: `lib/data/models/pending_transaction.dart`

- [x] **Step 1: Create `RecurringRule` Freezed model**

```dart
// lib/data/models/recurring_rule.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'recurring_rule.freezed.dart';

@freezed
abstract class RecurringRule with _$RecurringRule {
  const factory RecurringRule({
    required int id,
    required String name,
    required int amountMinorUnits,
    required Currency currency,
    required int categoryId,
    required int accountId,
    String? memo,
    required String frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    required bool isActive,
    required bool isArchived,
    required DateTime nextDueDate,
    String? lastError,
    DateTime? lastErrorAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecurringRule;
}
```

- [x] **Step 2: Create `RecurringRuleDraft` Freezed model**

```dart
// lib/data/models/recurring_rule_draft.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'recurring_rule_draft.freezed.dart';

/// Form-input value object for creating/updating a recurring rule.
/// No id, no next_due_date, no is_active, no is_archived, no timestamps —
/// those are repository-managed.
@freezed
abstract class RecurringRuleDraft with _$RecurringRuleDraft {
  const factory RecurringRuleDraft({
    required String name,
    required int amountMinorUnits,
    required Currency currency,
    required int categoryId,
    required int accountId,
    String? memo,
    required String frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
  }) = _RecurringRuleDraft;
}
```

- [x] **Step 3: Create `PendingTransaction` Freezed model**

```dart
// lib/data/models/pending_transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'pending_transaction.freezed.dart';

@freezed
abstract class PendingTransaction with _$PendingTransaction {
  const factory PendingTransaction({
    required int id,
    required String source,
    required int amountMinorUnits,
    required Currency currency,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  }) = _PendingTransaction;
}
```

- [x] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `.freezed.dart` files for all three models.

- [x] **Step 5: Commit**

```bash
git add lib/data/models/recurring_rule.dart lib/data/models/recurring_rule_draft.dart \
  lib/data/models/pending_transaction.dart
git commit -m "feat: add RecurringRule, RecurringRuleDraft, PendingTransaction domain models"
```

---

### Task 5: `PendingTransactionRepository` (minimal)

**Files:**
- Create: `lib/data/repositories/pending_transaction_repository.dart`

- [x] **Step 1: Create the repository**

This is a minimal implementation — only the methods needed by the recurring generation use case. The full PendingTransactionRepository will be expanded by the Pending Transactions UI plan.

```dart
// lib/data/repositories/pending_transaction_repository.dart
import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/currency_dao.dart';
import '../database/daos/pending_transaction_dao.dart';
import '../models/currency.dart';
import '../models/pending_transaction.dart';

class PendingTransactionRepositoryException implements Exception {
  const PendingTransactionRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'PendingTransactionRepositoryException: $message';
}

/// Minimal SSOT for `pending_transactions`.
///
/// This repository provides only the methods needed by
/// [RecurringGenerationUseCase]. The full repository (with approve/reject,
/// stream watchers, etc.) will be expanded by the Pending Transactions UI
/// plan.
abstract class PendingTransactionRepository {
  /// Check if a pending row exists for the given rule + date.
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date);

  /// Insert a new pending row. Returns the new id.
  Future<int> insert({
    required String source,
    required int amountMinorUnits,
    required String currencyCode,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  });

  /// Count pending rows for a specific recurring rule.
  Future<int> countByRecurringRule(int ruleId);
}

final class DriftPendingTransactionRepository
    implements PendingTransactionRepository {
  DriftPendingTransactionRepository(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  final DateTime Function() _clock;

  PendingTransactionDao get _dao => _db.pendingTransactionDao;

  @override
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date) {
    return _dao.existsForRuleAndDate(ruleId, date);
  }

  @override
  Future<int> insert({
    required String source,
    required int amountMinorUnits,
    required String currencyCode,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  }) {
    return _dao.insert(
      drift.PendingTransactionsCompanion(
        source: Value(source),
        amountMinorUnits: Value(amountMinorUnits),
        currency: Value(currencyCode),
        categoryId: categoryId != null
            ? Value(categoryId)
            : const Value.absent(),
        accountId: Value(accountId),
        memo: memo != null ? Value(memo) : const Value.absent(),
        date: Value(date),
        fetchedAt: Value(fetchedAt),
        recurringRuleId: recurringRuleId != null
            ? Value(recurringRuleId)
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<int> countByRecurringRule(int ruleId) {
    return _dao.countByRecurringRule(ruleId);
  }
}
```

- [x] **Step 2: Verify compilation**

Run: `dart analyze lib/data/repositories/pending_transaction_repository.dart`
Expected: No errors

- [x] **Step 3: Commit**

```bash
git add lib/data/repositories/pending_transaction_repository.dart
git commit -m "feat: add minimal PendingTransactionRepository for recurring generation"
```

---

### Task 6: `RecurringRulesRepository`

**Files:**
- Create: `lib/data/repositories/recurring_rules_repository.dart`
- Create: `test/unit/repositories/recurring_rules_repository_test.dart`

- [x] **Step 1: Write repository tests — initial `next_due_date` calculation**

```dart
// test/unit/repositories/recurring_rules_repository_test.dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule_draft.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seedCurrencyUsd(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO currencies '
    '(code, decimals, symbol, name_l10n_key, is_token, sort_order) '
    'VALUES (?, ?, ?, ?, 0, ?)',
    <Object?>['USD', 2, r'$', 'currency.usd', 1],
  );
}

Future<int> _insertCategoryRaw(AppDatabase db, {String type = 'expense'}) async {
  await db.customStatement(
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, is_archived) '
    "VALUES ('cat.test', 'tag', 0, ?, 1, 0)",
    <Object?>[type],
  );
  final rows = await db
      .customSelect('SELECT id FROM categories ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

Future<int> _insertAccountRaw(AppDatabase db, {String currency = 'USD'}) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO account_types '
    "(l10n_key, icon, color, sort_order, is_archived) VALUES ('at.test', 'wallet', 0, 1, 0)",
  );
  final typeRows = await db
      .customSelect('SELECT id FROM account_types ORDER BY id ASC LIMIT 1')
      .get();
  final typeId = typeRows.first.read<int>('id');
  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, is_archived) '
    "VALUES ('Cash', ?, ?, 0, 0)",
    <Object?>[typeId, currency],
  );
  final rows = await db
      .customSelect('SELECT id FROM accounts ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

void main() {
  group('RecurringRulesRepository', () {
    late AppDatabase db;
    late DriftRecurringRulesRepository repo;
    late int categoryId;
    late int accountId;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedCurrencyUsd(db);
      categoryId = await _insertCategoryRaw(db);
      accountId = await _insertAccountRaw(db);
      repo = DriftRecurringRulesRepository(db);
    });

    tearDown(() async => db.close());

    RecurringRuleDraft _draft({
      String name = 'Netflix',
      int amount = 1599,
      String frequency = 'monthly',
      int? dayOfWeek,
      int? dayOfMonth,
      int? monthOfYear,
    }) =>
        RecurringRuleDraft(
          name: name,
          amountMinorUnits: amount,
          currency: _usd,
          categoryId: categoryId,
          accountId: accountId,
          frequency: frequency,
          dayOfWeek: dayOfWeek,
          dayOfMonth: dayOfMonth,
          monthOfYear: monthOfYear,
        );

    test('insert daily rule sets next_due_date to today', () async {
      final today = DateTime(2026, 5, 7);
      final id = await repo.insert(_draft(frequency: 'daily'), today: today);
      final rule = await repo.getById(id);
      expect(rule, isNotNull);
      expect(rule!.nextDueDate, DateTime(2026, 5, 7));
    });

    test('insert weekly rule finds next matching weekday', () async {
      // May 7, 2026 is Thursday (weekday=4). dayOfWeek=5 (Friday).
      final today = DateTime(2026, 5, 7);
      final id = await repo.insert(
        _draft(frequency: 'weekly', dayOfWeek: 5),
        today: today,
      );
      final rule = await repo.getById(id);
      expect(rule!.nextDueDate, DateTime(2026, 5, 8)); // Friday
    });

    test('insert weekly rule when today matches', () async {
      // May 7 is Thursday (4). dayOfWeek=4 → today is the due date.
      final today = DateTime(2026, 5, 7);
      final id = await repo.insert(
        _draft(frequency: 'weekly', dayOfWeek: 4),
        today: today,
      );
      final rule = await repo.getById(id);
      expect(rule!.nextDueDate, DateTime(2026, 5, 7));
    });

    test('insert monthly rule clamps day_of_month to shorter month', () async {
      // Feb 5 with day_of_month=31 → Feb 28.
      final today = DateTime(2026, 2, 5);
      final id = await repo.insert(
        _draft(frequency: 'monthly', dayOfMonth: 31),
        today: today,
      );
      final rule = await repo.getById(id);
      expect(rule!.nextDueDate, DateTime(2026, 2, 28));
    });

    test('insert monthly rule when day already passed this month', () async {
      // May 20 with day_of_month=15 → next month June 15.
      final today = DateTime(2026, 5, 20);
      final id = await repo.insert(
        _draft(frequency: 'monthly', dayOfMonth: 15),
        today: today,
      );
      final rule = await repo.getById(id);
      expect(rule!.nextDueDate, DateTime(2026, 6, 15));
    });

    test('insert yearly rule with leap year clamping', () async {
      // Create on Jan 1, 2026 with month=2, day=29.
      // 2026 is not a leap year, so day=29 clamps to Feb 28 2026, which is
      // after Jan 1 2026 — so next_due_date = Feb 28, 2026. (Subsequent
      // advances will hit Feb 28 2027, then Feb 29 2028 once leap-year
      // re-clamping kicks back in.)
      final today = DateTime(2026, 1, 1);
      final id = await repo.insert(
        _draft(frequency: 'yearly', monthOfYear: 2, dayOfMonth: 29),
        today: today,
      );
      final rule = await repo.getById(id);
      expect(rule!.nextDueDate, DateTime(2026, 2, 28));
    });
  });
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/repositories/recurring_rules_repository_test.dart`
Expected: FAIL — `DriftRecurringRulesRepository` doesn't exist yet.

- [x] **Step 3: Implement `RecurringRulesRepository`**

```dart
// lib/data/repositories/recurring_rules_repository.dart
import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/currency_dao.dart';
import '../database/daos/recurring_rule_dao.dart';
import '../models/currency.dart';
import '../models/recurring_rule.dart';
import '../models/recurring_rule_draft.dart';

class RecurringRulesRepositoryException implements Exception {
  const RecurringRulesRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'RecurringRulesRepositoryException: $message';
}

class ArchivedReferenceException extends RecurringRulesRepositoryException {
  const ArchivedReferenceException(super.message);
}

class FrequencyFieldsMissingException
    extends RecurringRulesRepositoryException {
  const FrequencyFieldsMissingException(super.message);
}

abstract class RecurringRulesRepository {
  Stream<List<RecurringRule>> watchActive();

  /// One-shot query: active, non-archived rules whose next_due_date <= [today].
  Future<List<RecurringRule>> findDue(DateTime today);

  Future<RecurringRule?> getById(int id);

  /// Insert a new rule. Computes initial next_due_date from frequency + today.
  Future<int> insert(RecurringRuleDraft draft, {DateTime? today});

  /// Edit a rule. Affects future generations only.
  Future<void> update(int id, RecurringRuleDraft draft);

  /// Pause or resume. Resume recomputes next_due_date from today.
  Future<void> setActive(int id, {required bool active, DateTime? today});

  /// Soft-delete.
  Future<void> archive(int id);

  /// Advance next_due_date after generation. Called by use case.
  Future<void> advanceAfterGeneration(int id, DateTime newNextDueDate);

  /// Record a non-recoverable failure for [id]. Surfaced as a badge on
  /// the management screen and inside the form's error banner.
  Future<void> recordFailure(int id, String message, DateTime at);

  /// Clear the recorded failure for [id]. Called after a successful pass.
  Future<void> clearFailure(int id);

  /// Advance a date by one frequency interval, anchored on the rule's
  /// day_of_month / day_of_week / month_of_year. Used by the use case
  /// for the generation loop. Centralized here to avoid duplication.
  DateTime advanceDateByFrequency(RecurringRule rule, DateTime current);

  /// Fast-forward to the most recent matching occurrence at or before [today].
  /// Throws [StateError] if [safetyCap] iterations are exceeded — guards
  /// against pathological inputs (clock-back, corrupt rule, monotonicity
  /// regression) that would otherwise loop indefinitely.
  DateTime fastForwardToRecent(
    RecurringRule rule,
    DateTime today, {
    int safetyCap = 10000,
  });
}

final class DriftRecurringRulesRepository implements RecurringRulesRepository {
  DriftRecurringRulesRepository(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  final DateTime Function() _clock;

  RecurringRuleDao get _dao => _db.recurringRuleDao;
  CurrencyDao get _currencyDao => _db.currencyDao;

  // ---------- Reads ----------

  @override
  Stream<List<RecurringRule>> watchActive() {
    return _dao
        .watchActive()
        .asyncMap((rows) async => _rowsToDomain(rows));
  }

  @override
  Future<RecurringRule?> getById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<RecurringRule>> findDue(DateTime today) async {
    final rows = await _dao.findDue(today);
    return _rowsToDomain(rows);
  }

  // ---------- Writes ----------

  @override
  Future<int> insert(RecurringRuleDraft draft, {DateTime? today}) async {
    _validateFrequencyFields(draft);
    await _validateActiveReferences(draft.categoryId, draft.accountId, draft.currency.code);

    final now = _clock();
    final effectiveToday = today ?? DateTime(now.year, now.month, now.day);
    final nextDue = _computeInitialNextDue(draft, effectiveToday);

    final id = await _dao.insert(
      drift.RecurringRulesCompanion(
        name: Value(draft.name),
        amountMinorUnits: Value(draft.amountMinorUnits),
        currency: Value(draft.currency.code),
        categoryId: Value(draft.categoryId),
        accountId: Value(draft.accountId),
        memo: draft.memo != null ? Value(draft.memo) : const Value.absent(),
        frequency: Value(draft.frequency),
        dayOfWeek: draft.dayOfWeek != null
            ? Value(draft.dayOfWeek)
            : const Value.absent(),
        dayOfMonth: draft.dayOfMonth != null
            ? Value(draft.dayOfMonth)
            : const Value.absent(),
        monthOfYear: draft.monthOfYear != null
            ? Value(draft.monthOfYear)
            : const Value.absent(),
        isActive: const Value(true),
        isArchived: const Value(false),
        nextDueDate: Value(nextDue),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  @override
  Future<void> update(int id, RecurringRuleDraft draft) async {
    _validateFrequencyFields(draft);
    await _validateActiveReferences(draft.categoryId, draft.accountId, draft.currency.code);

    final stored = await _dao.findById(id);
    if (stored == null) {
      throw RecurringRulesRepositoryException('Recurring rule $id not found');
    }

    final now = _clock();
    await _dao.updateRow(
      drift.RecurringRulesCompanion(
        id: Value(id),
        name: Value(draft.name),
        amountMinorUnits: Value(draft.amountMinorUnits),
        currency: Value(draft.currency.code),
        categoryId: Value(draft.categoryId),
        accountId: Value(draft.accountId),
        memo: draft.memo != null ? Value(draft.memo) : const Value.absent(),
        frequency: Value(draft.frequency),
        dayOfWeek: draft.dayOfWeek != null
            ? Value(draft.dayOfWeek)
            : const Value.absent(),
        dayOfMonth: draft.dayOfMonth != null
            ? Value(draft.dayOfMonth)
            : const Value.absent(),
        monthOfYear: draft.monthOfYear != null
            ? Value(draft.monthOfYear)
            : const Value.absent(),
        createdAt: Value(stored.createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> setActive(int id, {required bool active, DateTime? today}) async {
    final stored = await _dao.findById(id);
    if (stored == null) {
      throw RecurringRulesRepositoryException('Recurring rule $id not found');
    }

    if (!active) {
      // Pause: just flip the flag.
      await _dao.setActive(id, active: false);
    } else {
      // Resume: recalculate next_due_date from today, then update both fields.
      final now = _clock();
      final effectiveToday = today ?? DateTime(now.year, now.month, now.day);
      final draft = await _storedToDraft(stored);
      final nextDue = _computeInitialNextDue(draft, effectiveToday);

      await _dao.setActive(id, active: true);
      await _dao.updateNextDueDate(id, nextDue, now);
    }
  }

  @override
  Future<void> archive(int id) async {
    final stored = await _dao.findById(id);
    if (stored == null) {
      throw RecurringRulesRepositoryException('Recurring rule $id not found');
    }
    if (stored.isArchived) return; // Idempotent.
    await _dao.archiveById(id);
  }

  @override
  Future<void> advanceAfterGeneration(int id, DateTime newNextDueDate) async {
    final now = _clock();
    await _dao.updateNextDueDate(id, newNextDueDate, now);
  }

  @override
  DateTime advanceDateByFrequency(RecurringRule rule, DateTime current) {
    switch (rule.frequency) {
      case 'daily':
        return DateTime(current.year, current.month, current.day + 1);
      case 'weekly':
        return DateTime(current.year, current.month, current.day + 7);
      case 'monthly':
        final nextMonth = current.month == 12 ? 1 : current.month + 1;
        final nextYear =
            current.month == 12 ? current.year + 1 : current.year;
        final clamped = _clampDay(nextYear, nextMonth, rule.dayOfMonth!);
        return DateTime(nextYear, nextMonth, clamped);
      case 'yearly':
        final nextYear = current.year + 1;
        final clamped =
            _clampDay(nextYear, rule.monthOfYear!, rule.dayOfMonth!);
        return DateTime(nextYear, rule.monthOfYear!, clamped);
      default:
        throw RecurringRulesRepositoryException(
          'Unknown frequency: ${rule.frequency}',
        );
    }
  }

  @override
  DateTime fastForwardToRecent(
    RecurringRule rule,
    DateTime today, {
    int safetyCap = 10000,
  }) {
    var candidate = rule.nextDueDate;
    var next = advanceDateByFrequency(rule, candidate);
    final todayMidnight = DateTime(today.year, today.month, today.day);
    var iterations = 0;
    while (next.isBefore(todayMidnight) || next.isAtSameMomentAs(todayMidnight)) {
      if (++iterations > safetyCap) {
        throw StateError(
          'fastForwardToRecent exceeded safetyCap=$safetyCap for rule ${rule.id}',
        );
      }
      candidate = next;
      next = advanceDateByFrequency(rule, candidate);
    }
    return candidate;
  }

  @override
  Future<void> recordFailure(int id, String message, DateTime at) {
    return _dao.recordFailure(id, message, at, _clock());
  }

  @override
  Future<void> clearFailure(int id) {
    return _dao.clearFailure(id, _clock());
  }

  // ---------- Validation ----------

  void _validateFrequencyFields(RecurringRuleDraft draft) {
    switch (draft.frequency) {
      case 'weekly':
        if (draft.dayOfWeek == null) {
          throw const FrequencyFieldsMissingException(
            'day_of_week is required for weekly frequency',
          );
        }
      case 'monthly':
        if (draft.dayOfMonth == null) {
          throw const FrequencyFieldsMissingException(
            'day_of_month is required for monthly frequency',
          );
        }
      case 'yearly':
        if (draft.monthOfYear == null || draft.dayOfMonth == null) {
          throw const FrequencyFieldsMissingException(
            'month_of_year and day_of_month are required for yearly frequency',
          );
        }
      case 'daily':
        break;
      default:
        throw RecurringRulesRepositoryException(
          'Unknown frequency: ${draft.frequency}',
        );
    }
  }

  Future<void> _validateActiveReferences(
    int categoryId,
    int accountId,
    String currencyCode,
  ) async {
    final cat = await _db.categoryDao.findById(categoryId);
    if (cat == null || cat.isArchived) {
      throw ArchivedReferenceException(
        'Category $categoryId is archived or missing',
      );
    }
    final acc = await _db.accountDao.findById(accountId);
    if (acc == null || acc.isArchived) {
      throw ArchivedReferenceException(
        'Account $accountId is archived or missing',
      );
    }
    final cur = await _currencyDao.findByCode(currencyCode);
    if (cur == null) {
      throw ArchivedReferenceException(
        'Currency $currencyCode not found',
      );
    }
  }

  // ---------- Next-due-date computation ----------

  DateTime _computeInitialNextDue(RecurringRuleDraft draft, DateTime today) {
    switch (draft.frequency) {
      case 'daily':
        return today;
      case 'weekly':
        return _nextWeeklyDate(today, draft.dayOfWeek!);
      case 'monthly':
        return _nextMonthlyDate(today, draft.dayOfMonth!);
      case 'yearly':
        return _nextYearlyDate(today, draft.monthOfYear!, draft.dayOfMonth!);
      default:
        throw RecurringRulesRepositoryException(
          'Unknown frequency: ${draft.frequency}',
        );
    }
  }

  /// Find the next date on or after [from] whose weekday matches [dayOfWeek]
  /// (0=Sun..6=Sat).
  DateTime _nextWeeklyDate(DateTime from, int dayOfWeek) {
    // Dart weekday: 1=Mon..7=Sun. Spec: 0=Sun..6=Sat.
    final dartWeekday = dayOfWeek == 0 ? 7 : dayOfWeek;
    final diff = (dartWeekday - from.weekday + 7) % 7;
    return DateTime(from.year, from.month, from.day + diff);
  }

  /// Find the next date on or after [from] whose day matches [dayOfMonth],
  /// clamping to the last day of shorter months.
  ///
  /// Examples:
  /// - from = Feb 5 2026, dayOfMonth = 31 → Feb 28 2026 (clamped)
  /// - from = May 20 2026, dayOfMonth = 15 → Jun 15 2026 (already passed)
  /// - from = May 10 2026, dayOfMonth = 15 → May 15 2026
  DateTime _nextMonthlyDate(DateTime from, int dayOfMonth) {
    // Try this month first: clamp the requested day to this month's max.
    // If today is on or before the clamped day, this month is the answer.
    final clampedThisMonth = _clampDay(from.year, from.month, dayOfMonth);
    if (from.day <= clampedThisMonth.day) {
      return clampedThisMonth;
    }
    // Otherwise next month, clamping again for shorter months.
    final nextMonth = from.month == 12 ? 1 : from.month + 1;
    final nextYear = from.month == 12 ? from.year + 1 : from.year;
    return _clampDay(nextYear, nextMonth, dayOfMonth);
  }

  /// Find the next date on or after [from] whose (month, day) match,
  /// clamping for leap years.
  DateTime _nextYearlyDate(DateTime from, int month, int day) {
    final clampedThisYear = _clampDay(from.year, month, day);
    final candidate = DateTime(from.year, month, clampedThisYear.day);
    if (!candidate.isBefore(DateTime(from.year, from.month, from.day))) {
      return candidate;
    }
    // Try next year.
    final nextYear = from.year + 1;
    final clamped = _clampDay(nextYear, month, day);
    return DateTime(nextYear, month, clamped.day);
  }

  /// Clamp [day] to the last day of [year]-[month].
  DateTime _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final clamped = day > lastDay ? lastDay : day;
    return DateTime(year, month, clamped);
  }

  // ---------- Mapping ----------

  Future<List<RecurringRule>> _rowsToDomain(List<drift.RecurringRuleRow> rows) async {
    if (rows.isEmpty) return const <RecurringRule>[];
    final codes = rows.map((r) => r.currency).toSet();
    final currenciesByCode = <String, Currency>{};
    for (final code in codes) {
      final row = (await _currencyDao.findByCode(code))!;
      currenciesByCode[code] = _currencyFromRow(row);
    }
    return rows
        .map((row) => RecurringRule(
              id: row.id,
              name: row.name,
              amountMinorUnits: row.amountMinorUnits,
              currency: currenciesByCode[row.currency]!,
              categoryId: row.categoryId,
              accountId: row.accountId,
              memo: row.memo,
              frequency: row.frequency,
              dayOfWeek: row.dayOfWeek,
              dayOfMonth: row.dayOfMonth,
              monthOfYear: row.monthOfYear,
              isActive: row.isActive,
              isArchived: row.isArchived,
              nextDueDate: row.nextDueDate,
              lastError: row.lastError,
              lastErrorAt: row.lastErrorAt,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ))
        .toList(growable: false);
  }

  Future<RecurringRule> _toDomain(drift.RecurringRuleRow row) async {
    final currencyRow = (await _currencyDao.findByCode(row.currency))!;
    return RecurringRule(
      id: row.id,
      name: row.name,
      amountMinorUnits: row.amountMinorUnits,
      currency: _currencyFromRow(currencyRow),
      categoryId: row.categoryId,
      accountId: row.accountId,
      memo: row.memo,
      frequency: row.frequency,
      dayOfWeek: row.dayOfWeek,
      dayOfMonth: row.dayOfMonth,
      monthOfYear: row.monthOfYear,
      isActive: row.isActive,
      isArchived: row.isArchived,
      nextDueDate: row.nextDueDate,
      lastError: row.lastError,
      lastErrorAt: row.lastErrorAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<RecurringRuleDraft> _storedToDraft(drift.RecurringRuleRow row) async {
    // Always load the real currency. A `decimals: 0` stub would silently
    // corrupt downstream money formatting if the draft escapes this scope —
    // CLAUDE.md is explicit that decimals come from `currencies.decimals`.
    final currencyRow = (await _currencyDao.findByCode(row.currency))!;
    return RecurringRuleDraft(
      name: row.name,
      amountMinorUnits: row.amountMinorUnits,
      currency: _currencyFromRow(currencyRow),
      categoryId: row.categoryId,
      accountId: row.accountId,
      memo: row.memo,
      frequency: row.frequency,
      dayOfWeek: row.dayOfWeek,
      dayOfMonth: row.dayOfMonth,
      monthOfYear: row.monthOfYear,
    );
  }

  Currency _currencyFromRow(drift.Currency row) => Currency(
        code: row.code,
        decimals: row.decimals,
        symbol: row.symbol,
        nameL10nKey: row.nameL10nKey,
        customName: row.customName,
        isToken: row.isToken,
        sortOrder: row.sortOrder,
      );
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/repositories/recurring_rules_repository_test.dart`
Expected: PASS

- [x] **Step 5: Add more repository tests**

Extend the test file with:
- Pause/resume: `is_active` toggle, `next_due_date` recalculation on resume
- Archive sets `is_archived = true` and `is_active = false`
- `ArchivedReferenceException` on insert with archived category/account
- `FrequencyFieldsMissingException` when required fields are null
- Stream emissions: `watchActive` emits sorted list
- Day-of-month anchor: insert with `day_of_month=31` in March → Mar 31; advance to April → Apr 30; advance to May → May 31

- [x] **Step 6: Run all repository tests**

Run: `flutter test test/unit/repositories/recurring_rules_repository_test.dart`
Expected: PASS

- [x] **Step 7: Commit**

```bash
git add lib/data/repositories/recurring_rules_repository.dart \
  test/unit/repositories/recurring_rules_repository_test.dart
git commit -m "feat: add RecurringRulesRepository with next-due-date computation and tests"
```

---

### Task 7: `PendingTransactionRepository` Tests

**Files:**
- Create: `test/unit/repositories/pending_transaction_repository_test.dart`

- [x] **Step 1: Write tests for PendingTransactionRepository**

```dart
// test/unit/repositories/pending_transaction_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seedCurrencyUsd(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO currencies '
    '(code, decimals, symbol, name_l10n_key, is_token, sort_order) '
    'VALUES (?, ?, ?, ?, 0, ?)',
    <Object?>['USD', 2, r'$', 'currency.usd', 1],
  );
}

Future<int> _insertCategoryRaw(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, is_archived) '
    "VALUES ('cat.test', 'tag', 0, 'expense', 1, 0)",
  );
  final rows = await db
      .customSelect('SELECT id FROM categories ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

Future<int> _insertAccountRaw(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO account_types '
    "(l10n_key, icon, color, sort_order, is_archived) VALUES ('at.test', 'wallet', 0, 1, 0)",
  );
  final typeRows = await db
      .customSelect('SELECT id FROM account_types ORDER BY id ASC LIMIT 1')
      .get();
  final typeId = typeRows.first.read<int>('id');
  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, is_archived) '
    "VALUES ('Cash', ?, 'USD', 0, 0)",
    <Object?>[typeId],
  );
  final rows = await db
      .customSelect('SELECT id FROM accounts ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

void main() {
  group('PendingTransactionRepository', () {
    late AppDatabase db;
    late DriftPendingTransactionRepository repo;
    late int categoryId;
    late int accountId;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedCurrencyUsd(db);
      categoryId = await _insertCategoryRaw(db);
      accountId = await _insertAccountRaw(db);
      repo = DriftPendingTransactionRepository(db, clock: () => DateTime(2026, 5, 7));
    });

    tearDown(() async => db.close());

    test('insert and check existence', () async {
      expect(await repo.existsForRuleAndDate(1, DateTime(2026, 5, 7)), false);

      await repo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: 'USD',
        categoryId: categoryId,
        accountId: accountId,
        date: DateTime(2026, 5, 7),
        fetchedAt: DateTime(2026, 5, 7),
        recurringRuleId: 1,
      );

      expect(await repo.existsForRuleAndDate(1, DateTime(2026, 5, 7)), true);
      expect(await repo.existsForRuleAndDate(1, DateTime(2026, 5, 8)), false);
      expect(await repo.existsForRuleAndDate(2, DateTime(2026, 5, 7)), false);
    });

    test('countByRecurringRule', () async {
      expect(await repo.countByRecurringRule(1), 0);

      await repo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: 'USD',
        categoryId: categoryId,
        accountId: accountId,
        date: DateTime(2026, 5, 7),
        fetchedAt: DateTime(2026, 5, 7),
        recurringRuleId: 1,
      );
      await repo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: 'USD',
        categoryId: categoryId,
        accountId: accountId,
        date: DateTime(2026, 6, 7),
        fetchedAt: DateTime(2026, 6, 7),
        recurringRuleId: 1,
      );

      expect(await repo.countByRecurringRule(1), 2);
      expect(await repo.countByRecurringRule(2), 0);
    });
  });
}
```

- [x] **Step 2: Run tests**

Run: `flutter test test/unit/repositories/pending_transaction_repository_test.dart`
Expected: PASS

- [x] **Step 3: Register providers in `repository_providers.dart`**

Add to `lib/app/providers/repository_providers.dart`:

```dart
import '../../data/repositories/pending_transaction_repository.dart';
import '../../data/repositories/recurring_rules_repository.dart';

@Riverpod(keepAlive: true, dependencies: [appDatabase])
PendingTransactionRepository pendingTransactionRepository(Ref ref) =>
    DriftPendingTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true, dependencies: [appDatabase])
RecurringRulesRepository recurringRulesRepository(Ref ref) =>
    DriftRecurringRulesRepository(ref.watch(appDatabaseProvider));

/// Use-case provider. Lives in `app/providers/` so that controllers in
/// `lib/features/.../*_controller.dart` can `ref.read` the use case
/// without importing `data/database/...` (forbidden by
/// `controllers_forbid_db_and_services` in import_analysis_options.yaml).
@Riverpod(
  keepAlive: true,
  dependencies: [appDatabase, recurringRulesRepository, pendingTransactionRepository],
)
RecurringGenerationUseCase recurringGenerationUseCase(Ref ref) {
  return RecurringGenerationUseCase(
    recurringRepo: ref.watch(recurringRulesRepositoryProvider),
    pendingRepo: ref.watch(pendingTransactionRepositoryProvider),
    db: ref.watch(appDatabaseProvider),
  );
}
```

- [x] **Step 4: Run codegen and verify**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/app/providers/repository_providers.dart
```
Expected: No errors

- [x] **Step 5: Commit**

```bash
git add lib/app/providers/repository_providers.dart \
  test/unit/repositories/pending_transaction_repository_test.dart
git commit -m "feat: add PendingTransactionRepository tests and wire providers"
```

---

## Chunk 2: Domain Layer + Generation Use Case

### Task 8: `RecurringGenerationUseCase`

**Files:**
- Create: `lib/data/use_cases/recurring_generation_use_case.dart`
- Create: `test/unit/use_cases/recurring_generation_use_case_test.dart`

- [x] **Step 1: Write use case tests — happy path**

The use case calls `db.transaction(() async { ... })`, which a Mocktail mock cannot honor without elaborate stubs. Use a real in-memory `AppDatabase` (the same `newTestAppDatabase()` harness as the repository tests) and mock only the two repositories.

```dart
// test/unit/use_cases/recurring_generation_use_case_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/data/use_cases/recurring_generation_use_case.dart';

import '../repositories/_harness/test_app_database.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

class _MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

RecurringRule _rule({
  required int id,
  required DateTime nextDueDate,
  String name = 'Netflix',
  int amount = 1599,
  String frequency = 'monthly',
  int? dayOfMonth = 15,
}) =>
    RecurringRule(
      id: id,
      name: name,
      amountMinorUnits: amount,
      currency: const Currency(code: 'USD', decimals: 2),
      categoryId: 1,
      accountId: 1,
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      isActive: true,
      isArchived: false,
      nextDueDate: nextDueDate,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('RecurringGenerationUseCase', () {
    late AppDatabase db;
    late _MockRecurringRulesRepository recurringRepo;
    late _MockPendingTransactionRepository pendingRepo;

    setUp(() {
      db = newTestAppDatabase();
      recurringRepo = _MockRecurringRulesRepository();
      pendingRepo = _MockPendingTransactionRepository();
      registerFallbackValue(DateTime(2026, 1, 1));
    });

    tearDown(() async => db.close());

    test('happy path: due rule generates pending row and advances date',
        () async {
      final today = DateTime(2026, 5, 7);
      final rule = _rule(id: 1, nextDueDate: DateTime(2026, 5, 7));

      when(() => recurringRepo.findDue(any()))
          .thenAnswer((_) async => [rule]);
      when(() => recurringRepo.advanceDateByFrequency(any(), any()))
          .thenAnswer((invocation) {
        final rule = invocation.positionalArguments[0] as RecurringRule;
        final current = invocation.positionalArguments[1] as DateTime;
        // Simple monthly advance for test purposes.
        return DateTime(current.year, current.month + 1, rule.dayOfMonth ?? current.day);
      });
      when(() => recurringRepo.fastForwardToRecent(any(), any()))
          .thenAnswer((invocation) {
        final today = invocation.positionalArguments[1] as DateTime;
        return today;
      });
      when(() => pendingRepo.existsForRuleAndDate(any(), any()))
          .thenAnswer((_) async => false);
      when(() => pendingRepo.insert(
            source: any(named: 'source'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            currencyCode: any(named: 'currencyCode'),
            categoryId: any(named: 'categoryId'),
            accountId: any(named: 'accountId'),
            memo: any(named: 'memo'),
            date: any(named: 'date'),
            fetchedAt: any(named: 'fetchedAt'),
            recurringRuleId: any(named: 'recurringRuleId'),
          )).thenAnswer((_) async => 1);
      when(() => recurringRepo.advanceAfterGeneration(any(), any()))
          .thenAnswer((_) async {});

      final useCase = RecurringGenerationUseCase(
        recurringRepo: recurringRepo,
        pendingRepo: pendingRepo,
        db: db,
      );
      await useCase.execute(clock: () => today);

      verify(() => pendingRepo.insert(
            source: 'recurring',
            amountMinorUnits: 1599,
            currencyCode: 'USD',
            categoryId: 1,
            accountId: 1,
            date: DateTime(2026, 5, 7),
            recurringRuleId: 1,
            fetchedAt: any(named: 'fetchedAt'),
          )).called(1);
      verify(() => recurringRepo.advanceAfterGeneration(
            1,
            DateTime(2026, 6, 15),
          )).called(1);
    });
  });
}
```

- [x] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/use_cases/recurring_generation_use_case_test.dart`
Expected: FAIL — `RecurringGenerationUseCase` doesn't exist yet.

- [x] **Step 3: Implement `RecurringGenerationUseCase`**

The use case is constructed manually in `bootstrap.dart` and in the form controller (after a `save`). It deliberately does **not** use `@Riverpod` — that would require importing `app/providers/repository_providers.dart` from a `data/` file, inverting the layer boundary. Manual construction is the same pattern bootstrap already uses for `DriftCurrencyRepository` etc.

```dart
// lib/data/use_cases/recurring_generation_use_case.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/recurring_rule.dart';
import '../repositories/pending_transaction_repository.dart';
import '../repositories/recurring_rules_repository.dart';

class RecurringGenerationFailure implements Exception {
  const RecurringGenerationFailure(this.ruleId, this.cause);
  final int ruleId;
  final Object cause;
  @override
  String toString() => 'RecurringGenerationFailure(rule=$ruleId): $cause';
}

class RecurringGenerationUseCase {
  RecurringGenerationUseCase({
    required this.recurringRepo,
    required this.pendingRepo,
    required this.db,
  });

  final RecurringRulesRepository recurringRepo;
  final PendingTransactionRepository pendingRepo;
  final AppDatabase db;

  static const _catchUpCap = 12;
  static const _fastForwardSafetyCap = 10000; // Pathological-input guard.

  /// Run for every active, due rule. Used by bootstrap on cold start.
  /// Returns per-rule outcomes so callers can surface cap-hit / failure
  /// state without parsing logs.
  Future<RecurringGenerationResult> execute({
    DateTime Function()? clock,
  }) async {
    final now = clock?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueRules = await recurringRepo.findDue(today);
    if (dueRules.isEmpty) return const RecurringGenerationResult(outcomes: []);

    // Single outer transaction wraps every rule. Drift's nested `transaction`
    // calls translate to SAVEPOINTs, so per-rule failure isolation is
    // preserved while N rules amortize to **one** fsync instead of N.
    return db.transaction<RecurringGenerationResult>(() async {
      final outcomes = <RecurringGenerationOutcome>[];
      for (final rule in dueRules) {
        outcomes.add(await _processRuleSafely(rule, today, clock));
      }
      return RecurringGenerationResult(outcomes: outcomes);
    });
  }

  /// Run for a single rule. Used by `RecurringRuleFormController.save()`
  /// after a successful insert/update so the user sees today's pending row
  /// without waiting for the next cold start.
  Future<RecurringGenerationOutcome> executeForRule(
    int ruleId, {
    DateTime Function()? clock,
  }) async {
    final now = clock?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rule = await recurringRepo.getById(ruleId);
    if (rule == null || !rule.isActive || rule.isArchived) {
      return RecurringGenerationOutcome.skipped(ruleId);
    }
    if (rule.nextDueDate.isAfter(today)) {
      // Skipped (future-dated): clear any prior error so the badge doesn't
      // persist after the user fixed the rule. The error column is meaningful
      // only when generation actually attempted and failed.
      await recurringRepo.clearFailure(ruleId);
      return RecurringGenerationOutcome.skipped(ruleId);
    }
    return db.transaction(() => _processRuleSafely(rule, today, clock));
  }

  Future<RecurringGenerationOutcome> _processRuleSafely(
    RecurringRule rule,
    DateTime today,
    DateTime Function()? clock,
  ) async {
    try {
      // Drift translates nested `transaction` to SAVEPOINT — per-rule
      // failures roll back this rule only, leaving sibling outcomes intact.
      return await db.transaction(() => _processRule(rule, today, clock));
    } on Object catch (cause) {
      // Persist the error so the management screen and form can surface it.
      // The error message is the exception's `toString()`; CLAUDE.md
      // forbids logging financial data, so callers must not put memos
      // or amounts into exception messages.
      //
      // Defensive nested try/catch: if the failure-recording write itself
      // fails (DB locked, disk full, FK regression), DO NOT let that escape
      // and roll back the OUTER bootstrap transaction — that would defeat
      // the per-rule SAVEPOINT isolation we just established. Sibling rules'
      // successful pending rows must survive even when error persistence
      // is itself broken.
      try {
        await recurringRepo.recordFailure(
          rule.id,
          cause.toString(),
          DateTime.now(),
        );
      } on Object {
        // Swallow — failure-of-failure-recording is observable only via
        // the returned `failed` outcome and the next cold start retry.
      }
      return RecurringGenerationOutcome.failed(rule.id);
    }
  }

  Future<RecurringGenerationOutcome> _processRule(
    RecurringRule rule,
    DateTime today,
    DateTime Function()? clock,
  ) async {
    var currentDue = rule.nextDueDate;
    var generated = 0;
    var capped = false;

    while (!_isAfter(currentDue, today) && generated < _catchUpCap) {
      // Fast-path idempotency skip; partial UNIQUE index is the backstop.
      final exists = await pendingRepo.existsForRuleAndDate(
        rule.id,
        currentDue,
      );
      if (!exists) {
        final now = clock?.call() ?? DateTime.now();
        await pendingRepo.insert(
          source: 'recurring',
          amountMinorUnits: rule.amountMinorUnits,
          currencyCode: rule.currency.code,
          categoryId: rule.categoryId,
          accountId: rule.accountId,
          memo: rule.memo,
          date: currentDue,
          fetchedAt: now,
          recurringRuleId: rule.id,
        );
      }
      currentDue = recurringRepo.advanceDateByFrequency(rule, currentDue);
      generated++;
    }

    if (generated == _catchUpCap && !_isAfter(currentDue, today)) {
      currentDue = recurringRepo.fastForwardToRecent(
        rule,
        today,
        safetyCap: _fastForwardSafetyCap,
      );
      capped = true;
    }

    await recurringRepo.advanceAfterGeneration(rule.id, currentDue);
    // Clear any prior error now that this rule succeeded.
    await recurringRepo.clearFailure(rule.id);

    return RecurringGenerationOutcome(
      ruleId: rule.id,
      generated: generated,
      capped: capped,
    );
  }

  bool _isAfter(DateTime a, DateTime b) {
    return a.isAfter(DateTime(b.year, b.month, b.day));
  }
}

/// Outcome of generating for a single rule.
class RecurringGenerationOutcome {
  const RecurringGenerationOutcome({
    required this.ruleId,
    required this.generated,
    required this.capped,
    this.failed = false,
    this.skipped = false,
  });

  factory RecurringGenerationOutcome.failed(int ruleId) =>
      RecurringGenerationOutcome(
        ruleId: ruleId,
        generated: 0,
        capped: false,
        failed: true,
      );

  factory RecurringGenerationOutcome.skipped(int ruleId) =>
      RecurringGenerationOutcome(
        ruleId: ruleId,
        generated: 0,
        capped: false,
        skipped: true,
      );

  final int ruleId;
  final int generated;
  final bool capped;
  final bool failed;
  final bool skipped;
}

/// Aggregate result of a generation pass (bootstrap or runtime).
class RecurringGenerationResult {
  const RecurringGenerationResult({required this.outcomes});
  final List<RecurringGenerationOutcome> outcomes;

  bool get anyCapped => outcomes.any((o) => o.capped);
  bool get anyFailed => outcomes.any((o) => o.failed);
  Iterable<int> get cappedRuleIds =>
      outcomes.where((o) => o.capped).map((o) => o.ruleId);
  Iterable<int> get failedRuleIds =>
      outcomes.where((o) => o.failed).map((o) => o.ruleId);
}

/// Bootstrap stores its single result here for Home (Wave 3) to read.
/// Default body throws — every test/runtime must override the value via
/// `ProviderScope` so missing-override bugs fail loudly instead of silently
/// returning `null`. `dependencies: const []` matches the project's lint
/// config; see `lib/app/providers/app_database_provider.dart`.
final lastGenerationResultProvider = Provider<RecurringGenerationResult>(
  (ref) => throw UnimplementedError(
    'lastGenerationResultProvider must be overridden by bootstrap() or a test harness',
  ),
  dependencies: const [],
);
```

- [x] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `recurring_generation_use_case.g.dart`

- [x] **Step 6: Run use case tests**

Run: `flutter test test/unit/use_cases/recurring_generation_use_case_test.dart`
Expected: PASS

- [x] **Step 7: Add more use case tests**

Extend the test file with:
- Idempotency: same rule, same date, run twice → only one pending row
- Catch-up cap: daily rule 30 days stale → exactly 12 pending rows
- Cap-hit signaling: outcome reports `capped: true` for capped rule
- Paused rules skipped
- Archived rules skipped
- Multiple rules: exception in rule A does not abort rule B (rule A's outcome is `failed`, rule B's outcome is normal)

- [x] **Step 8: Run all use case tests**

Run: `flutter test test/unit/use_cases/recurring_generation_use_case_test.dart`
Expected: PASS

- [x] **Step 9: Commit**

```bash
git add lib/data/use_cases/ lib/data/repositories/recurring_rules_repository.dart \
  test/unit/use_cases/
git commit -m "feat: add RecurringGenerationUseCase with catch-up cap and idempotency"
```

---

### Task 9: Bootstrap Wiring — Run Generation in `bootstrap.dart`

**Files:**
- Modify: `lib/app/bootstrap.dart`
- (No change to `lib/app/app.dart` for this feature.)

> Note: `migration_test.dart` was already updated to expect `schemaVersion = 4` in Task 3 Step 5. No additional change is required here.

The bootstrap sequence (per `PRD.md` → *Bootstrap Sequence*) is the documented place for ordered async init: open DB → init locale → read prefs → seed-if-empty → build `ProviderScope` with overrides. We add recurring generation as a post-seed step so generated rows are present in the DB when the first widget builds — Home (Wave 3) will render them inline alongside approved transactions on first paint.

- [x] **Step 1: Add a post-seed generation step to `bootstrap()`**

Construct the use case manually — same pattern bootstrap already uses for the seed-time repositories. **No transient `ProviderContainer`**: that pattern risked closing the open `AppDatabase` if `appDatabaseProvider`'s body registered an `onDispose` callback, and added a layer of indirection for what is a three-argument constructor call.

```dart
// lib/app/bootstrap.dart — new step inserted after seed-if-empty.
import '../data/repositories/pending_transaction_repository.dart';
import '../data/repositories/recurring_rules_repository.dart';
import '../data/use_cases/recurring_generation_use_case.dart';

Future<RecurringGenerationResult> _runRecurringGeneration(
  AppDatabase db,
  CurrencyRepository currencyRepo,
) async {
  final pendingRepo = DriftPendingTransactionRepository(db);
  final recurringRepo = DriftRecurringRulesRepository(db);
  final useCase = RecurringGenerationUseCase(
    recurringRepo: recurringRepo,
    pendingRepo: pendingRepo,
    db: db,
  );
  return useCase.execute();
}

// In bootstrap(), inserted after seed-if-empty:
//   final generationResult = await _runRecurringGeneration(db, currenciesRepo);
//
// Then in the runApp call, override lastGenerationResultProvider:
//   runApp(ProviderScope(
//     overrides: [
//       appDatabaseProvider.overrideWithValue(db),
//       lastGenerationResultProvider.overrideWithValue(generationResult),
//     ],
//     child: const App(),
//   ));
```

The provider is `Provider<RecurringGenerationResult>` with a body that throws `UnimplementedError` — every `runApp` and every test must override it. This makes a missing override fail loudly at first read instead of silently returning `null` and producing a never-shown banner.

**Latency budget:** generation runs inside a single outer `db.transaction`, so the entire pass amortizes to one fsync regardless of rule count. For a baseline Pixel 4a, 50 active rules at the 12-period cap should complete in well under 200ms. If the bootstrap-time integration test exceeds 500ms on the test bench, treat as a regression.

- [x] **Step 2: Verify compilation**

Run: `dart analyze lib/app/bootstrap.dart`
Expected: No errors.

- [x] **Step 3: Add a bootstrap integration test**

Test that after `bootstrap()` returns, due rules have produced pending rows and `next_due_date` has advanced. Use the same pattern as `test/integration/bootstrap_to_home_test.dart`.

- [x] **Step 4: Commit**

```bash
git add lib/app/bootstrap.dart test/integration/
git commit -m "feat: run recurring generation during bootstrap sequence"
```

---

## Chunk 3: UI — Controllers, Screens, Routing, l10n

### Task 10: l10n Strings

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`

- [x] **Step 1: Add recurring-related strings to `app_en.arb`**

Add the following entries at the end of `l10n/app_en.arb` (before the closing `}`):

```json
  "settingsRecurringTile": "Recurring transactions",
  "@settingsRecurringTile": { "description": "Settings entry-point label." },

  "recurringRulesTitle": "Recurring transactions",
  "@recurringRulesTitle": { "description": "Management screen app-bar title." },

  "recurringEmptyHeading": "No recurring rules yet",
  "@recurringEmptyHeading": { "description": "Empty state heading." },

  "recurringEmptyBody": "Set up a rule for rent, subscriptions, or any expense that repeats. Ledgerly will create a pending transaction for you on the due date.",
  "@recurringEmptyBody": { "description": "Empty state body." },

  "recurringEmptyCta": "Create rule",
  "@recurringEmptyCta": { "description": "Empty state CTA button." },

  "recurringFabNew": "New rule",
  "@recurringFabNew": { "description": "FAB label." },

  "recurringRulesLoadError": "Couldn't load your rules.",
  "@recurringRulesLoadError": { "description": "Error state text." },

  "recurringRulesLoadRetry": "Retry",
  "@recurringRulesLoadRetry": { "description": "Error state retry button." },

  "recurringTileNextDue": "Next: {date}",
  "@recurringTileNextDue": {
    "description": "Next-due text on management tile.",
    "placeholders": { "date": { "type": "String" } }
  },

  "recurringTilePaused": "Paused",
  "@recurringTilePaused": { "description": "Paused chip + semantics label." },

  "recurringFreqDailyLabel": "Daily",
  "@recurringFreqDailyLabel": { "description": "Frequency label." },

  "recurringFreqWeeklyLabel": "Every {weekday}",
  "@recurringFreqWeeklyLabel": {
    "description": "Weekly frequency label.",
    "placeholders": { "weekday": { "type": "String" } }
  },

  "recurringFreqMonthlyLabel": "Monthly on the {ordinal}",
  "@recurringFreqMonthlyLabel": {
    "description": "Monthly frequency label.",
    "placeholders": { "ordinal": { "type": "String" } }
  },

  "recurringFreqYearlyLabel": "Yearly on {month} {ordinal}",
  "@recurringFreqYearlyLabel": {
    "description": "Yearly frequency label.",
    "placeholders": { "month": { "type": "String" }, "ordinal": { "type": "String" } }
  },

  "recurringSwipePause": "Pause",
  "@recurringSwipePause": { "description": "Swipe action label." },

  "recurringSwipeResume": "Resume",
  "@recurringSwipeResume": { "description": "Swipe action label." },

  "recurringSwipeDelete": "Delete",
  "@recurringSwipeDelete": { "description": "Swipe action label." },

  "recurringPausedSnack": "Paused — {ruleName}",
  "@recurringPausedSnack": {
    "description": "Snackbar after pause.",
    "placeholders": { "ruleName": { "type": "String" } }
  },

  "recurringResumedSnack": "Resumed — {ruleName}, next due {date}. Missed periods are not generated on resume.",
  "@recurringResumedSnack": {
    "description": "Snackbar after resume. Discloses that periods missed while paused are not back-generated.",
    "placeholders": { "ruleName": { "type": "String" }, "date": { "type": "String" } }
  },


  "recurringDeletedSnack": "Rule deleted",
  "@recurringDeletedSnack": { "description": "Snackbar after delete." },

  "recurringFormCreateTitle": "New rule",
  "@recurringFormCreateTitle": { "description": "Create form app-bar title." },

  "recurringFormEditTitle": "Edit rule",
  "@recurringFormEditTitle": { "description": "Edit form app-bar title." },

  "recurringFormNamePlaceholder": "Rule name",
  "@recurringFormNamePlaceholder": { "description": "Name field placeholder." },

  "recurringFrequencyDaily": "Daily",
  "@recurringFrequencyDaily": { "description": "Frequency dropdown item." },

  "recurringFrequencyWeekly": "Weekly",
  "@recurringFrequencyWeekly": { "description": "Frequency dropdown item." },

  "recurringFrequencyMonthly": "Monthly",
  "@recurringFrequencyMonthly": { "description": "Frequency dropdown item." },

  "recurringFrequencyYearly": "Yearly",
  "@recurringFrequencyYearly": { "description": "Frequency dropdown item." },

  "recurringDailyHelper": "Generates one pending transaction every day from today.",
  "@recurringDailyHelper": { "description": "Daily frequency helper text." },

  "recurringDayOfMonthHint": "If the month is shorter, the rule uses the last day of that month.",
  "@recurringDayOfMonthHint": { "description": "Always-visible day-of-month hint." },

  "recurringFieldRequired": "Required",
  "@recurringFieldRequired": { "description": "Generic field validation copy." },

  "recurringSaveCreate": "Create",
  "@recurringSaveCreate": { "description": "Save action label (create mode)." },

  "recurringSaveUpdate": "Save",
  "@recurringSaveUpdate": { "description": "Save action label (edit mode)." },

  "recurringSavedCreate": "Rule created",
  "@recurringSavedCreate": { "description": "Snackbar after create." },

  "recurringSavedUpdate": "Rule updated",
  "@recurringSavedUpdate": { "description": "Snackbar after update." },

  "recurringDeleteRule": "Delete rule",
  "@recurringDeleteRule": { "description": "Destructive button label." },

  "recurringDeleteConfirm": "Delete this rule? Pending items already generated will remain in Pending Transactions.",
  "@recurringDeleteConfirm": { "description": "Delete confirmation dialog body." },

  "recurringEditWillNotAffectPending": "You have {count} pending item(s) from this rule. Edits below won't change them — approve or skip them on Home.",
  "@recurringEditWillNotAffectPending": {
    "description": "Edit form inline notice. Points to Home (Wave 3) where pending items surface inline.",
    "placeholders": { "count": { "type": "int", "format": "compact" } }
  },

  "recurringRuleHasError": "This rule had a problem on the last sync.",
  "@recurringRuleHasError": { "description": "Badge subtitle on a rule tile when its last_error is non-null. Tap opens the form which shows the error." },

  "recurringSavedButGenerationFailed": "Saved — but the first run hit an issue. We'll retry on the next launch.",
  "@recurringSavedButGenerationFailed": { "description": "Snackbar shown after a rule is saved but its inline post-save generation returned `failed`. Non-blocking; the rule persisted." }
```

- [x] **Step 2: Add corresponding strings to `app_zh_TW.arb` and `app_zh_CN.arb`**

Add Traditional Chinese and Simplified Chinese translations. For now, use English as placeholders (translators will fill in later).

- [x] **Step 3: Regenerate l10n code**

Run: `flutter gen-l10n` (or `flutter pub run build_runner build` if l10n is integrated)
Expected: `AppLocalizations` class includes all new getters.

- [x] **Step 4: Commit**

```bash
git add l10n/
git commit -m "feat: add l10n strings for recurring transactions feature"
```

---

### Task 11: Recurring Rules State + Controller

**Files:**
- Create: `lib/features/recurring/recurring_rules_state.dart`
- Create: `lib/features/recurring/recurring_rules_controller.dart`
- Create: `test/unit/controllers/recurring_rules_controller_test.dart`

- [x] **Step 1: Create `RecurringRulesState` Freezed model**

```dart
// lib/features/recurring/recurring_rules_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/recurring_rule.dart';

part 'recurring_rules_state.freezed.dart';

class RecurringRulesPendingDelete {
  const RecurringRulesPendingDelete({required this.ruleId});
  final int ruleId;
}

@freezed
sealed class RecurringRulesState with _$RecurringRulesState {
  const factory RecurringRulesState.loading() = RecurringRulesLoading;
  const factory RecurringRulesState.empty() = RecurringRulesEmpty;
  const factory RecurringRulesState.data({
    required List<RecurringRule> rules,
    required RecurringRulesPendingDelete? pendingDelete,
  }) = RecurringRulesData;
  const factory RecurringRulesState.error(Object error, StackTrace stack) =
      RecurringRulesError;
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 3: Write controller tests**

Create `test/unit/controllers/recurring_rules_controller_test.dart` with tests for:
- Loading → data when stream emits rules
- Loading → empty when stream emits empty list
- Stream error becomes RecurringRulesError
- `pauseRule` calls `setActive(id, active: false)`
- `resumeRule` calls `setActive(id, active: true)`
- `deleteRule` hides row immediately, starts undo window
- `undoDelete` cancels timer, repo.archive never called
- Timer expiry calls repo.archive
- Failed delete fires effect and restores hidden row

Follow the pattern from `test/unit/controllers/shopping_list_controller_test.dart`.

- [x] **Step 4: Implement `RecurringRulesController`**

```dart
// lib/features/recurring/recurring_rules_controller.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import 'recurring_rules_state.dart';

part 'recurring_rules_controller.g.dart';

typedef RecurringRulesEffectListener = void Function(
    RecurringRulesEffect effect);

sealed class RecurringRulesEffect {
  const RecurringRulesEffect();
}

final class RecurringRulesDeleteFailedEffect extends RecurringRulesEffect {
  const RecurringRulesDeleteFailedEffect(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

@Riverpod(dependencies: [recurringRulesRepository])
class RecurringRulesController extends _$RecurringRulesController {
  RecurringRulesPendingDelete? _pendingDelete;
  Timer? _undoTimer;
  _Composer? _composer;
  RecurringRulesEffectListener? _effectListener;

  @override
  Stream<RecurringRulesState> build() {
    final repo = ref.watch(recurringRulesRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      pendingDeleteGetter: () => _pendingDelete,
    );
    _composer = composer;
    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _pendingDelete = null;
      composer.dispose();
    });
    return composer.stream;
  }

  // ---------- Commands ----------

  Future<void> pauseRule(int id) async {
    final repo = ref.read(recurringRulesRepositoryProvider);
    await repo.setActive(id, active: false);
  }

  Future<void> resumeRule(int id) async {
    final repo = ref.read(recurringRulesRepositoryProvider);
    await repo.setActive(id, active: true);
  }

  Future<void> deleteRule(int id) async {
    if (_pendingDelete != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _pendingDelete!;
      final committed = await _commitDelete(prior.ruleId);
      if (!committed) return;
    }

    _pendingDelete = RecurringRulesPendingDelete(ruleId: id);
    _composer?.notifyPendingDeleteChanged();

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _pendingDelete;
      if (pending == null) return;
      await _commitDelete(pending.ruleId);
    });
  }

  Future<void> undoDelete() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDelete = null;
    _composer?.notifyPendingDeleteChanged();
  }

  void setEffectListener(RecurringRulesEffectListener? listener) {
    _effectListener = listener;
  }

  Future<bool> _commitDelete(int id) async {
    _composer?.notifyPendingDeleteChanged();
    try {
      await ref.read(recurringRulesRepositoryProvider).archive(id);
      if (_pendingDelete?.ruleId == id) {
        _pendingDelete = null;
        _composer?.notifyPendingDeleteChanged();
      }
      return true;
    } catch (error, stackTrace) {
      if (_pendingDelete?.ruleId == id) {
        _pendingDelete = null;
      }
      _composer?.notifyPendingDeleteChanged();
      _effectListener?.call(
        RecurringRulesDeleteFailedEffect(error, stackTrace),
      );
      return false;
    }
  }
}

class _Composer {
  _Composer({
    required RecurringRulesRepository repo,
    required RecurringRulesPendingDelete? Function() pendingDeleteGetter,
  })  : _repo = repo,
        _pendingDeleteGetter = pendingDeleteGetter {
    _out = StreamController<RecurringRulesState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final RecurringRulesRepository _repo;
  final RecurringRulesPendingDelete? Function() _pendingDeleteGetter;
  late final StreamController<RecurringRulesState> _out;
  StreamSubscription<List<RecurringRule>>? _sub;
  List<RecurringRule>? _rules;
  bool _emitScheduled = false;

  Stream<RecurringRulesState> get stream => _out.stream;

  void _start() {
    _out.add(const RecurringRulesState.loading());
    _sub = _repo.watchActive().listen(
      (rows) {
        _rules = rows;
        _scheduleEmit();
      },
      onError: _onError,
    );
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await _stop();
    if (!_out.isClosed) await _out.close();
  }

  void notifyPendingDeleteChanged() => _scheduleEmit();

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(RecurringRulesState.error(error, stack));
  }

  void _scheduleEmit() {
    if (_emitScheduled || _out.isClosed) return;
    _emitScheduled = true;
    scheduleMicrotask(() {
      _emitScheduled = false;
      _emitIfReady();
    });
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    final rules = _rules;
    if (rules == null) return;

    final pending = _pendingDeleteGetter();
    final visible = pending == null
        ? rules
        : rules.where((r) => r.id != pending.ruleId).toList(growable: false);

    if (visible.isEmpty && pending == null) {
      _out.add(const RecurringRulesState.empty());
    } else {
      _out.add(RecurringRulesState.data(rules: visible, pendingDelete: pending));
    }
  }
}
```

- [x] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 6: Run controller tests**

Run: `flutter test test/unit/controllers/recurring_rules_controller_test.dart`
Expected: PASS

- [x] **Step 7: Commit**

```bash
git add lib/features/recurring/recurring_rules_state.dart \
  lib/features/recurring/recurring_rules_controller.dart \
  test/unit/controllers/recurring_rules_controller_test.dart
git commit -m "feat: add RecurringRulesController with pause/resume/delete-undo"
```

---

### Task 12: Routing + Settings Entry Point

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/unit/app/router_test.dart`

- [x] **Step 1: Add routes to `router.dart`**

Add the three new routes inside the Settings branch's `routes` list, after the existing `manage-accounts/:id` route:

```dart
// Inside the Settings branch routes list:
GoRoute(
  path: 'recurring',
  builder: (_, _) => const RecurringRulesScreen(),
),
GoRoute(
  path: 'recurring/new',
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (ctx, state) => _modalPage(
    state,
    const _AdaptiveFormRoute(child: RecurringRuleFormScreen()),
    fullscreenDialog: true,
  ),
),
GoRoute(
  path: 'recurring/:id',
  redirect: (_, state) =>
      int.tryParse(state.pathParameters['id'] ?? '') == null
          ? '/settings'
          : null,
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (ctx, state) => _modalPage(
    state,
    _AdaptiveFormRoute(
      child: RecurringRuleFormScreen(
        ruleId: int.parse(state.pathParameters['id']!),
      ),
    ),
    fullscreenDialog: true,
  ),
),
```

Use `_AdaptiveFormRoute` from Task 12.5:

```dart
// In the page builders above:
//   _AdaptiveFormRoute(child: const RecurringRuleFormScreen())
//   _AdaptiveFormRoute(child: RecurringRuleFormScreen(ruleId: ...))
```

No new wrapper class is needed — the shared helper covers both transaction and recurring routes.

Add imports for `RecurringRulesScreen` and `RecurringRuleFormScreen`.

- [x] **Step 2: Add "Recurring Transactions" tile to Settings**

In `lib/features/settings/settings_screen.dart`, add a new tile in the "General" section:

```dart
// In the General section's children list, after ManageCategoriesTile:
ListTile(
  key: const ValueKey('settingsRecurringTile'),
  title: Text(l10n.settingsRecurringTile),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/settings/recurring'),
),
```

- [x] **Step 3: Run codegen and verify**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/app/router.dart lib/features/settings/settings_screen.dart
```
Expected: No errors

- [x] **Step 4: Commit**

```bash
git add lib/app/router.dart lib/features/settings/settings_screen.dart
git commit -m "feat: add recurring routes and settings entry point"
```

---

### Task 12.5: Extract `_AdaptiveFormRoute` Shared Helper

**Files:**
- Modify: `lib/app/router.dart`

The existing router already has `_AdaptiveTransactionFormRoute` and `_AdaptiveShoppingItemFormRoute` (or similar) using the same LayoutBuilder + Dialog shape. The new `_AdaptiveRecurringRuleFormRoute` would be a third copy. Extract a shared helper so the 600dp/560-maxWidth/24-inset breakpoint lives in one place.

```dart
// lib/app/router.dart — replace the per-feature wrapper classes with:
class _AdaptiveFormRoute extends StatelessWidget {
  const _AdaptiveFormRoute({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return child;
        return Scaffold(
          backgroundColor: Colors.black54,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Dialog(
                  insetPadding: const EdgeInsets.all(24),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.expand(child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

Then both `_AdaptiveTransactionFormRoute` and the new recurring route reduce to: `_AdaptiveFormRoute(child: TransactionFormScreen(...))` / `_AdaptiveFormRoute(child: RecurringRuleFormScreen(ruleId: ...))`.

- [x] **Step 1: Extract `_AdaptiveFormRoute`**
- [x] **Step 2: Replace existing `_AdaptiveTransactionFormRoute` call sites with `_AdaptiveFormRoute`**
- [x] **Step 3: Verify existing transaction-form route widget tests still pass**

```bash
git add lib/app/router.dart
git commit -m "refactor: extract _AdaptiveFormRoute shared helper"
```

---

### Task 13: `RecurringRulesScreen` (Management List)

**Files:**
- Create: `lib/features/recurring/recurring_rules_screen.dart`
- Create: `lib/features/recurring/recurring_rules_providers.dart`
- Create: `test/widget/features/recurring/recurring_rules_screen_test.dart`

- [x] **Step 1: Create `recurring_rules_providers.dart`**

```dart
// lib/features/recurring/recurring_rules_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';

part 'recurring_rules_providers.g.dart';

/// Returns the count of pending items for a given rule.
/// Used by the form screen's inline notice. Reads PendingTransactionRepository
/// directly (no proxy through RecurringRulesRepository — the recurring repo
/// is not coupled to pending state).
@Riverpod(dependencies: [pendingTransactionRepository])
Future<int> pendingCountForRule(Ref ref, int ruleId) {
  return ref
      .watch(pendingTransactionRepositoryProvider)
      .countByRecurringRule(ruleId);
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 3: Write widget tests for the management screen**

Create `test/widget/features/recurring/recurring_rules_screen_test.dart`:
- Renders rule list with correct tiles
- Renders empty state when no rules
- Renders loading state
- Swipe-left on active rule shows "Pause" label
- Swipe-left on paused rule shows "Resume" label
- Swipe-right shows "Delete" label
- Paused rule renders at 60% opacity
- FAB opens create route
- Tile has correct semantics label

- [x] **Step 4: Implement `RecurringRulesScreen`**

The screen follows the same pattern as `ShoppingListScreen`:
- Uses `ConsumerWidget` watching `recurringRulesControllerProvider`
- `CustomScrollView` with slivers for loading/empty/data/error states
- Each tile uses `Slidable` (flutter_slidable) for swipe actions, matching `ShoppingListScreen`. Pause/Resume in `startActionPane`; Delete in `endActionPane`.
- Leading: category color dot
- Title: rule name
- Subtitle: amount + frequency
- Trailing: next-due text or "Paused" chip
- FAB: `recurringFabNew`
- ≥600dp: FAB replaced by app-bar "+" action

- [x] **Step 5: Run widget tests**

Run: `flutter test test/widget/features/recurring/recurring_rules_screen_test.dart`
Expected: PASS

- [x] **Step 6: Commit**

```bash
git add lib/features/recurring/recurring_rules_screen.dart \
  lib/features/recurring/recurring_rules_providers.dart \
  test/widget/features/recurring/
git commit -m "feat: add RecurringRulesScreen with swipe actions and empty state"
```

---

### Task 14: `RecurringRuleFormScreen` (Create/Edit Form)

**Files:**
- Create: `lib/features/recurring/recurring_rule_form_state.dart`
- Create: `lib/features/recurring/recurring_rule_form_controller.dart`
- Create: `lib/features/recurring/recurring_rule_form_screen.dart`
- Create: `test/widget/features/recurring/recurring_rule_form_screen_test.dart`

- [x] **Step 1: Create `RecurringRuleFormState`**

```dart
// lib/features/recurring/recurring_rule_form_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/currency.dart';

part 'recurring_rule_form_state.freezed.dart';

/// Typed validation-error keys. Decouples controller from l10n.
enum RecurringFormErrorKey {
  nameRequired,
  categoryRequired,
  accountRequired,
  frequencyFieldRequired,
}

/// Save-time error surfaced on the form's banner.
sealed class RecurringFormError {
  const RecurringFormError();
  const factory RecurringFormError.archivedRef(String detail) = _ArchivedRef;
  const factory RecurringFormError.unknown(String detail) = _Unknown;
}

class _ArchivedRef extends RecurringFormError {
  const _ArchivedRef(this.detail);
  final String detail;
}

class _Unknown extends RecurringFormError {
  const _Unknown(this.detail);
  final String detail;
}

@freezed
abstract class RecurringRuleFormState with _$RecurringRuleFormState {
  const factory RecurringRuleFormState({
    @Default('') String name,
    @Default(0) int amountMinorUnits,
    required Currency currency,
    int? categoryId,
    int? accountId,
    String? memo,
    @Default('monthly') String frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    @Default(false) bool isEdit,
    @Default(false) bool isLoading,
    int? pendingItemCount,
    /// Field-level errors. Set by the controller per the validation-timing rules:
    /// - `nameError`: cleared on every keystroke; set on blur if name is empty,
    ///   and on a save attempt that fails `canSave`.
    /// - `categoryError` / `accountError`: only set on a save attempt that
    ///   fails `canSave` (selectors don't have a blur signal).
    /// - `frequencyFieldError`: set when the frequency dropdown changes to a
    ///   value whose required sub-field is null; cleared as soon as the
    ///   sub-field is filled.
    RecurringFormErrorKey? nameError,
    RecurringFormErrorKey? categoryError,
    RecurringFormErrorKey? accountError,
    RecurringFormErrorKey? frequencyFieldError,
    /// Form-level error from a failed save (archived FK, unknown). Cleared
    /// at the start of the next save attempt.
    RecurringFormError? formError,
    /// True when the rule was saved successfully but its post-save
    /// `executeForRule` returned `failed`. The screen reads this in its
    /// post-save listener and shows a non-blocking snackbar like:
    /// "Saved — but the first run hit an issue, will retry on next launch."
    @Default(false) bool postSaveGenerationFailed,
  }) = _RecurringRuleFormState;

  const RecurringRuleFormState._();

  bool get canSave =>
      name.trim().isNotEmpty &&
      amountMinorUnits > 0 &&
      categoryId != null &&
      accountId != null &&
      !hasFrequencyFieldError;

  bool get hasFrequencyFieldError {
    switch (frequency) {
      case 'weekly':
        return dayOfWeek == null;
      case 'monthly':
        return dayOfMonth == null;
      case 'yearly':
        return monthOfYear == null || dayOfMonth == null;
      default:
        return false;
    }
  }
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 3: Create `RecurringRuleFormController`**

```dart
// lib/features/recurring/recurring_rule_form_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/currency.dart';
import '../../data/models/recurring_rule_draft.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import 'recurring_rule_form_state.dart';
import 'recurring_rules_providers.dart';

part 'recurring_rule_form_controller.g.dart';

// `dependencies` mirrors the existing TransactionFormController pattern so
// `scoped_providers_should_specify_dependencies` lint is satisfied at every
// override site (widget tests, etc.).
@Riverpod(
  dependencies: [
    recurringRulesRepository,
    pendingTransactionRepository,
    recurringGenerationUseCase,
    currencyRepository,
    userPreferencesRepository,
  ],
)
class RecurringRuleFormController extends _$RecurringRuleFormController {
  @override
  Future<RecurringRuleFormState> build({int? ruleId}) async {
    // Default currency: read the code from user prefs, then resolve the
    // full Currency through the currency repo. (CurrencyRepository has no
    // `getDefault()` — the default is owned by user_preferences.)
    final userPrefs = ref.watch(userPreferencesRepositoryProvider);
    final currencyRepo = ref.watch(currencyRepositoryProvider);
    final defaultCode = await userPrefs.getDefaultCurrency();
    final defaultCurrency = await currencyRepo.getByCode(defaultCode);

    if (ruleId != null) {
      // Edit mode: hydrate from existing rule.
      final repo = ref.watch(recurringRulesRepositoryProvider);
      final rule = await repo.getById(ruleId);
      if (rule == null) {
        throw StateError('Recurring rule $ruleId not found');
      }
      // Pending count comes directly from the pending repo — no need to
      // proxy through RecurringRulesRepository.
      final pendingRepo = ref.watch(pendingTransactionRepositoryProvider);
      final pendingCount = await pendingRepo.countByRecurringRule(ruleId);
      return RecurringRuleFormState(
        name: rule.name,
        amountMinorUnits: rule.amountMinorUnits,
        currency: rule.currency,
        categoryId: rule.categoryId,
        accountId: rule.accountId,
        memo: rule.memo,
        frequency: rule.frequency,
        dayOfWeek: rule.dayOfWeek,
        dayOfMonth: rule.dayOfMonth,
        monthOfYear: rule.monthOfYear,
        isEdit: true,
        pendingItemCount: pendingCount,
      );
    }

    // Create mode: defaults.
    return RecurringRuleFormState(
      currency: defaultCurrency ?? const Currency(code: 'USD', decimals: 2),
    );
  }

  // ---------- Field updates ----------
  // Validation-timing rules (single source of truth):
  // - Free-text fields (`name`): clear nameError on every keystroke; set on
  //   blur if name is empty (handler owned by the screen — calls touchName).
  // - Selectors (`category`, `account`): error only set on a save attempt
  //   that fails canSave. Selecting a value clears that field's error.
  // - Frequency sub-fields (`dayOfWeek` / `dayOfMonth` / `monthOfYear`):
  //   filling the required sub-field clears `frequencyFieldError` immediately;
  //   it gets set on save attempt or on a frequency change that exposes a
  //   new required-but-unset sub-field.

  void updateName(String name) =>
      _update((s) => s.copyWith(name: name, nameError: null));

  /// Called from the name field's `onEditingComplete` (focus loss).
  void touchName() => _update((s) => s.copyWith(
        nameError: s.name.trim().isEmpty
            ? RecurringFormErrorKey.nameRequired
            : null,
      ));

  void updateAmount(int minorUnits) =>
      _update((s) => s.copyWith(amountMinorUnits: minorUnits));

  void updateCurrency(Currency currency) =>
      _update((s) => s.copyWith(currency: currency));

  void updateCategory(int categoryId) => _update((s) => s.copyWith(
        categoryId: categoryId,
        categoryError: null,
      ));

  void updateAccount(int accountId) => _update((s) => s.copyWith(
        accountId: accountId,
        accountError: null,
      ));

  void updateMemo(String? memo) =>
      _update((s) => s.copyWith(memo: memo));

  void updateFrequency(String frequency) {
    _update((s) {
      // Preserve unrelated sub-fields where possible. Switching to monthly
      // with a null dayOfMonth defaults to today's day clamped to 28 — gives
      // the user something to see in the stepper instead of a blank.
      var dayOfMonth = s.dayOfMonth;
      if ((frequency == 'monthly' || frequency == 'yearly') &&
          dayOfMonth == null) {
        final today = DateTime.now();
        dayOfMonth = today.day > 28 ? 28 : today.day;
      } else if (frequency == 'daily' || frequency == 'weekly') {
        dayOfMonth = null;
      }
      final next = s.copyWith(
        frequency: frequency,
        dayOfWeek: frequency == 'weekly' ? s.dayOfWeek : null,
        dayOfMonth: dayOfMonth,
        monthOfYear: frequency == 'yearly' ? s.monthOfYear : null,
      );
      // Set frequencyFieldError if the new state has a missing required field.
      return next.copyWith(
        frequencyFieldError: next.hasFrequencyFieldError
            ? RecurringFormErrorKey.frequencyFieldRequired
            : null,
      );
    });
  }

  void updateDayOfWeek(int? day) => _update((s) => s.copyWith(
        dayOfWeek: day,
        frequencyFieldError: day != null ? null : s.frequencyFieldError,
      ));

  void updateDayOfMonth(int? day) => _update((s) => s.copyWith(
        dayOfMonth: day,
        frequencyFieldError:
            day != null && (s.frequency != 'yearly' || s.monthOfYear != null)
                ? null
                : s.frequencyFieldError,
      ));

  void updateMonthOfYear(int? month) => _update((s) => s.copyWith(
        monthOfYear: month,
        frequencyFieldError: month != null && s.dayOfMonth != null
            ? null
            : s.frequencyFieldError,
      ));

  // v1 supports expense rules only — income parity is deferred. The category
  // picker constrains its options to `type='expense'`. Adding an income toggle
  // is a future change tracked in PRD's Phase-2 backlog.

  // ---------- Commands ----------

  /// Save the draft. On success, immediately runs generation for the new
  /// rule so the user sees today's pending row on Home without waiting
  /// for the next cold start. Returns the rule id on success, null if
  /// `canSave` was false. On a known repository error, sets `formError`
  /// on state and returns null without throwing.
  Future<int?> save() async {
    final current = state.valueOrNull;
    if (current == null) return null;
    if (!current.canSave) {
      _update((s) => s.copyWith(
            nameError: s.name.trim().isEmpty
                ? RecurringFormErrorKey.nameRequired
                : null,
            categoryError: s.categoryId == null
                ? RecurringFormErrorKey.categoryRequired
                : null,
            accountError: s.accountId == null
                ? RecurringFormErrorKey.accountRequired
                : null,
            frequencyFieldError: s.hasFrequencyFieldError
                ? RecurringFormErrorKey.frequencyFieldRequired
                : null,
          ));
      return null;
    }

    _update((s) => s.copyWith(isLoading: true, formError: null));
    try {
      final draft = RecurringRuleDraft(
        name: current.name.trim(),
        amountMinorUnits: current.amountMinorUnits,
        currency: current.currency,
        categoryId: current.categoryId!,
        accountId: current.accountId!,
        memo: current.memo,
        frequency: current.frequency,
        dayOfWeek: current.dayOfWeek,
        dayOfMonth: current.dayOfMonth,
        monthOfYear: current.monthOfYear,
      );

      final repo = ref.read(recurringRulesRepositoryProvider);
      final int savedId;
      if (current.isEdit && ruleId != null) {
        await repo.update(ruleId!, draft);
        savedId = ruleId!;
      } else {
        savedId = await repo.insert(draft);
      }

      // Fire generation for this rule synchronously so the user sees
      // today's pending row on Home without waiting for the next cold
      // start. The use case captures rule-level failures into
      // `last_error` and returns `failed` — it does not throw. The save
      // path stores the outcome on state so the screen can show a
      // non-blocking snackbar.
      //
      // The use case is read via its provider — the form controller is
      // a UI-layer file forbidden from importing `data/database/...` by
      // `controllers_forbid_db_and_services`. The provider lives in
      // `app/providers/`, which IS allowed.
      final useCase = ref.read(recurringGenerationUseCaseProvider);
      final outcome = await useCase.executeForRule(savedId);
      _update((s) => s.copyWith(
            postSaveGenerationFailed: outcome.failed,
          ));
      return savedId;
    } on ArchivedReferenceException catch (e) {
      _update((s) => s.copyWith(formError: RecurringFormError.archivedRef(e.message)));
      return null;
    } on RecurringRulesRepositoryException catch (e) {
      _update((s) => s.copyWith(formError: RecurringFormError.unknown(e.message)));
      return null;
    } finally {
      _update((s) => s.copyWith(isLoading: false));
    }
  }

  Future<void> deleteRule() async {
    if (ruleId == null) return;
    final repo = ref.read(recurringRulesRepositoryProvider);
    await repo.archive(ruleId!);
  }

  void _update(RecurringRuleFormState Function(RecurringRuleFormState) fn) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(fn(current));
  }
}
```

- [x] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 5: Write widget tests for the form screen**

Create `test/widget/features/recurring/recurring_rule_form_screen_test.dart`:
- Frequency dropdown swap renders correct conditional fields
- Day-of-week chips render at 48×48 dp
- `recurringDayOfMonthHint` always visible
- Name required, amount > 0 required
- Weekly chip required for frequency=weekly
- Save action disabled until valid
- Edit mode shows `recurringEditWillNotAffectPending` when count > 0
- Delete confirmation modal + post-delete snackbar with undo
- Adaptive: ≥600dp opens as constrained dialog

- [x] **Step 6: Implement `RecurringRuleFormScreen`**

The form screen follows the same structural pattern as `TransactionFormScreen`:
- `Scaffold(resizeToAvoidBottomInset: false)` with `SafeArea` → `Column`
- AppBar with title + save action
- Expanded scroll region with: name field, amount display, currency selector, account selector, category picker invoked via `await showCategoryPicker(context, type: CategoryType.expense)` (the frozen Wave-0 picker contract — v1 is expense-only), recurrence section, memo field, save-error banner (when `formError != null`), inline notice (edit mode, `pendingItemCount > 0`), delete button (edit mode)
- `KeypadCalculator` fixed at bottom
- Recurrence section: full-width `DropdownButtonFormField<String>` for frequency, `AnimatedSwitcher` (200ms fade) keyed by frequency for conditional sub-fields:
  - **Weekly:** `Wrap` of 7 `FilterChip` items, each min 48×48 dp, labeled with localized 2-letter weekday abbreviations.
  - **Monthly:** `_DayOfMonthStepper` widget (defined below) plus an always-visible `Text(recurringDayOfMonthHint)` in caption style.
  - **Yearly:** `DropdownButtonFormField<int>` for month (1-12, localized names), `_DayOfMonthStepper` below, plus the always-visible hint.
- Name field: on focus loss (`Focus.onFocusChange`) calls `controller.touchName()` so `nameError` only appears once the user has left the field empty — not while typing.
- Save tap: when `canSave` is false, calls `save()` anyway so the controller can populate per-field errors in one place.

**`_DayOfMonthStepper` widget contract:**

```dart
// A row laid out as: [-] [TextField(value)] [+]
// - TextField: numeric keyboard (TextInputType.number), max 2 digits,
//   InputFormatter clamps to 1..31. Width ~64dp; centered text.
// - Buttons: 44×44 dp tap targets via IconButton(constraints: BoxConstraints(
//   minWidth: 44, minHeight: 44)). Decrement disabled at 1, increment at 31.
// - Semantics: the whole row is a single semantics container with label
//   'Day of month, $value' and increase/decrease semantics actions wired to
//   the buttons. Long-press on +/- repeats every 100ms after a 400ms delay.
// - The widget calls `onChanged(int)` whenever the value changes; the form
//   controller's `updateDayOfMonth` clears `frequencyFieldError` when a
//   non-null value lands.
```

Why `TextField` + `+`/`-` (not a `Slider`, drum, or 31-step stepper): typing the day directly is fastest for power users who know the date; the buttons handle short adjustments; the input keyboard is the OS standard, accessible, RTL-safe, and respects text scaling. A 31-step single-tap stepper is a discoverability anti-pattern (27 taps to reach the 28th).

- [x] **Step 7: Run widget tests**

Run: `flutter test test/widget/features/recurring/recurring_rule_form_screen_test.dart`
Expected: PASS

- [x] **Step 8: Commit**

```bash
git add lib/features/recurring/recurring_rule_form_state.dart \
  lib/features/recurring/recurring_rule_form_controller.dart \
  lib/features/recurring/recurring_rule_form_screen.dart \
  test/widget/features/recurring/recurring_rule_form_screen_test.dart
git commit -m "feat: add RecurringRuleFormScreen with frequency-conditional fields"
```

---

### Task 15: Integration Tests

**Files:**
- Create: `test/integration/recurring_transaction_test.dart`

- [x] **Step 1: Write integration tests**

Cover the full user flow:
- Create rule with frequency=monthly day=15 on Mar 5 → `next_due_date` is Mar 15. Cold-start app on Mar 16 → pending row exists; approve → visible in Home; rule's `next_due_date` is Apr 15
- Idempotency: cold-start twice on the same day → exactly one pending row
- Pause rule → cold-start → no new pending rows. Resume → `next_due_date` recomputed from today
- Delete rule (archive) → no longer appears in management list; existing pending rows remain
- Catch-up cap end-to-end: cold-start with daily rule 30 days stale → 12 pending rows

Follow the pattern from `test/integration/bootstrap_to_home_test.dart`.

- [x] **Step 2: Run integration tests**

Run: `flutter test test/integration/recurring_transaction_test.dart`
Expected: PASS

- [x] **Step 3: Commit**

```bash
git add test/integration/recurring_transaction_test.dart
git commit -m "test: add recurring transaction integration tests"
```

---

### Task 16: Final Verification

- [x] **Step 1: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: All `.g.dart` and `.freezed.dart` files generated

- [x] **Step 2: Format**

Run: `dart format .`

- [x] **Step 3: Analyze**

Run: `flutter analyze`
Expected: No errors

- [x] **Step 4: Run all tests**

Run: `flutter test`
Expected: All tests pass

- [x] **Step 5: Final commit (if any formatting changes)**

```bash
git add -A
git commit -m "chore: format and finalize recurring transactions feature"
```
