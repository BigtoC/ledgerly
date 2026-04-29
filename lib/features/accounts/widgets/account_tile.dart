// Accounts list row (plan §4, §7).
//
// Renders: icon + color badge, account name, localized account-type
// chip, balance formatted in the account's native currency, and a
// default badge when applicable. Swipe:
//
//   - Leading action: "Set as default" — shown only when the row is
//     not already the default and is not archived.
//   - Trailing action: Archive / Delete / Archive-disabled per the
//     controller-computed affordance. Archived rows have no trailing
//     swipe action.
//
// Accessibility-mirror buttons live in the tile trailing row so tests
// and keyboard users can reach each action without a gesture.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../accounts_providers.dart';
import '../accounts_state.dart';

class AccountTile extends ConsumerWidget {
  const AccountTile({
    super.key,
    required this.view,
    required this.isDefault,
    required this.locale,
    required this.accountTypeLabel,
    required this.onTap,
    required this.onSetDefault,
    required this.onArchive,
    required this.onDelete,
    required this.onArchiveBlocked,
  });

  final AccountWithBalance view;
  final bool isDefault;
  final String locale;
  final String accountTypeLabel;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onArchiveBlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final a = view.account;
    final color = colorForIndex(a.color ?? 0);

    // Resolve currency metadata for balance formatting.
    final currenciesAsync = ref.watch(currenciesByCodeProvider);
    final currenciesByCode = currenciesAsync.maybeWhen(
      data: (m) => m,
      orElse: () => <String, Currency>{},
    );

    final startActions = <Widget>[
      if (!a.isArchived && !isDefault)
        SlidableAction(
          onPressed: (_) => onSetDefault(),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          icon: Icons.star_outline,
          label: l10n.accountsSetDefaultAction,
        ),
    ];

    final endActions = <Widget>[
      if (!a.isArchived)
        switch (view.affordance) {
          AccountRowAffordance.archive => SlidableAction(
            onPressed: (_) => onArchive(),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            icon: Icons.archive_outlined,
            label: l10n.accountsArchiveAction,
          ),
          AccountRowAffordance.delete => SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            label: l10n.accountsDeleteAction,
          ),
          AccountRowAffordance.archiveBlocked => SlidableAction(
            onPressed: (_) => onArchiveBlocked(),
            backgroundColor: Theme.of(
              context,
            ).disabledColor.withValues(alpha: 0.24),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            icon: Icons.archive_outlined,
            label: l10n.accountsArchiveAction,
          ),
        },
    ];

    return Slidable(
      key: ValueKey<int>(a.id),
      groupTag: 'accounts',
      startActionPane: startActions.isEmpty
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.3,
              children: startActions,
            ),
      endActionPane: endActions.isEmpty
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.3,
              children: endActions,
            ),
      child: ListTile(
        onTap: onTap,
        // Use three-line mode when the balance column has more than one
        // group so the tile grows vertically to accommodate multi-line
        // trailing content at any text scale.
        isThreeLine: view.balancesByCurrency.length > 1,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(iconForKey(a.icon), color: color, size: 22),
        ),
        title: Row(
          children: [
            Flexible(child: Text(a.name, overflow: TextOverflow.ellipsis)),
            if (isDefault) ...[
              const SizedBox(width: 8),
              _DefaultBadge(label: l10n.accountsDefaultBadge),
            ],
          ],
        ),
        subtitle: _buildSubtitle(
          context,
          accountTypeLabel,
          view.balancesByCurrency,
          currenciesByCode,
          l10n,
        ),
        trailing: _TrailingActions(
          view: view,
          isDefault: isDefault,
          onSetDefault: onSetDefault,
          onArchive: onArchive,
          onDelete: onDelete,
          onArchiveBlocked: onArchiveBlocked,
        ),
      ),
    );
  }

  /// Builds the subtitle area: account type label + grouped balance lines.
  ///
  /// Renders at most 2 currency groups as individual lines, then an
  /// `+N more` indicator when there are more than 2 groups. Native
  /// currency (the account's own currency) is always listed first;
  /// remaining groups are sorted alphabetically by code for
  /// deterministic display.
  Widget _buildSubtitle(
    BuildContext context,
    String accountTypeLabel,
    Map<String, int> balancesByCurrency,
    Map<String, Currency> currenciesByCode,
    AppLocalizations l10n,
  ) {
    if (balancesByCurrency.isEmpty) {
      return Text(accountTypeLabel);
    }

    // Sort: native currency first, then alphabetical by code.
    final nativeCode = view.account.currency.code.toUpperCase();
    final sortedEntries = balancesByCurrency.entries.toList(growable: false)
      ..sort((a, b) {
        final aIsNative = a.key == nativeCode;
        final bIsNative = b.key == nativeCode;
        if (aIsNative && !bIsNative) return -1;
        if (!aIsNative && bIsNative) return 1;
        return a.key.compareTo(b.key);
      });

    final displayCount = sortedEntries.length > 2 ? 2 : sortedEntries.length;
    final overflowCount = sortedEntries.length - displayCount;

    final lines = <Widget>[Text(accountTypeLabel)];
    for (var i = 0; i < displayCount; i++) {
      final code = sortedEntries[i].key;
      final amount = sortedEntries[i].value;
      final currency =
          currenciesByCode[code] ?? Currency(code: code, decimals: 2);
      final formatted = MoneyFormatter.format(
        amountMinorUnits: amount,
        currency: currency,
        locale: locale,
      );
      lines.add(Text('$code: $formatted'));
    }
    if (overflowCount > 0) {
      lines.add(
        Text(
          l10n.accountsBalanceMore(overflowCount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lines,
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

class _TrailingActions extends StatelessWidget {
  const _TrailingActions({
    required this.view,
    required this.isDefault,
    required this.onSetDefault,
    required this.onArchive,
    required this.onDelete,
    required this.onArchiveBlocked,
  });

  final AccountWithBalance view;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onArchiveBlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = view.account;
    if (a.isArchived) return const SizedBox.shrink();
    return PopupMenuButton<_RowAction>(
      key: ValueKey('accountTile:${a.id}:menu'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _RowAction.setDefault:
            onSetDefault();
          case _RowAction.archive:
            if (view.affordance == AccountRowAffordance.archiveBlocked) {
              onArchiveBlocked();
            } else {
              onArchive();
            }
          case _RowAction.delete:
            onDelete();
        }
      },
      itemBuilder: (ctx) => [
        if (!isDefault)
          PopupMenuItem(
            value: _RowAction.setDefault,
            child: Text(l10n.accountsSetDefaultAction),
          ),
        switch (view.affordance) {
          AccountRowAffordance.delete => PopupMenuItem(
            value: _RowAction.delete,
            child: Text(l10n.accountsDeleteAction),
          ),
          _ => PopupMenuItem(
            value: _RowAction.archive,
            enabled: view.affordance != AccountRowAffordance.archiveBlocked,
            child: Text(l10n.accountsArchiveAction),
          ),
        },
      ],
    );
  }
}

enum _RowAction { setDefault, archive, delete }
