// Shared in-memory Drift harness for repository-layer tests.
//
// Ownership: M3 Stream C (`docs/plans/m3-repositories-seed/
// stream-c-preferences-seed-migration.md` §4). No test file may fork a
// local in-memory DB helper (see Stream B plan §6.4).
//
// Besides `newTestAppDatabase()`, this file holds the raw-SQL fixtures that
// several repository tests share, so they seed rows without depending on
// other repositories' internals, and a no-op `ExchangeRateRepository`.

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/recurring_rule_draft.dart';
import 'package:mocktail/mocktail.dart';

/// Returns a fresh in-memory `AppDatabase` for tests.
///
/// `NativeDatabase.memory()` gives each test an isolated DB with no disk
/// footprint. The caller MUST `await db.close()` in a `tearDown` /
/// `addTearDown` block.
///
/// The returned database applies `PRAGMA foreign_keys = ON` via
/// `AppDatabase.migration.beforeOpen` — repository FK pre-check tests rely
/// on this being active.
AppDatabase newTestAppDatabase() => AppDatabase(NativeDatabase.memory());

class _NoRatesService extends Mock implements ExchangeRateService {}

/// Returns a real `ExchangeRateRepository` on its own in-memory DB whose
/// service fetches no rates, so `refreshAll` is a silent no-op. The repo
/// is disposed and its DB closed at teardown.
ExchangeRateRepository newNoRatesExchangeRateRepository() {
  final service = _NoRatesService();
  when(() => service.fetchRates(any())).thenAnswer((_) async => []);
  final db = newTestAppDatabase();
  final repo = ExchangeRateRepository(
    db,
    service,
    const Stream<String>.empty(),
  );
  addTearDown(() async {
    repo.dispose();
    await db.close();
  });
  return repo;
}

/// Row ids [seedRepositoryFixtures] inserted.
typedef RepositoryFixtures = ({
  int expenseCategoryId,
  int incomeCategoryId,
  int accountTypeId,
  int accountId,
});

/// Seeds the minimal fixture surface the transaction and category tests
/// need:
///   - currencies: USD(2), JPY(0), TWD(2)
///   - categories: one `category.food` expense + one `category.salary` income
///   - account_types: one `accountType.cash` row
///   - accounts: one USD Cash account
Future<RepositoryFixtures> seedRepositoryFixtures(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, is_token, '
    'sort_order) VALUES (?, ?, ?, ?, 0, ?), (?, ?, ?, ?, 0, ?), '
    '(?, ?, ?, ?, 0, ?)',
    <Object?>[
      'USD',
      2,
      r'$',
      'currency.usd',
      1,
      'JPY',
      0,
      '¥',
      'currency.jpy',
      2,
      'TWD',
      2,
      r'NT$',
      'currency.twd',
      3,
    ],
  );

  final expenseId = await _insertCategoryRaw(
    db,
    l10nKey: 'category.food',
    icon: 'restaurant',
    color: 0,
    type: 'expense',
    sortOrder: 1,
  );
  final incomeId = await _insertCategoryRaw(
    db,
    l10nKey: 'category.salary',
    icon: 'work',
    color: 1,
    type: 'income',
    sortOrder: 2,
  );

  await db.customStatement(
    'INSERT INTO account_types (l10n_key, icon, color, sort_order, '
    'is_archived) VALUES (?, ?, 0, 1, 0)',
    <Object?>['accountType.cash', 'wallet'],
  );
  final accountTypeRows = await db
      .customSelect('SELECT id FROM account_types')
      .get();
  final accountTypeId = accountTypeRows.first.read<int>('id');

  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, '
    'opening_balance_minor_units, is_archived) VALUES (?, ?, ?, 0, 0)',
    <Object?>['Cash', accountTypeId, 'USD'],
  );
  final accountRows = await db.customSelect('SELECT id FROM accounts').get();
  final accountId = accountRows.first.read<int>('id');

  return (
    expenseCategoryId: expenseId,
    incomeCategoryId: incomeId,
    accountTypeId: accountTypeId,
    accountId: accountId,
  );
}

Future<int> _insertCategoryRaw(
  AppDatabase db, {
  required String l10nKey,
  required String icon,
  required int color,
  required String type,
  required int sortOrder,
}) async {
  await db.customStatement(
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, '
    'is_archived) VALUES (?, ?, ?, ?, ?, 0)',
    <Object?>[l10nKey, icon, color, type, sortOrder],
  );
  final rows = await db
      .customSelect(
        'SELECT id FROM categories WHERE l10n_key = ?',
        variables: <Variable<Object>>[Variable.withString(l10nKey)],
      )
      .get();
  return rows.first.read<int>('id');
}

/// Inserts the USD currency row, ignoring it if already present.
Future<void> seedUsdCurrencyRaw(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO currencies '
    '(code, decimals, symbol, name_l10n_key, is_token, sort_order) '
    'VALUES (?, ?, ?, ?, 0, ?)',
    <Object?>['USD', 2, r'$', 'currency.usd', 1],
  );
}

/// Inserts an `at.test` account type (once) and a USD 'Cash' account on
/// it, returning the account's id. Needs the USD currency row.
Future<int> insertCashAccountRaw(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO account_types '
    '(l10n_key, icon, color, sort_order, is_archived) '
    'VALUES (?, ?, ?, ?, ?)',
    <Object?>['at.test', 'wallet', 0, 1, 0],
  );
  final typeRows = await db
      .customSelect('SELECT id FROM account_types ORDER BY id ASC LIMIT 1')
      .get();
  final typeId = typeRows.first.read<int>('id');
  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, '
    'opening_balance_minor_units, is_archived) '
    'VALUES (?, ?, ?, 0, 0)',
    <Object?>['Cash', typeId, 'USD'],
  );
  final rows = await db
      .customSelect('SELECT id FROM accounts ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

/// Inserts a minimal shopping-list item referencing the given category and
/// account. Drift stores DateTimes as Unix seconds; use integer timestamps.
Future<void> insertShoppingListItemRaw(
  AppDatabase db, {
  required int categoryId,
  required int accountId,
}) async {
  final nowUnix = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
  final dateUnix = DateTime(2026, 5, 1).millisecondsSinceEpoch ~/ 1000;
  await db.customInsert(
    'INSERT INTO shopping_list_items '
    '(category_id, account_id, draft_date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?)',
    variables: [
      Variable<int>(categoryId),
      Variable<int>(accountId),
      Variable<int>(dateUnix),
      Variable<int>(nowUnix),
      Variable<int>(nowUnix),
    ],
    updates: {db.shoppingListItems},
  );
}

const Currency _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
  sortOrder: 1,
);

/// Inserts a daily USD recurring rule referencing the given category and
/// account through `DriftRecurringRulesRepository`, returning its id.
Future<int> insertRecurringRuleRaw(
  AppDatabase db, {
  required int categoryId,
  required int accountId,
}) {
  return DriftRecurringRulesRepository(
    db,
    clock: () => DateTime(2026, 5, 7),
  ).insert(
    RecurringRuleDraft(
      name: 'Rule',
      amountMinorUnits: 100,
      currency: _usd,
      categoryId: categoryId,
      accountId: accountId,
      frequency: 'daily',
    ),
    today: DateTime(2026, 5, 7),
  );
}
