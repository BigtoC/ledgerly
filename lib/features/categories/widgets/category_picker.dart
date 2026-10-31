// Adaptive `showCategoryPicker` — Wave 1 Categories slice implementation
// of the Wave 0 frozen public API
// (`docs/plans/m5-ui-feature-slices/wave-0-contracts-plan.md` §2.1,
// Wave 1 plan §5).
//
// * Signature is frozen — do not add or change parameters here without
//   Wave 0 contract amendment. Amended for issue #81: `type` is optional,
//   and omitting it lists expense then income categories.
// * Presentation adapts at a single 600dp threshold: `showModalBottomSheet`
//   on <600dp, `Dialog` on >=600dp. Both render the same
//   `CustomScrollView → SliverGrid` body.
// * Data flows through the `categoriesByTypeProvider(type)` family in
//   `categories_controller.dart` — never directly from the repository.
// * View-only: no inline "+ New" tile, no plus-FAB, no long-press-to-
//   create. The empty-state CTA closes the picker with `null`; the
//   caller decides what to do next.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';
import '../categories_controller.dart';
import 'category_display.dart';

/// Opens the category picker sheet and resolves with the user's selection.
/// Returns null if the user dismisses the sheet without choosing or taps
/// the empty-state CTA.
///
/// `type` filters by expense/income per PRD §Add/Edit Interaction Rules.
/// When `type` is null the picker lists expense categories, then income
/// categories below them, each under its own title; a type with no
/// categories is left out. Archived categories are always excluded.
/// Categories are sorted by `sortOrder` (nulls last) then display name
/// ascending.
///
/// Presents adaptively per PRD → Adaptive Layouts: modal bottom sheet on
/// <600dp, constrained dialog on >=600dp. Both containers render the
/// same `CustomScrollView → SliverGrid` picker body and survive 2× text
/// scale.
@Dependencies([categoriesByType])
Future<Category?> showCategoryPicker(
  BuildContext context, {
  CategoryType? type,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<Category>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
          child: _CategoryPickerSheet(type: type),
        ),
      ),
    );
  }
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _CategoryPickerSheet(type: type),
    ),
  );
}

/// Picker body — identical across the modal-sheet and dialog containers.
@Dependencies([categoriesByType])
class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.type});

  final CategoryType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final types = switch (type) {
      final type? => [type],
      null => const [CategoryType.expense, CategoryType.income],
    };
    final asyncs = [
      for (final t in types) ref.watch(categoriesByTypeProvider(t)),
    ];
    final error = asyncs.where((a) => a.hasError).firstOrNull?.error;

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          if (error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('$error')),
            )
          else if (!asyncs.every((a) => a.hasValue))
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            for (var i = 0; i < types.length; i++)
              if (types.length == 1 || asyncs[i].requireValue.isNotEmpty) ...[
                _titleSliver(context, l10n, types[i]),
                ..._gridSlivers(context, l10n, asyncs[i].requireValue),
              ],
            if (asyncs.every((a) => a.requireValue.isEmpty))
              ..._emptyStateSlivers(context, l10n),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _titleSliver(
    BuildContext context,
    AppLocalizations l10n,
    CategoryType type,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          type == CategoryType.expense
              ? l10n.categoriesPickerTitleExpense
              : l10n.categoriesPickerTitleIncome,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  List<Widget> _gridSlivers(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
  ) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisExtent: 88,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate((context, i) {
            final cat = categories[i];
            return _CategoryPickerTile(
              category: cat,
              label: categoryDisplayName(cat, l10n),
              onTap: () => Navigator.of(context).pop(cat),
            );
          }, childCount: categories.length),
        ),
      ),
    ];
  }

  List<Widget> _emptyStateSlivers(BuildContext context, AppLocalizations l10n) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.categoriesPickerEmptyCta),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

class _CategoryPickerTile extends StatelessWidget {
  const _CategoryPickerTile({
    required this.category,
    required this.label,
    required this.onTap,
  });

  final Category category;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorForIndex(category.color);
    final icon = iconForKey(category.icon);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            // Shrink a long label instead of wrapping it, so every icon
            // in a row stays on the same line.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
