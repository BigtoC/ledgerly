// Account filter on ChartsSelection — spec § Account filter → State.
// Acceptance criteria 4 (filter clearing) and 6 (persistence).

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

  test('initial state has no account filter (all accounts)', () {
    expect(state().accountFilterId, isNull);
  });

  group('setAccountFilter', () {
    test('sets the filter and clears the selected slice', () {
      notifier().toggleSlice(const SelectedSlice.category(7));

      notifier().setAccountFilter(3);

      expect(state().accountFilterId, 3);
      expect(state().selectedSlice, isNull);
    });

    test('clearing the filter (null) also clears the selected slice', () {
      notifier().setAccountFilter(3);
      notifier().toggleSlice(const SelectedSlice.category(7));

      notifier().setAccountFilter(null);

      expect(state().accountFilterId, isNull);
      expect(state().selectedSlice, isNull);
    });

    test('is a no-op when the filter is unchanged', () {
      notifier().setAccountFilter(3);
      notifier().toggleSlice(const SelectedSlice.category(7));
      final before = state();

      notifier().setAccountFilter(3);

      expect(identical(state(), before), isTrue);
      expect(state().selectedSlice, const SelectedSlice.category(7));
    });

    test('picking an account while the dimension is Account switches the '
        'dimension to Category', () {
      notifier().setDimension(ChartDimension.account);

      notifier().setAccountFilter(3);

      expect(state().dimension, ChartDimension.category);
      expect(state().accountFilterId, 3);
    });

    test('picking an account keeps the Currency dimension', () {
      notifier().setDimension(ChartDimension.currency);

      notifier().setAccountFilter(3);

      expect(state().dimension, ChartDimension.currency);
    });
  });

  group('setDimension', () {
    test('choosing Account clears the filter and the slice', () {
      notifier().setAccountFilter(3);
      notifier().toggleSlice(const SelectedSlice.category(7));

      notifier().setDimension(ChartDimension.account);

      expect(state().dimension, ChartDimension.account);
      expect(state().accountFilterId, isNull);
      expect(state().selectedSlice, isNull);
    });

    test('choosing Currency keeps the filter', () {
      notifier().setAccountFilter(3);

      notifier().setDimension(ChartDimension.currency);

      expect(state().accountFilterId, 3);
    });
  });

  group('the filter survives', () {
    setUp(() {
      notifier().setAccountFilter(3);
    });

    test('setPeriod', () {
      notifier().setPeriod(PeriodType.month);
      expect(state().accountFilterId, 3);
    });

    test('previousPeriod', () {
      notifier().previousPeriod();
      expect(state().accountFilterId, 3);
    });

    test('nextPeriod', () {
      notifier().previousPeriod();
      notifier().nextPeriod();
      expect(state().accountFilterId, 3);
    });

    test('toggleType', () {
      notifier().toggleType();
      expect(state().type, CategoryType.income);
      expect(state().accountFilterId, 3);
    });
  });
}
