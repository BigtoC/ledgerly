// Tests for `TransactionDao.watchRecentMemosByCategory` /
// `TransactionRepository.watchRecentMemosForCategory` — the stream that
// backs the memo suggestion chips on the transaction form.

import 'package:drift/drift.dart' show TableUpdate;
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
    "'restaurant', 0, 1, 0), (2, 'expense', 'cat.transport', NULL, "
    "'bus', 0, 2, 0)",
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
  int categoryId = 1,
}) {
  // Drift stores DateTime as integer Unix seconds (default mode).
  final epoch = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
  return db.customStatement(
    'INSERT INTO transactions (id, amount_minor_units, currency, '
    'category_id, account_id, date, memo, created_at, updated_at) '
    "VALUES (?, 1000, 'USD', ?, 1, ?, ?, ?, ?)",
    <Object?>[
      id,
      categoryId,
      date.millisecondsSinceEpoch ~/ 1000,
      memo,
      epoch,
      epoch,
    ],
  );
}

void main() {
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

  test('distinct memos ordered by most recent use, not insertion', () async {
    // id order deliberately differs from date order.
    await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 3), memo: 'B');
    await _insertTx(db: db, id: 2, date: DateTime.utc(2026, 5, 1), memo: 'A');
    await _insertTx(db: db, id: 3, date: DateTime.utc(2026, 5, 2), memo: 'C');
    // Old 'A' reused most recently → 'A' moves to the front, once.
    await _insertTx(db: db, id: 4, date: DateTime.utc(2026, 5, 4), memo: 'A');

    final memos = await repo.watchRecentMemosForCategory(1, limit: 10).first;

    expect(memos, ['A', 'B', 'C']);
  });

  test('same-date ties break by newest id', () async {
    final day = DateTime.utc(2026, 5, 1);
    await _insertTx(db: db, id: 1, date: day, memo: 'first');
    await _insertTx(db: db, id: 2, date: day, memo: 'second');

    final memos = await repo.watchRecentMemosForCategory(1, limit: 10).first;

    expect(memos, ['second', 'first']);
  });

  test('same-day tiebreak uses the id of each memo\'s latest row', () async {
    final today = DateTime.utc(2026, 5, 2);
    await _insertTx(db: db, id: 90, date: today, memo: 'Lunch');
    await _insertTx(db: db, id: 100, date: today, memo: 'Coffee');
    // Backdated 'Lunch' gets the highest id but an older date; it must
    // not lift 'Lunch' above today's later 'Coffee'.
    await _insertTx(
      db: db,
      id: 101,
      date: DateTime.utc(2026, 5, 1),
      memo: 'Lunch',
    );

    final memos = await repo.watchRecentMemosForCategory(1, limit: 10).first;

    expect(memos, ['Coffee', 'Lunch']);
  });

  test('NULL, empty and whitespace-only memos are excluded', () async {
    await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 1), memo: 'ok');
    await _insertTx(db: db, id: 2, date: DateTime.utc(2026, 5, 2));
    await _insertTx(db: db, id: 3, date: DateTime.utc(2026, 5, 3), memo: '');
    await _insertTx(db: db, id: 4, date: DateTime.utc(2026, 5, 4), memo: '  ');

    final memos = await repo.watchRecentMemosForCategory(1, limit: 10).first;

    expect(memos, ['ok']);
  });

  test('memos are trimmed and deduplicated after trimming', () async {
    await _insertTx(
      db: db,
      id: 1,
      date: DateTime.utc(2026, 5, 1),
      memo: 'Lunch ',
    );
    await _insertTx(
      db: db,
      id: 2,
      date: DateTime.utc(2026, 5, 2),
      memo: ' Lunch',
    );

    final memos = await repo.watchRecentMemosForCategory(1, limit: 10).first;

    expect(memos, ['Lunch']);
  });

  test('scoped to the requested category', () async {
    await _insertTx(
      db: db,
      id: 1,
      date: DateTime.utc(2026, 5, 1),
      memo: 'groceries',
    );
    await _insertTx(
      db: db,
      id: 2,
      date: DateTime.utc(2026, 5, 2),
      memo: 'bus',
      categoryId: 2,
    );

    expect(await repo.watchRecentMemosForCategory(1, limit: 10).first, [
      'groceries',
    ]);
    expect(await repo.watchRecentMemosForCategory(2, limit: 10).first, ['bus']);
  });

  test('caps the result at limit, keeping the most recent', () async {
    for (var i = 1; i <= 12; i++) {
      await _insertTx(
        db: db,
        id: i,
        date: DateTime.utc(2026, 5, i),
        memo: 'memo $i',
      );
    }

    final memos = await repo.watchRecentMemosForCategory(1, limit: 10).first;

    expect(memos, hasLength(10));
    expect(memos.first, 'memo 12');
    expect(memos.last, 'memo 3');
  });

  test('re-emits when a transaction is written', () async {
    await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 1), memo: 'A');

    final emissions = repo
        .watchRecentMemosForCategory(1, limit: 10)
        .take(2)
        .toList();
    await pumpEventQueue();
    await _insertTx(db: db, id: 2, date: DateTime.utc(2026, 5, 2), memo: 'B');
    // Raw customStatement bypasses Drift's table-update tracking.
    db.notifyUpdates({TableUpdate.onTable(db.transactions)});

    expect(await emissions, [
      ['A'],
      ['B', 'A'],
    ]);
  });
}
