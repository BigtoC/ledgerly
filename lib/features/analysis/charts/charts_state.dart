// Chart slice state — see
// `docs/superpowers/specs/2026-05-18-basic-charts-design.md` § Controller
// & State and `docs/superpowers/plans/2026-05-19-basic-charts.md`.
//
// `ChartsLoading.previous` and `ChartsBlockedByMissingRates.previous`
// carry the prior `ChartsData` so the UI can keep rendering the previous
// chart body under a spinner or banner without remounting controls.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/category.dart' show CategoryType;

part 'charts_state.freezed.dart';

/// Active chart period — drives both the period selector label and the
/// repository range / bar-chart granularity.
enum PeriodType { day, week, month, year }

/// Pie/bar grouping axis. Toggled via the dimension chips.
enum ChartDimension { category, account, currency }

@freezed
sealed class ChartsState with _$ChartsState {
  /// Pre-first-emission. Renders chart-sized loading shimmer beneath the
  /// (already-mounted) control row.
  const factory ChartsState.idle() = ChartsIdle;

  /// New range/dimension/type subscribed; previous data (if any) is kept
  /// visible while the new payload lands. `previous == null` means cold
  /// start.
  const factory ChartsState.loading({ChartsData? previous}) = ChartsLoading;

  /// Latest converted-and-grouped payload.
  const factory ChartsState.data({required ChartsData chartData}) =
      ChartsDataState;

  /// Range has no transactions matching the active type. Shows the
  /// `chartsNoData` copy under the controls.
  const factory ChartsState.empty() = ChartsEmpty;

  /// FX rates missing for category/account dimensions. Keeps the prior
  /// chart visible if any, plus the rates-required banner. See spec
  /// § Empty States.
  const factory ChartsState.blockedByMissingRates({ChartsData? previous}) =
      ChartsBlockedByMissingRates;

  /// Stream error path. Controls stay mounted; chart body shows error +
  /// retry.
  const factory ChartsState.error(Object error, StackTrace stack) = ChartsError;
}

@freezed
abstract class ChartsData with _$ChartsData {
  const factory ChartsData({
    required PeriodType period,
    required DateTime anchorDate,
    required CategoryType type,
    required ChartDimension dimension,
    required List<ChartSlice> slices,
    required List<ChartBucketTotal> bucketTotals,

    /// Only set when every active subtotal is comparable in one
    /// display currency. Null in currency-view-with-mixed-rates.
    required int? grandTotalMinorUnits,

    /// Set when slices are unified into one display currency. Null when
    /// each slice keeps its own `currencyCode` (currency dimension with
    /// missing rates).
    required String? displayCurrencyCode,
    @Default(false) bool mixedCurrencies,

    /// True when Task 12's cold-start fallback auto-switched the active
    /// dimension from `category` to `currency` because category view was
    /// blocked by missing FX rates. `ChartsSection` reads this flag to
    /// render an explanatory banner above the chart body. Cleared when
    /// the user manually changes dimension or dismisses the banner.
    @Default(false) bool autoSwitchedFromCategoryDimension,

    /// Currency codes whose subtotals were dropped from this chart
    /// because their FX rate was missing at emit time. Empty in the
    /// all-rates-present case. When non-empty, `ChartsSection` renders
    /// a ribbon listing them above the chart body. Category/account
    /// dimension only — currency dimension shows source amounts inline.
    @Default(<String>[]) List<String> excludedCurrencyCodes,
  }) = _ChartsData;
}

@freezed
abstract class ChartSlice with _$ChartSlice {
  const factory ChartSlice({
    /// Resolved display label (category name, account name, or currency
    /// code). The controller resolves labels so widgets stay pure.
    required String label,

    /// Currency to format `totalMinorUnits` in. Equals
    /// `ChartsData.displayCurrencyCode` for converted slices; equals the
    /// source currency for currency-view-mixed slices.
    required String currencyCode,
    required int totalMinorUnits,

    /// `0.0–1.0` when `ChartsData.grandTotalMinorUnits != null`,
    /// otherwise null (hide percentage label).
    double? fraction,

    /// Index into `core/utils/color_palette.dart`.
    required int colorIndex,

    /// `core/utils/icon_registry.dart` key for legend icon. Empty string
    /// for currency-dimension slices.
    required String iconKey,
  }) = _ChartSlice;
}

@freezed
abstract class ChartBucketTotal with _$ChartBucketTotal {
  const factory ChartBucketTotal({
    required DateTime bucketStart,
    required int totalMinorUnits,
  }) = _ChartBucketTotal;
}
