// Frozen public API for the category picker.
//
// Owned by the Categories slice; imported by the Transactions slice and
// any other caller that needs the user to select a category. The picker
// is view-only in MVP: no inline "+ New" tile, no plus-FAB, no
// long-press-to-create. Category creation lives on the Categories
// management screen (Settings → Manage Categories).
//
// The implementation lands in Wave 1 (Categories slice owner). Wave 0
// freezes only the call-site signature so parallel slices can code
// against a stable contract.
//
// See `docs/plans/m5-ui-feature-slices/wave-0-contracts-plan.md` §2.1.

import 'package:flutter/material.dart';

import '../../../data/models/category.dart';

/// Opens the category picker sheet and resolves with the user's selection.
/// Returns null if the user dismisses the sheet without choosing.
///
/// `type` filters by expense/income per PRD §Add/Edit Interaction Rules.
/// Archived categories are always excluded from the picker. Categories
/// are sorted by `sortOrder` (nulls last) then by display name.
///
/// Presents adaptively per PRD.md → Adaptive Layouts: modal bottom sheet
/// on <600dp, constrained dialog on >=600dp. Both containers render the
/// same `CustomScrollView → SliverGrid` picker body and must survive 2×
/// text scale per PRD.md → Layout Primitives → Constraint rule.
///
/// Implementation lands in Wave 1 (Categories slice owner).
Future<Category?> showCategoryPicker(
  BuildContext context, {
  required CategoryType type,
}) {
  throw UnimplementedError('Wave 1: Categories slice owner');
}
