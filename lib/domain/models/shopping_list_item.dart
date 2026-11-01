import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_list_item.freezed.dart';

/// Domain model for a shopping-list draft item.
///
/// Mirrors the `shopping_list_items` Drift row but carries no Drift types —
/// the seam that protects the UI from schema churn.
///
/// `draftAmountMinorUnits` and `draftCurrencyCode` are an all-or-nothing
/// nullable pair: both null for zero-amount drafts, both non-null for
/// amount-bearing drafts. The invariant is enforced by `ShoppingListRepository`.
@freezed
abstract class ShoppingListItem with _$ShoppingListItem {
  const factory ShoppingListItem({
    required int id,
    required int categoryId,
    required int accountId,
    String? memo,

    /// Null for zero-amount drafts. If non-null, [draftCurrencyCode] is
    /// also non-null.
    int? draftAmountMinorUnits,

    /// Null for zero-amount drafts. If non-null, [draftAmountMinorUnits] is
    /// also non-null.
    String? draftCurrencyCode,

    /// The date the user plans to make the transaction.
    required DateTime draftDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShoppingListItem;
}
