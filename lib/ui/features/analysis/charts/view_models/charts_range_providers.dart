// The selected period's `[start, end)` range, resolved in one place for every
// Analysis surface: the charts, the summary totals and the drill-down.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../app/providers/repository_providers.dart';
import '../../../../../data/repositories/transaction_repository.dart';
import 'charts_selection_controller.dart';
import 'charts_state.dart' show PeriodType;

part 'charts_range_providers.g.dart';

/// Half-open `[start, end)` range of the selected period.
typedef ChartsRange = ({DateTime start, DateTime end});

/// Earliest and latest transaction dates, across every type and account.
/// Re-emits when the earliest transaction is added or deleted (plan D13).
///
/// `keepAlive` because the kept-alive [chartsRange] watches it on All.
@Riverpod(keepAlive: true, dependencies: [transactionRepository])
Stream<DateBounds?> chartsDateBounds(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watchDateBounds();

/// The selected period's range. Day, Week, Month and Year snap the anchor;
/// All runs from the first day of the earliest transaction's month to the
/// start of next month, and is empty (`start == end`) when there are no
/// transactions up to then. Loading or failed only while All's date
/// bounds are.
///
/// Watches only `(period, anchorDate)`, so a type, dimension, slice or
/// account change does not re-query its consumers.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` watch it.
@Riverpod(
  keepAlive: true,
  dependencies: [chartsDateBounds, ChartsSelectionController],
)
AsyncValue<ChartsRange> chartsRange(Ref ref) {
  final (PeriodType period, DateTime anchorDate) = ref.watch(
    chartsSelectionControllerProvider.select((s) => (s.period, s.anchorDate)),
  );
  if (period != PeriodType.all) {
    final start = normalizeAnchor(anchorDate, period);
    return AsyncData((start: start, end: shiftAnchor(start, period, 1)));
  }
  // Only the earliest month matters, so a new latest date does not notify.
  final firstMonth = ref.watch(
    chartsDateBoundsProvider.select(
      (bounds) => bounds.whenData(
        (b) => b == null ? null : DateTime(b.first.year, b.first.month),
      ),
    ),
  );
  final now = DateTime.now();
  final end = DateTime(now.year, now.month + 1);
  return firstMonth.whenData(
    (first) => first == null || !first.isBefore(end)
        ? (start: end, end: end)
        : (start: first, end: end),
  );
}
