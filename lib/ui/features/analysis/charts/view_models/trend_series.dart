// Pure trend-card series: the zero-filled buckets of a period plus what the
// card derives from them (future flags, average, current bucket, x labels).
// See `docs/superpowers/specs/2026-11-02-analysis-redesign-design.md` § 7.

import 'charts_state.dart';

/// One bar of the trend chart.
class const TrendBucket({
  required final DateTime bucketStart,
  required final int totalMinorUnits,

  /// The bucket starts after now.
  required final bool isFuture,
});

class const TrendSeries({
  required final List<TrendBucket> buckets,

  /// Sum of the elapsed buckets ÷ their count; future buckets are left out
  /// even when they hold an amount. 0 when nothing has elapsed.
  required final double averageMinorUnits,

  /// The bucket holding now, only when the period is the current one.
  required final int? currentIndex,

  /// Buckets that get an x label.
  required final Set<int> labelIndices,

  /// The [labelIndices] whose label is the year rather than the bucket's
  /// own label: each January on All, except the current month (D15).
  required final Set<int> yearLabelIndices,
});

/// Month labels sit under days 1, 8, 15, 22 and 29 (plus today).
const _kMonthLabelIndices = [0, 7, 14, 21, 28];

TrendSeries trendSeries({
  required PeriodType period,
  required DateTime anchorDate,
  required List<ChartBucketTotal> bucketTotals,
  required DateTime now,
}) {
  final starts = _bucketStarts(period, anchorDate, now);
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
  final end = _periodEnd(period, anchorDate, now);
  final isCurrent = elapsed.isNotEmpty && now.isBefore(end);
  final currentIndex = isCurrent ? elapsed.length - 1 : null;
  // All: the year under each January; the current month's own label wins.
  final yearLabelIndices = period == PeriodType.all
      ? {
          for (var i = 0; i < buckets.length; i++)
            if (buckets[i].bucketStart.month == 1 && i != currentIndex) i,
        }
      : const <int>{};
  final labelIndices = switch (period) {
    PeriodType.month => {
      ..._kMonthLabelIndices.where((i) => i < buckets.length),
      ?currentIndex,
    },
    PeriodType.all => {...yearLabelIndices, ?currentIndex},
    _ => {for (var i = 0; i < buckets.length; i++) i},
  };
  return TrendSeries(
    buckets: buckets,
    averageMinorUnits: elapsed.isEmpty ? 0 : sum / elapsed.length,
    currentIndex: currentIndex,
    labelIndices: labelIndices,
    yearLabelIndices: yearLabelIndices,
  );
}

List<DateTime> _bucketStarts(PeriodType period, DateTime anchor, DateTime now) {
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
    // One month per bucket, from the anchor's month to now's.
    case PeriodType.all:
      final count =
          (now.year - anchor.year) * 12 + now.month - anchor.month + 1;
      return [
        for (var m = 0; m < count; m++)
          DateTime(anchor.year, anchor.month + m, 1),
      ];
  }
}

DateTime _periodEnd(PeriodType period, DateTime anchor, DateTime now) =>
    switch (period) {
      PeriodType.day => DateTime(anchor.year, anchor.month, anchor.day + 1),
      PeriodType.week => DateTime(anchor.year, anchor.month, anchor.day + 7),
      PeriodType.month => DateTime(anchor.year, anchor.month + 1, 1),
      PeriodType.year => DateTime(anchor.year + 1, 1, 1),
      PeriodType.all => DateTime(now.year, now.month + 1, 1),
    };
