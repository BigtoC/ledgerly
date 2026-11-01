// Categories slice state (plan §3.1).
//
// Freezed sealed union. First-run seed guarantees the DB is never empty,
// so there is no top-level `empty` variant — the `Data` variant still
// supports per-section empty rendering after archive flows (plan §3.1,
// §4).
//
// Both `expense` and `income` lists are pre-sorted by the controller:
// `sortOrder ASC (nulls last)`, then display name ASC (resolved via
// `customName` first, `l10nKey` otherwise).
//
// The `*Outcome` unions at the end are what the controller's commands
// return; widgets switch on them to pick a message.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/category.dart';

part 'categories_state.freezed.dart';

/// Affordance hint computed by the controller for a row (plan §7).
///
/// - `isReferenced(id) == true` (transactions or active recurring rules)
///   → archive
/// - `l10nKey != null` (seeded row), referenced or not → archive
/// - `l10nKey == null` AND `isReferenced(id) == false` (custom unused) →
///   delete
enum CategoryRowAffordance { archive, delete }

@freezed
sealed class CategoriesState with _$CategoriesState {
  /// Pre-first-emission from the underlying category stream.
  const factory CategoriesState.loading() = CategoriesLoading;

  /// Fully-resolved category lists, grouped by type with per-row
  /// affordance hints pre-computed.
  const factory CategoriesState.data({
    required List<CategoryRowView> expense,
    required List<CategoryRowView> income,
  }) = CategoriesData;

  /// Upstream stream failure.
  const factory CategoriesState.error(Object error, StackTrace stack) =
      CategoriesError;
}

/// One row's view-model. Pairs the domain [Category] with the
/// controller-computed affordance so the widget does not re-query the
/// repository on render (plan §4).
@freezed
abstract class CategoryRowView with _$CategoryRowView {
  const factory CategoryRowView({
    required Category category,
    required CategoryRowAffordance affordance,
  }) = _CategoryRowView;
}

/// Result of [CategoriesController.createCategory],
/// [CategoriesController.renameCategory] and
/// [CategoriesController.updateIconColor]. Shared because all three feed
/// the form sheet's one inline banner.
@freezed
sealed class SaveCategoryOutcome with _$SaveCategoryOutcome {
  /// Saved. The form sheet closes.
  const factory SaveCategoryOutcome.ok() = SaveCategoryOk;

  /// Any failure. The sheet stays open with `errorSnackbarGeneric` inline.
  const factory SaveCategoryOutcome.failed() = SaveCategoryFailed;
}

/// Result of [CategoriesController.archiveCategory].
@freezed
sealed class ArchiveCategoryOutcome with _$ArchiveCategoryOutcome {
  /// Archived. The widget shows the Undo snackbar.
  const factory ArchiveCategoryOutcome.ok() = ArchiveCategoryOk;

  /// An active recurring rule uses the category. The widget shows
  /// `categoriesArchiveRecurringRuleError`.
  const factory ArchiveCategoryOutcome.hasActiveRecurringRule() =
      ArchiveCategoryHasActiveRecurringRule;

  /// Any other failure. The widget shows `errorSnackbarGeneric`.
  const factory ArchiveCategoryOutcome.failed() = ArchiveCategoryFailed;
}

/// Result of [CategoriesController.undoArchive].
@freezed
sealed class UndoArchiveCategoryOutcome with _$UndoArchiveCategoryOutcome {
  /// Restored, or the row no longer exists. The widget shows nothing.
  const factory UndoArchiveCategoryOutcome.ok() = UndoArchiveCategoryOk;

  /// Any failure. The widget shows `errorSnackbarGeneric`.
  const factory UndoArchiveCategoryOutcome.failed() = UndoArchiveCategoryFailed;
}

/// Result of [CategoriesController.deleteCategory].
@freezed
sealed class DeleteCategoryOutcome with _$DeleteCategoryOutcome {
  /// Deleted, or the row was already gone. The widget shows nothing.
  const factory DeleteCategoryOutcome.ok() = DeleteCategoryOk;

  /// Transactions, recurring rules or shopping-list drafts still use the
  /// category. The widget shows `categoriesDeleteInUseError`.
  const factory DeleteCategoryOutcome.inUse() = DeleteCategoryInUse;

  /// Any other failure. The widget shows `errorSnackbarGeneric`.
  const factory DeleteCategoryOutcome.failed() = DeleteCategoryFailed;
}

/// Result of [CategoriesController.reorder].
@freezed
sealed class ReorderCategoriesOutcome with _$ReorderCategoriesOutcome {
  /// Every row has its new `sortOrder`. The widget shows nothing.
  const factory ReorderCategoriesOutcome.ok() = ReorderCategoriesOk;

  /// Nothing was written. The widget shows `errorSnackbarGeneric`.
  const factory ReorderCategoriesOutcome.failed() = ReorderCategoriesFailed;
}
