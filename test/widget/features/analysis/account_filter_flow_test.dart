// Account filter across the Analysis page — spec § Account filter;
// acceptance criteria 5, 6 and 12. Drives the real AnalysisScreen with a
// mocked TransactionRepository whose answers depend on `accountId`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/category_slice.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/currency_slice.dart';
import 'package:ledgerly/domain/models/time_bucket_slice.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/account_filter_button.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/category_pie_chart.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/chart_legend.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_breakdown_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_summary_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_trend_card.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:ledgerly/ui/features/analysis/views/analysis_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

const _cash = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd);
const _visa = Account(
  id: 2,
  name: 'Visa card',
  accountTypeId: 2,
  currency: _usd,
);

/// No transactions at all.
const _savings = Account(
  id: 3,
  name: 'Savings',
  accountTypeId: 2,
  currency: _usd,
);

/// Per-account fixture. Expense: Cash has Food $30 + Transport $10, Visa
/// has Food $12. Income: Cash $22, Visa $8, with no income categories or
/// buckets, so the Income chart is empty.
_MockTxRepo _repo() {
  final repo = _MockTxRepo();
  when(
    () => repo.watchTotalsByTypeInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      accountId: any(named: 'accountId'),
    ),
  ).thenAnswer(
    (invocation) =>
        Stream.value(switch (invocation.namedArguments[#accountId]) {
          null => {'USD': (expense: 5200, income: 3000)},
          2 => {'USD': (expense: 1200, income: 800)},
          1 => {'USD': (expense: 4000, income: 2200)},
          _ => <String, ({int expense, int income})>{},
        }),
  );
  when(
    () => repo.watchByCategoryInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      accountId: any(named: 'accountId'),
    ),
  ).thenAnswer((invocation) {
    if (invocation.namedArguments[#type] == CategoryType.income) {
      return Stream.value(const <CategorySlice>[]);
    }
    return Stream.value(switch (invocation.namedArguments[#accountId]) {
      null => const [
        CategorySlice(
          categoryId: 1,
          currencyCode: 'USD',
          totalMinorUnits: 4200,
        ),
        CategorySlice(
          categoryId: 2,
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ],
      2 => const [
        CategorySlice(
          categoryId: 1,
          currencyCode: 'USD',
          totalMinorUnits: 1200,
        ),
      ],
      1 => const [
        CategorySlice(
          categoryId: 1,
          currencyCode: 'USD',
          totalMinorUnits: 3000,
        ),
        CategorySlice(
          categoryId: 2,
          currencyCode: 'USD',
          totalMinorUnits: 1000,
        ),
      ],
      _ => const <CategorySlice>[],
    });
  });
  when(
    () => repo.watchByAccountInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
    ),
  ).thenAnswer(
    (invocation) => Stream.value(
      invocation.namedArguments[#type] == CategoryType.income
          ? const [
              AccountSlice(
                accountId: 1,
                currencyCode: 'USD',
                totalMinorUnits: 2200,
              ),
              AccountSlice(
                accountId: 2,
                currencyCode: 'USD',
                totalMinorUnits: 800,
              ),
            ]
          : const [
              AccountSlice(
                accountId: 1,
                currencyCode: 'USD',
                totalMinorUnits: 4000,
              ),
              AccountSlice(
                accountId: 2,
                currencyCode: 'USD',
                totalMinorUnits: 1200,
              ),
            ],
    ),
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
      CurrencySlice(currencyCode: 'USD', totalMinorUnits: 5200),
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
  ).thenAnswer((invocation) {
    final start = invocation.namedArguments[#start] as DateTime;
    // Like the category slices, the buckets carry expense only.
    if (invocation.namedArguments[#type] == CategoryType.income) {
      return Stream.value(const <TimeBucketSlice>[]);
    }
    final total = switch (invocation.namedArguments[#accountId]) {
      null => 5200,
      2 => 1200,
      1 => 4000,
      _ => 0,
    };
    return Stream.value([
      if (total > 0)
        TimeBucketSlice(
          bucketStart: start,
          currencyCode: 'USD',
          totalMinorUnits: total,
        ),
    ]);
  });
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
  return repo;
}

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
])
Future<ProviderContainer> _pumpScreen(WidgetTester tester) async {
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

  final container = ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(_repo()),
      exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
      initialDefaultCurrencyProvider.overrideWithValue('USD'),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd}),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value({
          1: const Category(
            id: 1,
            type: CategoryType.expense,
            customName: 'Food',
            icon: 'restaurant',
            color: 0,
          ),
          2: const Category(
            id: 2,
            type: CategoryType.expense,
            customName: 'Transport',
            icon: 'directions_car',
            color: 1,
          ),
        }),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value({1: _cash, 2: _visa, 3: _savings}),
      ),
      analysisAccountTypesByIdProvider.overrideWith(
        (ref) => Stream.value({
          1: const AccountType(id: 1, icon: 'wallet', color: 3),
          2: const AccountType(id: 2, icon: 'savings', color: 5),
        }),
      ),
    ],
  );
  addTearDown(container.dispose);

  // A phone width (so the sheet opens as a bottom sheet), tall enough that
  // the summary, breakdown and trend cards all lay out.
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AnalysisScreen(),
      ),
    ),
  );
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Opens the account sheet from the app-bar button and taps [name].
Future<void> _pick(WidgetTester tester, String name) async {
  await tester.tap(find.byType(AccountFilterButton));
  await _settle(tester);
  await tester.tap(
    find.descendant(of: find.byType(BottomSheet), matching: find.text(name)),
  );
  await _settle(tester);
}

