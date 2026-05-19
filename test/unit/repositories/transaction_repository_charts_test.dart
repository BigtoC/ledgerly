import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' hide Currency;
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Future<void> _seedFixtures(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('EUR', 2, '€', 'currency.eur', 0, 2)",
  );
  // Two expense categories, one income category.
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (1, 'expense', 'cat.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (2, 'expense', 'cat.transport', 'car', 1, 2, 0)",
  );
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (3, 'income', 'cat.salary', 'work', 2, 3, 0)",
  );
  await db.customStatement(
    "INSERT INTO account_types (id, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO accounts (id, account_type_id, name, currency, "
    "opening_balance_minor_units, sort_order, is_archived) VALUES "
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO accounts (id, account_type_id, name, currency, "
    "opening_balance_minor_units, sort_order, is_archived) VALUES "
    "(2, 1, 'EUR Cash', 'EUR', 0, 2, 0)",
  );
}

Future<void> _insertTx(
  AppDatabase db, {
  required int id,
  required DateTime date,
  required int amountMinorUnits,
  required String currency,
  required int categoryId,
  int accountId = 1,
}) async {
  final epoch = DateTime.utc(2026).millisecondsSinceEpoch ~/ 1000;
  await db.customStatement(
    'INSERT INTO transactions (id, amount_minor_units, currency, '
    'category_id, account_id, date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      amountMinorUnits,
      currency,
      categoryId,
      accountId,
      date.millisecondsSinceEpoch ~/ 1000,
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
    repo = DriftTransactionRepository(db);
    await _seedFixtures(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchByCategoryInRange', () {
    test('groups by (categoryId, currency) within [start, end)', () async {
      await _insertTx(
        db,
        id: 1,
        date: DateTime(2026, 5, 18, 10),
        amountMinorUnits: 500,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 2,
        date: DateTime(2026, 5, 19, 12),
        amountMinorUnits: 700,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 3,
        date: DateTime(2026, 5, 20, 14),
        amountMinorUnits: 300,
        currency: 'EUR',
        categoryId: 1,
        accountId: 2,
      );
      await _insertTx(
        db,
        id: 4,
        date: DateTime(2026, 5, 21, 9),
        amountMinorUnits: 1000,
        currency: 'USD',
        categoryId: 2,
      );
      // Outside range.
      await _insertTx(
        db,
        id: 5,
        date: DateTime(2026, 5, 17, 10),
        amountMinorUnits: 9999,
        currency: 'USD',
        categoryId: 1,
      );
      // Income — excluded by type filter.
      await _insertTx(
        db,
        id: 6,
        date: DateTime(2026, 5, 19, 10),
        amountMinorUnits: 50000,
        currency: 'USD',
        categoryId: 3,
      );

      final slices = await repo
          .watchByCategoryInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 25),
            type: CategoryType.expense,
          )
          .first;

      expect(slices, hasLength(3));
      expect(
        slices
            .firstWhere((s) => s.categoryId == 1 && s.currencyCode == 'USD')
            .totalMinorUnits,
        1200,
      );
      expect(
        slices
            .firstWhere((s) => s.categoryId == 1 && s.currencyCode == 'EUR')
            .totalMinorUnits,
        300,
      );
      expect(
        slices
            .firstWhere((s) => s.categoryId == 2 && s.currencyCode == 'USD')
            .totalMinorUnits,
        1000,
      );
    });

    test('emits empty list for ranges with no transactions', () async {
      final slices = await repo
          .watchByCategoryInRange(
            start: DateTime(2026, 1, 1),
            end: DateTime(2026, 1, 8),
            type: CategoryType.expense,
          )
          .first;
      expect(slices, isEmpty);
    });
  });

  group('watchByAccountInRange', () {
    test('groups by (accountId, currency)', () async {
      await _insertTx(
        db,
        id: 1,
        date: DateTime(2026, 5, 18, 10),
        amountMinorUnits: 500,
        currency: 'USD',
        categoryId: 1,
        accountId: 1,
      );
      await _insertTx(
        db,
        id: 2,
        date: DateTime(2026, 5, 19, 12),
        amountMinorUnits: 700,
        currency: 'EUR',
        categoryId: 1,
        accountId: 2,
      );

      final slices = await repo
          .watchByAccountInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 25),
            type: CategoryType.expense,
          )
          .first;

      expect(slices, hasLength(2));
      expect(slices.firstWhere((s) => s.accountId == 1).totalMinorUnits, 500);
      expect(slices.firstWhere((s) => s.accountId == 2).totalMinorUnits, 700);
    });
  });

  group('watchByCurrencyInRange', () {
    test('sums per currency', () async {
      await _insertTx(
        db,
        id: 1,
        date: DateTime(2026, 5, 18, 10),
        amountMinorUnits: 500,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 2,
        date: DateTime(2026, 5, 19, 12),
        amountMinorUnits: 700,
        currency: 'USD',
        categoryId: 2,
      );
      await _insertTx(
        db,
        id: 3,
        date: DateTime(2026, 5, 20, 14),
        amountMinorUnits: 300,
        currency: 'EUR',
        categoryId: 1,
        accountId: 2,
      );

      final slices = await repo
          .watchByCurrencyInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 25),
            type: CategoryType.expense,
          )
          .first;

      expect(
        slices.firstWhere((s) => s.currencyCode == 'USD').totalMinorUnits,
        1200,
      );
      expect(
        slices.firstWhere((s) => s.currencyCode == 'EUR').totalMinorUnits,
        300,
      );
    });
  });

  group('watchTimeBucketsInRange', () {
    test('hour granularity buckets by local hour', () async {
      await _insertTx(
        db,
        id: 1,
        date: DateTime(2026, 5, 18, 10, 5),
        amountMinorUnits: 500,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 2,
        date: DateTime(2026, 5, 18, 10, 45),
        amountMinorUnits: 200,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 3,
        date: DateTime(2026, 5, 18, 14, 30),
        amountMinorUnits: 100,
        currency: 'USD',
        categoryId: 1,
      );

      final buckets = await repo
          .watchTimeBucketsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 19),
            type: CategoryType.expense,
            granularity: TimeBucketGranularity.hour,
          )
          .first;

      final tenAm = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 5, 18, 10),
      );
      expect(tenAm.totalMinorUnits, 700);
      final twoPm = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 5, 18, 14),
      );
      expect(twoPm.totalMinorUnits, 100);
    });

    test('day granularity buckets by startOfDay; preserves currency', () async {
      await _insertTx(
        db,
        id: 1,
        date: DateTime(2026, 5, 18, 10),
        amountMinorUnits: 500,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 2,
        date: DateTime(2026, 5, 18, 14),
        amountMinorUnits: 300,
        currency: 'EUR',
        categoryId: 1,
        accountId: 2,
      );
      await _insertTx(
        db,
        id: 3,
        date: DateTime(2026, 5, 20, 9),
        amountMinorUnits: 200,
        currency: 'USD',
        categoryId: 1,
      );

      final buckets = await repo
          .watchTimeBucketsInRange(
            start: DateTime(2026, 5, 18),
            end: DateTime(2026, 5, 25),
            type: CategoryType.expense,
            granularity: TimeBucketGranularity.day,
          )
          .first;

      expect(buckets, hasLength(3));
      final mondayUsd = buckets.firstWhere(
        (b) =>
            b.bucketStart == DateTime(2026, 5, 18) && b.currencyCode == 'USD',
      );
      expect(mondayUsd.totalMinorUnits, 500);
    });

    test('month granularity buckets by startOfMonth', () async {
      await _insertTx(
        db,
        id: 1,
        date: DateTime(2026, 1, 15, 10),
        amountMinorUnits: 500,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 2,
        date: DateTime(2026, 1, 31, 23),
        amountMinorUnits: 300,
        currency: 'USD',
        categoryId: 1,
      );
      await _insertTx(
        db,
        id: 3,
        date: DateTime(2026, 3, 5, 12),
        amountMinorUnits: 100,
        currency: 'USD',
        categoryId: 1,
      );

      final buckets = await repo
          .watchTimeBucketsInRange(
            start: DateTime(2026, 1, 1),
            end: DateTime(2027, 1, 1),
            type: CategoryType.expense,
            granularity: TimeBucketGranularity.month,
          )
          .first;

      final jan = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 1, 1),
      );
      expect(jan.totalMinorUnits, 800);
      final mar = buckets.firstWhere(
        (b) => b.bucketStart == DateTime(2026, 3, 1),
      );
      expect(mar.totalMinorUnits, 100);
    });

    test('reactive: re-emits on insert', () async {
      final stream = repo.watchTimeBucketsInRange(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 25),
        type: CategoryType.expense,
        granularity: TimeBucketGranularity.day,
      );

      final emissions = <List<TimeBucketSlice>>[];
      final sub = stream.listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));
      expect(emissions.first, isEmpty);

      // Use the repo's save() so Drift's stream-tracker sees the insert.
      // Raw customStatement inserts bypass that invalidation.
      await repo.save(
        Transaction(
          id: 0,
          amountMinorUnits: 500,
          currency: _usd,
          categoryId: 1,
          accountId: 1,
          date: DateTime(2026, 5, 19, 10),
          memo: null,
          createdAt: DateTime.utc(0),
          updatedAt: DateTime.utc(0),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.totalMinorUnits, 500);

      await sub.cancel();
    });
  });
}
