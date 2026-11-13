// Transaction row for search results — see spec
// `docs/superpowers/specs/2026-05-09-transaction-search-design.md`
// § Transaction tiles (dismissible Slidable + 4 s undo).
//
// Layout: icon, title, "account • memo" subtitle, signed amount with
// type-driven color.
// Primary tap → edit (delegates to caller). Swipe → delete with a 4 s
// undo window (delegates to caller; the owning controller owns the
// optimistic-hide + commit timer).

import 'package:material_ui/material_ui.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/icon_registry.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/account.dart';
import '../../../../../domain/models/category.dart';
import '../../../../../domain/models/transaction.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../categories/views/category_display.dart';

class const TransactionSearchRow({
  super.key,
  required final Transaction transaction,
  required final Category? category,
  required final Account? account,
  required final String locale,

  /// Primary tap.
  required final VoidCallback onTap,

  /// End-swipe delete.
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final acc = account;

    final color = cat != null ? colorForIndex(cat.color) : theme.disabledColor;
    final icon = cat != null ? iconForKey(cat.icon) : Icons.help_outline;
    final isIncome = cat?.type == CategoryType.income;

    final bookedAmountText = MoneyFormatter.formatForCategoryType(
      amountMinorUnits: transaction.amountMinorUnits,
      currency: transaction.currency,
      locale: locale,
      categoryType: cat?.type,
    );

    final memo = transaction.memo;
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
      trailing: Text(
        bookedAmountText,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Slidable(
      key: ValueKey<int>(transaction.id),
      groupTag: 'analysis_search',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        dismissible: DismissiblePane(onDismissed: onDelete),
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
      child: tile,
    );
  }
}
