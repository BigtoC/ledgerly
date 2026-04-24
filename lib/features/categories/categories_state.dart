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

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/category.dart';

part 'categories_state.freezed.dart';

/// Affordance hint computed by the controller for a row (plan §7).
///
/// - `isReferenced(id) == true` → archive
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
