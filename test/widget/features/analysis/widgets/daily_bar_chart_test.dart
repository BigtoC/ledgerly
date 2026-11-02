import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/trend_series.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/daily_bar_chart.dart';

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
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: DailyBarChart(
              period: period,
              series: series,
              barColor: _barColor,
              locale: 'en',
              currenciesByCode: const {},
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
      await _pump(
        tester,
        period: PeriodType.year,
        series: trendSeries(
          period: PeriodType.year,
          anchorDate: DateTime(2025, 1, 1),
          bucketTotals: const [],
          now: DateTime(2026, 11, 2),
        ),
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
}
