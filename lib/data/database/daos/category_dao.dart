import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

/// Thin SQL wrapper for `categories`.
///
/// Business rules (type-lock after first use, archive-vs-delete,
/// l10n_key stability) live in `CategoryRepository` (M3). This DAO
/// returns Drift rows only.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Watch all categories, optionally excluding archived rows and
  /// optionally filtered by [type] (the raw string `'expense'` or
  /// `'income'`). Ordered by `sort_order` (NULLs last), then `id` ascending.
  Stream<List<CategoryRow>> watchAll({
    bool includeArchived = false,
    String? type,
  }) {
    final query = select(categories);
    if (!includeArchived) {
      query.where((c) => c.isArchived.equals(false));
    }
    if (type != null) {
      query.where((c) => c.type.equals(type));
    }
    query.orderBy([
      (c) => OrderingTerm(
        expression: c.sortOrder,
        mode: OrderingMode.asc,
        nulls: NullsOrder.last,
      ),
      (c) => OrderingTerm(expression: c.id),
    ]);
    return query.watch();
  }

  Future<CategoryRow?> findById(int id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Used by M3 seed idempotency check.
  Future<CategoryRow?> findByL10nKey(String key) {
    return (select(
      categories,
    )..where((c) => c.l10nKey.equals(key))).getSingleOrNull();
  }

  Future<int> insert(CategoriesCompanion row) {
    return into(categories).insert(row);
  }

  Future<bool> updateRow(CategoriesCompanion row) {
    return update(categories).replace(row);
  }

  /// Hard delete. Repository restricts to unused custom rows; DAO just
  /// deletes whatever id it is handed.
  Future<int> deleteById(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  /// `UPDATE ... SET is_archived = 1`. Repository decides archive vs
  /// delete.
  Future<int> archiveById(int id) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      const CategoriesCompanion(isArchived: Value(true)),
    );
  }

  /// `UPDATE categories SET sort_order = ? WHERE id = ?`. Returns the
  /// number of rows changed, 0 when no row has that id.
  Future<int> updateSortOrder(int id, int sortOrder) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(sortOrder: Value(sortOrder)),
    );
  }
}
