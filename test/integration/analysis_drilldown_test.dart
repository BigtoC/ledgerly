import 'dart:async';
import 'dart:ui' show GestureSettings;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart' as drift;
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/ui/features/analysis/views/analysis_screen.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_data.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/category_pie_chart.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/chart_legend.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_trend_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/slice_transaction_row.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../unit/repositories/_harness/test_app_database.dart';

import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';

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
      'INSERT INTO transactions (uuid, id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (hex(randomblob(16)), ?, ?, ?, ?, 1, ?, ?, ?)',
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

/// Holds back the drill-down rows until [release] completes, so the test
/// decides when they land, on a fake clock or a device's real one.
class _SlowDrilldownController extends SliceDrilldownController {
  _SlowDrilldownController(this.release);

  final Future<void> release;

  @override
  Stream<SliceDrilldownData> build() {
    final rows = super.build();
    return Stream<void>.fromFuture(release).asyncExpand((_) => rows);
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
  chartsAccountFilterOptions,
  chartsRange,
  chartsDateBounds,
])
Future<ProviderContainer> _pumpAnalysisScreen(
  WidgetTester tester, {
  Future<void>? drilldownRelease,
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
        if (drilldownRelease != null)
          sliceDrilldownControllerProvider.overrideWith(
            () => _SlowDrilldownController(drilldownRelease),
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
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AnalysisScreen(),
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
  chartsAccountFilterOptions,
  chartsRange,
  chartsDateBounds,
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
    expect(find.byType(SliceTransactionRow), findsOneWidget);
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
    expect(find.byType(SliceTransactionRow), findsNothing);
    expect(
      ((container.read(chartsControllerProvider).value! as ChartsDataState)
              .chartData
              .bucketTotals)
          .fold<int>(0, (sum, bucket) => sum + bucket.totalMinorUnits),
      5000,
    );
  });

  group('selection auto-scroll', () {
    late Finder scrollable;
    late Finder legendRows;
    late Finder trendCard;
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
      chartsAccountFilterOptions,
      chartsRange,
      chartsDateBounds,
    ])
    Future<ProviderContainer> pumpPhone(
      WidgetTester tester, {
      Future<void>? drilldownRelease,
      bool seedPreviousWeek = false,
      // A 432 dp viewport under the 64 dp app bar: short enough that the
      // page scrolls the trend card to the top.
      Size size = const Size(360, 496),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      // A device reports its own touch slop in physical pixels, which the
      // pixel ratio of 1 above turns into logical ones (21 on a Pixel
      // emulator). Pin the host's 18 so the drags below scroll the same
      // distance everywhere.
      tester.view.gestureSettings = const GestureSettings(
        physicalTouchSlop: kTouchSlop,
      );
      addTearDown(tester.view.reset);
      final container = await _pumpAnalysisScreen(
        tester,
        drilldownRelease: drilldownRelease,
        seedPreviousWeek: seedPreviousWeek,
      );
      scrollable = find.byType(SingleChildScrollView).first;
      legendRows = find.byType(ChartLegend);
      // The bar chart is what a selection lifts to the top.
      trendCard = find.byType(ChartsTrendCard);
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

    void expectAtTop(WidgetTester tester, Finder target) {
      final viewport = tester.getRect(scrollable);
      final card = tester.getRect(target);
      expect(card.top, moreOrLessEquals(viewport.top, epsilon: 1));
      expect(card.bottom, lessThanOrEqualTo(viewport.bottom));
    }

    void expectCardAtTop(WidgetTester tester) => expectAtTop(tester, trendCard);

    void expectWholePieVisible(WidgetTester tester) {
      final viewport = tester.getRect(scrollable);
      final pieRect = tester.getRect(pie);
      expect(pieRect.top, greaterThanOrEqualTo(viewport.top));
      expect(pieRect.bottom, lessThanOrEqualTo(viewport.bottom));
    }

    // The drill-down spinner animates until the rows are released, so
    // pumpAndSettle would time out. Pump past the 300 ms reveal animation
    // instead.
    Future<void> pumpPastReveal(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets(
      'selecting a category lifts the trend card to the top; clearing it '
      'shows the pie again',
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
          tester.getRect(legendRows).bottom,
          lessThanOrEqualTo(tester.getRect(scrollable).top),
        );

        // The ranked rows are above the page now; clear from the trend
        // card's filter chip.
        await tester.tap(
          find.descendant(of: trendCard, matching: find.byIcon(Icons.close)),
        );
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
      // Tall enough that the transactions card's loading state alone cannot
      // fill the space below the trend card, short enough that the loaded
      // row can.
      final rows = Completer<void>();
      await pumpPhone(
        tester,
        drilldownRelease: rows.future,
        size: const Size(360, 510),
      );
      await tapLegendRow(tester, 'Food');
      await pumpPastReveal(tester);
      // Only the loading state sits below the trend card so far, so the
      // first scroll stops short of the top.
      expect(find.byType(SliceTransactionRow), findsNothing);
      expect(
        tester.getRect(trendCard).top,
        greaterThan(tester.getRect(scrollable).top + 1),
      );

      rows.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SliceTransactionRow), findsOneWidget);
      expectCardAtTop(tester);
    });

    testWidgets('a user drag stops the card from being lifted', (tester) async {
      final rows = Completer<void>();
      // Tall enough that the card can never reach the top, so the reveal is
      // still following when the drag comes.
      await pumpPhone(
        tester,
        drilldownRelease: rows.future,
        size: const Size(360, 700),
      );
      await tapLegendRow(tester, 'Food');
      await pumpPastReveal(tester);
      expect(
        tester.getRect(trendCard).top,
        greaterThan(tester.getRect(scrollable).top + 1),
      );
      await tester.drag(scrollable, const Offset(0, 100));
      await pumpPastReveal(tester);
      expect(find.byType(SliceTransactionRow), findsNothing);
      final pixels = position(tester).pixels;

      rows.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SliceTransactionRow), findsOneWidget);
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
        tester.getRect(trendCard).top,
        greaterThan(tester.getRect(scrollable).top + 1),
      );
      await tester.pump(const Duration(seconds: 5));
      final pixels = position(tester).pixels;

      tester.view.physicalSize = const Size(360, 600);
      await tester.pumpAndSettle();
      expect(position(tester).pixels, pixels);
    });

    testWidgets('on Day, which has no trend card, lifts the ranked rows', (
      tester,
    ) async {
      // Without the trend card there is less below the rows, so the page
      // must be shorter for them to reach the top.
      final container = await pumpPhone(tester, size: const Size(360, 360));
      // Day keeps the week's anchor; step on to today, where the rows are.
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      )..setPeriod(PeriodType.day);
      while (!selection.isAtCurrentPeriod()) {
        selection.nextPeriod();
      }
      await tester.pumpAndSettle();
      expect(trendCard, findsNothing);

      await tapLegendRow(tester, 'Food');
      await tester.pumpAndSettle();
      expect(
        container.read(chartsSelectionControllerProvider).selectedSlice,
        const SelectedSlice.category(1),
      );
      expectAtTop(tester, legendRows);
    });
  });
}
