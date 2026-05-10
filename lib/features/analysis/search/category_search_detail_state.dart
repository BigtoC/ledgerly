// Detail-screen state for category-filtered search results — see spec
// § UI — Category Search Detail Screen.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/currency.dart';
import '../../../data/models/transaction.dart';

part 'category_search_detail_state.freezed.dart';

/// Pending-delete record set during the 4-second undo window. Mirrors
/// `home/home_state.dart`'s `PendingDelete`; declared locally so the
/// analysis slice does not import from the home feature.
class CategorySearchPendingDelete {
  const CategorySearchPendingDelete({
    required this.transaction,
    required this.scheduledFor,
  });

  final Transaction transaction;
  final DateTime scheduledFor;
}

@freezed
sealed class CategorySearchDetailState with _$CategorySearchDetailState {
  const factory CategorySearchDetailState.loading() = DetailLoading;

  /// `query` and `categoryId` are NOT echoed here — they're already
  /// available as family-key parameters on the controller and as
  /// constructor args on `CategorySearchDetailScreen`.
  ///
  /// `pendingDelete` is non-null while a row is in its 4-second undo
  /// window; the matching transaction is filtered out of [days] and
  /// excluded from [overallSumMinorUnits] so the UI hides it
  /// optimistically until the timer commits or the user taps Undo.
  const factory CategorySearchDetailState.data({
    required List<DatedTransactionGroup> days,
    required int overallSumMinorUnits,
    required Currency currency,
    CategorySearchPendingDelete? pendingDelete,
  }) = DetailData;

  const factory CategorySearchDetailState.empty() = DetailEmpty;
}

@freezed
abstract class DatedTransactionGroup with _$DatedTransactionGroup {
  const factory DatedTransactionGroup({
    required DateTime date,
    required List<Transaction> transactions,
    required int daySumMinorUnits,
  }) = _DatedTransactionGroup;
}
