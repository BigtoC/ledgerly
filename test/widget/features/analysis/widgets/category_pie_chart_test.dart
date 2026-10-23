import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/widgets/category_pie_chart.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

// Slice 0 covers 75% of the ring, clockwise from 3 o'clock, so it owns
// the bottom and left; slice 1 owns the top-right quadrant.
const _slices = [
  ChartSlice(
    label: 'Food',
    currencyCode: 'USD',
    totalMinorUnits: 7500,
    fraction: 0.75,
    colorIndex: 0,
    iconKey: '',
    selectionKey: SelectedSlice.category(1),
  ),
  ChartSlice(
    label: 'Transport',
    currencyCode: 'USD',
    totalMinorUnits: 2500,
    fraction: 0.25,
    colorIndex: 1,
    iconKey: '',
    selectionKey: SelectedSlice.category(2),
  ),
];

// Midway through the ring (centre hole 44, section radius 60).
const _ringOffset = 74.0;

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

Future<List<int?>> _pumpAndTap(
  WidgetTester tester, {
  required int? selectedIndex,
  required Offset fromCentre,
}) async {
  final reported = <int?>[];
  await tester.pumpWidget(
    _wrap(
      CategoryPieChart(
        slices: _slices,
        currenciesByCode: const {'USD': _usd},
        locale: 'en',
        grandTotalMinorUnits: 10000,
        displayCurrencyCode: 'USD',
        selectedIndex: selectedIndex,
        onSelectionChanged: reported.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getCenter(find.byType(PieChart)) + fromCentre);
  await tester.pumpAndSettle();
  return reported;
}

void main() {
  testWidgets('tapping a slice selects it', (tester) async {
    final reported = await _pumpAndTap(
      tester,
      selectedIndex: null,
      fromCentre: const Offset(0, _ringOffset),
    );
    expect(reported, [0]);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('tapping another slice moves the selection to it', (
    tester,
  ) async {
    final reported = await _pumpAndTap(
      tester,
      selectedIndex: 0,
      fromCentre: const Offset(_ringOffset * 0.7, -_ringOffset * 0.7),
    );
    expect(reported, [1]);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('tapping the selected slice clears the selection', (
    tester,
  ) async {
    final reported = await _pumpAndTap(
      tester,
      selectedIndex: 0,
      // Selected slices grow to radius 72, so this still lands on slice 0.
      fromCentre: const Offset(-_ringOffset, 0),
    );
    expect(reported, [null]);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('tapping the centre hole clears the selection', (tester) async {
    final reported = await _pumpAndTap(
      tester,
      selectedIndex: 0,
      fromCentre: Offset.zero,
    );
    expect(reported, [null]);
  }, variant: TargetPlatformVariant.mobile());
}
