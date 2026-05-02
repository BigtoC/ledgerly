// `CategoryRepository` — SSOT for `categories` rows.
//
// See `docs/plans/m3-repositories-seed/stream-a-transaction-category.md`
// for the full specification.
//
// Invariants enforced here (and only here):
//   - `Category.type` is immutable after the first referencing
//     transaction (G5).
//   - Archive-instead-of-delete when referenced (G6); hard-delete only
//     when the row has zero referencing transactions.
//   - Renames write `customName` only; `l10nKey` is never mutated by
//     `save` / `rename` (G7).
//   - `CategoryType` wire values are `'expense'` / `'income'` — locked
//     at two mapping sites (`_toDomain`, `_wireFromType`).

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/shopping_list_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../models/category.dart';

/// Generic category-layer failure. Stream-A-local per §1.3.
///
/// Does **not** extend the sealed `RepositoryException` base — the
/// Phase 1 base class is closed to outside subclasses. Implements
/// `Exception` directly and carries an identical `toString()` shape.
class CategoryRepositoryException implements Exception {
  const CategoryRepositoryException(this.message);

  /// Human-readable description.
  final String message;

  @override
  String toString() => 'CategoryRepositoryException: $message';
}

/// Raised by [CategoryRepository.save] when the caller attempts to
/// change `Category.type` on a row that already has a referencing
/// transaction. G5 — PRD.md 293-294, 315, 735-737.
class CategoryTypeLockedException implements Exception {
  const CategoryTypeLockedException(this.id);

  /// The category id whose type mutation is blocked.
  final int id;

  String get message =>
      'Category type is locked after first transaction; '
      'create a new category instead (id: $id).';

  @override
  String toString() => 'CategoryTypeLockedException: $message';
}

/// Raised by [CategoryRepository.delete] when the caller tries to
/// hard-delete a category that has at least one referencing
/// transaction. Caller should archive instead. G6 — PRD.md 315-316.
class CategoryInUseException implements Exception {
  const CategoryInUseException(this.id);

  /// The category id whose deletion is blocked.
  final int id;

  String get message => 'Category $id is in use and cannot be deleted.';

  @override
  String toString() => 'CategoryInUseException: $message';
}

/// SSOT for `categories`. Owns every write path to the Drift
/// `categories` table. Drift data classes never leave this file.
abstract class CategoryRepository {
  /// Categories stream, optionally filtered by type and including
  /// archived rows. Ordered by `sortOrder NULLS LAST, id ASC`.
  Stream<List<Category>> watchAll({
    CategoryType? type,
    bool includeArchived = false,
  });

  /// One-shot read by id.
  Future<Category?> getById(int id);

  /// One-shot read by `l10nKey`.
  Future<Category?> getByL10nKey(String l10nKey);

  /// Seed-only insert-or-update keyed by `l10nKey`. Used by Stream C's
  /// first-run seed to make seeded category writes idempotent without
  /// routing through the user-facing `save(Category)` path.
  ///
  /// - Insert path: creates the row with the supplied seed-owned fields.
  /// - Update path: rewrites seed-owned fields (`icon`, `color`,
  ///   `sortOrder`, `isArchived = false`) and preserves row identity.
  /// - `customName` is preserved on existing rows.
  /// - If the incoming `type` disagrees with a referenced row, the same
  ///   type-lock guard as [save] applies.
  Future<Category> upsertSeeded({
    required String l10nKey,
    required String icon,
    required int color,
    required CategoryType type,
    required int sortOrder,
  });

  /// Insert-or-update.
  ///
  /// On **insert** (`category.id == 0`): writes a new row.
  /// On **update**: compares `type` against the stored row; if they
  /// differ and the stored category has at least one referencing
  /// transaction, throws [CategoryTypeLockedException] (G5). Otherwise
  /// persists the row.
  ///
  /// Does NOT mutate `l10nKey`. Supplying a `l10nKey` that differs
  /// from the stored one on update is a contract violation and throws
  /// a generic [RepositoryException].
  Future<Category> save(Category category);

  /// Rename a category. Writes `customName` only and leaves `l10nKey`
  /// untouched.
  ///
  /// `customName` may be `null` (revert to localized default) or a
  /// non-empty string. Empty / whitespace-only strings are treated as
  /// `null`.
  Future<Category> rename(int id, String? customName);

