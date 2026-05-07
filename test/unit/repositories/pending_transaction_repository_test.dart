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
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, '
    'is_archived) VALUES (?, ?, ?, ?, ?, ?)',
    <Object?>['cat.test', 'tag', 0, 'expense', 1, 0],
  );
  final rows = await db
      .customSelect('SELECT id FROM categories ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

Future<int> _insertAccountRaw(AppDatabase db) async {
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

Future<int> _insertRuleRaw(
  AppDatabase db, {
  required int categoryId,
  required int accountId,
}) async {
  await db.customStatement(
    'INSERT INTO recurring_rules (name, amount_minor_units, currency, '
    'category_id, account_id, frequency, is_active, is_archived, '
    'next_due_date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, 1, 0, 0, 0, 0)',
    <Object?>['Test', 100, 'USD', categoryId, accountId, 'daily'],
  );
  final rows = await db
      .customSelect('SELECT id FROM recurring_rules ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

void main() {
  group('PendingTransactionRepository', () {
    late AppDatabase db;
    late DriftPendingTransactionRepository repo;
    late int categoryId;
    late int accountId;
    late int ruleId;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedCurrencyUsd(db);
      categoryId = await _insertCategoryRaw(db);
      accountId = await _insertAccountRaw(db);
      ruleId = await _insertRuleRaw(
        db,
        categoryId: categoryId,
        accountId: accountId,
      );
      repo = DriftPendingTransactionRepository(db);
    });

    tearDown(() async => db.close());

    test('insert and check existence', () async {
      expect(
        await repo.existsForRuleAndDate(ruleId, DateTime(2026, 5, 7)),
        isFalse,
      );

      await repo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: 'USD',
        categoryId: categoryId,
        accountId: accountId,
        date: DateTime(2026, 5, 7),
        fetchedAt: DateTime(2026, 5, 7),
        recurringRuleId: ruleId,
      );

      expect(
        await repo.existsForRuleAndDate(ruleId, DateTime(2026, 5, 7)),
        isTrue,
      );
      expect(
        await repo.existsForRuleAndDate(ruleId, DateTime(2026, 5, 8)),
        isFalse,
      );
      expect(
        await repo.existsForRuleAndDate(ruleId + 999, DateTime(2026, 5, 7)),
        isFalse,
      );
    });

    test(
      'countByRecurringRule counts only matching rule + recurring source',
      () async {
        expect(await repo.countByRecurringRule(ruleId), 0);

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
          amountMinorUnits: 100,
          currencyCode: 'USD',
          categoryId: categoryId,
          accountId: accountId,
          date: DateTime(2026, 6, 7),
          fetchedAt: DateTime(2026, 6, 7),
          recurringRuleId: ruleId,
        );

        expect(await repo.countByRecurringRule(ruleId), 2);
        expect(await repo.countByRecurringRule(ruleId + 999), 0);
      },
    );
  });
}
