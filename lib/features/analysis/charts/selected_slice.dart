import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_slice.freezed.dart';

/// Drill-down selection identity. Sealed because the chart's three
/// dimensions (category, account, currency) each have a distinct payload
/// that downstream consumers (repository filter, header label resolution)
/// must pattern-switch on. Lives in the analysis layer because this typed
/// selection never crosses the repository boundary; `ChartsController`
/// translates it into plain filter args before data access.
@freezed
sealed class SelectedSlice with _$SelectedSlice {
  /// Drill-down into a category. `currencyCode` is reserved for a future
  /// lower-layer filter path when a later UI may emit per-(category,
  /// currency) slices. In this MVP's chart UI, category selection stays
  /// currency-less and aggregates all currencies for that category.
  const factory SelectedSlice.category(int categoryId, {String? currencyCode}) =
      SelectedCategorySlice;

  /// Drill-down into an account. In this MVP the selection identity is the
  /// account id only; account-level currency splitting can be added later
  /// if the chart ever emits per-(account, currency) slices.
  const factory SelectedSlice.account(int accountId) = SelectedAccountSlice;

  /// Drill-down into a currency.
  const factory SelectedSlice.currency(String currencyCode) =
      SelectedCurrencySlice;
}

/// Translates a typed selection into plain `(categoryId, accountId,
/// currencyCode)` repository filter args. Keeps [SelectedSlice] inside the
/// analysis layer — this is the only place it crosses into data-access
/// territory.
(int?, int?, String?) selectionFilters(SelectedSlice? selection) {
  return switch (selection) {
    null => (null, null, null),
    SelectedCategorySlice(:final categoryId, :final currencyCode) => (
      categoryId,
      null,
      currencyCode,
    ),
    SelectedAccountSlice(:final accountId) => (null, accountId, null),
    SelectedCurrencySlice(:final currencyCode) => (null, null, currencyCode),
  };
}
