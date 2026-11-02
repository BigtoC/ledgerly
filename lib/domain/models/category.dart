import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// Expense vs income. Wire values match `categories.type` TEXT column
/// (Stream A §2.3) — do not rename without a schema migration.
///
/// Wire values are **migration-locked**: lowercase `'expense'` / `'income'`
/// forever. No `transfer` variant, now or ever (see Stream C §9.6).
enum CategoryType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

/// User-facing category. Mirrors `categories` row (PRD.md 293-314).
/// Display name resolution: `customName ?? l10nKey` — handled at the UI
/// boundary, not here (PRD.md 308-309, CLAUDE.md -> Data-Model Invariants).
@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,

    /// Icon-registry string key. Never `IconData`.
    required String icon,

    /// Index into `core/utils/color_palette.dart`. Never ARGB.
    required int color,

    /// Immutable after first referencing transaction (enforced in
    /// `CategoryRepository` at M3).
    required CategoryType type,

    /// Stable identity for seeded rows.
    String? l10nKey,

    /// User override of the localized name.
    String? customName,

    /// Order in pickers.
    int? sortOrder,

    /// DB default `false`.
    @Default(false) bool isArchived,
  }) = _Category;
}
