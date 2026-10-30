// CSV export screen state.
//
// Freezed sealed union driven by `CsvExportController`; the screen only
// renders it. Carries no transactions: the use case reads and writes them
// in one call.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'csv_export_state.freezed.dart';

/// [noTransactions]: the chosen range holds no transactions, so no save
/// dialog was shown.
enum CsvExportStatus { idle, exporting, done, noTransactions, failed }

@freezed
sealed class CsvExportState with _$CsvExportState {
  /// There are no transactions to export.
  const factory CsvExportState.empty() = CsvExportEmpty;

  /// All dates are local midnights.
  const factory CsvExportState.ready({
    /// Days of the earliest and latest transaction: the picker's bounds
    /// and the default range.
    required DateTime firstDay,
    required DateTime lastDay,

    /// The chosen range, both days included.
    required DateTime rangeStart,
    required DateTime rangeEnd,
    @Default(CsvExportStatus.idle) CsvExportStatus status,

    /// Rows written by the last export; set when [status] is done.
    int? exportedCount,
  }) = CsvExportReady;
}
