import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/category_slice.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/time_bucket_slice.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_section.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  SliceDrilldownController,
  chartsNetTotal,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  testWidgets('renders pie + legend with single category slice', (
    tester,
  ) async {
    await _pumpSection(tester);

    expect(find.text('Food'), findsWidgets);
    // Period, type and dimension toggles mark the selected segment by fill
    // only, without a leading check icon.
    expect(find.byIcon(Icons.check), findsNothing);
  });

  group('trend card visibility by period', () {
    testWidgets('Day hides the trend chart even with buckets', (tester) async {
      await _pumpSection(tester, period: PeriodType.day);

      expect(find.text('Food'), findsWidgets);
      expect(find.byType(DailyBarChart), findsNothing);
    });

    for (final period in [PeriodType.week, PeriodType.month, PeriodType.year]) {
      testWidgets('${period.name} shows the trend chart with buckets', (
        tester,
      ) async {
        await _pumpSection(tester, period: period);

        expect(find.byType(DailyBarChart), findsOneWidget);
      });
    }
  });
}

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  SliceDrilldownController,
  chartsNetTotal,
])
Future<void> _pumpSection(WidgetTester tester, {PeriodType? period}) async {
  final repo = _MockTxRepo();
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
        totalMinorUnits: 5000,
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
        totalMinorUnits: 5000,
      ),
    ]),
  );

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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
        analysisCategoriesByIdProvider.overrideWith(
          (ref) => Stream.value({
            1: const Category(
              id: 1,
              type: CategoryType.expense,
              l10nKey: 'cat.test',
              customName: 'Food',
              icon: 'restaurant',
              color: 0,
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
  await tester.pumpAndSettle();
  if (period != null) {
    // Drive the period through the production selection controller.
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(chartsSelectionControllerProvider.notifier)
        .setPeriod(period);
    await tester.pumpAndSettle();
  }
}
