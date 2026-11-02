// ChartsController passes the account filter to every query it scopes —
// spec § Account filter → What it affects; acceptance criterion 5(d).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/category_slice.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/currency_slice.dart';
import 'package:ledgerly/domain/models/time_bucket_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../repositories/_harness/test_app_database.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

ProviderContainer _container(_MockRepo repo) {
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
        }),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, Account>{}),
      ),
    ],
  );
}

/// Stubs every slice and bucket query with one USD row, matching any
/// `accountId` so the filtered calls resolve too.
void _stubAll(_MockRepo repo) {
  when(
    () => repo.watchByCategoryInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      accountId: any(named: 'accountId'),
    ),
  ).thenAnswer(
    (_) => Stream.value(const [
      CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
    ]),
  );
  when(
    () => repo.watchByCurrencyInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      accountId: any(named: 'accountId'),
    ),
  ).thenAnswer(
    (_) => Stream.value(const [
      CurrencySlice(currencyCode: 'USD', totalMinorUnits: 1000),
    ]),
  );
  when(
    () => repo.watchByAccountInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
    ),
  ).thenAnswer(
    (_) => Stream.value(const [
      AccountSlice(accountId: 4, currencyCode: 'USD', totalMinorUnits: 1000),
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
}

@Dependencies([ChartsController, ChartsSelectionController])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    _stubAll(repo);
    container = _container(repo);
    addTearDown(container.dispose);
  });

  @Dependencies([ChartsSelectionController])
  ChartsSelectionController selection() =>
      container.read(chartsSelectionControllerProvider.notifier);

  @Dependencies([ChartsController])
  Future<void> settle() async {
    container.listen(chartsControllerProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  /// `(categoryId, accountId, currencyCode)` of the latest bucket query.
  (Object?, Object?, Object?) lastBucketFilters() {
    final captured = verify(
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
    final n = captured.length;
    return (captured[n - 3], captured[n - 2], captured[n - 1]);
  }

  Object? lastCategoryAccountId() => verify(
    () => repo.watchByCategoryInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      accountId: captureAny(named: 'accountId'),
    ),
  ).captured.last;

  Object? lastCurrencyAccountId() => verify(
    () => repo.watchByCurrencyInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      accountId: captureAny(named: 'accountId'),
    ),
  ).captured.last;

  test('without a filter the category and bucket queries get a null '
      'accountId', () async {
    await settle();

    expect(lastCategoryAccountId(), isNull);
    expect(lastBucketFilters(), (null, null, null));
  });

  test('Category dimension: the filter reaches the category and bucket '
      'queries', () async {
    selection().setAccountFilter(3);
    await settle();

    expect(lastCategoryAccountId(), 3);
    expect(lastBucketFilters(), (null, 3, null));
  });

  test('Currency dimension: the filter reaches the currency and bucket '
      'queries', () async {
    selection().setDimension(ChartDimension.currency);
    selection().setAccountFilter(3);
    await settle();

    expect(lastCurrencyAccountId(), 3);
    expect(lastBucketFilters(), (null, 3, null));
  });

  test('a category slice under the filter queries buckets by category AND '
      'account', () async {
    selection().setAccountFilter(3);
    await settle();

    selection().toggleSlice(const SelectedSlice.category(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(lastBucketFilters(), (1, 3, null));
  });

  test('a currency slice under the filter queries buckets by currency AND '
      'account', () async {
    selection().setDimension(ChartDimension.currency);
    selection().setAccountFilter(3);
    await settle();

    selection().toggleSlice(const SelectedSlice.currency('USD'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(lastBucketFilters(), (null, 3, 'USD'));
  });

  test(
    'an account slice (no filter) queries buckets by its own account',
    () async {
      selection().setDimension(ChartDimension.account);
      await settle();

      selection().toggleSlice(const SelectedSlice.account(4));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(lastBucketFilters(), (null, 4, null));
    },
  );

  test('clearing the filter goes back to all-accounts queries', () async {
    selection().setAccountFilter(3);
    await settle();

    selection().setAccountFilter(null);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(lastCategoryAccountId(), isNull);
    expect(lastBucketFilters(), (null, null, null));
  });
}
