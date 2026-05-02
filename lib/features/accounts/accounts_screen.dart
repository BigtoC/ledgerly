// Accounts list screen (plan §3.1, §4).
//
// Layout (PRD → Layout Primitives): `Scaffold` with a `CustomScrollView`
// containing a title header sliver, the active-accounts sliver list,
// an optional archived-accounts sliver section, and an FAB-clearance
// pad. FAB routes to `/accounts/new`. Tapping a tile routes to
// `/accounts/:id`.
//
// Swipe + overflow actions (set default / archive / delete) are
// rendered by `AccountTile`; the screen owns the async plumbing
// (undo snackbar, confirm-delete dialog, pick-new-default dialog).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/utils/box_shadow.dart';
import '../../l10n/app_localizations.dart';
import '../shopping_list/widgets/shopping_list_card.dart';
import 'accounts_controller.dart';
import 'accounts_providers.dart';
import 'accounts_state.dart';
import 'widgets/account_tile.dart';
import 'widgets/account_type_display.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts_fab',
        onPressed: () => context.go('/accounts/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.accountsAddCta),
      ),
      body: SlidableAutoCloseBehavior(
        child: switch (state) {
          AsyncData<AccountsState>(value: final AccountsData data) =>
            _AccountsBody(data: data),
          AsyncData<AccountsState>(value: AccountsError()) ||
          AsyncError() => const _ErrorSurface(),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _AccountsBody extends ConsumerWidget {
  const _AccountsBody({required this.data});

  final AccountsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    const cardPadding = EdgeInsets.symmetric(
      horizontal: homePageCardHorizontalPadding - 16,
    );
    final allActiveIds = data.active
        .map((r) => r.account.id)
        .toList(growable: false);

    return CustomScrollView(
      slivers: [
        // Shopping list card is always FIRST — visible even when no accounts.
        SliverPadding(
          padding: cardPadding.copyWith(top: 16),
          sliver: const SliverToBoxAdapter(child: ShoppingListCard()),
        ),

        if (data.active.isNotEmpty)
          SliverPadding(
            padding: cardPadding.copyWith(top: 16),
            sliver: SliverToBoxAdapter(
              child: _AccountListCard(
                accounts: data.active,
                defaultAccountId: data.defaultAccountId,
                locale: locale,
                allActiveIds: allActiveIds,
              ),
            ),
          ),

        if (data.active.isEmpty)
          SliverPadding(
            padding: cardPadding.copyWith(top: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.accountsEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.accountsEmptyCta),
                      onPressed: () => context.go('/accounts/new'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (data.archived.isNotEmpty)
          SliverPadding(
            padding: cardPadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Text(
                      l10n.accountsArchivedSectionLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _AccountListCard(
                    accounts: data.archived,
                    defaultAccountId: null,
                    locale: locale,
                    allActiveIds: allActiveIds,
                  ),
                ],
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _AccountTileWithLookups extends ConsumerWidget {
  const _AccountTileWithLookups({
    required this.view,
    required this.isDefault,
    required this.locale,
    required this.allActiveIds,
  });

  final AccountWithBalance view;
  final bool isDefault;
  final String locale;
  final List<int> allActiveIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final typeAsync = ref.watch(
      accountTypeByIdProvider(view.account.accountTypeId),
    );
    final typeLabel = typeAsync.maybeWhen(
      data: (t) => t == null ? '' : accountTypeDisplayName(t, l10n),
      orElse: () => '',
    );
    return AccountTile(
      view: view,
      isDefault: isDefault,
      locale: locale,
      accountTypeLabel: typeLabel,
      onTap: () => context.go('/accounts/${view.account.id}'),
      onSetDefault: () => _onSetDefault(context, ref, view.account.id),
      onArchive: () => _onArchive(context, ref, view.account.id),
      onDelete: () => _onDelete(context, ref, view.account.id),
      onArchiveBlocked: () => _onArchiveBlocked(context),
    );
  }

  Future<void> _onSetDefault(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).setDefault(id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
    }
  }

  Future<void> _onArchive(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).archive(id);
    } on AccountsOperationException catch (e) {
      if (e.kind == AccountsOperationError.lastActiveAccount) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountsArchiveLastActiveBlocked)),
        );
        return;
      }
      if (e.kind == AccountsOperationError.defaultAccount) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.accountsDeleteDefaultBlockedTitle),
            content: Text(l10n.accountsDeleteDefaultBlockedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.accountsArchiveUndoSnackbar),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () => unawaited(
            ref.read(accountsControllerProvider.notifier).unarchive(id),
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountsDeleteConfirmTitle),
        content: Text(l10n.accountsDeleteConfirmBody),
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
      await ref.read(accountsControllerProvider.notifier).delete(id);
    } on AccountsOperationException catch (e) {
      if (e.kind == AccountsOperationError.defaultAccount) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.accountsDeleteDefaultBlockedTitle),
            content: Text(l10n.accountsDeleteDefaultBlockedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSnackbarGeneric)),
      );
    }
  }

  void _onArchiveBlocked(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.accountsArchiveLastActiveBlocked)),
    );
  }
}

class _AccountListCard extends StatelessWidget {
  const _AccountListCard({
    required this.accounts,
    required this.defaultAccountId,
    required this.locale,
    required this.allActiveIds,
  });

  final List<AccountWithBalance> accounts;
  final int? defaultAccountId;
  final String locale;
  final List<int> allActiveIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(homePageCardBorderRadius),
        boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final view in accounts)
            _AccountTileWithLookups(
              view: view,
              isDefault: defaultAccountId == view.account.id,
              locale: locale,
              allActiveIds: allActiveIds,
            ),
        ],
      ),
    );
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