  /// Mark the category as archived. Non-destructive; referenced rows
  /// remain queryable via `includeArchived: true`. Idempotent.
  Future<Category> archive(int id);

  /// Hard-delete. Only allowed for unused custom categories. Throws
  /// [CategoryInUseException] when at least one transaction references the id.
  Future<bool> delete(int id);

  /// Returns `true` when at least one row in `transactions` references
  /// this category.
  Future<bool> isReferenced(int id);
}

/// Concrete Drift-backed implementation of [CategoryRepository].
final class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  CategoryDao get _dao => _db.categoryDao;
  TransactionDao get _txDao => _db.transactionDao;
  ShoppingListDao get _slDao => _db.shoppingListDao;

  // ---------- Reads ----------

  @override
  Stream<List<Category>> watchAll({
    CategoryType? type,
    bool includeArchived = false,
  }) {
    final Stream<List<CategoryRow>> source;
    if (type == null && !includeArchived) {
      source = _dao.watchAll(includeArchived: false);
    } else if (type == null && includeArchived) {
      source = _dao.watchAll(includeArchived: true);
    } else if (type != null && !includeArchived) {
      source = _dao.watchByType(_wireFromType(type));
    } else {
      // includeArchived + type: no DAO helper; filter in Dart.
      final wire = _wireFromType(type!);
      source = _dao
          .watchAll(includeArchived: true)
          .map((rows) => rows.where((r) => r.type == wire).toList());
    }
    return source.map((rows) => rows.map(_toDomain).toList(growable: false));
  }

  @override
  Future<Category?> getById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Category?> getByL10nKey(String l10nKey) async {
    final row = await _dao.findByL10nKey(l10nKey);
    return row == null ? null : _toDomain(row);
  }

  // ---------- Writes ----------

  @override
  Future<Category> upsertSeeded({
    required String l10nKey,
    required String icon,
    required int color,
    required CategoryType type,
    required int sortOrder,
  }) async {
    final existing = await _dao.findByL10nKey(l10nKey);
    final wireType = _wireFromType(type);

    if (existing == null) {
      // Insert path.
      final id = await _dao.insert(
        CategoriesCompanion(
          l10nKey: Value(l10nKey),
          icon: Value(icon),
          color: Value(color),
          type: Value(wireType),
          sortOrder: Value(sortOrder),
          isArchived: const Value(false),
        ),
      );
      final inserted = await _dao.findById(id);
      if (inserted == null) {
        throw const CategoryRepositoryException(
          'Seed insert disappeared before read-back',
        );
      }
      return _toDomain(inserted);
    }

    // Update path — enforce the same type-lock guard as `save`.
    if (existing.type != wireType) {
      final txCount = await _txDao.countByCategory(existing.id);
      final slCount = await _slDao.countByCategory(existing.id);
      if (txCount > 0 || slCount > 0) {
        throw CategoryTypeLockedException(existing.id);
      }
    }

    // Rewrite seed-owned fields. `customName` is deliberately omitted
    // so user renames are preserved (same pattern as Currency.upsert).
    await _dao.updateRow(
      CategoriesCompanion(
        id: Value(existing.id),
        l10nKey: Value(l10nKey),
        customName: existing.customName == null
            ? const Value.absent()
            : Value(existing.customName),
        icon: Value(icon),
        color: Value(color),
        type: Value(wireType),
        sortOrder: Value(sortOrder),
        isArchived: const Value(false),
      ),
    );
    final updated = await _dao.findById(existing.id);
    if (updated == null) {
      throw const CategoryRepositoryException(
        'Seed update disappeared before read-back',
      );
    }
    return _toDomain(updated);
  }

  @override
  Future<Category> save(Category category) async {
    if (category.id == 0) {
      // Insert path.
      final id = await _dao.insert(_toCompanion(category));
      final inserted = await _dao.findById(id);
      if (inserted == null) {
        throw const CategoryRepositoryException(
          'Insert disappeared before read-back',
        );
      }
      return _toDomain(inserted);
    }

    // Update path — enforce type-lock and l10nKey-lock.
    final stored = await _dao.findById(category.id);
    if (stored == null) {
      throw CategoryRepositoryException('Category ${category.id} not found');
    }
    final storedType = _typeFromWire(stored.type);
    if (category.type != storedType) {
      final txCount = await _txDao.countByCategory(category.id);
      final slCount = await _slDao.countByCategory(category.id);
      if (txCount > 0 || slCount > 0) {
        throw CategoryTypeLockedException(category.id);
      }
    }
    if ((stored.l10nKey ?? '') != (category.l10nKey ?? '')) {
      throw CategoryRepositoryException(
        'l10nKey mutation forbidden for category ${category.id}; '
        'use rename()',
      );
    }

    await _dao.updateRow(_toCompanion(category));
    final updated = await _dao.findById(category.id);
    if (updated == null) {
      throw CategoryRepositoryException(
        'Category ${category.id} disappeared after update',
      );
    }
    return _toDomain(updated);
  }

  @override
  Future<Category> rename(int id, String? customName) async {
    final existing = await _dao.findById(id);
    if (existing == null) {
      throw CategoryRepositoryException('Category $id not found');
    }
    final normalized = (customName == null || customName.trim().isEmpty)
        ? null
        : customName.trim();

    // Only `custom_name` is written; every other column is absent so the
    // UPDATE leaves them alone.
    await _dao.updateRow(
      CategoriesCompanion(
        id: Value(id),
        l10nKey: existing.l10nKey == null
            ? const Value.absent()
            : Value(existing.l10nKey),
        customName: Value(normalized),
        icon: Value(existing.icon),
        color: Value(existing.color),
        type: Value(existing.type),
        sortOrder: existing.sortOrder == null
            ? const Value.absent()
            : Value(existing.sortOrder),
        isArchived: Value(existing.isArchived),
      ),
    );
    final updated = await _dao.findById(id);
    if (updated == null) {
      throw CategoryRepositoryException(
        'Category $id disappeared after rename',
      );
    }
    return _toDomain(updated);
  }

  @override
  Future<Category> archive(int id) async {
    final existing = await _dao.findById(id);
    if (existing == null) {
      throw CategoryRepositoryException('Category $id not found');
    }
    if (existing.isArchived) {
      // Idempotent.
      return _toDomain(existing);
    }
    await _dao.archiveById(id);
    final updated = await _dao.findById(id);
    if (updated == null) {
      throw CategoryRepositoryException(
        'Category $id disappeared after archive',
      );
    }
    return _toDomain(updated);
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await _dao.findById(id);
    if (existing == null) {
      return false;
    }

    final slCount = await _slDao.countByCategory(id);
    if (slCount > 0) {
      throw CategoryInUseException(id);
    }

    final refCount = await _txDao.countByCategory(id);
    if (refCount > 0) {
      throw CategoryInUseException(id);
    }
    if (existing.l10nKey != null) {
      throw CategoryRepositoryException(
        'Seeded category $id cannot be deleted; archive it instead',
      );
    }

    final removed = await _dao.deleteById(id);
    return removed > 0;
  }

  @override
  Future<bool> isReferenced(int id) async {
    final count = await _txDao.countByCategory(id);
    return count > 0;
  }

  // ---------- Private mapping ----------

  Category _toDomain(CategoryRow row) => Category(
    id: row.id,
    icon: row.icon,
    color: row.color,
    type: _typeFromWire(row.type),
    l10nKey: row.l10nKey,
    customName: row.customName,
    sortOrder: row.sortOrder,
    isArchived: row.isArchived,
  );

  CategoriesCompanion _toCompanion(Category c) {
    return CategoriesCompanion(
      id: c.id == 0 ? const Value.absent() : Value(c.id),
      icon: Value(c.icon),
      color: Value(c.color),
      type: Value(_wireFromType(c.type)),
      l10nKey: c.l10nKey == null ? const Value.absent() : Value(c.l10nKey),
      customName: c.customName == null
          ? const Value.absent()
          : Value(c.customName),
      sortOrder: c.sortOrder == null
          ? const Value.absent()
          : Value(c.sortOrder),
      isArchived: Value(c.isArchived),
    );
  }

  CategoryType _typeFromWire(String wire) => switch (wire) {
    'expense' => CategoryType.expense,
    'income' => CategoryType.income,
    _ => throw CategoryRepositoryException(
      'Unknown category type wire value "$wire"',
    ),
  };

  String _wireFromType(CategoryType t) => switch (t) {
    CategoryType.expense => 'expense',
    CategoryType.income => 'income',
  };
}
