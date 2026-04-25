// Home summary strip — Wave 3 §4.1, §7.
//
// Three labelled tiles per currency: `Today expense`, `Today income`,
// `Month net`. Multiple currencies stack inside a `Wrap` so the strip
// reflows under 2× text scale and on narrow phones.
//
// All values are integer minor units, scaled at the UI boundary by
// `MoneyFormatter` per Wave 0 §2.7 / PRD Money Storage Policy.

import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../home_state.dart';

class SummaryStrip extends StatelessWidget {
  const SummaryStrip({
    super.key,
    required this.todayTotalsByCurrency,
    required this.monthNetByCurrency,
    required this.currenciesByCode,
    required this.locale,
  });

  /// Today's per-currency expense/income split.
  final DailyTotals todayTotalsByCurrency;

  /// Month-to-date net per currency.
  final Map<String, int> monthNetByCurrency;

  /// Resolves a currency code to its metadata so [MoneyFormatter] can
  /// render `decimals` correctly. Codes missing from this map fall back
  /// to a 2-decimal placeholder so a transient gap (e.g. metadata still
  /// loading) does not crash the strip.
  final Map<String, Currency> currenciesByCode;

  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Union of currencies that appear in either map.
    final codes = <String>{
      ...todayTotalsByCurrency.keys,
      ...monthNetByCurrency.keys,
    }.toList()..sort();

    if (codes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _PlaceholderRow(
          theme: theme,
          labels: [
            l10n.homeSummaryTodayExpense,
            l10n.homeSummaryTodayIncome,
            l10n.homeSummaryMonthNet,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final code in codes)
            _CurrencyGroup(
              code: code,
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
            ),
        ],
      ),
    );
  }
}

class _CurrencyGroup extends StatelessWidget {
  const _CurrencyGroup({
    required this.code,
    required this.currency,
    required this.expense,
    required this.income,
    required this.monthNet,
    required this.locale,
    required this.labels,
  });

  final String code;
  final Currency currency;
  final int expense;
  final int income;
  final int monthNet;
  final String locale;
  final ({String expense, String income, String monthNet}) labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code, style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          _Chip(
            label: labels.expense,
            value: MoneyFormatter.format(
              amountMinorUnits: expense,
              currency: currency,
              locale: locale,
            ),
          ),
          _Chip(
            label: labels.income,
            value: MoneyFormatter.format(
              amountMinorUnits: income,
              currency: currency,
              locale: locale,
            ),
          ),
          _Chip(
            label: labels.monthNet,
            value: MoneyFormatter.formatSigned(
              amountMinorUnits: monthNet,
              currency: currency,
              locale: locale,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({required this.theme, required this.labels});

  final ThemeData theme;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final label in labels)
          Row(
            mainAxisSize: MainAxisSize.min,
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
      ],
    );
  }
}
