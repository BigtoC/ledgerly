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
// which affordance to show and routes the correct command. Every
// command returns a sealed outcome from `categories_state.dart` and
// never throws: `CategoryInUseException` and
// `CategoryHasRecurringRuleException` map to their own variants, and
// every other failure is logged by type and returned as `failed`. The
// widgets switch on the outcome to pick a localized message without
// importing the repository. The form sheet stays open for retry
// (plan §6).

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../domain/models/category.dart';
import 'categories_state.dart';

part 'categories_controller.g.dart';

/// Picker data source (plan §5). Must NOT be `keepAlive: true`.
@Riverpod(dependencies: [categoryRepository])
Stream<List<Category>> categoriesByType(Ref ref, CategoryType type) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll(type: type, includeArchived: false).map(_sortForDisplay);
}

@Riverpod(dependencies: [categoryRepository])
class CategoriesController extends _$CategoriesController {
  @override
  Stream<CategoriesState> build() async* {
    final repo = ref.watch(categoryRepositoryProvider);

    final source = repo.watchAll(includeArchived: false);
    await for (final rows in source) {
      final expense = <Category>[];
      final income = <Category>[];
      for (final c in rows) {
        if (c.type == CategoryType.expense) {
          expense.add(c);
        } else {
          income.add(c);
        }
      }
      final expenseViews = await _withAffordance(
        _sortForDisplay(expense),
        repo,
      );
      final incomeViews = await _withAffordance(_sortForDisplay(income), repo);
      yield CategoriesState.data(expense: expenseViews, income: incomeViews);
    }
  }

  // ---------- Commands ----------

  /// Create a new category. `category.id` must be `0`.
  Future<SaveCategoryOutcome> createCategory(Category category) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.save(category.copyWith(id: 0));
      return const SaveCategoryOutcome.ok();
    } catch (e) {
      debugPrint(
        '[CategoriesController] createCategory failed: ${e.runtimeType}',
      );
      return const SaveCategoryOutcome.failed();
    }
  }

  /// Rename an existing category. Writes `customName` only.
  Future<SaveCategoryOutcome> renameCategory(int id, String? customName) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.rename(id, customName);
      return const SaveCategoryOutcome.ok();
    } catch (e) {
      debugPrint(
        '[CategoriesController] renameCategory failed: ${e.runtimeType}',
      );
      return const SaveCategoryOutcome.failed();
    }
  }

  /// Updates icon + color on an existing category, preserving every other
  /// field. Never mutates `type` or `l10nKey`; those have repo-level
  /// locks. A missing row is [SaveCategoryOutcome.failed].
  Future<SaveCategoryOutcome> updateIconColor({
    required int id,
    required String icon,
    required int color,
  }) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final existing = await repo.getById(id);
      if (existing == null) return const SaveCategoryOutcome.failed();
      await repo.save(existing.copyWith(icon: icon, color: color));
      return const SaveCategoryOutcome.ok();
    } catch (e) {
      debugPrint(
        '[CategoriesController] updateIconColor failed: ${e.runtimeType}',
      );
      return const SaveCategoryOutcome.failed();
    }
  }

  /// Archive a category. Idempotent at repo level. Returns
  /// [ArchiveCategoryOutcome.hasActiveRecurringRule] when an active
  /// recurring rule still uses the category.
  Future<ArchiveCategoryOutcome> archiveCategory(int id) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.archive(id);
      return const ArchiveCategoryOutcome.ok();
    } on CategoryHasRecurringRuleException {
      return const ArchiveCategoryOutcome.hasActiveRecurringRule();
    } catch (e) {
      debugPrint(
        '[CategoriesController] archiveCategory failed: ${e.runtimeType}',
      );
      return const ArchiveCategoryOutcome.failed();
    }
  }

  /// Un-archive after an undo-snackbar action. A row that no longer
  /// exists has nothing to restore, so it is [UndoArchiveCategoryOutcome.ok]
  /// and writes nothing.
  ///
  /// The action can run after the screen is gone, on a controller that
  /// `container.read` just rebuilt and will dispose again, so the
  /// repository is read before the first await and `ref` is not used
  /// after it.
  Future<UndoArchiveCategoryOutcome> undoArchive(int id) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final existing = await repo.getById(id);
      if (existing == null) return const UndoArchiveCategoryOutcome.ok();
      await repo.save(existing.copyWith(isArchived: false));
      return const UndoArchiveCategoryOutcome.ok();
    } catch (e) {
      debugPrint('[CategoriesController] undoArchive failed: ${e.runtimeType}');
      return const UndoArchiveCategoryOutcome.failed();
    }
  }

  /// Hard-delete a custom, unused category. Returns
  /// [DeleteCategoryOutcome.inUse] when transactions, recurring rules or
  /// shopping-list drafts still reference the row. A row that is already
  /// gone is [DeleteCategoryOutcome.ok].
  Future<DeleteCategoryOutcome> deleteCategory(int id) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.delete(id);
      return const DeleteCategoryOutcome.ok();
    } on CategoryInUseException {
      return const DeleteCategoryOutcome.inUse();
    } catch (e) {
      debugPrint(
        '[CategoriesController] deleteCategory failed: ${e.runtimeType}',
      );
      return const DeleteCategoryOutcome.failed();
    }
  }

  /// Re-order within a single type section. `orderedIds` is the new
  /// top-to-bottom order for the section (no cross-type moves).
  ///
  /// Writes `sortOrder` as the list index in one transaction, so a
  /// failure leaves the old order untouched. Other fields are preserved.
  Future<ReorderCategoriesOutcome> reorder(List<int> orderedIds) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.reorder(orderedIds);
      return const ReorderCategoriesOutcome.ok();
    } catch (e) {
      debugPrint('[CategoriesController] reorder failed: ${e.runtimeType}');
      return const ReorderCategoriesOutcome.failed();
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
