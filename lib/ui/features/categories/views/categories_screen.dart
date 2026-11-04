// Categories management screen (plan §4).
//
// Layout (PRD → Layout Primitives): `Scaffold` → `CustomScrollView`
// with Expense header, expense list, Income header, income list, and
// FAB-clearance padding. Per-section inline Add CTA shows when a
// section has no visible categories (plan §4).
//
// Reordering uses `SliverReorderableList`; per-row swipe actions are
// rendered by `CategoryTile` via `flutter_slidable`. Archive actions
// emit an undo snackbar; delete actions confirm via a dialog first.
//
// `CategoriesController` commands return sealed outcomes, which this
// file switches on (it never imports the repository). A delete blocked
// by references and an archive blocked by an active recurring rule show
// localized snackbars; every other failure, including a failed reorder
// or Undo, shows `errorSnackbarGeneric`. Every snackbar clears the
// current one first: an Undo snackbar has an action, so it stays until
// dismissed, and anything shown after it would wait behind it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../domain/models/category.dart';
import '../../../../l10n/app_localizations.dart';
import '../view_models/categories_controller.dart';
import '../view_models/categories_state.dart';
import 'category_form_sheet.dart';
import 'category_tile.dart';

@Dependencies([CategoriesController])
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(categoriesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesManageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'categories_fab',
        onPressed: () => showCategoryFormSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.categoriesAddCta),
      ),
      body: SlidableAutoCloseBehavior(
        child: switch (state) {
          AsyncData<CategoriesState>(value: final CategoriesData data) =>
            _CategoriesBody(data: data),
          AsyncError() => const _ErrorSurface(),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

@Dependencies([CategoriesController])
class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody({required this.data});

  final CategoriesData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        _SectionHeader(label: l10n.categoriesSectionExpense),
        _Section(type: CategoryType.expense, rows: data.expense, l10n: l10n),
        _SectionHeader(label: l10n.categoriesSectionIncome),
        _Section(type: CategoryType.income, rows: data.income, l10n: l10n),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

@Dependencies([CategoriesController])
class _Section extends ConsumerWidget {
  const _Section({required this.type, required this.rows, required this.l10n});

  final CategoryType type;
  final List<CategoryRowView> rows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: OutlinedButton.icon(
            onPressed: () => showCategoryFormSheet(
              context,
              initial: Category(id: 0, icon: 'category', color: 0, type: type),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.categoriesAddCta),
          ),
        ),
      );
    }
    return SliverReorderableList(
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final view = rows[i];
        return CategoryTile(
          key: ValueKey('categoryTile:${view.category.id}'),
          view: view,
          index: i,
          onTap: () => showCategoryFormSheet(context, initial: view.category),
          onArchive: () => _onArchive(context, ref, view.category),
          onDelete: () => _onDelete(context, ref, view.category),
        );
      },
      onReorderItem: (oldIndex, newIndex) =>
          _onReorder(context, ref, oldIndex, newIndex),
    );
  }

  Future<void> _onReorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final reordered = [...rows];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final outcome = await ref
        .read(categoriesControllerProvider.notifier)
        .reorder(reordered.map((v) => v.category.id).toList());
    switch (outcome) {
      case ReorderCategoriesOk():
        break;
      case ReorderCategoriesFailed():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  Future<void> _onArchive(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // Undo can be tapped after this screen is gone, when `ref` throws.
    final container = ProviderScope.containerOf(context, listen: false);
    final outcome = await ref
        .read(categoriesControllerProvider.notifier)
        .archiveCategory(cat.id);
    switch (outcome) {
      case ArchiveCategoryOk():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.categoriesArchiveUndoSnackbar),
              action: SnackBarAction(
                label: l10n.commonUndo,
                onPressed: () async {
                  final undone = await container
                      .read(categoriesControllerProvider.notifier)
                      .undoArchive(cat.id);
                  switch (undone) {
                    case UndoArchiveCategoryOk():
                      break;
                    case UndoArchiveCategoryFailed():
                      messenger
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
                        );
                  }
                },
              ),
            ),
          );
      case ArchiveCategoryHasActiveRecurringRule():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.categoriesArchiveRecurringRuleError)),
          );
      case ArchiveCategoryFailed():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categoriesDeleteConfirmTitle),
        content: Text(l10n.categoriesDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(categoriesControllerProvider.notifier)
        .deleteCategory(cat.id);
    switch (outcome) {
      case DeleteCategoryOk():
        break;
      case DeleteCategoryInUse():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.categoriesDeleteInUseError)),
          );
      case DeleteCategoryFailed():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.errorSnackbarGeneric),
      ),
    );
  }
}
