// ChartsSelectionController — owns the live user selection (period,
// type, dimension, anchorDate, account filter) for the analysis-tab
// chart slice.
//
// Split out from `ChartsController` so the data-emitting notifier does
// not have to expose public selection getters (which would trip
// `avoid_public_notifier_properties`). `ChartsController.build()`
// ref.watches this notifier, so any selection mutation transparently
// re-runs the data pipeline.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/utils/date_helpers.dart';
import '../../../../../domain/models/category.dart' show CategoryType;
import 'charts_state.dart' show ChartDimension, PeriodType;
import 'selected_slice.dart';

part 'charts_selection_controller.freezed.dart';
part 'charts_selection_controller.g.dart';

/// Immutable snapshot of the user's chart selection.
@freezed
abstract class ChartsSelection with _$ChartsSelection {
  const factory ChartsSelection({
    required PeriodType period,
    required CategoryType type,
    required ChartDimension dimension,
    required DateTime anchorDate,
    SelectedSlice? selectedSlice,

    /// Account the whole page is limited to; null = all accounts.
    int? accountFilterId,
  }) = _ChartsSelection;
}

@Riverpod(keepAlive: true, dependencies: [])
class ChartsSelectionController extends _$ChartsSelectionController {
  @override
  ChartsSelection build() {
    return ChartsSelection(
      period: PeriodType.week,
      type: CategoryType.expense,
      dimension: ChartDimension.category,
      anchorDate: normalizeAnchor(DateTime.now(), PeriodType.week),
      selectedSlice: null,
    );
  }

  /// All ignores the anchor, so switching to it keeps the anchor for the
  /// period the user returns to.
  void setPeriod(PeriodType period) {
    if (state.period == period) return;
    state = state.copyWith(
      period: period,
      anchorDate: normalizeAnchor(state.anchorDate, period),
      selectedSlice: null,
    );
  }

  /// No-op on All, which has nothing before it.
  void previousPeriod() {
    if (state.period == PeriodType.all) return;
    state = state.copyWith(
      anchorDate: shiftAnchor(state.anchorDate, state.period, -1),
      selectedSlice: null,
    );
  }

  void nextPeriod() {
    if (isAtCurrentPeriod()) return;
    state = state.copyWith(
      anchorDate: shiftAnchor(state.anchorDate, state.period, 1),
      selectedSlice: null,
    );
  }

  void toggleType() {
    state = state.copyWith(
      type: state.type == CategoryType.expense
          ? CategoryType.income
          : CategoryType.expense,
      selectedSlice: null,
    );
  }

  /// Choosing the Account dimension clears the account filter: an account
  /// slice and the filter never coexist.
  void setDimension(ChartDimension dimension) {
    if (state.dimension == dimension) return;
    state = state.copyWith(
      dimension: dimension,
      selectedSlice: null,
      accountFilterId: dimension == ChartDimension.account
          ? null
          : state.accountFilterId,
    );
  }

  /// Limit the page to account [id] (null = all accounts). Clears the
  /// slice selection; picking an account while the dimension is Account
  /// switches the dimension to Category.
  void setAccountFilter(int? id) {
    if (state.accountFilterId == id) return;
    state = state.copyWith(
      accountFilterId: id,
      selectedSlice: null,
      dimension: id != null && state.dimension == ChartDimension.account
          ? ChartDimension.category
          : state.dimension,
    );
  }

  /// Tap-toggle semantics: same slice clears, different slice replaces.
  void toggleSlice(SelectedSlice slice) {
    state = state.copyWith(
      selectedSlice: state.selectedSlice == slice ? null : slice,
    );
  }

  /// Clear an active drill-down selection. No-op when already null. Used
  /// by the stale-selection self-heal listener in `ChartsSection`.
  void clearSlice() {
    if (state.selectedSlice == null) return;
    state = state.copyWith(selectedSlice: null);
  }

  /// Always true on All, which always ends at the current month.
  bool isAtCurrentPeriod() {
    if (state.period == PeriodType.all) return true;
    final now = DateTime.now();
    final currentAnchor = normalizeAnchor(now, state.period);
    final myAnchor = normalizeAnchor(state.anchorDate, state.period);
    return !myAnchor.isBefore(currentAnchor);
  }
}

/// Snap `anchor` to the start-of-period boundary that matches `period`.
/// All has no anchor, so it returns `anchor` unchanged.
DateTime normalizeAnchor(DateTime anchor, PeriodType period) {
  switch (period) {
    case PeriodType.day:
      return DateHelpers.startOfDay(anchor);
    case PeriodType.week:
      return DateHelpers.startOfWeek(anchor);
    case PeriodType.month:
      return DateHelpers.startOfMonth(anchor);
    case PeriodType.year:
      return DateHelpers.startOfYear(anchor);
    case PeriodType.all:
      return anchor;
  }
}

/// Step `anchor` forward (`delta > 0`) or backward (`delta < 0`) by one
/// period bucket. All does not step: it returns `anchor` unchanged.
DateTime shiftAnchor(DateTime anchor, PeriodType period, int delta) {
  final base = normalizeAnchor(anchor, period);
  switch (period) {
    case PeriodType.day:
      return DateTime(base.year, base.month, base.day + delta);
    case PeriodType.week:
      return DateTime(base.year, base.month, base.day + 7 * delta);
    case PeriodType.month:
      return DateTime(base.year, base.month + delta, 1);
    case PeriodType.year:
      return DateTime(base.year + delta, 1, 1);
    case PeriodType.all:
      return base;
  }
}
