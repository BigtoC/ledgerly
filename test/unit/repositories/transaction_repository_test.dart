// Tests for `TransactionRepository` (M3 Stream A §6.3).
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Every case has a direct row in the §6.3 Test Plan table (T-*).
//
// Because the Phase 1 harness does not yet ship
// `TestRepoBundle.seedMinimalRepositoryFixtures()`, this file seeds the
// required fixture rows (currencies, categories, account_type, account)
// directly via `customStatement` calls so Stream A can merge ahead of
// Stream C's harness completion.

import 'package:drift/drift.dart'
    show
        ApplyInterceptor,
        QueryExecutor,
        QueryInterceptor,
        Variable,
        driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

const Currency _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
  sortOrder: 1,
);

/// Seeds the minimal fixture surface Stream A needs:
///   - currencies: USD(2), JPY(0), TWD(2)
///   - categories: one seeded expense + one seeded income
///   - account_types: one `cash` row
///   - accounts: one USD Cash account (id = 1)
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

  // account_types row.
  await db.customStatement(
    'INSERT INTO account_types (l10n_key, icon, color, sort_order, '
    'is_archived) VALUES (?, ?, 0, 1, 0)',
    <Object?>['accountType.cash', 'wallet'],
  );
  final accountTypeRows = await db
      .customSelect('SELECT id FROM account_types')
      .get();
  final accountTypeId = accountTypeRows.first.read<int>('id');

  // One USD Cash account.
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

Future<int> _insertAccountRaw(
  AppDatabase db, {
  required String name,
  required int accountTypeId,
  required String currencyCode,
}) async {
  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, '
    'opening_balance_minor_units, is_archived) VALUES (?, ?, ?, 0, 0)',
    <Object?>[name, accountTypeId, currencyCode],
  );
  final rows = await db
      .customSelect(
        'SELECT id FROM accounts WHERE name = ?',
        variables: <Variable<Object>>[Variable.withString(name)],
      )
      .get();
  return rows.last.read<int>('id');
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

