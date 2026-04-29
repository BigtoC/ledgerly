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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../l10n/app_localizations.dart';
import 'categories_controller.dart';
import 'categories_state.dart';
import 'widgets/category_form_sheet.dart';
import 'widgets/category_tile.dart';

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
          AsyncData<CategoriesState>(value: CategoriesError()) ||
          AsyncError() => const _ErrorSurface(),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _CategoriesBody extends ConsumerWidget {
  const _CategoriesBody({required this.data});

  final CategoriesData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      onReorder: (oldIndex, newIndex) {
        final reordered = [...rows];
        final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(adjusted, moved);
        unawaited(
          ref
              .read(categoriesControllerProvider.notifier)
              .reorder(reordered.map((v) => v.category.id).toList()),
        );
      },
    );
  }

  Future<void> _onArchive(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(categoriesControllerProvider.notifier)
          .archiveCategory(cat.id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.categoriesArchiveUndoSnackbar),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () => unawaited(
            ref.read(categoriesControllerProvider.notifier).undoArchive(cat.id),
          ),
        ),
      ),
    );
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
    try {
      await ref
          .read(categoriesControllerProvider.notifier)
          .deleteCategory(cat.id);
    } on CategoryInUseException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
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
