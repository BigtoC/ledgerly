// Read-only transaction row for search results — see spec
// § Transaction tiles.
//
// Search results are a *view* over transactions, not an action surface.
// Mutations from a filtered view would silently change the result set
// under the user, so this widget is intentionally presentational only —
// no tap, no swipe, no overflow menu.

import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';

class TransactionSearchRow extends StatelessWidget {
  const TransactionSearchRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
  });

  final Transaction transaction;
  final Category? category;
  final Account? account;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final acc = account;

    final color = cat != null ? colorForIndex(cat.color) : theme.disabledColor;
    final icon = cat != null ? iconForKey(cat.icon) : Icons.help_outline;
    final isIncome = cat?.type == CategoryType.income;

    final amountText = switch (cat?.type) {
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

    return ListTile(
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
        amountText,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
