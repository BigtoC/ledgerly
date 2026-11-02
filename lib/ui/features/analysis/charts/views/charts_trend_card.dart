import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/category.dart' show CategoryType;
import '../../../../../domain/models/currency.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../../../categories/views/category_display.dart';
import '../view_models/charts_state.dart';
import '../view_models/trend_series.dart';
import 'daily_bar_chart.dart';

/// Trend card: title, average legend, slice filter chip and the bar chart.
/// See `docs/superpowers/specs/2026-11-02-analysis-redesign-design.md` § 7.
class ChartsTrendCard extends StatelessWidget {
  const ChartsTrendCard({
    super.key,
    required this.data,
    required this.selectedSlice,
    required this.onClearSlice,
    required this.locale,
    required this.currenciesByCode,
    this.accountName,
  });

  final ChartsData data;

  /// The slice the bars are filtered to, if any.
  final ChartSlice? selectedSlice;
  final VoidCallback onClearSlice;
  final String locale;
  final Map<String, Currency> currenciesByCode;

  /// The filtered account's name, shown as `<Account> · ` before the
  /// average. Null = all accounts.
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final l10n = AppLocalizations.of(context);
    final series = trendSeries(
      period: data.period,
      anchorDate: data.anchorDate,
      bucketTotals: data.bucketTotals,
      now: DateTime.now(),
    );
    final monthly = data.period == PeriodType.year;
    final expense = data.type == CategoryType.expense;
    final title = switch ((monthly, expense)) {
      (false, true) => l10n.chartsTrendDailySpending,
      (true, true) => l10n.chartsTrendMonthlySpending,
      (false, false) => l10n.chartsTrendDailyIncome,
      (true, false) => l10n.chartsTrendMonthlyIncome,
    };
    final average = _amount(series.averageMinorUnits.round());
    final subtitle = monthly
        ? l10n.chartsAvgPerMonth(average)
        : l10n.chartsAvgPerDay(average);
    final subtitleStyle = analysisText(
      size: 13,
      lineHeight: 18,
      color: colors.fg2,
      tabular: true,
    );
    final slice = selectedSlice;
    final barColor = slice != null
        ? colorForIndex(slice.colorIndex)
        : expense
        ? colors.exp
        : colors.inc;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: analysisText(
                            size: 16,
                            lineHeight: 24,
                            weight: FontWeight.w500,
                            color: colors.fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        LayoutBuilder(
                          builder: (context, line) => Row(
                            children: [
                              CustomPaint(
                                key: const ValueKey('trendAvgLegend'),
                                size: const Size(14, 1.5),
                                painter: _DashPainter(colors.fg3),
                              ),
                              const SizedBox(width: 6),
                              // The account prefix takes what the average
                              // leaves and ellipsizes first (D2).
                              if (accountName != null)
                                Flexible(
                                  child: Text(
                                    '$accountName · ',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: subtitleStyle,
                                  ),
                                ),
                              // The amount is never cut off: one line,
                              // scaled down only when it alone does not fit
                              // beside the legend (D2).
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: math.max(0, line.maxWidth - 20),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: subtitleStyle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (slice != null) ...[
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      // The design lets the chip push the title to zero
                      // width; cap it at half the header instead.
                      constraints: BoxConstraints(
                        maxWidth: (constraints.maxWidth - 12) / 2,
                      ),
                      child: _FilterChip(slice: slice, onTap: onClearSlice),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: DailyBarChart(
              period: data.period,
              series: series,
              barColor: barColor,
              locale: locale,
              currenciesByCode: currenciesByCode,
              displayCurrencyCode: data.displayCurrencyCode,
            ),
          ),
        ],
      ),
    );
  }

  String _amount(int minorUnits) {
    final code = data.displayCurrencyCode;
    if (code == null) return minorUnits.toString();
    return MoneyFormatter.format(
      amountMinorUnits: minorUnits,
      currency: currenciesByCode[code] ?? Currency(code: code, decimals: 2),
      locale: locale,
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({required this.slice, required this.onTap});

  final ChartSlice slice;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  final _pillKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final l10n = AppLocalizations.of(context);
    final slice = widget.slice;
    final label = categoryDisplayNameForKey(slice.label, l10n);
    return Semantics(
      container: true,
      button: true,
      label: l10n.chartsClearSliceFilter(label),
      onTap: widget.onTap,
      excludeSemantics: true,
      // The card's fill hides the Scaffold's Material, so the ink needs its
      // own.
      child: Material(
        type: MaterialType.transparency,
        child: _PillInkWell(
          pillKey: _pillKey,
          onTap: widget.onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: ConstrainedBox(
                key: const ValueKey('trendFilterPill'),
                constraints: const BoxConstraints(minHeight: 32),
                // Ink, not a Container fill, so the ripple paints above it.
                child: Ink(
                  key: _pillKey,
                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                  decoration: BoxDecoration(
                    color: colors.sel,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: const ValueKey('trendFilterDot'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorForIndex(slice.colorIndex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            color: colors.fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.close, size: 16, color: colors.fg2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An [InkWell] over the whole 44 px hit target whose ripple, highlight and
/// focus ink cover only the pill inside it (D16).
class _PillInkWell extends InkWell {
  const _PillInkWell({
    required this.pillKey,
    super.onTap,
    super.customBorder,
    super.child,
  });

  final GlobalKey pillKey;

  @override
  RectCallback getRectCallback(RenderBox referenceBox) => () {
    final pill = pillKey.currentContext?.findRenderObject();
    if (pill is! RenderBox || !pill.attached) {
      return Offset.zero & referenceBox.size;
    }
    return MatrixUtils.transformRect(
      pill.getTransformTo(referenceBox),
      Offset.zero & pill.size,
    );
  };
}

/// The average line's legend: a 1.5 px `[3, 3]` dashed stroke.
class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 6) {
      final end = x + 3 < size.width ? x + 3 : size.width;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
