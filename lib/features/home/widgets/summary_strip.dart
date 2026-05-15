// Home summary strip — Wave 3 §4.1, §7 (extended with multi-currency
// conversion in Phase 2).
//
// When exchange rates are available for every in-use currency, the strip
// renders a single unified total in the user's default currency
// (today's expense / income, month-to-date net). When rates are missing
// for some currencies, the strip shows the unified total plus a separator
// labelled "Unconverted" plus a fallback per-currency group for each
// missing-rate currency, in stable ascending currency-code order.
//
// All values are integer minor units, scaled at the UI boundary by
// `MoneyFormatter` per Wave 0 §2.7 / PRD Money Storage Policy.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledgerly/core/utils/box_shadow.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../core/constants.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../home_state.dart';

class SummaryStrip extends ConsumerWidget {
  const SummaryStrip({
    super.key,
    required this.todayTotalsByCurrency,
    required this.monthNetByCurrency,
    required this.currenciesByCode,
    required this.locale,
    required this.defaultCurrency,
    this.showJumpToToday = false,
    this.onJumpToToday,
  });

  /// Selected-day's per-currency expense/income split.
  final DailyTotals todayTotalsByCurrency;

  /// Month-to-date net per currency for the selected day's month.
  final Map<String, int> monthNetByCurrency;

  /// Resolves a currency code to its metadata so [MoneyFormatter] can
  /// render `decimals` correctly. Codes missing from this map fall back
  /// to a 2-decimal placeholder so a transient gap (e.g. metadata still
  /// loading) does not crash the strip.
  final Map<String, Currency> currenciesByCode;

  final String locale;

  /// ISO 4217 code of the user's preferred default currency. Provided
  /// synchronously by the parent so the strip does not flicker through a
  /// `'USD'` fallback on cold start.
  final String defaultCurrency;

  /// When true, renders a "Jump to today" button at the top of the strip.
  final bool showJumpToToday;

  /// Called when the "Jump to today" button is tapped.
  final VoidCallback? onJumpToToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final ratesMap =
        ref.watch(exchangeRatesProvider).valueOrNull ?? const <String, int>{};

    final toCurrency =
        currenciesByCode[defaultCurrency] ??
        Currency(
          code: defaultCurrency,
          decimals: 2,
          symbol: defaultCurrency,
        );

    int convertedExpense = 0;
    int convertedIncome = 0;
    int convertedMonthNet = 0;
    final missingRatesFor = <String>{};

