// Home transaction row — Wave 3 §4.1, §9.
//
// Renders: category icon chip, a title (the memo, or the category name
// when the memo is empty or blank) and the amount with `+`/`-` prefix in the
// row's native currency. Tap → edit; deleting happens from the edit
// screen. The row claims no horizontal drag, so a swipe over it reaches
// Home's day-switch gesture.
//
// Phase 2: when the transaction's currency differs from the user's
// default currency, a secondary muted line shows the approximate
// converted amount (`≈ $X.XX`). The `≈` glyph is read aloud by screen
// readers as the localized "approximately" prefix via Semantics.
//
// Archived category rows still render with their archived metadata so
// historical rows stay readable (Wave 3 §2 requirements).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import '../home_providers.dart';

@Dependencies([exchangeRates])
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.locale,
    required this.defaultCurrency,
    required this.onTap,
  });

  final Transaction transaction;

  /// Resolved category — null when the metadata lookup is still loading
  /// or the row references a deleted category. Tile renders a neutral
  /// fallback in that case so the list never blank-rows.
  final Category? category;

  final String locale;

  /// ISO 4217 code of the user's preferred default currency. Provided
  /// synchronously by the parent so the tile does not flicker through a
  /// `'USD'` fallback on cold start.
  final String defaultCurrency;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;

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
          ref.watch(exchangeRatesProvider).value ?? const <String, int>{};
      final rateScaledE9 = ratesMap['${txCurrency.code}→$defaultCurrency'];
      if (rateScaledE9 != null) {
        final currenciesByCode =
            ref.watch(homeCurrenciesByCodeProvider).value ??
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
    final title = memo != null && memo.trim().isNotEmpty
        ? memo
        : (cat == null ? '' : categoryDisplayName(cat, l10n));

    // A plain Row rather than a ListTile: a one-line ListTile sizes itself
    // from the title alone, so the two-line amount column would spill into
    // the next row at large text scales. Metrics follow the M3 ListTile.
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
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
            ],
          ),
        ),
      ),
    );
  }
}
