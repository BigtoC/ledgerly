import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_slice.freezed.dart';

/// Per-(category, currency) subtotal emitted by
/// `TransactionRepository.watchByCategoryInRange`. Lives as a separate
/// shape from `CategorySearchResult` because charts care about the
/// `category_id` only (icon/name resolution happens at the controller
/// level via `analysisCategoriesByIdProvider`).
@freezed
abstract class CategorySlice with _$CategorySlice {
  const factory CategorySlice({
    required int categoryId,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _CategorySlice;
}
