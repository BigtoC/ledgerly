// Whole-page check for AC 10 (plan Step 8 item 2): the Analysis page at 2×
// text scale, in light and dark, with Roboto loaded, the account filter on
// and the All period over more than 24 months, so the trend scrolls.
//
// The whole file loads Roboto, so keep any test that needs the default test
// font out of it.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/service_providers.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/account_filter_button.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_summary_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_trend_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/period_selector.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:ledgerly/ui/features/analysis/views/analysis_screen.dart';

import '../../../support/test_app.dart';

class _MockFxService extends Mock implements ExchangeRateService {}

/// Long enough that the account pill has to ellipsize it.
const _accountName = 'Everyday rewards credit card';

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    final bytes = File(
      '$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Lets Drift's real-timer queries finish, then pumps their results.
Future<void> _settleDrift(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
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
  chartsDateBounds,
])
void main() {
  setUpAll(_loadRoboto);

  for (final (themeName, theme) in [
    ('light', lightTheme),
    ('dark', darkTheme),
  ]) {
    for (final width in [360.0, 390.0]) {
      testWidgets('$themeName, $width wide, 2×: account filter on, All over '
          '30 months renders without overflow', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fx = _MockFxService();
        when(() => fx.fetchRates(any())).thenAnswer((_) async => []);
        late AppDatabase db;
        late ProviderContainer container;
        late int accountId;
        await tester.runAsync(() async {
          db = newTestAppDatabase();
          await runTestSeed(db);
          final cashType = await getAccountTypeId(db, 'accountType.cash');
          final food = await getSeededCategoryId(db, 'category.food');
          final salary = await getSeededCategoryId(
            db,
            'category.income.salary',
          );
          accountId = (await createTestAccount(
            db,
            name: _accountName,
            currencyCode: 'USD',
            accountTypeId: cashType,
          )).id;
          final now = DateTime.now();
          // 30 months back, so All covers more than 24 and the trend
          // scrolls.
          for (final (date, category, amount) in [
            (DateTime(now.year, now.month - 30, 10), food, 1234567),
            (DateTime(now.year, now.month - 12, 10), food, 89000),
            (DateTime(now.year, now.month, 1), salary, 98765432),
            (DateTime(now.year, now.month, 1), food, 4500),
          ]) {
            await insertTestTransaction(
              db,
              accountId: accountId,
              categoryId: category,
              currencyCode: 'USD',
              amountMinorUnits: amount,
              date: date,
            );
          }
          container = makeTestContainer(
            db: db,
            extraOverrides: [
              exchangeRateServiceProvider.overrideWithValue(fx),
              initialDefaultCurrencyProvider.overrideWithValue('USD'),
            ],
          );
        });
        addTearDown(() async {
          container.dispose();
          await tester.runAsync(db.close);
        });

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const AnalysisScreen(),
            ),
          ),
        );
        await _settleDrift(tester);
        container
            .read(chartsSelectionControllerProvider.notifier)
            .setAccountFilter(accountId);
        await _settleDrift(tester);
        await tester.tap(find.text('All'));
        await _settleDrift(tester);

        expect(tester.takeException(), isNull);
        expect(
          container.read(chartsSelectionControllerProvider).period,
          PeriodType.all,
        );

        // App bar: fixed 64, its title clamped at 1.5× (D1): 24/32 → 48.
        expect(tester.getSize(find.byType(AppBar)).height, 64);
        expect(tester.getSize(find.text('Analysis')).height, 48);

        // The account pill shows the filtered account, inside the row.
        final pill = find.byType(AccountFilterButton);
        expect(
          find.descendant(of: pill, matching: find.text(_accountName)),
          findsOneWidget,
        );
        expect(tester.getRect(pill).right, lessThanOrEqualTo(width));

        // Period track: every segment keeps its 44 hit height.
        for (final label in ['Day', 'Week', 'Month', 'Year', 'All']) {
          final segment = find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DecoratedBox),
              )
              .first;
          expect(
            tester.getSize(segment).height,
            greaterThanOrEqualTo(44),
            reason: label,
          );
          final text = find.descendant(
            of: find.byType(PeriodSelector),
            matching: find.text(label),
          );
          expect(text, findsOneWidget);
          // Laid out in full, so a too-wide label is scaled down, not
          // clipped (D23).
          final paragraph = tester.renderObject<RenderBox>(text);
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.01),
            reason: '$label is clipped',
          );
        }

        // Summary amounts are never cut off (D2): each one lays out in full
        // on one line, scaled by at most 1, inside the card. The totals are
        // the seeded rows above: expense, income and their net.
        final card = find.byType(ChartsSummaryCard);
        final cardRect = tester.getRect(card);
        for (final amount in [r'$13,280.67', r'$987,654.32', r'+$974,373.65']) {
          final text = find.descendant(of: card, matching: find.text(amount));
          expect(text, findsOneWidget, reason: amount);
          final paragraph = tester.renderObject<RenderBox>(text);
          final natural = paragraph.size;
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(natural.width + 0.01),
            reason: '$amount is clipped',
          );
          final rect = tester.getRect(text);
          expect(rect.width, greaterThan(0), reason: amount);
          expect(
            rect.width,
            lessThanOrEqualTo(natural.width + 0.01),
            reason: '$amount is scaled up',
          );
          expect(rect.left, greaterThanOrEqualTo(cardRect.left - 0.01));
          expect(rect.right, lessThanOrEqualTo(cardRect.right + 0.01));
        }

        // The trend card is there and its 30-plus months scroll sideways.
        final trend = find.byType(ChartsTrendCard);
        expect(trend, findsOneWidget);
        expect(tester.getRect(trend).width, width - 32);
        final chart = tester.widget<DailyBarChart>(find.byType(DailyBarChart));
        expect(chart.series.buckets.length, greaterThan(24));
        expect(
          find.descendant(
            of: trend,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  (w.axisDirection == AxisDirection.right ||
                      w.axisDirection == AxisDirection.left),
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.getSize(find.text('Monthly spending')).height,
          greaterThanOrEqualTo(48),
        );
      });
    }
  }
}
