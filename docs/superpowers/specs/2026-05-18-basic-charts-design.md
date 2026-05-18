# Basic Charts — Design Spec

**Status:** Approved
**Date:** 2026-05-18
**Feature:** Phase 2 — Basic charts (pie, bar) on the Analysis tab

---

## Overview

Add spending/income charts to the Analysis tab. A pie chart shows category/account/currency breakdowns for the selected period; a bar chart shows hour/day/month totals depending on that period. The existing memo search remains the primary entry point, and charts render as the default secondary view when no search query is active.

**Scope:**
- Pie chart by category, account, or currency (user toggle)
- Periods: day, week, month, year with prev/next navigation; default = week
- Bar chart: hourly bars in day view, daily bars in week and month views, monthly bars in year view
- Expense/income toggle
- Multi-currency auto-conversion when exchange rates are available
- Background warm-up of the default weekly charts after the initial FX snapshot / refresh attempt completes
- View-only charts; memo search remains the primary actionable workflow

**Out of scope:**
- Drill-down navigation from chart segments
- Budget overlay on charts
- Custom date range picker
- Export/share chart images

---

## Data Layer

### New Repository Methods

Four new methods on `TransactionRepository`, all using generic date-range parameters to serve day/week/month/year views.

```dart
/// Per-category subtotal in [start, end) filtered by type.
/// Emits one row per (category, currency) pair so conversion happens before
/// regrouping.
Stream<List<CategorySlice>> watchByCategoryInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
});

/// Per-account subtotal in [start, end) filtered by type.
/// Emits one row per (account, currency) pair so conversion happens before
/// regrouping.
Stream<List<AccountSlice>> watchByAccountInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
});

/// Per-currency total for transactions in [start, end) filtered by type.
Stream<List<CurrencySlice>> watchByCurrencyInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
});

/// Per local-time bucket subtotal in [start, end) filtered by type.
/// `granularity`: hour (day view), day (week/month views), month (year view).
/// Emits one row per (bucketStart, currency) pair.
Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
  required TimeBucketGranularity granularity,
});
```

### DAO Query Surface

`TransactionDao` adds four chart-specific query methods:

```dart
Stream<List<CategoryChartRow>> watchCategoryTotalsInRange(...);
Stream<List<AccountChartRow>> watchAccountTotalsInRange(...);
Stream<List<CurrencyChartRow>> watchCurrencyTotalsInRange(...);
Stream<List<TransactionChartRow>> watchChartRowsInRange(...);
```

`watchChartRowsInRange(...)` is the raw row stream used for local-time bucket regrouping in week/month/day/year bar charts.

Each method:
- Joins `transactions` with `categories` to filter by `categories.type`
- `watchByCategoryInRange` groups by `(category_id, currency)`
- `watchByAccountInRange` groups by `(account_id, currency)`
- `watchByCurrencyInRange` groups by `currency`
- `watchTimeBucketsInRange` returns one subtotal per `(bucketStart, currency)` so the controller can convert per currency and regroup by bucket
- Sums `amount_minor_units` (integer minor units, never doubles)
- Returns a `Stream` backed by Drift's `.watch()` for reactive updates
- Uses device-local `DateHelpers` boundaries for every range and bucket calculation

**Period boundaries:**
- Day view: `[startOfDay, startOfNextDay)`
- Week view: `[startOfWeek, startOfNextWeek)` using Monday-start local weeks
- Month view: `[startOfMonth, startOfNextMonth)`
- Year view: `[startOfYear, startOfNextYear)`
- Add `DateHelpers.startOfWeek`, `startOfMonth`, and `startOfYear` alongside the existing `startOfDay` helper so boundaries and chart buckets share the same device-local semantics

### Query / Bucketing Examples

**Category aggregation (preserve source currency):**
```sql
SELECT t.category_id, t.currency, SUM(t.amount_minor_units) AS total
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.date >= ? AND t.date < ? AND c.type = ?
GROUP BY t.category_id, t.currency
```

