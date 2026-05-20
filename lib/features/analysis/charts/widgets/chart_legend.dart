import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';
import '../charts_state.dart';

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.mixedCurrencies = false,
    this.selectedSliceIndex,
    this.onSelectSlice,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;

  /// When true, the legend's `Other` bucket renders an item count instead
  /// of a summed amount, because the leftover slices are in different
  /// source currencies and cannot be added meaningfully.
  final bool mixedCurrencies;

  /// Index into [slices] of the chart's currently focused slice. Drives
  /// the dim/elevate treatment on legend rows so the legend mirrors the
  /// pie chart's selection.
  final int? selectedSliceIndex;

  /// Tap callback for legend rows. Receives the index into [slices] (the
  /// original order, not the visually-sorted order). Null toggles off.
  final ValueChanged<int?>? onSelectSlice;

  static const int _maxVisible = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Index-tagged sort so taps can map back to the original slice index
    // (which is what the pie chart selection is keyed on).
    final indexed =
        [for (var i = 0; i < slices.length; i++) (index: i, slice: slices[i])]
          ..sort(
            (a, b) =>
                b.slice.totalMinorUnits.compareTo(a.slice.totalMinorUnits),
          );

    final visible = <({int index, ChartSlice slice})>[];
    var otherTotal = 0;
    var otherCount = 0;
    final otherCurrencyCode = indexed.isNotEmpty
        ? indexed.first.slice.currencyCode
        : 'USD';
    if (indexed.length <= _maxVisible) {
      visible.addAll(indexed);
    } else {
      visible.addAll(indexed.take(_maxVisible - 1));
      for (final entry in indexed.skip(_maxVisible - 1)) {
        otherTotal += entry.slice.totalMinorUnits;
        otherCount++;
      }
    }
    final hasOther = indexed.length > _maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in visible)
          _row(context, entry.slice, originalIndex: entry.index),
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
              onPressed: () => _openFullLegend(context, indexed),
              child: Text(l10n.chartsViewAll),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, ChartSlice s, {int? originalIndex}) {
    final l10n = AppLocalizations.of(context);
    final currency =
        currenciesByCode[s.currencyCode] ??
        Currency(code: s.currencyCode, decimals: 2);
    // The controller serializes seeded categories as their `category.*`
    // l10n key (no BuildContext available there). Re-resolve at render
    // time so the legend shows the localized name.
    final displayLabel = s.label.startsWith('category.')
        ? categoryDisplayNameForKey(s.label, l10n)
        : s.label;
    final isSelected =
        originalIndex != null && originalIndex == selectedSliceIndex;
    final hasAnySelection = selectedSliceIndex != null;
    final dim = hasAnySelection && !isSelected;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorForIndex(s.colorIndex).withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 220),
        style: DefaultTextStyle.of(context).style.copyWith(
          color: DefaultTextStyle.of(
            context,
          ).style.color?.withValues(alpha: dim ? 0.45 : 1.0),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 14 : 12,
              height: isSelected ? 14 : 12,
              decoration: BoxDecoration(
                color: colorForIndex(
                  s.colorIndex,
                ).withValues(alpha: dim ? 0.45 : 1.0),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorForIndex(
                            s.colorIndex,
                          ).withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            if (s.iconKey.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: Icon(iconForKey(s.iconKey), size: 16),
              ),
            Expanded(
              child: Text(displayLabel, overflow: TextOverflow.ellipsis),
            ),
            Text(
              MoneyFormatter.format(
                amountMinorUnits: s.totalMinorUnits,
                currency: currency,
                locale: locale,
              ),
            ),
          ],
        ),
      ),
    );
    if (originalIndex == null || onSelectSlice == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSelectSlice!(isSelected ? null : originalIndex),
        child: row,
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

  void _openFullLegend(
    BuildContext context,
    List<({int index, ChartSlice slice})> all,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in all)
              _row(sheetCtx, entry.slice, originalIndex: entry.index),
          ],
        ),
      ),
    );
  }
}
