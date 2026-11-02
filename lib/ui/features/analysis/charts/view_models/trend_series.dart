// Pure trend-card series: the zero-filled buckets of a period plus what the
// card derives from them (future flags, average, current bucket, x labels).
// See `docs/superpowers/specs/2026-11-02-analysis-redesign-design.md` § 7.

import 'charts_state.dart';

/// One bar of the trend chart.
class TrendBucket {
  const TrendBucket({
    required this.bucketStart,
    required this.totalMinorUnits,
    required this.isFuture,
  });

  final DateTime bucketStart;
  final int totalMinorUnits;

  /// The bucket starts after now.
  final bool isFuture;
}

class TrendSeries {
  const TrendSeries({
    required this.buckets,
    required this.elapsedCount,
    required this.averageMinorUnits,
    required this.currentIndex,
    required this.labelIndices,
  });

  final List<TrendBucket> buckets;

  /// Buckets that are not future.
  final int elapsedCount;

  /// Sum of the elapsed buckets ÷ [elapsedCount]; future buckets are left
  /// out even when they hold an amount. 0 when nothing has elapsed.
  final double averageMinorUnits;

  /// The bucket holding now, only when the period is the current one.
  final int? currentIndex;

  /// Buckets that get an x label.
  final Set<int> labelIndices;
}

/// Month labels sit under days 1, 8, 15, 22 and 29 (plus today).
const _kMonthLabelIndices = [0, 7, 14, 21, 28];

TrendSeries trendSeries({
  required PeriodType period,
  required DateTime anchorDate,
  required List<ChartBucketTotal> bucketTotals,
  required DateTime now,
}) {
  final starts = _bucketStarts(period, anchorDate);
  final totals = {
    for (final b in bucketTotals) b.bucketStart: b.totalMinorUnits,
  };
  final buckets = [
    for (final start in starts)
      TrendBucket(
        bucketStart: start,
        totalMinorUnits: totals[start] ?? 0,
        isFuture: start.isAfter(now),
      ),
  ];
  final elapsed = buckets.where((b) => !b.isFuture).toList();
  final sum = elapsed.fold<int>(0, (a, b) => a + b.totalMinorUnits);
  final end = _periodEnd(period, anchorDate);
  final isCurrent = elapsed.isNotEmpty && now.isBefore(end);
  final currentIndex = isCurrent ? elapsed.length - 1 : null;
  final labelIndices = switch (period) {
    PeriodType.month => {
      ..._kMonthLabelIndices.where((i) => i < buckets.length),
      ?currentIndex,
    },
    _ => {for (var i = 0; i < buckets.length; i++) i},
  };
  return TrendSeries(
    buckets: buckets,
    elapsedCount: elapsed.length,
    averageMinorUnits: elapsed.isEmpty ? 0 : sum / elapsed.length,
    currentIndex: currentIndex,
    labelIndices: labelIndices,
  );
}

List<DateTime> _bucketStarts(PeriodType period, DateTime anchor) {
  switch (period) {
    // The trend card never shows on Day.
    case PeriodType.day:
      return const [];
    case PeriodType.week:
      return [
        for (var d = 0; d < 7; d++)
          DateTime(anchor.year, anchor.month, anchor.day + d),
      ];
    case PeriodType.month:
      final days = DateTime(anchor.year, anchor.month + 1, 0).day;
      return [
        for (var d = 1; d <= days; d++) DateTime(anchor.year, anchor.month, d),
      ];
    case PeriodType.year:
      return [for (var m = 1; m <= 12; m++) DateTime(anchor.year, m, 1)];
  }
}

DateTime _periodEnd(PeriodType period, DateTime anchor) => switch (period) {
  PeriodType.day => DateTime(anchor.year, anchor.month, anchor.day + 1),
  PeriodType.week => DateTime(anchor.year, anchor.month, anchor.day + 7),
  PeriodType.month => DateTime(anchor.year, anchor.month + 1, 1),
  PeriodType.year => DateTime(anchor.year + 1, 1, 1),
};
