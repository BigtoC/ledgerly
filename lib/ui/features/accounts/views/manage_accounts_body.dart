// Caller is responsible for resolving data state; this widget renders only AccountsData.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../app/providers/default_currency_provider.dart';
import '../../../../app/providers/exchange_rates_provider.dart';
import '../../../../core/constants.dart';
import '../../../../core/utils/box_shadow.dart';
import '../../../../l10n/app_localizations.dart';
import '../view_models/accounts_controller.dart';
import '../view_models/accounts_providers.dart';
import '../view_models/accounts_state.dart';
import 'account_tile.dart';
import 'account_type_display.dart';

@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class ManageAccountsBody extends StatelessWidget {
  const ManageAccountsBody({super.key, required this.data});

  final AccountsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    const cardPadding = EdgeInsets.symmetric(
      horizontal: homePageCardHorizontalPadding - 16,
    );

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

@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class _AccountTileWithLookups extends ConsumerWidget {
  const _AccountTileWithLookups({
    required this.view,
    required this.isDefault,
    required this.locale,
  });

  final AccountWithBalance view;
  final bool isDefault;
  final String locale;

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
    final outcome = await ref
        .read(accountsControllerProvider.notifier)
        .setDefault(id);
    if (!context.mounted) return;
    final message = switch (outcome) {
      SetDefaultAccountOk() => l10n.manageAccountsSetDefaultSuccess(name),
      SetDefaultAccountFailed() => l10n.manageAccountsSetDefaultFailed,
    };
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onArchive(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // The Undo action can run after this tile is gone (the row moved to
    // the Archived card, or the sheet closed), so it must not use `ref`.
    final container = ProviderScope.containerOf(context, listen: false);
    final outcome = await ref
        .read(accountsControllerProvider.notifier)
        .archive(id);
    switch (outcome) {
      case ArchiveAccountOk():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.accountsArchiveUndoSnackbar),
              action: SnackBarAction(
                label: l10n.commonUndo,
                onPressed: () =>
                    unawaited(_undoArchive(container, messenger, l10n, id)),
              ),
            ),
          );
      case ArchiveAccountIsDefault():
        if (!context.mounted) return;
        await _showDefaultBlockedDialog(context, l10n);
      case ArchiveAccountLastActive():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.accountsArchiveLastActiveBlocked)),
          );
      case ArchiveAccountHasActiveRecurringRule():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.accountsArchiveRecurringRuleError)),
          );
      case ArchiveAccountFailed():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  /// Uses only what [_onArchive] captured while the tile was mounted.
  /// `unarchive` never throws, so this future cannot fail.
  static Future<void> _undoArchive(
    ProviderContainer container,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    int id,
  ) async {
    final outcome = await container
        .read(accountsControllerProvider.notifier)
        .unarchive(id);
    switch (outcome) {
      case UnarchiveAccountOk():
        break;
      case UnarchiveAccountFailed():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
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
    final outcome = await ref
        .read(accountsControllerProvider.notifier)
        .delete(id);
    switch (outcome) {
      case DeleteAccountOk():
        break;
      case DeleteAccountIsDefault():
        if (!context.mounted) return;
        await _showDefaultBlockedDialog(context, l10n);
      case DeleteAccountInUse():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.accountsDeleteInUseError)),
          );
      case DeleteAccountFailed():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  Future<void> _showDefaultBlockedDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<void>(
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

@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class _AccountListCard extends StatelessWidget {
  const _AccountListCard({
    required this.accounts,
    required this.defaultAccountId,
    required this.locale,
  });

  final List<AccountWithBalance> accounts;
  final int? defaultAccountId;
  final String locale;

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
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final view in accounts)
              _AccountTileWithLookups(
                view: view,
                isDefault: defaultAccountId == view.account.id,
                locale: locale,
              ),
          ],
        ),
      ),
    );
  }
}
