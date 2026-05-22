import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';

void main() {
  test('ChartSlice.selectionKey defaults to null', () {
    const slice = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
    );
    expect(slice.selectionKey, isNull);
  });

  test('ChartSlice.selectionKey round-trips a category selection', () {
    const slice = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: SelectedSlice.category(7),
    );
    expect(slice.selectionKey, equals(const SelectedSlice.category(7)));
  });

  test('ChartSlice equality ignores nothing — selectionKey participates', () {
    const a = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: SelectedSlice.category(7),
    );
    const b = ChartSlice(
      label: 'Food',
      currencyCode: 'USD',
      totalMinorUnits: 1000,
      colorIndex: 0,
      iconKey: 'restaurant',
      selectionKey: SelectedSlice.category(8),
    );
    expect(a, isNot(equals(b)));
  });
}
