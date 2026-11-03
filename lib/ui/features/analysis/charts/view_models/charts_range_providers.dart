// The selected period's `[start, end)` range, resolved in one place for every
// Analysis surface: the charts, the summary totals and the drill-down.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'charts_selection_controller.dart';
import 'charts_state.dart' show PeriodType;

part 'charts_range_providers.g.dart';

/// Half-open `[start, end)` range of the selected period.
typedef ChartsRange = ({DateTime start, DateTime end});

/// The selected period's range: the anchor snapped to its period.
///
/// Watches only `(period, anchorDate)`, so a type, dimension, slice or
/// account change does not re-query its consumers.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` watch it.
@Riverpod(keepAlive: true, dependencies: [ChartsSelectionController])
AsyncValue<ChartsRange> chartsRange(Ref ref) {
  final (PeriodType period, DateTime anchorDate) = ref.watch(
    chartsSelectionControllerProvider.select((s) => (s.period, s.anchorDate)),
  );
  final start = normalizeAnchor(anchorDate, period);
  return AsyncData((start: start, end: shiftAnchor(start, period, 1)));
}