class _SelectCountingInterceptor extends QueryInterceptor {
  final statements = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements.add(statement);
    return super.runSelect(executor, statement, args);
  }
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
  late TransactionRepository txRepo;
  // Pinned inside setUp because DateTime is not const.
  late DateTime frozenNow;

  setUp(() async {
    frozenNow = DateTime(2026, 4, 22, 12, 0);
    db = newTestAppDatabase();
    fixtures = await _seedFixtures(db);
    txRepo = DriftTransactionRepository(db, clock: () => frozenNow);
  });

  tearDown(() async {
    await db.close();
  });

  Transaction sampleTx({
    int amount = 1234,
    DateTime? date,
    Currency currency = _usd,
    int? categoryId,
    int? accountId,
    String? memo,
  }) {
    return Transaction(
      id: 0,
      amountMinorUnits: amount,
      currency: currency,
      categoryId: categoryId ?? fixtures.expenseCategoryId,
      accountId: accountId ?? fixtures.accountId,
      date: date ?? frozenNow,
      memo: memo,
      // Placeholders; repo overwrites on insert.
      createdAt: DateTime.utc(0),
      updatedAt: DateTime.utc(0),
    );
  }

  group('save / getById', () {
    test('T-happy-01: insert a valid USD expense', () async {
      final inserted = await txRepo.save(sampleTx(amount: 1234));
      expect(inserted.id, isNot(0));
      expect(inserted.amountMinorUnits, 1234);
      expect(inserted.currency.code, 'USD');

      final fetched = await txRepo.getById(inserted.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, inserted.id);
      expect(fetched.amountMinorUnits, 1234);
      expect(fetched.categoryId, fixtures.expenseCategoryId);
      expect(fetched.accountId, fixtures.accountId);

      final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
      final dayRows = await txRepo.watchByDay(today).first;
      expect(dayRows.length, 1);
      expect(dayRows.single.id, inserted.id);
    });

    test('T-happy-02: round-trip memo == null', () async {
      final inserted = await txRepo.save(sampleTx(memo: null));
      final fetched = await txRepo.getById(inserted.id);
      expect(fetched!.memo, isNull);
    });
  });

  group('watchByDay', () {
    test('T-day-01: today-only emission; reverse-chronological', () async {
      final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
      final yesterday = today.subtract(const Duration(days: 1));

      await txRepo.save(
        sampleTx(amount: 100, date: today.add(const Duration(hours: 9))),
      );
      await txRepo.save(
        sampleTx(amount: 999, date: yesterday.add(const Duration(hours: 10))),
      );
      final later = await txRepo.save(
        sampleTx(amount: 200, date: today.add(const Duration(hours: 15))),
      );

      final rows = await txRepo.watchByDay(today).first;
      expect(rows.length, 2);
      // Reverse-chronological within the day: `later` first.
      expect(rows.first.id, later.id);
      expect(rows.map((t) => t.amountMinorUnits), [200, 100]);
    });

    test('T-day-02: delete reflects in next stream emission', () async {
      final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
      final inserted = await txRepo.save(sampleTx(amount: 100, date: today));
      final emissions = <List<Transaction>>[];
      final sub = txRepo.watchByDay(today).listen(emissions.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.length, 1);
      expect(emissions.last.single.id, inserted.id);

      await txRepo.delete(inserted.id);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, isEmpty);
    });

    test('T-day-03: local-timezone boundary at midnight', () async {
      // 23:59:59 on the 22nd → in-window.
      final lateOn22 = DateTime(2026, 4, 22, 23, 59, 59);
      // 00:00:00 on the 23rd → out-of-window for a watchByDay(22nd).
      final startOf23 = DateTime(2026, 4, 23, 0, 0, 0);

      await txRepo.save(sampleTx(amount: 1, date: lateOn22));
      await txRepo.save(sampleTx(amount: 2, date: startOf23));

      final rows22 = await txRepo.watchByDay(DateTime(2026, 4, 22)).first;
      expect(rows22.length, 1);
      expect(rows22.single.amountMinorUnits, 1);

      final rows23 = await txRepo.watchByDay(DateTime(2026, 4, 23)).first;
      expect(rows23.length, 1);
      expect(rows23.single.amountMinorUnits, 2);
    });

    test('T-day-04: DST change still ends at next local midnight', () async {
      final day = DateTime(2026, 3, 8);
      final nextMidnight = DateTime(2026, 3, 9);

      // This assertion is meaningful only in time zones where the process sees
      // a DST transition on 2026-03-08. We run it explicitly under
      // `TZ=America/New_York` in verification.
      if (day.timeZoneOffset == nextMidnight.timeZoneOffset) {
        return;
      }

      await txRepo.save(sampleTx(amount: 1, date: DateTime(2026, 3, 9, 0, 30)));

      final rows = await txRepo.watchByDay(day).first;
      expect(rows, isEmpty);
    });
  });

  group('watchDaysWithActivity', () {
    test(
      'T-days-01: three distinct days, newest first, no duplicates',
      () async {
        final day1 = DateTime(2026, 4, 20, 10);
        final day2 = DateTime(2026, 4, 21, 10);
        final day3 = DateTime(2026, 4, 22, 10);

        // Insert one per day + a second one on day2 to prove de-dup.
        await txRepo.save(sampleTx(date: day1));
        await txRepo.save(sampleTx(date: day2));
        await txRepo.save(sampleTx(date: day2.add(const Duration(hours: 4))));
        await txRepo.save(sampleTx(date: day3));

        final days = await txRepo.watchDaysWithActivity().first;
        expect(days, hasLength(3));
        expect(days[0], DateTime(2026, 4, 22));
        expect(days[1], DateTime(2026, 4, 21));
        expect(days[2], DateTime(2026, 4, 20));
      },
    );

    test('T-days-02: same day from two accounts emits one day', () async {
      final day = DateTime(2026, 4, 22, 10);
      final otherAccountId = await _insertAccountRaw(
        db,
        name: 'Second',
        accountTypeId: fixtures.accountTypeId,
        currencyCode: 'USD',
      );
      await txRepo.save(sampleTx(date: day));
      await txRepo.save(sampleTx(date: day, accountId: otherAccountId));

      final days = await txRepo.watchDaysWithActivity().first;
      expect(days, hasLength(1));
      expect(days.single, DateTime(2026, 4, 22));
    });

    test(
      'T-days-03: groups UTC instants by the host local-day boundary',
      () async {
        final localMidnight = DateTime(2026, 4, 22);
        // Convert a pair of local instants around midnight into UTC so this
        // assertion stays valid on every host timezone (including CI in UTC).
        final justBeforeLocalMidnight = localMidnight
            .subtract(const Duration(minutes: 30))
            .toUtc();
        final justAfterLocalMidnight = localMidnight
            .add(const Duration(minutes: 30))
            .toUtc();

        await txRepo.save(sampleTx(date: justBeforeLocalMidnight));
        await txRepo.save(sampleTx(date: justAfterLocalMidnight));

        final days = await txRepo.watchDaysWithActivity().first;
        expect(days, [DateTime(2026, 4, 22), DateTime(2026, 4, 21)]);
      },
    );
  });

  group('watchForAccount / watchForCategory', () {
    test(
      'T-stream-02: watchForAccount only emits target account rows',
      () async {
        final otherAccountId = await _insertAccountRaw(
          db,
          name: 'Second',
          accountTypeId: fixtures.accountTypeId,
          currencyCode: 'USD',
        );
        final inA = await txRepo.save(sampleTx(amount: 100));
        final inB = await txRepo.save(
          sampleTx(amount: 200, accountId: otherAccountId),
        );

        final forA = await txRepo.watchForAccount(fixtures.accountId).first;
        expect(forA.map((t) => t.id), [inA.id]);

        final forB = await txRepo.watchForAccount(otherAccountId).first;
        expect(forB.map((t) => t.id), [inB.id]);
      },
    );

    test(
      'T-stream-03: watchForCategory only emits target category rows',
      () async {
        final expenseTx = await txRepo.save(
          sampleTx(amount: 100, categoryId: fixtures.expenseCategoryId),
        );
        final incomeTx = await txRepo.save(
          sampleTx(amount: 999, categoryId: fixtures.incomeCategoryId),
        );

        final forExpense = await txRepo
            .watchForCategory(fixtures.expenseCategoryId)
            .first;
        expect(forExpense.map((t) => t.id), [expenseTx.id]);

        final forIncome = await txRepo
            .watchForCategory(fixtures.incomeCategoryId)
            .first;
        expect(forIncome.map((t) => t.id), [incomeTx.id]);
      },
    );
  });

  group('save → currency FK', () {
    test(
      'T-currency-fk-01: unknown currency throws, no row inserted',
      () async {
        const unknown = Currency(code: 'XXX', decimals: 2);
        await expectLater(
          txRepo.save(sampleTx(currency: unknown)),
          throwsA(
            isA<CurrencyNotFoundException>().having(
              (e) => e.code,
              'code',
              'XXX',
            ),
          ),
        );

        final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
        final rows = await txRepo.watchByDay(today).first;
        expect(rows, isEmpty);
      },
    );

    test(
      'T-currency-fk-02: account/transaction currency mismatch throws, no row inserted',
      () async {
        await expectLater(
          txRepo.save(
            sampleTx(
              currency: const Currency(
                code: 'JPY',
                decimals: 0,
                symbol: '¥',
                nameL10nKey: 'currency.jpy',
                sortOrder: 2,
              ),
            ),
          ),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.message,
              'message',
              'Transaction currency JPY must match account ${fixtures.accountId} '
                  'currency USD.',
            ),
          ),
        );

        final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
        final rows = await txRepo.watchByDay(today).first;
        expect(rows, isEmpty);
      },
    );
  });

  group('save → timestamps', () {
    test(
      'T-timestamps-01: insert sets createdAt == updatedAt == frozenNow',
      () async {
        final inserted = await txRepo.save(sampleTx());
        expect(inserted.createdAt, frozenNow);
        expect(inserted.updatedAt, frozenNow);
      },
    );

    test(
      'T-timestamps-02: update refreshes updatedAt; preserves createdAt',
      () async {
        final inserted = await txRepo.save(sampleTx(amount: 100));
        final later = frozenNow.add(const Duration(hours: 1));
        frozenNow = later;

        final updated = await txRepo.save(
          inserted.copyWith(amountMinorUnits: 250),
        );
        expect(updated.createdAt, isNot(later));
        expect(updated.updatedAt, later);

        // Re-fetch and confirm persisted.
        final fetched = await txRepo.getById(inserted.id);
        expect(fetched!.createdAt, inserted.createdAt);
        expect(fetched.updatedAt, later);
        expect(fetched.amountMinorUnits, 250);
      },
    );

    test(
      'T-timestamps-03: mangled incoming createdAt does not corrupt stored',
      () async {
        final inserted = await txRepo.save(sampleTx(amount: 100));
        final originalCreated = inserted.createdAt;
        final later = frozenNow.add(const Duration(hours: 2));
        frozenNow = later;

        final mangledEpoch = DateTime.fromMillisecondsSinceEpoch(0);
        await txRepo.save(
          inserted.copyWith(amountMinorUnits: 999, createdAt: mangledEpoch),
        );

        final fetched = await txRepo.getById(inserted.id);
        expect(fetched!.createdAt, originalCreated);
        expect(fetched.updatedAt, later);
      },
    );
  });

  group('delete', () {
    test('T-delete-01: delete existing row → true, row gone', () async {
      final inserted = await txRepo.save(sampleTx());
      final removed = await txRepo.delete(inserted.id);
      expect(removed, isTrue);
      expect(await txRepo.getById(inserted.id), isNull);

      final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
      final rows = await txRepo.watchByDay(today).first;
      expect(rows, isEmpty);
    });

    test('T-delete-02: delete non-existent id → false, no exception', () async {
      final removed = await txRepo.delete(9999);
      expect(removed, isFalse);
    });
  });

  group('duplicate', () {
    test('T-duplicate-01: copies all fields except id / timestamps', () async {
      final source = await txRepo.save(
        sampleTx(
          amount: 500,
          memo: 'lunch',
          categoryId: fixtures.expenseCategoryId,
        ),
      );
      final dup = await txRepo.duplicate(source.id);

      expect(dup.id, isNot(source.id));
      expect(dup.amountMinorUnits, source.amountMinorUnits);
      expect(dup.currency.code, source.currency.code);
      expect(dup.categoryId, source.categoryId);
      expect(dup.accountId, source.accountId);
      expect(dup.memo, source.memo);
      expect(dup.date, source.date);
    });

    test('T-duplicate-02: duplicate sets fresh timestamps', () async {
      final source = await txRepo.save(sampleTx());
      final later = frozenNow.add(const Duration(hours: 3));
      frozenNow = later;
      final dup = await txRepo.duplicate(source.id);
      expect(dup.createdAt, later);
      expect(dup.updatedAt, later);
      expect(dup.createdAt, isNot(source.createdAt));
    });

    test('T-duplicate-03: missing source id throws', () async {
      await expectLater(
        txRepo.duplicate(9999),
        throwsA(isA<TransactionRepositoryException>()),
      );
    });
  });

  group('save → money', () {
    test('T-amount-int-01: ETH-scale minor units round-trip exactly', () async {
      // Seed ETH currency.
      await db.customStatement(
        'INSERT INTO currencies (code, decimals, symbol, is_token, '
        'sort_order) VALUES (?, ?, ?, 1, ?)',
        <Object?>['ETH', 18, 'Ξ', 100],
      );
      final ethAccountId = await _insertAccountRaw(
        db,
        name: 'ETH wallet',
        accountTypeId: fixtures.accountTypeId,
        currencyCode: 'ETH',
      );
      const eth = Currency(code: 'ETH', decimals: 18, isToken: true);
      const bigAmount = 1500000000000000000; // 1.5 ETH in wei

      final inserted = await txRepo.save(
        sampleTx(
          amount: bigAmount,
          currency: eth,
          accountId: ethAccountId,
        ),
      );
      expect(inserted.amountMinorUnits, bigAmount);

      final fetched = await txRepo.getById(inserted.id);
      expect(fetched!.amountMinorUnits, bigAmount);
    });
  });

  // Sanity-tests that watchByDay emits when a save happens mid-subscription.
  group('reactive emissions', () {
    test('watchByDay re-emits after save', () async {
      final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
      final emissions = <List<Transaction>>[];
      final sub = txRepo.watchByDay(today).listen(emissions.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);

      await txRepo.save(sampleTx(amount: 1));
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.length, 1);
    });
  });

  group('read-path batching', () {
    test('watchByDay resolves each currency code once per snapshot', () async {
      final interceptor = _SelectCountingInterceptor();
      final executor = NativeDatabase.memory();
      final countedDb = AppDatabase(executor.interceptWith(interceptor));
      addTearDown(() async => countedDb.close());

      final countedFixtures = await _seedFixtures(countedDb);
      final countedRepo = DriftTransactionRepository(
        countedDb,
        clock: () => DateTime(2026, 4, 22, 12, 0),
      );

      Future<Transaction> insert(int amount) {
        return countedRepo.save(
          Transaction(
            id: 0,
            amountMinorUnits: amount,
            currency: _usd,
            categoryId: countedFixtures.expenseCategoryId,
            accountId: countedFixtures.accountId,
            date: DateTime(2026, 4, 22, 9, amount),
            memo: null,
            createdAt: DateTime.utc(0),
            updatedAt: DateTime.utc(0),
          ),
        );
      }

      await insert(1);
      await insert(2);
      await insert(3);
      interceptor.statements.clear();

      final rows = await countedRepo.watchByDay(DateTime(2026, 4, 22)).first;

      expect(rows, hasLength(3));
      final currencySelects = interceptor.statements
          .where((sql) => sql.contains('FROM "currencies"'))
          .length;
      expect(currencySelects, 1);
    });
  });
}
