import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/trend_series.dart';

ChartBucketTotal _b(DateTime start, int total) =>
    ChartBucketTotal(bucketStart: start, totalMinorUnits: total);

void main() {
  group('zero-fill', () {
    test('week fills 7 days from the anchor', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 10, 26),
        bucketTotals: [_b(DateTime(2026, 10, 28), 500)],
        now: DateTime(2026, 12, 1),
      );

      expect(s.buckets.map((b) => b.bucketStart), [
        for (var d = 0; d < 7; d++) DateTime(2026, 10, 26 + d),
      ]);
      expect(s.buckets.map((b) => b.totalMinorUnits), [0, 0, 500, 0, 0, 0, 0]);
    });

    test('month fills every day of the month', () {
      final s = trendSeries(
        period: PeriodType.month,
        anchorDate: DateTime(2026, 2, 1),
        bucketTotals: [_b(DateTime(2026, 2, 28), 900)],
        now: DateTime(2026, 12, 1),
      );

      expect(s.buckets, hasLength(28));
      expect(s.buckets.first.bucketStart, DateTime(2026, 2, 1));
      expect(s.buckets.last.bucketStart, DateTime(2026, 2, 28));
      expect(s.buckets.last.totalMinorUnits, 900);
    });

    test('year fills 12 months', () {
      final s = trendSeries(
        period: PeriodType.year,
        anchorDate: DateTime(2026, 1, 1),
        bucketTotals: [_b(DateTime(2026, 3, 1), 700)],
        now: DateTime(2027, 6, 1),
      );

      expect(s.buckets.map((b) => b.bucketStart), [
        for (var m = 1; m <= 12; m++) DateTime(2026, m, 1),
      ]);
      expect(s.buckets[2].totalMinorUnits, 700);
    });
  });

  group('elapsed vs future', () {
    test('a bucket is future when it starts after now', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 10, 26),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31, 15),
      );

      expect(s.buckets.map((b) => b.isFuture), [
        false,
        false,
        false,
        false,
        false,
        false,
        true,
      ]);
    });

    test('a past period has no future buckets', () {
      final s = trendSeries(
        period: PeriodType.year,
        anchorDate: DateTime(2025, 1, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31),
      );

      expect(s.buckets.any((b) => b.isFuture), isFalse);
    });
  });

  group('average', () {
    test('is the sum of elapsed buckets divided by the elapsed count', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 10, 26),
        bucketTotals: [
          _b(DateTime(2026, 10, 26), 300),
          _b(DateTime(2026, 10, 28), 600),
        ],
        // Wednesday: Mon, Tue, Wed elapsed.
        now: DateTime(2026, 10, 28, 9),
      );

      expect(s.averageMinorUnits, 300);
    });

    test('excludes future buckets even when they hold an amount', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 10, 26),
        bucketTotals: [
          _b(DateTime(2026, 10, 26), 400),
          _b(DateTime(2026, 11, 1), 10000),
        ],
        now: DateTime(2026, 10, 27, 9),
      );

      expect(s.buckets.last.isFuture, isTrue);
      expect(s.buckets.last.totalMinorUnits, 10000);
      expect(s.averageMinorUnits, 200);
    });

    test('is 0 when no bucket has elapsed', () {
      final s = trendSeries(
        period: PeriodType.month,
        anchorDate: DateTime(2027, 1, 1),
        bucketTotals: [_b(DateTime(2027, 1, 5), 500)],
        now: DateTime(2026, 10, 31),
      );

      expect(s.averageMinorUnits, 0);
    });
  });

  group('current index', () {
    test('points at the bucket holding now in the current period', () {
      final s = trendSeries(
        period: PeriodType.month,
        anchorDate: DateTime(2026, 10, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31, 23),
      );

      expect(s.currentIndex, 30);
    });

    test('is the current month in the current year', () {
      final s = trendSeries(
        period: PeriodType.year,
        anchorDate: DateTime(2026, 1, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 2),
      );

      expect(s.currentIndex, 9);
    });

    test('is null for a past period', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 10, 19),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31),
      );

      expect(s.currentIndex, isNull);
    });

    test('is null for a future period', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 11, 2),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31),
      );

      expect(s.currentIndex, isNull);
    });
  });

  group('x labels', () {
    test('week labels all 7 days', () {
      final s = trendSeries(
        period: PeriodType.week,
        anchorDate: DateTime(2026, 10, 26),
        bucketTotals: const [],
        now: DateTime(2026, 12, 1),
      );

      expect(s.labelIndices, {0, 1, 2, 3, 4, 5, 6});
    });

    test('year labels all 12 months', () {
      final s = trendSeries(
        period: PeriodType.year,
        anchorDate: DateTime(2025, 1, 1),
        bucketTotals: const [],
        now: DateTime(2026, 12, 1),
      );

      expect(s.labelIndices, {for (var i = 0; i < 12; i++) i});
    });

    test('a past month labels days 1, 8, 15, 22 and 29', () {
      final s = trendSeries(
        period: PeriodType.month,
        anchorDate: DateTime(2026, 9, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31),
      );

      expect(s.labelIndices, {0, 7, 14, 21, 28});
    });

    test('the current month also labels today', () {
      final s = trendSeries(
        period: PeriodType.month,
        anchorDate: DateTime(2026, 10, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31, 8),
      );

      expect(s.labelIndices, {0, 7, 14, 21, 28, 30});
    });

    test('February without day 29 skips that label', () {
      final s = trendSeries(
        period: PeriodType.month,
        anchorDate: DateTime(2026, 2, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31),
      );

      expect(s.labelIndices, {0, 7, 14, 21});
    });
  });

  group('All (monthly, from the first month to now)', () {
    test('one bucket per month from the anchor month to the current month, '
        'none future', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2024, 8, 1),
        bucketTotals: [
          _b(DateTime(2024, 8, 1), 100),
          _b(DateTime(2026, 5, 1), 300),
        ],
        now: DateTime(2026, 5, 31, 15),
      );

      expect(s.buckets, hasLength(22));
      expect(s.buckets.first.bucketStart, DateTime(2024, 8, 1));
      expect(s.buckets.last.bucketStart, DateTime(2026, 5, 1));
      expect(s.buckets.first.totalMinorUnits, 100);
      expect(s.buckets.last.totalMinorUnits, 300);
      expect(s.buckets.where((b) => b.isFuture), isEmpty);
      expect(s.currentIndex, 21);
    });

    test('average per month over every month (D8 unchanged)', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2026, 7, 1),
        bucketTotals: [
          _b(DateTime(2026, 7, 1), 400),
          _b(DateTime(2026, 9, 1), 800),
        ],
        now: DateTime(2026, 10, 2),
      );

      expect(s.averageMinorUnits, 300);
    });

    test('labels: the year under each January, the month name under the '
        'last bar', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2024, 1, 1),
        bucketTotals: const [],
        now: DateTime(2025, 9, 30),
      );

      expect(s.labelIndices, {0, 12, 20});
      expect(s.yearLabelIndices, {0, 12});
    });

    test('a first month that is not January gets no year label (D15)', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2024, 6, 1),
        bucketTotals: const [],
        now: DateTime(2026, 3, 10),
      );

      expect(s.buckets, hasLength(22));
      expect(s.labelIndices, {7, 19, 21});
      expect(s.yearLabelIndices, {7, 19});
    });

    test('when the current month is January the last bar shows the month '
        'name, not the year (D15)', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2025, 3, 1),
        bucketTotals: const [],
        now: DateTime(2027, 1, 5),
      );

      expect(s.buckets.last.bucketStart, DateTime(2027, 1, 1));
      expect(s.labelIndices, {10, 22});
      expect(s.yearLabelIndices, {10});
      expect(s.currentIndex, 22);
    });

    test('a single month that is January shows only its month name', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2026, 1, 1),
        bucketTotals: [_b(DateTime(2026, 1, 1), 5)],
        now: DateTime(2026, 1, 20),
      );

      expect(s.buckets, hasLength(1));
      expect(s.labelIndices, {0});
      expect(s.yearLabelIndices, isEmpty);
      expect(s.currentIndex, 0);
    });

    test('more than 24 months keep one bucket per month', () {
      final s = trendSeries(
        period: PeriodType.all,
        anchorDate: DateTime(2024, 4, 1),
        bucketTotals: const [],
        now: DateTime(2026, 10, 31),
      );

      expect(s.buckets, hasLength(31));
      expect(s.yearLabelIndices, {9, 21});
      expect(s.labelIndices, {9, 21, 30});
    });

    test('other periods have no year labels', () {
      for (final period in [
        PeriodType.week,
        PeriodType.month,
        PeriodType.year,
      ]) {
        final s = trendSeries(
          period: period,
          anchorDate: DateTime(2026, 1, 1),
          bucketTotals: const [],
          now: DateTime(2026, 10, 31),
        );
        expect(s.yearLabelIndices, isEmpty, reason: '$period');
      }
    });
  });
}
