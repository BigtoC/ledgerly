import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/shopping_list_items_table.dart';

part 'shopping_list_dao.g.dart';

/// Thin SQL wrapper for `shopping_list_items`.
///
/// Business rules (amount/currency all-or-nothing invariant,
/// created_at/updated_at population) live in `ShoppingListRepository`.
/// This DAO returns Drift rows only.
@DriftAccessor(tables: [ShoppingListItems])
class ShoppingListDao extends DatabaseAccessor<AppDatabase>
    with _$ShoppingListDaoMixin {
  ShoppingListDao(super.db);

  /// Watch all items, newest `created_at` first.
  Stream<List<ShoppingListItemRow>> watchAll() {
    return (select(shoppingListItems)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// One-shot read by id.
  Future<ShoppingListItemRow?> findById(int id) {
    return (select(
      shoppingListItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new row. Returns the new `id`.
  Future<int> insert(ShoppingListItemsCompanion row) {
    return into(shoppingListItems).insert(row);
  }

  /// Replace row by PK. Returns `true` if a row was updated.
  Future<bool> updateRow(ShoppingListItemsCompanion row) {
    return update(shoppingListItems).replace(row);
  }

  /// Delete by id. Returns the number of affected rows.
  Future<int> deleteById(int id) {
    return (delete(shoppingListItems)..where((t) => t.id.equals(id))).go();
  }

  /// Count shopping-list items referencing the given account.
  /// Used for delete guard checks in the repository layer.
  Future<int> countByAccount(int accountId) async {
    final countExp = shoppingListItems.id.count();
    final row =
        await (selectOnly(shoppingListItems)
              ..addColumns([countExp])
              ..where(shoppingListItems.accountId.equals(accountId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Count shopping-list items referencing the given category.
  /// Used for delete guard checks in the repository layer.
  Future<int> countByCategory(int categoryId) async {
    final countExp = shoppingListItems.id.count();
    final row =
        await (selectOnly(shoppingListItems)
              ..addColumns([countExp])
              ..where(shoppingListItems.categoryId.equals(categoryId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }
}
