import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/category.dart';
import '../../../../../domain/models/currency.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../../../categories/views/category_display.dart';
import '../view_models/charts_state.dart';

/// Breakdown donut with tap-to-focus interaction. A selected slice keeps
/// its colour while the others fade, and the centre shows its label,
/// amount and share. Selection is hoisted via [onSelectionChanged] so
/// [ChartLegend] can mirror it.
class const CategoryPieChart({
  super.key,
  required final List<ChartSlice> slices,
  required final Map<String, Currency> currenciesByCode,
  required final String locale,

  /// Chart type, for the centre's "Total expense" / "of income" wording.
  required final CategoryType type,

  /// Grouping, for the centre's "N categories / accounts / currencies".
  required final ChartDimension dimension,
  final int? grandTotalMinorUnits,
  final String? displayCurrencyCode,

  /// Externally-controlled selection (e.g. from legend taps). Null means
  /// no slice is highlighted. The chart is fully controlled — there is no
  /// internal fallback selection.
  final int? selectedIndex,

  /// Fired when the user taps a slice. Null means "deselect". Receivers
  /// should treat this as an authoritative selection update.
  final ValueChanged<int?>? onSelectionChanged,

  /// The filtered account's name; while no slice is selected the centre
  /// then reads `<Account> expense`. Null = all accounts.
  final String? accountName,
}) extends StatefulWidget {
  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  static const double _kSize = 200;
  static const double _kHoleRadius = 74;
  static const double _kRingWidth = 26;

  /// D6: fl_chart draws a constant-width gap, not the design's 0.6 %
  /// wedge; 3.28 is the wedge's width at mid-ring.
  static const double _kSectionsSpace = 3.28;

  /// D6: start at 12 o'clock, shifted back by half the 0.6 % wedge
  /// (1.08°) so each gap sits where the design ends its slice.
  static const double _kStartDegreeOffset = -90 - 1.08;

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty) {
      return const SizedBox(height: _kSize);
    }
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final selection = widget.selectedIndex;

    return Semantics(
      label: _semanticsLabel(l10n),
      image: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          heightFactor: 1,
          child: SizedBox.square(
            dimension: _kSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: _kSectionsSpace,
                    centerSpaceRadius: _kHoleRadius,
                    startDegreeOffset: _kStartDegreeOffset,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        // Don't gate on `isInterestedForInteractions`:
                        // fl_chart reports FlTapUpEvent as uninteresting on
                        // mobile, which would drop every slice tap.
                        if ((event is! FlTapUpEvent &&
                                event is! FlLongPressEnd) ||
                            response == null ||
                            response.touchedSection == null) {
                          return;
                        }
                        final idx =
                            response.touchedSection!.touchedSectionIndex;
                        if (idx < 0 || idx >= widget.slices.length) {
                          // Tap landed in the centre hole — clear selection.
                          widget.onSelectionChanged?.call(null);
                          return;
                        }
                        widget.onSelectionChanged?.call(
                          selection == idx ? null : idx,
                        );
                      },
                    ),
                    sections: [
                      for (var i = 0; i < widget.slices.length; i++)
                        _section(
                          slice: widget.slices[i],
                          faded: selection != null && i != selection,
                        ),
                    ],
                  ),
                  duration: AnalysisMotion.standardDuration,
                  curve: AnalysisMotion.standardCurve,
                ),
                IgnorePointer(
                  // Fixed-size box: clamp the centre text at 1.5x (D2).
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: SizedBox.square(
                      dimension: _kHoleRadius * 2,
                      child: _center(l10n, colors, selection),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PieChartSectionData _section({
    required ChartSlice slice,
    required bool faded,
  }) {
    final baseColor = colorForIndex(slice.colorIndex);
    return PieChartSectionData(
      value: slice.totalMinorUnits.abs().toDouble(),
      color: faded ? baseColor.withAlpha(0x4D) : baseColor,
      radius: _kRingWidth,
      showTitle: false,
    );
  }

  Widget _center(AppLocalizations l10n, AnalysisColors colors, int? selection) {
    final isIncome = widget.type == CategoryType.income;
    final String top;
    final Color topColor;
    final FontWeight topWeight;
    final String amount;
    final String? sub;
    if (selection == null) {
      final account = widget.accountName;
      top = account != null
          ? (isIncome
                ? l10n.chartsAccountIncome(account)
                : l10n.chartsAccountExpense(account))
          : (isIncome ? l10n.chartsTotalIncome : l10n.chartsTotalExpense);
      topColor = colors.fg2;
      topWeight = FontWeight.w400;
      final total = widget.grandTotalMinorUnits;
      final code = widget.displayCurrencyCode;
      // D12: no grand total when currencies are mixed.
      amount = total == null || code == null ? '—' : _format(total, code);
      final count = widget.slices.length;
      sub = switch (widget.dimension) {
        ChartDimension.category => l10n.chartsCategoryCount(count),
        ChartDimension.account => l10n.chartsAccountCount(count),
        ChartDimension.currency => l10n.chartsCurrencyCount(count),
      };
    } else {
      final slice = widget.slices[selection];
      top = categoryDisplayNameForKey(slice.label, l10n);
      topColor = colors.fg;
      topWeight = FontWeight.w500;
      amount = _format(slice.totalMinorUnits, slice.currencyCode);
      final fraction = slice.fraction;
      if (fraction == null) {
        sub = null;
      } else {
        final percent = '${(fraction * 100).toStringAsFixed(1)}%';
        sub = isIncome
            ? l10n.chartsShareOfIncome(percent)
            : l10n.chartsShareOfExpense(percent);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            top,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: analysisText(
              size: 12,
              lineHeight: 16,
              weight: topWeight,
              color: topColor,
            ),
          ),
          const SizedBox(height: 2),
          // D2: shrink long amounts to the 128 dp line instead of
          // overflowing it; 1:1 when they fit.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              maxLines: 1,
              softWrap: false,
              style: analysisText(
                size: 17,
                lineHeight: 24,
                weight: FontWeight.w500,
                color: colors.fg,
                tabular: true,
              ),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: analysisText(size: 12, lineHeight: 16, color: colors.fg3),
            ),
          ],
        ],
      ),
    );
  }

  String _format(int minorUnits, String code) => MoneyFormatter.format(
    amountMinorUnits: minorUnits,
    currency:
        widget.currenciesByCode[code] ?? Currency(code: code, decimals: 2),
    locale: widget.locale,
  );

  String _semanticsLabel(AppLocalizations l10n) {
    final parts = <String>[l10n.chartsPieChart];
    for (final s in widget.slices) {
      final amount = _format(s.totalMinorUnits, s.currencyCode);
      final displayLabel = categoryDisplayNameForKey(s.label, l10n);
      if (s.fraction != null) {
        parts.add('$displayLabel ${(s.fraction! * 100).round()}%, $amount');
      } else {
        parts.add('$displayLabel: $amount');
      }
    }
    if (widget.grandTotalMinorUnits != null &&
        widget.displayCurrencyCode != null) {
      final total = _format(
        widget.grandTotalMinorUnits!,
        widget.displayCurrencyCode!,
      );
      parts.add('${l10n.chartsTotal} $total');
    }
    return parts.join('. ');
  }
}
