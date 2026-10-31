import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/charts/charts_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_net_total_provider.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_section.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_controller.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _MockFxSvc extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
  chartsNetTotal,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  testWidgets('stale selection clears when slice no longer in emission', (
    tester,
  ) async {
    final repo = _MockRepo();
    final controller = StreamController<List<CategorySlice>>.broadcast();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) => controller.stream);
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
          totalMinorUnits: 5000,
        ),
      ]),
    );
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value(const []));

    final fxSvc = _MockFxSvc();
    when(() => fxSvc.fetchRates(any())).thenAnswer((_) async => []);
    final fxDb = newTestAppDatabase();
    final fxRepo = ExchangeRateRepository(
      fxDb,
      fxSvc,
      const Stream<String>.empty(),
    );
    addTearDown(() async {
      await controller.close();
      fxRepo.dispose();
      await fxDb.close();
    });

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
        analysisCategoriesByIdProvider.overrideWith(
          (ref) => Stream.value({
            1: const Category(
              id: 1,
              type: CategoryType.expense,
              l10nKey: 'category.food',
              icon: 'restaurant',
              color: 0,
            ),
            2: const Category(
              id: 2,
              type: CategoryType.expense,
              l10nKey: 'category.transportation',
              icon: 'car',
              color: 1,
            ),
          }),
        ),
        analysisAccountsByIdProvider.overrideWith(
          (ref) => Stream.value(const <int, Account>{}),
        ),
        chartsCurrenciesByCodeProvider.overrideWith(
          (ref) => Stream.value({'USD': _usd}),
        ),
        chartsFxStatusProvider.overrideWith(
          (ref) => Stream.value(
            const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
          ),
        ),
        initialDefaultCurrencyProvider.overrideWithValue('USD'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ChartsSection())),
        ),
      ),
    );

    // First emission contains category 1.
    controller.add(const [
      CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 5000),
    ]);
    await tester.pumpAndSettle();
    // Select category 1 directly via the notifier — simpler than scroll+tap.
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(1));
    // Use pump(duration) instead of pumpAndSettle: after toggleSlice the
    // ChartsController re-subscribes on the broadcast stream (no pending
    // replay) so the UI stays in ChartsLoading with an infinitely-animating
    // spinner. pumpAndSettle would time out waiting for the spinner to stop.
    // Two pump() calls flush pending microtasks + one frame.
    await tester.pump();
    await tester.pump();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      equals(const SelectedSlice.category(1)),
    );

    // Second emission has no slice with that selectionKey — the self-heal
    // listener in ChartsSection should clear the selection.
    controller.add(const [
      CategorySlice(categoryId: 2, currencyCode: 'USD', totalMinorUnits: 3000),
    ]);
    // pump() + pump() flushes the stream emission and the listener callback
    // without waiting for the infinite loading spinner to stop.
    await tester.pump();
    await tester.pump();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      isNull,
    );
  });
}
