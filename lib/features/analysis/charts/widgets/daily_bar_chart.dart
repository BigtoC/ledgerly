import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class DailyBarChart extends StatefulWidget {
  const DailyBarChart({
    super.key,
    required this.period,
    required this.anchorDate,
    required this.bucketTotals,
    required this.locale,
    required this.currenciesByCode,
    this.displayCurrencyCode,
  });

  final PeriodType period;
  final DateTime anchorDate;
  final List<ChartBucketTotal> bucketTotals;
  final String locale;
  final Map<String, Currency> currenciesByCode;
  final String? displayCurrencyCode;

  @override
  State<DailyBarChart> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<DailyBarChart> {
  int? _touchedIndex;

  @override
  void didUpdateWidget(covariant DailyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drop the highlight when the bucket set changes — the previously
    // touched index points at a different time bucket after a period or
    // dimension swap and would mislead the reader.
    if (oldWidget.period != widget.period ||
        oldWidget.anchorDate != widget.anchorDate ||
        oldWidget.bucketTotals.length != widget.bucketTotals.length) {
      _touchedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final filledBuckets = _zeroFill(
      widget.anchorDate,
      widget.period,
      widget.bucketTotals,
    );
    final maxY = filledBuckets
        .map((b) => b.totalMinorUnits.abs())
        .fold<int>(0, (a, b) => a > b ? a : b);
    final headroom = (maxY * 1.1).round();
    final l10n = AppLocalizations.of(context);
    final currency = widget.displayCurrencyCode == null
        ? null
        : (widget.currenciesByCode[widget.displayCurrencyCode!] ??
              Currency(code: widget.displayCurrencyCode!, decimals: 2));

    final gradientBottom =
        Color.lerp(scheme.primary, Colors.black, 0.2) ?? scheme.primary;
    final gradientTop = scheme.secondary;
    final barsGradient = LinearGradient(
      colors: [gradientBottom, gradientTop],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
    final futureGradient = LinearGradient(
      colors: [
        gradientBottom.withValues(alpha: 0.3),
        gradientTop.withValues(alpha: 0.3),
      ],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    return Semantics(
      label: _semanticsLabel(l10n, filledBuckets),
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.6,
        child: BarChart(
          BarChartData(
            maxY: headroom == 0 ? 1 : headroom.toDouble(),
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedRadius: 8,
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
                  if (idx < 0 || idx >= filledBuckets.length) return null;
                  final bucket = filledBuckets[idx];
                  final amount = currency == null
                      ? bucket.totalMinorUnits.toString()
                      : MoneyFormatter.format(
                          amountMinorUnits: bucket.totalMinorUnits,
                          currency: currency,
                          locale: widget.locale,
                        );
                  final label = _axisLabel(bucket.bucketStart);
                  return BarTooltipItem(
                    '$label\n',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: amount,
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
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.spot == null) {
                  setState(() => _touchedIndex = null);
                  return;
                }
                setState(
                  () => _touchedIndex = response.spot!.touchedBarGroupIndex,
                );
              },
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= filledBuckets.length) {
                      return const SizedBox.shrink();
                    }
                    final selected = idx == _touchedIndex;
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(
                        _axisLabel(filledBuckets[idx].bucketStart),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? gradientTop
                              : gradientBottom.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < filledBuckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: filledBuckets[i].totalMinorUnits.abs().toDouble(),
                      gradient: filledBuckets[i].bucketStart.isAfter(now)
                          ? futureGradient
                          : barsGradient,
                      width: i == _touchedIndex ? 14 : 10,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuad,
        ),
      ),
    );
  }

  String _semanticsLabel(
    AppLocalizations l10n,
    List<ChartBucketTotal> filledBuckets,
  ) {
    final parts = <String>[l10n.chartsBarChart];
    final currency = widget.displayCurrencyCode == null
        ? null
        : (widget.currenciesByCode[widget.displayCurrencyCode!] ??
              Currency(code: widget.displayCurrencyCode!, decimals: 2));
    for (final b in filledBuckets) {
      if (b.totalMinorUnits == 0) continue;
      final amount = currency == null
          ? b.totalMinorUnits.toString()
          : MoneyFormatter.format(
              amountMinorUnits: b.totalMinorUnits,
              currency: currency,
              locale: widget.locale,
            );
      parts.add('${_axisLabel(b.bucketStart)}: $amount');
    }
    return parts.join('. ');
  }

  List<ChartBucketTotal> _zeroFill(
    DateTime anchor,
    PeriodType period,
    List<ChartBucketTotal> raw,
  ) {
    final map = {for (final b in raw) b.bucketStart: b.totalMinorUnits};
    final out = <ChartBucketTotal>[];
    switch (period) {
      case PeriodType.day:
        for (var h = 0; h < 24; h++) {
          final ts = DateTime(anchor.year, anchor.month, anchor.day, h);
          out.add(
            ChartBucketTotal(bucketStart: ts, totalMinorUnits: map[ts] ?? 0),
          );
        }
      case PeriodType.week:
        for (var d = 0; d < 7; d++) {
          final ts = DateTime(anchor.year, anchor.month, anchor.day + d);
          out.add(
            ChartBucketTotal(bucketStart: ts, totalMinorUnits: map[ts] ?? 0),
          );
        }
      case PeriodType.month:
        var cursor = DateTime(anchor.year, anchor.month, 1);
        while (cursor.month == anchor.month) {
          out.add(
            ChartBucketTotal(
              bucketStart: cursor,
              totalMinorUnits: map[cursor] ?? 0,
            ),
          );
          cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
        }
      case PeriodType.year:
        for (var m = 1; m <= 12; m++) {
          final ts = DateTime(anchor.year, m, 1);
          out.add(
            ChartBucketTotal(bucketStart: ts, totalMinorUnits: map[ts] ?? 0),
          );
        }
    }
    return out;
  }

  String _axisLabel(DateTime bucketStart) {
    switch (widget.period) {
      case PeriodType.day:
        return bucketStart.hour.toString().padLeft(2, '0');
      case PeriodType.week:
        return DateFormat.E(widget.locale).format(bucketStart);
      case PeriodType.month:
        return bucketStart.day.toString();
      case PeriodType.year:
        return DateFormat.MMM(widget.locale).format(bucketStart);
    }
  }
}
