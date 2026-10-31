// Transaction row for search results and chart drill-down — see specs:
//   - `docs/superpowers/specs/2026-05-09-transaction-search-design.md`
//     § Transaction tiles (dismissible Slidable + 4 s undo).
//   - `docs/superpowers/specs/2026-05-21-chart-slice-drilldown-design.md`
//     § Items list (action-only delete; converted/original amount split).
//
// Layout: icon, title, "account • memo" subtitle, signed amount with
// type-driven color.
// Primary tap → edit (delegates to caller). Swipe → delete with a 4 s
// undo window (delegates to caller; the owning controller owns the
// optimistic-hide + commit timer).

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';

/// Swipe-delete affordance variants used by `TransactionSearchRow`.
///
/// - [dismissible]: the existing search-result behavior — the user can
///   fling all the way to delete instantly, OR tap the trailing Delete
///   action. Owning controller still owns the 4 s undo.
/// - [actionOnly]: the chart drill-down behavior — the user MUST tap the
///   trailing Delete action (no full-fling auto-dismiss). Removes the
///   accidental-delete failure mode when the row is part of a dense
///   stacked list below a live chart surface.
enum TransactionSearchRowDeleteMode { dismissible, actionOnly }

class TransactionSearchRow extends StatelessWidget {
  const TransactionSearchRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    this.onTap,
    this.onDelete,
    this.deleteMode = TransactionSearchRowDeleteMode.dismissible,
    this.convertedAmount,
    this.originalAmountLabel,
  });

  final Transaction transaction;
  final Category? category;
  final Account? account;
  final String locale;

  /// Primary tap. When null the row renders without an `onTap` (read-only).
  final VoidCallback? onTap;

  /// End-swipe gesture. When null the swipe affordance is omitted entirely.
  final VoidCallback? onDelete;

  /// Selects between full-dismissible (default) and action-only delete UX.
  final TransactionSearchRowDeleteMode deleteMode;

  /// Pre-formatted converted amount (e.g. FX-converted display-currency
  /// value). When non-null this string replaces the primary amount and
  /// the booked amount drops to a labeled secondary row.
  final String? convertedAmount;

  /// Label shown above the secondary booked amount when [convertedAmount]
  /// is non-null. Typically `l10n.analysisOriginalAmount`.
  final String? originalAmountLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final acc = account;

    final color = cat != null ? colorForIndex(cat.color) : theme.disabledColor;
    final icon = cat != null ? iconForKey(cat.icon) : Icons.help_outline;
    final isIncome = cat?.type == CategoryType.income;

    final bookedAmountText = switch (cat?.type) {
      CategoryType.income => MoneyFormatter.formatSigned(
        amountMinorUnits: transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
      CategoryType.expense => MoneyFormatter.formatSigned(
        amountMinorUnits: -transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
      null => MoneyFormatter.format(
        amountMinorUnits: transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
    };

    final memo = transaction.memo;
    final hasConverted = convertedAmount != null && originalAmountLabel != null;

    final trailing = hasConverted
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                convertedAmount!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isIncome
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                originalAmountLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                bookedAmountText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          )
        : Text(
            bookedAmountText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isIncome
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          );

    final tile = ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        cat == null ? '' : categoryDisplayName(cat, l10n),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        memo == null || memo.isEmpty
            ? (acc?.name ?? '')
            : '${acc?.name ?? ''} • $memo',
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing,
    );

    if (onDelete == null) return tile;

    return Slidable(
      key: ValueKey<int>(transaction.id),
      groupTag: 'analysis_search',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        dismissible: deleteMode == TransactionSearchRowDeleteMode.dismissible
            ? DismissiblePane(onDismissed: onDelete!)
            : null,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete!(),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            label: l10n.commonDelete,
          ),
        ],
      ),
      child: tile,
    );
  }
}
