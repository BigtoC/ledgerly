import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/widgets/chart_legend.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

List<ChartSlice> _nineSlices() => List.generate(
  9,
  (i) => ChartSlice(
    label: 'Slice $i',
    currencyCode: 'USD',
    totalMinorUnits: 1000 - i * 100,
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
  home: Scaffold(body: child),
);

void main() {
  testWidgets('View all sheet pops itself when a row is tapped', (
    tester,
  ) async {
    int? selectedIndex;
    await tester.pumpWidget(
      _wrap(
        ChartLegend(
          slices: _nineSlices(),
          currenciesByCode: const {'USD': _usd},
          locale: 'en',
          selectedSliceIndex: null,
          onSelectSlice: (idx) => selectedIndex = idx,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Slice 8 is the 9th slice (smallest amount, 200), which is only visible
    // inside the sheet — not in the inline legend.
    expect(find.text('Slice 8'), findsNothing);

    // Find and tap "View all".
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    // The modal sheet shows all nine rows. Slice 8 is now visible.
    expect(find.text('Slice 8'), findsOneWidget);

    // Tap the row for Slice 8 inside the sheet.
    await tester.tap(find.text('Slice 8'));
    await tester.pumpAndSettle();
    // After tap, the sheet must close → Slice 8 is hidden again (not in inline
    // legend), and the callback must have fired with the correct index.
    expect(find.text('Slice 8'), findsNothing);
    expect(find.text('View all'), findsOneWidget);
    expect(selectedIndex, equals(8));
  });
}
