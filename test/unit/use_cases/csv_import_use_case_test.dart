// Use-case tests for [CsvImportUseCase]: load (parse, currency lookup,
// rounding, multiset dedup) and the atomic commit. Real repositories on
// an in-memory seeded `AppDatabase`; only the file picker is faked.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/data/database/app_database.dart'
    show AppDatabase, TransactionRow;
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/csv_import.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/seed/first_run_seed.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';
import 'package:ledgerly/domain/use_cases/csv_import_use_case.dart';

import '../../support/test_app.dart';

const _samplePath = 'test/data/import_fortune_city_data.csv';
const _header = 'Account,Category,Amount,Currency,Recorded At,note,Account ID';
const _salaryNotes = {'Salary', '薪資', '薪资'};

class _FakeCsvFileService(final Future<PickedFile?> Function() _pick)
    implements CsvFileService {
  @override
  Future<PickedFile?> pick() => _pick();

  @override
  Future<bool> save(String fileName, Uint8List bytes) =>
      throw UnimplementedError();
}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

_FakeCsvFileService _serviceFor(Uint8List bytes, {String name = 'a.csv'}) =>
    _FakeCsvFileService(() async => (name: name, bytes: bytes));

Uint8List _csv(List<String> rows) =>
    Uint8List.fromList(utf8.encode([_header, ...rows].join('\n')));

/// [n] rows newest first, as the export orders them, three per minute so
/// a minute straddles each 1,000-row chunk boundary. Row `i` costs `i + 1`
/// HKD, so a stored row's line is `amountMinorUnits ~/ 100 + 1`.
List<String> _rowsNewestFirst(
  int n, {
  String account = 'Cash',
  String category = '食物',
}) {
  final rows = <String>[];
  for (var i = 0; i < n; i++) {
    final t = DateTime(2026).add(Duration(minutes: (n - 1 - i) ~/ 3));
    final minute = t.minute.toString().padLeft(2, '0');
    rows.add(
      '$account,$category,${i + 1},HKD,'
      '${t.year}/${t.month}/${t.day} ${t.hour}:$minute,,0',
    );
  }
  return rows;
}

