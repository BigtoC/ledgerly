import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' hide Currency;
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

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
  late TransactionRepository repo;

  setUp(() async {
    db = newTestAppDatabase();
    repo = DriftTransactionRepository(db);
    await _seed(db);
  });
  tearDown(() async => db.close());

  group('watchTransactionsForSliceInRange', () {
    test(
      'category selection returns matching rows date DESC, id DESC',
      () async {
        final txs = await repo
            .watchTransactionsForSliceInRange(
              start: DateTime(2026, 5, 18),
              end: DateTime(2026, 5, 20),
              type: CategoryType.expense,
              categoryId: 1,
            )
            .first;
        expect(txs.map((t) => t.id).toList(), [3, 2, 1]);
      },
    );

    test('category + currencyCode filters both', () async {
      final txs = await repo
          .watchTransactionsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: CategoryType.expense,
            categoryId: 1,
            currencyCode: 'USD',
          )
          .first;
      expect(txs.map((t) => t.id).toList(), [2, 1]);
    });

    test('currency selection scopes to that currency', () async {
      final txs = await repo
          .watchTransactionsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: CategoryType.expense,
            currencyCode: 'EUR',
          )
          .first;
      expect(txs.map((t) => t.id).toList(), [3]);
    });

    test('account selection scopes to that account', () async {
      final txs = await repo
          .watchTransactionsForSliceInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: CategoryType.expense,
            accountId: 1,
          )
          .first;
      expect(txs, hasLength(4));
    });

    test('stream re-emits after insert / delete', () async {
      final stream = repo.watchTransactionsForSliceInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
        categoryId: 1,
        currencyCode: 'USD',
      );
      final emissions = <int>[];
      final sub = stream.listen((rows) => emissions.add(rows.length));
      addTearDown(sub.cancel);
      // Settle the initial emission (txs 1 and 2).
      // asyncMap needs a small delay to resolve currency FK lookups.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, 2);

      // Use repo.save() so Drift's stream-tracker sees the insert
      // (customStatement bypasses stream invalidation).
      const usd = Currency(
        code: 'USD',
        decimals: 2,
        symbol: r'$',
        nameL10nKey: 'currency.usd',
        sortOrder: 1,
      );
      await repo.save(
        Transaction(
          id: 0,
          amountMinorUnits: 333,
          currency: usd,
          categoryId: 1,
          accountId: 1,
          date: DateTime(2026, 5, 18, 16),
          memo: null,
          createdAt: DateTime.utc(0),
          updatedAt: DateTime.utc(0),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, 3);

      // Delete tx1 — should drop back to 2.
      await repo.delete(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, 2);
    });
  });

  group('watchTimeBucketsInRange with filters', () {
    test('null filters preserve current behavior', () async {
      final stream = repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 20),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
      );
      final buckets = await stream.first;
      final totalsByDay = <DateTime, int>{};
      for (final b in buckets) {
        totalsByDay[b.bucketStart] =
            (totalsByDay[b.bucketStart] ?? 0) + b.totalMinorUnits;
      }
      // Food USD: 1000+2000=3000; Transport USD: 7000. May 18 total = 10000.
      expect(totalsByDay[DateTime(2026, 5, 18)], equals(10000));
    });

    test('categoryId filters buckets to that category', () async {
      final buckets = await repo
          .watchTimeBucketsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: CategoryType.expense,
            granularity: TimeBucketGranularity.day,
            categoryId: 1,
          )
          .first;
      final totalsByDay = <DateTime, int>{};
      for (final b in buckets) {
        totalsByDay[b.bucketStart] =
            (totalsByDay[b.bucketStart] ?? 0) + b.totalMinorUnits;
      }
      expect(totalsByDay[DateTime(2026, 5, 18)], equals(3000));
      expect(totalsByDay[DateTime(2026, 5, 19)], equals(500));
    });

    test('currencyCode filters buckets to that currency', () async {
      final buckets = await repo
          .watchTimeBucketsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: CategoryType.expense,
            granularity: TimeBucketGranularity.day,
            currencyCode: 'EUR',
          )
          .first;
      expect(buckets, hasLength(1));
      expect(buckets.first.totalMinorUnits, equals(500));
    });

    test('categoryId + currencyCode apply both', () async {
      final buckets = await repo
          .watchTimeBucketsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 20),
            type: CategoryType.expense,
            granularity: TimeBucketGranularity.day,
            categoryId: 1,
            currencyCode: 'USD',
          )
          .first;
      final totalsByDay = <DateTime, int>{};
      for (final b in buckets) {
        totalsByDay[b.bucketStart] =
            (totalsByDay[b.bucketStart] ?? 0) + b.totalMinorUnits;
      }
      expect(totalsByDay[DateTime(2026, 5, 18)], equals(3000));
      expect(totalsByDay.containsKey(DateTime(2026, 5, 19)), isFalse);
    });
  });
}
