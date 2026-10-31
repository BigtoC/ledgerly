import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart' as drift;
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_net_total_providers.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_controller.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_data.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/category_pie_chart.dart';
import 'package:ledgerly/features/analysis/charts/widgets/chart_legend.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/search/analysis_controller.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../unit/repositories/_harness/test_app_database.dart';

class _MockFxSvc extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Future<void> _seed(
  drift.AppDatabase db, {
  bool seedPreviousWeek = false,
}) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('EUR', 2, '€', 'currency.eur', 0, 2)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'expense', 'category.food', 'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (2, 'expense', 'category.transportation', 'car', 1, 2, 0)",
  );
  await db.customStatement(
    'INSERT INTO account_types (id, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    'INSERT INTO accounts (id, account_type_id, name, currency, '
    'opening_balance_minor_units, sort_order, is_archived) VALUES '
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
  final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  Future<void> tx(int id, int amt, int cat, String currency, {DateTime? date}) {
    return db.customStatement(
      'INSERT INTO transactions (id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
      [
        id,
        amt,
        currency,
        cat,
        (date ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
        epoch,
        epoch,
      ],
    );
  }

  await tx(1, 1000, 1, 'USD');
  await tx(2, 500, 1, 'EUR');
  await tx(3, 4000, 2, 'USD');
  if (seedPreviousWeek) {
    // USD only, so the previous week has no excluded-currency banner.
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    await tx(4, 1000, 1, 'USD', date: lastWeek);
    await tx(5, 4000, 2, 'USD', date: lastWeek);
  }
}

/// Holds back the drill-down rows so they land after the legend's reveal
/// animation has finished.
class _SlowDrilldownController extends SliceDrilldownController {
  _SlowDrilldownController(this.delay);

  final Duration delay;

  @override
  Stream<SliceDrilldownData> build() {
    final rows = super.build();
    return Stream<void>.fromFuture(Future<void>.delayed(delay))
        .asyncExpand((_) => rows);
  }
}

/// Pumps [AnalysisScreen] over a seeded in-memory database and returns the
/// container so tests can read controller state.
@Dependencies([
  AnalysisController,
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
Future<ProviderContainer> _pumpAnalysisScreen(
  WidgetTester tester, {
  Duration? drilldownDelay,
  bool seedPreviousWeek = false,
}) async {
  late drift.AppDatabase db;
  late DriftTransactionRepository repo;
  late ExchangeRateRepository fxRepo;
  late ProviderContainer container;
  await tester.runAsync(() async {
    db = newTestAppDatabase();
    repo = DriftTransactionRepository(db);
    await _seed(db, seedPreviousWeek: seedPreviousWeek);

    final fxSvc = _MockFxSvc();
    when(() => fxSvc.fetchRates(any())).thenAnswer((_) async => []);
    fxRepo = ExchangeRateRepository(db, fxSvc, const Stream<String>.empty());

    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
        initialDefaultCurrencyProvider.overrideWithValue('USD'),
        // Override analysis lookup providers so they don't require
        // categoryRepositoryProvider / accountRepositoryProvider
        // (which depend on appDatabaseProvider, not overridden here).
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
          (ref) => Stream.value({
            'USD': _usd,
            'EUR': const Currency(code: 'EUR', decimals: 2, symbol: '€'),
          }),
        ),
        chartsFxStatusProvider.overrideWith(
          (ref) => Stream.value(
            const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
          ),
        ),
        if (drilldownDelay != null)
          sliceDrilldownControllerProvider.overrideWith(
            () => _SlowDrilldownController(drilldownDelay),
          ),
      ],
    );
  });

  addTearDown(() async {
    fxRepo.dispose();
    container.dispose();
    await db.close();
  });

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
        home: AnalysisScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

@Dependencies([
  ChartsController,
  ChartsSelectionController,
  SliceDrilldownController,
  AnalysisController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
  chartsNetTotal,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  testWidgets('Analysis tab: tap food slice → 2 rows, tap again clears', (
    tester,
  ) async {
    final container = await _pumpAnalysisScreen(tester);
    expect(
      ((container.read(chartsControllerProvider).value! as ChartsDataState)
              .chartData
              .bucketTotals)
          .fold<int>(0, (sum, bucket) => sum + bucket.totalMinorUnits),
      5000,
    );
    // The legend 'Food' row may be off-screen inside the SingleChildScrollView.
    // Scope the finder to ChartLegend to avoid matching the pie-chart labels or
    // items-list header that also say "Food".
    final firstLegendFoodFinder = find.descendant(
      of: find.byType(ChartLegend),
      matching: find.text('Food'),
    );
    await tester.dragUntilVisible(
      firstLegendFoodFinder,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(firstLegendFoodFinder);
    await tester.pumpAndSettle();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      equals(const SelectedSlice.category(1)),
    );
    expect(find.byType(ListTile), findsOneWidget);
    expect(
      container
          .read(sliceDrilldownControllerProvider)
          .value!
          .rows
          .map((t) => t.id)
          .toList(),
      [1],
    );
    expect(
      ((container.read(chartsControllerProvider).value! as ChartsDataState)
              .chartData
              .bucketTotals)
          .fold<int>(0, (sum, bucket) => sum + bucket.totalMinorUnits),
      1000,
    );
    // Tap again — selection clears. After selection the items list expands
    // below the chart and the legend may scroll off-screen. Target the legend's
    // Food row specifically via find.descendant(of: ChartLegend) to avoid
    // matching the items-list header that also says "Food".
    final legendFoodFinder = find.descendant(
      of: find.byType(ChartLegend),
      matching: find.text('Food'),
    );
    await tester.dragUntilVisible(
      legendFoodFinder,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(legendFoodFinder);
    await tester.pumpAndSettle();
    expect(
      container.read(chartsSelectionControllerProvider).selectedSlice,
      isNull,
    );
    expect(find.byType(ListTile), findsNothing);
    expect(
      ((container.read(chartsControllerProvider).value! as ChartsDataState)
              .chartData
              .bucketTotals)
          .fold<int>(0, (sum, bucket) => sum + bucket.totalMinorUnits),
      5000,
    );
  });

  group('legend auto-scroll', () {
    late Finder scrollable;
    late Finder legendCard;
    late Finder pie;
    Finder legendRow(String label) => find.descendant(
      of: find.byType(ChartLegend),
      matching: find.text(label),
    );
    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    @Dependencies([
      AnalysisController,
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
    Future<ProviderContainer> pumpPhone(
      WidgetTester tester, {
      Duration? drilldownDelay,
      bool seedPreviousWeek = false,
      Size size = const Size(360, 560),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = await _pumpAnalysisScreen(
        tester,
        drilldownDelay: drilldownDelay,
        seedPreviousWeek: seedPreviousWeek,
      );
      scrollable = find.byType(SingleChildScrollView).first;
      legendCard = find.descendant(
        of: find.byType(ChartLegend),
        matching: find.byType(Card),
      );
      pie = find.byType(CategoryPieChart);
      return container;
    }

    Future<void> tapLegendRow(WidgetTester tester, String label) async {
      await tester.dragUntilVisible(
        legendRow(label),
        scrollable,
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();
      await tester.tap(legendRow(label));
    }

    void expectCardAtTop(WidgetTester tester) {
      final viewport = tester.getRect(scrollable);
      final card = tester.getRect(legendCard);
      expect(card.top, moreOrLessEquals(viewport.top, epsilon: 1));
      expect(card.bottom, lessThanOrEqualTo(viewport.bottom));
    }

    void expectWholePieVisible(WidgetTester tester) {
      final viewport = tester.getRect(scrollable);
      final pieRect = tester.getRect(pie);
      expect(pieRect.top, greaterThanOrEqualTo(viewport.top));
      expect(pieRect.bottom, lessThanOrEqualTo(viewport.bottom));
    }

    // The drill-down spinner animates forever, so pumpAndSettle would also
    // wait out the delay. Pump past the 300 ms reveal animation instead.
    Future<void> pumpPastReveal(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets(
      'selecting a category lifts the card to the top; clearing it shows '
      'the pie again',
      (tester) async {
        final container = await pumpPhone(tester);
        await tapLegendRow(tester, 'Food');
        await tester.pumpAndSettle();
        expect(
          container.read(chartsSelectionControllerProvider).selectedSlice,
          const SelectedSlice.category(1),
        );
        expectCardAtTop(tester);
        expect(
          tester.getRect(pie).bottom,
          lessThanOrEqualTo(tester.getRect(scrollable).top),
        );

        await tester.tap(legendRow('Food'));
        await tester.pumpAndSettle();
        expect(
          container.read(chartsSelectionControllerProvider).selectedSlice,
          isNull,
        );
        expectWholePieVisible(tester);
      },
    );

    testWidgets('keeps lifting the card when the drill-down rows load late', (
      tester,
    ) async {
      await pumpPhone(tester, drilldownDelay: const Duration(seconds: 1));
      await tapLegendRow(tester, 'Food');
      await pumpPastReveal(tester);
      // Only the loading spinner sits below the card so far, so the first
      // scroll stops short of the top.
      expect(find.byType(ListTile), findsNothing);
      expect(
        tester.getRect(legendCard).top,
        greaterThan(tester.getRect(scrollable).top + 1),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expectCardAtTop(tester);
    });

    testWidgets('a user drag stops the card from being lifted', (tester) async {
      await pumpPhone(tester, drilldownDelay: const Duration(seconds: 1));
      await tapLegendRow(tester, 'Food');
      await pumpPastReveal(tester);
      await tester.drag(scrollable, const Offset(0, 100));
      await pumpPastReveal(tester);
      expect(find.byType(ListTile), findsNothing);
      final pixels = position(tester).pixels;

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(position(tester).pixels, pixels);
    });

    testWidgets('switching straight to another category reveals the card', (
      tester,
    ) async {
      final container = await pumpPhone(tester);
      await tapLegendRow(tester, 'Food');
      await tester.pumpAndSettle();
      expectCardAtTop(tester);

      await tester.drag(scrollable, const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.tap(legendRow('Transportation'));
      await tester.pumpAndSettle();
      expect(
        container.read(chartsSelectionControllerProvider).selectedSlice,
        const SelectedSlice.category(2),
      );
      expectCardAtTop(tester);
    });

    testWidgets('a period change that clears the selection shows the pie', (
      tester,
    ) async {
      final container = await pumpPhone(tester);
      await tapLegendRow(tester, 'Food');
      await tester.pumpAndSettle();
      expectCardAtTop(tester);

      final selection = container.read(chartsSelectionControllerProvider);
      container
          .read(chartsSelectionControllerProvider.notifier)
          .setPeriod(
            selection.period == PeriodType.year
                ? PeriodType.month
                : PeriodType.year,
          );
      await tester.pumpAndSettle();
      expect(
        container.read(chartsSelectionControllerProvider).selectedSlice,
        isNull,
      );
      expectWholePieVisible(tester);
    });

    testWidgets(
      'stepping to a period without the currency banner shows the whole pie',
      (tester) async {
        final container = await pumpPhone(tester, seedPreviousWeek: true);
        // This week has an unconverted EUR row, so a banner sits above the
        // pie; last week has none, so its pie sits higher on the page.
        expect(find.byType(MaterialBanner), findsOneWidget);
        await tapLegendRow(tester, 'Food');
        await tester.pumpAndSettle();
        expectCardAtTop(tester);

        container
            .read(chartsSelectionControllerProvider.notifier)
            .previousPeriod();
        await tester.pumpAndSettle();
        expect(find.byType(MaterialBanner), findsNothing);
        expectWholePieVisible(tester);
      },
    );

    testWidgets('a resize long after selecting does not move the page', (
      tester,
    ) async {
      // Tall enough that the card can never reach the top, so the reveal
      // never finishes on its own.
      await pumpPhone(tester, size: const Size(360, 700));
      await tapLegendRow(tester, 'Food');
      await tester.pumpAndSettle();
      expect(
        tester.getRect(legendCard).top,
        greaterThan(tester.getRect(scrollable).top + 1),
      );
      await tester.pump(const Duration(seconds: 5));
      final pixels = position(tester).pixels;

      tester.view.physicalSize = const Size(360, 600);
      await tester.pumpAndSettle();
      expect(position(tester).pixels, pixels);
    });
  });
}
