import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_bucket_slice.freezed.dart';

/// Local-time bucket granularity selected by the chart period:
/// - `day`  — Day, Week and Month views
/// - `month` — Year view (12 buckets)
enum TimeBucketGranularity { day, month }

/// Per-(bucketStart, currency) subtotal emitted by
/// `TransactionRepository.watchTimeBucketsInRange`. Conversion happens
/// before regrouping into final `ChartBucketTotal`s — so currencies are
/// preserved here, not collapsed.
@freezed
abstract class TimeBucketSlice with _$TimeBucketSlice {
  const factory TimeBucketSlice({
    required DateTime bucketStart,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _TimeBucketSlice;
}
