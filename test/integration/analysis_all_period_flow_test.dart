// Integration test: on the All period, adding or deleting the earliest
// transaction in Drift moves the covered range, the navigator caption and
// the trend's first month (spec § All time, plan D13).

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart' as drift;
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:ledgerly/ui/features/analysis/views/analysis_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../unit/repositories/_harness/test_app_database.dart';

class _MockFxSvc extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

/// Seeds one USD expense dated now.
Future<void> _seed(drift.AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    'INSERT INTO categories (id, type, l10n_key, icon, color, sort_order, '
    "is_archived) VALUES (1, 'expense', 'category.food', 'restaurant', 0, 1, 0)",
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
  await _insertTx(db, id: 1, date: DateTime.now());
}

/// Inserts a USD expense, notifying the transactions streams.
Future<void> _insertTx(
  drift.AppDatabase db, {
  required int id,
  required DateTime date,
}) {
  final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return db.customInsert(
    'INSERT INTO transactions (id, amount_minor_units, currency, '
    'category_id, account_id, date, created_at, updated_at) '
    "VALUES (?, 1000, 'USD', 1, 1, ?, ?, ?)",
    variables: [
      Variable.withInt(id),
      Variable.withInt(date.millisecondsSinceEpoch ~/ 1000),
      Variable.withInt(epoch),
      Variable.withInt(epoch),
    ],
    updates: {db.transactions},
  );
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
  chartsRange,
  chartsAccountFilterOptions,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  testWidgets('adding and deleting the earliest transaction moves the All '
      'range, its caption and the trend', (tester) async {
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
          analysisCategoriesByIdProvider.overrideWith(
            (ref) => Stream.value({
              1: const Category(
                id: 1,
                type: CategoryType.expense,
                l10nKey: 'category.food',
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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AnalysisScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final earlier = DateTime(now.year, now.month - 3, 15);
    String month(DateTime d) => DateFormat.yMMM('en').format(d);
    List<DateTime> trendMonths() => [
      for (final b
          in tester
              .widget<DailyBarChart>(find.byType(DailyBarChart))
              .series
              .buckets)
        b.bucketStart,
    ];
    Future<void> settleDrift() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('All time'), findsOneWidget);
    expect(find.text('${month(now)} – ${month(now)}'), findsOneWidget);
    expect(trendMonths(), [thisMonth]);

    await tester.runAsync(() => _insertTx(db, id: 2, date: earlier));
    await settleDrift();

    expect(container.read(chartsRangeProvider).value, (
      start: DateTime(earlier.year, earlier.month),
      end: DateTime(now.year, now.month + 1),
    ));
    expect(find.text('${month(earlier)} – ${month(now)}'), findsOneWidget);
    expect(trendMonths(), [
      for (var m = 0; m < 4; m++) DateTime(earlier.year, earlier.month + m),
    ]);

    await tester.runAsync(() => repo.delete(2));
    await settleDrift();

    expect(container.read(chartsRangeProvider).value, (
      start: thisMonth,
      end: DateTime(now.year, now.month + 1),
    ));
    expect(find.text('${month(now)} – ${month(now)}'), findsOneWidget);
    expect(trendMonths(), [thisMonth]);
  });
}
