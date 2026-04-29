// Home summary strip — Wave 3 §4.1, §7.
//
// Three labelled tiles per currency: `Today expense`, `Today income`,
// `Month net`. Multiple currencies stack inside a `Wrap` so the strip
// reflows under 2× text scale and on narrow phones.
//
// All values are integer minor units, scaled at the UI boundary by
// `MoneyFormatter` per Wave 0 §2.7 / PRD Money Storage Policy.

import 'package:flutter/material.dart';

import 'package:ledgerly/core/utils/box_shadow.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants.dart';
import '../home_state.dart';

class SummaryStrip extends StatelessWidget {
  const SummaryStrip({
    super.key,
    required this.todayTotalsByCurrency,
    required this.monthNetByCurrency,
    required this.currenciesByCode,
    required this.locale,
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

  /// When true, renders a "Jump to today" button at the top of the strip.
  final bool showJumpToToday;

  /// Called when the "Jump to today" button is tapped.
  final VoidCallback? onJumpToToday;

  /// Maximum number of currency groups to render before showing the note.
  static const int _kMaxCurrencyGroups = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final todayCodes = todayTotalsByCurrency.keys.toSet();
    final allCodes =
        <String>{...todayCodes, ...monthNetByCurrency.keys}.toList()
          ..sort((a, b) {
            final aToday = todayCodes.contains(a);
            final bToday = todayCodes.contains(b);
            if (aToday && !bToday) return -1;
            if (!aToday && bToday) return 1;
            return a.compareTo(b);
          });

    final hasMultiCurrency = allCodes.length > _kMaxCurrencyGroups;
    final codes = hasMultiCurrency
        ? allCodes.sublist(0, _kMaxCurrencyGroups)
        : allCodes;

    Widget content;
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
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < codes.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _CurrencyGroup(
              currency:
                  currenciesByCode[codes[i]] ??
                  Currency(code: codes[i], decimals: 2, symbol: codes[i]),
              expense: todayTotalsByCurrency[codes[i]]?.expense ?? 0,
              income: todayTotalsByCurrency[codes[i]]?.income ?? 0,
              monthNet: monthNetByCurrency[codes[i]] ?? 0,
              locale: locale,
              labels: (
                expense: l10n.homeSummaryTodayExpense,
                income: l10n.homeSummaryTodayIncome,
                monthNet: l10n.homeSummaryMonthNet,
              ),
            ),
          ],
          if (hasMultiCurrency) ...[
            const SizedBox(height: 8),
            Text(
              l10n.homeSummaryMultiCurrencyNote,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // (1) Jump-to-today button (only when not on today)
          if (showJumpToToday)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onJumpToToday,
                child: Text(l10n.homeJumpToToday),
              ),
            ),
          // (2) Currency groups + (3) month-net + (4) multi-currency note
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
  });

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
          // Currency identity is conveyed by the symbol that
          // `MoneyFormatter` prefixes onto each amount, so the row no
          // longer carries a separate code header.
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
      // Wrap so the label + value reflow onto multiple lines under
      // 2× text scale instead of overflowing the chip's row width.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
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
              // Wrap mirrors `_Chip`'s 2× text-scale reflow.
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
