# Recurring Transactions Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can define recurring transaction rules (daily/weekly/monthly/yearly) that auto-generate pending transactions on app open for one-tap approval.

**Architecture:** Introduces the `domain/` layer for the first time. A `RecurringGenerationUseCase` scans active rules on cold start, creates pending rows in `pending_transactions`, and advances `next_due_date`. The feature adds two new Drift tables (`recurring_rules`, `pending_transactions`) via a v3→v4 schema migration. UI follows the existing controller+state+screen pattern with a dedicated form screen (not a mode of TransactionFormScreen).

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
| `lib/domain/recurring_generation_use_case.dart`                       | Scans rules, creates pending items, advances dates                 |
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

| File                                          | Change                                                                          |
|-----------------------------------------------|---------------------------------------------------------------------------------|
| `lib/data/database/app_database.dart`         | Add 2 tables + 2 DAOs, bump schemaVersion to 4                                  |
| `lib/app/providers/repository_providers.dart` | Add `recurringRulesRepositoryProvider`, `pendingTransactionRepositoryProvider`  |
| `lib/app/app.dart`                            | Post-frame callback for `RecurringGenerationUseCase`                            |
| `lib/app/router.dart`                         | Add `/settings/recurring`, `/settings/recurring/new`, `/settings/recurring/:id` |
| `lib/features/settings/settings_screen.dart`  | Add "Recurring Transactions" tile                                               |
| `test/unit/repositories/migration_test.dart`  | Extend for v3→v4 migration                                                      |
| `l10n/app_en.arb`                             | Add recurring-related strings                                                   |
| `l10n/app_zh_TW.arb`                          | Add recurring-related strings                                                   |
| `l10n/app_zh_CN.arb`                          | Add recurring-related strings                                                   |

---

## Chunk 1: Data Layer Foundation

### Task 1: Schema — `pending_transactions` Table

**Files:**
- Create: `lib/data/database/tables/pending_transactions_table.dart`
- Test: `test/unit/repositories/migration_test.dart` (extend later in Task 3)

- [ ] **Step 1: Create the `PendingTransactions` Drift table definition**

```dart
// lib/data/database/tables/pending_transactions_table.dart
import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';
import 'recurring_rules_table.dart';

@DataClassName('PendingTransactionRow')
@TableIndex(
  name: 'idx_pending_recurring_unique',
  columns: {#recurringRuleId, #date},
  unique: true,
  // partial: WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL
  // Drift doesn't support partial indexes declaratively; we add it via
  // customStatement in migration.
)
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

- [ ] **Step 2: Verify the file compiles**

Run: `dart analyze lib/data/database/tables/pending_transactions_table.dart`
Expected: No errors (will warn about unused import of RecurringRules until Task 2)

- [ ] **Step 3: Commit**

```bash
git add lib/data/database/tables/pending_transactions_table.dart
git commit -m "feat: add pending_transactions Drift table definition"
```

---

### Task 2: Schema — `recurring_rules` Table

**Files:**
- Create: `lib/data/database/tables/recurring_rules_table.dart`

- [ ] **Step 1: Create the `RecurringRules` Drift table definition**

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

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `dart analyze lib/data/database/tables/recurring_rules_table.dart`
Expected: No errors

- [ ] **Step 3: Commit**

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

- [ ] **Step 1: Create `RecurringRuleDao`**

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

  /// Hard-delete by id.
  Future<int> deleteById(int id) {
    return (delete(recurringRules)..where((t) => t.id.equals(id))).go();
  }
}
```

- [ ] **Step 2: Create `PendingTransactionDao`**

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

- [ ] **Step 3: Run codegen for the new DAOs**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `recurring_rule_dao.g.dart` and `pending_transaction_dao.g.dart`

- [ ] **Step 4: Update `AppDatabase` — register tables, DAOs, bump schema, add migration**

In `lib/data/database/app_database.dart`:
- Import the two new table files and two new DAO files
- Add `PendingTransactions` and `RecurringRules` to the `tables` list in `@DriftDatabase`
- Add `PendingTransactionDao` and `RecurringRuleDao` to the `daos` list
- Bump `schemaVersion` from `3` to `4`
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

  // Partial UNIQUE index for recurring idempotency.
  // Drift doesn't support partial indexes declaratively, so we add
  // it via customStatement.
  await customStatement(
    'CREATE UNIQUE INDEX idx_pending_recurring_unique '
    'ON pending_transactions(recurring_rule_id, date) '
    "WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL",
  );
}
```

- [ ] **Step 5: Update migration tests**

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

- [ ] **Step 6: Regenerate Drift schema snapshot and harness**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/unit/repositories/_harness/generated/
```