void main() {
  late AppDatabase db;
  late CurrencyRepository currencies;
  late CategoryRepository categories;
  late AccountTypeRepository accountTypes;
  late AccountRepository accounts;
  late TransactionRepository transactions;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<Transaction>[]);
  });

  setUp(() async {
    db = newTestAppDatabase();
    await runTestSeed(db);
    currencies = DriftCurrencyRepository(db);
    categories = DriftCategoryRepository(db);
    accountTypes = DriftAccountTypeRepository(db, currencies);
    accounts = DriftAccountRepository(db, currencies);
    transactions = DriftTransactionRepository(db);
  });

  tearDown(() => db.close());

  CsvImportUseCase useCaseWith(
    CsvFileService service, {
    TransactionRepository? transactionRepo,
  }) => CsvImportUseCase(
    fileService: service,
    transactionRepo: transactionRepo ?? transactions,
    categoryRepo: categories,
    accountRepo: accounts,
    accountTypeRepo: accountTypes,
    currencyRepo: currencies,
    db: db,
  );

  CsvImportUseCase sampleUseCase({TransactionRepository? transactionRepo}) =>
      useCaseWith(
        _serviceFor(
          File(_samplePath).readAsBytesSync(),
          name: 'import_fortune_city_data.csv',
        ),
        transactionRepo: transactionRepo,
      );

  Future<int> categoryIdFor(String l10nKey) async =>
      (await db.categoryDao.findByL10nKey(l10nKey))!.id;

  /// The plan the matcher would build for the sample on a fresh en_US
  /// install, with Credit Card sent to [creditCard].
  Future<CsvImportPlan> samplePlan(
    CsvLoadResult load, {
    AccountResolution creditCard = const AccountResolution.createTypeAndAccount(
      name: 'Credit Card',
      currencyCode: 'HKD',
    ),
    CategoryType repaymentType = CategoryType.expense,
  }) async {
    final cash = (await accounts.watchAll().first).singleWhere(
      (a) => a.name == kSeededCashAccountName,
    );
    final investmentType = (await db.accountTypeDao.findByL10nKey(
      'accountType.investment',
    ))!;
    return CsvImportPlan(
      rows: load.validRows,
      accounts: {
        'Cash': AccountResolution.existing(cash.id),
        'Investment': AccountResolution.createAccount(
          name: 'Investment',
          accountTypeId: investmentType.id,
          currencyCode: 'HKD',
        ),
        'Credit Card': creditCard,
      },
      categories: {
        (value: '食物', type: null): CategoryResolution.existing(
          await categoryIdFor('category.food'),
        ),
        (value: '交通', type: null): CategoryResolution.existing(
          await categoryIdFor('category.transportation'),
        ),
        (value: '飲品', type: null): CategoryResolution.existing(
          await categoryIdFor('category.drinks'),
        ),
        (value: '收入', type: null): CategoryResolution.incomeByNote(
          salaryCategoryId: await categoryIdFor('category.income.salary'),
          otherCategoryId: await categoryIdFor('category.income.other'),
        ),
        (value: '理財', type: null): CategoryResolution.existing(
          await categoryIdFor('category.investment'),
        ),
        (value: '娛樂', type: null): CategoryResolution.existing(
          await categoryIdFor('category.entertainment'),
        ),
        (value: '醫藥', type: null): CategoryResolution.existing(
          await categoryIdFor('category.medical'),
        ),
        (value: '3C', type: null): CategoryResolution.existing(
          await categoryIdFor('category.threeC'),
        ),
        (value: '居家', type: null): CategoryResolution.existing(
          await categoryIdFor('category.housing'),
        ),
        (value: '消費', type: null): CategoryResolution.existing(
          await categoryIdFor('category.shopping'),
        ),
        (value: '其他', type: null): CategoryResolution.existing(
          await categoryIdFor('category.other'),
        ),
        (value: '還款', type: null): CategoryResolution.create(
          name: '還款',
          type: repaymentType,
        ),
        (value: '個人護理', type: null): const CategoryResolution.create(
          name: '個人護理',
          type: CategoryType.expense,
        ),
        (value: '休閒', type: null): const CategoryResolution.create(
          name: '休閒',
          type: CategoryType.expense,
        ),
      },
      salaryNotes: _salaryNotes,
    );
  }

  Future<List<TransactionRow>> allTransactionRows() => (db.select(
    db.transactions,
  )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();

  Future<({int types, int accounts, int categories, int transactions})>
  counts() async => (
    types: (await accountTypes.watchAll(includeArchived: true).first).length,
    accounts: (await accounts.watchAll(includeArchived: true).first).length,
    categories: (await categories.watchAll(includeArchived: true).first).length,
    transactions: (await allTransactionRows()).length,
  );

  group('pickAndLoad', () {
    test('loads the sample as 105 HKD rows with no duplicates', () async {
      final load = (await sampleUseCase().pickAndLoad())!;

      expect(load.fileName, 'import_fortune_city_data.csv');
      expect(load.validRows, hasLength(105));
      expect(load.rowsToImport, load.validRows);
      expect(load.errors, isEmpty);
      expect(load.validRows.map((r) => r.currency.code).toSet(), {'HKD'});
      final line26 = load.validRows.singleWhere((r) => r.line == 26);
      expect(line26.amountMinorUnits, 2360);
      expect(line26.recordedAt, DateTime(2023, 8, 2, 10, 27));
      expect(
        load.validRows.singleWhere((r) => r.line == 53).amountMinorUnits,
        1986977,
      );
    });

    test('returns null when the pick is cancelled', () async {
      final useCase = useCaseWith(_FakeCsvFileService(() async => null));
      expect(await useCase.pickAndLoad(), isNull);
    });

    test('parser file errors propagate unchanged', () async {
      final useCase = useCaseWith(_serviceFor(_csv([])));
      await expectLater(
        useCase.pickAndLoad(),
        throwsA(
          isA<CsvFileException>().having(
            (e) => e.kind,
            'kind',
            CsvFileErrorKind.empty,
          ),
        ),
      );
    });

    test('currency and amount problems become row errors, sorted by line, '
        'and their values never reach the rows to import', () async {
      final useCase = useCaseWith(
        _serviceFor(
          _csv([
            'Ghost,Phantom,10,XYZ,2026/1/5 9:05,,0',
            'Cash,食物,abc,HKD,2026/1/5 9:06,,0',
            ',食物,1,HKD,2026/1/5 9:07,,0',
            'Cash,食物,0.004,HKD,2026/1/5 9:08,,0',
            'Cash,食物,1234.5,jpy,2026/1/5 9:09,,0',
            'Cash,食物,12.345,HKD,2026/1/5 9:10, lunch ,0',
          ]),
        ),
      );

      final load = (await useCase.pickAndLoad())!;

      expect(load.errors, const [
        CsvRowError(
          lineNumber: 2,
          reason: CsvRowErrorReason.unknownCurrency,
          currencyCode: 'XYZ',
        ),
        CsvRowError(lineNumber: 3, reason: CsvRowErrorReason.invalidAmount),
        CsvRowError(lineNumber: 4, reason: CsvRowErrorReason.emptyAccount),
        CsvRowError(lineNumber: 5, reason: CsvRowErrorReason.zeroAmount),
      ]);
      expect(load.validRows.map((r) => r.account).toSet(), {'Cash'});
      expect(load.validRows.map((r) => r.category).toSet(), {'食物'});
      expect(
        load.validRows.map(
          (r) => (r.line, r.currency.code, r.amountMinorUnits),
        ),
        [(6, 'JPY', 1235), (7, 'HKD', 1235)],
      );
      expect(load.validRows.last.memo, ' lunch ');
    });

    test('an amount past 2^63 - 1 minor units is an invalid amount', () async {
      final useCase = useCaseWith(
        _serviceFor(_csv(['Cash,食物,99999999999999999,HKD,2026/1/5 9:05,,0'])),
      );
      final load = (await useCase.pickAndLoad())!;
      expect(load.validRows, isEmpty);
      expect(load.errors.single.reason, CsvRowErrorReason.invalidAmount);
    });

    test('dedup is multiset-based', () async {
      final food = await categoryIdFor('category.food');
      final cash = (await accounts.watchAll().first).single;
      final hkd = (await currencies.getByCode('HKD'))!;
      await transactions.insertImported([
        Transaction(
          id: 0,
          amountMinorUnits: 1000,
          currency: hkd,
          categoryId: food,
          accountId: cash.id,
          date: DateTime(2026, 1, 5),
          memo: 'coffee',
          createdAt: DateTime(2026, 1, 5, 9, 5),
          updatedAt: DateTime(2026, 1, 5, 9, 5),
        ),
      ]);
      final useCase = useCaseWith(
        _serviceFor(
          _csv([
            'Cash,食物,10,HKD,2026/1/5 9:05,coffee,0',
            'Cash,食物,10,HKD,2026/1/5 9:05,coffee,0',
          ]),
        ),
      );

      final load = (await useCase.pickAndLoad())!;
      expect(load.validRows, hasLength(2));
      expect(load.rowsToImport, hasLength(1));

      final result = await useCase.commit(
        CsvImportPlan(
          rows: load.validRows,
          accounts: {'Cash': AccountResolution.existing(cash.id)},
          categories: {
            (value: '食物', type: null): CategoryResolution.existing(food),
          },
          salaryNotes: _salaryNotes,
        ),
      );
      expect(result.importedCount, 1);
      expect(result.duplicateCount, 1);
      expect((await allTransactionRows()), hasLength(2));
    });

    test('a row with no memo is found again on re-import', () async {
      final food = await categoryIdFor('category.food');
      final cash = (await accounts.watchAll().first).single;
      final useCase = useCaseWith(
        _serviceFor(_csv(['Cash,食物,10,HKD,2026/1/5 9:05,,0'])),
      );
      final plan = CsvImportPlan(
        rows: (await useCase.pickAndLoad())!.validRows,
        accounts: {'Cash': AccountResolution.existing(cash.id)},
        categories: {
          (value: '食物', type: null): CategoryResolution.existing(food),
        },
        salaryNotes: _salaryNotes,
      );
      await useCase.commit(plan);

      final again = (await useCase.pickAndLoad())!;
      expect(again.rowsToImport, isEmpty);
      expect(again.validRows, hasLength(1));
    });
  });

  group('commit', () {
    test('the full sample creates 1 type, 2 accounts, 3 categories and 105 '
        'transactions', () async {
      final useCase = sampleUseCase();
      final load = (await useCase.pickAndLoad())!;
      final before = await counts();

      final result = await useCase.commit(await samplePlan(load));

      expect(result.importedCount, 105);
      expect(result.duplicateCount, 0);
      expect(result.createdAccountCount, 2);
      expect(result.createdCategoryCount, 3);
      expect(result.currencyCodes, {'HKD'});
      final after = await counts();
      expect(after.types, before.types + 1);
      expect(after.accounts, before.accounts + 2);
      expect(after.categories, before.categories + 3);
      expect(after.transactions, 105);

      final types = await accountTypes.watchAll().first;
      final creditCardType = types.singleWhere(
        (t) => t.customName == 'Credit Card',
      );
      expect(creditCardType.l10nKey, isNull);
      expect(creditCardType.defaultCurrency, isNull);
      expect(creditCardType.icon, 'wallet');
      expect(creditCardType.color, 10);
      expect(
        creditCardType.sortOrder,
        types
                .where((t) => t != creditCardType)
                .map((t) => t.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1,
      );

      final allAccounts = await accounts.watchAll().first;
      final creditCard = allAccounts.singleWhere(
        (a) => a.name == 'Credit Card',
      );
      expect(creditCard.accountTypeId, creditCardType.id);
      expect(creditCard.currency.code, 'HKD');
      expect(creditCard.openingBalanceMinorUnits, 0);
      expect(creditCard.icon, isNull);
      expect(creditCard.color, isNull);
      final investment = allAccounts.singleWhere((a) => a.name == 'Investment');
      expect(
        investment.accountTypeId,
        (await db.accountTypeDao.findByL10nKey('accountType.investment'))!.id,
      );
      expect(
        {creditCard.sortOrder, investment.sortOrder},
        hasLength(2),
        reason: 'each created account gets its own sortOrder',
      );

      final created = (await categories.watchAll().first)
          .where((c) => c.l10nKey == null)
          .toList();
      expect(created.map((c) => c.customName).toSet(), {'還款', '個人護理', '休閒'});
      for (final c in created) {
        expect(c.type, CategoryType.expense);
        expect(c.icon, 'category');
        expect(c.isArchived, isFalse);
      }

      final salaryId = await categoryIdFor('category.income.salary');
      final otherIncomeId = await categoryIdFor('category.income.other');
      final txRows = await allTransactionRows();
      expect(txRows.where((r) => r.categoryId == salaryId), hasLength(1));
      expect(txRows.where((r) => r.categoryId == otherIncomeId), hasLength(9));
      // 2026/10/30: 理財 4000 (expense) and 收入 61700 (income).
      expect(
        await transactions.watchDailyTotalsByType(DateTime(2026, 10, 30)).first,
        {'HKD': (expense: 400000, income: 6170000)},
      );

      final rows = await allTransactionRows();
      final byKey = {
        for (final r in load.validRows) (r.recordedAt, r.amountMinorUnits): r,
      };
      for (final row in rows) {
        final source = byKey[(row.createdAt, row.amountMinorUnits)]!;
        expect(row.createdAt, source.recordedAt);
        expect(
          row.date,
          DateTime(
            source.recordedAt.year,
            source.recordedAt.month,
            source.recordedAt.day,
          ),
        );
        expect(row.currency, 'HKD');
        expect(row.amountFormula, isNull);
      }
    });

    test('a category toggled to income sums as income', () async {
      final useCase = sampleUseCase();
      final load = (await useCase.pickAndLoad())!;

      await useCase.commit(
        await samplePlan(load, repaymentType: CategoryType.income),
      );

      final repayment = (await categories.watchAll().first).singleWhere(
        (c) => c.customName == '還款',
      );
      expect(repayment.type, CategoryType.income);
      final repaymentRows = load.validRows.where((r) => r.category == '還款');
      expect(repaymentRows, hasLength(3));
      for (final day in repaymentRows.map((r) => r.recordedAt)) {
        final incomeThatDay = load.validRows
            .where(
              (r) =>
                  (r.category == '還款' || r.category == '收入') &&
                  r.recordedAt.year == day.year &&
                  r.recordedAt.month == day.month &&
                  r.recordedAt.day == day.day,
            )
            .fold<int>(0, (sum, r) => sum + r.amountMinorUnits);
        final totals = await transactions.watchDailyTotalsByType(day).first;
        expect(totals['HKD']!.income, incomeThatDay);
      }
    });

    test('ids follow (createdAt ASC, line DESC)', () async {
      final useCase = sampleUseCase();
      final load = (await useCase.pickAndLoad())!;
      await useCase.commit(await samplePlan(load));

      final rows = await allTransactionRows();
      for (var i = 1; i < rows.length; i++) {
        expect(
          rows[i].createdAt.isBefore(rows[i - 1].createdAt),
          isFalse,
          reason: 'id ${rows[i].id} is older than id ${rows[i - 1].id}',
        );
      }
      expect(rows.last.createdAt, DateTime(2026, 10, 30, 10, 39));

      // Two rows share 2026/10/30 10:39; the export is newest-first, so
      // the earlier line is the later entry and gets the higher id.
      final sameMinute = rows
          .where((r) => r.createdAt == DateTime(2026, 10, 30, 10, 39))
          .toList();
      expect(sameMinute, hasLength(2));
      final line2 = load.validRows.singleWhere((r) => r.line == 2);
      expect(sameMinute.last.amountMinorUnits, line2.amountMinorUnits);

      final foodRows = load.validRows.where((r) => r.category == '食物').toList()
        ..sort((a, b) {
          final byTime = b.recordedAt.compareTo(a.recordedAt);
          return byTime != 0 ? byTime : a.line.compareTo(b.line);
        });
      final memos = await transactions
          .watchRecentMemosForCategory(
            await categoryIdFor('category.food'),
            limit: 1,
          )
          .first;
      expect(memos, [foodRows.first.memo!.trim()]);
    });

    test('re-importing after a commit finds 105 duplicates even when the '
        'chosen account was archived since', () async {
      final cardTypeId = (await db.accountTypeDao.findByL10nKey(
        'accountType.cash',
      ))!.id;
      final hkd = (await currencies.getByCode('HKD'))!;
      final cardId = await accounts.save(
        Account(
          id: 0,
          name: 'My card',
          accountTypeId: cardTypeId,
          currency: hkd,
        ),
      );
      final useCase = sampleUseCase();
      final load = (await useCase.pickAndLoad())!;
      await useCase.commit(
        await samplePlan(load, creditCard: AccountResolution.existing(cardId)),
      );
      await accounts.archive(cardId);

      final again = (await useCase.pickAndLoad())!;

      expect(again.rowsToImport, isEmpty);
      expect(again.validRows, hasLength(105));
      expect(again.errors, isEmpty);
    });

    test('the commit-time recount skips rows inserted since load and does '
        'not create a category left without rows', () async {
      final useCase = sampleUseCase();
      final load = (await useCase.pickAndLoad())!;
      final plan = await samplePlan(load);

      // Another path inserts the three 還款 rows between load and commit.
      final other = await categoryIdFor('category.other');
      final cash = (await accounts.watchAll().first).single;
      final hkd = (await currencies.getByCode('HKD'))!;
      await transactions.insertImported([
        for (final r in load.validRows.where((r) => r.category == '還款'))
          Transaction(
            id: 0,
            amountMinorUnits: r.amountMinorUnits,
            currency: hkd,
            categoryId: other,
            accountId: cash.id,
            date: DateTime(
              r.recordedAt.year,
              r.recordedAt.month,
              r.recordedAt.day,
            ),
            memo: r.memo,
            createdAt: r.recordedAt,
            updatedAt: r.recordedAt,
          ),
      ]);

      final result = await useCase.commit(plan);

      expect(result.importedCount, 102);
      expect(result.duplicateCount, 3);
      expect(result.createdCategoryCount, 2);
      final names = (await categories.watchAll(includeArchived: true).first)
          .map((c) => c.customName)
          .toSet();
      expect(names, isNot(contains('還款')));
      expect(names, containsAll(['個人護理', '休閒']));
      expect(await allTransactionRows(), hasLength(105));
    });

    test('names that normalize the same way share one created row', () async {
      final useCase = useCaseWith(
        _serviceFor(
          _csv([
            'Card,Fun,10,HKD,2026/1/5 9:05,,0',
            ' card ,fun,11,HKD,2026/1/5 9:06,,0',
          ]),
        ),
      );
      final load = (await useCase.pickAndLoad())!;
      expect(load.validRows.map((r) => r.account).toSet(), {'Card', 'card'});
      final before = await counts();

      final result = await useCase.commit(
        CsvImportPlan(
          rows: load.validRows,
          accounts: const {
            'Card': AccountResolution.createTypeAndAccount(
              name: 'Card',
              currencyCode: 'HKD',
            ),
            'card': AccountResolution.createTypeAndAccount(
              name: 'card',
              currencyCode: 'HKD',
            ),
          },
          categories: const {
            (value: 'Fun', type: null): CategoryResolution.create(
              name: 'Fun',
              type: CategoryType.expense,
            ),
            (value: 'fun', type: null): CategoryResolution.create(
              name: 'fun',
              type: CategoryType.expense,
            ),
          },
          salaryNotes: _salaryNotes,
        ),
      );

      expect(result.createdAccountCount, 1);
      expect(result.createdCategoryCount, 1);
      final after = await counts();
      expect(after.types, before.types + 1);
      expect(after.accounts, before.accounts + 1);
      expect(after.categories, before.categories + 1);
      final rows = await allTransactionRows();
      expect(rows.map((r) => r.accountId).toSet(), hasLength(1));
      expect(rows.map((r) => r.categoryId).toSet(), hasLength(1));
    });

    test('names that normalize the same way but differ in type get one '
        'created row per type', () async {
      final useCase = useCaseWith(
        _serviceFor(
          _csv([
            'Card,Fun,10,HKD,2026/1/5 9:05,,0',
            'Card,fun,11,HKD,2026/1/5 9:06,,0',
          ]),
        ),
      );
      final load = (await useCase.pickAndLoad())!;
      final before = await counts();

      final result = await useCase.commit(
        CsvImportPlan(
          rows: load.validRows,
          accounts: const {
            'Card': AccountResolution.createTypeAndAccount(
              name: 'Card',
              currencyCode: 'HKD',
            ),
          },
          categories: const {
            (value: 'Fun', type: null): CategoryResolution.create(
              name: 'Fun',
              type: CategoryType.expense,
            ),
            (value: 'fun', type: null): CategoryResolution.create(
              name: 'fun',
              type: CategoryType.income,
            ),
          },
          salaryNotes: _salaryNotes,
        ),
      );

      expect(result.createdCategoryCount, 2);
      expect((await counts()).categories, before.categories + 2);
      expect(
        await transactions.watchDailyTotalsByType(DateTime(2026, 1, 5)).first,
        {'HKD': (expense: 1000, income: 1100)},
      );
    });

    test(
      '收入 rows whose note normalizes to a salary note go to Salary',
      () async {
        final useCase = useCaseWith(
          _serviceFor(
            _csv([
              'Cash,收入,10,HKD,2026/1/5 9:05, SALARY ,0',
              'Cash,收入,11,HKD,2026/1/5 9:06,薪资,0',
              'Cash,收入,12,HKD,2026/1/5 9:07,bonus,0',
              'Cash,收入,13,HKD,2026/1/5 9:08,,0',
            ]),
          ),
        );
        final load = (await useCase.pickAndLoad())!;
        final cash = (await accounts.watchAll().first).single;
        final salary = await categoryIdFor('category.income.salary');
        final other = await categoryIdFor('category.income.other');

        await useCase.commit(
          CsvImportPlan(
            rows: load.validRows,
            accounts: {'Cash': AccountResolution.existing(cash.id)},
            categories: {
              (value: '收入', type: null): CategoryResolution.incomeByNote(
                salaryCategoryId: salary,
                otherCategoryId: other,
              ),
            },
            salaryNotes: _salaryNotes,
          ),
        );

        final rows = await allTransactionRows();
        expect(
          {for (final r in rows) r.amountMinorUnits: r.categoryId},
          {1000: salary, 1100: salary, 1200: other, 1300: other},
        );
      },
    );

    test('is atomic: a failing insert leaves types, accounts, categories '
        'and transactions unchanged', () async {
      final failing = _MockTransactionRepository();
      when(() => failing.getImportSignatures(any(), any()))
          .thenAnswer((_) async => const []);
      when(() => failing.insertImported(any()))
          .thenThrow(StateError('insert failed'));
      final useCase = sampleUseCase(transactionRepo: failing);
      final load = (await useCase.pickAndLoad())!;
      final before = await counts();

      await expectLater(
        useCase.commit(await samplePlan(load)),
        throwsA(isA<StateError>()),
      );

      expect(await counts(), before);
    });

    group('2,500 rows', () {
      late _MockTransactionRepository spy;
      late List<int> batchSizes;

      setUp(() {
        spy = _MockTransactionRepository();
        batchSizes = [];
        when(() => spy.getImportSignatures(any(), any())).thenAnswer(
          (i) => transactions.getImportSignatures(
            i.positionalArguments[0] as DateTime,
            i.positionalArguments[1] as DateTime,
          ),
        );
        when(() => spy.insertImported(any())).thenAnswer((i) {
          final txs = i.positionalArguments.single as List<Transaction>;
          batchSizes.add(txs.length);
          return transactions.insertImported(txs);
        });
      });

      Future<CsvImportPlan> cashFoodPlan(CsvLoadResult load) async =>
          CsvImportPlan(
            rows: load.validRows,
            accounts: {
              'Cash': AccountResolution.existing(
                (await accounts.watchAll().first).single.id,
              ),
            },
            categories: {
              (value: '食物', type: null): CategoryResolution.existing(
                await categoryIdFor('category.food'),
              ),
            },
            salaryNotes: _salaryNotes,
          );

      test('are inserted in 1,000-row chunks and ids still follow '
          '(createdAt ASC, line DESC)', () async {
        final useCase = useCaseWith(
          _serviceFor(_csv(_rowsNewestFirst(2500))),
          transactionRepo: spy,
        );
        final load = (await useCase.pickAndLoad())!;

        final result = await useCase.commit(await cashFoodPlan(load));

        expect(result.importedCount, 2500);
        expect(batchSizes, [1000, 1000, 500]);
        final rows = await allTransactionRows();
        expect(rows, hasLength(2500));
        int lineOf(TransactionRow r) => r.amountMinorUnits ~/ 100 + 1;
        for (var i = 1; i < rows.length; i++) {
          final byTime = rows[i].createdAt.compareTo(rows[i - 1].createdAt);
          expect(byTime, greaterThanOrEqualTo(0), reason: 'id ${rows[i].id}');
          if (byTime == 0) {
            expect(
              lineOf(rows[i]),
              lessThan(lineOf(rows[i - 1])),
              reason: 'id ${rows[i].id}',
            );
          }
        }
      });

      test('a failing later chunk rolls back the earlier chunks and the '
          'created type, account and category', () async {
        when(() => spy.insertImported(any())).thenAnswer((i) {
          if (batchSizes.isNotEmpty) throw StateError('second chunk failed');
          final txs = i.positionalArguments.single as List<Transaction>;
          batchSizes.add(txs.length);
          return transactions.insertImported(txs);
        });
        final useCase = useCaseWith(
          _serviceFor(
            _csv(_rowsNewestFirst(2500, account: 'Card', category: 'Fun')),
          ),
          transactionRepo: spy,
        );
        final load = (await useCase.pickAndLoad())!;
        final before = await counts();

        await expectLater(
          useCase.commit(
            CsvImportPlan(
              rows: load.validRows,
              accounts: const {
                'Card': AccountResolution.createTypeAndAccount(
                  name: 'Card',
                  currencyCode: 'HKD',
                ),
              },
              categories: const {
                (value: 'Fun', type: null): CategoryResolution.create(
                  name: 'Fun',
                  type: CategoryType.expense,
                ),
              },
              salaryNotes: _salaryNotes,
            ),
          ),
          throwsA(isA<StateError>()),
        );

        expect(batchSizes, [1000]);
        expect(await counts(), before);
      });

      test('re-importing after a commit finds every row a duplicate', () async {
        final useCase = useCaseWith(_serviceFor(_csv(_rowsNewestFirst(2500))));
        await useCase.commit(
          await cashFoodPlan((await useCase.pickAndLoad())!),
        );

        final again = (await useCase.pickAndLoad())!;

        expect(again.rowsToImport, isEmpty);
        expect(again.validRows, hasLength(2500));
      });
    });
  });

  group('Ledgerly export', () {
    Uint8List ledgerlyCsv(List<String> rows) => Uint8List.fromList(
      utf8.encode(
        [
          'id,date,type,amount,currency,category,account,memo,'
              'created_at,updated_at',
          ...rows,
        ].join('\n'),
      ),
    );

    test('amounts keep every decimal of the currency', () async {
      await currencies.upsert(const Currency(code: 'BHD', decimals: 3));
      final load = (await useCaseWith(
        _serviceFor(
          ledgerlyCsv([
            '1,2026-10-29T00:00:00+08:00,expense,1.235,BHD,Food,Cash,,'
                '2026-10-30T14:31:05+08:00,2026-10-30T14:31:05+08:00',
          ]),
        ),
      ).pickAndLoad())!;

      final row = load.validRows.single;
      expect(row.amountMinorUnits, 1235);
      expect(row.type, CategoryType.expense);
      expect(row.date, DateTime(2026, 10, 29));
    });

    test('commit writes date from the date column and createdAt from '
        'created_at, and a re-import finds the row again', () async {
      final useCase = useCaseWith(
        _serviceFor(
          ledgerlyCsv([
            '1,2026-10-29T00:00:00+08:00,expense,12.34,HKD,Food,Cash,lunch,'
                '2026-10-30T14:31:05+08:00,2026-10-31T09:00:00+08:00',
          ]),
        ),
      );
      final load = (await useCase.pickAndLoad())!;
      final cash = (await accounts.watchAll().first).single;
      final food = await categoryIdFor('category.food');

      await useCase.commit(
        CsvImportPlan(
          rows: load.validRows,
          accounts: {'Cash': AccountResolution.existing(cash.id)},
          categories: {
            (value: 'Food', type: CategoryType.expense):
                CategoryResolution.existing(food),
          },
          salaryNotes: _salaryNotes,
        ),
      );

      final stored = (await allTransactionRows()).single;
      expect(stored.date, DateTime(2026, 10, 29));
      expect(stored.createdAt, DateTime.utc(2026, 10, 30, 6, 31, 5).toLocal());
      expect(stored.amountMinorUnits, 1234);
      expect((await useCase.pickAndLoad())!.rowsToImport, isEmpty);
    });

    test('one value in both types lands in one category per type', () async {
      final useCase = useCaseWith(
        _serviceFor(
          ledgerlyCsv([
            '1,2026-10-29T00:00:00+08:00,expense,5,HKD,Investment,Cash,,'
                '2026-10-29T10:00:00+08:00,2026-10-29T10:00:00+08:00',
            '2,2026-10-30T00:00:00+08:00,income,7,HKD,Investment,Cash,,'
                '2026-10-30T10:00:00+08:00,2026-10-30T10:00:00+08:00',
          ]),
        ),
      );
      final load = (await useCase.pickAndLoad())!;
      final cash = (await accounts.watchAll().first).single;
      final expense = await categoryIdFor('category.investment');
      final income = await categoryIdFor('category.income.investment');

      await useCase.commit(
        CsvImportPlan(
          rows: load.validRows,
          accounts: {'Cash': AccountResolution.existing(cash.id)},
          categories: {
            (value: 'Investment', type: CategoryType.expense):
                CategoryResolution.existing(expense),
            (value: 'Investment', type: CategoryType.income):
                CategoryResolution.existing(income),
          },
          salaryNotes: _salaryNotes,
        ),
      );

      final stored = await allTransactionRows();
      expect(
        {for (final r in stored) r.amountMinorUnits: r.categoryId},
        {500: expense, 700: income},
      );
    });

    group('uuid', () {
      const u1 = '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80';
      const u2 = '0b8e3c1a-5d2f-4a6b-8c7d-9e0f1a2b3c4d';

      String row(
        String id, {
        String amount = '12.34',
        String memo = 'lunch',
        String createdAt = '2026-10-30T14:31:05+08:00',
      }) =>
          '$id,2026-10-29T00:00:00+08:00,expense,$amount,HKD,Food,Cash,'
          '$memo,$createdAt,$createdAt';

      /// Loads [rows] and commits every one of them to Cash and Food.
      Future<({CsvLoadResult load, CsvImportResult result})> importRows(
        List<String> rows,
      ) async {
        final useCase = useCaseWith(_serviceFor(ledgerlyCsv(rows)));
        final load = (await useCase.pickAndLoad())!;
        final cash = (await accounts.watchAll().first).single;
        final food = await categoryIdFor('category.food');
        final result = await useCase.commit(
          CsvImportPlan(
            rows: load.validRows,
            accounts: {'Cash': AccountResolution.existing(cash.id)},
            categories: {
              (value: 'Food', type: CategoryType.expense):
                  CategoryResolution.existing(food),
            },
            salaryNotes: _salaryNotes,
          ),
        );
        return (load: load, result: result);
      }

      test('an unknown uuid is inserted with that uuid', () async {
        final (:load, :result) = await importRows([row(u1.toUpperCase())]);

        expect(load.rowsToImport.single.uuid, u1);
        expect(result.importedCount, 1);
        expect((await allTransactionRows()).single.uuid, u1);
      });

      test('a known uuid is a duplicate even after its amount and memo '
          'were edited; the device copy wins', () async {
        await importRows([row(u1)]);
        final stored = (await transactions.getById(
          (await allTransactionRows()).single.id,
        ))!;
        await transactions.save(
          stored.copyWith(amountMinorUnits: 9999, memo: 'dinner'),
        );

        final (:load, :result) = await importRows([row(u1)]);

        expect(load.rowsToImport, isEmpty);
        expect(result.importedCount, 0);
        expect(result.duplicateCount, 1);
        final after = (await allTransactionRows()).single;
        expect(
          (after.uuid, after.amountMinorUnits, after.memo),
          (u1, 9999, 'dinner'),
        );
      });

      test('a uuid repeated in the file is imported once', () async {
        final (:load, :result) = await importRows([
          row(u1),
          row(u1, amount: '5', memo: 'other'),
        ]);

        expect(load.rowsToImport.map((r) => r.line), [2]);
        expect(result.importedCount, 1);
        expect(result.duplicateCount, 1);
        final stored = (await allTransactionRows()).single;
        expect((stored.uuid, stored.amountMinorUnits), (u1, 1234));
      });

      test('an integer id falls back to the signature, and an inserted row '
          'gets a fresh uuid', () async {
        await importRows([row('1')]);
        final first = (await allTransactionRows()).single.uuid;

        // Same integer id both times: only the signature tells them apart.
        final (:load, :result) = await importRows([
          row('1'),
          row('1', amount: '1'),
        ]);

        expect(load.rowsToImport.map((r) => r.line), [3]);
        expect(result.importedCount, 1);
        expect(result.duplicateCount, 1);
        final uuids = (await allTransactionRows()).map((r) => r.uuid).toList();
        expect(uuids.first, first);
        expect(uuids.last, isNot(first));
        expect(uuids, everyElement(hasLength(36)));
      });

      test('an unknown uuid still matches a row imported before v8 by '
          'signature', () async {
        await importRows([row('1')]);

        final (:load, :result) = await importRows([row(u1)]);

        expect(load.rowsToImport, isEmpty);
        expect(result.duplicateCount, 1);
        expect((await allTransactionRows()).single.uuid, isNot(u1));
      });

      test('a row matched by uuid is not matched again by signature', () async {
        await importRows([row(u1)]);

        // Two transactions that differ only in uuid; the first is stored.
        final (:load, :result) = await importRows([row(u1), row(u2)]);

        expect(load.rowsToImport.map((r) => r.uuid), [u2]);
        expect(result.importedCount, 1);
        expect(result.duplicateCount, 1);
        expect((await allTransactionRows()).map((r) => r.uuid), [u1, u2]);
      });
    });
  });
}
