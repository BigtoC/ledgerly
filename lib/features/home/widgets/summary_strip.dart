// Home summary strip — Wave 3 §4.1, §7 (extended with multi-currency
// conversion in Phase 2).
//
// When exchange rates are available for every in-use currency, the strip
// renders a single unified card in the user's default currency: day net
// and month-to-date net, an income-vs-expense ratio bar, and the day's
// income / expense tiles. When rates are missing
// for some currencies, the strip shows the unified total plus a separator
// labelled "Unconverted" plus a fallback per-currency group for each
// missing-rate currency, in stable ascending currency-code order.
//
// All values are integer minor units, scaled at the UI boundary by
// `MoneyFormatter` per Wave 0 §2.7 / PRD Money Storage Policy.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/constants.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../home_state.dart';

@Dependencies([exchangeRates])
class SummaryStrip extends ConsumerWidget {
  const SummaryStrip({
    super.key,
    required this.todayTotalsByCurrency,
    required this.monthNetByCurrency,
    required this.currenciesByCode,
    required this.locale,
    required this.defaultCurrency,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final ratesMap =
        ref.watch(exchangeRatesProvider).value ?? const <String, int>{};

    final toCurrency =
        currenciesByCode[defaultCurrency] ??
        Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);

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
      const dash = _Figure(text: '—');
      content = const _SummaryCard(
        dayNet: dash,
        monthNet: dash,
        income: dash,
        expense: dash,
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
      child: content,
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
    required this.isApproximate,
    required this.approximatelyPrefixLabel,
  });

  final Currency currency;
  final int expense;
  final int income;
  final int monthNet;
  final String locale;
  final bool isApproximate;
  final String approximatelyPrefixLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = isApproximate ? '≈ ' : '';

    _Figure signed(int amount, {bool isNet = false}) {
      final text = MoneyFormatter.formatSigned(
        amountMinorUnits: amount,
        currency: currency,
        locale: locale,
      );
      final shown = '$prefix$text';
      return _Figure(
        text: shown,
        semanticValue: isApproximate ? '$approximatelyPrefixLabel $text' : null,
        color: isNet ? _netColor(theme, amount) : null,
        parts: isNet
            ? _AmountParts.split(
                shown,
                bare: MoneyFormatter.formatBare(
                  amountMinorUnits: amount.abs(),
                  currency: currency,
                  locale: locale,
                ),
                decimals: currency.decimals,
              )
            : null,
      );
    }

    return _SummaryCard(
      dayNet: signed(income - expense, isNet: true),
      monthNet: signed(monthNet, isNet: true),
      income: signed(income),
      expense: signed(-expense),
      ratio: (income: income, expense: expense),
    );
  }
}

/// Green when positive, red when negative, the plain text colour at zero.
/// Light mode takes darker shades so the amount keeps WCAG AA contrast on
/// `surfaceContainer`.
Color _netColor(ThemeData theme, int amount) {
  final isDark = theme.brightness == Brightness.dark;
  if (amount > 0) return isDark ? _positiveDark : _positiveLight;
  if (amount < 0) return isDark ? _negativeDark : _negativeLight;
  return theme.colorScheme.onSurface;
}

const _positiveLight = Color(0xFF13744A);
const _positiveDark = Color(0xFF6DD5A3);
const _negativeLight = Color(0xFFB8283F);
const _negativeDark = Color(0xFFFF8F8F);

/// One formatted amount. [semanticValue] replaces the visible text for
/// screen readers (spelling out the `≈` prefix); [color] defaults to
/// `onSurface`.
class _Figure {
  const _Figure({
    required this.text,
    this.semanticValue,
    this.color,
    this.parts,
  });

  final String text;
  final String? semanticValue;
  final Color? color;

  /// When set, [text] renders in the design's mixed sizes.
  final _AmountParts? parts;
}

/// [_Figure.text] cut into the runs the design sizes separately: sign
/// (with any `≈`), currency symbol, integer part, and decimal separator
/// plus fraction. [trailing] holds a symbol that a locale puts after the
/// number.
class _AmountParts {
  const _AmountParts({
    required this.sign,
    required this.symbol,
    required this.integer,
    required this.fraction,
    required this.trailing,
  });

  final String sign;
  final String symbol;
  final String integer;
  final String fraction;
  final String trailing;

  static final _signRun = RegExp(r'^[≈+\-−\s]*');

  /// Locates [bare] (the unsigned number without symbol) inside [text].
  /// Returns null when it is not there, so the caller falls back to one
  /// size rather than guessing.
  static _AmountParts? split(
    String text, {
    required String bare,
    required int decimals,
  }) {
    final start = text.indexOf(bare);
    if (start < 0) return null;
    final lead = text.substring(0, start);
    final signLength = _signRun.firstMatch(lead)!.end;
    final fractionLength = decimals > 0 ? decimals + 1 : 0;
    return _AmountParts(
      sign: lead.substring(0, signLength),
      symbol: lead.substring(signLength),
      integer: bare.substring(0, bare.length - fractionLength),
      fraction: bare.substring(bare.length - fractionLength),
      trailing: text.substring(start + bare.length),
    );
  }
}

