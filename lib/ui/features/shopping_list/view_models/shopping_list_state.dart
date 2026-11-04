// Shopping-list slice state — Task 4.
//
// Freezed sealed union. Matches the pattern of `home_state.dart`.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/shopping_list_item.dart';

part 'shopping_list_state.freezed.dart';

@freezed
sealed class ShoppingListState with _$ShoppingListState {
  /// Pre-first emission from the underlying stream.
  const factory ShoppingListState.loading() = ShoppingListLoading;

  /// Empty state — no items in the shopping list.
  const factory ShoppingListState.empty() = ShoppingListEmpty;

  /// Populated state. [items] already excludes the row whose id is
  /// [pendingDeleteId], set during the 4-second undo window.
  const factory ShoppingListState.data({
    required List<ShoppingListItem> items,
    required int? pendingDeleteId,
  }) = ShoppingListData;

  /// Upstream stream failure.
  const factory ShoppingListState.error(Object error, StackTrace stack) =
      ShoppingListError;
}
