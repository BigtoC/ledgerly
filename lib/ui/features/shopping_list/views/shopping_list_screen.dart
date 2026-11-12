// Shopping-list screen — Task 4.
//
// Layout:
//   Scaffold
//     └─ AppBar (shoppingListScreenTitle)
//     └─ body: switch on AsyncValue<ShoppingListState>:
//         loading → Center(CircularProgressIndicator)
//         empty   → Center(empty-state text + CTA to /home/shopping-list/new)
//         data    → CustomScrollView with SliverList of rows
//         error   → Center(error text + Retry button)
//     └─ FAB (empty and data states) → /home/shopping-list/new (issue #147)
//
// Each row uses Slidable for swipe-to-delete, and a trailing IconButton
// for non-swipe (accessibility) delete. Both call
// `controller.deleteItem(id)` and then show the undo SnackBar.
//
// Effect handling: ShoppingListDeleteFailedEffect → generic error snackbar.
// Undo snackbar is owned solely by this screen (not the controller).

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../core/constants.dart';
import '../../../../core/utils/box_shadow.dart';
import '../../../../domain/models/shopping_list_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../../transactions/view_models/transaction_form_state.dart';
import '../view_models/shopping_list_controller.dart';
import '../view_models/shopping_list_providers.dart';
import '../view_models/shopping_list_state.dart';
import 'shopping_list_item_labels.dart';

@Dependencies([
  ShoppingListController,
  shoppingListCategoryById,
  shoppingListAccountById,
  shoppingListCurrencyByCode,
])
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  ShoppingListController? _controller;
  int? _lastShownPendingId;

  @override
  void initState() {
    super.initState();
    _bindController(ref.read(shoppingListControllerProvider.notifier));
  }

  @override
  void dispose() {
    _controller?.setEffectListener(null);
    super.dispose();
  }

  void _bindController(ShoppingListController controller) {
    if (identical(_controller, controller)) return;
    _controller?.setEffectListener(null);
    _controller = controller;
    _controller?.setEffectListener(_onEffect);
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

  void _maybeShowUndoSnackbar(BuildContext context, int? pendingId) {
    if (pendingId == null) {
      _lastShownPendingId = null;
      return;
    }
    if (_lastShownPendingId == pendingId) return;

    _lastShownPendingId = pendingId;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showUndoSnackBar(
      message: l10n.shoppingListDeleteUndoSnackbar,
      undoLabel: l10n.commonUndo,
      onUndo: () {
        // The snackbar outlives this screen. Once the screen is gone,
        // the auto-dispose controller has dropped the pending delete,
        // so there is nothing to undo and `ref` is unusable.
        if (!mounted) return;
        ref.read(shoppingListControllerProvider.notifier).undoDelete();
      },
    );
  }

  /// Opens the draft form at [location] (`/home/shopping-list/<id>` or
  /// `/home/shopping-list/new`) and confirms its result with a snackbar.
  Future<void> _openForm(BuildContext context, String location) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.push<ShoppingListEditResult?>(location);
    if (!mounted) return;
    final message = switch (result) {
      ShoppingListEditResultMissingDraft() =>
        l10n.shoppingListDraftNotFoundSnackbar,
      ShoppingListEditResultSavedDraft() ||
      ShoppingListEditResultAddedToList() =>
        l10n.shoppingListSavedDraftSnackbar,
      ShoppingListEditResultSavedTransaction() =>
        l10n.shoppingListConvertedSnackbar,
      null => null,
    };
    if (message == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onDeleteItem(int id) {
    unawaited(ref.read(shoppingListControllerProvider.notifier).deleteItem(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(shoppingListControllerProvider);
    _bindController(ref.read(shoppingListControllerProvider.notifier));

    ref.listen(shoppingListControllerProvider, (_, next) {
      if (next case AsyncData<ShoppingListState>(value: final value)) {
        switch (value) {
          case ShoppingListData(:final pendingDeleteId):
            _maybeShowUndoSnackbar(context, pendingDeleteId);
          case ShoppingListLoading() ||
              ShoppingListEmpty() ||
              ShoppingListError():
            _maybeShowUndoSnackbar(context, null);
        }
      }
    });

    void onAdd() => _openForm(context, '/home/shopping-list/new');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingListScreenTitle)),
      floatingActionButton: switch (state) {
        AsyncData<ShoppingListState>(
          value: ShoppingListEmpty() || ShoppingListData(),
        ) =>
          FloatingActionButton(
            tooltip: l10n.shoppingListScreenEmptyCta,
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        _ => null,
      },
      body: SlidableAutoCloseBehavior(
        child: switch (state) {
          AsyncData<ShoppingListState>(value: ShoppingListLoading()) =>
            const Center(child: CircularProgressIndicator()),
          AsyncData<ShoppingListState>(value: ShoppingListEmpty()) =>
            _EmptyState(onAddPressed: onAdd),
          AsyncData<ShoppingListState>(value: final ShoppingListData data) =>
            _DataBody(
              data: data,
              onDeleteItem: _onDeleteItem,
              onTapItem: (id) => _openForm(context, '/home/shopping-list/$id'),
            ),
          AsyncData<ShoppingListState>(value: ShoppingListError()) ||
          AsyncError() => _ErrorSurface(
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

@Dependencies([
  shoppingListCategoryById,
  shoppingListAccountById,
  shoppingListCurrencyByCode,
])
class _DataBody extends StatelessWidget {
  const _DataBody({
    required this.data,
    required this.onDeleteItem,
    required this.onTapItem,
  });

  final ShoppingListData data;
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
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(homePageCardBorderRadius),
              boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
            ),
            sliver: SliverClipRRect(
              borderRadius: BorderRadius.circular(homePageCardBorderRadius),
              clipOverlap: ClipOverlapBehavior.none,
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ShoppingListRow(
                    item: item,
                    canTap: data.pendingDeleteId == null,
                    onDelete: () => onDeleteItem(item.id),
                    onTap: () => onTapItem(item.id),
                  );
                },
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

@Dependencies([
  shoppingListCategoryById,
  shoppingListAccountById,
  shoppingListCurrencyByCode,
])
class _ShoppingListRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final categoryAsync = ref.watch(
      shoppingListCategoryByIdProvider(item.categoryId),
    );
    final accountAsync = ref.watch(
      shoppingListAccountByIdProvider(item.accountId),
    );
    final currencyAsync = item.draftCurrencyCode != null
        ? ref.watch(shoppingListCurrencyByCodeProvider(item.draftCurrencyCode!))
        : null;

    final category = categoryAsync.value;
    final account = accountAsync.value;
    final currency = currencyAsync?.value;

    final locale = Localizations.localeOf(context).toString();
    final primaryLabel = resolvePrimaryLabel(item, category, l10n);
    final secondaryLabel = resolveSecondaryLabel(category, account, l10n);
    final trailingLabel = resolveTrailingLabel(item, currency, locale);

    return Material(
      type: MaterialType.transparency,
      child: Slidable(
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
          title: Text(primaryLabel),
          subtitle: secondaryLabel.isNotEmpty ? Text(secondaryLabel) : null,
          onTap: canTap ? onTap : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailingLabel,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.end,
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
      ),
    );
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface({required this.onRetry});

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
              l10n.errorSnackbarGeneric,
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