/// Day net and month net side by side, a divider, the income/expense
/// ratio bar (when [ratio] has activity) and the income and expense tiles.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.dayNet,
    required this.monthNet,
    required this.income,
    required this.expense,
    this.ratio,
  });

  final _Figure dayNet;
  final _Figure monthNet;
  final _Figure income;
  final _Figure expense;
  final ({int income, int expense})? ratio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ratio = this.ratio;
    final hasRatio = ratio != null && ratio.income + ratio.expense > 0;
    final isDark = theme.brightness == Brightness.dark;
    // Large text stacks each pair so every amount gets the full card width.
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(homePageCardBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Pair(
            stacked: stacked,
            gap: 12,
            first: _NetFigure(
              label: l10n.homeSummaryDayNet,
              figure: dayNet,
              alignment: CrossAxisAlignment.start,
            ),
            second: _NetFigure(
              label: l10n.homeSummaryMonthNet,
              figure: monthNet,
              alignment: stacked
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          if (hasRatio) ...[
            _RatioBar(
              income: ratio.income,
              expense: ratio.expense,
              incomeColor: isDark ? _positiveDark : _positiveLight,
              expenseColor: isDark ? _negativeDark : _negativeLight,
            ),
            const SizedBox(height: 12),
          ],
          _Pair(
            stacked: stacked,
            gap: 10,
            first: _FlowTile(
              label: l10n.homeSummaryTodayIncome,
              figure: income,
              icon: Icons.south_west,
              accent: isDark ? _positiveDark : _positiveLight,
            ),
            second: _FlowTile(
              label: l10n.homeSummaryTodayExpense,
              figure: expense,
              icon: Icons.north_east,
              accent: isDark ? _negativeDark : _negativeLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two equal-width columns side by side, or one above the other when
/// [stacked].
class _Pair extends StatelessWidget {
  const _Pair({
    required this.stacked,
    required this.gap,
    required this.first,
    required this.second,
  });

  final bool stacked;
  final double gap;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          SizedBox(height: gap),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        SizedBox(width: gap),
        Expanded(child: second),
      ],
    );
  }
}

class _NetFigure extends StatelessWidget {
  const _NetFigure({
    required this.label,
    required this.figure,
    required this.alignment,
  });

  final String label;
  final _Figure figure;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textAlign = alignment == CrossAxisAlignment.end
        ? TextAlign.end
        : TextAlign.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        _FigureText(
          figure: figure,
          textAlign: textAlign,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({
    required this.label,
    required this.figure,
    required this.icon,
    required this.accent,
  });

  final String label;
  final _Figure figure;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FigureText(
            figure: figure,
            textAlign: TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigureText extends StatelessWidget {
  const _FigureText({
    required this.figure,
    required this.textAlign,
    required this.style,
  });

  final _Figure figure;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // One line always: a wrapped amount can strand its minus sign. A
    // figure wider than its column scales down instead.
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: _text(
        style?.copyWith(
          color: figure.color ?? Theme.of(context).colorScheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final semanticValue = figure.semanticValue;
    if (semanticValue == null) return text;
    return Semantics(label: semanticValue, excludeSemantics: true, child: text);
  }

  Text _text(TextStyle? style) {
    final parts = figure.parts;
    final size = style?.fontSize;
    if (parts == null || size == null) {
      return Text(figure.text, maxLines: 1, softWrap: false, style: style);
    }
    // Design sizes against a 20px integer part: sign 18px, currency
    // symbol 14px, decimals 15px. The 1px gap after the sign and 3px gap
    // after the symbol are letter spacing on their last glyph, so the
    // text itself (read by screen readers) gains no characters.
    TextSpan run(String text, double scale, {double? gapAfter}) {
      final style = TextStyle(fontSize: size * scale);
      if (gapAfter == null) return TextSpan(text: text, style: style);
      final runes = text.runes.toList();
      final last = TextSpan(
        text: String.fromCharCode(runes.last),
        style: TextStyle(letterSpacing: gapAfter),
      );
      if (runes.length == 1) {
        return TextSpan(style: style, children: [last]);
      }
      return TextSpan(
        text: String.fromCharCodes(runes.take(runes.length - 1)),
        style: style,
        children: [last],
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          if (parts.sign.isNotEmpty) run(parts.sign, 0.9, gapAfter: 1),
          if (parts.symbol.isNotEmpty) run(parts.symbol, 0.7, gapAfter: 3),
          TextSpan(
            text: parts.integer,
            style: const TextStyle(letterSpacing: -0.2),
          ),
          if (parts.fraction.isNotEmpty) run(parts.fraction, 0.75),
          if (parts.trailing.isNotEmpty) run(parts.trailing, 0.7),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: style,
    );
  }
}

/// Income share (left) against expense share (right). A side with no
/// activity drops out, leaving one full-width segment.
class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.income,
    required this.expense,
    required this.incomeColor,
    required this.expenseColor,
  });

  final int income;
  final int expense;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final incomePercent = (income * 100 / (income + expense)).round();
    Widget segment(int flex, Color color) => Expanded(
      flex: flex,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: l10n.homeSummaryRatioLabel(incomePercent, 100 - incomePercent),
      child: SizedBox(
        key: const ValueKey('summaryRatioBar'),
        height: 6,
        // Stretch: a childless DecoratedBox otherwise collapses to 0px.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (income > 0) segment(income, incomeColor),
            if (income > 0 && expense > 0) const SizedBox(width: 3),
            if (expense > 0) segment(expense, expenseColor),
          ],
        ),
      ),
    );
  }
}