Expected: `drift_schemas/drift_schema_v4.json` created, harness files updated.

- [ ] **Step 7: Run migration tests to verify**

Run: `flutter test test/unit/repositories/migration_test.dart`
Expected: PASS

- [ ] **Step 8: Commit**

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

- [ ] **Step 1: Create `RecurringRule` Freezed model**

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
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecurringRule;
}
```

- [ ] **Step 2: Create `RecurringRuleDraft` Freezed model**

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

- [ ] **Step 3: Create `PendingTransaction` Freezed model**

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

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `.freezed.dart` files for all three models.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/recurring_rule.dart lib/data/models/recurring_rule_draft.dart \
  lib/data/models/pending_transaction.dart
git commit -m "feat: add RecurringRule, RecurringRuleDraft, PendingTransaction domain models"
```

---

### Task 5: `PendingTransactionRepository` (minimal)

**Files:**
- Create: `lib/data/repositories/pending_transaction_repository.dart`

- [ ] **Step 1: Create the repository**

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

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/data/repositories/pending_transaction_repository.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/pending_transaction_repository.dart
git commit -m "feat: add minimal PendingTransactionRepository for recurring generation"
```

---

### Task 6: `RecurringRulesRepository`

**Files:**
- Create: `lib/data/repositories/recurring_rules_repository.dart`
- Create: `test/unit/repositories/recurring_rules_repository_test.dart`

- [ ] **Step 1: Write repository tests — initial `next_due_date` calculation**

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
      // Next Feb 29 is 2028 (leap year). But 2026 is not leap, so
      // next_due_date should be Feb 28, 2027.
      final today = DateTime(2026, 1, 1);
      final id = await repo.insert(
        _draft(frequency: 'yearly', monthOfYear: 2, dayOfMonth: 29),
        today: today,
      );
      final rule = await repo.getById(id);
      // 2026 is not leap → Feb 28, 2026 is the first match (already passed
      // if today is Jan 1? No, Feb 28 2026 is in the future). Actually
      // we need to think about this: today is Jan 1, 2026. month=2, day=29.
      // Feb 29 2026 doesn't exist (not leap). Clamp to Feb 28 2026.
      // Feb 28 2026 is after Jan 1, so next_due_date = Feb 28, 2026.
      expect(rule!.nextDueDate, DateTime(2026, 2, 28));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/repositories/recurring_rules_repository_test.dart`
Expected: FAIL — `DriftRecurringRulesRepository` doesn't exist yet.

- [ ] **Step 3: Implement `RecurringRulesRepository`**

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

class RuleHasPendingItemsException extends RecurringRulesRepositoryException {
  const RuleHasPendingItemsException(super.message);
}

class FrequencyFieldsMissingException
    extends RecurringRulesRepositoryException {
  const FrequencyFieldsMissingException(super.message);
}

abstract class RecurringRulesRepository {
  Stream<List<RecurringRule>> watchActive();

  /// One-shot query: active, non-archived rules whose next_due_date <= [today].
  Future<List<RecurringRule>> watchDue(DateTime today);

  Future<RecurringRule?> getById(int id);
  Future<int> countPendingForRule(int id);

  /// Insert a new rule. Computes initial next_due_date from frequency + today.
  Future<int> insert(RecurringRuleDraft draft, {DateTime? today});

  /// Edit a rule. Affects future generations only.
  Future<void> update(int id, RecurringRuleDraft draft);

  /// Pause or resume. Resume recomputes next_due_date from today.
  Future<void> setActive(int id, {required bool active, DateTime? today});

  /// Soft-delete.
  Future<void> archive(int id);

  /// Hard-delete. Only for unused rules.
  Future<void> hardDelete(int id);

  /// Advance next_due_date after generation. Called by use case.
  Future<void> advanceAfterGeneration(int id, DateTime newNextDueDate);

  /// Advance a date by one frequency interval, anchored on the rule's
  /// day_of_month / day_of_week / month_of_year. Used by the use case
  /// for the generation loop. Centralized here to avoid duplication.
  DateTime advanceDateByFrequency(RecurringRule rule, DateTime current);

