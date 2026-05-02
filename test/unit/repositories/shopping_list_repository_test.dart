// Tests for `ShoppingListRepository`.
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Seeds fixtures via raw SQL (customStatement/customInsert) so these tests
// don't depend on other repository internals beyond what is already known-good.

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

// ---------------------------------------------------------------------------
// Raw-SQL fixture helpers
// ---------------------------------------------------------------------------

Future<void> _seedCurrencyUsd(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO currencies '
    '(code, decimals, symbol, name_l10n_key, is_token, sort_order) '
    'VALUES (?, ?, ?, ?, 0, ?)',
    <Object?>['USD', 2, r'$', 'currency.usd', 1],
  );
}

Future<int> _insertCategoryRaw(
  AppDatabase db, {
  String l10nKey = 'category.food',
  String icon = 'restaurant',
  String type = 'expense',
}) async {
  await db.customStatement(
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, '
    'is_archived) VALUES (?, ?, 0, ?, 1, 0)',
    <Object?>[l10nKey, icon, type],
  );
  final rows = await db
      .customSelect(
        'SELECT id FROM categories WHERE l10n_key = ?',
        variables: [Variable.withString(l10nKey)],
      )
      .get();
  return rows.first.read<int>('id');
}

Future<int> _insertAccountRaw(
  AppDatabase db, {
  String name = 'Cash',
  String currency = 'USD',
  bool archived = false,
}) async {
  // Use INSERT OR IGNORE so repeated calls with the same l10n_key are safe.
  await db.customStatement(
    'INSERT OR IGNORE INTO account_types '
    '(l10n_key, icon, color, sort_order, is_archived) '
    'VALUES (?, ?, 0, 1, 0)',
    <Object?>['accountType.cash', 'wallet'],
  );
  final typeRows = await db
      .customSelect('SELECT id FROM account_types ORDER BY id ASC LIMIT 1')
      .get();
  final typeId = typeRows.first.read<int>('id');

  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, '
    'opening_balance_minor_units, is_archived) VALUES (?, ?, ?, 0, ?)',
    <Object?>[name, typeId, currency, archived ? 1 : 0],
  );
  final rows = await db
      .customSelect('SELECT id FROM accounts ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

// Insert a minimal shopping-list item row directly via SQL.
// Returns the inserted row's id.
//
// Drift 2.x defaults to storing DateTimes as Unix seconds (integers) unless
// `storeDateTimeAsText: true` is passed to `DriftOptions`. The in-memory test
// DB uses the default (`false`), so we must insert Unix timestamps here.
Future<int> _insertShoppingListItemRaw(
  AppDatabase db, {
  required int categoryId,
  required int accountId,
  String? memo,
  int? draftAmountMinorUnits,
  String? draftCurrencyCode,
  DateTime? draftDate,
  DateTime? createdAt,
  DateTime? updatedAt,
}) async {
  int toUnix(DateTime dt) => (dt.millisecondsSinceEpoch / 1000).truncate();

  final dateUnix = toUnix(draftDate ?? DateTime.utc(2026, 5, 1));
  final nowUnix = toUnix(createdAt ?? DateTime.utc(2026, 1, 1));
  final updUnix = toUnix(updatedAt ?? createdAt ?? DateTime.utc(2026, 1, 1));

  await db.customInsert(
    'INSERT INTO shopping_list_items '
    '(category_id, account_id, memo, draft_amount_minor_units, '
    'draft_currency_code, draft_date, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable<int>(categoryId),
      Variable<int>(accountId),
      memo != null ? Variable<String>(memo) : const Variable(null),
      draftAmountMinorUnits != null
          ? Variable<int>(draftAmountMinorUnits)
          : const Variable(null),
      draftCurrencyCode != null
          ? Variable<String>(draftCurrencyCode)
          : const Variable(null),
      Variable<int>(dateUnix),
      Variable<int>(nowUnix),
      Variable<int>(updUnix),
    ],
    updates: {db.shoppingListItems},
  );

  final rows = await db
      .customSelect(
        'SELECT id FROM shopping_list_items ORDER BY id DESC LIMIT 1',
      )
      .get();
  return rows.first.read<int>('id');
}

// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late DriftShoppingListRepository repo;
  late DriftTransactionRepository txRepo;
  late int expenseCategoryId;
  late int incomeCategoryId;
  late int accountId;

  setUp(() async {
    db = newTestAppDatabase();
    txRepo = DriftTransactionRepository(db);
    repo = DriftShoppingListRepository(db, txRepo);

    await _seedCurrencyUsd(db);
    expenseCategoryId = await _insertCategoryRaw(
      db,
      l10nKey: 'category.food',
      type: 'expense',
    );
    incomeCategoryId = await _insertCategoryRaw(
      db,
      l10nKey: 'category.salary',
      icon: 'payments',
      type: 'income',
    );
    accountId = await _insertAccountRaw(db);
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // insert
  // -------------------------------------------------------------------------

  group('insert', () {
    test(
      'insert round-trips memo, amount, currency, date for an amount-bearing draft',
      () async {
        final date = DateTime(2026, 6, 15);
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          memo: 'Groceries',
          draftAmountMinorUnits: 2500,
          draftCurrencyCode: 'USD',
          draftDate: date,
        );

        expect(item.id, isNonZero);
        expect(item.categoryId, expenseCategoryId);
        expect(item.accountId, accountId);
        expect(item.memo, 'Groceries');
        expect(item.draftAmountMinorUnits, 2500);
        expect(item.draftCurrencyCode, 'USD');
        // Drift stores datetimes as Unix seconds; compare via same-moment.
        expect(
          item.draftDate.millisecondsSinceEpoch,
          date.millisecondsSinceEpoch,
        );
        expect(item.createdAt, equals(item.updatedAt));
      },
    );

    test(
      'insert zero-amount draft persists null amount/null currency',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        expect(item.draftAmountMinorUnits, isNull);
        expect(item.draftCurrencyCode, isNull);
      },
    );

    test(
      'insert normalizes zero amount with currency to null amount/null currency',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftAmountMinorUnits: 0,
          draftCurrencyCode: 'USD',
          draftDate: DateTime.utc(2026, 6, 1),
        );

        expect(item.draftAmountMinorUnits, isNull);
        expect(item.draftCurrencyCode, isNull);
      },
    );

    test(
      'insert with amount but no currency throws ShoppingListRepositoryException',
      () async {
        await expectLater(
          repo.insert(
            categoryId: expenseCategoryId,
            accountId: accountId,
            draftAmountMinorUnits: 100,
            draftCurrencyCode: null,
            draftDate: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'insert with currency but no amount throws ShoppingListRepositoryException',
      () async {
        await expectLater(
          repo.insert(
            categoryId: expenseCategoryId,
            accountId: accountId,
            draftAmountMinorUnits: null,
            draftCurrencyCode: 'USD',
            draftDate: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'insert with income category throws ShoppingListRepositoryException',
      () async {
        await expectLater(
          repo.insert(
            categoryId: incomeCategoryId,
            accountId: accountId,
            draftDate: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  group('update', () {
    test(
      'update with amount but no currency throws ShoppingListRepositoryException',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await expectLater(
          repo.update(
            item.copyWith(draftAmountMinorUnits: 100, draftCurrencyCode: null),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'update with currency but no amount throws ShoppingListRepositoryException',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await expectLater(
          repo.update(
            item.copyWith(
              draftAmountMinorUnits: null,
              draftCurrencyCode: 'USD',
            ),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'update normalizes zero amount with currency to null amount/null currency',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftAmountMinorUnits: 100,
          draftCurrencyCode: 'USD',
          draftDate: DateTime.utc(2026, 6, 1),
        );

        final updated = await repo.update(
          item.copyWith(draftAmountMinorUnits: 0, draftCurrencyCode: 'USD'),
        );

        expect(updated.draftAmountMinorUnits, isNull);
        expect(updated.draftCurrencyCode, isNull);
      },
    );

    test(
      'update with income category throws ShoppingListRepositoryException',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await expectLater(
          repo.update(item.copyWith(categoryId: incomeCategoryId)),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'update when item id does not exist throws ShoppingListRepositoryException',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        // Delete the item so the update target is gone.
        await repo.delete(item.id);

        await expectLater(
          repo.update(item.copyWith(memo: 'ghost update')),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test('update preserves createdAt and refreshes updatedAt', () async {
      // Use local (non-UTC) times because Drift stores as Unix seconds
      // and reads back as local DateTime.
      final originalClock = DateTime(2026, 1, 1, 12, 0);
      final laterClock = DateTime(2026, 3, 1, 12, 0);

      final fixedClockRepo = DriftShoppingListRepository(
        db,
        txRepo,
        clock: () => originalClock,
      );

      final inserted = await fixedClockRepo.insert(
        categoryId: expenseCategoryId,
        accountId: accountId,
        draftDate: DateTime(2026, 6, 1),
      );

      // Compare via millisecondsSinceEpoch to avoid local vs UTC mismatch.
      expect(
        inserted.createdAt.millisecondsSinceEpoch,
        originalClock.millisecondsSinceEpoch,
      );
      expect(
        inserted.updatedAt.millisecondsSinceEpoch,
        originalClock.millisecondsSinceEpoch,
      );

      // Now update using a repo with a later clock.
      final laterClockRepo = DriftShoppingListRepository(
        db,
        txRepo,
        clock: () => laterClock,
      );
      final updated = await laterClockRepo.update(
        inserted.copyWith(memo: 'Updated memo'),
      );

      expect(
        updated.createdAt.millisecondsSinceEpoch,
        originalClock.millisecondsSinceEpoch,
      ); // Preserved
      expect(
        updated.updatedAt.millisecondsSinceEpoch,
        laterClock.millisecondsSinceEpoch,
      ); // Refreshed
      expect(updated.memo, 'Updated memo');
    });
  });

  // -------------------------------------------------------------------------
  // delete
  // -------------------------------------------------------------------------

  group('delete', () {
    test('delete removes the row and returns true', () async {
      final item = await repo.insert(
        categoryId: expenseCategoryId,
        accountId: accountId,
        draftDate: DateTime.utc(2026, 6, 1),
      );

      final result = await repo.delete(item.id);
      expect(result, isTrue);
      expect(await repo.getById(item.id), isNull);
    });

    test('delete on missing id returns false', () async {
      final result = await repo.delete(99999);
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // watchAll
  // -------------------------------------------------------------------------

  group('watchAll', () {
    test('watchAll emits newest-created-at first', () async {
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 3, 1);

      await _insertShoppingListItemRaw(
        db,
        categoryId: expenseCategoryId,
        accountId: accountId,
        memo: 'older',
        createdAt: t1,
      );
      await _insertShoppingListItemRaw(
        db,
        categoryId: expenseCategoryId,
        accountId: accountId,
        memo: 'newer',
        createdAt: t2,
      );

      final items = await repo.watchAll().first;
      expect(items.length, 2);
      expect(items[0].memo, 'newer');
      expect(items[1].memo, 'older');
    });

    test('watchAll limit returns only the newest rows', () async {
      await _insertShoppingListItemRaw(
        db,
        categoryId: expenseCategoryId,
        accountId: accountId,
        memo: 'first',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await _insertShoppingListItemRaw(
        db,
        categoryId: expenseCategoryId,
        accountId: accountId,
        memo: 'second',
        createdAt: DateTime.utc(2026, 2, 1),
      );
      await _insertShoppingListItemRaw(
        db,
        categoryId: expenseCategoryId,
        accountId: accountId,
        memo: 'third',
        createdAt: DateTime.utc(2026, 3, 1),
      );
      await _insertShoppingListItemRaw(
        db,
        categoryId: expenseCategoryId,
        accountId: accountId,
        memo: 'fourth',
        createdAt: DateTime.utc(2026, 4, 1),
      );

      final items = await repo.watchAll(limit: 3).first;
      expect(items.map((item) => item.memo), ['fourth', 'third', 'second']);
    });
  });

  // -------------------------------------------------------------------------
  // watchCount
  // -------------------------------------------------------------------------

  group('watchCount', () {
    test(
      'watchCount emits current count and updates after insert/delete',
      () async {
        final snapshots = <int>[];
        final sub = repo.watchCount().listen(snapshots.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last, 0);

        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last, 1);

        await repo.delete(item.id);

        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last, 0);
      },
    );
  });

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  group('getById', () {
    test('getById returns item when found', () async {
      final item = await repo.insert(
        categoryId: expenseCategoryId,
        accountId: accountId,
        draftDate: DateTime.utc(2026, 6, 1),
      );

      final fetched = await repo.getById(item.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, item.id);
    });

    test('getById returns null when missing', () async {
      expect(await repo.getById(99999), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // convertToTransaction
  // -------------------------------------------------------------------------

  group('convertToTransaction', () {
    test(
      'convertToTransaction creates a transaction and deletes the draft atomically',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          memo: 'Atomics',
          draftAmountMinorUnits: 1500,
          draftCurrencyCode: 'USD',
          draftDate: DateTime.utc(2026, 6, 1),
        );

        final tx = await repo.convertToTransaction(
          shoppingListItemId: item.id,
          categoryId: expenseCategoryId,
          accountId: accountId,
          currencyCode: 'USD',
          amountMinorUnits: 1500,
          date: DateTime.utc(2026, 6, 1),
          memo: 'Atomics',
        );

        expect(tx, isA<Transaction>());
        expect(tx.amountMinorUnits, 1500);
        expect(tx.currency.code, 'USD');
        expect(tx.categoryId, expenseCategoryId);
        expect(tx.accountId, accountId);
        expect(tx.memo, 'Atomics');

        // Draft must be deleted.
        expect(await repo.getById(item.id), isNull);
      },
    );

    test(
      'convertToTransaction with missing draft throws ShoppingListRepositoryException',
      () async {
        await expectLater(
          repo.convertToTransaction(
            shoppingListItemId: 99999,
            categoryId: expenseCategoryId,
            accountId: accountId,
            currencyCode: 'USD',
            amountMinorUnits: 1000,
            date: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'convertToTransaction with zero amount throws and keeps the draft',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await expectLater(
          repo.convertToTransaction(
            shoppingListItemId: item.id,
            categoryId: expenseCategoryId,
            accountId: accountId,
            currencyCode: 'USD',
            amountMinorUnits: 0,
            date: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );

        expect(await repo.getById(item.id), isNotNull);
        final txCount = await db
            .customSelect('SELECT COUNT(*) AS n FROM transactions')
            .get();
        expect(txCount.first.read<int>('n'), 0);
      },
    );

    test(
      'convertToTransaction with archived account throws ShoppingListRepositoryException',
      () async {
        final archivedAccountId = await _insertAccountRaw(
          db,
          name: 'Archived Account',
          archived: true,
        );

        // Insert the draft referencing the normal account first (FK constraint
        // would prevent using archived account directly here — we insert raw).
        final itemId = await _insertShoppingListItemRaw(
          db,
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await expectLater(
          repo.convertToTransaction(
            shoppingListItemId: itemId,
            categoryId: expenseCategoryId,
            accountId: archivedAccountId,
            currencyCode: 'USD',
            amountMinorUnits: 1000,
            date: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'convertToTransaction with archived category throws ShoppingListRepositoryException',
      () async {
        // Archive the expense category.
        await db.customStatement(
          'UPDATE categories SET is_archived = 1 WHERE id = ?',
          <Object?>[expenseCategoryId],
        );

        final itemId = await _insertShoppingListItemRaw(
          db,
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        await expectLater(
          repo.convertToTransaction(
            shoppingListItemId: itemId,
            categoryId: expenseCategoryId,
            accountId: accountId,
            currencyCode: 'USD',
            amountMinorUnits: 1000,
            date: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      'convertToTransaction with income category throws ShoppingListRepositoryException',
      () async {
        // Seed a draft referencing the expense category (FK constraint prevents
        // using the income category directly as the draft's category_id).
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        // Attempt to convert using the income category — must be rejected.
        await expectLater(
          repo.convertToTransaction(
            shoppingListItemId: item.id,
            categoryId: incomeCategoryId,
            accountId: accountId,
            currencyCode: 'USD',
            amountMinorUnits: 1000,
            date: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
      },
    );

    test(
      // This tests the step-1 failure path (draft missing at existence check),
      // not a savepoint rollback mid-transaction.
      'convertToTransaction with pre-deleted draft creates no transaction row',
      () async {
        final item = await repo.insert(
          categoryId: expenseCategoryId,
          accountId: accountId,
          draftDate: DateTime.utc(2026, 6, 1),
        );

        // Pre-delete the draft so the convert will fail at step 1.
        await repo.delete(item.id);

        // The convert should fail with exception.
        await expectLater(
          repo.convertToTransaction(
            shoppingListItemId: item.id,
            categoryId: expenseCategoryId,
            accountId: accountId,
            currencyCode: 'USD',
            amountMinorUnits: 1000,
            date: DateTime.utc(2026, 6, 1),
          ),
          throwsA(isA<ShoppingListRepositoryException>()),
        );

        // And no transaction should have been created.
        final txCount = await db
            .customSelect('SELECT COUNT(*) AS n FROM transactions')
            .get();
        expect(txCount.first.read<int>('n'), 0);
      },
    );
  });
}
