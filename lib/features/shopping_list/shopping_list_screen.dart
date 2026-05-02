// Shopping-list screen — Task 4.
//
// Layout:
//   Scaffold
//     └─ AppBar (shoppingListScreenTitle)
//     └─ body: switch on AsyncValue<ShoppingListState>:
//         loading → Center(CircularProgressIndicator)
//         empty   → Center(empty-state text + CTA to /home/add)
//         data    → CustomScrollView with SliverList of rows
//         error   → Center(error text + Retry button)
//
// Each row uses Slidable for swipe-to-delete, and a trailing IconButton
// for non-swipe (accessibility) delete. Both call
// `controller.deleteItem(id)` and then show the undo SnackBar.
//
// Effect handling: ShoppingListDeleteFailedEffect → generic error snackbar.
// Undo snackbar is owned solely by this screen (not the controller).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/utils/box_shadow.dart';
import '../../data/models/shopping_list_item.dart';
import '../../l10n/app_localizations.dart';
import 'shopping_list_controller.dart';
import 'shopping_list_state.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  late final ShoppingListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(shoppingListControllerProvider.notifier);
    _controller.setEffectListener(_onEffect);
  }

  @override
  void dispose() {
    _controller.setEffectListener(null);
    super.dispose();
  }

  void _onEffect(ShoppingListEffect effect) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (effect) {
      case ShoppingListDeleteFailedEffect():
        ScaffoldMessenger.maybeOf(context)
          ?..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  void _onDeleteItem(BuildContext context, int id) {
    final l10n = AppLocalizations.of(context);
    unawaited(_controller.deleteItem(id));
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.shoppingListDeleteUndoSnackbar),
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () => unawaited(_controller.undoDelete()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(shoppingListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingListScreenTitle)),
      body: SlidableAutoCloseBehavior(
        child: switch (state) {
          AsyncData<ShoppingListState>(value: ShoppingListLoading()) =>
            const Center(child: CircularProgressIndicator()),
          AsyncData<ShoppingListState>(value: ShoppingListEmpty()) =>
            _EmptyState(onAddPressed: () => context.push('/home/add')),
          AsyncData<ShoppingListState>(value: final ShoppingListData data) =>
            _DataBody(
              data: data,
              canOpenItem: data.pendingDelete == null,
              onDeleteItem: (id) => _onDeleteItem(context, id),
              onTapItem: (id) => context.push('/accounts/shopping-list/$id'),
            ),
          AsyncData<ShoppingListState>(value: ShoppingListError()) =>
            _ErrorSurface(
              message: l10n.errorSnackbarGeneric,
              onRetry: () => ref.invalidate(shoppingListControllerProvider),
            ),
          AsyncError() => _ErrorSurface(
            message: l10n.errorSnackbarGeneric,
            onRetry: () => ref.invalidate(shoppingListControllerProvider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

// ---------- Body widgets ----------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.shoppingListScreenEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAddPressed,
              child: Text(l10n.shoppingListScreenEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataBody extends StatelessWidget {
  const _DataBody({
    required this.data,
    required this.canOpenItem,
    required this.onDeleteItem,
    required this.onTapItem,
  });

  final ShoppingListData data;
  final bool canOpenItem;
  final void Function(int id) onDeleteItem;
  final void Function(int id) onTapItem;

  @override
  Widget build(BuildContext context) {
    final items = data.items;
    if (items.isEmpty) {
      // Pending delete in progress; show empty list area.
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    const cardPadding = EdgeInsets.symmetric(
      horizontal: homePageCardHorizontalPadding - 16,
      vertical: 12,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(homePageCardBorderRadius),
                boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final item in items)
                    _ShoppingListRow(
                      item: item,
                      canTap: canOpenItem,
                      onDelete: () => onDeleteItem(item.id),
                      onTap: () => onTapItem(item.id),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _ShoppingListRow extends StatelessWidget {
  const _ShoppingListRow({
    required this.item,
    required this.canTap,
    required this.onDelete,
    required this.onTap,
  });

  final ShoppingListItem item;
  final bool canTap;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Slidable(
      key: ValueKey('shoppingListRow:${item.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete,
            label: l10n.shoppingListDeleteAction,
          ),
        ],
      ),
      child: ListTile(
        title: Text(item.memo ?? ''),
        onTap: canTap ? onTap : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(item.draftDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            IconButton(
              key: ValueKey('shoppingListItem:${item.id}:delete'),
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.shoppingListDeleteAction,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.shoppingListScreenRetry),
            ),
          ],
        ),
      ),
    );
  }
}