  /// Fast-forward to the most recent matching occurrence at or before [today].
  DateTime fastForwardToRecent(RecurringRule rule, DateTime today);
}

final class DriftRecurringRulesRepository implements RecurringRulesRepository {
  DriftRecurringRulesRepository(
    this._db, {
    DateTime Function()? clock,
    this.pendingDao,
  })  : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  final DateTime Function() _clock;

  /// Optional DAO for pending count checks. When null, countPendingForRule
  /// returns 0 (used before PendingTransactionRepository is wired).
  final drift.PendingTransactionDao? pendingDao;

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
  Future<int> countPendingForRule(int id) async {
    return pendingDao?.countByRecurringRule(id) ?? 0;
  }

  @override
  Future<List<RecurringRule>> watchDue(DateTime today) async {
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
      final draft = _storedToDraft(stored);
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
  Future<void> hardDelete(int id) async {
    final stored = await _dao.findById(id);
    if (stored == null) return;

    final pendingCount = await countPendingForRule(id);
    if (pendingCount > 0) {
      throw RuleHasPendingItemsException(
        'Cannot hard-delete rule $id: $pendingCount pending items exist',
      );
    }
    await _dao.deleteById(id);
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
  DateTime fastForwardToRecent(RecurringRule rule, DateTime today) {
    var candidate = rule.nextDueDate;
    var next = advanceDateByFrequency(rule, candidate);
    while (next.isBefore(DateTime(today.year, today.month, today.day)) ||
        next.isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
      candidate = next;
      next = advanceDateByFrequency(rule, candidate);
    }
    return candidate;
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
  DateTime _nextMonthlyDate(DateTime from, int dayOfMonth) {
    // If today's day <= dayOfMonth and this month can hold it, use this month.
    final clampedThisMonth = _clampDay(from.year, from.month, dayOfMonth);
    if (from.day <= dayOfMonth &&
        clampedThisMonth.day == dayOfMonth) {
      return clampedThisMonth;
    }
    // Otherwise next month.
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
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  RecurringRuleDraft _storedToDraft(drift.RecurringRuleRow row) {
    // Note: decimals are not needed for date computation, but we load the
    // full currency in _toDomain for the domain model. Here we only need
    // the code for _computeInitialNextDue, so a minimal Currency stub is OK.
    return RecurringRuleDraft(
      name: row.name,
      amountMinorUnits: row.amountMinorUnits,
      currency: Currency(code: row.currency, decimals: 0),
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

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/repositories/recurring_rules_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Add more repository tests**

Extend the test file with:
- Pause/resume: `is_active` toggle, `next_due_date` recalculation on resume
- `hardDelete` throws `RuleHasPendingItemsException` when pending rows exist
- Archive sets `is_archived = true` and `is_active = false`
- `ArchivedReferenceException` on insert with archived category/account
- `FrequencyFieldsMissingException` when required fields are null
- Stream emissions: `watchActive` emits sorted list
- Day-of-month anchor: insert with `day_of_month=31` in March → Mar 31; advance to April → Apr 30; advance to May → May 31

- [ ] **Step 6: Run all repository tests**

Run: `flutter test test/unit/repositories/recurring_rules_repository_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/data/repositories/recurring_rules_repository.dart \
  test/unit/repositories/recurring_rules_repository_test.dart
git commit -m "feat: add RecurringRulesRepository with next-due-date computation and tests"
```

---

### Task 7: `PendingTransactionRepository` Tests

**Files:**
- Create: `test/unit/repositories/pending_transaction_repository_test.dart`

- [ ] **Step 1: Write tests for PendingTransactionRepository**

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

- [ ] **Step 2: Run tests**

Run: `flutter test test/unit/repositories/pending_transaction_repository_test.dart`
Expected: PASS

- [ ] **Step 3: Register providers in `repository_providers.dart`**

Add to `lib/app/providers/repository_providers.dart`:

```dart
import '../../data/repositories/pending_transaction_repository.dart';
import '../../data/repositories/recurring_rules_repository.dart';

@Riverpod(keepAlive: true, dependencies: [appDatabase])
PendingTransactionRepository pendingTransactionRepository(Ref ref) =>
    DriftPendingTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true, dependencies: [appDatabase, currencyRepository, pendingTransactionRepository])
RecurringRulesRepository recurringRulesRepository(Ref ref) =>
    DriftRecurringRulesRepository(
      ref.watch(appDatabaseProvider),
      pendingDao: ref.watch(appDatabaseProvider).pendingTransactionDao,
    );
```

- [ ] **Step 4: Run codegen and verify**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/app/providers/repository_providers.dart
```
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/app/providers/repository_providers.dart \
  test/unit/repositories/pending_transaction_repository_test.dart
git commit -m "feat: add PendingTransactionRepository tests and wire providers"
```

---

## Chunk 2: Domain Layer + Generation Use Case

### Task 8: `RecurringGenerationUseCase`

**Files:**
- Create: `lib/domain/recurring_generation_use_case.dart`
- Create: `test/unit/use_cases/recurring_generation_use_case_test.dart`

- [ ] **Step 1: Write use case tests — happy path**

```dart
// test/unit/use_cases/recurring_generation_use_case_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/domain/recurring_generation_use_case.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

class _MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

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
    late _MockRecurringRulesRepository recurringRepo;
    late _MockPendingTransactionRepository pendingRepo;

    setUp(() {
      recurringRepo = _MockRecurringRulesRepository();
      pendingRepo = _MockPendingTransactionRepository();
      registerFallbackValue(DateTime(2026, 1, 1));
    });

    ProviderContainer makeContainer({
      DateTime Function()? clock,
    }) {
      return ProviderContainer(
        overrides: [
          recurringRulesRepositoryProvider.overrideWithValue(recurringRepo),
          pendingTransactionRepositoryProvider.overrideWithValue(pendingRepo),
        ],
      );
    }

    test('happy path: due rule generates pending row and advances date',
        () async {
      final today = DateTime(2026, 5, 7);
      final rule = _rule(id: 1, nextDueDate: DateTime(2026, 5, 7));

      when(() => recurringRepo.watchDue(any()))
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

      final container = makeContainer(clock: () => today);
      addTearDown(container.dispose);

      final useCase = container.read(recurringGenerationUseCaseProvider);
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

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/use_cases/recurring_generation_use_case_test.dart`
Expected: FAIL — `recurringGenerationUseCaseProvider` doesn't exist.

- [ ] **Step 3: Implement `RecurringGenerationUseCase`**

```dart
// lib/domain/recurring_generation_use_case.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app/providers/repository_providers.dart';
import '../data/models/recurring_rule.dart';
import '../data/repositories/pending_transaction_repository.dart';
import '../data/repositories/recurring_rules_repository.dart';

part 'recurring_generation_use_case.g.dart';

/// Provider for the generation-in-progress flag.
/// Consumed by the Pending Transactions screen to show a loading banner.
final generationInProgressProvider = StateProvider<bool>((ref) => false);

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

  Future<void> execute({DateTime Function()? clock}) async {
    final now = clock?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueRules = await recurringRepo.watchDue(today);
    if (dueRules.isEmpty) return;

    for (final rule in dueRules) {
      try {
        await _processRule(rule, today, clock);
      } catch (e) {
        // Per-rule error: log and continue. One bad rule does not abort
        // generation for the rest.
        // ignore: avoid_print
        print('RecurringGenerationUseCase: error processing rule ${rule.id}: $e');
      }
    }
  }

  Future<void> _processRule(
    RecurringRule rule,
    DateTime today,
    DateTime Function()? clock,
  ) async {
    var currentDue = rule.nextDueDate;
    var generated = 0;

    // Per-rule atomicity: the entire insert+advance loop runs in a single
    // DB transaction. A crash mid-sequence rolls back both insert and advance.
    await db.transaction(() async {
      while (!_isAfter(currentDue, today) && generated < _catchUpCap) {
        // Fast-path idempotency skip.
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

        // Advance to next occurrence (delegates to repository for date math).
        currentDue = recurringRepo.advanceDateByFrequency(rule, currentDue);
        generated++;
      }

      // If we hit the cap and there are still more missed periods,
      // fast-forward to the most recent matching occurrence at or before today.
      if (generated == _catchUpCap && !_isAfter(currentDue, today)) {
        currentDue = recurringRepo.fastForwardToRecent(rule, today);
      }
    });

    // Persist the new next_due_date (outside the transaction so the
    // advance is visible to the next stream emission).
    await recurringRepo.advanceAfterGeneration(rule.id, currentDue);
  }

  bool _isAfter(DateTime a, DateTime b) {
    return a.isAfter(DateTime(b.year, b.month, b.day));
  }
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `recurring_generation_use_case.g.dart`

- [ ] **Step 6: Run use case tests**

Run: `flutter test test/unit/use_cases/recurring_generation_use_case_test.dart`
Expected: PASS

- [ ] **Step 7: Add more use case tests**

Extend the test file with:
- Idempotency: same rule, same date, run twice → only one pending row
- Catch-up cap: daily rule 30 days stale → exactly 12 pending rows
- Paused rules skipped
- Archived rules skipped
- Multiple rules: exception in rule A does not abort rule B
- `generationInProgress` flag toggles correctly

- [ ] **Step 8: Run all use case tests**

Run: `flutter test test/unit/use_cases/recurring_generation_use_case_test.dart`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add lib/domain/ lib/data/repositories/recurring_rules_repository.dart \
  test/unit/use_cases/
git commit -m "feat: add RecurringGenerationUseCase with catch-up cap and idempotency"
```

---

### Task 9: Bootstrap Wiring — Post-Frame Callback

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `test/unit/repositories/migration_test.dart` (update version assertion)

- [ ] **Step 1: Add post-frame callback to `App` widget**

In `lib/app/app.dart`, add a `ConsumerStatefulWidget` wrapper that registers the post-frame callback:

```dart
// In lib/app/app.dart, replace the existing App class:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recurring_generation_use_case.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _generationTriggered = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final preferredLocale = ref.watch(userLocalePreferenceProvider);

    // Trigger recurring generation on first frame render.
    if (!_generationTriggered) {
      _generationTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final useCase = ref.read(recurringGenerationUseCaseProvider);
        ref.read(generationInProgressProvider.notifier).state = true;
        unawaited(
          useCase
              .execute()
              .whenComplete(() {
                if (mounted) {
                  ref.read(generationInProgressProvider.notifier).state = false;
                }
              }),
        );
      });
    }

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: preferredLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (device, supported) => resolveChineseLocale(
        preferredLocale,
        supported,
        device ?? const Locale('en', 'US'),
      ),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/app/app.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/app/app.dart
git commit -m "feat: wire RecurringGenerationUseCase into app post-frame callback"
```

---

## Chunk 3: UI — Controllers, Screens, Routing, l10n

### Task 10: l10n Strings

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`

- [ ] **Step 1: Add recurring-related strings to `app_en.arb`**

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

  "recurringResumedSnack": "Resumed — {ruleName}, next due {date}",
  "@recurringResumedSnack": {
    "description": "Snackbar after resume.",
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

  "recurringDeleteConfirm": "Delete this rule? Pending items already generated will remain in your queue.",
  "@recurringDeleteConfirm": { "description": "Delete confirmation dialog body." },

  "recurringEditWillNotAffectPending": "You have {count} pending item(s) from this rule. Edits below won't change them — review them in Pending Transactions.",
  "@recurringEditWillNotAffectPending": {
    "description": "Edit form inline notice.",
    "placeholders": { "count": { "type": "int", "format": "compact" } }
  },

  "recurringSourceHeader": "Recurring",
  "@recurringSourceHeader": { "description": "Pending Transactions screen source group." },

  "recurringPendingDueLabel": "Due {date}",
  "@recurringPendingDueLabel": {
    "description": "Pending item due-date label.",
    "placeholders": { "date": { "type": "String" } }
  },

  "recurringGenerationInProgress": "Checking for new pending items…",
  "@recurringGenerationInProgress": { "description": "Banner on Pending screen during generation." }
```

- [ ] **Step 2: Add corresponding strings to `app_zh_TW.arb` and `app_zh_CN.arb`**

Add Traditional Chinese and Simplified Chinese translations. For now, use English as placeholders (translators will fill in later).

- [ ] **Step 3: Regenerate l10n code**

Run: `flutter gen-l10n` (or `flutter pub run build_runner build` if l10n is integrated)
Expected: `AppLocalizations` class includes all new getters.

- [ ] **Step 4: Commit**

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

- [ ] **Step 1: Create `RecurringRulesState` Freezed model**

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

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Write controller tests**

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

- [ ] **Step 4: Implement `RecurringRulesController`**

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

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run controller tests**

Run: `flutter test test/unit/controllers/recurring_rules_controller_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

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

- [ ] **Step 1: Add routes to `router.dart`**

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
    const _AdaptiveRecurringRuleFormRoute(),
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
    _AdaptiveRecurringRuleFormRoute(
      ruleId: int.parse(state.pathParameters['id']!),
    ),
    fullscreenDialog: true,
  ),
),
```

Add the adaptive wrapper widget (similar to `_AdaptiveTransactionFormRoute`):

```dart
class _AdaptiveRecurringRuleFormRoute extends StatelessWidget {
  const _AdaptiveRecurringRuleFormRoute({this.ruleId});
  final int? ruleId;

  @override
  Widget build(BuildContext context) {
    final form = RecurringRuleFormScreen(ruleId: ruleId);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return form;
        return Scaffold(
          backgroundColor: Colors.black54,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Dialog(
                  insetPadding: const EdgeInsets.all(24),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.expand(child: form),
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

Add imports for `RecurringRulesScreen` and `RecurringRuleFormScreen`.

- [ ] **Step 2: Add "Recurring Transactions" tile to Settings**

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

- [ ] **Step 3: Run codegen and verify**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/app/router.dart lib/features/settings/settings_screen.dart
```
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/app/router.dart lib/features/settings/settings_screen.dart
git commit -m "feat: add recurring routes and settings entry point"
```

---

### Task 13: `RecurringRulesScreen` (Management List)

**Files:**
- Create: `lib/features/recurring/recurring_rules_screen.dart`
- Create: `lib/features/recurring/recurring_rules_providers.dart`
- Create: `test/widget/features/recurring/recurring_rules_screen_test.dart`

- [ ] **Step 1: Create `recurring_rules_providers.dart`**

```dart
// lib/features/recurring/recurring_rules_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';

part 'recurring_rules_providers.g.dart';

/// Returns the count of pending items for a given rule.
/// Used by the form screen's inline notice.
@Riverpod(dependencies: [recurringRulesRepository])
Future<int> pendingCountForRule(Ref ref, int ruleId) {
  return ref
      .watch(recurringRulesRepositoryProvider)
      .countPendingForRule(ruleId);
}
```

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Write widget tests for the management screen**

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

- [ ] **Step 4: Implement `RecurringRulesScreen`**

The screen follows the same pattern as `ShoppingListScreen`:
- Uses `ConsumerWidget` watching `recurringRulesControllerProvider`
- `CustomScrollView` with slivers for loading/empty/data/error states
- Each tile uses `Dismissible` for swipe actions
- Leading: category color dot
- Title: rule name
- Subtitle: amount + frequency
- Trailing: next-due text or "Paused" chip
- FAB: `recurringFabNew`
- ≥600dp: FAB replaced by app-bar "+" action

- [ ] **Step 5: Run widget tests**

Run: `flutter test test/widget/features/recurring/recurring_rules_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

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

- [ ] **Step 1: Create `RecurringRuleFormState`**

```dart
// lib/features/recurring/recurring_rule_form_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/currency.dart';

part 'recurring_rule_form_state.freezed.dart';

@freezed
abstract class RecurringRuleFormState with _$RecurringRuleFormState {
  const factory RecurringRuleFormState({
    @Default('expense') String transactionType,
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
    String? nameError,
    String? categoryError,
    String? accountError,
    String? frequencyFieldError,
  }) = _RecurringRuleFormState;

  const RecurringRuleFormState._();

  bool get canSave =>
      name.trim().isNotEmpty &&
      amountMinorUnits > 0 &&
      categoryId != null &&
      accountId != null &&
      !_hasFrequencyFieldError;

  bool get _hasFrequencyFieldError {
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

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Create `RecurringRuleFormController`**

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

@riverpod
class RecurringRuleFormController extends _$RecurringRuleFormController {
  @override
  Future<RecurringRuleFormState> build({int? ruleId}) async {
    final currencyRepo = ref.watch(currencyRepositoryProvider);
    final defaultCurrency = await currencyRepo.getDefault();

    if (ruleId != null) {
      // Edit mode: hydrate from existing rule.
      final repo = ref.watch(recurringRulesRepositoryProvider);
      final rule = await repo.getById(ruleId);
      if (rule == null) {
        throw StateError('Recurring rule $ruleId not found');
      }
      final pendingCount = await repo.countPendingForRule(ruleId);
      return RecurringRuleFormState(
        transactionType: 'expense', // derived from category
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

  void updateName(String name) => _update((s) => s.copyWith(name: name));

  void updateAmount(int minorUnits) =>
      _update((s) => s.copyWith(amountMinorUnits: minorUnits));

  void updateCurrency(Currency currency) =>
      _update((s) => s.copyWith(currency: currency));

  void updateCategory(int categoryId) =>
      _update((s) => s.copyWith(categoryId: categoryId));

  void updateAccount(int accountId) =>
      _update((s) => s.copyWith(accountId: accountId));

  void updateMemo(String? memo) =>
      _update((s) => s.copyWith(memo: memo));

  void updateFrequency(String frequency) => _update((s) => s.copyWith(
        frequency: frequency,
        dayOfWeek: frequency == 'weekly' ? s.dayOfWeek : null,
        dayOfMonth: (frequency == 'monthly' || frequency == 'yearly')
            ? s.dayOfMonth
            : null,
        monthOfYear: frequency == 'yearly' ? s.monthOfYear : null,
      ));

  void updateDayOfWeek(int? day) =>
      _update((s) => s.copyWith(dayOfWeek: day));

  void updateDayOfMonth(int? day) =>
      _update((s) => s.copyWith(dayOfMonth: day));

  void updateMonthOfYear(int? month) =>
      _update((s) => s.copyWith(monthOfYear: month));

  void updateTransactionType(String type) =>
      _update((s) => s.copyWith(
            transactionType: type,
            categoryId: null, // reset category when type changes
          ));

  // ---------- Commands ----------

  Future<int?> save() async {
    final current = state.valueOrNull;
    if (current == null || !current.canSave) return null;

    _update((s) => s.copyWith(isLoading: true));
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
      if (current.isEdit && ruleId != null) {
        await repo.update(ruleId!, draft);
        return ruleId;
      } else {
        return await repo.insert(draft);
      }
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

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Write widget tests for the form screen**

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

- [ ] **Step 6: Implement `RecurringRuleFormScreen`**

The form screen follows the same structural pattern as `TransactionFormScreen`:
- `Scaffold(resizeToAvoidBottomInset: false)` with `SafeArea` → `Column`
- AppBar with title + save action
- Expanded scroll region with: type toggle, name field, amount display, currency selector, account selector, category picker, recurrence section, memo field, inline notice (edit mode), delete button (edit mode)
- `KeypadCalculator` fixed at bottom
- Recurrence section: frequency dropdown + conditional fields (animated cross-fade)
- Weekly: 7-chip horizontal selector (Sun-Sat), min 48×48 dp
- Monthly: stepper 1-31 + always-visible hint
- Yearly: month dropdown + day stepper + hint

- [ ] **Step 7: Run widget tests**

Run: `flutter test test/widget/features/recurring/recurring_rule_form_screen_test.dart`
Expected: PASS

- [ ] **Step 8: Commit**

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

- [ ] **Step 1: Write integration tests**

Cover the full user flow:
- Create rule with frequency=monthly day=15 on Mar 5 → `next_due_date` is Mar 15. Cold-start app on Mar 16 → pending row exists; approve → visible in Home; rule's `next_due_date` is Apr 15
- Idempotency: cold-start twice on the same day → exactly one pending row
- Pause rule → cold-start → no new pending rows. Resume → `next_due_date` recomputed from today
- Delete rule (archive) → no longer appears in management list; existing pending rows remain
- Catch-up cap end-to-end: cold-start with daily rule 30 days stale → 12 pending rows

Follow the pattern from `test/integration/bootstrap_to_home_test.dart`.

- [ ] **Step 2: Run integration tests**

Run: `flutter test test/integration/recurring_transaction_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/integration/recurring_transaction_test.dart
git commit -m "test: add recurring transaction integration tests"
```

---

### Task 16: Final Verification

- [ ] **Step 1: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: All `.g.dart` and `.freezed.dart` files generated

- [ ] **Step 2: Format**

Run: `dart format .`

- [ ] **Step 3: Analyze**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 4: Run all tests**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: Final commit (if any formatting changes)**

```bash
git add -A
git commit -m "chore: format and finalize recurring transactions feature"
```
