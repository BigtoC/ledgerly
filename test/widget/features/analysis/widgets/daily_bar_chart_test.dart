import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/daily_bar_chart.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  int? touchedIndex(WidgetTester tester) {
    final groups = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups;
    final hit = groups.indexWhere((g) => g.barRods.single.width == 14);
    return hit == -1 ? null : hit;
  }

  testWidgets('moving within the touched bar does not rebuild the chart', (
    tester,
  ) async {
    final anchor = DateTime(2026, 5, 18);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: DailyBarChart(
              period: PeriodType.week,
              anchorDate: anchor,
              bucketTotals: [
                for (var d = 0; d < 7; d++)
                  ChartBucketTotal(
                    bucketStart: DateTime(2026, 5, 18 + d),
                    totalMinorUnits: 1000,
                  ),
              ],
              locale: 'en',
              currenciesByCode: const {},
            ),
          ),
        ),
      ),
    );

    // Sweep a mouse across the middle of the chart until it lands on a bar.
    final rect = tester.getRect(find.byType(BarChart));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset(rect.left, rect.center.dy));
    var x = rect.left;
    while (touchedIndex(tester) == null && x < rect.right) {
      x += 1;
      await mouse.moveTo(Offset(x, rect.center.dy));
      await tester.pump();
    }
    final touched = touchedIndex(tester);
    expect(touched, isNotNull);
    final before = tester.widget<BarChart>(find.byType(BarChart));

    // A few more pixels into the same bar: same index, so no setState.
    await mouse.moveTo(Offset(x + 2, rect.center.dy));
    await tester.pump();
    expect(touchedIndex(tester), touched);
    expect(
      identical(tester.widget<BarChart>(find.byType(BarChart)), before),
      isTrue,
    );

    await mouse.removePointer();
  });
}