**Time-bucket aggregation (repository-side local bucketing):**
```dart
final rows = dao.watchChartRowsInRange(
  start: start,
  end: end,
  type: type,
);

// Do not use bare `date(t.date)`.
// Bucket with the same local-time helpers used for period boundaries.
final bucketStart = switch (granularity) {
  TimeBucketGranularity.hour => DateTime(
    tx.date.year,
    tx.date.month,
    tx.date.day,
    tx.date.hour,
  ),
  TimeBucketGranularity.day => DateHelpers.startOfDay(tx.date),
  TimeBucketGranularity.month => DateHelpers.startOfMonth(tx.date),
};

groupBy((bucketStart, tx.currency));
```

The repository owns local bucket math so midnight and DST behavior stays aligned with the rest of the app's `DateHelpers` usage. Week view still uses day buckets inside a `startOfWeek` range.

**Base range query for time buckets:**
```sql
SELECT t.date, t.currency, t.amount_minor_units
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.date >= ? AND t.date < ? AND c.type = ?
ORDER BY t.date ASC
```

Account and currency follow the same pattern, with account grouping by `(t.account_id, t.currency)`.

### New Domain Models

In `lib/data/models/`:

```dart
@freezed
abstract class CategorySlice with _$CategorySlice {
  const factory CategorySlice({
    required int categoryId,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _CategorySlice;
}

@freezed
abstract class AccountSlice with _$AccountSlice {
  const factory AccountSlice({
    required int accountId,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _AccountSlice;
}

@freezed
abstract class CurrencySlice with _$CurrencySlice {
  const factory CurrencySlice({
    required String currencyCode,
    required int totalMinorUnits,
  }) = _CurrencySlice;
}

@freezed
abstract class TimeBucketSlice with _$TimeBucketSlice {
  const factory TimeBucketSlice({
    required DateTime bucketStart,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _TimeBucketSlice;
}

enum TimeBucketGranularity { hour, day, month }
```

---

## Controller & State

### ChartsController

`StreamNotifier` in `lib/features/analysis/charts/charts_controller.dart`.

**Parameters managed internally:**
- `period` — `PeriodType.day`, `.week`, `.month`, or `.year`
- `anchorDate` — the currently selected day / week / month / year anchor
- `type` — `CategoryType.expense` or `CategoryType.income`
- `dimension` — `ChartDimension.category`, `.account`, or `.currency`

**State:**

```dart
@freezed
sealed class ChartsState with _$ChartsState {
  const factory ChartsState.idle() = ChartsIdle;
  const factory ChartsState.loading({ChartsData? previous}) = ChartsLoading;
  const factory ChartsState.data({
    required ChartsData chartData,
  }) = ChartsDataState;
  const factory ChartsState.empty() = ChartsEmpty;
  const factory ChartsState.error(Object error, StackTrace stack) = ChartsError;
  const factory ChartsState.blockedByMissingRates({
    required ChartsData? previous,
  }) = ChartsBlockedByMissingRates;
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
    required int? grandTotalMinorUnits,
    required String? displayCurrencyCode,
    @Default(false) bool mixedCurrencies,
  }) = _ChartsData;
}

@freezed
abstract class ChartSlice with _$ChartSlice {
  const factory ChartSlice({
    required String label,
    required String currencyCode,
    required int totalMinorUnits,
    double? fraction, // 0.0–1.0 when grand total is comparable
    required int colorIndex, // for pie segment color
    required String iconKey, // for legend icon (category/account)
  }) = _ChartSlice;
}

@freezed
abstract class ChartBucketTotal with _$ChartBucketTotal {
  const factory ChartBucketTotal({
    required DateTime bucketStart,
    required int totalMinorUnits,
  }) = _ChartBucketTotal;
}
```

**Commands:**
- `previousPeriod()` — moves anchor back one day, week, month, or year
- `nextPeriod()` — moves anchor forward (disabled when next would exceed the current day/week/month/year)
- `setPeriod(PeriodType period)` — switches between day/week/month/year while keeping the nearest matching anchor
- `toggleType()` — switches between expense and income
- `toggleDimension(ChartDimension d)` — switches category/account/currency

