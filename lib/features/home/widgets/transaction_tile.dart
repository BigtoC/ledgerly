// Home transaction row — Wave 3 §4.1, §9.
//
// Renders: category icon chip, category name, amount with `+`/`-`
// prefix in the row's native currency, optional memo preview, account
// name tag, time. Primary tap → edit. Overflow → Edit / Duplicate /
// Delete. Swipe-to-delete is the destructive gesture (handled by
// `flutter_slidable`); swipe and overflow share `onDelete`.
//
// Archived category / account rows still render with their archived
// metadata so historical rows stay readable (Wave 3 §2 requirements).

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Transaction transaction;

  /// Resolved category — null when the metadata lookup is still loading
  /// or the row references a deleted category. Tile renders a neutral
  /// fallback in that case so the list never blank-rows.
  final Category? category;

  /// Resolved account — same null fallback handling as [category].
  final Account? account;

  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final acc = account;

    final color = cat != null ? colorForIndex(cat.color) : theme.disabledColor;
    final icon = cat != null ? iconForKey(cat.icon) : Icons.help_outline;

    final isIncome = cat?.type == CategoryType.income;
    final signedAmount = isIncome
        ? transaction.amountMinorUnits
        : -transaction.amountMinorUnits;
    final amountText = MoneyFormatter.formatSigned(
      amountMinorUnits: signedAmount,
      currency: transaction.currency,
      locale: locale,
    );

    final timeText = DateFormat.Hm(locale).format(transaction.date);
    final memo = transaction.memo;

    return Slidable(
      key: ValueKey<int>(transaction.id),
      groupTag: 'home',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            label: l10n.commonDelete,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cat == null ? '' : categoryDisplayName(cat, l10n),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              amountText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isIncome
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                memo == null || memo.isEmpty
                    ? (acc?.name ?? '')
                    : '${acc?.name ?? ''} • $memo',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            Text(timeText, style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: PopupMenuButton<_RowAction>(
          key: ValueKey('homeTile:${transaction.id}:menu'),
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _RowAction.edit:
                onTap();
              case _RowAction.duplicate:
                onDuplicate();
              case _RowAction.delete:
                onDelete();
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(value: _RowAction.edit, child: Text(l10n.commonEdit)),
            PopupMenuItem(
              value: _RowAction.duplicate,
              child: Text(l10n.homeDuplicateAction),
            ),
            PopupMenuItem(
              value: _RowAction.delete,
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RowAction { edit, duplicate, delete }
