// Tests for `TransactionDao.watchByMemo` and
// `TransactionRepository.watchByMemo` — analysis-search backing
// streams. Uses the shared in-memory harness; mirrors the seeding
// style of `transaction_repository_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seedMinimal(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, custom_name, icon, color, '
    "sort_order, is_archived) VALUES (1, 'expense', 'cat.food', NULL, "
    "'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO account_types (id, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO accounts (id, account_type_id, name, currency, '
    'opening_balance_minor_units, sort_order, is_archived) VALUES '
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
}

Future<void> _insertTx({
  required AppDatabase db,
  required int id,
  required DateTime date,
  String? memo,
}) {
  // Drift stores DateTime as integer Unix seconds (default mode).
  final epoch = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
  return db.customStatement(
    'INSERT INTO transactions (id, amount_minor_units, currency, '
    'category_id, account_id, date, memo, created_at, updated_at) '
    "VALUES (?, 1000, 'USD', 1, 1, ?, ?, ?, ?)",
    <Object?>[id, date.millisecondsSinceEpoch ~/ 1000, memo, epoch, epoch],
  );
}

void main() {
  group('TransactionDao.watchByMemo', () {
    late AppDatabase db;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedMinimal(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('empty query short-circuits without scanning', () async {
      await _insertTx(
        db: db,
        id: 1,
        date: DateTime.utc(2026, 5, 1),
        memo: 'coffee',
      );

      final empty = await db.transactionDao.watchByMemo('').first;
      final whitespace = await db.transactionDao.watchByMemo('   ').first;

      expect(empty, isEmpty);
      expect(whitespace, isEmpty);
    });

    test('case-insensitive substring match; NULL memo excluded', () async {
      await _insertTx(
        db: db,
        id: 1,
        date: DateTime.utc(2026, 5, 1),
        memo: 'Coffee',
      );
      await _insertTx(
        db: db,
        id: 2,
        date: DateTime.utc(2026, 5, 2),
        memo: 'COFFEE shop',
      );
      await _insertTx(
        db: db,
        id: 3,
        date: DateTime.utc(2026, 5, 3),
        memo: 'tea',
      );
      await _insertTx(
        db: db,
        id: 4,
        date: DateTime.utc(2026, 5, 4),
        memo: null,
      );

      final rows = await db.transactionDao.watchByMemo('coffee').first;

      expect(rows.map((r) => r.id).toSet(), {1, 2});
    });

    test('orders by date DESC, id DESC', () async {
      await _insertTx(
        db: db,
        id: 1,
        date: DateTime.utc(2026, 5, 1),
        memo: 'coffee A',
      );
      await _insertTx(
        db: db,
        id: 2,
        date: DateTime.utc(2026, 5, 3),
        memo: 'coffee B',
      );
      await _insertTx(
        db: db,
        id: 3,
        date: DateTime.utc(2026, 5, 3),
        memo: 'coffee C',
      );

      final rows = await db.transactionDao.watchByMemo('coffee').first;

      // 2026-05-03/id=3, 2026-05-03/id=2, 2026-05-01/id=1
      expect(rows.map((r) => r.id).toList(), [3, 2, 1]);
    });
  });

  group('TransactionRepository.watchByMemo', () {
    late AppDatabase db;
    late TransactionRepository repo;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedMinimal(db);
      repo = DriftTransactionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns domain Transactions with hydrated currency', () async {
      await _insertTx(
        db: db,
        id: 1,
        date: DateTime.utc(2026, 5, 1),
        memo: 'latte',
      );

      final txs = await repo.watchByMemo('latte').first;

      expect(txs, hasLength(1));
      expect(txs.first.id, 1);
      expect(txs.first.currency.code, 'USD');
      expect(txs.first.currency.decimals, 2);
    });

    test('empty query emits []', () async {
      await _insertTx(
        db: db,
        id: 1,
        date: DateTime.utc(2026, 5, 1),
        memo: 'latte',
      );

      expect(await repo.watchByMemo('').first, isEmpty);
    });
  });
}
