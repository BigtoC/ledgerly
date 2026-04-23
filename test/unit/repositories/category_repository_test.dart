// Tests for `CategoryRepository` (M3 Stream A §6.4).
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Every case has a direct row in the §6.4 Test Plan table (C-*).
//
// Because the Phase 1 harness does not yet ship
// `TestRepoBundle.seedMinimalRepositoryFixtures()`, this file seeds the
// required fixture rows (currencies, account_type, account) directly via
// `customStatement` calls so Stream A can merge ahead of Stream C's
// harness completion.

import 'package:drift/drift.dart' show Variable;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

// ---------------------------------------------------------------------------
// Shared fixtures (mirrors transaction_repository_test.dart)
// ---------------------------------------------------------------------------

const Currency _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
  sortOrder: 1,
);

Future<_Fixtures> _seedFixtures(AppDatabase db) async {
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

  return _Fixtures(
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

class _Fixtures {
  const _Fixtures({
    required this.expenseCategoryId,
    required this.incomeCategoryId,
    required this.accountTypeId,
    required this.accountId,
  });

  final int expenseCategoryId;
  final int incomeCategoryId;
  final int accountTypeId;
  final int accountId;
}

// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  late AppDatabase db;
  late _Fixtures fixtures;
  late CategoryRepository catRepo;
  late TransactionRepository txRepo;
  late DateTime frozenNow;

  setUp(() async {
    frozenNow = DateTime(2026, 4, 22, 12, 0);
    db = newTestAppDatabase();
    fixtures = await _seedFixtures(db);
    catRepo = DriftCategoryRepository(db);
    txRepo = DriftTransactionRepository(db, clock: () => frozenNow);
  });

  tearDown(() async {
    await db.close();
  });

  Transaction sampleTx({int? categoryId}) {
    return Transaction(
      id: 0,
      amountMinorUnits: 100,
      currency: _usd,
      categoryId: categoryId ?? fixtures.expenseCategoryId,
      accountId: fixtures.accountId,
      date: frozenNow,
      createdAt: DateTime.utc(0),
      updatedAt: DateTime.utc(0),
    );
  }

  group('save / getById', () {
    test('C-happy-01: insert a custom expense category', () async {
      const custom = Category(
        id: 0,
        icon: 'travel',
        color: 3,
        type: CategoryType.expense,
      );
      final inserted = await catRepo.save(custom);
      expect(inserted.id, isNot(0));

      final fetched = await catRepo.getById(inserted.id);
      expect(fetched, isNotNull);
      expect(fetched!.type, CategoryType.expense);
      expect(fetched.icon, 'travel');
      expect(fetched.color, 3);
      expect(fetched.l10nKey, isNull);
      expect(fetched.isArchived, isFalse);
    });
  });

  group('getByL10nKey', () {
    test('C-happy-02: seeded lookup returns row; unknown key → null', () async {
      final found = await catRepo.getByL10nKey('category.food');
      expect(found, isNotNull);
      expect(found!.l10nKey, 'category.food');
      expect(found.type, CategoryType.expense);

      final miss = await catRepo.getByL10nKey('not.a.key');
      expect(miss, isNull);
    });
  });

  group('upsertSeeded', () {
    test('C-seed-01: seeds category.food into an empty DB', () async {
      // Fresh DB without the pre-seeded categories.
      final freshDb = newTestAppDatabase();
      addTearDown(freshDb.close);
      await freshDb.customStatement(
        'INSERT INTO currencies (code, decimals, symbol, is_token, sort_order) '
        'VALUES (?, ?, ?, 0, ?)',
        <Object?>['USD', 2, r'$', 1],
      );
      final fresh = DriftCategoryRepository(freshDb);

      final row = await fresh.upsertSeeded(
        l10nKey: 'category.food',
        icon: 'restaurant',
        color: 0,
        type: CategoryType.expense,
        sortOrder: 1,
      );
      expect(row.l10nKey, 'category.food');
      expect(row.type, CategoryType.expense);
      expect(row.icon, 'restaurant');
      expect(row.color, 0);
      expect(row.sortOrder, 1);
      expect(row.isArchived, isFalse);
    });

    test('C-seed-02: re-running seed is idempotent', () async {
      final first = await catRepo.upsertSeeded(
        l10nKey: 'category.food',
        icon: 'restaurant',
        color: 0,
        type: CategoryType.expense,
        sortOrder: 1,
      );
      final second = await catRepo.upsertSeeded(
        l10nKey: 'category.food',
        icon: 'dining', // Icon / color bumped by a re-seed.
        color: 5,
        type: CategoryType.expense,
        sortOrder: 1,
      );

      expect(second.id, first.id); // Same logical row.
      expect(second.icon, 'dining');
      expect(second.color, 5);

      // No duplicate row.
      final rows = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM categories WHERE l10n_key = ?',
            variables: <Variable<Object>>[Variable.withString('category.food')],
          )
          .get();
      expect(rows.first.read<int>('n'), 1);
    });

    test('preserves customName on re-seed', () async {
      await catRepo.rename(fixtures.expenseCategoryId, 'Meals');
      await catRepo.upsertSeeded(
        l10nKey: 'category.food',
        icon: 'dining',
        color: 7,
        type: CategoryType.expense,
        sortOrder: 1,
      );
      final row = await catRepo.getById(fixtures.expenseCategoryId);
      expect(row!.customName, 'Meals');
      expect(row.icon, 'dining');
    });
  });

  group('watchAll', () {
    test('C-stream-01: default watch emits seeded categories', () async {
      final rows = await catRepo.watchAll().first;
      expect(rows, hasLength(2));
      // Ordered by sort_order ASC.
      expect(rows[0].l10nKey, 'category.food');
      expect(rows[1].l10nKey, 'category.salary');
    });

    test('C-stream-02: type filter emits only matching rows', () async {
      final expenses = await catRepo.watchAll(type: CategoryType.expense).first;
      expect(expenses.map((c) => c.l10nKey), ['category.food']);

      final incomes = await catRepo.watchAll(type: CategoryType.income).first;
      expect(incomes.map((c) => c.l10nKey), ['category.salary']);
    });

    test('C-stream-03: archive flag toggles visibility', () async {
      await catRepo.archive(fixtures.expenseCategoryId);

      final visible = await catRepo.watchAll().first;
      expect(visible.map((c) => c.l10nKey), ['category.salary']);

      final all = await catRepo.watchAll(includeArchived: true).first;
      expect(all.map((c) => c.l10nKey).toSet(), {
        'category.food',
        'category.salary',
      });
    });

    test('C-stream-04: type + includeArchived composite filter', () async {
      await catRepo.archive(fixtures.incomeCategoryId);

      final archivedIncomes = await catRepo
          .watchAll(type: CategoryType.income, includeArchived: true)
          .first;
      expect(archivedIncomes.length, 1);
      expect(archivedIncomes.single.l10nKey, 'category.salary');
      expect(archivedIncomes.single.isArchived, isTrue);
    });
  });

  group('save → type lock (G5)', () {
    test('C-type-lock-01: unreferenced → type flip succeeds', () async {
      final cat = await catRepo.getById(fixtures.expenseCategoryId);
      final flipped = await catRepo.save(
        cat!.copyWith(type: CategoryType.income),
      );
      expect(flipped.type, CategoryType.income);

      final stored = await catRepo.getById(fixtures.expenseCategoryId);
      expect(stored!.type, CategoryType.income);
    });

    test(
      'C-type-lock-02: referenced → type flip throws, row unchanged',
      () async {
        await txRepo.save(sampleTx(categoryId: fixtures.expenseCategoryId));

        final cat = await catRepo.getById(fixtures.expenseCategoryId);
        await expectLater(
          catRepo.save(cat!.copyWith(type: CategoryType.income)),
          throwsA(
            isA<CategoryTypeLockedException>().having(
              (e) => e.id,
              'id',
              fixtures.expenseCategoryId,
            ),
          ),
        );

        // Row untouched.
        final stored = await catRepo.getById(fixtures.expenseCategoryId);
        expect(stored!.type, CategoryType.expense);
      },
    );
  });

  group('archive (G6)', () {
    test('C-archive-01: archive hides from default watch', () async {
      final archived = await catRepo.archive(fixtures.expenseCategoryId);
      expect(archived.isArchived, isTrue);

      final visible = await catRepo.watchAll().first;
      expect(visible.map((c) => c.id), isNot(contains(archived.id)));

      final all = await catRepo.watchAll(includeArchived: true).first;
      expect(all.map((c) => c.id), contains(archived.id));
    });

    test('C-archive-02: archive is idempotent', () async {
      final first = await catRepo.archive(fixtures.expenseCategoryId);
      final second = await catRepo.archive(fixtures.expenseCategoryId);
      expect(second.id, first.id);
      expect(second.isArchived, isTrue);
    });
  });

  group('delete (G6)', () {
    test(
      'C-delete-01: unused custom category → hard-delete succeeds',
      () async {
        const custom = Category(
          id: 0,
          icon: 'misc',
          color: 2,
          type: CategoryType.expense,
        );
        final inserted = await catRepo.save(custom);
        final removed = await catRepo.delete(inserted.id);
        expect(removed, isTrue);
        expect(await catRepo.getById(inserted.id), isNull);
      },
    );

    test('C-delete-02: used category → CategoryInUseException', () async {
      await txRepo.save(sampleTx(categoryId: fixtures.expenseCategoryId));
      await expectLater(
        catRepo.delete(fixtures.expenseCategoryId),
        throwsA(
          isA<CategoryInUseException>().having(
            (e) => e.id,
            'id',
            fixtures.expenseCategoryId,
          ),
        ),
      );
      // Row still present.
      final row = await catRepo.getById(fixtures.expenseCategoryId);
      expect(row, isNotNull);
    });

    test(
      'C-delete-03: unused seeded category cannot be hard-deleted',
      () async {
        await expectLater(
          catRepo.delete(fixtures.expenseCategoryId),
          throwsA(isA<Exception>()),
        );

        final row = await catRepo.getById(fixtures.expenseCategoryId);
        expect(row, isNotNull);
        expect(row!.l10nKey, 'category.food');
      },
    );
  });

  group('rename (G7)', () {
    test('C-rename-01: rename preserves l10nKey', () async {
      final renamed = await catRepo.rename(fixtures.expenseCategoryId, 'Meals');
      expect(renamed.customName, 'Meals');
      expect(renamed.l10nKey, 'category.food');
    });

    test('C-rename-02: null clears the override', () async {
      await catRepo.rename(fixtures.expenseCategoryId, 'Meals');
      final cleared = await catRepo.rename(fixtures.expenseCategoryId, null);
      expect(cleared.customName, isNull);
      expect(cleared.l10nKey, 'category.food');
    });

    test('C-rename-03: whitespace normalizes to null', () async {
      final row = await catRepo.rename(fixtures.expenseCategoryId, '   ');
      expect(row.customName, isNull);
    });
  });

  group('save → l10nKey lock (G7 defence)', () {
    test('C-l10nkey-lock-01: mutating l10nKey via save throws', () async {
      final cat = await catRepo.getById(fixtures.expenseCategoryId);
      await expectLater(
        catRepo.save(cat!.copyWith(l10nKey: 'category.different')),
        throwsA(isA<CategoryRepositoryException>()),
      );

      // Stored l10nKey unchanged.
      final stored = await catRepo.getById(fixtures.expenseCategoryId);
      expect(stored!.l10nKey, 'category.food');
    });
  });

  group('isReferenced', () {
    test('C-isref-01: unused category returns false', () async {
      final refd = await catRepo.isReferenced(fixtures.expenseCategoryId);
      expect(refd, isFalse);
    });

    test('C-isref-02: one referencing transaction → true', () async {
      await txRepo.save(sampleTx(categoryId: fixtures.expenseCategoryId));
      final refd = await catRepo.isReferenced(fixtures.expenseCategoryId);
      expect(refd, isTrue);
    });
  });
}
