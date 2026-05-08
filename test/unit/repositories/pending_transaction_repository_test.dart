import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

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
      repo = DriftPendingTransactionRepository(
        db,
        txRepo: DriftTransactionRepository(db),
      );
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

      final pendingRows = await repo.watchAll().first;
      expect(pendingRows, isEmpty);
    });

    test(
      'approve overwrites the sentinel createdAt/updatedAt timestamps',
      () async {
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

        // Drift stores DateTime as Unix-seconds, so read-back loses
        // sub-second precision. Take `before` minus 1 second to absorb the
        // truncation; the assertion still proves the timestamp landed in
        // the recent past, not at DateTime(0).
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final tx = await repo.approve(pendingId);

        expect(
          tx.createdAt.isAfter(DateTime(2000)),
          isTrue,
          reason:
              'createdAt must be overwritten by save, not left at DateTime(0)',
        );
        expect(
          tx.updatedAt.isAtSameMomentAs(tx.createdAt) ||
              tx.updatedAt.isAfter(tx.createdAt),
          isTrue,
        );
        expect(
          tx.createdAt.isAtSameMomentAs(before) || tx.createdAt.isAfter(before),
          isTrue,
        );
      },
    );

    test('approve throws when pending row does not exist', () async {
      expect(
        () => repo.approve(9999),
        throwsA(isA<PendingTransactionRepositoryException>()),
      );
    });

    test('approve throws when categoryId is null', () async {
      await db.customStatement(
        'INSERT INTO pending_transactions '
        '(source, amount_minor_units, currency, category_id, account_id, '
        'date, fetched_at, recurring_rule_id) '
        'VALUES (?, ?, ?, NULL, ?, ?, ?, ?)',
        <Object?>[
          'recurring',
          100,
          'USD',
          accountId,
          DateTime(2026, 5, 8).millisecondsSinceEpoch ~/ 1000,
          DateTime(2026, 5, 8).millisecondsSinceEpoch ~/ 1000,
          ruleId,
        ],
      );
      final rows = await db
          .customSelect(
            'SELECT id FROM pending_transactions ORDER BY id DESC LIMIT 1',
          )
          .get();
      final pendingId = rows.first.read<int>('id');

      expect(
        () => repo.approve(pendingId),
        throwsA(isA<PendingTransactionRepositoryException>()),
      );

      final dbRow = await db.pendingTransactionDao.findById(pendingId);
      expect(dbRow, isNotNull);
    });

    test('approve throws when account is archived', () async {
      await db.customStatement(
        'UPDATE accounts SET is_archived = 1 WHERE id = ?',
        <Object?>[accountId],
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

    test('approve throws when category is archived', () async {
      await db.customStatement(
        'UPDATE categories SET is_archived = 1 WHERE id = ?',
        <Object?>[categoryId],
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
        <Object?>[accountId],
      );

      final hidden = await repo.watchAll().first;
      expect(hidden, isEmpty);

      await db.customStatement(
        'UPDATE accounts SET is_archived = 0 WHERE id = ?',
        <Object?>[accountId],
      );

      final restored = await repo.watchAll().first;
      expect(restored, hasLength(1));
      expect(restored.first.id, pendingId);
    });

    test(
      'approve does NOT modify parent recurring rule next_due_date',
      () async {
        final ruleBefore = await db
            .customSelect(
              'SELECT next_due_date FROM recurring_rules WHERE id = ?',
              variables: [Variable.withInt(ruleId)],
            )
            .getSingle();
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

        final ruleAfter = await db
            .customSelect(
              'SELECT next_due_date FROM recurring_rules WHERE id = ?',
              variables: [Variable.withInt(ruleId)],
            )
            .getSingle();
        expect(ruleAfter.read<DateTime>('next_due_date'), originalDueDate);
      },
    );

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
      await repo.reject(9999);
    });

    test('reject does NOT modify parent recurring rule', () async {
      final ruleBefore = await db
          .customSelect(
            'SELECT next_due_date FROM recurring_rules WHERE id = ?',
            variables: [Variable.withInt(ruleId)],
          )
          .getSingle();
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

      final ruleAfter = await db
          .customSelect(
            'SELECT next_due_date FROM recurring_rules WHERE id = ?',
            variables: [Variable.withInt(ruleId)],
          )
          .getSingle();
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
  });
}
