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
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/category_slice.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/time_bucket_slice.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/category_pie_chart.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/chart_legend.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_breakdown_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_section.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_summary_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/dimension_toggle.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/period_selector.dart';
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
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
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

  testWidgets('period selector sits flush; the cards get 16 sides and '
      '24 bottom', (tester) async {
    await _pumpSection(tester);

    final section = tester.getRect(find.byType(ChartsSection));
    final selector = tester.getRect(find.byType(PeriodSelector));
    expect(selector.top, section.top);
    expect(selector.left, section.left);
    expect(selector.right, section.right);

    // The trend chart is the last block in the column at Week.
    final trend = tester.getRect(find.byType(DailyBarChart));
    expect(trend.left - section.left, 16);
    expect(section.right - trend.right, 16);
    expect(section.bottom - trend.bottom, 24);
  });

  group('breakdown card', () {
    Finder inCard(Finder f) =>
        find.descendant(of: find.byType(ChartsBreakdownCard), matching: f);

    testWidgets('hosts the title, chips, donut and ranked rows', (
      tester,
    ) async {
      await _pumpSection(tester);

      expect(find.byType(ChartsBreakdownCard), findsOneWidget);
      expect(inCard(find.text('Expense breakdown')), findsOneWidget);
      expect(inCard(find.byType(DimensionChips)), findsOneWidget);
      expect(inCard(find.byType(CategoryPieChart)), findsOneWidget);
      expect(inCard(find.byType(ChartLegend)), findsOneWidget);
      expect(find.byType(SegmentedButton<ChartDimension>), findsNothing);
      // The trend chart is not part of the breakdown card.
      expect(inCard(find.byType(DailyBarChart)), findsNothing);
    });

    testWidgets('sits 12 below the block above it, inside the 16 margin', (
      tester,
    ) async {
      await _pumpSection(tester);

      final card = tester.getRect(find.byType(ChartsBreakdownCard));
      // The section fills the scroll view's width.
      final section = tester.getRect(find.byType(SingleChildScrollView));
      expect(card.left, section.left + 16);
      expect(card.right, section.right - 16);
      expect(
        card.top,
        tester.getRect(find.byType(ChartsSummaryCard)).bottom + 12,
      );
    });

    testWidgets('chips switch the dimension and report it as selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpSection(tester);

      await tester.tap(inCard(find.text('Account')));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      expect(
        container.read(chartsSelectionControllerProvider).dimension,
        ChartDimension.account,
      );
      expect(
        tester.getSemantics(inCard(find.text('Account'))),
        isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('an empty period shows the empty state inside the card', (
      tester,
    ) async {
      await _pumpSection(tester, slices: const [], withBuckets: false);

      expect(inCard(find.byType(BreakdownEmptyState)), findsOneWidget);
      expect(inCard(find.text('No expense in this period')), findsOneWidget);
      expect(
        inCard(find.text('Switch to Income or pick another period.')),
        findsOneWidget,
      );
      expect(find.text('No transactions yet'), findsNothing);
      expect(find.byType(CategoryPieChart), findsNothing);
    });

    testWidgets('FX banners stay above the card', (tester) async {
      await _pumpSection(
        tester,
        slices: const [
          CategorySlice(
            categoryId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 5000,
          ),
          CategorySlice(
            categoryId: 1,
            currencyCode: 'EUR',
            totalMinorUnits: 300,
          ),
        ],
      );

      final banner = find.byType(MaterialBanner);
      expect(banner, findsOneWidget);
      expect(
        find.descendant(of: find.byType(ChartsBreakdownCard), matching: banner),
        findsNothing,
      );
      expect(
        tester.getRect(banner).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(ChartsBreakdownCard)).top),
      );
    });
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

  group('summary card', () {
    testWidgets('replaces the type toggle and the net pill, 16 below the '
        'period selector', (tester) async {
      await _pumpSection(tester);

      expect(find.byType(ChartsSummaryCard), findsOneWidget);
      expect(find.byType(SegmentedButton<CategoryType>), findsNothing);
      expect(
        tester.getTopLeft(find.byType(ChartsSummaryCard)).dy -
            tester.getBottomLeft(find.byType(PeriodSelector)).dy,
        16,
      );
    });

    testWidgets('tapping the Income tile charts income', (tester) async {
      final repo = await _pumpSection(tester);

      await tester.tap(find.byKey(const ValueKey('summaryTile.income')));
      await tester.pumpAndSettle();

      verify(
        () => repo.watchByCategoryInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: CategoryType.income,
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('recalculates the net when the period changes', (tester) async {
      await _pumpSection(tester);
      const colors = AnalysisColors.light;

      expect(find.text(r'+$30.00'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(r'+$30.00')).style?.color,
        colors.incText,
      );

      await tester.tap(find.byTooltip('Previous period'));
      await tester.pumpAndSettle();

      expect(find.text(r'+$30.00'), findsNothing);
      expect(find.text(r'-$7.00'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(r'-$7.00')).style?.color,
        colors.expText,
      );
    });
  });
}

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  SliceDrilldownController,
  chartsNetTotal,
])
Future<_MockTxRepo> _pumpSection(
  WidgetTester tester, {
  PeriodType? period,
  List<CategorySlice> slices = const [
    CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 5000),
  ],
  bool withBuckets = true,
}) async {
  final repo = _MockTxRepo();
  // The first period queried has income +\$30.00; any other period has
  // expense \$7.00. Keyed on the first query rather than DateTime.now() so
  // a run that crosses a week boundary cannot flake.
  DateTime? firstStart;
  when(
    () => repo.watchTotalsByTypeInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      accountId: any(named: 'accountId'),
    ),
  ).thenAnswer((invocation) {
    final start = invocation.namedArguments[#start] as DateTime;
    firstStart ??= start;
    return Stream.value({
      'USD': start == firstStart
          ? (expense: 0, income: 3000)
          : (expense: 700, income: 0),
    });
  });
  when(
    () => repo.watchByCategoryInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) => Stream.value(slices));
  when(
    () => repo.watchByAccountInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) => Stream.value(const <AccountSlice>[]));
  when(
    () => repo.watchTimeBucketsInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      granularity: any(named: 'granularity'),
    ),
  ).thenAnswer(
    (_) => Stream.value(<TimeBucketSlice>[
      if (withBuckets)
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
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: ChartsSection()),
        ),
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
  return repo;
}
