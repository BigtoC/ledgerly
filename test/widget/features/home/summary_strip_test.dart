// SummaryStrip widget tests — Wave 3 §4.3.
//
// Covers: single-currency case, multi-currency case (two currency
// groups), all-zero / empty case (placeholders).
//
// Phase 2: SummaryStrip is a ConsumerWidget that reads
// `exchangeRatesProvider`. Tests use a `ProviderScope` to inject a
// rates-stream override. Where rates are absent the strip falls back to
// per-currency render (mirrors the old behavior). Where a rate is
// supplied for a non-default currency, the strip renders a unified
// converted total in the default currency.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/home/widgets/summary_strip.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');

Widget _wrap(Widget child, {Map<String, int>? rates}) => ProviderScope(
  overrides: [
    exchangeRatesProvider.overrideWith(
      (_) => Stream.value(rates ?? const <String, int>{}),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // Home renders the strip inside a scroll view; several currency
    // cards are taller than the test surface.
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

@Dependencies([exchangeRates])
void main() {
  testWidgets('SS01: single currency — signed nets and tiles rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'USD': (expense: 1500, income: 500)},
          monthNetByCurrency: {'USD': -1000},
          currenciesByCode: {'USD': _usd},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('USD'), findsNothing);
    expect(find.text(r'-$15.00'), findsOneWidget);
    expect(find.text(r'+$5.00'), findsOneWidget);
    // Day net (income − expense) and month net are both -$10.00.
    expect(find.text(r'-$10.00'), findsNWidgets(2));
    // Default-currency-only case: no ≈ prefix.
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets(
    'SS02a: multi-currency with rates available — unified USD group',
    (tester) async {
      // USD: today expense 100 = $1.00, monthNet -100 = -$1.00
      // JPY: today expense 500 = ¥500 → at 0.01 USD/JPY = 500 JPY minor units
      // (JPY has 0 decimals) converted to USD (2 decimals):
      //   500 * 0.01 = 5 USD → scale-shift +2 → 500 USD minor units = $5.00.
      // monthNet -500 JPY → -$5.00.
      // Unified totals: expense = $1.00 + $5.00 = $6.00; monthNet = -$6.00.
      await tester.pumpWidget(
        _wrap(
          const SummaryStrip(
            todayTotalsByCurrency: {
              'USD': (expense: 100, income: 0),
              'JPY': (expense: 500, income: 0),
            },
            monthNetByCurrency: {'USD': -100, 'JPY': -500},
            currenciesByCode: {'USD': _usd, 'JPY': _jpy},
            locale: 'en_US',
            defaultCurrency: 'USD',
          ),
          rates: {'JPY→USD': (0.01 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();
      // Unified group with the ≈ prefix.
      expect(find.textContaining('≈'), findsWidgets);
      // Expense tile, day net and month net all read ≈ -$6.00.
      expect(find.text(r'≈ -$6.00'), findsNWidgets(3));
      expect(find.text(r'≈ $0.00'), findsOneWidget);
      // No JPY fallback group because the JPY→USD rate is available.
      expect(find.text('¥500'), findsNothing);
    },
  );

  testWidgets('SS02b: multi-currency with rates missing — fallback groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {
            'USD': (expense: 100, income: 0),
            'JPY': (expense: 500, income: 0),
          },
          monthNetByCurrency: {'USD': -100, 'JPY': -500},
          currenciesByCode: {'USD': _usd, 'JPY': _jpy},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Default USD group renders (canShowUnified true: USD is convertible).
    // Expense tile, day net and month net each read -$1.00.
    expect(find.text(r'-$1.00'), findsNWidgets(3));
    // JPY shows in the fallback group below the "Unconverted" separator.
    expect(find.text(r'-¥500'), findsNWidgets(3));
    // Separator header is present.
    expect(find.text('Unconverted'), findsOneWidget);
  });

  testWidgets('SS03: empty maps — placeholder dashes for each label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {},
          monthNetByCurrency: {},
          currenciesByCode: {},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Day net, month net, income and expense.
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('Day net'), findsOneWidget);
    expect(find.byKey(const ValueKey('summaryRatioBar')), findsNothing);
  });

  testWidgets('SS06: multi-currency with default present + others missing — '
      'unified default + fallback for others', (tester) async {
    // USD is the default — convertible (identity).
    // AUD/CAD have no rates — fallback to per-currency groups.
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'USD': (expense: 100, income: 0)},
          monthNetByCurrency: {'AUD': -100, 'CAD': -200, 'USD': -300},
          currenciesByCode: {'USD': _usd, 'JPY': _jpy, 'EUR': _eur},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Default USD group totals: expense $1.00, monthNet -$3.00.
    expect(find.textContaining(r'-$3.00'), findsOneWidget);
    // Two fallback groups: AUD and CAD.
    expect(find.text('Unconverted'), findsOneWidget);
  });

  // Figures from the design mock: income 61,700.69, expense 4,179.40,
  // month net −93,966.06.
  const designTotals = {'USD': (expense: 417940, income: 6170069)};
  const designMonthNet = {'USD': -9396606};

  Widget designStrip({ThemeData? theme}) => ProviderScope(
    overrides: [
      exchangeRatesProvider.overrideWith(
        (_) => Stream.value(const <String, int>{}),
      ),
    ],
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SummaryStrip(
          todayTotalsByCurrency: designTotals,
          monthNetByCurrency: designMonthNet,
          currenciesByCode: {'USD': _usd},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    ),
  );

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('SS07: day net on the left, month net on the right', (
    tester,
  ) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();

    expect(find.text('Day net'), findsOneWidget);
    expect(find.text('Month net'), findsOneWidget);
    expect(find.text(r'+$57,521.29'), findsOneWidget);
    expect(find.text(r'-$93,966.06'), findsOneWidget);

    final dayLabel = tester.getRect(find.text('Day net'));
    final dayValue = tester.getRect(find.text(r'+$57,521.29'));
    final monthLabel = tester.getRect(find.text('Month net'));
    final monthValue = tester.getRect(find.text(r'-$93,966.06'));
    // Each figure sits under its label; month net is right-aligned.
    expect(dayValue.top, greaterThanOrEqualTo(dayLabel.bottom));
    expect(monthValue.top, greaterThanOrEqualTo(monthLabel.bottom));
    expect(dayLabel.left, lessThan(monthLabel.left));
    expect((monthLabel.right - monthValue.right).abs(), lessThan(1));
  });

  testWidgets('SS08: income and expense tiles show signed amounts with '
      'direction arrows', (tester) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text(r'+$61,700.69'), findsOneWidget);
    expect(find.text(r'-$4,179.40'), findsOneWidget);
    expect(find.byIcon(Icons.south_west), findsOneWidget);
    expect(find.byIcon(Icons.north_east), findsOneWidget);
    // Income tile on the left, expense tile on the right.
    expect(
      tester.getCenter(find.text('Income')).dx,
      lessThan(tester.getCenter(find.text('Expense')).dx),
    );
  });

  testWidgets('SS09: nets are green when positive and red when negative '
      '(light theme)', (tester) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();
    expect(colorOf(tester, r'+$57,521.29'), const Color(0xFF13744A));
    expect(colorOf(tester, r'-$93,966.06'), const Color(0xFFB8283F));
  });

  testWidgets('SS10: nets use the lighter green and red in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(designStrip(theme: ThemeData.dark()));
    await tester.pumpAndSettle();
    expect(colorOf(tester, r'+$57,521.29'), const Color(0xFF6DD5A3));
    expect(colorOf(tester, r'-$93,966.06'), const Color(0xFFFF8F8F));
  });

  testWidgets('SS11: a zero net uses the plain text colour', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'USD': (expense: 500, income: 500)},
          monthNetByCurrency: {'USD': 0},
          currenciesByCode: {'USD': _usd},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final onSurface = Theme.of(tester.element(find.byType(SummaryStrip)))
        .colorScheme
        .onSurface;
    final zeros = tester.widgetList<Text>(find.text(r'$0.00'));
    expect(zeros, hasLength(2));
    for (final t in zeros) {
      expect(t.style?.color, onSurface);
    }
  });

  testWidgets('SS12: ratio bar splits income and expense and announces '
      'the shares', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();

    final bar = find.byKey(const ValueKey('summaryRatioBar'));
    expect(bar, findsOneWidget);
    expect(find.bySemanticsLabel('Income 94%, expense 6%'), findsOneWidget);
    final segments = tester
        .widgetList<Expanded>(
          find.descendant(of: bar, matching: find.byType(Expanded)),
        )
        .toList();
    expect(segments, hasLength(2));
    expect(segments[0].flex, 6170069);
    expect(segments[1].flex, 417940);
    semantics.dispose();
  });

  testWidgets('SS13: no ratio bar when the day has no income or expense', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {},
          monthNetByCurrency: {'USD': -100},
          currenciesByCode: {'USD': _usd},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Day net'), findsOneWidget);
    expect(find.byKey(const ValueKey('summaryRatioBar')), findsNothing);
  });

  testWidgets('SS14: ratio bar shows a single segment when only one side '
      'has activity', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'USD': (expense: 1500, income: 0)},
          monthNetByCurrency: {'USD': -1500},
          currenciesByCode: {'USD': _usd},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey('summaryRatioBar'));
    expect(
      find.descendant(of: bar, matching: find.byType(Expanded)),
      findsOneWidget,
    );
  });

  // An amount that wraps can strand its minus sign on its own line, so
  // every amount must lay out on one line however narrow its column.
  void expectAmountsOnOneLine(WidgetTester tester) {
    final amounts = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data?.contains(r'$') == true || w.data?.contains('¥') == true),
    );
    expect(amounts, findsWidgets);
    for (final element in amounts.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(
        paragraph.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(paragraph.size.width + 0.5),
        reason: '"${(element.widget as Text).data}" wrapped',
      );
    }
  }

  @Dependencies([exchangeRates])
  Future<void> pumpLargeAmounts(
    WidgetTester tester, {
    required double width,
    required double textScale,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {
            'USD': (expense: 123456789, income: 987654321),
            'JPY': (expense: 12345678, income: 0),
          },
          monthNetByCurrency: {'USD': -987654321, 'JPY': -12345678},
          currenciesByCode: {'USD': _usd, 'JPY': _jpy},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SS15: large multi-currency amounts stay on one line at 2x '
      'text scale on a 360dp phone', (tester) async {
    await pumpLargeAmounts(tester, width: 360, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Day net'), findsNWidgets(2));
    expectAmountsOnOneLine(tester);
    // Large text stacks each pair so every amount gets the full card
    // width instead of a half column.
    final dayNet = tester.getRect(find.text('Day net').first);
    final monthNet = tester.getRect(find.text('Month net').first);
    expect(monthNet.top, greaterThan(dayNet.bottom));
    expect(monthNet.left, dayNet.left);
    final income = tester.getRect(find.text('Income').first);
    final expense = tester.getRect(find.text('Expense').first);
    expect(expense.top, greaterThan(income.bottom));
  });

  testWidgets('SS16: large amounts stay on one line at 1x on a 320dp phone', (
    tester,
  ) async {
    await pumpLargeAmounts(tester, width: 320, textScale: 1);
    expect(tester.takeException(), isNull);
    expectAmountsOnOneLine(tester);
  });

  testWidgets('SS17: amounts use tabular figures', (tester) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();
    for (final amount in [
      r'+$57,521.29',
      r'-$93,966.06',
      r'+$61,700.69',
      r'-$4,179.40',
    ]) {
      expect(
        tester.widget<Text>(find.text(amount)).style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: amount,
      );
    }
  });

  Color? segmentColor(WidgetTester tester, int index) {
    final bar = find.byKey(const ValueKey('summaryRatioBar'));
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: bar, matching: find.byType(DecoratedBox)).at(index),
    );
    return (box.decoration as BoxDecoration).color;
  }

  Color? iconColor(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon)).color;

  testWidgets('SS18: ratio bar and tile accents are green for income and red '
      'for expense (light theme)', (tester) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();
    expect(segmentColor(tester, 0), const Color(0xFF13744A));
    expect(segmentColor(tester, 1), const Color(0xFFB8283F));
    expect(iconColor(tester, Icons.south_west), const Color(0xFF13744A));
    expect(iconColor(tester, Icons.north_east), const Color(0xFFB8283F));
  });

  testWidgets('SS19: ratio bar and tile accents use the lighter shades in '
      'dark theme', (tester) async {
    await tester.pumpWidget(designStrip(theme: ThemeData.dark()));
    await tester.pumpAndSettle();
    expect(segmentColor(tester, 0), const Color(0xFF6DD5A3));
    expect(segmentColor(tester, 1), const Color(0xFFFF8F8F));
    expect(iconColor(tester, Icons.south_west), const Color(0xFF6DD5A3));
    expect(iconColor(tester, Icons.north_east), const Color(0xFFFF8F8F));
  });

  // Font size of each styled run in [text]'s Text.rich, keyed by run text.
  Map<String, double?> runSizes(WidgetTester tester, String text) {
    // Day net, month net and a tile can share a string; take the first
    // figure that renders as split runs.
    final span = tester
        .widgetList<Text>(find.text(text))
        .map((t) => t.textSpan)
        .whereType<TextSpan>()
        .first;
    return {
      for (final child in span.children!.cast<TextSpan>())
        child.toPlainText(): child.style?.fontSize,
    };
  }

  testWidgets('SS20: net figures shrink the sign, currency symbol and '
      'decimals around the integer part, as in the design', (tester) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();

    for (final (text, sign, integer, fraction) in [
      (r'+$57,521.29', '+', '57,521', '.29'),
      (r'-$93,966.06', '-', '93,966', '.06'),
    ]) {
      final sizes = runSizes(tester, text);
      final base = tester.widget<Text>(find.text(text)).style!.fontSize!;
      expect(sizes.keys, [sign, r'$', integer, fraction], reason: text);
      // Design: sign 18px, symbol 14px, integer 20px, decimals 15px.
      expect(sizes[sign], closeTo(base * 0.9, 0.01), reason: text);
      expect(sizes[r'$'], closeTo(base * 0.7, 0.01), reason: text);
      expect(sizes[integer], isNull, reason: '$text integer uses the base');
      expect(sizes[fraction], closeTo(base * 0.75, 0.01), reason: text);
    }
  });

  testWidgets('SS21: zero-decimal currencies split without a fraction run', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'JPY': (expense: 500, income: 0)},
          monthNetByCurrency: {'JPY': -500},
          currenciesByCode: {'JPY': _jpy},
          locale: 'en_US',
          defaultCurrency: 'JPY',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(runSizes(tester, '-¥500').keys, ['-', '¥', '500']);
  });

  testWidgets('SS23: the ≈ prefix of a converted total sizes with the sign', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'JPY': (expense: 500, income: 0)},
          monthNetByCurrency: {'JPY': -500},
          currenciesByCode: {'USD': _usd, 'JPY': _jpy},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
        rates: {'JPY→USD': (0.01 * 1000000000).round()},
      ),
    );
    await tester.pumpAndSettle();
    expect(runSizes(tester, r'≈ -$5.00').keys, ['≈ -', r'$', '5', '.00']);
  });

  testWidgets('SS22: income and expense tile amounts stay one size', (
    tester,
  ) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();
    for (final text in [r'+$61,700.69', r'-$4,179.40']) {
      expect(tester.widget<Text>(find.text(text)).textSpan, isNull);
    }
  });

  for (final locale in ['zh_TW', 'zh_Hant_TW', 'zh_CN', 'zh_Hans_CN']) {
    testWidgets('SS24: $locale net figures split into sized runs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SummaryStrip(
            todayTotalsByCurrency: const {
              'USD': (expense: 417940, income: 6170069),
            },
            monthNetByCurrency: const {'USD': -9396606},
            currenciesByCode: const {'USD': _usd},
            locale: locale,
            defaultCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final day = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.textSpan)
          .whereType<TextSpan>()
          .map(
            (span) =>
                span.children!.cast<TextSpan>().map((c) => c.toPlainText()),
          )
          .toList();
      expect(day, [
        ['+', r'$', '57,521', '.29'],
        ['-', r'$', '93,966', '.06'],
      ]);
    });
  }

  // Letter spacing after the last glyph of [run] in [text]'s split figure.
  double? gapAfter(WidgetTester tester, String text, String run) {
    final span = tester
        .widgetList<Text>(find.text(text))
        .map((t) => t.textSpan)
        .whereType<TextSpan>()
        .first;
    var leaf = span.children!.cast<TextSpan>().firstWhere(
      (c) => c.toPlainText() == run,
    );
    while (leaf.children?.isNotEmpty ?? false) {
      leaf = leaf.children!.last as TextSpan;
    }
    return leaf.style?.letterSpacing;
  }

  testWidgets('SS25: net figures keep the design gaps after the sign and '
      'after the currency symbol', (tester) async {
    await tester.pumpWidget(designStrip());
    await tester.pumpAndSettle();
    // Design: sign margin-right 1px, currency margin-right 3px. The gap is
    // spacing, not a character, so the text stays "+$57,521.29".
    expect(gapAfter(tester, r'+$57,521.29', '+'), 1);
    expect(gapAfter(tester, r'+$57,521.29', r'$'), 3);
    expect(gapAfter(tester, r'-$93,966.06', '-'), 1);
    expect(gapAfter(tester, r'-$93,966.06', r'$'), 3);
    // The integer part is set slightly tight (letter-spacing -0.2px).
    expect(gapAfter(tester, r'+$57,521.29', '57,521'), -0.2);
  });

  testWidgets('SS26: only the last glyph of a multi-character symbol or '
      'sign carries the gap', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'HKD': (expense: 0, income: 6170069)},
          monthNetByCurrency: {'HKD': 6170069},
          currenciesByCode: {
            'HKD': Currency(code: 'HKD', decimals: 2, symbol: r'HK$'),
          },
          locale: 'en_US',
          defaultCurrency: 'HKD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final figure = tester
        .widgetList<Text>(find.text(r'+HK$61,700.69'))
        .map((t) => t.textSpan)
        .whereType<TextSpan>()
        .first;
    final symbol = figure.children!.cast<TextSpan>().firstWhere(
      (c) => c.toPlainText() == r'HK$',
    );
    expect(symbol.text, 'HK');
    expect(symbol.style?.letterSpacing, isNull);
    expect(gapAfter(tester, r'+HK$61,700.69', r'HK$'), 3);
  });
}
