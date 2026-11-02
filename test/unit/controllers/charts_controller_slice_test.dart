import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/category_slice.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/currency_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/domain/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../repositories/_harness/test_app_database.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

ProviderContainer _container(
  _MockRepo repo, {
  Map<int, Account> accounts = const {},
  Map<int, AccountType> accountTypes = const {},
  Stream<Map<int, AccountType>>? accountTypesStream,
}) {
  final fxService = _MockExchangeRateService();
  when(() => fxService.fetchRates(any())).thenAnswer((_) async => []);
  final fxDb = newTestAppDatabase();
  final fxRepo = ExchangeRateRepository(
    fxDb,
    fxService,
    const Stream<String>.empty(),
  );
  addTearDown(() async {
    fxRepo.dispose();
    await fxDb.close();
  });
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
      initialDefaultCurrencyProvider.overrideWithValue('USD'),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd}),
      ),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value({
          1: const Category(
            id: 1,
            type: CategoryType.expense,
            l10nKey: 'cat.food',
            icon: 'restaurant',
            color: 0,
          ),
          2: const Category(
            id: 2,
            type: CategoryType.expense,
            l10nKey: 'cat.transport',
            icon: 'car',
            color: 1,
          ),
        }),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(accounts),
      ),
      analysisAccountTypesByIdProvider.overrideWith(
        (ref) => accountTypesStream ?? Stream.value(accountTypes),
      ),
    ],
  );
}

@Dependencies([ChartsController, ChartsSelectionController])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  test(
    'category slices receive SelectedCategorySlice as selectionKey',
    () async {
      final repo = _MockRepo();
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(const [
          CategorySlice(
            categoryId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 1000,
          ),
          CategorySlice(
            categoryId: 2,
            currencyCode: 'USD',
            totalMinorUnits: 2000,
          ),
        ]),
      );
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<TimeBucketSlice>[
          TimeBucketSlice(
            bucketStart: DateTime(2026, 5, 18),
            currencyCode: 'USD',
            totalMinorUnits: 3000,
          ),
        ]),
      );

      final container = _container(repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final data =
          container.read(chartsControllerProvider).value as ChartsDataState;
      final keys = data.chartData.slices.map((s) => s.selectionKey).toList();
      expect(
        keys,
        containsAll(<SelectedSlice>[
          const SelectedSlice.category(1),
          const SelectedSlice.category(2),
        ]),
      );
    },
  );

  test('account slices receive SelectedAccountSlice', () async {
    final repo = _MockRepo();
    when(
      () => repo.watchByAccountInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ]),
    );

    final container = _container(repo);
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.account);
    addTearDown(container.dispose);
    container.listen(chartsControllerProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final data =
        container.read(chartsControllerProvider).value as ChartsDataState;
    expect(
      data.chartData.slices.first.selectionKey,
      equals(const SelectedSlice.account(1)),
    );
  });

  group('account slices fall back to the account type (D4)', () {
    const cash = AccountType(
      id: 1,
      l10nKey: 'accountType.cash',
      icon: 'wallet',
      color: 10,
    );

    @Dependencies([ChartsController, ChartsSelectionController])
    Future<ProviderContainer> accountContainer(
      Account account, {
      Stream<Map<int, AccountType>>? accountTypes,
    }) async {
      final repo = _MockRepo();
      when(
        () => repo.watchByAccountInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value([
          AccountSlice(
            accountId: account.id,
            currencyCode: 'USD',
            totalMinorUnits: 1000,
          ),
        ]),
      );
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = _container(
        repo,
        accounts: {account.id: account},
        accountTypes: const {1: cash},
        accountTypesStream: accountTypes,
      );
      addTearDown(container.dispose);
      container
          .read(chartsSelectionControllerProvider.notifier)
          .setDimension(ChartDimension.account);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return container;
    }

    @Dependencies([ChartsController])
    ChartSlice onlySlice(ProviderContainer container) {
      final data =
          container.read(chartsControllerProvider).value as ChartsDataState;
      return data.chartData.slices.single;
    }

    @Dependencies([ChartsController, ChartsSelectionController])
    Future<ChartSlice> accountSlice(Account account) async =>
        onlySlice(await accountContainer(account));

    test("an account with no icon or colour uses its type's", () async {
      final slice = await accountSlice(
        const Account(id: 7, name: 'Cash', accountTypeId: 1, currency: _usd),
      );
      expect(slice.iconKey, 'wallet');
      expect(slice.colorIndex, 10);
    });

    test("an account's own icon and colour win over its type's", () async {
      final slice = await accountSlice(
        const Account(
          id: 7,
          name: 'Visa',
          accountTypeId: 1,
          currency: _usd,
          icon: 'credit_card',
          color: 3,
        ),
      );
      expect(slice.iconKey, 'credit_card');
      expect(slice.colorIndex, 3);
    });

    test('editing the account type re-emits the slice', () async {
      final types = StreamController<Map<int, AccountType>>();
      addTearDown(types.close);
      types.add(const {1: cash});
      final container = await accountContainer(
        const Account(id: 7, name: 'Cash', accountTypeId: 1, currency: _usd),
        accountTypes: types.stream,
      );
      expect(onlySlice(container).iconKey, 'wallet');
      expect(onlySlice(container).colorIndex, 10);

      types.add(const {
        1: AccountType(
          id: 1,
          l10nKey: 'accountType.cash',
          icon: 'savings',
          color: 4,
        ),
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(onlySlice(container).iconKey, 'savings');
      expect(onlySlice(container).colorIndex, 4);
    });
  });

  test('currency slices receive SelectedCurrencySlice', () async {
    final repo = _MockRepo();
    when(
      () => repo.watchByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        CurrencySlice(currencyCode: 'USD', totalMinorUnits: 1000),
        CurrencySlice(currencyCode: 'EUR', totalMinorUnits: 500),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ]),
    );

    final container = _container(repo);
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.currency);
    addTearDown(container.dispose);
    container.listen(chartsControllerProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final data =
        container.read(chartsControllerProvider).value as ChartsDataState;
    final keys = data.chartData.slices.map((s) => s.selectionKey).toList();
    expect(
      keys,
      containsAll(<SelectedSlice>[
        const SelectedSlice.currency('USD'),
        const SelectedSlice.currency('EUR'),
      ]),
    );
  });

  test(
    'bucket query receives translated filters when selectedSlice is set',
    () async {
      final repo = _MockRepo();
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(const [
          CategorySlice(
            categoryId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 1000,
          ),
        ]),
      );
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<TimeBucketSlice>[
          TimeBucketSlice(
            bucketStart: DateTime(2026, 5, 18),
            currencyCode: 'USD',
            totalMinorUnits: 1000,
          ),
        ]),
      );

      final container = _container(repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      clearInteractions(repo);

      container
          .read(chartsSelectionControllerProvider.notifier)
          .toggleSlice(const SelectedSlice.category(1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final capt = verify(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
          categoryId: captureAny(named: 'categoryId'),
          accountId: captureAny(named: 'accountId'),
          currencyCode: captureAny(named: 'currencyCode'),
        ),
      ).captured;
      expect(capt, contains(1));
      expect(capt, contains(null));
    },
  );
}
