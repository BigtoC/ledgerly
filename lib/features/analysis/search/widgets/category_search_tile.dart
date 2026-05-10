// Level 1 result card — see spec § CategorySearchTile widget.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/category.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';
import '../analysis_state.dart';

class CategorySearchTile extends StatelessWidget {
  const CategorySearchTile({
    super.key,
    required this.result,
    required this.query,
    required this.locale,
  });

  final CategorySearchResult result;
  final String query;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = result.category;
    final color = colorForIndex(cat.color);
    final icon = iconForKey(cat.icon);
    final isIncome = cat.type == CategoryType.income;
    final signedAmount = isIncome
        ? result.totalAmountMinorUnits
        : -result.totalAmountMinorUnits;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        categoryDisplayName(cat, l10n),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(l10n.analysisTransactionCount(result.transactionCount)),
      trailing: Text(
        MoneyFormatter.formatSigned(
          amountMinorUnits: signedAmount,
          currency: result.currency,
          locale: locale,
        ),
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => context.push(
        Uri(
          path: '/analysis/search/${cat.id}',
          queryParameters: {'q': query, 'c': result.currency.code},
        ).toString(),
      ),
    );
  }
}