Finder _inside(Type card, Finder f) =>
    find.descendant(of: find.byType(card), matching: f);

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
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  testWidgets('picking an account filters the whole page (AC 5, AC 12)', (
    tester,
  ) async {
    final container = await _pumpScreen(tester);

    // All accounts.
    expect(
      _inside(AccountFilterButton, find.text('All accounts')),
      findsOneWidget,
    );
    expect(_inside(CategoryPieChart, find.text('Total expense')), findsOne);
    expect(_inside(CategoryPieChart, find.text(r'$52.00')), findsOneWidget);
    expect(_inside(ChartLegend, find.text('Transport')), findsOneWidget);
    expect(_inside(ChartsSummaryCard, find.text(r'$52.00')), findsOneWidget);
    expect(_inside(ChartsSummaryCard, find.text(r'$30.00')), findsOneWidget);

    await _pick(tester, 'Visa card');

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      2,
    );
    // (a) The button names the account.
    expect(
      _inside(AccountFilterButton, find.text('Visa card')),
      findsOneWidget,
    );
    // (b) Only that account's categories.
    expect(_inside(ChartLegend, find.text('Food')), findsOneWidget);
    expect(_inside(ChartLegend, find.text('Transport')), findsNothing);
    // (c) The donut centre names the account, (d) with its total.
    expect(
      _inside(CategoryPieChart, find.text('Visa card expense')),
      findsOneWidget,
    );
    expect(_inside(CategoryPieChart, find.text(r'$12.00')), findsOneWidget);
    // AC 12: the tiles and net show only Visa card's expense and income.
    expect(_inside(ChartsSummaryCard, find.text(r'$12.00')), findsOneWidget);
    expect(_inside(ChartsSummaryCard, find.text(r'$8.00')), findsOneWidget);
    expect(_inside(ChartsSummaryCard, find.text(r'-$4.00')), findsOneWidget);
    expect(_inside(ChartsSummaryCard, find.text(r'$52.00')), findsNothing);
    // The trend subtitle is prefixed with the account.
    expect(_inside(ChartsTrendCard, find.text('Visa card · ')), findsOneWidget);
  });

  testWidgets('"All accounts" clears the filter', (tester) async {
    final container = await _pumpScreen(tester);
    await _pick(tester, 'Visa card');

    await _pick(tester, 'All accounts');

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      isNull,
    );
    expect(
      _inside(AccountFilterButton, find.text('All accounts')),
      findsOneWidget,
    );
    expect(_inside(CategoryPieChart, find.text('Total expense')), findsOne);
    expect(_inside(ChartLegend, find.text('Transport')), findsOneWidget);
    expect(_inside(ChartsSummaryCard, find.text(r'$52.00')), findsOneWidget);
    expect(find.text('Visa card · '), findsNothing);
  });

  testWidgets('the filter survives a type change; the empty state then '
      'names the account', (tester) async {
    final container = await _pumpScreen(tester);
    await _pick(tester, 'Visa card');

    container.read(chartsSelectionControllerProvider.notifier).toggleType();
    await _settle(tester);

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      2,
    );
    // The fixture has no income categories: the empty state names the
    // account.
    expect(
      _inside(
        ChartsBreakdownCard,
        find.text('No income on Visa card in this period'),
      ),
      findsOneWidget,
    );
    expect(
      _inside(
        ChartsBreakdownCard,
        find.text('Pick another account or period.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an account with nothing in the period shows the account '
      'empty state', (tester) async {
    await _pumpScreen(tester);

    await _pick(tester, 'Savings');

    expect(
      _inside(
        ChartsBreakdownCard,
        find.text('No expense on Savings in this period'),
      ),
      findsOneWidget,
    );
    expect(
      _inside(
        ChartsBreakdownCard,
        find.text('Pick another account or period.'),
      ),
      findsOneWidget,
    );
    expect(_inside(AccountFilterButton, find.text('Savings')), findsOneWidget);
  });

  testWidgets('the sheet lists accounts by the current type\'s amount, the '
      'zero account last', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byType(AccountFilterButton));
    await _settle(tester);

    double top(String name) => tester
        .getTopLeft(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(name),
          ),
        )
        .dy;
    expect(top('All accounts'), lessThan(top('Cash')));
    expect(top('Cash'), lessThan(top('Visa card')));
    expect(top('Visa card'), lessThan(top('Savings')));
    expect(find.text(r'$52.00 · 100.0%'), findsOneWidget);
    expect(find.text(r'$40.00 · 76.9%'), findsOneWidget);
    expect(find.text(r'$12.00 · 23.1%'), findsOneWidget);
    expect(find.text(r'$0.00 · 0.0%'), findsOneWidget);
  });

  testWidgets('picking an account in the Account dimension switches to '
      'Category (AC 6)', (tester) async {
    final container = await _pumpScreen(tester);
    await tester.tap(_inside(ChartsBreakdownCard, find.text('Account')));
    await _settle(tester);
    expect(
      container.read(chartsSelectionControllerProvider).dimension,
      ChartDimension.account,
    );

    await _pick(tester, 'Visa card');

    final selection = container.read(chartsSelectionControllerProvider);
    expect(selection.accountFilterId, 2);
    expect(selection.dimension, ChartDimension.category);
    expect(_inside(ChartLegend, find.text('Food')), findsOneWidget);
    expect(
      _inside(CategoryPieChart, find.text('Visa card expense')),
      findsOneWidget,
    );
  });

  testWidgets('the bridge in an account drill-down applies the filter, '
      'switches to Category and clears the slice (AC 7)', (tester) async {
    final container = await _pumpScreen(tester);
    await tester.tap(_inside(ChartsBreakdownCard, find.text('Account')));
    await _settle(tester);
    await tester.tap(_inside(ChartLegend, find.text('Visa card')));
    await _settle(tester);

    await tester.tap(find.text('See categories in Visa card'));
    await _settle(tester);

    final selection = container.read(chartsSelectionControllerProvider);
    expect(selection.accountFilterId, 2);
    expect(selection.dimension, ChartDimension.category);
    expect(selection.selectedSlice, isNull);
    expect(find.text('See categories in Visa card'), findsNothing);
    expect(
      _inside(AccountFilterButton, find.text('Visa card')),
      findsOneWidget,
    );
    expect(_inside(ChartLegend, find.text('Food')), findsOneWidget);
    expect(_inside(ChartLegend, find.text('Transport')), findsNothing);
  });

  testWidgets('choosing the Account chip clears the filter (AC 4)', (
    tester,
  ) async {
    final container = await _pumpScreen(tester);
    await _pick(tester, 'Visa card');

    await tester.tap(_inside(ChartsBreakdownCard, find.text('Account')));
    await _settle(tester);

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      isNull,
    );
    expect(
      _inside(AccountFilterButton, find.text('All accounts')),
      findsOneWidget,
    );
    expect(_inside(CategoryPieChart, find.text('Total expense')), findsOne);
  });

  testWidgets('the active pill uses the sel fill', (tester) async {
    await _pumpScreen(tester);
    await _pick(tester, 'Visa card');

    final pill = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('accountFilterPill')),
    );
    expect((pill.decoration! as BoxDecoration).color, AnalysisColors.light.sel);
  });
}
