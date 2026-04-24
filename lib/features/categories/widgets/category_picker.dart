// Adaptive `showCategoryPicker` — Wave 1 Categories slice implementation
// of the Wave 0 frozen public API
// (`docs/plans/m5-ui-feature-slices/wave-0-contracts-plan.md` §2.1,
// Wave 1 plan §5).
//
// * Signature is frozen — do not add or change parameters here without
//   Wave 0 contract amendment.
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
/// Archived categories are always excluded. Categories are sorted by
/// `sortOrder` (nulls last) then display name ascending.
///
/// Presents adaptively per PRD → Adaptive Layouts: modal bottom sheet on
/// <600dp, constrained dialog on >=600dp. Both containers render the
/// same `CustomScrollView → SliverGrid` picker body and survive 2× text
/// scale.
Future<Category?> showCategoryPicker(
  BuildContext context, {
  required CategoryType type,
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
      heightFactor: 0.75,
      child: _CategoryPickerSheet(type: type),
    ),
  );
}

/// Picker body — identical across the modal-sheet and dialog containers.
class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.type});

  final CategoryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(categoriesByTypeProvider(type));
    final title = type == CategoryType.expense
        ? l10n.categoriesPickerTitleExpense
        : l10n.categoriesPickerTitleIncome;

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ...switch (async) {
            AsyncData<List<Category>>(:final value) when value.isEmpty =>
              _emptyStateSlivers(context, l10n),
            AsyncData<List<Category>>(:final value) => _gridSlivers(
              context,
              l10n,
              value,
            ),
            AsyncError(:final error) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('$error')),
              ),
            ],
            _ => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
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
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            childAspectRatio: 0.85,
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
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
