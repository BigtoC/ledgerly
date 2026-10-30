// Unit tests for `CsvImportController`: load → preview → commit, with a
// mocked use case and repositories. `build()` is synchronous, so tests
// subscribe with `container.listen` and read the provider directly.

import 'dart:async';
import 'dart:io' show FileSystemException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart' as drift;
import 'package:ledgerly/data/database/daos/exchange_rate_dao.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/csv_import.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/data/use_cases/csv_import_use_case.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_controller.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_matcher.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_state.dart';

class _MockCsvImportUseCase extends Mock implements CsvImportUseCase {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockAccountTypeRepository extends Mock
    implements AccountTypeRepository {}

class _MockAppDatabase extends Mock implements drift.AppDatabase {}

class _MockExchangeRateDao extends Mock implements ExchangeRateDao {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _hkd = Currency(code: 'HKD', decimals: 2);

const _food = Category(
  id: 1,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);
const _salary = Category(
  id: 2,
  icon: 'work',
  color: 0,
  type: CategoryType.income,
  l10nKey: 'category.income.salary',
);
const _otherIncome = Category(
  id: 3,
  icon: 'payments',
  color: 0,
  type: CategoryType.income,
  l10nKey: 'category.income.other',
);

const _cashType = AccountType(
  id: 1,
  l10nKey: 'accountType.cash',
  icon: 'wallet',
  color: 0,
);
const _investmentType = AccountType(
  id: 2,
  l10nKey: 'accountType.investment',
  icon: 'trending_up',
  color: 0,
  sortOrder: 1,
);
const _cash = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _hkd);

CsvImportRow _row(
  int line, {
  String account = 'Cash',
  String category = '食物',
  Currency currency = _hkd,
  DateTime? recordedAt,
  String? memo,
}) => CsvImportRow(
  line: line,
  account: account,
  category: category,
  amountMinorUnits: 100,
  currency: currency,
  recordedAt: recordedAt ?? DateTime(2026, 10, 30, 10, 39),
  memo: memo,
);

/// A small file shaped like the sample: Cash (tier 1), Investment (tier
/// 2b), Credit Card (tier 3); 食物 (existing), 收入 (income marker, one
/// Salary note), 還款 (new). Line 9 is already in the database.
final _rows = [
  _row(2, recordedAt: DateTime(2026, 10, 30, 10, 39)),
  _row(3, account: 'Credit Card', category: '還款'),
  _row(4, account: 'Credit Card'),
  _row(5, account: 'Investment', category: '收入', memo: '薪資'),
  _row(6, category: '收入', memo: '利息'),
  _row(7, category: '收入'),
  _row(8, recordedAt: DateTime(2022, 7, 16, 18, 28)),
];
final _duplicate = _row(9, recordedAt: DateTime(2023, 1, 1, 9, 0));

final _load = CsvLoadResult(
  fileName: 'export.csv',
  validRows: [..._rows, _duplicate],
  rowsToImport: _rows,
  duplicateCount: 1,
  errors: const [
    CsvRowError(lineNumber: 10, reason: CsvRowErrorReason.invalidDate),
  ],
);

const _result = CsvImportResult(
  importedCount: 7,
  duplicateCount: 1,
  createdAccountCount: 2,
  createdCategoryCount: 1,
  currencyCodes: {'HKD'},
);

@Dependencies([CsvImportController, defaultCurrency])
void main() {
  setUpAll(() {
    registerFallbackValue(
      const CsvImportPlan(
        rows: [],
        accounts: {},
        categories: {},
        salaryNotes: {},
      ),
    );
  });

  late _MockCsvImportUseCase useCase;
  late _MockCategoryRepository categoryRepo;
  late _MockAccountRepository accountRepo;
  late _MockAccountTypeRepository accountTypeRepo;
  // `ExchangeRateRepository` is final, so a real one runs over a mocked
  // DAO; each `refreshAll` reads the DAO's currency set once.
  late _MockExchangeRateDao rateDao;
  late _MockExchangeRateService rateService;
  late ExchangeRateRepository rateRepo;

  setUp(() {
    useCase = _MockCsvImportUseCase();
    categoryRepo = _MockCategoryRepository();
    accountRepo = _MockAccountRepository();
    accountTypeRepo = _MockAccountTypeRepository();
    final db = _MockAppDatabase();
    rateDao = _MockExchangeRateDao();
    rateService = _MockExchangeRateService();
    when(() => db.exchangeRateDao).thenReturn(rateDao);
    when(() => rateDao.watchAll())
        .thenAnswer((_) => Stream.value(const <drift.ExchangeRateRow>[]));
    when(() => rateDao.distinctCurrenciesAcrossAllTables())
        .thenAnswer((_) async => {'HKD', 'JPY', 'USD'});
    when(() => rateService.fetchRates(any())).thenAnswer((_) async => []);
    rateRepo = ExchangeRateRepository(
      db,
      rateService,
      const Stream<String>.empty(),
    );
    addTearDown(rateRepo.dispose);

    when(() => useCase.pickAndLoad()).thenAnswer((_) async => _load);
    when(() => useCase.commit(any())).thenAnswer((_) async => _result);
    when(() => categoryRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_food, _salary, _otherIncome]));
    when(() => accountRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cash]));
    when(() => accountTypeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cashType, _investmentType]));
  });

  /// [defaultCurrency] null leaves the default-currency stream loading,
  /// so the controller must fall back to [initialDefault].
  ProviderContainer makeContainer({
    String? defaultCurrency = 'HKD',
    String initialDefault = 'USD',
  }) {
    final container = ProviderContainer(
      overrides: [
        csvImportUseCaseProvider.overrideWithValue(useCase),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        accountTypeRepositoryProvider.overrideWithValue(accountTypeRepo),
        exchangeRateRepositoryProvider.overrideWithValue(rateRepo),
        defaultCurrencyProvider.overrideWith(
          (ref) => defaultCurrency == null
              ? StreamController<String>().stream
              : Stream.value(defaultCurrency),
        ),
        initialDefaultCurrencyProvider.overrideWithValue(initialDefault),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Subscribes to the controller and returns every state it emits.
  @Dependencies([CsvImportController])
  List<CsvImportState> listen(ProviderContainer container) {
    final states = <CsvImportState>[];
    container.listen(
      csvImportControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    return states;
  }

  @Dependencies([CsvImportController, defaultCurrency])
  Future<CsvImportPreview> loadPreview(ProviderContainer container) async {
    // Prime the keepAlive default-currency stream, as the running app does.
    container.listen(defaultCurrencyProvider, (_, _) {});
    await container.pump();
    await container.read(csvImportControllerProvider.notifier).pickFile();
    return container.read(csvImportControllerProvider) as CsvImportPreview;
  }

  CsvAccountMatch accountEntry(CsvImportPreview p, String value) =>
      p.accounts.singleWhere((a) => a.csvValue == value);

  CsvCategoryEntry categoryEntry(CsvImportPreview p, String value) =>
      p.categories.singleWhere((c) => c.csvValue == value);

  group('CsvImportController', () {
    test('goes idle → loading → preview', () async {
      final container = makeContainer();
      final states = listen(container);

      final preview = await loadPreview(container);

      expect(states.map((s) => s.runtimeType), [
        CsvImportIdle,
        CsvImportLoading,
        CsvImportPreview,
      ]);
      expect(preview.fileName, 'export.csv');
      expect(preview.importCount, 7);
      expect(preview.firstRecordedAt, DateTime(2022, 7, 16, 18, 28));
      expect(preview.lastRecordedAt, DateTime(2026, 10, 30, 10, 39));
      expect(preview.duplicateCount, 1);
      expect(preview.errors, _load.errors);

      expect(accountEntry(preview, 'Cash').tier, CsvAccountTier.name);
      expect(
        accountEntry(preview, 'Cash').resolution,
        const AccountResolution.existing(1),
      );
      final investment = accountEntry(preview, 'Investment');
      expect(investment.tier, CsvAccountTier.typeWithoutAccount);
      expect(investment.isNew, isTrue);
      expect(accountEntry(preview, 'Credit Card').resolution, isNull);
    });

    test('preview lists categories with their targets and types', () async {
      final preview = await loadPreview(makeContainer());

      final food = categoryEntry(preview, '食物');
      expect(food.category, _food);
      expect(food.type, CategoryType.expense);
      expect(food.isNew, isFalse);
      expect(food.rowCount, 3);

      final repayment = categoryEntry(preview, '還款');
      expect(repayment.isNew, isTrue);
      expect(repayment.type, CategoryType.expense);
      expect(repayment.category, isNull);
    });

    test('preview shows the income marker with its Salary / Other '
        'income split', () async {
      final preview = await loadPreview(makeContainer());

      final income = categoryEntry(preview, '收入');
      expect(income.isNew, isFalse);
      expect(income.type, CategoryType.income);
      expect(income.salaryCategory, _salary);
      expect(income.otherIncomeCategory, _otherIncome);
      expect(income.rowCount, 3);
      expect(income.salaryRowCount, 1);
      expect(income.otherIncomeRowCount, 2);
    });

    test('canCommit waits for Credit Card; the pre-selected Investment '
        'resolution counts as decided', () async {
      final container = makeContainer();
      final preview = await loadPreview(container);
      expect(preview.canCommit, isFalse);

      container
          .read(csvImportControllerProvider.notifier)
          .setAccountResolution(
            'Credit Card',
            const AccountResolution.createTypeAndAccount(
              name: 'Credit Card',
              currencyCode: 'HKD',
            ),
          );

      final after = container.read(csvImportControllerProvider);
      expect((after as CsvImportPreview).canCommit, isTrue);
      expect(accountEntry(after, 'Credit Card').isNew, isTrue);
    });

    test('canCommit is false when there is nothing to import', () async {
      when(() => useCase.pickAndLoad()).thenAnswer(
        (_) async => CsvLoadResult(
          fileName: 'export.csv',
          validRows: _rows,
          rowsToImport: const [],
          duplicateCount: _rows.length,
          errors: const [],
        ),
      );

      final preview = await loadPreview(makeContainer());

      expect(preview.importCount, 0);
      expect(preview.duplicateCount, 7);
      expect(preview.accounts, isEmpty);
      expect(preview.categories, isEmpty);
      expect(preview.firstRecordedAt, isNull);
      expect(preview.canCommit, isFalse);
    });

    test('setters update the preview but never the counts', () async {
      final container = makeContainer();
      final before = await loadPreview(container);
      final controller = container.read(csvImportControllerProvider.notifier);

      controller
        ..setAccountResolution(
          'Investment',
          const AccountResolution.existing(1),
        )
        ..setNewCategoryType('還款', CategoryType.income);

      final after = container.read(csvImportControllerProvider);
      after as CsvImportPreview;
      expect(
        accountEntry(after, 'Investment').resolution,
        const AccountResolution.existing(1),
      );
      expect(accountEntry(after, 'Investment').isNew, isFalse);
      expect(categoryEntry(after, '還款').type, CategoryType.income);
      expect(
        categoryEntry(after, '還款').resolution,
        const CategoryResolution.create(name: '還款', type: CategoryType.income),
      );
      expect(after.importCount, before.importCount);
      expect(after.duplicateCount, before.duplicateCount);
      expect(after.errors, before.errors);
    });

    test('setNewCategoryType ignores categories that are not new', () async {
      final container = makeContainer();
      final before = await loadPreview(container);

      container
          .read(csvImportControllerProvider.notifier)
          .setNewCategoryType('食物', CategoryType.income);

      expect(container.read(csvImportControllerProvider), before);
    });

    test('commit goes committing → done with the full plan', () async {
      final container = makeContainer();
      final states = listen(container);
      await loadPreview(container);
      final controller = container.read(csvImportControllerProvider.notifier)
        ..setAccountResolution(
          'Credit Card',
          const AccountResolution.createTypeAndAccount(
            name: 'Credit Card',
            currencyCode: 'HKD',
          ),
        )
        ..setNewCategoryType('還款', CategoryType.income);

      await controller.commit();

      expect(states.skip(3).map((s) => s.runtimeType), [
        CsvImportPreview, // after the setters
        CsvImportPreview,
        CsvImportCommitting,
        CsvImportDone,
      ]);
      final done = states.last as CsvImportDone;
      expect(done.result, _result);
      expect(done.invalidRowCount, 1);

      final plan =
          verify(() => useCase.commit(captureAny())).captured.single
              as CsvImportPlan;
      // Duplicates included: the commit recounts them.
      expect(plan.rows, _load.validRows);
      expect(plan.accounts, {
        'Cash': const AccountResolution.existing(1),
        'Credit Card': const AccountResolution.createTypeAndAccount(
          name: 'Credit Card',
          currencyCode: 'HKD',
        ),
        'Investment': const AccountResolution.createAccount(
          name: 'Investment',
          accountTypeId: 2,
          currencyCode: 'HKD',
        ),
      });
      expect(plan.categories, {
        '食物': const CategoryResolution.existing(1),
        '還款': const CategoryResolution.create(
          name: '還款',
          type: CategoryType.income,
        ),
        '收入': const CategoryResolution.incomeByNote(
          salaryCategoryId: 2,
          otherCategoryId: 3,
        ),
      });
      expect(plan.salaryNotes, containsAll(['Salary', '薪資']));
    });

    test('commit is ignored while a decision is pending', () async {
      final container = makeContainer();
      await loadPreview(container);

      await container.read(csvImportControllerProvider.notifier).commit();

      verifyNever(() => useCase.commit(any()));
      expect(
        container.read(csvImportControllerProvider),
        isA<CsvImportPreview>(),
      );
    });

    group('exchange-rate refresh', () {
      /// The `to` side of every pair the single refresh fetched.
      Set<String> refreshedAgainst() {
        verify(() => rateDao.distinctCurrenciesAcrossAllTables()).called(1);
        final pairs =
            verify(() => rateService.fetchRates(captureAny())).captured.single
                as List<({String from, String to})>;
        return pairs.map((p) => p.to).toSet();
      }

      @Dependencies([CsvImportController, defaultCurrency])
      Future<void> importWith(
        ProviderContainer container,
        Set<String> codes,
      ) async {
        when(() => useCase.commit(any()))
            .thenAnswer((_) async => _result.copyWith(currencyCodes: codes));
        await loadPreview(container);
        final controller = container.read(csvImportControllerProvider.notifier)
          ..setAccountResolution(
            'Credit Card',
            const AccountResolution.existing(1),
          );
        await controller.commit();
        await pumpEventQueue();
      }

      test('refreshes once against the initial default when the default '
          'stream has not emitted', () async {
        final container = makeContainer(defaultCurrency: null);

        await importWith(container, {'HKD', 'JPY'});

        expect(refreshedAgainst(), {'USD'});
      });

      test('refreshes once when a non-default currency was imported', () async {
        final container = makeContainer();

        await importWith(container, {'HKD', 'JPY'});

        expect(refreshedAgainst(), {'HKD'});
      });

      test('does not refresh when every currency is the default', () async {
        final container = makeContainer();

        await importWith(container, {'HKD'});

        verifyNever(() => rateDao.distinctCurrenciesAcrossAllTables());
      });
    });

    test('a commit exception goes to failure(commitFailed)', () async {
      when(() => useCase.commit(any())).thenThrow(StateError('boom'));
      final container = makeContainer();
      await loadPreview(container);
      final controller = container.read(csvImportControllerProvider.notifier)
        ..setAccountResolution(
          'Credit Card',
          const AccountResolution.existing(1),
        );

      await controller.commit();

      expect(
        container.read(csvImportControllerProvider),
        const CsvImportState.failure(CsvFileErrorKind.commitFailed),
      );
      await pumpEventQueue();
      verifyNever(() => rateDao.distinctCurrenciesAcrossAllTables());
    });

    test('a cancelled pick returns to idle', () async {
      when(() => useCase.pickAndLoad()).thenAnswer((_) async => null);
      final container = makeContainer();
      final states = listen(container);

      await container.read(csvImportControllerProvider.notifier).pickFile();

      expect(states.map((s) => s.runtimeType), [
        CsvImportIdle,
        CsvImportLoading,
        CsvImportIdle,
      ]);
    });

    for (final kind in CsvFileErrorKind.values) {
      test('CsvFileException(${kind.name}) maps to failure', () async {
        when(
          () => useCase.pickAndLoad(),
        ).thenThrow(CsvFileException(kind, missingColumns: const ['Amount']));
        final container = makeContainer();
        listen(container);

        await container.read(csvImportControllerProvider.notifier).pickFile();

        expect(
          container.read(csvImportControllerProvider),
          CsvImportState.failure(kind, missingColumns: const ['Amount']),
        );
      });
    }

    test('any other load exception goes to failure(readFailed), and the '
        'user can pick again', () async {
      when(() => useCase.pickAndLoad())
          .thenThrow(const FileSystemException('unreadable'));
      final container = makeContainer();
      listen(container);
      final controller = container.read(csvImportControllerProvider.notifier);

      await controller.pickFile();

      expect(
        container.read(csvImportControllerProvider),
        const CsvImportState.failure(CsvFileErrorKind.readFailed),
      );
      when(() => useCase.pickAndLoad()).thenAnswer((_) async => _load);
      await controller.pickFile();
      expect(
        container.read(csvImportControllerProvider),
        isA<CsvImportPreview>(),
      );
    });

    test('a repository read failure goes to failure(readFailed)', () async {
      when(() => categoryRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.error(StateError('db')));
      final container = makeContainer();
      listen(container);

      await container.read(csvImportControllerProvider.notifier).pickFile();

      expect(
        container.read(csvImportControllerProvider),
        const CsvImportState.failure(CsvFileErrorKind.readFailed),
      );
    });

    test('reset returns to idle', () async {
      final container = makeContainer();
      await loadPreview(container);

      container.read(csvImportControllerProvider.notifier).reset();

      expect(container.read(csvImportControllerProvider), isA<CsvImportIdle>());
    });

    test('no state write after dispose during load', () async {
      final pending = Completer<CsvLoadResult?>();
      when(() => useCase.pickAndLoad()).thenAnswer((_) => pending.future);
      final container = makeContainer();
      listen(container);
      final load = container
          .read(csvImportControllerProvider.notifier)
          .pickFile();

      container.dispose();
      pending.complete(_load);

      await expectLater(load, completes);
    });

    test('no state write after dispose during commit', () async {
      final pending = Completer<CsvImportResult>();
      when(() => useCase.commit(any())).thenAnswer((_) => pending.future);
      final container = makeContainer();
      listen(container);
      await loadPreview(container);
      final controller = container.read(csvImportControllerProvider.notifier)
        ..setAccountResolution(
          'Credit Card',
          const AccountResolution.existing(1),
        );
      final commit = controller.commit();

      container.dispose();
      pending.complete(_result);

      await expectLater(commit, completes);
    });
  });
}
