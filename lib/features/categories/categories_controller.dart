// Categories slice controller (plan §3.1, §5, §7).
//
// Two Riverpod surfaces live here:
//   1. `categoriesByTypeProvider(type)` — family `StreamProvider<List<Category>>`
//      used by `showCategoryPicker`. Not `keepAlive` (plan §12 risk #6);
//      the picker disposes on sheet close and frees its subscription.
//   2. `CategoriesController` — screen-scoped `StreamNotifier` that
//      reads every visible category, computes the per-row
//      archive-vs-delete affordance per plan §7, and exposes typed
//      commands for create/rename/updateIconColor/archive/undoArchive/
//      delete/reorder.
//
// Repository-layer invariants (category-type lock, seeded-row-cannot-
// delete) stay in `CategoryRepository`; the controller only derives
// which affordance to show and routes the correct command. Typed
// exceptions (`CategoryTypeLockedException`, `CategoryInUseException`)
// bubble to the form sheet via `AsyncError` so the sheet stays open for
// retry (plan §6).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import 'categories_state.dart';

part 'categories_controller.g.dart';

/// Picker data source (plan §5). Must NOT be `keepAlive: true`.
@riverpod
Stream<List<Category>> categoriesByType(Ref ref, CategoryType type) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo
      .watchAll(type: type, includeArchived: false)
      .map((rows) => _sortForDisplay(rows));
}

@riverpod
class CategoriesController extends _$CategoriesController {
  @override
  Stream<CategoriesState> build() async* {
    final repo = ref.watch(categoryRepositoryProvider);

    final source = repo.watchAll(includeArchived: false);
    await for (final rows in source) {
      final expense = <Category>[];
      final income = <Category>[];
      for (final c in rows) {
        if (c.isArchived) continue;
        if (c.type == CategoryType.expense) {
          expense.add(c);
        } else {
          income.add(c);
        }
      }
      final expenseViews = await _withAffordance(_sortForDisplay(expense), repo);
      final incomeViews = await _withAffordance(_sortForDisplay(income), repo);
      yield CategoriesState.data(expense: expenseViews, income: incomeViews);
    }
  }

  // ---------- Commands ----------

  /// Create a new category. `category.id` must be `0`.
  Future<Category> createCategory(Category category) {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.save(category.copyWith(id: 0));
  }

  /// Rename an existing category. Writes `customName` only.
  Future<Category> renameCategory(int id, String? customName) {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.rename(id, customName);
  }

  /// Updates icon + color on an existing category, preserving every other
  /// field. Never mutates `type` or `l10nKey`; those have repo-level
  /// locks.
  Future<Category> updateIconColor({
    required int id,
    required String icon,
    required int color,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final existing = await repo.getById(id);
    if (existing == null) {
      throw CategoryRepositoryException('Category $id not found');
    }
    return repo.save(existing.copyWith(icon: icon, color: color));
  }

  /// Archive a category. Idempotent at repo level.
  Future<Category> archiveCategory(int id) {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.archive(id);
  }

  /// Un-archive after an undo-snackbar action.
  Future<Category> undoArchive(int id) async {
    final repo = ref.read(categoryRepositoryProvider);
    final existing = await repo.getById(id);
    if (existing == null) {
      throw CategoryRepositoryException('Category $id not found');
    }
    return repo.save(existing.copyWith(isArchived: false));
  }

  /// Hard-delete a custom, unused category. Surfaces
  /// [CategoryInUseException] when the row has referencing transactions.
  Future<bool> deleteCategory(int id) {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.delete(id);
  }

  /// Re-order within a single type section. `orderedIds` is the new
  /// top-to-bottom order for the section (no cross-type moves).
  ///
  /// Writes `sortOrder` as the list index. Other fields are preserved.
  Future<void> reorder(List<int> orderedIds) async {
    final repo = ref.read(categoryRepositoryProvider);
    for (var i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final existing = await repo.getById(id);
      if (existing == null) continue;
      await repo.save(existing.copyWith(sortOrder: i));
    }
  }

  // ---------- Private helpers ----------

  Future<List<CategoryRowView>> _withAffordance(
    List<Category> rows,
    CategoryRepository repo,
  ) async {
    final out = <CategoryRowView>[];
    for (final c in rows) {
      final affordance = await _computeAffordance(c, repo);
      out.add(CategoryRowView(category: c, affordance: affordance));
    }
    return out;
  }

  Future<CategoryRowAffordance> _computeAffordance(
    Category c,
    CategoryRepository repo,
  ) async {
    // Seeded rows always archive — never delete, even if unreferenced
    // (plan §12 risk #3).
    if (c.l10nKey != null) return CategoryRowAffordance.archive;
    final referenced = await repo.isReferenced(c.id);
    return referenced
        ? CategoryRowAffordance.archive
        : CategoryRowAffordance.delete;
  }
}

// ---------- Shared sort helpers ----------

/// Sort order: `sortOrder ASC (nulls last)`, then display-name ASC.
/// Display name = `customName ?? l10nKey ?? id.toString()`.
List<Category> _sortForDisplay(List<Category> rows) {
  final copy = [...rows];
  copy.sort((a, b) {
    final sa = a.sortOrder;
    final sb = b.sortOrder;
    if (sa != sb) {
      if (sa == null) return 1;
      if (sb == null) return -1;
      return sa.compareTo(sb);
    }
    final na = a.customName ?? a.l10nKey ?? a.id.toString();
    final nb = b.customName ?? b.l10nKey ?? b.id.toString();
    return na.toLowerCase().compareTo(nb.toLowerCase());
  });
  return copy;
}
