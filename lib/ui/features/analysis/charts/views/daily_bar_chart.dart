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

const EdgeInsets _kTooltipPadding = EdgeInsets.symmetric(
  horizontal: 10,
  vertical: 6,
);

/// fl_chart's default; named so the tooltip can be measured the same way.
const double _kTooltipMaxContentWidth = 120;

final Map<String, DateFormat> _weekdayFormats = {};
final Map<String, DateFormat> _monthFormats = {};
final Map<String, DateFormat> _yearFormats = {};
final Map<String, DateFormat> _yearMonthFormats = {};

/// The trend card's bars, average line and x labels.
class DailyBarChart extends StatefulWidget {
  const DailyBarChart({
    super.key,
    required this.period,
    required this.series,
    required this.barColor,
    required this.locale,
    required this.currenciesByCode,
    this.displayCurrencyCode,
    this.edgeInset = 0,
  });

  final PeriodType period;
  final TrendSeries series;

  /// Solid fill of every bar: the selected slice's colour, else the type's.
  final Color barColor;
  final String locale;
  final Map<String, Currency> currenciesByCode;
  final String? displayCurrencyCode;

  /// The parent's horizontal padding on each side. A scrolling chart
  /// scrolls through it, so at either end its bars sit where an unscrolled
  /// chart's would and its edge labels stay centred under their bars.
  /// Touches in it do not reach the chart.
  final double edgeInset;

  @override
  State<DailyBarChart> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<DailyBarChart> {
  final _scroll = ScrollController();

  /// Shift of the touched bar's tooltip that keeps it inside a scrolling
  /// chart's viewport; 0 when it fits centred, and always for a chart that
  /// does not scroll (fl_chart keeps that one inside the plot).
  double _tooltipOffset = 0;

  PeriodType get period => widget.period;
  TrendSeries get series => widget.series;
  Color get barColor => widget.barColor;
  String get locale => widget.locale;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
    final code = widget.displayCurrencyCode;
    final currency = code == null
        ? null
        : (widget.currenciesByCode[code] ?? Currency(code: code, decimals: 2));
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
        final insets = scrolls
            ? _scrollInsets(context, rodWidth)
            : (left: 0.0, right: 0.0);
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
                        tooltipPadding: _kTooltipPadding,
                        maxContentWidth: _kTooltipMaxContentWidth,
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipHorizontalOffset: scrolls ? _tooltipOffset : 0,
                        getTooltipColor: (_) =>
                            scheme.inverseSurface.withValues(alpha: 0.92),
                        getTooltipItem: (group, _, rod, rodIdx) =>
                            _tooltipItem(group.x, scheme, currency),
                      ),
                      touchCallback: scrolls
                          ? (event, response) => _fitTooltip(
                              response?.spot?.touchedBarGroupIndex,
                              rodWidth,
                              gap,
                              insets,
                              scheme,
                              currency,
                            )
                          : null,
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
                child: ExcludeSemantics(child: _labels(colors, gap)),
              ),
            ),
          ],
        );
        if (!scrolls) return chart;
        // The plot, its average line and the labels scroll together; the y
        // scale and the average still cover every month. The viewport
        // reaches into the parent's padding on both sides.
        final viewport = width + 2 * widget.edgeInset;
        return OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          minWidth: viewport,
          maxWidth: viewport,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            // Opens at the right end, on the current month.
            reverse: true,
            padding: EdgeInsets.only(left: insets.left, right: insets.right),
            child: SizedBox(width: n * rodWidth + (n - 1) * gap, child: chart),
          ),
        );
      },
    );
  }

  /// Padding at each end of a scrolling chart's content: the parent's
  /// [DailyBarChart.edgeInset], or more where an end label overhangs its
  /// bar by more than that (at large text scales), so the label is never
  /// clipped.
  ({double left, double right}) _scrollInsets(
    BuildContext context,
    double rodWidth,
  ) {
    final last = series.buckets.length - 1;
    double inset(int i) {
      if (!series.labelIndices.contains(i)) return widget.edgeInset;
      final painter = TextPainter(
        text: TextSpan(
          text: _labelText(i),
          style: DefaultTextStyle.of(context).style
              .merge(_labelStyle(AnalysisColors.of(context), i)),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final overhang = (painter.width - rodWidth) / 2;
      painter.dispose();
      return overhang > widget.edgeInset ? overhang : widget.edgeInset;
    }

    return (left: inset(0), right: inset(last));
  }

  BarTooltipItem? _tooltipItem(
    int idx,
    ColorScheme scheme,
    Currency? currency,
  ) {
    final buckets = series.buckets;
    if (idx < 0 || idx >= buckets.length) return null;
    final bucket = buckets[idx];
    if (bucket.isFuture && bucket.totalMinorUnits == 0) return null;
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
  }

  /// On a touch of bar [index] in a scrolling chart, shifts its tooltip by
  /// the least amount that keeps it inside the viewport, which clips it;
  /// fl_chart only keeps it inside the whole, wider plot.
  void _fitTooltip(
    int? index,
    double rodWidth,
    double gap,
    ({double left, double right}) insets,
    ColorScheme scheme,
    Currency? currency,
  ) {
    if (index == null || !_scroll.hasClients) return;
    final item = _tooltipItem(index, scheme, currency);
    if (item == null) return;
    final painter = TextPainter(
      text: TextSpan(
        style: _tooltipTextStyle(item.textStyle),
        text: item.text,
        children: item.children,
      ),
      textAlign: item.textAlign,
      textDirection: item.textDirection,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: _kTooltipMaxContentWidth);
    final tooltipWidth = painter.width + _kTooltipPadding.horizontal;
    painter.dispose();

    // The viewport in plot coordinates. Reversed, offset 0 is the right
    // end.
    final position = _scroll.position;
    final plotWidth =
        series.buckets.length * rodWidth + (series.buckets.length - 1) * gap;
    final contentWidth = insets.left + plotWidth + insets.right;
    final visibleLeft =
        contentWidth -
        position.viewportDimension -
        position.pixels -
        insets.left;
    final visibleRight = visibleLeft + position.viewportDimension;

    final centre = index * (rodWidth + gap) + rodWidth / 2;
    final left = centre - tooltipWidth / 2;
    final right = centre + tooltipWidth / 2;
    final offset = left < visibleLeft
        ? visibleLeft - left
        : right > visibleRight
        ? visibleRight - right
        : 0.0;
    if (offset != _tooltipOffset) setState(() => _tooltipOffset = offset);
  }

  /// The tooltip text style as fl_chart resolves it before measuring.
  TextStyle _tooltipTextStyle(TextStyle? style) {
    var resolved = style == null || style.inherit
        ? DefaultTextStyle.of(context).style.merge(style)
        : style;
    if (MediaQuery.boldTextOf(context)) {
      resolved = resolved.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    return resolved;
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

  Widget _labels(AnalysisColors colors, double gap) {
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
                    child: Text(
                      _labelText(i),
                      maxLines: 1,
                      softWrap: false,
                      style: _labelStyle(colors, i),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  String _labelText(int i) {
    final start = series.buckets[i].bucketStart;
    return series.yearLabelIndices.contains(i)
        ? _yearFormats
              .putIfAbsent(locale, () => DateFormat.y(locale))
              .format(start)
        : _axisLabel(start);
  }

  TextStyle _labelStyle(AnalysisColors colors, int i) => analysisText(
    size: 11,
    lineHeight: 14,
    weight: i == series.currentIndex ? FontWeight.w700 : FontWeight.w400,
    color: i == series.currentIndex ? colors.fg : colors.fg3,
  );

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
