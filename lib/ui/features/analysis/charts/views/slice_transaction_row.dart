// One transaction row in the Analysis transactions card (the slice
// drill-down) — Main.dc.html lines 214-224. Search results keep
// `TransactionSearchRow`.
//
// Title: memo, falling back to the category name. Subtitle:
// "MMM d · account", plus " · <booked amount>" when the row shows a
// converted amount. Tap → edit (caller); action-only swipe delete (caller
// owns the undo window).

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/account.dart';
import '../../../../../domain/models/category.dart';
import '../../../../../domain/models/transaction.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../../../categories/views/category_display.dart';

class SliceTransactionRow extends StatelessWidget {
  const SliceTransactionRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    required this.onTap,
    required this.onDelete,
    this.convertedAmount,
  });

  final Transaction transaction;
  final Category? category;
  final Account? account;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Pre-formatted, signed amount in the slice currency for a
  /// foreign-currency row. When set it is the row's amount and the booked
  /// amount moves to the subtitle.
  final String? convertedAmount;

  // Building a DateFormat parses the locale pattern; rows build often.
  static final Map<String, DateFormat> _monthDayFormats = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AnalysisColors.of(context);
    final cat = category;
    final isIncome = cat?.type == CategoryType.income;

    final bookedAmount = switch (cat?.type) {
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
    final title = memo != null && memo.isNotEmpty
        ? memo
        : (cat == null ? '' : categoryDisplayName(cat, l10n));
    final date = _monthDayFormats
        .putIfAbsent(locale, () => DateFormat.MMMd(locale))
        .format(transaction.date);
    final subtitle = [
      date,
      ?account?.name,
      if (convertedAmount != null) bookedAmount,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Slidable(
        key: ValueKey<int>(transaction.id),
        groupTag: 'analysis_drilldown',
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
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: analysisText(
                          size: 15,
                          lineHeight: 20,
                          color: colors.fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: analysisText(
                          size: 13,
                          lineHeight: 18,
                          color: colors.fg2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  convertedAmount ?? bookedAmount,
                  maxLines: 1,
                  softWrap: false,
                  style: analysisText(
                    size: 15,
                    lineHeight: 20,
                    weight: FontWeight.w500,
                    color: isIncome ? colors.incText : colors.expText,
                    tabular: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
