import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_trend_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _colors = AnalysisColors.light;

/// The controller hands seeded categories over as their l10n key.
const _food = ChartSlice(
  label: 'category.food',
  currencyCode: 'USD',
  totalMinorUnits: 700,
  fraction: 1,
  colorIndex: 3,
  iconKey: 'restaurant',
  selectionKey: SelectedSlice.category(1),
);

/// Anchors in 2025, so every bucket has elapsed whatever today is.
ChartsData _data({
  PeriodType period = PeriodType.week,
  CategoryType type = CategoryType.expense,
  List<ChartBucketTotal>? buckets,
}) {
  final anchor = switch (period) {
    PeriodType.week => DateTime(2025, 10, 20),
    PeriodType.month => DateTime(2025, 9, 1),
    _ => DateTime(2025, 1, 1),
  };
  return ChartsData(
    period: period,
    anchorDate: anchor,
    type: type,
    dimension: ChartDimension.category,
    slices: const [_food],
    bucketTotals:
        buckets ??
        [ChartBucketTotal(bucketStart: anchor, totalMinorUnits: 700)],
    grandTotalMinorUnits: 700,
    displayCurrencyCode: 'USD',
  );
}

Future<void> _pump(
  WidgetTester tester,
  ChartsData data, {
  ChartSlice? selectedSlice,
  VoidCallback? onClearSlice,
  double textScale = 1,
  double cardWidth = 358,
  String? accountName,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: cardWidth,
            child: ChartsTrendCard(
              data: data,
              selectedSlice: selectedSlice,
              onClearSlice: onClearSlice ?? () {},
              locale: 'en',
              currenciesByCode: const {'USD': _usd},
              accountName: accountName,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

Color _barColor(WidgetTester tester) =>
    tester.widget<DailyBarChart>(find.byType(DailyBarChart)).barColor;

void main() {
  group('title', () {
    for (final (period, type, title) in [
      (PeriodType.week, CategoryType.expense, 'Daily spending'),
      (PeriodType.month, CategoryType.expense, 'Daily spending'),
      (PeriodType.year, CategoryType.expense, 'Monthly spending'),
      (PeriodType.week, CategoryType.income, 'Daily income'),
      (PeriodType.month, CategoryType.income, 'Daily income'),
      (PeriodType.year, CategoryType.income, 'Monthly income'),
    ]) {
      testWidgets('${period.name} ${type.name} reads "$title"', (tester) async {
        await _pump(tester, _data(period: period, type: type));

        final text = tester.widget<Text>(find.text(title));
        expect(text.style!.fontSize, 16);
        expect(text.style!.height, 24 / 16);
        expect(text.style!.fontWeight, FontWeight.w500);
        expect(text.style!.color, _colors.fg);
      });
    }
  });

  group('average legend', () {
    testWidgets('daily bars show "Avg <amount> / day"', (tester) async {
      // 700 over 7 elapsed days.
      await _pump(tester, _data());

      final text = tester.widget<Text>(find.text(r'Avg $1.00 / day'));
      expect(text.style!.fontSize, 13);
      expect(text.style!.height, 18 / 13);
      expect(text.style!.color, _colors.fg2);
      expect(text.style!.fontFeatures, const [FontFeature.tabularFigures()]);
    });

    testWidgets('monthly bars show "Avg <amount> / month"', (tester) async {
      // 1200 over 12 elapsed months.
      await _pump(
        tester,
        _data(
          period: PeriodType.year,
          buckets: [
            ChartBucketTotal(
              bucketStart: DateTime(2025, 3, 1),
              totalMinorUnits: 1200,
            ),
          ],
        ),
      );

      expect(find.text(r'Avg $1.00 / month'), findsOneWidget);
    });

    testWidgets('is led by a 14 px dashed legend line', (tester) async {
      await _pump(tester, _data());

      final legend = find.byKey(const ValueKey('trendAvgLegend'));
      expect(tester.getSize(legend), const Size(14, 1.5));
      final text = tester.getRect(find.text(r'Avg $1.00 / day'));
      expect(text.left - tester.getRect(legend).right, 6);
      expect(tester.getRect(legend).center.dy, closeTo(text.center.dy, 0.01));
    });
  });

  group('account prefix', () {
    testWidgets('the subtitle is prefixed "<Account> · " with the filter', (
      tester,
    ) async {
      await _pump(tester, _data(), accountName: 'Visa card');

      final prefix = find.text('Visa card · ');
      expect(prefix, findsOneWidget);
      final style = tester.widget<Text>(prefix).style!;
      expect(style.fontSize, 13);
      expect(style.height, 18 / 13);
      expect(style.color, _colors.fg2);
      expect(style.fontFeatures, const [FontFeature.tabularFigures()]);
      final avg = tester.getRect(find.text(r'Avg $1.00 / day'));
      final legend = tester.getRect(
        find.byKey(const ValueKey('trendAvgLegend')),
      );
      // Legend, 6, prefix, then the average right after it.
      expect(tester.getRect(prefix).left - legend.right, 6);
      expect(avg.left, closeTo(tester.getRect(prefix).right, 0.01));
    });

    testWidgets('no prefix without the filter', (tester) async {
      await _pump(tester, _data());
      expect(find.textContaining(' · '), findsNothing);
    });

    testWidgets('a long name ellipsizes before the amount, which keeps its '
        'size (D2)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        _data(),
        accountName: 'A very long account name that cannot fit the header',
        textScale: 2,
        cardWidth: 328,
      );

      expect(tester.takeException(), isNull);
      final prefix = find.textContaining('A very long account name');
      expect(tester.widget<Text>(prefix).overflow, TextOverflow.ellipsis);
      expect(
        tester.renderObject<RenderParagraph>(prefix).didExceedMaxLines,
        isTrue,
      );
      final avg = find.text(r'Avg $1.00 / day');
      // Full size: 18 px line at 2×, no scale-down.
      expect(tester.getSize(avg).height, 36);
      final unscaled = tester.renderObject<RenderParagraph>(avg).size;
      expect(tester.getSize(avg), unscaled);
      // Both inside the card's 16 padding.
      expect(tester.getRect(avg).right, lessThanOrEqualTo(328 - 16 + 0.01));
    });
  });

  group('card chrome', () {
    testWidgets('radius 20, card fill, 1 px line border, padding 16', (
      tester,
    ) async {
      await _pump(tester, _data());

      final card = find.byType(ChartsTrendCard);
      final box = tester.widget<Container>(
        find.descendant(of: card, matching: find.byType(Container)).first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, _colors.card);
      expect(decoration.borderRadius, BorderRadius.circular(20));
      expect(decoration.border, Border.all(color: _colors.line));
      expect(decoration.boxShadow, isNull);

      final cardRect = tester.getRect(card);
      final title = tester.getRect(find.text('Daily spending'));
      // 1 px border + 16 px padding.
      expect(title.topLeft - cardRect.topLeft, const Offset(17, 17));
      // Header (min 44) then a 12 px gap above the plot.
      expect(
        tester.getRect(find.byType(BarChart)).top - cardRect.top,
        17 + 44 + 12,
      );
    });
  });

  group('bar colour', () {
    testWidgets('is exp for expense without a slice', (tester) async {
      await _pump(tester, _data());
      expect(_barColor(tester), _colors.exp);
    });

    testWidgets('is inc for income without a slice', (tester) async {
      await _pump(tester, _data(type: CategoryType.income));
      expect(_barColor(tester), _colors.inc);
    });

    testWidgets('is the selected slice colour', (tester) async {
      await _pump(tester, _data(), selectedSlice: _food);
      expect(_barColor(tester), colorForIndex(3));
    });
  });

  group('filter chip (AC 8)', () {
    testWidgets('is absent without a selected slice', (tester) async {
      await _pump(tester, _data());

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('shows the slice dot, label and close icon', (tester) async {
      await _pump(tester, _data(), selectedSlice: _food);

      final label = tester.widget<Text>(find.text('Food'));
      expect(label.style!.fontSize, 13);
      expect(label.style!.fontWeight, FontWeight.w500);
      expect(label.style!.color, _colors.fg);
      expect(label.style!.height, isNull);
      expect(label.style!.letterSpacing, 0);

      final icon = tester.widget<Icon>(find.byIcon(Icons.close));
      expect(icon.size, 16);
      expect(icon.color, _colors.fg2);

      final dot = tester.widget<Container>(
        find.byKey(const ValueKey('trendFilterDot')),
      );
      expect(
        dot.decoration,
        BoxDecoration(color: colorForIndex(3), shape: BoxShape.circle),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('trendFilterDot'))),
        const Size(8, 8),
      );
    });

    testWidgets('is a 32 px sel pill inside a 44 px hit target', (
      tester,
    ) async {
      await _pump(tester, _data(), selectedSlice: _food);

      final target = find.bySemanticsLabel('Showing Food only. Clear filter');
      expect(target, findsOneWidget);
      expect(tester.getSize(target).height, 44);

      final pill = find.byKey(const ValueKey('trendFilterPill'));
      expect(tester.getSize(pill).height, 32);
      final decoration =
          tester
                  .widget<Ink>(
                    find.descendant(of: pill, matching: find.byType(Ink)),
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, _colors.sel);
      expect(decoration.borderRadius, BorderRadius.circular(16));
      // Padding 0 8 0 10, gap 6.
      final pillRect = tester.getRect(pill);
      final dot = tester.getRect(find.byKey(const ValueKey('trendFilterDot')));
      final label = tester.getRect(find.text('Food'));
      final icon = tester.getRect(find.byIcon(Icons.close));
      expect(dot.left - pillRect.left, 10);
      expect(label.left - dot.right, 6);
      expect(icon.left - label.right, 6);
      expect(pillRect.right - icon.right, 8);
      // Right-aligned in the header, 17 px in from the card edge.
      expect(
        tester.getRect(find.byType(ChartsTrendCard)).right - pillRect.right,
        17,
      );
    });

    testWidgets('tapping it clears the slice', (tester) async {
      var cleared = 0;
      await _pump(
        tester,
        _data(),
        selectedSlice: _food,
        onClearSlice: () => cleared++,
      );

      await tester.tap(find.text('Food'));
      expect(cleared, 1);
    });

    testWidgets('a tap in the 44 px target above the pill clears the slice', (
      tester,
    ) async {
      var cleared = 0;
      await _pump(
        tester,
        _data(),
        selectedSlice: _food,
        onClearSlice: () => cleared++,
      );

      final target = tester.getRect(
        find.bySemanticsLabel('Showing Food only. Clear filter'),
      );
      await tester.tapAt(Offset(target.center.dx, target.top + 2));
      expect(cleared, 1);
    });

    testWidgets('pressing it shows an ink ripple clipped to the pill (D16)', (
      tester,
    ) async {
      await _pump(tester, _data(), selectedSlice: _food);

      final target = tester.getRect(
        find.bySemanticsLabel('Showing Food only. Clear filter'),
      );
      final pill = tester.getRect(
        find.byKey(const ValueKey('trendFilterPill')),
      );
      final gesture = await tester.startGesture(pill.center);
      await tester.pump(const Duration(milliseconds: 200));

      // The ink is painted in the hit target's coordinates; the clip is the
      // 16-radius pill, not the 44 px target.
      final inPill = pill.shift(-target.topLeft);
      expect(
        Material.of(tester.element(find.text('Food'))),
        paints..clipPath(
          pathMatcher: isPathThat(
            includes: [inPill.center, inPill.centerLeft + const Offset(1, 0)],
            excludes: [
              Offset(inPill.center.dx, inPill.top - 2),
              Offset(inPill.center.dx, inPill.bottom + 2),
              inPill.topLeft + const Offset(1, 1),
              inPill.bottomRight - const Offset(1, 1),
            ],
          ),
        ),
      );
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('takes keyboard focus and clears on Enter (D16)', (
      tester,
    ) async {
      var cleared = 0;
      await _pump(
        tester,
        _data(),
        selectedSlice: _food,
        onClearSlice: () => cleared++,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.text('Food'))).hasPrimaryFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(cleared, 1);
    });

    testWidgets('a screen reader can activate it', (tester) async {
      final handle = tester.ensureSemantics();
      var cleared = 0;
      await _pump(
        tester,
        _data(),
        selectedSlice: _food,
        onClearSlice: () => cleared++,
      );

      final target = find.bySemanticsLabel('Showing Food only. Clear filter');
      expect(
        tester
            .getSemantics(target)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.tap(
        find.semantics.byLabel('Showing Food only. Clear filter'),
      );
      expect(cleared, 1);
      handle.dispose();
    });
  });

  testWidgets('title, legend and chip grow at 2× text scale', (tester) async {
    await _pump(tester, _data(), selectedSlice: _food, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text('Daily spending')).height, greaterThan(47));
    expect(tester.getSize(find.text('Food')).height, greaterThan(25));
    expect(
      tester.getSize(find.byKey(const ValueKey('trendFilterPill'))).height,
      greaterThan(32),
    );
  });

  testWidgets('a long average scales down on one line at 2× on a phone (D2)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // 7 elapsed days averaging $123,456,789.00.
    await _pump(
      tester,
      _data(
        buckets: [
          ChartBucketTotal(
            bucketStart: DateTime(2025, 10, 20),
            totalMinorUnits: 7 * 12345678900,
          ),
        ],
      ),
      selectedSlice: _food,
      textScale: 2,
      cardWidth: 328,
    );

    expect(tester.takeException(), isNull);
    const subtitle = r'Avg $123,456,789.00 / day';
    final text = find.text(subtitle);
    expect(text, findsOneWidget);
    final rect = tester.getRect(text);
    // One line (18 px at 2×), never wrapped or broken mid-amount.
    expect(rect.height, lessThanOrEqualTo(36.01));
    // Inside its slot: right of the legend, left of the chip's 12 px gap.
    final legend = tester.getRect(find.byKey(const ValueKey('trendAvgLegend')));
    final chip = tester.getRect(
      find.bySemanticsLabel('Showing Food only. Clear filter'),
    );
    expect(rect.left, greaterThanOrEqualTo(legend.right + 6 - 0.01));
    expect(rect.right, lessThanOrEqualTo(chip.left - 12 + 0.01));
  });
}
