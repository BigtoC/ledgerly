import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';
import '../charts_state.dart';

/// Pie chart with tap-to-focus interaction. The selected slice grows, its
/// neighbours dim, and the centre hole surfaces label + amount. Selection
/// is hoisted via [onSelectionChanged] so [ChartLegend] can mirror it.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.grandTotalMinorUnits,
    this.displayCurrencyCode,
    this.selectedIndex,
    this.onSelectionChanged,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;
  final int? grandTotalMinorUnits;
  final String? displayCurrencyCode;

  /// Externally-controlled selection (e.g. from legend taps). When null the
  /// chart maintains its own internal selection state.
  final int? selectedIndex;

  /// Fired when the user taps a slice. Null means "deselect". Receivers
  /// should treat this as an authoritative selection update.
  final ValueChanged<int?>? onSelectionChanged;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _internalSelection;

  int? get _effectiveSelection => widget.selectedIndex ?? _internalSelection;

  @override
  void didUpdateWidget(covariant CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection if the slice set changes — indices are no longer
    // meaningful after a period/dimension swap.
    if (oldWidget.slices.length != widget.slices.length) {
      _internalSelection = null;
    }
  }

  void _select(int? index) {
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(index);
    }
    if (widget.selectedIndex == null) {
      setState(() => _internalSelection = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty) {
      return const SizedBox(height: 200);
    }
    final showLabels = widget.slices.first.fraction != null;
    final l10n = AppLocalizations.of(context);
    final selection = _effectiveSelection;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: _semanticsLabel(l10n),
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      return;
                    }
                    final idx = response.touchedSection!.touchedSectionIndex;
                    if (idx < 0 || idx >= widget.slices.length) {
                      // Tap landed in the centre hole — clear selection.
                      if (event is FlTapUpEvent || event is FlLongPressEnd) {
                        _select(null);
                      }
                      return;
                    }
                    if (event is FlTapUpEvent || event is FlLongPressEnd) {
                      _select(selection == idx ? null : idx);
                    }
                  },
                ),
                sections: [
                  for (var i = 0; i < widget.slices.length; i++)
                    _section(
                      slice: widget.slices[i],
                      isSelected: i == selection,
                      anySelected: selection != null,
                      showLabels: showLabels,
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
            IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _centerLabel(
                  l10n: l10n,
                  scheme: scheme,
                  selection: selection,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section({
    required ChartSlice slice,
    required bool isSelected,
    required bool anySelected,
    required bool showLabels,
  }) {
    final baseColor = colorForIndex(slice.colorIndex);
    final color = anySelected && !isSelected
        ? baseColor.withValues(alpha: 0.4)
        : baseColor;
    return PieChartSectionData(
      value: slice.totalMinorUnits.abs().toDouble(),
      color: color,
      title: showLabels ? '${(slice.fraction! * 100).round()}%' : '',
      radius: isSelected ? 72 : 60,
      titleStyle: TextStyle(
        fontSize: isSelected ? 14 : 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: Colors.white,
        shadows: isSelected
            ? const [Shadow(blurRadius: 2, color: Colors.black54)]
            : null,
      ),
    );
  }

  Widget _centerLabel({
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required int? selection,
  }) {
    if (selection == null) {
      if (widget.grandTotalMinorUnits == null ||
          widget.displayCurrencyCode == null) {
        return const SizedBox.shrink(key: ValueKey('empty'));
      }
      final currency =
          widget.currenciesByCode[widget.displayCurrencyCode!] ??
          Currency(code: widget.displayCurrencyCode!, decimals: 2);
      final amount = MoneyFormatter.format(
        amountMinorUnits: widget.grandTotalMinorUnits!,
        currency: currency,
        locale: widget.locale,
      );
      return Column(
        key: const ValueKey('total'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.chartsTotal,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      );
    }
    final slice = widget.slices[selection];
    final currency =
        widget.currenciesByCode[slice.currencyCode] ??
        Currency(code: slice.currencyCode, decimals: 2);
    final amount = MoneyFormatter.format(
      amountMinorUnits: slice.totalMinorUnits,
      currency: currency,
      locale: widget.locale,
    );
    final displayLabel = slice.label.startsWith('category.')
        ? categoryDisplayNameForKey(slice.label, l10n)
        : slice.label;
    return Padding(
      key: ValueKey('slice-$selection'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorForIndex(slice.colorIndex),
            ),
          ),
          if (slice.fraction != null) ...[
            const SizedBox(height: 2),
            Text(
              '${(slice.fraction! * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  String _semanticsLabel(AppLocalizations l10n) {
    final parts = <String>[l10n.chartsPieChart];
    for (final s in widget.slices) {
      final currency =
          widget.currenciesByCode[s.currencyCode] ??
          Currency(code: s.currencyCode, decimals: 2);
      final amount = MoneyFormatter.format(
        amountMinorUnits: s.totalMinorUnits,
        currency: currency,
        locale: widget.locale,
      );
      final displayLabel = s.label.startsWith('category.')
          ? categoryDisplayNameForKey(s.label, l10n)
          : s.label;
      if (s.fraction != null) {
        parts.add('$displayLabel ${(s.fraction! * 100).round()}%, $amount');
      } else {
        parts.add('$displayLabel: $amount');
      }
    }
    if (widget.grandTotalMinorUnits != null &&
        widget.displayCurrencyCode != null) {
      final currency =
          widget.currenciesByCode[widget.displayCurrencyCode!] ??
          Currency(code: widget.displayCurrencyCode!, decimals: 2);
      final total = MoneyFormatter.format(
        amountMinorUnits: widget.grandTotalMinorUnits!,
        currency: currency,
        locale: widget.locale,
      );
      parts.add('${l10n.chartsTotal} $total');
    }
    return parts.join('. ');
  }
}
