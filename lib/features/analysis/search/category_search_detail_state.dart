// Detail-screen state for category-filtered search results — see spec
// § UI — Category Search Detail Screen.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/currency.dart';
import '../../../data/models/transaction.dart';

part 'category_search_detail_state.freezed.dart';

@freezed
sealed class CategorySearchDetailState with _$CategorySearchDetailState {
  const factory CategorySearchDetailState.loading() = DetailLoading;

  /// `query` and `categoryId` are NOT echoed here — they're already
  /// available as family-key parameters on the controller and as
  /// constructor args on `CategorySearchDetailScreen`.
  const factory CategorySearchDetailState.data({
    required List<DatedTransactionGroup> days,
    required int overallSumMinorUnits,
    required Currency currency,
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
