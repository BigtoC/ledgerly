import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/transaction.dart';

part 'slice_drilldown_data.freezed.dart';

@freezed
abstract class SliceDrilldownData with _$SliceDrilldownData {
  /// Latest matching transactions. [pendingDeleteId] is non-null while a
  /// row is in its `kUndoWindow` window. The row stays visible until commit
  /// so the list/header remain aligned with the selected chart slice.
  const factory SliceDrilldownData({
    required List<Transaction> rows,
    int? pendingDeleteId,
  }) = _SliceDrilldownData;
}
