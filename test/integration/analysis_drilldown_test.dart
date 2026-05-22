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
import 'package:ledgerly/features/analysis/charts/slice_drilldown_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/chart_legend.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../unit/repositories/_harness/test_app_database.dart';

class _MockFxSvc extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Future<void> _seed(drift.AppDatabase db) async {
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
  Future<void> tx(int id, int amt, int cat, String currency) {
    return db.customStatement(
      'INSERT INTO transactions (id, amount_minor_units, currency, '
      'category_id, account_id, date, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, 1, ?, ?, ?)',
      [
        id,
        amt,
        currency,
        cat,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        epoch,
        epoch,
      ],
    );
  }

  await tx(1, 1000, 1, 'USD');
  await tx(2, 500, 1, 'EUR');
  await tx(3, 4000, 2, 'USD');
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  testWidgets('Analysis tab: tap food slice → 2 rows, tap again clears', (
    tester,
  ) async {
    late drift.AppDatabase db;
    late DriftTransactionRepository repo;
    late ExchangeRateRepository fxRepo;
    late ProviderContainer container;
    await tester.runAsync(() async {
      db = newTestAppDatabase();
      repo = DriftTransactionRepository(db);
      await _seed(db);

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
    expect(
      ((container.read(chartsControllerProvider).valueOrNull!
                  as ChartsDataState)
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
          .valueOrNull!
          .rows
          .map((t) => t.id)
          .toList(),
      [1],
    );
    expect(
      ((container.read(chartsControllerProvider).valueOrNull!
                  as ChartsDataState)
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
      ((container.read(chartsControllerProvider).valueOrNull!
                  as ChartsDataState)
              .chartData
              .bucketTotals)
          .fold<int>(0, (sum, bucket) => sum + bucket.totalMinorUnits),
      5000,
    );
  });
}
