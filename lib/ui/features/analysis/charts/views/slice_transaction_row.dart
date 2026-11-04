// One transaction row in the Analysis transactions card (the slice
// drill-down) — Main.dc.html lines 214-224. Search results keep
// `TransactionSearchRow`.
//
// Title: memo, falling back to the category name. Subtitle:
// "MMM d · account", plus " · <booked amount>" when the row shows a
// converted amount. Tap → edit (caller); action-only swipe delete (caller
// owns the undo window).

import 'dart:math' as math;

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

    final bookedAmount = MoneyFormatter.formatForCategoryType(
      amountMinorUnits: transaction.amountMinorUnits,
      currency: transaction.currency,
      locale: locale,
      categoryType: cat?.type,
    );

    final memo = transaction.memo;
    final title = memo != null && memo.isNotEmpty
        ? memo
        : (cat == null ? '' : categoryDisplayName(cat, l10n));
    final date = _monthDayFormats
        .putIfAbsent(locale, () => DateFormat.MMMd(locale))
        .format(transaction.date);
    final meta = [date, ?account?.name].join(' · ');
    final subtitleStyle = analysisText(
      size: 13,
      lineHeight: 18,
      color: colors.fg2,
    );
    final bookedSuffix = ' · $bookedAmount';
    final metaText = Text(
      meta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: subtitleStyle,
    );

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
        // A bare InkWell adds only the tap action; the button role, the
        // enabled state and the always-false selected state keep the
        // ListTile row's semantics (plan D16).
        child: Semantics(
          button: true,
          selected: false,
          enabled: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _LabelThenAmount(
                gap: 12,
                expandLabel: true,
                // The booked amount in the subtitle needs room too: the
                // main amount keeps its size while that still fits beside
                // it ("date · account" ellipsizes first), then the two
                // share the line.
                amountShare: convertedAmount == null ? 1 : 0.5,
                labelReserve: convertedAmount == null
                    ? 0
                    : _naturalWidth(context, bookedSuffix, subtitleStyle),
                label: Column(
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
                    if (convertedAmount == null)
                      metaText
                    else
                      _LabelThenAmount(
                        label: metaText,
                        amount: Text(
                          bookedSuffix,
                          maxLines: 1,
                          softWrap: false,
                          style: subtitleStyle,
                        ),
                      ),
                  ],
                ),
                amount: Text(
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The width [text] takes in one line, laid out as a [Text] in [context]
  /// would lay it out.
  static double _naturalWidth(
    BuildContext context,
    String text,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// [label], an optional [gap], then [amount] on one line. The amount keeps
/// its natural size and the label gives way (ellipsizes) first; the amount
/// scales down only when it is wider than both its [amountShare] of the
/// line and the line less [labelReserve], so it is never cut off (plan D2).
class _LabelThenAmount extends StatelessWidget {
  const _LabelThenAmount({
    required this.label,
    required this.amount,
    this.gap = 0,
    this.expandLabel = false,
    this.amountShare = 1,
    this.labelReserve = 0,
  });

  final Widget label;
  final Widget amount;
  final double gap;

  /// Whether the label fills the line, pushing the amount to the end.
  final bool expandLabel;

  /// The share of the line, after [gap], the amount may always take
  /// before it scales down.
  final double amountShare;

  /// The width the label must keep. The amount may take the rest of the
  /// line, beyond its [amountShare], before it scales down.
  final double labelReserve;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final line = constraints.maxWidth - gap;
        return Row(
          children: [
            if (expandLabel) Expanded(child: label) else Flexible(child: label),
            if (gap > 0) SizedBox(width: gap),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(
                  0,
                  math.max(line * amountShare, line - labelReserve),
                ),
              ),
              child: FittedBox(fit: BoxFit.scaleDown, child: amount),
            ),
          ],
        );
      },
    );
  }
}
