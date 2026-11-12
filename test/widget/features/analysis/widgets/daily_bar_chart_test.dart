import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/trend_series.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';

import '../../../../support/text_scale.dart';

const _barColor = Color(0xFF123456);
const _colors = AnalysisColors.light;

/// A finished week (Mon 2026-10-19 … Sun 2026-10-25), viewed from later.
final _pastWeek = DateTime(2026, 10, 19);

TrendSeries _week(List<int> totals, {DateTime? now}) => trendSeries(
  period: PeriodType.week,
  anchorDate: _pastWeek,
  bucketTotals: [
    for (var d = 0; d < totals.length; d++)
      ChartBucketTotal(
        bucketStart: DateTime(2026, 10, 19 + d),
        totalMinorUnits: totals[d],
      ),
  ],
  now: now ?? DateTime(2026, 11, 2),
);

Future<void> _pump(
  WidgetTester tester, {
  required PeriodType period,
  required TrendSeries series,
  double width = 400,
  double textScale = 1,
  double edgeInset = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: textScaleBuilder(textScale),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          // The parent's padding, which a scrolling chart scrolls through.
          child: SizedBox(
            width: width + 2 * edgeInset,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: edgeInset),
              child: DailyBarChart(
                period: period,
                series: series,
                barColor: _barColor,
                locale: 'en',
                currenciesByCode: const {},
                edgeInset: edgeInset,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

BarChartData _data(WidgetTester tester) =>
    tester.widget<BarChart>(find.byType(BarChart)).data;

/// The painted width of bar [index]'s tooltip, as fl_chart lays it out.
double _tooltipWidth(WidgetTester tester, int index) {
  final data = _data(tester);
  final tooltip = data.barTouchData.touchTooltipData;
  final group = data.barGroups[index];
  final item = tooltip.getTooltipItem(group, index, group.barRods.single, 0)!;
  final context = tester.element(find.byType(BarChart));
  final painter = TextPainter(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style.merge(item.textStyle),
      text: item.text,
      children: item.children,
    ),
    textAlign: item.textAlign,
    textDirection: item.textDirection,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: tooltip.maxContentWidth);
  final width = painter.width + tooltip.tooltipPadding.horizontal;
  painter.dispose();
  return width;
}

List<BarChartRodData> _rods(WidgetTester tester) => [
  for (final g in _data(tester).barGroups) g.barRods.single,
];

void main() {
  group('bars', () {
    testWidgets('are solid in the given colour, no gradient', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([100, 200, 300, 400, 500, 600, 700]),
      );

      for (final rod in _rods(tester)) {
        expect(rod.color, _barColor);
        expect(rod.gradient, isNull);
      }
    });

    testWidgets('maxY is the largest bucket × 1.12', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([100, 1000, 300, 0, 0, 0, 0]),
      );

      expect(_data(tester).maxY, closeTo(1120, 1e-9));
    });

    testWidgets('an elapsed zero bucket draws no bar', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([1000, 0, 0, 0, 0, 0, 0]),
      );

      expect(_rods(tester)[1].toY, 0);
    });

    testWidgets('week and year use radius 6/2, month 3/1', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([1000, 1000, 1000, 1000, 1000, 1000, 1000]),
      );
      expect(
        _rods(tester).first.borderRadius,
        const BorderRadius.vertical(
          top: Radius.circular(6),
          bottom: Radius.circular(2),
        ),
      );

      await _pump(
        tester,
        period: PeriodType.month,
        series: trendSeries(
          period: PeriodType.month,
          anchorDate: DateTime(2026, 9, 1),
          bucketTotals: [
            ChartBucketTotal(
              bucketStart: DateTime(2026, 9, 3),
              totalMinorUnits: 1000,
            ),
          ],
          now: DateTime(2026, 11, 2),
        ),
      );
      expect(
        _rods(tester)[2].borderRadius,
        const BorderRadius.vertical(
          top: Radius.circular(3),
          bottom: Radius.circular(1),
        ),
      );
    });

    testWidgets('a tiny bar is 2 px tall with its radii scaled to fit', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([10000, 1, 0, 0, 0, 0, 0]),
      );

      final maxY = _data(tester).maxY;
      final rod = _rods(tester)[1];
      // 2 px of the 140 px plot.
      expect(rod.toY, closeTo(2 * maxY / 140, 1e-9));
      // 6 + 2 > 2 px: both radii scale by 2 / 8.
      expect(
        rod.borderRadius,
        const BorderRadius.vertical(
          top: Radius.circular(1.5),
          bottom: Radius.circular(0.5),
        ),
      );
    });
  });

  group('future buckets', () {
    // Wednesday of the current week: Thu–Sun are future.
    final midWeek = DateTime(2026, 10, 21, 10);

    testWidgets('an empty future bucket is a 3 px track stub', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([1000, 500, 200], now: midWeek),
      );

      final maxY = _data(tester).maxY;
      final stub = _rods(tester)[4];
      expect(stub.toY, closeTo(3 * maxY / 140, 1e-9));
      expect(stub.color, _colors.track);
      expect(stub.borderRadius, BorderRadius.circular(1.5));
    });

    testWidgets('a future bucket with an amount is a normal bar', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([1000, 500, 200, 0, 800, 0, 0], now: midWeek),
      );

      final bar = _rods(tester)[4];
      expect(bar.toY, 800);
      expect(bar.color, _barColor);
    });

    testWidgets('an empty future bucket has no tooltip', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([1000, 500, 200], now: midWeek),
      );

      final data = _data(tester);
      final tooltip = data.barTouchData.touchTooltipData.getTooltipItem;
      BarTooltipItem? at(int i) =>
          tooltip(data.barGroups[i], i, data.barGroups[i].barRods.single, 0);
      expect(at(0), isNotNull);
      expect(at(5), isNull);
    });
  });

  group('average line', () {
    testWidgets('is a 1.5 px dashed fg3 line just above the average', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([700, 0, 0, 0, 0, 0, 0]),
      );

      final data = _data(tester);
      final lines = data.extraLinesData.horizontalLines;
      expect(lines, hasLength(1));
      final line = lines.single;
      // Average 100; the stroke sits 0.75 px above it, like a CSS border.
      expect(line.y, closeTo(100 + 0.75 * data.maxY / 140, 1e-9));
      expect(line.strokeWidth, 1.5);
      expect(line.color, _colors.fg3);
      expect(line.dashArray, [3, 3]);
    });

    testWidgets('is hidden when the average is 0', (tester) async {
      // A future week: nothing has elapsed, but one day holds an amount.
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([0, 0, 500], now: DateTime(2026, 10, 1)),
      );

      expect(_data(tester).extraLinesData.horizontalLines, isEmpty);
    });
  });

  group('layout', () {
    testWidgets('plot is 140 high above a 1 px line border', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([100, 0, 0, 0, 0, 0, 0]),
      );

      expect(tester.getSize(find.byType(BarChart)).height, 141);
      final border = _data(tester).borderData;
      expect(border.show, isTrue);
      expect(border.border.bottom, BorderSide(color: _colors.line));
      expect(border.border.top, BorderSide.none);
      expect(border.border.left, BorderSide.none);
      expect(border.border.right, BorderSide.none);
      expect(_data(tester).titlesData.show, isFalse);
    });

    for (final (period, gap, n) in [
      (PeriodType.week, 10.0, 7),
      (PeriodType.month, 3.0, 30),
      (PeriodType.year, 6.0, 12),
    ]) {
      testWidgets('${period.name} rods fill the width with exact $gap gaps', (
        tester,
      ) async {
        final series = trendSeries(
          period: period,
          anchorDate: period == PeriodType.week
              ? _pastWeek
              : period == PeriodType.month
              ? DateTime(2026, 9, 1)
              : DateTime(2025, 1, 1),
          bucketTotals: const [],
          now: DateTime(2026, 11, 2),
        );
        await _pump(tester, period: period, series: series, width: 400);

        final data = _data(tester);
        expect(data.alignment, BarChartAlignment.spaceBetween);
        final width = (400 - (n - 1) * gap) / n;
        for (final rod in _rods(tester)) {
          expect(rod.width, closeTo(width, 1e-9));
        }
      });
    }

    testWidgets('touches just above the baseline reach the chart', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([1000, 1000, 1000, 1000, 1000, 1000, 1000]),
      );

      // The x labels overlap the plot's bottom 4 px; a touch there must
      // still reach fl_chart.
      final plot = tester.getRect(find.byType(BarChart));
      final chart = tester.renderObject(
        find.descendant(
          of: find.byType(BarChart),
          matching: find.byWidgetPredicate((w) => w is LeafRenderObjectWidget),
        ),
      );
      final result = tester.hitTestOnBinding(
        Offset(plot.left + 10, plot.bottom - 1 - 2),
      );
      expect(result.path.map((e) => e.target), contains(chart));
      // The layout still ends under the labels: 141 − 4 + 14.
      expect(tester.getSize(find.byType(DailyBarChart)).height, 151);
    });

    testWidgets('bar heights animate for 360 ms on the emphasized curve', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([100, 0, 0, 0, 0, 0, 0]),
      );

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.duration, AnalysisMotion.emphasizedDuration);
      expect(chart.curve, AnalysisMotion.emphasizedCurve);
    });
  });

  group('x labels', () {
    testWidgets('week labels every day in 11/14 fg3', (tester) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([100, 0, 0, 0, 0, 0, 0]),
      );

      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        final text = tester.widget<Text>(find.text(day));
        expect(text.style!.fontSize, 11);
        expect(text.style!.height, 14 / 11);
        expect(text.style!.color, _colors.fg3);
        expect(text.style!.fontWeight, FontWeight.w400);
      }
    });

    testWidgets('a past month labels days 1, 8, 15, 22 and 29', (tester) async {
      await _pump(
        tester,
        period: PeriodType.month,
        series: trendSeries(
          period: PeriodType.month,
          anchorDate: DateTime(2026, 9, 1),
          bucketTotals: const [],
          now: DateTime(2026, 11, 2),
        ),
      );

      for (final day in ['1', '8', '15', '22', '29']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.text('2'), findsNothing);
      expect(find.text('30'), findsNothing);
    });

    testWidgets('year labels every month', (tester) async {
      // Wide enough that the test font's 33 px month names keep the 2 px
      // gap (D22).
      await _pump(
        tester,
        period: PeriodType.year,
        series: trendSeries(
          period: PeriodType.year,
          anchorDate: DateTime(2025, 1, 1),
          bucketTotals: const [],
          now: DateTime(2026, 11, 2),
        ),
        width: 480,
      );

      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
    });

    testWidgets('the current bucket label is 700 fg', (tester) async {
      await _pump(
        tester,
        period: PeriodType.month,
        series: trendSeries(
          period: PeriodType.month,
          anchorDate: DateTime(2026, 10, 1),
          bucketTotals: const [],
          now: DateTime(2026, 10, 31, 9),
        ),
      );

      final today = tester.widget<Text>(find.text('31'));
      expect(today.style!.fontWeight, FontWeight.w700);
      expect(today.style!.color, _colors.fg);
      final other = tester.widget<Text>(find.text('29'));
      expect(other.style!.fontWeight, FontWeight.w400);
    });

    testWidgets('labels sit centred under their bar, 4 px into the plot', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.week,
        series: _week([100, 0, 0, 0, 0, 0, 0]),
      );

      final plot = tester.getRect(find.byType(BarChart));
      const rodWidth = (400 - 6 * 10) / 7;
      for (var i = 0; i < 7; i++) {
        final label = tester.getRect(
          find.text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i]),
        );
        final barCenter = plot.left + i * (rodWidth + 10) + rodWidth / 2;
        expect(label.center.dx, closeTo(barCenter, 0.01));
        expect(label.top, closeTo(plot.bottom - 4, 0.01));
      }
    });

    testWidgets('labels grow at 2× text scale without overflowing', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.month,
        series: trendSeries(
          period: PeriodType.month,
          anchorDate: DateTime(2026, 9, 1),
          bucketTotals: const [],
          now: DateTime(2026, 11, 2),
        ),
        width: 320,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text('22')).height, 14);

      await _pump(
        tester,
        period: PeriodType.month,
        series: trendSeries(
          period: PeriodType.month,
          anchorDate: DateTime(2026, 9, 1),
          bucketTotals: const [],
          now: DateTime(2026, 11, 2),
        ),
        width: 320,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text('22')).height, 28);
      // Wider than its 7.6 px column, but drawn in full.
      expect(tester.getSize(find.text('22')).width, greaterThan(8));
    });
  });

  group('All (D14, D15)', () {
    /// Months from [first] to [now]'s month, with [totals] keyed by month.
    TrendSeries all(
      DateTime first, {
      required DateTime now,
      Map<DateTime, int> totals = const {},
    }) => trendSeries(
      period: PeriodType.all,
      anchorDate: first,
      bucketTotals: [
        for (final e in totals.entries)
          ChartBucketTotal(bucketStart: e.key, totalMinorUnits: e.value),
      ],
      now: now,
    );

    // The trend card's plot width in a 390 phone: 390 − 2 × 16 margin −
    // 2 × 1 border − 2 × 16 padding.
    const phone = 324.0;
    const rod24 = (phone - 23 * 4) / 24;

    Finder horizontalScrollable() => find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.left,
    );

    testWidgets('up to 24 months fill the width with 4 gaps and 3/1 radii, '
        'without scrolling', (tester) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(
          DateTime(2024, 8),
          now: DateTime(2026, 5, 31),
          totals: {DateTime(2024, 9): 1000},
        ),
        width: phone,
      );

      final rods = _rods(tester);
      expect(rods, hasLength(22));
      for (final rod in rods) {
        expect(rod.width, closeTo((phone - 21 * 4) / 22, 1e-9));
      }
      expect(
        rods[1].borderRadius,
        const BorderRadius.vertical(
          top: Radius.circular(3),
          bottom: Radius.circular(1),
        ),
      );
      expect(_data(tester).alignment, BarChartAlignment.spaceBetween);
      expect(tester.getSize(find.byType(BarChart)).width, phone);
      expect(horizontalScrollable(), findsNothing);
    });

    testWidgets('exactly 24 months still fill the width, without scrolling', (
      tester,
    ) async {
      // Jun 2024 … May 2026.
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2024, 6), now: DateTime(2026, 5, 31)),
        width: phone,
      );

      final rods = _rods(tester);
      expect(rods, hasLength(24));
      for (final rod in rods) {
        expect(rod.width, closeTo(rod24, 1e-9));
      }
      expect(tester.getSize(find.byType(BarChart)).width, phone);
      expect(horizontalScrollable(), findsNothing);
    });

    testWidgets('25 months keep the 24-month bar width and scroll', (
      tester,
    ) async {
      // May 2024 … May 2026.
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2024, 5), now: DateTime(2026, 5, 31)),
        width: phone,
      );

      final rods = _rods(tester);
      expect(rods, hasLength(25));
      for (final rod in rods) {
        expect(rod.width, closeTo(rod24, 1e-9));
      }
      expect(
        tester.getSize(find.byType(BarChart)).width,
        closeTo(25 * rod24 + 24 * 4, 1e-6),
      );
      expect(horizontalScrollable(), findsOneWidget);
    });

    testWidgets('labels: the year under each January and the current month '
        'in 700 fg under the last bar; nothing else', (tester) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2024, 1), now: DateTime(2025, 9, 30)),
        width: phone,
      );

      final plot = tester.getRect(find.byType(BarChart));
      const rod = (phone - 20 * 4) / 21;
      double center(int i) => plot.left + i * (rod + 4) + rod / 2;
      expect(
        tester.getRect(find.text('2024')).center.dx,
        closeTo(center(0), 0.01),
      );
      expect(
        tester.getRect(find.text('2025')).center.dx,
        closeTo(center(12), 0.01),
      );
      expect(
        tester.getRect(find.text('Sep')).center.dx,
        closeTo(center(20), 0.01),
      );
      final current = tester.widget<Text>(find.text('Sep'));
      expect(current.style!.fontWeight, FontWeight.w700);
      expect(current.style!.color, _colors.fg);
      final year = tester.widget<Text>(find.text('2024'));
      expect(year.style!.fontWeight, FontWeight.w400);
      expect(year.style!.color, _colors.fg3);
      expect(find.text('Jan'), findsNothing);
      expect(find.text('Feb'), findsNothing);
    });

    testWidgets('a January current month shows its month name (D15)', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2023, 6), now: DateTime(2025, 1, 4)),
        width: phone,
      );

      expect(find.text('2024'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('2025'), findsNothing);
      // June 2023 is the first month but not a January: no year label.
      expect(find.text('2023'), findsNothing);
    });

    testWidgets('beyond 24 months each bar keeps the 24-month width, the '
        'chart scrolls and opens at the right end', (tester) async {
      // Sep 2023 … Feb 2026: 30 months.
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2023, 9), now: DateTime(2026, 2, 28)),
        width: phone,
        edgeInset: 16,
      );

      final rods = _rods(tester);
      expect(rods, hasLength(30));
      for (final rod in rods) {
        expect(rod.width, closeTo(rod24, 1e-9));
      }
      const content = 30 * rod24 + 29 * 4;
      // The plot and its average line span every month, not the viewport.
      expect(
        tester.getSize(find.byType(BarChart)).width,
        closeTo(content, 1e-6),
      );
      expect(horizontalScrollable(), findsOneWidget);

      // At the right end: the last bar sits where an unscrolled chart's
      // would, at the chart's right edge.
      final box = tester.getRect(find.byType(DailyBarChart));
      final plot = tester.getRect(find.byType(BarChart));
      expect(plot.right, closeTo(box.right, 0.01));
      expect(plot.left, closeTo(box.right - content, 0.01));
      // The chart scrolls through the parent's 16 px padding, so the last
      // label stays centred under its bar, as drawn, without being clipped.
      final viewport = tester.getRect(horizontalScrollable());
      expect(viewport.left, closeTo(box.left - 16, 0.01));
      expect(viewport.right, closeTo(box.right + 16, 0.01));
      final feb = tester.getRect(find.text('Feb'));
      expect(feb.center.dx, closeTo(plot.right - rod24 / 2, 0.01));
      expect(feb.right, lessThanOrEqualTo(viewport.right));
    });

    testWidgets('at 2× an edge label wider than the padding moves the bars '
        'in rather than being clipped', (tester) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2024, 1), now: DateTime(2026, 6, 30)),
        width: phone,
        edgeInset: 16,
        textScale: 2,
      );
      await tester.drag(find.byType(BarChart), const Offset(2000, 0));
      // Let the overscroll stretch, which scales the content, recede.
      await tester.pumpAndSettle();

      final viewport = tester.getRect(horizontalScrollable());
      final plot = tester.getRect(find.byType(BarChart));
      final year = tester.getRect(find.text('2024'));
      expect(year.left, closeTo(viewport.left, 0.01));
      expect(year.center.dx, closeTo(plot.left + rod24 / 2, 0.01));
    });

    testWidgets('a tooltip on a bar at the viewport edge shifts into view', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(
          DateTime(2023, 9),
          now: DateTime(2026, 2, 28),
          totals: {DateTime(2023, 9): 900, DateTime(2026, 2): 900},
        ),
        width: phone,
        edgeInset: 16,
      );
      final tooltip = _data(tester).barTouchData.touchTooltipData;
      expect(tooltip.tooltipHorizontalOffset, 0);

      // Opened at the right end: touch the last bar.
      var plot = tester.getRect(find.byType(BarChart));
      var gesture = await tester.startGesture(
        Offset(plot.right - rod24 / 2, plot.top + 120),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final right = _data(tester).barTouchData.touchTooltipData;
      // Centred on a bar 16 px from the viewport's edge, the tooltip would
      // be cut off; it moves left just enough to fit.
      expect(right.tooltipHorizontalOffset, lessThan(0));
      final viewport = tester.getRect(horizontalScrollable());
      final width = _tooltipWidth(tester, 29);
      final centre = plot.right - rod24 / 2;
      expect(
        centre - width / 2 + right.tooltipHorizontalOffset + width,
        closeTo(viewport.right, 0.01),
      );
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      // Scrolled to the left end: touch the first bar.
      await tester.drag(find.byType(BarChart), const Offset(2000, 0));
      // Let the overscroll stretch, which scales the content, recede.
      await tester.pumpAndSettle();
      plot = tester.getRect(find.byType(BarChart));
      gesture = await tester.startGesture(
        Offset(plot.left + rod24 / 2, plot.top + 120),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final left = _data(tester).barTouchData.touchTooltipData;
      expect(left.tooltipHorizontalOffset, greaterThan(0));
      expect(
        plot.left +
            rod24 / 2 -
            _tooltipWidth(tester, 0) / 2 +
            left.tooltipHorizontalOffset,
        closeTo(viewport.left, 0.01),
      );
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a tooltip with room keeps its centre on the bar', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(
          DateTime(2023, 9),
          now: DateTime(2026, 2, 28),
          totals: {DateTime(2025, 6): 900},
        ),
        width: phone,
        edgeInset: 16,
      );
      final plot = tester.getRect(find.byType(BarChart));
      // June 2025 is index 21, mid-viewport at the right end.
      final gesture = await tester.startGesture(
        Offset(plot.left + 21 * (rod24 + 4) + rod24 / 2, plot.top + 120),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        _data(tester).barTouchData.touchTooltipData.tooltipHorizontalOffset,
        0,
      );
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('beyond 24 months the y scale and the average use every '
        'month, also the scrolled-away ones', (tester) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(
          DateTime(2023, 9),
          now: DateTime(2026, 2, 28),
          // The biggest month is the first, far left of the viewport.
          totals: {DateTime(2023, 9): 3000, DateTime(2026, 2): 600},
        ),
        width: phone,
      );

      final data = _data(tester);
      expect(data.maxY, closeTo(3000 * 1.12, 1e-9));
      final line = data.extraLinesData.horizontalLines.single;
      // (3000 + 600) / 30 months.
      expect(line.y, closeTo(120 + 0.75 * data.maxY / 140, 1e-9));
    });

    testWidgets('the x labels scroll with the bars', (tester) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2023, 9), now: DateTime(2026, 2, 28)),
        width: phone,
      );
      final plotBefore = tester.getRect(find.byType(BarChart));
      // "2026" gives way to the current "Feb" beside it (D22).
      final labelBefore = tester.getRect(find.text('2025'));

      await tester.drag(find.byType(BarChart), const Offset(100, 0));
      await tester.pump();

      final dx = tester.getRect(find.byType(BarChart)).left - plotBefore.left;
      expect(dx, greaterThan(50));
      expect(
        tester.getRect(find.text('2025')).left - labelBefore.left,
        closeTo(dx, 0.01),
      );
    });

    testWidgets('touches on a scrolled bar still reach the chart', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(
          DateTime(2023, 9),
          now: DateTime(2026, 2, 28),
          totals: {DateTime(2026, 2): 600},
        ),
        width: phone,
      );

      final plot = tester.getRect(find.byType(BarChart));
      final chart = tester.renderObject(
        find.descendant(
          of: find.byType(BarChart),
          matching: find.byWidgetPredicate((w) => w is LeafRenderObjectWidget),
        ),
      );
      final result = tester.hitTestOnBinding(
        Offset(plot.right - rod24 / 2, plot.bottom - 20),
      );
      expect(result.path.map((e) => e.target), contains(chart));
      // The tooltip names the month and year.
      final data = _data(tester);
      final item = data.barTouchData.touchTooltipData.getTooltipItem(
        data.barGroups[29],
        29,
        data.barGroups[29].barRods.single,
        0,
      );
      expect(item!.text, 'Feb 2026\n');
    });

    testWidgets('2× text scale at phone width: labels grow, no overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.all,
        series: all(DateTime(2023, 9), now: DateTime(2026, 2, 28)),
        width: phone,
        textScale: 2,
        edgeInset: 16,
      );

      expect(tester.takeException(), isNull);
      // "2026" gives way to the current "Feb" beside it (D22).
      expect(find.text('2026'), findsNothing);
      expect(tester.getSize(find.text('2025')).height, 28);
      expect(tester.getSize(find.text('Feb')).height, 28);
      // The last label stays inside the viewport.
      final viewport = tester.getRect(horizontalScrollable());
      expect(
        tester.getRect(find.text('Feb')).right,
        lessThanOrEqualTo(viewport.right + 0.01),
      );
    });
  });

  testWidgets('semantics list non-zero buckets and skip empty future ones', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // Viewed on Wednesday: Thursday to Sunday are empty future buckets.
    await _pump(
      tester,
      period: PeriodType.week,
      series: _week([1234, 0, 0, 0, 0, 0, 0], now: DateTime(2026, 10, 21)),
    );

    final label = tester
        .getSemantics(find.bySemanticsLabel(RegExp('^Bar chart')))
        .label;
    expect(label, startsWith('Bar chart. '));
    expect(label, contains('Mon: 1234'));
    for (final day in ['Thu', 'Fri', 'Sat', 'Sun']) {
      expect(label, isNot(contains(day)));
    }
    handle.dispose();
  });

  testWidgets('hovering across the bars does not rebuild the chart', (
    tester,
  ) async {
    await _pump(
      tester,
      period: PeriodType.week,
      series: _week([1000, 1000, 1000, 1000, 1000, 1000, 1000]),
    );

    final before = tester.widget<BarChart>(find.byType(BarChart));
    final rect = tester.getRect(find.byType(BarChart));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset(rect.left, rect.center.dy));
    for (var x = rect.left; x < rect.right; x += 20) {
      await mouse.moveTo(Offset(x, rect.center.dy));
      await tester.pump();
    }

    // No touched-bar growth: the chart widget is never rebuilt.
    expect(
      identical(tester.widget<BarChart>(find.byType(BarChart)), before),
      isTrue,
    );
    await mouse.removePointer();
  });

  // Loads Roboto for the rest of the file, so it stays last: the test font
  // draws "2024" wider than the 16 px padding allows.
  group('All edge labels in Roboto', () {
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final roboto = File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(roboto)))).load();
    });

    testWidgets('scrolled to the left end, the first label is centred under '
        'its bar inside the viewport', (tester) async {
      const phone = 324.0;
      const rod24 = (phone - 23 * 4) / 24;
      // Jan 2024 … Jun 2026: 30 months; January 2024 carries "2024".
      await _pump(
        tester,
        period: PeriodType.all,
        series: trendSeries(
          period: PeriodType.all,
          anchorDate: DateTime(2024, 1),
          bucketTotals: const [],
          now: DateTime(2026, 6, 30),
        ),
        width: phone,
        edgeInset: 16,
      );
      await tester.drag(find.byType(BarChart), const Offset(2000, 0));
      // Let the overscroll stretch, which scales the content, recede.
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(DailyBarChart));
      final plot = tester.getRect(find.byType(BarChart));
      final viewport = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.left,
        ),
      );
      // The first bar sits where an unscrolled chart's would.
      expect(plot.left, closeTo(box.left, 0.01));
      final year = tester.getRect(find.text('2024'));
      expect(year.center.dx, closeTo(plot.left + rod24 / 2, 0.01));
      expect(year.left, greaterThanOrEqualTo(viewport.left));
    });
  });

  // Also loads Roboto (with its bold face for the current label), so it
  // stays last with the group above.
  group('x label collisions in Roboto (D22)', () {
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final loader = FontLoader('Roboto');
      for (final face in ['Regular', 'Bold']) {
        final bytes = File(
          '$root/bin/cache/artifacts/material_fonts/Roboto-$face.ttf',
        ).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });

    // The trend card's plot width in a 390 phone.
    const phone = 324.0;

    /// The visible x labels' texts, left to right, after checking that
    /// neighbours keep at least a 2 px gap.
    List<String> visibleLabels(WidgetTester tester) {
      final labels = [
        for (final e
            in find
                .descendant(
                  of: find.byType(DailyBarChart),
                  matching: find.byType(Text),
                )
                .evaluate())
          (
            text: (e.widget as Text).data!,
            rect: tester.getRect(find.byWidget(e.widget)),
          ),
      ]..sort((a, b) => a.rect.left.compareTo(b.rect.left));
      for (var i = 1; i < labels.length; i++) {
        expect(
          labels[i].rect.left - labels[i - 1].rect.right,
          greaterThanOrEqualTo(2 - 0.01),
          reason: '${labels[i - 1].text} / ${labels[i].text}',
        );
      }
      return [for (final l in labels) l.text];
    }

    testWidgets('Year at 2×: no two labels collide and the current month '
        'is shown', (tester) async {
      await _pump(
        tester,
        period: PeriodType.year,
        series: trendSeries(
          period: PeriodType.year,
          anchorDate: DateTime(2026, 1, 1),
          bucketTotals: const [],
          now: DateTime(2026, 5, 18),
        ),
        width: phone,
        edgeInset: 16,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      final labels = visibleLabels(tester);
      expect(labels, contains('May'));
      expect(labels.length, lessThan(12));
      expect(
        tester.widget<Text>(find.text('May')).style!.fontWeight,
        FontWeight.w700,
      );
    });

    testWidgets('All with a February current month at 1×: the year label '
        'under January gives way to the current month', (tester) async {
      // Oct 2024 … Feb 2026: 17 months, so January 2026 is the bar before
      // the current one.
      await _pump(
        tester,
        period: PeriodType.all,
        series: trendSeries(
          period: PeriodType.all,
          anchorDate: DateTime(2024, 10),
          bucketTotals: const [],
          now: DateTime(2026, 2, 14),
        ),
        width: phone,
        edgeInset: 16,
      );

      expect(visibleLabels(tester), ['2025', 'Feb']);
    });

    testWidgets('Month with today next to a fixed label at 1×: today wins', (
      tester,
    ) async {
      await _pump(
        tester,
        period: PeriodType.month,
        series: trendSeries(
          period: PeriodType.month,
          anchorDate: DateTime(2026, 10, 1),
          bucketTotals: const [],
          now: DateTime(2026, 10, 16, 9),
        ),
        width: phone,
        edgeInset: 16,
      );

      expect(visibleLabels(tester), ['1', '8', '16', '22', '29']);
    });

    testWidgets('Year at 1×: every month fits and is shown', (tester) async {
      await _pump(
        tester,
        period: PeriodType.year,
        series: trendSeries(
          period: PeriodType.year,
          anchorDate: DateTime(2026, 1, 1),
          bucketTotals: const [],
          now: DateTime(2026, 5, 18),
        ),
        width: phone,
        edgeInset: 16,
      );

      expect(visibleLabels(tester), hasLength(12));
    });
  });
}
