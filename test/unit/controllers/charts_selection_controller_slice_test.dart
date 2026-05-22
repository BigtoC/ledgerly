import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  ChartsSelectionController notifier() =>
      container.read(chartsSelectionControllerProvider.notifier);
  ChartsSelection state() => container.read(chartsSelectionControllerProvider);

  test('initial state has selectedSlice == null', () {
    expect(state().selectedSlice, isNull);
  });

  test('toggleSlice from null sets the slice', () {
    notifier().toggleSlice(const SelectedSlice.category(7));
    expect(state().selectedSlice, equals(const SelectedSlice.category(7)));
  });

  test('toggleSlice with same slice clears it', () {
    notifier().toggleSlice(const SelectedSlice.category(7));
    notifier().toggleSlice(const SelectedSlice.category(7));
    expect(state().selectedSlice, isNull);
  });

  test('toggleSlice with different slice replaces', () {
    notifier().toggleSlice(const SelectedSlice.category(7));
    notifier().toggleSlice(const SelectedSlice.category(9));
    expect(state().selectedSlice, equals(const SelectedSlice.category(9)));
  });

  test('clearSlice resets to null and is a no-op when already null', () {
    notifier().clearSlice();
    expect(state().selectedSlice, isNull);
    notifier().toggleSlice(const SelectedSlice.category(7));
    notifier().clearSlice();
    expect(state().selectedSlice, isNull);
  });

  group('mutators clear selectedSlice', () {
    setUp(() {
      notifier().toggleSlice(const SelectedSlice.category(7));
    });

    test('setPeriod clears', () {
      notifier().setPeriod(PeriodType.month);
      expect(state().selectedSlice, isNull);
    });

    test('setPeriod with same period does not clear', () {
      final before = state().selectedSlice;
      notifier().setPeriod(state().period);
      expect(state().selectedSlice, equals(before));
    });

    test('setDimension clears', () {
      notifier().setDimension(ChartDimension.account);
      expect(state().selectedSlice, isNull);
    });

    test('toggleType clears', () {
      notifier().toggleType();
      expect(state().selectedSlice, isNull);
    });

    test('previousPeriod clears', () {
      notifier().previousPeriod();
      expect(state().selectedSlice, isNull);
    });

    test('nextPeriod clears when it actually moves', () {
      notifier().previousPeriod();
      notifier().toggleSlice(const SelectedSlice.category(7));
      notifier().nextPeriod();
      expect(state().selectedSlice, isNull);
    });
  });
}
