import 'package:drift/drift.dart';

/// Drift table for `categories`.
///
/// See `PRD.md` lines 293–314 (Database Schema → categories) and
/// `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.3.
///
/// - `l10n_key` is the **stable identity** for seeded rows; renames write
///   `custom_name` and keep `l10n_key` intact so locale switches neither
///   duplicate nor orphan rows.
/// - `icon` is a string key resolved via `core/utils/icon_registry.dart`;
///   `color` is an index into the append-only
///   `core/utils/color_palette.dart`. Never store `IconData` or ARGB ints.
/// - `type` is stored as TEXT with a SQL-level
///   `CHECK (type IN ('expense', 'income'))`. The category type-lock
///   after first-use is enforced in `CategoryRepository` (M3), not here.
@DataClassName('CategoryRow')
@TableIndex(name: 'categories_parent_idx', columns: {#parentId})
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get l10nKey => text().named('l10n_key').nullable().unique()();
  TextColumn get customName => text().named('custom_name').nullable()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK (type IN ('expense', 'income'))",
  )();
  IntColumn get parentId =>
      integer().named('parent_id').nullable().references(Categories, #id)();
  IntColumn get sortOrder => integer().named('sort_order').nullable()();
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();
}
