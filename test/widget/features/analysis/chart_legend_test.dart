import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/widgets/chart_legend.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

List<ChartSlice> _twelveSlices() => List.generate(
  12,
  (i) => ChartSlice(
    label: 'Slice $i',
    currencyCode: 'USD',
    totalMinorUnits: 1200 - i * 100,
    colorIndex: i,
    iconKey: '',
    selectionKey: SelectedSlice.category(i + 1),
  ),
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('lists every slice inside a card, with no View all button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ChartLegend(
          slices: _twelveSlices(),
          currenciesByCode: const {'USD': _usd},
          locale: 'en',
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 12; i++) {
      expect(
        find.descendant(
          of: find.descendant(
            of: find.byType(ChartLegend),
            matching: find.byType(Card),
          ),
          matching: find.text('Slice $i'),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('View all'), findsNothing);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('tapping a row beyond the old 8-row cap selects that slice', (
    tester,
  ) async {
    int? selectedIndex;
    await tester.pumpWidget(
      _wrap(
        ChartLegend(
          slices: _twelveSlices(),
          currenciesByCode: const {'USD': _usd},
          locale: 'en',
          onSelectSlice: (idx) => selectedIndex = idx,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Slice 11'));
    await tester.tap(find.text('Slice 11'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 11);
  });
}
