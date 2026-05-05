import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/utils/box_shadow.dart';
import '../../../l10n/app_localizations.dart';
import '../accounts_controller.dart';
import '../accounts_providers.dart';
import '../accounts_state.dart';
import 'account_tile.dart';
import 'account_type_display.dart';

class ManageAccountsBody extends ConsumerWidget {
  const ManageAccountsBody({super.key, required this.data});

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

    return SlidableAutoCloseBehavior(
      child: CustomScrollView(
        slivers: [
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
          if (data.active.isEmpty && data.archived.isEmpty)
            SliverPadding(
              padding: cardPadding.copyWith(top: 16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.manageAccountsBodyEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
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
      onTap: () => context.push('/settings/manage-accounts/${view.account.id}'),
      onSetDefault: () =>
          _onSetDefault(context, ref, view.account.id, view.account.name),
      onArchive: () => _onArchive(context, ref, view.account.id),
      onDelete: () => _onDelete(context, ref, view.account.id),
      onArchiveBlocked: () => _onArchiveBlocked(context),
    );
  }

  Future<void> _onSetDefault(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).setDefault(id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.manageAccountsSetDefaultSuccess(name))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.manageAccountsSetDefaultFailed)),
          );
      }
    }
  }

  Future<void> _onArchive(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).archive(id);
    } on AccountsOperationException catch (e) {
      if (e.kind == AccountsOperationError.lastActiveAccount) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
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
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
      return;
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
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
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  void _onArchiveBlocked(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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
