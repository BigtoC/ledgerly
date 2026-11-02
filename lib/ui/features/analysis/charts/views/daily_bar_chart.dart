import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:intl/intl.dart';

import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/currency.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_state.dart';
import '../view_models/trend_series.dart';

/// Plot height of the trend chart, above its 1 px baseline.
const double _kPlotHeight = 140;

/// The x labels overlap the plot's bottom by this much (CSS margin-top −4).
const double _kLabelOverlap = 4;

/// On All, up to this many months fill the width; beyond it each bar keeps
/// this many months' width and the chart scrolls (plan D14).
const int _kAllFullWidthMonths = 24;

final Map<String, DateFormat> _weekdayFormats = {};
final Map<String, DateFormat> _monthFormats = {};
final Map<String, DateFormat> _yearFormats = {};
final Map<String, DateFormat> _yearMonthFormats = {};

/// The trend card's bars, average line and x labels.
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    super.key,
    required this.period,
    required this.series,
    required this.barColor,
    required this.locale,
    required this.currenciesByCode,
    this.displayCurrencyCode,
  });

  final PeriodType period;
  final TrendSeries series;

  /// Solid fill of every bar: the selected slice's colour, else the type's.
  final Color barColor;
  final String locale;
  final Map<String, Currency> currenciesByCode;
  final String? displayCurrencyCode;

  double get _gap => switch (period) {
    PeriodType.week => 10,
    PeriodType.year => 6,
    PeriodType.all => 4,
    PeriodType.day || PeriodType.month => 3,
  };

  (double top, double bottom) get _radii => switch (period) {
    PeriodType.week || PeriodType.year => (6, 2),
    PeriodType.day || PeriodType.month || PeriodType.all => (3, 1),
  };

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final buckets = series.buckets;
    final currency = displayCurrencyCode == null
        ? null
        : (currenciesByCode[displayCurrencyCode!] ??
              Currency(code: displayCurrencyCode!, decimals: 2));
    final maxBucket = buckets
        .map((b) => b.totalMinorUnits.abs())
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxBucket == 0 ? 1.0 : maxBucket * 1.12;
    // Value units per plot pixel.
    final perPixel = maxY / _kPlotHeight;
    final average = series.averageMinorUnits;
    final gap = _gap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final n = buckets.length;
        final scrolls = period == PeriodType.all && n > _kAllFullWidthMonths;
        final columns = scrolls ? _kAllFullWidthMonths : n;
        final rodWidth = (width - (columns - 1) * gap) / columns;
        // The labels overlap the plot's bottom; they ignore touches so the
        // plot's full height stays touchable.
        final chart = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _kPlotHeight + 1,
              child: Semantics(
                label: _semanticsLabel(l10n, currency),
                image: true,
                excludeSemantics: true,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceBetween,
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipColor: (_) =>
                            scheme.inverseSurface.withValues(alpha: 0.92),
                        getTooltipItem: (group, _, rod, rodIdx) {
                          final idx = group.x;
                          if (idx < 0 || idx >= buckets.length) return null;
                          final bucket = buckets[idx];
                          if (bucket.isFuture && bucket.totalMinorUnits == 0) {
                            return null;
                          }
                          return BarTooltipItem(
                            '${_bucketLabel(bucket.bucketStart)}\n',
                            TextStyle(
                              color: scheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            children: [
                              TextSpan(
                                text: _amount(bucket.totalMinorUnits, currency),
                                style: TextStyle(
                                  color: scheme.onInverseSurface,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(bottom: BorderSide(color: colors.line)),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (average > 0)
                          HorizontalLine(
                            // The CSS border's 1.5 px stroke sits on top of
                            // the average, so its centre is 0.75 px higher.
                            y: average + 0.75 * perPixel,
                            strokeWidth: 1.5,
                            color: colors.fg3,
                            dashArray: const [3, 3],
                          ),
                      ],
                    ),
                    barGroups: [
                      for (var i = 0; i < n; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            _rod(buckets[i], rodWidth, perPixel, colors),
                          ],
                        ),
                    ],
                  ),
                  duration: AnalysisMotion.emphasizedDuration,
                  curve: AnalysisMotion.emphasizedCurve,
                ),
              ),
            ),
            // Not positioned, so the labels set the layout's height.
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: _kPlotHeight + 1 - _kLabelOverlap,
                ),
                child: ExcludeSemantics(
                  child: _labels(colors, gap, keepEndsInside: scrolls),
                ),
              ),
            ),
          ],
        );
        if (!scrolls) return chart;
        // The plot, its average line and the labels scroll together; the y
        // scale and the average still cover every month.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Opens at the right end, on the current month.
          reverse: true,
          child: SizedBox(width: n * rodWidth + (n - 1) * gap, child: chart),
        );
      },
    );
  }

  BarChartRodData _rod(
    TrendBucket bucket,
    double width,
    double perPixel,
    AnalysisColors colors,
  ) {
    final value = bucket.totalMinorUnits.abs();
    if (value == 0) {
      if (!bucket.isFuture) {
        return BarChartRodData(toY: 0, width: width, color: barColor);
      }
      return BarChartRodData(
        toY: 3 * perPixel,
        width: width,
        color: colors.track,
        borderRadius: BorderRadius.circular(1.5),
      );
    }
    final (top, bottom) = _radii;
    final height = value / perPixel < 2 ? 2.0 : value / perPixel;
    // fl_chart stretches a bar to fit its corners; shrink the corners instead.
    final scale = height < top + bottom ? height / (top + bottom) : 1.0;
    return BarChartRodData(
      toY: height * perPixel,
      width: width,
      color: barColor,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(top * scale),
        bottom: Radius.circular(bottom * scale),
      ),
    );
  }

  /// With [keepEndsInside] (a scrolling chart, which clips at its edges),
  /// the first and last labels align to their bar's outer edge rather than
  /// its centre, so a label wider than its bar is not cut off.
  Widget _labels(
    AnalysisColors colors,
    double gap, {
    required bool keepEndsInside,
  }) {
    final buckets = series.buckets;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < buckets.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: series.labelIndices.contains(i)
                ? OverflowBox(
                    fit: OverflowBoxFit.deferToChild,
                    maxWidth: double.infinity,
                    alignment: !keepEndsInside
                        ? Alignment.center
                        : i == buckets.length - 1
                        ? Alignment.centerRight
                        : i == 0
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: Text(
                      series.yearLabelIndices.contains(i)
                          ? _yearFormats
                                .putIfAbsent(locale, () => DateFormat.y(locale))
                                .format(buckets[i].bucketStart)
                          : _axisLabel(buckets[i].bucketStart),
                      maxLines: 1,
                      softWrap: false,
                      style: analysisText(
                        size: 11,
                        lineHeight: 14,
                        weight: i == series.currentIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: i == series.currentIndex
                            ? colors.fg
                            : colors.fg3,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  String _amount(int minorUnits, Currency? currency) => currency == null
      ? minorUnits.toString()
      : MoneyFormatter.format(
          amountMinorUnits: minorUnits,
          currency: currency,
          locale: locale,
        );

  String _semanticsLabel(AppLocalizations l10n, Currency? currency) {
    final parts = <String>[l10n.chartsBarChart];
    for (final b in series.buckets) {
      if (b.totalMinorUnits == 0) continue;
      parts.add(
        '${_bucketLabel(b.bucketStart)}: '
        '${_amount(b.totalMinorUnits, currency)}',
      );
    }
    return parts.join('. ');
  }

  /// The tooltip and semantics name of a bucket: All spans years, so its
  /// months carry the year.
  String _bucketLabel(DateTime bucketStart) => period == PeriodType.all
      ? _yearMonthFormats
            .putIfAbsent(locale, () => DateFormat.yMMM(locale))
            .format(bucketStart)
      : _axisLabel(bucketStart);

  String _axisLabel(DateTime bucketStart) {
    switch (period) {
      case PeriodType.day:
        return bucketStart.hour.toString().padLeft(2, '0');
      case PeriodType.week:
        return _weekdayFormats
            .putIfAbsent(locale, () => DateFormat.E(locale))
            .format(bucketStart);
      case PeriodType.month:
        return bucketStart.day.toString();
      case PeriodType.year:
      case PeriodType.all:
        return _monthFormats
            .putIfAbsent(locale, () => DateFormat.MMM(locale))
            .format(bucketStart);
    }
  }
}
