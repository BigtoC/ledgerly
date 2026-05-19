import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class DailyBarChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final filledBuckets = _zeroFill(anchorDate, period, bucketTotals);
    final maxY = filledBuckets
        .map((b) => b.totalMinorUnits.abs())
        .fold<int>(0, (a, b) => a > b ? a : b);
    final headroom = (maxY * 1.1).round();
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: _semanticsLabel(l10n, filledBuckets),
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.6,
        child: BarChart(
          BarChartData(
            maxY: headroom == 0 ? 1 : headroom.toDouble(),
            barTouchData: BarTouchData(enabled: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
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
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= filledBuckets.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _axisLabel(filledBuckets[idx].bucketStart),
                        style: const TextStyle(fontSize: 10),
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
                      color: filledBuckets[i].bucketStart.isAfter(now)
                          ? color.withValues(alpha: 0.3)
                          : color,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(
    AppLocalizations l10n,
    List<ChartBucketTotal> filledBuckets,
  ) {
    final parts = <String>[l10n.chartsBarChart];
    final currency = displayCurrencyCode == null
        ? null
        : (currenciesByCode[displayCurrencyCode!] ??
              Currency(code: displayCurrencyCode!, decimals: 2));
    for (final b in filledBuckets) {
      if (b.totalMinorUnits == 0) continue;
      final amount = currency == null
          ? b.totalMinorUnits.toString()
          : MoneyFormatter.format(
              amountMinorUnits: b.totalMinorUnits,
              currency: currency,
              locale: locale,
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
    switch (period) {
      case PeriodType.day:
        return bucketStart.hour.toString().padLeft(2, '0');
      case PeriodType.week:
        return DateFormat.E(locale).format(bucketStart);
      case PeriodType.month:
        return bucketStart.day.toString();
      case PeriodType.year:
        return DateFormat.MMM(locale).format(bucketStart);
    }
  }
}