**Behavior:**
- On build and on each command change, compute the date range `[start, end)` from `period` + `anchorDate`
- Subscribe to the appropriate repository stream based on current `dimension`
- Subscribe to `watchTimeBucketsInRange` with granularity `hour` for day view, `day` for week/month views, and `month` for year view
- Also subscribe to `chartsFxStatusProvider` for conversion readiness and staleness
- Re-subscribe when period, type, or dimension changes (cancel prior subscription, like `AnalysisController`)
- For category/account dimensions, convert per-currency subtotals first, then regroup into final `ChartSlice`s
- For currency dimension, no regrouping is needed because each slice stays tied to one `currencyCode`
- When exchange rates are missing for needed pairs, trigger `ExchangeRateRepository.refreshAll(defaultCurrency)` if `chartsFxStatusProvider` says no refresh is already in flight for that default currency
- For `ChartDimension.currency`, pie slices may render immediately in their source currencies, but the bar chart is hidden until all bucket subtotals are comparable in one display currency
- For `ChartDimension.category` / `.account`, emit `ChartsState.blockedByMissingRates(previous: previousDataOrNull)` until comparable converted totals are available
- When rates arrive, re-compute and re-emit with converted amounts
- `ChartsController` may seed its initial empty-query render from a warm weekly snapshot only when all of the following still match: default currency unchanged, locale unchanged, active period = week, active type = expense, active dimension = category, no transaction/category/account mutations since warm-up, and the FX freshness window remains under 1 hour
- After the user changes period, type, or dimension once, clearing search restores that last chart selection instead of resetting to the weekly default

### Providers

In `lib/features/analysis/charts/charts_providers.dart`:

```dart
/// Currency metadata for money formatting.
final chartsCurrenciesByCodeProvider = Provider<Map<String, Currency>>(...);

/// FX readiness + freshness snapshot for the current default currency.
final chartsFxStatusProvider = StreamProvider<ChartsFxStatus>(...);
```

Reuse existing `analysisCategoriesByIdProvider` and `analysisAccountsByIdProvider` from `search/analysis_providers.dart`; chart code depends on those providers directly rather than re-exporting alias providers.

`ChartsFxStatus` is a charts-facing model that exposes:
- current default currency code
- per-pair `fetchedAt`
- whether the initial default-currency refresh attempt has completed
- whether a refresh is currently in flight

`ChartsController` is the single owner of warm-start chart state. It may seed itself from the latest `chartsFxStatusProvider` + repository streams, but no separate app-level `StateProvider<ChartsData?>` cache is introduced.

---

## UI Components

### File Structure

```
lib/features/analysis/
  charts/
    charts_section.dart          # Main widget, wraps fl_chart widgets with controls
    charts_controller.dart       # StreamNotifier
    charts_state.dart            # Freezed state
    charts_providers.dart        # Co-located providers
    widgets/
      category_pie_chart.dart    # fl_chart PieChart wrapper
      daily_bar_chart.dart       # fl_chart BarChart wrapper for all period buckets
      chart_legend.dart          # Color-coded legend below pie
      period_selector.dart       # Day/week/month/year toggle + prev/next arrows
      dimension_toggle.dart      # Category | Account | Currency chips
      type_toggle.dart           # Expense | Income segmented control
```

### AnalysisScreen Integration

The existing `SearchBar` stays in the `AppBar` so search remains the first interactive control. The `AnalysisScreen` body becomes a `CustomScrollView` that renders charts only while the search query is empty:

```dart
Scaffold(
  appBar: AppBar(
    title: Text(l10n.analysisTitle),
    bottom: PreferredSize(...SearchBar(...)),
  ),
  body: CustomScrollView(
    slivers: [
      if (query.isEmpty) SliverToBoxAdapter(child: ChartsSection()),
      searchResultsSliver,
    ],
  ),
)
```

`ChartsSection` owns the period selector, type toggle, dimension toggle, pie chart, legend, and bar chart.

