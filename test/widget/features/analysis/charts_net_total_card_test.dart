// ChartsNetTotalCard — the small box above the Analysis chart showing
// income minus expense for the period picked in the time picker.

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
import 'package:ledgerly/features/analysis/charts/charts_net_total_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_section.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_controller.dart';
import 'package:ledgerly/features/analysis/charts/widgets/charts_net_total_card.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

const _localizations = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<void> _pumpCard(
  WidgetTester tester,
  ChartsNetTotal? net, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [chartsNetTotalProvider.overrideWithValue(net)],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        localizationsDelegates: _localizations,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ChartsNetTotalCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ChartsNetTotal _net(int? minorUnits, {List<String> excluded = const []}) =>
    ChartsNetTotal(
      currency: _usd,
      netMinorUnits: minorUnits,
      excludedCurrencyCodes: excluded,
    );

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

@Dependencies([
  chartsNetTotal,
  ChartsSelectionController,
  ChartsController,
  SliceDrilldownController,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  group('ChartsNetTotalCard', () {
    testWidgets('shows a positive net in green with a plus sign', (
      tester,
    ) async {
      await _pumpCard(tester, _net(2005));

      expect(find.text(r'+$20.05'), findsOneWidget);
      // Darker shades in light mode keep WCAG AA contrast on
      // surfaceContainer.
      expect(_colorOf(tester, r'+$20.05'), Colors.green.shade900);
    });

    testWidgets('shows a negative net in pink', (tester) async {
      await _pumpCard(tester, _net(-1250));

      expect(find.text(r'-$12.50'), findsOneWidget);
      expect(_colorOf(tester, r'-$12.50'), Colors.pink.shade700);
    });

    testWidgets('uses lighter green and pink in dark mode', (tester) async {
      await _pumpCard(tester, _net(100), brightness: Brightness.dark);
      expect(_colorOf(tester, r'+$1.00'), Colors.green.shade400);

      await _pumpCard(tester, _net(-100), brightness: Brightness.dark);
      expect(_colorOf(tester, r'-$1.00'), Colors.pinkAccent);
    });

    testWidgets('shows a zero net in neither green nor pink', (tester) async {
      await _pumpCard(tester, _net(0));

      final color = _colorOf(tester, r'$0.00');
      expect(color, isNot(Colors.green.shade900));
      expect(color, isNot(Colors.pink.shade700));
    });

    testWidgets('shows a dash, not a zero, when no currency had a rate', (
      tester,
    ) async {
      await _pumpCard(tester, _net(null, excluded: ['JPY']));

      expect(find.text('—'), findsOneWidget);
      expect(find.text(r'$0.00'), findsNothing);
      expect(find.text('Excluded: JPY — no exchange rate yet'), findsOneWidget);
    });

    testWidgets('shows only the amount, with "Net" kept for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, _net(2005));

      expect(find.text('Net'), findsNothing);
      expect(find.textContaining('≈'), findsNothing);
      expect(find.bySemanticsLabel(r'Net +$20.05'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('is a pill like the segmented buttons above it', (
      tester,
    ) async {
      await _pumpCard(tester, _net(2005));

      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(r'+$20.05'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((box.decoration! as ShapeDecoration).shape, const StadiumBorder());
    });

    testWidgets('uses the segmented buttons\' label font size', (tester) async {
      await _pumpCard(tester, _net(2005));

      final labelLarge = Theme.of(tester.element(find.text(r'+$20.05')))
          .textTheme
          .labelLarge!;
      expect(
        tester.widget<Text>(find.text(r'+$20.05')).style?.fontSize,
        labelLarge.fontSize,
      );
    });

    testWidgets('names currencies left out for missing rates', (tester) async {
      await _pumpCard(tester, _net(500, excluded: ['EUR', 'JPY']));

      expect(
        find.text('Excluded: EUR, JPY — no exchange rate yet'),
        findsOneWidget,
      );
    });

    testWidgets('renders nothing until the net has loaded', (tester) async {
      await _pumpCard(tester, null);

      expect(find.byType(Text), findsNothing);
    });
  });

  testWidgets('ChartsSection recalculates the net when the period changes', (
    tester,
  ) async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(const <CategorySlice>[
        CategorySlice(categoryId: 1, currencyCode: 'USD', totalMinorUnits: 1),
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
    // The first period queried nets +$30.00; any other period nets -$7.00.
    // Keyed on the first query rather than DateTime.now() so a run that
    // crosses a week boundary cannot flake.
    DateTime? firstStart;
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((invocation) {
      final start = invocation.namedArguments[#start] as DateTime;
      firstStart ??= start;
      return Stream.value({'USD': start == firstStart ? 3000 : -700});
    });

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
          localizationsDelegates: _localizations,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ChartsSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'+$30.00'), findsOneWidget);
    expect(_colorOf(tester, r'+$30.00'), Colors.green.shade900);

    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();

    expect(find.text(r'+$30.00'), findsNothing);
    expect(find.text(r'-$7.00'), findsOneWidget);
    expect(_colorOf(tester, r'-$7.00'), Colors.pink.shade700);
  });
}
