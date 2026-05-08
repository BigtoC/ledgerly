// Pending approval state — spec 2026-05-08.
//
// Freezed sealed union consumed by PendingSection on HomeScreen.
// PendingController composes the repository stream into one of these
// variants. PendingSkipScheduled is an in-memory sentinel for the
// 4-second undo window — the row only leaves the DB when the timer
// expires.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/pending_transaction.dart';

part 'pending_state.freezed.dart';

/// A pending row currently inside the 4-second skip-undo window.
/// Held in-memory by the controller, NOT in the DB.
class PendingSkipScheduled {
  const PendingSkipScheduled({
    required this.pendingId,
    required this.scheduledFor,
  });
  final int pendingId;
  final DateTime scheduledFor;
}

@freezed
sealed class PendingState with _$PendingState {
  /// Pre-first emission from watchAll().
  const factory PendingState.loading() = PendingLoading;

  /// No un-approved pending rows. Section renders nothing.
  const factory PendingState.empty() = PendingEmpty;

  const factory PendingState.data({
    required List<PendingTransaction> items,
    required PendingSkipScheduled? skipScheduled,
  }) = PendingData;

  const factory PendingState.error(Object error, StackTrace stack) =
      PendingError;
}
