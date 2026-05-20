import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/widgets/period_selector.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('renders the week label and calls callbacks', (tester) async {
    var prev = 0, next = 0;
    PeriodType? picked;
    await pump(
      tester,
      PeriodSelector(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 5, 18),
        isAtCurrent: false,
        locale: 'en',
        onPrevious: () => prev++,
        onNext: () => next++,
        onPeriodChanged: (p) => picked = p,
      ),
    );

    expect(find.textContaining('May'), findsWidgets);

    await tester.tap(find.byTooltip('Previous period'));
    await tester.pump();
    expect(prev, 1);

    await tester.tap(find.byTooltip('Next period'));
    await tester.pump();
    expect(next, 1);

    await tester.tap(find.text('Day'));
    await tester.pump();
    expect(picked, PeriodType.day);
  });

  testWidgets('next button disabled at current period', (tester) async {
    var next = 0;
    await pump(
      tester,
      PeriodSelector(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 5, 18),
        isAtCurrent: true,
        locale: 'en',
        onPrevious: () {},
        onNext: () => next++,
        onPeriodChanged: (_) {},
      ),
    );
    await tester.tap(find.byTooltip('Next period'));
    await tester.pump();
    expect(next, 0);
  });
}
