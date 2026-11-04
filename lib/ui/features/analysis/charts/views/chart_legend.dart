import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/icon_registry.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/currency.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../../../categories/views/category_display.dart';
import '../view_models/charts_state.dart';
import '../view_models/selected_slice.dart';

/// Breakdown ranked rows: one row per slice, largest first, each with a
/// coloured icon circle, label, amount, share bar and percentage. Mirrors
/// the donut's selection.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.selectedSliceIndex,
    required this.onSelectSlice,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;

  /// Index into [slices] of the chart's currently focused slice. Drives
  /// the selected fill and the fade on the other rows.
  final int? selectedSliceIndex;

  /// Tap callback for rows. Receives the index into [slices] (the
  /// original order, not the visually-sorted order). Null toggles off.
  final ValueChanged<int?> onSelectSlice;

  @override
  Widget build(BuildContext context) {
    // Index-tagged sort so taps can map back to the original slice index
    // (which is what the pie chart selection is keyed on).
    final indexed =
        [for (var i = 0; i < slices.length; i++) (index: i, slice: slices[i])]
          ..sort(
            (a, b) =>
                b.slice.totalMinorUnits.compareTo(a.slice.totalMinorUnits),
          );

    // Every slice gets a row. The count is bounded by the user's
    // categories / accounts / currencies, so a non-lazy Column is fine.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in indexed)
            _RankedRow(
              slice: entry.slice,
              amount: MoneyFormatter.format(
                amountMinorUnits: entry.slice.totalMinorUnits,
                currency:
                    currenciesByCode[entry.slice.currencyCode] ??
                    Currency(code: entry.slice.currencyCode, decimals: 2),
                locale: locale,
              ),
              selected: entry.index == selectedSliceIndex,
              faded:
                  selectedSliceIndex != null &&
                  entry.index != selectedSliceIndex,
              onTap: () => onSelectSlice(
                entry.index == selectedSliceIndex ? null : entry.index,
              ),
            ),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.slice,
    required this.amount,
    required this.selected,
    required this.faded,
    required this.onTap,
  });

  static const _darkInk = Color(0xFF1B1B1B);
  static const _lightInk = Color(0xFFFFFFFF);

  /// Width the label keeps before a long amount starts to scale down.
  static const double _minLabelWidth = 40;

  final ChartSlice slice;
  final String amount;
  final bool selected;

  /// Another row is selected: fade the circle and the bar fill only.
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final sliceColor = colorForIndex(slice.colorIndex);
    final ink = sliceColor.computeLuminance() > 0.35 ? _darkInk : _lightInk;
    // The currency code is small text (4.5:1), so it takes whichever ink
    // contrasts more with the fill rather than the icon threshold (D24).
    final codeInk = higherContrastInk(
      sliceColor,
      dark: _darkInk,
      light: _lightInk,
    );
    final fadeOpacity = faded ? 0.35 : 1.0;
    final fraction = slice.fraction;
    // The controller serializes seeded categories as their `category.*`
    // l10n key (no BuildContext available there). Re-resolve at render
    // time so the row shows the localized name.
    final label = categoryDisplayNameForKey(slice.label, l10n);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: fadeOpacity,
            duration: AnalysisMotion.standardDuration,
            curve: AnalysisMotion.standardCurve,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sliceColor,
                shape: BoxShape.circle,
              ),
              child: slice.selectionKey is SelectedCurrencySlice
                  // Fixed-size circle: clamp the code at 1.5x.
                  ? MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.5,
                      child: Text(
                        slice.label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: codeInk,
                        ),
                      ),
                    )
                  : Icon(iconForKey(slice.iconKey), size: 18, color: ink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // D2: the label ellipsizes first. The amount never
                // ellipsizes; it scales down only when it cannot fit beside
                // a minimal label.
                LayoutBuilder(
                  // Centre, not baseline: FittedBox reports its child's
                  // unscaled baseline, so a scaled amount would ride up.
                  // Both texts share 15/20 metrics, so at full size centre
                  // lands on the same baseline.
                  builder: (context, constraints) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: analysisText(
                            size: 15,
                            lineHeight: 20,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: colors.fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: math.max(
                            0,
                            constraints.maxWidth - 8 - _minLabelWidth,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amount,
                            maxLines: 1,
                            softWrap: false,
                            style: analysisText(
                              size: 15,
                              lineHeight: 20,
                              weight: FontWeight.w500,
                              color: colors.fg,
                              tabular: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Mixed currencies have no share: hide the bar and the %.
                if (fraction != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.track,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: AlignmentDirectional.centerStart,
                          child: AnimatedFractionallySizedBox(
                            duration: AnalysisMotion.emphasizedDuration,
                            curve: AnalysisMotion.emphasizedCurve,
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: fraction,
                            heightFactor: 1,
                            child: AnimatedOpacity(
                              opacity: fadeOpacity,
                              duration: AnalysisMotion.standardDuration,
                              curve: AnalysisMotion.standardCurve,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: sliceColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 40),
                        child: Text(
                          '${(fraction * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: analysisText(
                            size: 12,
                            lineHeight: 16,
                            color: colors.fg3,
                            tabular: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right, size: 18, color: colors.fg3),
        ],
      ),
    );

    final row = AnimatedContainer(
      duration: AnalysisMotion.standardDuration,
      curve: AnalysisMotion.standardCurve,
      decoration: BoxDecoration(
        color: selected ? colors.sel : colors.sel.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(14),
      ),
      // The ink paints on this transparent Material, above the sel fill.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: content,
        ),
      ),
    );
    return MergeSemantics(
      child: Semantics(button: true, selected: selected, child: row),
    );
  }
}
