import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' hide Currency;

import '_harness/test_app_database.dart';

Future<void> _seed(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('EUR', 2, '€', 'currency.eur', 0, 2)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'expense', 'cat.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (2, 'expense', 'cat.transport', 'car', 1, 2, 0)",
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
  // Two USD expenses in food (May 18), one EUR expense in food (May 19),
  // one USD expense in transport (May 18).
  final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
  Future<void> tx(int id, DateTime d, int amt, String cur, int cat) {
    return db.customStatement(
      'INSERT INTO transactions (id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
      [id, amt, cur, cat, d.millisecondsSinceEpoch ~/ 1000, epoch, epoch],
    );
  }

  await tx(1, DateTime(2026, 5, 18, 9), 1000, 'USD', 1);
  await tx(2, DateTime(2026, 5, 18, 11), 2000, 'USD', 1);
  await tx(3, DateTime(2026, 5, 19, 12), 500, 'EUR', 1);
  await tx(4, DateTime(2026, 5, 18, 14), 7000, 'USD', 2);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestAppDatabase();
    await _seed(db);
  });
  tearDown(() async => db.close());

  group('watchChartRowsInRange with filters', () {
    test(
      'null filters preserves original behavior (all rows in range)',
      () async {
        final rows = await db.transactionDao
            .watchChartRowsInRange(
              start: DateTime(2026, 5, 18),
              end: DateTime(2026, 5, 20),
              type: 'expense',
            )
            .first;
        expect(rows, hasLength(4));
      },
    );

    test('categoryId filter scopes to that category only', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
          )
          .first;
      expect(rows, hasLength(3));
    });

    test('categoryId + currencyCode filter applies both', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
            currencyCode: 'USD',
          )
          .first;
      expect(rows, hasLength(2));
    });

    test('currencyCode-only filter scopes to that currency', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            currencyCode: 'EUR',
          )
          .first;
      expect(rows, hasLength(1));
    });

    test('accountId filter scopes to that account', () async {
      final rows = await db.transactionDao
          .watchChartRowsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            accountId: 1,
          )
          .first;
      expect(rows, hasLength(4));
    });
  });

  group('watchTransactionRowsForSliceInRange', () {
    test('category filter returns full TransactionRow objects ordered date DESC, id DESC', () async {
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
          )
          .first;
      expect(rows.map((r) => r.id).toList(), [3, 2, 1]);
    });

    test('account filter excludes wrong account', () async {
      await db.customStatement(
        'INSERT INTO accounts (id, account_type_id, name, currency, '
        'opening_balance_minor_units, sort_order, is_archived) VALUES '
        "(2, 1, 'EUR Cash', 'EUR', 0, 2, 0)",
      );
      final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
      await db.customStatement(
        'INSERT INTO transactions (id, amount_minor_units, currency, '
        'category_id, account_id, date, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          100,
          400,
          'EUR',
          1,
          2,
          DateTime(2026, 5, 18, 8).millisecondsSinceEpoch ~/ 1000,
          epoch,
          epoch,
        ],
      );
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            accountId: 1,
          )
          .first;
      expect(rows.map((r) => r.id).toSet(), {1, 2, 3, 4});
    });

    test(
      'currency-only filter (no cat/acct) scopes to that currency',
      () async {
        final rows = await db.transactionDao
            .watchTransactionRowsForSliceInRange(
              start: DateTime(2026, 5, 18),
              end: DateTime(2026, 5, 20),
              type: 'expense',
              currencyCode: 'EUR',
            )
            .first;
        expect(rows.map((r) => r.id).toList(), [3]);
      },
    );

    test('range is half-open: end-of-range row excluded', () async {
      final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
      await db.customStatement(
        'INSERT INTO transactions (id, amount_minor_units, currency, '
        'category_id, account_id, date, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
        [
          50,
          100,
          'USD',
          1,
          DateTime(2026, 5, 20).millisecondsSinceEpoch ~/ 1000,
          epoch,
          epoch,
        ],
      );
      final rows = await db.transactionDao
          .watchTransactionRowsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: 'expense',
            categoryId: 1,
          )
          .first;
      expect(rows.map((r) => r.id), isNot(contains(50)));
    });
  });
}
