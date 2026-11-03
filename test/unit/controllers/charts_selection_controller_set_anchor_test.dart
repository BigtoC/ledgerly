// ChartsSelectionController.setAnchor — the period picker's jump
// (docs/superpowers/specs/2026-11-03-analysis-period-picker-design.md § 6,
// acceptance criterion 11).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/models/category.dart' show CategoryType;
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([ChartsSelectionController])
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  @Dependencies([ChartsSelectionController])
  ChartsSelectionController notifier() =>
      container.read(chartsSelectionControllerProvider.notifier);
  @Dependencies([ChartsSelectionController])
  ChartsSelection state() => container.read(chartsSelectionControllerProvider);

  group('setAnchor normalizes to the start of the period', () {
    final picked = DateTime(2025, 9, 17, 15, 30); // a Wednesday afternoon

    test('Day snaps to midnight', () {
      notifier().setPeriod(PeriodType.day);
      notifier().setAnchor(picked);
      expect(state().anchorDate, DateTime(2025, 9, 17));
    });

    test('Week snaps to its Monday', () {
      // The default period is Week.
      notifier().setAnchor(picked);
      expect(state().anchorDate, DateTime(2025, 9, 15));
    });

    test('Month snaps to the 1st', () {
      notifier().setPeriod(PeriodType.month);
      notifier().setAnchor(picked);
      expect(state().anchorDate, DateTime(2025, 9, 1));
    });

    test('Year snaps to Jan 1', () {
      notifier().setPeriod(PeriodType.year);
      notifier().setAnchor(picked);
      expect(state().anchorDate, DateTime(2025, 1, 1));
    });
  });

  test('is a no-op on All', () {
    notifier().setPeriod(PeriodType.all);
    notifier().toggleSlice(const SelectedSlice.category(7));
    final before = state();

    notifier().setAnchor(DateTime(2025, 9, 17));

    expect(state(), same(before));
  });

  test('is a no-op when the date is in the selected period', () {
    notifier().setPeriod(PeriodType.month);
    notifier().setAnchor(DateTime(2025, 9, 1));
    notifier().toggleSlice(const SelectedSlice.category(7));
    final before = state();

    notifier().setAnchor(DateTime(2025, 9, 28, 8));

    expect(state(), same(before));
    expect(state().selectedSlice, const SelectedSlice.category(7));
  });

  test('clears the slice and keeps type, dimension and account filter', () {
    notifier()
      ..toggleType()
      ..setDimension(ChartDimension.currency)
      ..setAccountFilter(3)
      ..toggleSlice(const SelectedSlice.currency('USD'));

    notifier().setAnchor(DateTime(2025, 9, 17));

    expect(state().anchorDate, DateTime(2025, 9, 15));
    expect(state().selectedSlice, isNull);
    expect(state().type, CategoryType.income);
    expect(state().dimension, ChartDimension.currency);
    expect(state().accountFilterId, 3);
    expect(state().period, PeriodType.week);
  });
}