    int? convert(int amount, String fromCode) {
      if (fromCode == defaultCurrency) return amount;
      final rateScaledE9 = ratesMap['$fromCode→$defaultCurrency'];
      if (rateScaledE9 == null) return null;
      final fromCurrency =
          currenciesByCode[fromCode] ??
          Currency(code: fromCode, decimals: 2, symbol: fromCode);
      return CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateScaledE9: rateScaledE9,
        fromDecimals: fromCurrency.decimals,
        toDecimals: toCurrency.decimals,
      );
    }

    final allCodes = <String>{
      ...todayTotalsByCurrency.keys,
      ...monthNetByCurrency.keys,
    };

    for (final code in allCodes) {
      final today = todayTotalsByCurrency[code];
      final month = monthNetByCurrency[code] ?? 0;
      final expenseConverted = today == null ? 0 : convert(today.expense, code);
      final incomeConverted = today == null ? 0 : convert(today.income, code);
      final monthConverted = convert(month, code);
      if (expenseConverted == null ||
          incomeConverted == null ||
          monthConverted == null) {
        missingRatesFor.add(code);
        continue;
      }
      convertedExpense += expenseConverted;
      convertedIncome += incomeConverted;
      convertedMonthNet += monthConverted;
    }

    final convertibleCount = allCodes.length - missingRatesFor.length;
    final canShowUnified = convertibleCount > 0;
    final missingRatesSorted = missingRatesFor.toList()..sort();
    final hasAnyNonDefaultConvertible = allCodes.any(
      (c) => c != defaultCurrency && !missingRatesFor.contains(c),
    );

    final Widget content;
    if (allCodes.isEmpty) {
      content = _PlaceholderBox(
        theme: theme,
        labels: [
          l10n.homeSummaryTodayExpense,
          l10n.homeSummaryTodayIncome,
          l10n.homeSummaryMonthNet,
        ],
      );
    } else {
      content = AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canShowUnified)
              _CurrencyGroup(
                currency: toCurrency,
                expense: convertedExpense,
                income: convertedIncome,
                monthNet: convertedMonthNet,
                locale: locale,
                labels: (
                  expense: l10n.homeSummaryTodayExpense,
                  income: l10n.homeSummaryTodayIncome,
                  monthNet: l10n.homeSummaryMonthNet,
                ),
                isApproximate: hasAnyNonDefaultConvertible,
                approximatelyPrefixLabel: l10n.approximatelyPrefix,
              ),
            if (canShowUnified && missingRatesSorted.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.homeSummaryUnconvertedHeader,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            for (final code in missingRatesSorted) ...[
              const SizedBox(height: 8),
              _CurrencyGroup(
                currency:
                    currenciesByCode[code] ??
                    Currency(code: code, decimals: 2, symbol: code),
                expense: todayTotalsByCurrency[code]?.expense ?? 0,
                income: todayTotalsByCurrency[code]?.income ?? 0,
                monthNet: monthNetByCurrency[code] ?? 0,
                locale: locale,
                labels: (
                  expense: l10n.homeSummaryTodayExpense,
                  income: l10n.homeSummaryTodayIncome,
                  monthNet: l10n.homeSummaryMonthNet,
                ),
                isApproximate: false,
                approximatelyPrefixLabel: l10n.approximatelyPrefix,
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: showJumpToToday ? onJumpToToday : null,
              child: Text(l10n.homeJumpToToday),
            ),
          ),
          content,
        ],
      ),
    );
  }
}

class _CurrencyGroup extends StatelessWidget {
  const _CurrencyGroup({
    required this.currency,
    required this.expense,
    required this.income,
    required this.monthNet,
    required this.locale,
    required this.labels,
    required this.isApproximate,
    required this.approximatelyPrefixLabel,
  });

  final Currency currency;
  final int expense;
  final int income;
  final int monthNet;
  final String locale;
  final ({String expense, String income, String monthNet}) labels;
  final bool isApproximate;
  final String approximatelyPrefixLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseStr = MoneyFormatter.format(
      amountMinorUnits: expense,
      currency: currency,
      locale: locale,
    );
    final incomeStr = MoneyFormatter.format(
      amountMinorUnits: income,
      currency: currency,
      locale: locale,
    );
    final monthNetStr = MoneyFormatter.formatSigned(
      amountMinorUnits: monthNet,
      currency: currency,
      locale: locale,
    );
    final prefix = isApproximate ? '≈ ' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(homePageCardBorderRadius),
        boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Chip(
            label: labels.expense,
            value: '$prefix$expenseStr',
            semanticValue: isApproximate
                ? '$approximatelyPrefixLabel $expenseStr'
                : null,
          ),
          _Chip(
            label: labels.income,
            value: '$prefix$incomeStr',
            semanticValue: isApproximate
                ? '$approximatelyPrefixLabel $incomeStr'
                : null,
          ),
          _Chip(
            label: labels.monthNet,
            value: '$prefix$monthNetStr',
            semanticValue: isApproximate
                ? '$approximatelyPrefixLabel $monthNetStr'
                : null,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.value,
    this.semanticValue,
  });

  final String label;
  final String value;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$label: ', style: theme.textTheme.bodySmall),
          if (semanticValue != null)
            Semantics(
              label: semanticValue,
              excludeSemantics: true,
              child: valueText,
            )
          else
            valueText,
        ],
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({required this.theme, required this.labels});

  final ThemeData theme;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final label in labels)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('$label: ', style: theme.textTheme.bodySmall),
                  Text(
                    '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