The existing `SearchBar` remains the first interactive control on the screen. When the query is empty, `ChartsSection` renders beneath it and replaces the old empty search placeholder. When the user starts a query, the search results state takes priority and the charts collapse out of the scroll body until the query returns to empty.

`ChartsController` and `AnalysisController` remain independent, but `AnalysisScreen` owns a small presentation-state matrix:
- Search idle + charts loading/data/empty/error/blocked: show the search bar first, then the matching chart state below it
- Search loading/results/empty/error: keep the search bar visible and prioritize the search surface; charts are hidden while query-driven search is active
- Search clear before any chart interaction: restore the warmed weekly charts state immediately when available, otherwise show the chart loading state
- Search clear after chart interaction: restore the user's last chart selection and state instead of resetting to the default weekly view

### Chart Rendering

Uses [`fl_chart`](https://pub.dev/packages/fl_chart) for both pie and bar charts. Provides built-in animations, touch interactions (future-proofing), and Material Design styling.

**Pie chart (`fl_chart` `PieChart`):**
- `PieChartData` entries from `ChartSlice` list
- Colors from `color_palette.dart` indices
- Donut style with `sectionsSpace: 2` and `centerSpaceRadius: 40`
- When `fraction == null`, hide percentage-style labels and total-summary copy; the legend still shows each slice's raw amount in its own `currencyCode`
- Built-in animation on data change (`swapAnimationDuration`)
- `PieTouchData` configured as no-op for now (view-only); enables future drill-down

**Bar chart (`fl_chart` `BarChart`):**
- Day view: 24 `BarChartGroupData` buckets (one per hour), x-axis shows hour labels
- Week view: 7 `BarChartGroupData` buckets (one per weekday), x-axis shows localized weekday abbreviations
- Month view: one `BarChartGroupData` per calendar day in the selected month, including zero-value days
- Year view: 12 `BarChartGroupData` buckets (one per month), including zero-value months
- Future buckets inside the current active period render with `color.withOpacity(0.3)` for dimmed appearance
- `BarTouchData` configured as no-op for now
- `maxY` auto-scaled to max value with 10% headroom
- Built-in animation on data change

**Legend (`ChartLegend`):**
- Below pie chart
- Each entry: colored dot + label + formatted amount
- Format each amount with `slice.currencyCode` when `displayCurrencyCode == null`; otherwise format in `displayCurrencyCode`
- Labels resolved from category name (`customName ?? l10nKey`), account name, or currency code
- Max 8 entries shown; "Other" bucket aggregates remaining slices (sorted by `totalMinorUnits` descending, top 7 + "Other" = 8 entries)
- When `Other` is present, show a trailing "View all" affordance that opens a bottom sheet listing every slice with label + amount; this stays in-chart and does not navigate to transactions
- "Other" slice uses Neutral Variant 50 color (`#79747E`) — same as the seeded Miscellaneous category

### Period Selector (`PeriodSelector`)

- Row with prev arrow, period label, next arrow
- Toggle button: "Day" | "Week" | "Month" | "Year"
- Day label: localized short date (for example, `May 18, 2026`)
- Week label: localized week range (for example, `May 18-24, 2026`)
- Month label: `May 2026`
- Year label: `2026`
- Default period is Week
- Next disabled when viewing the current active day/week/month/year

### Dimension Toggle (`DimensionToggle`)

- Three compact chips: "Category" | "Account" | "Currency"
- MD3 filter chip style
- Default: Category

### Type Toggle (`TypeToggle`)

- Segmented control: "Expense" | "Income"
- MD3 segmented button style
- Default: Expense

### Empty States

- **No transactions for period**: Show period label + "No transactions yet" message
- **Single currency in currency dimension**: Show pie chart normally (100% one slice)
- **Missing rates in category/account dimension**: Show a blocked state explaining that comparable totals need FX data; keep the period, type, and dimension controls visible and usable so the user can switch to Currency view immediately
- **Mixed currencies in currency dimension with missing rates**: Show the pie chart normally and banner-copy that values stay in their original currencies; hide the bar chart until all bucket totals are comparable in one display currency

### Loading + Error States

- `ChartsLoading(previous: previous)` keeps chart controls mounted
- When `previous != null`, render the previous chart content with an inline loading indicator in the chart body
- When `previous == null`, render a chart-sized loading placeholder under the controls
- `ChartsBlockedByMissingRates(previous: previous)` keeps chart controls mounted; only the chart body swaps to the blocked-state message and refresh-status copy
- `ChartsError` keeps chart controls mounted and shows an inline error state in the chart body with a retry action wired to the controller refresh path

### Accessibility & Responsiveness

- Keep the chart controls inside the app's existing 600dp adaptive shell rules; do not introduce a second breakpoint
- Below 600dp, period and dimension controls may wrap to multiple lines; above 600dp they may stay inline if touch targets remain at least 48dp
- Provide semantic summaries for the pie chart (top slices + total) and bar chart (period + max bucket + total)
- Do not rely on color alone: the legend keeps text labels and formatted amounts for every visible entry, and the full-legend sheet mirrors them
- Respect text scaling by allowing chip / segmented-control labels to wrap or expand instead of clipping
- Prev/next buttons announce the current period label and disabled state to assistive technologies
- Period/type/dimension controls announce which option is currently selected
- The `View all` bottom sheet moves focus to its title on open and returns focus to the triggering control on close

---

## Multi-Currency Conversion

### Flow

1. `ChartsController.build()` reads `chartsFxStatusProvider` for rates, `fetchedAt`, and whether the initial default-currency FX refresh has completed
2. If rates are **stale** (>1h since `fetchedAt`) or **missing** for needed pairs:
   - Call `ExchangeRateRepository.refreshAll(defaultCurrency)` (non-blocking)
   - If the active dimension is `currency`, automatically select Currency view for the first empty-query render when Week + Category would otherwise open into a blocked state
   - For `ChartDimension.currency`, render original-currency pie slices immediately
   - For `ChartDimension.category` / `.account`, emit `ChartsState.blockedByMissingRates(previous: previousDataOrNull)` until comparable converted totals are available
   - Set `mixedCurrencies: true` on state when any needed pair is unresolved
3. Subscribe to the exchange-rate stream backing `chartsFxStatusProvider`
4. When updated rates arrive, re-compute all `totalMinorUnits` values:
   - For category/account views, convert each `(dimension, currency)` subtotal with `convertedMinor = (originalMinor * rateNumerator) ~/ rateDenominator`, then regroup by final dimension id
   - For time buckets, convert each `(bucketStart, currency)` subtotal before regrouping into the displayed bucket total
   - For currency view, keep each slice in its own currency unless the UI is explicitly rendering a converted grand total
5. Re-emit with `displayCurrencyCode = defaultCurrency` and `mixedCurrencies = false` only when every subtotal needed by the active chart has a valid rate
6. After the initial default-currency FX refresh attempt completes, `ChartsController` may reuse a warm weekly expense-by-category snapshot only when the freshness/invalidation rules above still hold

### Conversion Rules

- Conversion uses the same integer arithmetic as existing exchange-rate code — never doubles
- `ExchangeRateRepository` stores forward rates (foreign → default); the chart controller uses these directly
- If a rate pair is completely missing (no forward or inverse), category/account charts do not compute a blended total from unlike currencies
- The `mixedCurrencies` banner appears when **any** currency present in the active chart lacks a valid exchange rate to `defaultCurrency`
- For category/account views, `grandTotalMinorUnits` and `fraction` are only emitted when all required subtotals are converted into one display currency
- For currency view with unresolved rates, `displayCurrencyCode` stays `null`, each slice keeps its own `currencyCode`, no synthetic cross-currency grand total is shown, and the bar chart remains hidden until bucket totals are comparable
- The banner disappears only when **all** currencies in the active chart have valid rates

---

## Localization

Chart-related ARB keys for all three locales (en, zh_TW, zh_CN). Reuse the existing `analysisTitle` key for the screen title and add the chart-specific entries below:

| Key                       | English                           | Notes                                      |
|---------------------------|-----------------------------------|--------------------------------------------|
| `analysisTitle`           | Analysis                          | App bar title (already exists from search) |
| `chartsPeriodDay`         | Day                               | Period toggle label                        |
| `chartsPeriodWeek`        | Week                              | Period toggle label                        |
| `chartsPeriodMonth`       | Month                             | Period toggle label                        |
| `chartsPeriodYear`        | Year                              | Period toggle label                        |
| `chartsTypeExpense`       | Expense                           | Type toggle label                          |
| `chartsTypeIncome`        | Income                            | Type toggle label                          |
| `chartsDimensionCategory` | Category                          | Dimension toggle label                     |
| `chartsDimensionAccount`  | Account                           | Dimension toggle label                     |
| `chartsDimensionCurrency` | Currency                          | Dimension toggle label                     |
| `chartsNoData`            | No transactions yet               | Empty state                                |
| `chartsMixedCurrencies`   | Showing original currency amounts | Banner for unresolved currency-view values |
| `chartsRatesRequired`     | Waiting for exchange rates        | Blocked state for category/account charts  |
| `chartsViewAll`           | View all                          | Full-legend bottom-sheet affordance        |
| `chartsTotal`             | Total                             | Grand total label                          |
| `chartsOther`             | Other                             | Aggregated remaining slices                |

---

## Testing

### Repository Tests (`test/unit/repositories/`)

- Insert transactions across multiple days/categories/accounts/currencies
- Verify `watchByCategoryInRange` returns one subtotal per `(category, currency)` pair
- Verify `watchByAccountInRange` returns one subtotal per `(account, currency)` pair
- Verify `watchByCurrencyInRange` returns correct per-currency sums
- Verify `watchTimeBucketsInRange` returns correct hour/day/month buckets for day/week/month/year views
- Verify zero-filled buckets are produced at the controller layer for inactive days / months
- Verify type filtering (expense vs income)
- Verify empty result for date range with no transactions
- Verify reactive re-emission on insert/delete
- Verify local bucket math around midnight and DST boundaries matches `DateHelpers`

### Controller Tests (`test/unit/controllers/`)

- Mock repository streams, verify `ChartsState.data` emission
- Verify `setPeriod()` switches across day/week/month/year and re-subscribes with the correct range + granularity
- Verify `previousPeriod()` / `nextPeriod()` changes anchor and re-subscribes for each period
- Verify `toggleType()` switches between expense/income data
- Verify `toggleDimension()` switches between category/account/currency data
- Verify conversion logic: category/account subtotals convert per currency before regrouping
- Verify missing-rate behavior: category/account charts emit `ChartsBlockedByMissingRates`, first-load multi-currency sessions fall back to Currency view, currency pie stays viewable, and the bar chart stays hidden until units are comparable
- Verify rate fetch trigger when rates are stale
- Verify warm-start reuse only when locale/default currency/source data/freshness still match; otherwise the controller recomputes from live streams
- Verify `nextPeriod()` disabled at the current day/week/month/year

### Widget Tests (`test/widget/features/analysis/`)

- Render `ChartsSection` with mocked `ChartsController` states
- Verify pie chart renders correct number of segments
- Verify bar chart renders correct number of bars
- Verify period/type/dimension toggles call correct controller commands
- Verify empty state renders when no data
- Verify legend displays correct labels and amounts
- Verify `View all` opens the full legend when `Other` is present
- Verify the blocked FX state appears for category/account charts when rates are missing
- Verify the search-first layout hides charts while a search query is active
- Verify the old empty search placeholder does not render while charts are visible on an empty query
- Verify loading(previous), blocked, and error states keep controls mounted and swap only the chart body
- Verify chart controls remain readable at >1.5x text scale and across the 600dp adaptive breakpoint
- Verify assistive labels announce selected toggle state, disabled next-period state, and `View all` sheet focus return

### Integration Test (`test/integration/`)

- Insert transactions → open Analysis → verify charts display correct data
- Launch app → complete initial FX readiness → verify weekly chart warm-up is reused on first Analysis visit
- Switch day/week/month/year → verify charts update with the correct bucket counts
- Switch year view → verify 12 monthly bars including zero-value months
- Toggle expense/income → verify data changes
- Toggle dimension → verify pie changes between category/account/currency views
- Search while charts are present → verify search takes visual priority and charts return when the query is cleared

---

## Dependencies

New external dependency:
- [`fl_chart`](https://pub.dev/packages/fl_chart) — `^0.70.2` (latest stable as of 2026-05-18). Material 3 compatible, built-in animations, touch support. Add to `pubspec.yaml` under `dependencies`.

New internal imports:
- `data/models/` — 4 new Freezed models
- `data/repositories/transaction_repository.dart` — 4 new methods
- `core/utils/color_palette.dart` — existing, for pie segment colors
- `core/utils/icon_registry.dart` — existing, for legend icons
- `core/utils/money_formatter.dart` — existing, for amount display
- `data/repositories/exchange_rate_repository.dart` — existing, for conversion

---

## File Inventory

### New files
- `lib/data/models/category_slice.dart` + `.freezed.dart`
- `lib/data/models/account_slice.dart` + `.freezed.dart`
- `lib/data/models/currency_slice.dart` + `.freezed.dart`
- `lib/data/models/time_bucket_slice.dart` + `.freezed.dart`
- `lib/features/analysis/charts/charts_section.dart`
- `lib/features/analysis/charts/charts_controller.dart` + `.g.dart`
- `lib/features/analysis/charts/charts_state.dart` + `.freezed.dart`
- `lib/features/analysis/charts/charts_providers.dart`
- `lib/features/analysis/charts/widgets/category_pie_chart.dart`
- `lib/features/analysis/charts/widgets/daily_bar_chart.dart`
- `lib/features/analysis/charts/widgets/chart_legend.dart`
- `lib/features/analysis/charts/widgets/period_selector.dart`
- `lib/features/analysis/charts/widgets/dimension_toggle.dart`
- `lib/features/analysis/charts/widgets/type_toggle.dart`

### Modified files
- `lib/data/repositories/transaction_repository.dart` — add 4 range methods
- `lib/data/database/daos/transaction_dao.dart` — add 4 DAO query methods
- `lib/features/analysis/analysis_screen.dart` — integrate ChartsSection beneath the search bar and hide charts while query-driven search is active
- `lib/core/utils/date_helpers.dart` — add `startOfWeek`, `startOfMonth`, and `startOfYear` helpers for chart boundaries
- `lib/app/app.dart` or chart bootstrap wiring — warm the default weekly chart state after initial FX readiness
- `l10n/app_en.arb`, `l10n/app_zh_TW.arb`, `l10n/app_zh_CN.arb` — new chart labels

### Test files
- `test/unit/repositories/chart_aggregation_test.dart`
- `test/unit/controllers/charts_controller_test.dart`
- `test/widget/features/analysis/charts_section_test.dart`
- `test/integration/chart_display_flow_test.dart`

## Deferred / Open Questions

### From 2026-05-19 review

- **Blocked charts should degrade instead of fully blocking** — Multi-Currency Conversion (P1, adversarial, confidence 75)

  One unresolved or unsupported currency can currently block the entire category/account chart for the active period. The spec now protects mathematical correctness, but it still needs a product decision on whether long-tail unsupported currencies should cause full blocking or a degraded mode that excludes unresolved values with explicit disclosure.

  <!-- dedup-key: section="multi currency conversion" title="blocked charts should degrade instead of fully blocking" evidence="for chartdimensioncategory and account emit a blocked loading state until comparable converted totals are available" -->

- **Charts should bridge into transaction inspection** — Overview / AnalysisScreen Integration / Out of scope (P2, product-lens, confidence 75)

  The charts now avoid misleading states better, but they still surface anomalies without a direct path into the underlying transaction set. A later product decision should determine whether chart context eventually prefilters the existing Analysis detail/search surfaces.

  <!-- dedup-key: section="overview analysisscreen integration out of scope" title="charts should bridge into transaction inspection" evidence="view only charts memo search remains the primary actionable workflow" -->
