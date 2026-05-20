// ChartsController tests — Tasks 9 + 10 cover period/dimension/type
// commands; Tasks 11–13 add conversion, blocked state, warm-start.
//
// Tests stub the four repository range methods via mocktail and use
// real `analysisCategoriesByIdProvider` / `analysisAccountsByIdProvider`
// stubs so the controller can resolve labels.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_slice.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/currency_slice.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/charts/charts_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../repositories/_harness/test_app_database.dart';

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

class _MockTxRepo extends Mock implements TransactionRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

const _defaultCategories = {
  1: Category(
    id: 1,
    type: CategoryType.expense,
    l10nKey: 'cat.test',
    customName: 'Food',
    icon: 'restaurant',
    color: 0,
  ),
};

ProviderContainer _container({
  required TransactionRepository repo,
  Map<int, Category> categories = _defaultCategories,
  Map<int, Account> accounts = const {},
  Map<String, Currency> currencies = const {'USD': _usd},
  ChartsFxStatus? fxStatus,
}) {
  // Real `ExchangeRateRepository` against an in-memory DB with a mock
  // service. `refreshAll` becomes a silent no-op because `fetchRates`
  // returns an empty list — the test only cares that the controller can
  // fire-and-forget the call without exploding.
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
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value(categories),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(accounts),
      ),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value(currencies),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          fxStatus ??
              const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
      initialDefaultCurrencyProvider.overrideWithValue(
        fxStatus?.defaultCurrencyCode ?? 'USD',
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
    registerFallbackValue('');
  });

  group('ChartsController — single-currency category dimension', () {
    late _MockTxRepo repo;

    setUp(() {
      repo = _MockTxRepo();
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<CategorySlice>[
          const CategorySlice(
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
    });

    test('default state is week / expense / category and emits data', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      ChartsState? latest;
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) => latest = next.valueOrNull,
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sub.close();

      expect(latest, isA<ChartsDataState>());
      final data = (latest! as ChartsDataState).chartData;
      expect(data.period, PeriodType.week);
      expect(data.type, CategoryType.expense);
      expect(data.dimension, ChartDimension.category);
      expect(data.slices, hasLength(1));
      expect(data.slices.first.totalMinorUnits, 1000);
    });

    test('setPeriod(day) re-subscribes with a 24h range', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      clearInteractions(repo);

      container
          .read(chartsControllerProvider.notifier)
          .setPeriod(PeriodType.day);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final captured = verify(
        () => repo.watchByCategoryInRange(
          start: captureAny(named: 'start'),
          end: captureAny(named: 'end'),
          type: any(named: 'type'),
        ),
      ).captured;
      final start = captured[0] as DateTime;
      final end = captured[1] as DateTime;
      expect(end.difference(start), const Duration(days: 1));
    });

    test('previousPeriod shifts the anchor backwards', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final initial =
          container.read(chartsControllerProvider).valueOrNull
              as ChartsDataState;
      final initialAnchor = initial.chartData.anchorDate;

      container.read(chartsControllerProvider.notifier).previousPeriod();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final after =
          (container.read(chartsControllerProvider).valueOrNull
                  as ChartsDataState)
              .chartData
              .anchorDate;
      expect(after.isBefore(initialAnchor), isTrue);
    });

    test('toggleType switches to income and resubscribes', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));

      container.read(chartsControllerProvider.notifier).toggleType();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: CategoryType.income,
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('toggleDimension(account) re-subscribes to account stream', () async {
      when(
        () => repo.watchByAccountInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<AccountSlice>[
          const AccountSlice(
            accountId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 500,
          ),
        ]),
      );

      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));

      container
          .read(chartsControllerProvider.notifier)
          .toggleDimension(ChartDimension.account);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(
        () => repo.watchByAccountInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('empty slices emit ChartsEmpty', () async {
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) => Stream.value(const <CategorySlice>[]));
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
        ),
      ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = _container(repo: repo);
      addTearDown(container.dispose);

      final completer = Completer<ChartsState>();
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) {
          final v = next.valueOrNull;
          if (v is ChartsEmpty && !completer.isCompleted) {
            completer.complete(v);
          }
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final result = await completer.future.timeout(const Duration(seconds: 1));
      expect(result, isA<ChartsEmpty>());
    });
  });

  group('ChartsController — multi-currency conversion', () {
    late _MockTxRepo repo;

    setUp(() {
      repo = _MockTxRepo();
    });

    ChartsFxStatus fx(Map<String, int> ratesScaledE9, String defaultCurrency) {
      final rates = <String, ExchangeRateMetadata>{};
      final now = DateTime.now().subtract(const Duration(minutes: 5));
      for (final entry in ratesScaledE9.entries) {
        rates[entry.key] = ExchangeRateMetadata(
          rateScaledE9: entry.value,
          fetchedAt: now,
        );
      }
      return ChartsFxStatus(defaultCurrencyCode: defaultCurrency, rates: rates);
    }

    test('category dimension converts EUR→USD and regroups by id', () async {
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<CategorySlice>[
          const CategorySlice(
            categoryId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 1000,
          ),
          const CategorySlice(
            categoryId: 1,
            currencyCode: 'EUR',
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
        ),
      ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = _container(
        repo: repo,
        currencies: {
          'USD': _usd,
          'EUR': const Currency(
            code: 'EUR',
            decimals: 2,
            symbol: '€',
            nameL10nKey: 'currency.eur',
          ),
        },
        // 1 EUR = 1.10 USD → 1_100_000_000.
        fxStatus: fx({'EUR→USD': 1100000000}, 'USD'),
      );
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final state = container.read(chartsControllerProvider).valueOrNull;
      expect(state, isA<ChartsDataState>());
      final data = (state! as ChartsDataState).chartData;
      expect(data.slices, hasLength(1));
      expect(data.slices.first.totalMinorUnits, 2100);
      expect(data.displayCurrencyCode, 'USD');
      expect(data.grandTotalMinorUnits, 2100);
      expect(data.mixedCurrencies, isFalse);
      expect(data.slices.first.fraction, closeTo(1.0, 0.0001));
    });

    test('category dimension blocks only when ALL rates are missing', () async {
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<CategorySlice>[
          const CategorySlice(
            categoryId: 1,
            currencyCode: 'EUR',
            totalMinorUnits: 1000,
          ),
          const CategorySlice(
            categoryId: 1,
            currencyCode: 'JPY',
            totalMinorUnits: 1000,
          ),
        ]),
      );
      when(
        () => repo.watchByCurrencyInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<CurrencySlice>[
          const CurrencySlice(currencyCode: 'EUR', totalMinorUnits: 1000),
          const CurrencySlice(currencyCode: 'JPY', totalMinorUnits: 1000),
        ]),
      );
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
        ),
      ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = _container(repo: repo, fxStatus: fx(const {}, 'USD'));
      addTearDown(container.dispose);

      // Week+Category+AllMissing+cold-start → auto-switches to currency
      // dimension; the resulting state is ChartsDataState, not blocked.
      ChartsState? latest;
      final sub = container.listen<AsyncValue<ChartsState>>(
        chartsControllerProvider,
        (_, next) => latest = next.valueOrNull,
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sub.close();

      expect(latest, isA<ChartsDataState>());
      final data = (latest! as ChartsDataState).chartData;
      expect(data.dimension, ChartDimension.currency);
      expect(data.autoSwitchedFromCategoryDimension, isTrue);
    });

    test(
      'category dimension partial-converts when only some rates missing',
      () async {
        when(
          () => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) => Stream.value(<CategorySlice>[
            const CategorySlice(
              categoryId: 1,
              currencyCode: 'USD',
              totalMinorUnits: 1000,
            ),
            const CategorySlice(
              categoryId: 1,
              currencyCode: 'EUR',
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
          ),
        ).thenAnswer(
          (_) => Stream.value(<TimeBucketSlice>[
            TimeBucketSlice(
              bucketStart: DateTime(2026, 5, 18),
              currencyCode: 'USD',
              totalMinorUnits: 1000,
            ),
            TimeBucketSlice(
              bucketStart: DateTime(2026, 5, 18),
              currencyCode: 'EUR',
              totalMinorUnits: 1000,
            ),
          ]),
        );

        final container = _container(
          repo: repo,
          currencies: {
            'USD': _usd,
            'EUR': const Currency(
              code: 'EUR',
              decimals: 2,
              symbol: '€',
              nameL10nKey: 'currency.eur',
            ),
          },
          fxStatus: fx(const {}, 'USD'),
        );
        addTearDown(container.dispose);
        container.listen(chartsControllerProvider, (_, _) {});
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final state = container.read(chartsControllerProvider).valueOrNull;
        expect(state, isA<ChartsDataState>());
        final data = (state! as ChartsDataState).chartData;
        // Only USD slice survives → fraction is 1.0, total is 1000.
        expect(data.slices, hasLength(1));
        expect(data.slices.first.totalMinorUnits, 1000);
        expect(data.grandTotalMinorUnits, 1000);
        expect(data.excludedCurrencyCodes, equals(<String>['EUR']));
        expect(data.bucketTotals, hasLength(1));
        expect(data.bucketTotals.first.totalMinorUnits, 1000);
      },
    );

    test(
      'currency dimension renders source-currency slices when rates missing',
      () async {
        when(
          () => repo.watchByCurrencyInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) => Stream.value(<CurrencySlice>[
            const CurrencySlice(currencyCode: 'USD', totalMinorUnits: 1000),
            const CurrencySlice(currencyCode: 'EUR', totalMinorUnits: 1000),
          ]),
        );
        when(
          () => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) => Stream.value(const <CategorySlice>[]));
        when(
          () => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          ),
        ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

        final container = _container(repo: repo, fxStatus: fx(const {}, 'USD'));
        addTearDown(container.dispose);
        container.listen(chartsControllerProvider, (_, _) {});
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Switch to currency dimension (this also clears auto-switch flag).
        container
            .read(chartsControllerProvider.notifier)
            .toggleDimension(ChartDimension.currency);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final state = container.read(chartsControllerProvider).valueOrNull;
        expect(state, isA<ChartsDataState>());
        final data = (state! as ChartsDataState).chartData;
        expect(data.slices, hasLength(2));
        expect(data.displayCurrencyCode, isNull);
        expect(data.mixedCurrencies, isTrue);
      },
    );

    test(
      'auto-switches to currency dimension on cold-start missing rates',
      () async {
        when(
          () => repo.watchByCategoryInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) => Stream.value(<CategorySlice>[
            const CategorySlice(
              categoryId: 1,
              currencyCode: 'EUR',
              totalMinorUnits: 1000,
            ),
          ]),
        );
        when(
          () => repo.watchByCurrencyInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) => Stream.value(<CurrencySlice>[
            const CurrencySlice(currencyCode: 'EUR', totalMinorUnits: 1000),
          ]),
        );
        when(
          () => repo.watchTimeBucketsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
            type: any(named: 'type'),
            granularity: any(named: 'granularity'),
          ),
        ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

        final container = _container(repo: repo, fxStatus: fx(const {}, 'USD'));
        addTearDown(container.dispose);

        ChartsState? latest;
        final sub = container.listen<AsyncValue<ChartsState>>(
          chartsControllerProvider,
          (_, next) => latest = next.valueOrNull,
          fireImmediately: true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        sub.close();

        expect(latest, isA<ChartsDataState>());
        final data = (latest! as ChartsDataState).chartData;
        expect(data.dimension, ChartDimension.currency);
        expect(data.autoSwitchedFromCategoryDimension, isTrue);
      },
    );

    test('dismissAutoSwitchBanner re-emits with the flag cleared', () async {
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<CategorySlice>[
          const CategorySlice(
            categoryId: 1,
            currencyCode: 'EUR',
            totalMinorUnits: 1000,
          ),
        ]),
      );
      when(
        () => repo.watchByCurrencyInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) => Stream.value(<CurrencySlice>[
          const CurrencySlice(currencyCode: 'EUR', totalMinorUnits: 1000),
        ]),
      );
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
        ),
      ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));

      final container = _container(repo: repo, fxStatus: fx(const {}, 'USD'));
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var data =
          (container.read(chartsControllerProvider).valueOrNull!
                  as ChartsDataState)
              .chartData;
      expect(data.autoSwitchedFromCategoryDimension, isTrue);

      container
          .read(chartsControllerProvider.notifier)
          .dismissAutoSwitchBanner();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      data =
          (container.read(chartsControllerProvider).valueOrNull!
                  as ChartsDataState)
              .chartData;
      expect(data.autoSwitchedFromCategoryDimension, isFalse);
      expect(data.dimension, ChartDimension.currency);
    });
  });

  group('ChartsController — boundary', () {
    late _MockTxRepo repo;

    setUp(() {
      repo = _MockTxRepo();
      when(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) => Stream.value(const <CategorySlice>[]));
      when(
        () => repo.watchTimeBucketsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          granularity: any(named: 'granularity'),
        ),
      ).thenAnswer((_) => Stream.value(const <TimeBucketSlice>[]));
    });

    test('nextPeriod is a no-op when already at the current period', () async {
      final container = _container(repo: repo);
      addTearDown(container.dispose);
      container.listen(chartsControllerProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      final controller = container.read(chartsControllerProvider.notifier);
      controller.nextPeriod();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(chartsControllerProvider).valueOrNull;
      final calls = verify(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).callCount;
      expect(calls, 1, reason: 'nextPeriod at current should not resubscribe');
      expect(state, anyOf(isA<ChartsEmpty>(), isA<ChartsDataState>()));
    });
  });
}
