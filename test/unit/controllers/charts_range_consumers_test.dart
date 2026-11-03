// Every Analysis range consumer queries the range chartsRangeProvider
// resolves, so the All period's range reaches each surface from one place.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/category_slice.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/time_bucket_slice.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

/// A range no period would produce from the default anchor.
final ChartsRange _range = (start: DateTime(2020, 2), end: DateTime(2020, 7));

ProviderContainer _container(
  TransactionRepository repo, {
  AsyncValue<ChartsRange>? range,
  Stream<DateBounds?> Function()? dateBounds,
}) {
  final container = ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      // With [dateBounds], the real chartsRange resolves All from them.
      if (dateBounds != null)
        chartsDateBoundsProvider.overrideWith((ref) => dateBounds())
      else
        chartsRangeProvider.overrideWithValue(range ?? AsyncData(_range)),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd}),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
      initialDefaultCurrencyProvider.overrideWithValue('USD'),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, Category>{}),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, Account>{}),
      ),
      analysisAccountTypesByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, AccountType>{}),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _flush() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

@Dependencies([
  chartsAccountFilterOptions,
  ChartsController,
  ChartsSelectionController,
  chartsNetTotal,
  SliceDrilldownController,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  late _MockTxRepo repo;

  setUp(() {
    repo = _MockTxRepo();
  });

  test('ChartsController queries slices and buckets in the range and '
      'charts from its start', () async {
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const [
        CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 5),
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

    final container = _container(repo);
    ChartsState? latest;
    container.listen(
      chartsControllerProvider,
      (_, next) => latest = next.value,
      fireImmediately: true,
    );
    await _flush();

    verify(
      () => repo.watchByCategoryInRange(
        start: _range.start,
        end: _range.end,
        type: any(named: 'type'),
        accountId: any(named: 'accountId'),
      ),
    ).called(1);
    verify(
      () => repo.watchTimeBucketsInRange(
        start: _range.start,
        end: _range.end,
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).called(1);
    expect((latest! as ChartsDataState).chartData.anchorDate, _range.start);
  });

  test('chartsNetTotal queries the totals in the range', () async {
    when(
      () => repo.watchTotalsByTypeInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) => Stream.value({'USD': (expense: 1, income: 2)}));

    final container = _container(repo);
    container.listen(chartsNetTotalProvider, (_, _) {});
    await _flush();

    verify(
      () => repo.watchTotalsByTypeInRange(
        start: _range.start,
        end: _range.end,
        accountId: any(named: 'accountId'),
      ),
    ).called(1);
    expect(container.read(chartsNetTotalProvider)?.netMinorUnits, 1);
  });

  test('SliceDrilldownController queries the slice in the range', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value(const <Transaction>[]));

    final container = _container(repo);
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(1));
    container.listen(sliceDrilldownControllerProvider, (_, _) {});
    await _flush();

    verify(
      () => repo.watchTransactionsForSliceInRange(
        start: _range.start,
        end: _range.end,
        type: any(named: 'type'),
        categoryId: 1,
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).called(1);
  });

  test(
    'chartsAccountFilterOptions queries the account totals in the range',
    () async {
      when(
        () => repo.watchByAccountInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) => Stream.value(const <AccountSlice>[]));

      final container = _container(repo);
      container.listen(chartsAccountFilterOptionsProvider, (_, _) {});
      await _flush();

      verify(
        () => repo.watchByAccountInRange(
          start: _range.start,
          end: _range.end,
          type: any(named: 'type'),
        ),
      ).called(1);
    },
  );

  group('loading and failed ranges', () {
    void stubCharts() {
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) => Stream.value(const <CategorySlice>[]));
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
    }

    test('ChartsController shows an error when All\'s date bounds fail, '
        'and Retry re-reads them', () async {
      stubCharts();
      var reads = 0;
      final container = _container(
        repo,
        dateBounds: () {
          reads++;
          return Stream.error(StateError('bounds'));
        },
      );
      container
          .read(chartsSelectionControllerProvider.notifier)
          .setPeriod(PeriodType.all);
      ChartsState? latest;
      container.listen(
        chartsControllerProvider,
        (_, next) => latest = next.value,
        fireImmediately: true,
      );
      await _flush();

      expect(latest, isA<ChartsError>());
      expect(reads, 1);

      container.read(chartsControllerProvider.notifier).retry();
      await _flush();

      expect(reads, 2);
    });

    test('a bounds error after data still makes Retry re-read them', () async {
      stubCharts();
      var reads = 0;
      final bounds = StreamController<DateBounds?>();
      addTearDown(bounds.close);
      final container = _container(
        repo,
        dateBounds: () {
          reads++;
          return reads == 1 ? bounds.stream : const Stream.empty();
        },
      );
      container
          .read(chartsSelectionControllerProvider.notifier)
          .setPeriod(PeriodType.all);
      ChartsState? latest;
      container.listen(
        chartsControllerProvider,
        (_, next) => latest = next.value,
        fireImmediately: true,
      );
      bounds.add((first: DateTime(2025, 3, 4), last: DateTime(2025, 6, 1)));
      await _flush();
      expect(latest, isNot(isA<ChartsError>()));

      bounds.addError(StateError('bounds'));
      await _flush();
      expect(latest, isA<ChartsError>());

      container.read(chartsControllerProvider.notifier).retry();
      await _flush();

      expect(reads, 2);
    });

    test('SliceDrilldownController waits while the range loads', () async {
      final container = _container(repo, range: const AsyncLoading());
      container
          .read(chartsSelectionControllerProvider.notifier)
          .toggleSlice(const SelectedSlice.category(1));
      container.listen(sliceDrilldownControllerProvider, (_, _) {});
      await _flush();

      expect(container.read(sliceDrilldownControllerProvider).isLoading, true);
      verifyNever(
        () => repo.watchTransactionsForSliceInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      );
    });

    test('SliceDrilldownController fails when the range does', () async {
      final container = _container(
        repo,
        range: AsyncError(StateError('bounds'), StackTrace.empty),
      );
      container
          .read(chartsSelectionControllerProvider.notifier)
          .toggleSlice(const SelectedSlice.category(1));
      container.listen(sliceDrilldownControllerProvider, (_, _) {});
      await _flush();

      expect(
        container.read(sliceDrilldownControllerProvider).error,
        isA<StateError>(),
      );
      verifyNever(
        () => repo.watchTransactionsForSliceInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      );
    });
  });
}
