import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.mixedCurrencies = false,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;

  /// When true, the legend's `Other` bucket renders an item count instead
  /// of a summed amount, because the leftover slices are in different
  /// source currencies and cannot be added meaningfully.
  final bool mixedCurrencies;

  static const int _maxVisible = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...slices]
      ..sort((a, b) => b.totalMinorUnits.compareTo(a.totalMinorUnits));

    final visible = <ChartSlice>[];
    var otherTotal = 0;
    var otherCount = 0;
    final otherCurrencyCode = sorted.isNotEmpty
        ? sorted.first.currencyCode
        : 'USD';
    if (sorted.length <= _maxVisible) {
      visible.addAll(sorted);
    } else {
      visible.addAll(sorted.take(_maxVisible - 1));
      for (final s in sorted.skip(_maxVisible - 1)) {
        otherTotal += s.totalMinorUnits;
        otherCount++;
      }
    }
    final hasOther = sorted.length > _maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in visible) _row(context, s),
        if (hasOther)
          _otherRow(
            context,
            l10n: l10n,
            total: otherTotal,
            count: otherCount,
            currencyCode: otherCurrencyCode,
          ),
        if (hasOther)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => _openFullLegend(context, sorted),
              child: Text(l10n.chartsViewAll),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, ChartSlice s) {
    final currency =
        currenciesByCode[s.currencyCode] ??
        Currency(code: s.currencyCode, decimals: 2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colorForIndex(s.colorIndex),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          if (s.iconKey.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(iconForKey(s.iconKey), size: 16),
            ),
          Expanded(child: Text(s.label, overflow: TextOverflow.ellipsis)),
          Text(
            MoneyFormatter.format(
              amountMinorUnits: s.totalMinorUnits,
              currency: currency,
              locale: locale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherRow(
    BuildContext context, {
    required AppLocalizations l10n,
    required int total,
    required int count,
    required String currencyCode,
  }) {
    if (mixedCurrencies) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorForIndex(CategoryPaletteIndex.neutralVariant50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.chartsOtherCount(count),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return _row(
      context,
      ChartSlice(
        label: l10n.chartsOther,
        currencyCode: currencyCode,
        totalMinorUnits: total,
        colorIndex: CategoryPaletteIndex.neutralVariant50,
        iconKey: '',
      ),
    );
  }

  void _openFullLegend(BuildContext context, List<ChartSlice> all) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [for (final s in all) _row(sheetCtx, s)],
        ),
      ),
    );
  }
}
