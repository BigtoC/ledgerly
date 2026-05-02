// Shopping-list slice state — Task 4.
//
// Freezed sealed union. Matches the pattern of `home_state.dart`.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/shopping_list_item.dart';

part 'shopping_list_state.freezed.dart';

/// Pending-delete record set during the 4-second undo window.
/// Plain class (not Freezed) — controller swaps it out by reference.
class ShoppingListPendingDelete {
  const ShoppingListPendingDelete({
    required this.itemId,
    required this.scheduledFor,
  });

  final int itemId;
  final DateTime scheduledFor;
}

@freezed
sealed class ShoppingListState with _$ShoppingListState {
  /// Pre-first emission from the underlying stream.
  const factory ShoppingListState.loading() = ShoppingListLoading;

  /// Empty state — no items in the shopping list.
  const factory ShoppingListState.empty() = ShoppingListEmpty;

  /// Populated state. [items] already excludes the pending-delete row.
  const factory ShoppingListState.data({
    required List<ShoppingListItem> items,
    required ShoppingListPendingDelete? pendingDelete,
  }) = ShoppingListData;

  /// Upstream stream failure.
  const factory ShoppingListState.error(Object error, StackTrace stack) =
      ShoppingListError;
}
