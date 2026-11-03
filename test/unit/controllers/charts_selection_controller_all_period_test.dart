// The All period on ChartsSelection — spec § All time: switching to All
// ignores anchorDate, and previous / next are no-ops (AC 13).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('PeriodType lists All last, after Year', () {
    expect(PeriodType.values, [
      PeriodType.day,
      PeriodType.week,
      PeriodType.month,
      PeriodType.year,
      PeriodType.all,
    ]);
  });

  test('setPeriod(all) leaves anchorDate alone and clears the slice', () {
    notifier().setPeriod(PeriodType.month);
    notifier().previousPeriod();
    final anchor = state().anchorDate;
    notifier().toggleSlice(const SelectedSlice.category(7));

    notifier().setPeriod(PeriodType.all);

    expect(state().period, PeriodType.all);
    expect(state().anchorDate, anchor);
    expect(state().selectedSlice, isNull);
  });

  test('leaving All returns to the period the anchor was on', () {
    notifier().setPeriod(PeriodType.month);
    notifier().previousPeriod();
    final anchor = state().anchorDate;

    notifier()
      ..setPeriod(PeriodType.all)
      ..setPeriod(PeriodType.month);

    expect(state().anchorDate, anchor);
  });

  test('previousPeriod and nextPeriod are no-ops on All', () {
    notifier().setPeriod(PeriodType.all);
    notifier().toggleSlice(const SelectedSlice.category(7));
    final before = state();

    notifier().previousPeriod();
    expect(identical(state(), before), isTrue);

    notifier().nextPeriod();
    expect(identical(state(), before), isTrue);
  });

  test('isAtCurrentPeriod is true on All, even from a past anchor', () {
    notifier().setPeriod(PeriodType.year);
    notifier().previousPeriod();
    expect(notifier().isAtCurrentPeriod(), isFalse);

    notifier().setPeriod(PeriodType.all);

    expect(notifier().isAtCurrentPeriod(), isTrue);
  });
}
