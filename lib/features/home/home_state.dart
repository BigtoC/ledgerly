// Home slice state — Wave 3 §5.
//
// Freezed sealed union. The first-run / no-history case lives in the
// dedicated [HomeEmpty] variant so the widget renders the empty CTA
// without inspecting `transactionsForDay.isEmpty`. Per-day empty (gap
// day with prior history) lives inside [HomeData] with an empty
// `transactionsForDay`.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/transaction.dart';

part 'home_state.freezed.dart';

/// Per-currency expense/income split used by the summary strip.
typedef DailyTotals = Map<String, ({int expense, int income})>;

@freezed
sealed class HomeState with _$HomeState {
  /// Pre-first emission from the underlying streams.
  const factory HomeState.loading() = HomeLoading;

  /// First-run / no-history terminal state. Renders empty CTA.
  const factory HomeState.empty({required DateTime selectedDay}) = HomeEmpty;

  /// Populated state. Covers both days with rows and gap-day empties
  /// (when `transactionsForDay.isEmpty`).
  const factory HomeState.data({
    required DateTime selectedDay,
    required DateTime today,
    required List<Transaction> transactionsForDay,
    required DailyTotals todayTotalsByCurrency,
    required Map<String, int> monthNetByCurrency,
    required bool canGoPrev,
    required bool canGoNext,
  }) = HomeData;

  /// Upstream stream failure.
  const factory HomeState.error(Object error, StackTrace stack) = HomeError;
}
