// Home transaction row — Wave 3 §4.1, §9.
//
// Renders: category icon chip, category name, amount with `+`/`-`
// prefix in the row's native currency, optional memo preview, account
// name tag, time. Primary tap → edit. Overflow → Edit / Duplicate /
// Delete. Swipe-to-delete is the destructive gesture (handled by
// `flutter_slidable`); swipe and overflow share `onDelete`.
//
// Phase 2: when the transaction's currency differs from the user's
// default currency, a secondary muted line shows the approximate
// converted amount (`≈ $X.XX`). The `≈` glyph is read aloud by screen
// readers as the localized "approximately" prefix via Semantics.
//
// Archived category / account rows still render with their archived
// metadata so historical rows stay readable (Wave 3 §2 requirements).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import '../home_providers.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    required this.defaultCurrency,
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

  /// ISO 4217 code of the user's preferred default currency. Provided
  /// synchronously by the parent so the tile does not flicker through a
  /// `'USD'` fallback on cold start.
  final String defaultCurrency;

  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Convert to default currency when the transaction is in a foreign
    // currency and a rate is available. Otherwise render only the
    // primary line.
    String? convertedText;
    final txCurrency = transaction.currency;
    if (txCurrency.code != defaultCurrency) {
      final ratesMap =
          ref.watch(exchangeRatesProvider).valueOrNull ?? const <String, int>{};
      final rateScaledE9 = ratesMap['${txCurrency.code}→$defaultCurrency'];
      if (rateScaledE9 != null) {
        final currenciesByCode =
            ref.watch(homeCurrenciesByCodeProvider).valueOrNull ??
            const <String, Currency>{};
        final toCurrency =
            currenciesByCode[defaultCurrency] ??
            Currency(
              code: defaultCurrency,
              decimals: 2,
              symbol: defaultCurrency,
            );
        final convertedMinorUnits = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: transaction.amountMinorUnits,
          rateScaledE9: rateScaledE9,
          fromDecimals: txCurrency.decimals,
          toDecimals: toCurrency.decimals,
        );
        final signedConverted = isIncome
            ? convertedMinorUnits
            : -convertedMinorUnits;
        final formatted = MoneyFormatter.formatSigned(
          amountMinorUnits: signedConverted,
          currency: toCurrency,
          locale: locale,
        );
        convertedText = '≈ $formatted';
      }
    }

    final memo = transaction.memo;

    return Slidable(
      key: ValueKey<int>(transaction.id),
      groupTag: 'home',
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
      child: ListTile(
        onTap: onTap,
        isThreeLine: convertedText != null,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amountText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isIncome
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (convertedText != null)
                  Semantics(
                    label:
                        '${l10n.approximatelyPrefix} '
                        '${convertedText.substring(2)}',
                    excludeSemantics: true,
                    child: Text(
                      convertedText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
            PopupMenuButton<_RowAction>(
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
                PopupMenuItem(
                  value: _RowAction.edit,
                  child: Text(l10n.homeEditAction),
                ),
                PopupMenuItem(
                  value: _RowAction.duplicate,
                  child: Semantics(
                    button: true,
                    label: l10n.homeDuplicateAction,
                    child: Text(l10n.homeDuplicateAction),
                  ),
                ),
                PopupMenuItem(
                  value: _RowAction.delete,
                  child: Semantics(
                    button: true,
                    label: l10n.commonDelete,
                    child: Text(l10n.commonDelete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _RowAction { edit, duplicate, delete }
