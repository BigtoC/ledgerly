# Basic Charts — Design Spec

**Status:** Approved
**Date:** 2026-05-18
**Feature:** Phase 2 — Basic charts (pie, bar) on the Analysis tab

---

## Overview

Add spending/income charts to the Analysis tab. A pie chart shows category/account/currency breakdowns; a bar chart shows daily (month view) or monthly (year view) totals. Charts sit above the existing transaction search in a single scrollable view.

**Scope:**
- Pie chart by category, account, or currency (user toggle)
- Bar chart: daily bars in month view, monthly bars in year view
- Expense/income toggle
- Month/year period toggle with prev/next navigation
- Multi-currency auto-conversion when exchange rates available; fallback to original currency
- View-only — no drill-down to transactions

**Out of scope:**
- Drill-down navigation from chart segments
- Budget overlay on charts
- Custom date range picker
- Export/share chart images

---

## Data Layer

### New Repository Methods

Four new methods on `TransactionRepository`, all using generic date-range parameters to serve both month and year views.

```dart
/// Per-category total for transactions in [start, end) filtered by type.
Stream<List<CategorySlice>> watchByCategoryInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
});

/// Per-account total for transactions in [start, end) filtered by type.
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

/// Per-day total for transactions in [start, end) filtered by type.
/// Returns one row per calendar day that has activity.
Stream<List<DailySlice>> watchDailyTotalsInRange({
  required DateTime start,
  required DateTime end,
  required CategoryType type,
});
```

Each method:
- Joins `transactions` with `categories` to filter by `categories.type`
- Groups by the relevant dimension column
- Sums `amount_minor_units` (integer minor units, never doubles)
- Returns a `Stream` backed by Drift's `.watch()` for reactive updates
- Uses `DateHelpers.startOfDay` for range boundaries (device-local timezone)

**Period boundaries:**
- Month view: `[startOfMonth, startOfNextMonth)` — e.g., May 2026 = `[2026-05-01 00:00, 2026-06-01 00:00)`
- Year view: `[startOfYear, startOfNextYear)` — e.g., 2026 = `[2026-01-01 00:00, 2027-01-01 00:00)`
- `DateHelpers.startOfDay` used for both boundaries to stay in device-local timezone

### SQL Examples

**Category aggregation:**
```sql
SELECT t.category_id, SUM(t.amount_minor_units) AS total
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.date >= ? AND t.date < ? AND c.type = ?
GROUP BY t.category_id
```

**Daily aggregation:**
```sql
SELECT date(t.date) AS day, SUM(t.amount_minor_units) AS total
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.date >= ? AND t.date < ? AND c.type = ?
GROUP BY date(t.date)
ORDER BY day ASC
```

Account and currency follow the same pattern, grouping by `t.account_id` and `t.currency` respectively.

### New Domain Models

In `lib/data/models/`:

```dart
@freezed
abstract class CategorySlice with _$CategorySlice {
  const factory CategorySlice({
    required int categoryId,
    required int totalMinorUnits,
  }) = _CategorySlice;
}

@freezed
abstract class AccountSlice with _$AccountSlice {
  const factory AccountSlice({
    required int accountId,
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
abstract class DailySlice with _$DailySlice {
  const factory DailySlice({
    required DateTime day,
    required int totalMinorUnits,
  }) = _DailySlice;
}
```

---

## Controller & State

### ChartsController

`StreamNotifier` in `lib/features/analysis/charts/charts_controller.dart`.

**Parameters managed internally:**
- `period` — `PeriodType.month` or `PeriodType.year`
- `anchorDate` — the month or year being viewed (e.g., `DateTime(2026, 5)` for May 2026)
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
}

@freezed
abstract class ChartsData with _$ChartsData {
  const factory ChartsData({
    required PeriodType period,
    required DateTime anchorDate,
    required CategoryType type,
    required ChartDimension dimension,
    required List<ChartSlice> slices,
    required List<DailyTotal> dailyTotals,
    required int grandTotalMinorUnits,
    required String displayCurrencyCode,
    @Default(false) bool mixedCurrencies,
  }) = _ChartsData;
}

@freezed
abstract class ChartSlice with _$ChartSlice {
  const factory ChartSlice({
    required String label,
    required int totalMinorUnits,
    required double fraction, // 0.0–1.0, share of grand total
    required int colorIndex, // for pie segment color
    required String iconKey, // for legend icon (category/account)
  }) = _ChartSlice;
}

@freezed
abstract class DailyTotal with _$DailyTotal {
  const factory DailyTotal({
    required DateTime day,
    required int totalMinorUnits,
  }) = _DailyTotal;
}
```

**Commands:**
- `previousPeriod()` — moves anchor back one month or year
- `nextPeriod()` — moves anchor forward (disabled when next would exceed current month/year)
- `toggleType()` — switches between expense and income
- `toggleDimension(ChartDimension d)` — switches category/account/currency

**Behavior:**
- On build and on each command change, compute the date range `[start, end)` from `period` + `anchorDate`
- Subscribe to the appropriate repository stream based on current `dimension`
- Also subscribe to `exchangeRateRepositoryProvider` for conversion
- Re-subscribe when period, type, or dimension changes (cancel prior subscription, like `AnalysisController`)
- When exchange rates are missing for needed pairs, call `ExchangeRateRepository.refreshAll(defaultCurrency)` and render with original currency + `mixedCurrencies: true`
- When rates arrive, re-compute and re-emit with converted amounts

### Providers

In `lib/features/analysis/charts/charts_providers.dart`:

```dart
/// Category metadata for chart labels/icons.
final chartsCategoriesByIdProvider = analysisCategoriesByIdProvider;

/// Account metadata for chart labels.
final chartsAccountsByIdProvider = analysisAccountsByIdProvider;
```

Reuse existing `analysisCategoriesByIdProvider` and `analysisAccountsByIdProvider` from `search/analysis_providers.dart`.

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
      daily_bar_chart.dart       # fl_chart BarChart wrapper
      chart_legend.dart          # Color-coded legend below pie
      period_selector.dart       # Month/year toggle + prev/next arrows
      dimension_toggle.dart      # Category | Account | Currency chips
      type_toggle.dart           # Expense | Income segmented control
```

### AnalysisScreen Integration

The `AnalysisScreen` becomes a `CustomScrollView` replacing the current `Scaffold > body: ListView`:

```dart
CustomScrollView(
  slivers: [
    // Charts section
    SliverToBoxAdapter(child: PeriodSelector()),
    SliverToBoxAdapter(child: TypeToggle()),
    SliverToBoxAdapter(child: DimensionToggle()),
    SliverToBoxAdapter(child: PieChartWithLegend()),
    SliverToBoxAdapter(child: BarChart()),
    // Search section (existing)
    SliverToBoxAdapter(child: SearchBar(...)),
    // Search results (existing, now as sliver)
    searchResultsSliver,
  ],
)
```

The existing `SearchBar` and search results remain below the charts. The `ChartsController` and `AnalysisController` are independent — no shared state.

### Chart Rendering

Uses [`fl_chart`](https://pub.dev/packages/fl_chart) for both pie and bar charts. Provides built-in animations, touch interactions (future-proofing), and Material Design styling.

**Pie chart (`fl_chart` `PieChart`):**
- `PieChartData` entries from `ChartSlice` list
- Colors from `color_palette.dart` indices
- Donut style with `sectionsSpace: 2` and `centerSpaceRadius: 40`
- Built-in animation on data change (`swapAnimationDuration`)
- `PieTouchData` configured as no-op for now (view-only); enables future drill-down

**Bar chart (`fl_chart` `BarChart`):**
- Month view: 28–31 `BarChartGroupData` (one per calendar day), x-axis shows day numbers
- Year view: 12 `BarChartGroupData` (one per month), x-axis shows month abbreviations
- Future days/months rendered with `color.withOpacity(0.3)` for dimmed appearance
- `BarTouchData` configured as no-op for now
- `maxY` auto-scaled to max value with 10% headroom
- Built-in animation on data change

**Legend (`ChartLegend`):**
- Below pie chart
- Each entry: colored dot + label + formatted amount
- Labels resolved from category name (`customName ?? l10nKey`), account name, or currency code
- Max 8 entries shown; "Other" bucket aggregates remaining slices (sorted by `totalMinorUnits` descending, top 7 + "Other" = 8 entries)
- "Other" slice uses Neutral Variant 50 color (`#79747E`) — same as the seeded Miscellaneous category

### Period Selector (`PeriodSelector`)

- Row with prev arrow, period label, next arrow
- Toggle button: "Month" | "Year"
- Month label: "May 2026"
- Year label: "2026"
- Next disabled when viewing current month/year

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
- **Mixed currencies with no rates**: Show original-currency chart + subtle banner "Showing original currency amounts"

---

## Multi-Currency Conversion

### Flow

1. `ChartsController.build()` checks `ExchangeRateRepository.snapshot` for rates
2. If rates are **stale** (>1h since `fetchedAt`) or **missing** for needed pairs:
   - Call `ExchangeRateRepository.refreshAll(defaultCurrency)` (non-blocking)
   - Render charts with original currency amounts
   - Set `mixedCurrencies: true` on state
3. Subscribe to `ExchangeRateRepository` stream (backed by `exchange_rates` DAO watch)
4. When updated rates arrive, re-compute all `totalMinorUnits` values:
   - For each slice, if `slice.currencyCode != defaultCurrency` and rate exists, convert: `convertedMinor = (originalMinor * rateNumerator) ~/ rateDenominator`
   - If rate missing for a currency, keep original amount
5. Re-emit with `displayCurrencyCode = defaultCurrency` and `mixedCurrencies = false` (if all rates resolved)

### Conversion Rules

- Conversion uses the same integer arithmetic as existing exchange-rate code — never doubles
- `ExchangeRateRepository` stores forward rates (foreign → default); the chart controller uses these directly
- If a rate pair is completely missing (no forward or inverse), that currency's amounts stay in original form
- The `mixedCurrencies` banner appears when **any** currency present in the chart data lacks a valid exchange rate to `defaultCurrency`
- The banner disappears only when **all** currencies in the chart have valid rates

---

## Localization

New ARB entries for all three locales (en, zh_TW, zh_CN):

| Key                       | English                           | Notes                                      |
|---------------------------|-----------------------------------|--------------------------------------------|
| `chartsTitle`             | Analysis                          | App bar title (already exists from search) |
| `chartsPeriodMonth`       | Month                             | Period toggle label                        |
| `chartsPeriodYear`        | Year                              | Period toggle label                        |
| `chartsTypeExpense`       | Expense                           | Type toggle label                          |
| `chartsTypeIncome`        | Income                            | Type toggle label                          |
| `chartsDimensionCategory` | Category                          | Dimension toggle label                     |
| `chartsDimensionAccount`  | Account                           | Dimension toggle label                     |
| `chartsDimensionCurrency` | Currency                          | Dimension toggle label                     |
| `chartsNoData`            | No transactions yet               | Empty state                                |
| `chartsMixedCurrencies`   | Showing original currency amounts | Banner when rates unavailable              |
| `chartsTotal`             | Total                             | Grand total label                          |
| `chartsOther`             | Other                             | Aggregated remaining slices                |

---

## Testing

### Repository Tests (`test/unit/repositories/`)

- Insert transactions across multiple days/categories/accounts/currencies
- Verify `watchByCategoryInRange` returns correct per-category sums
- Verify `watchByAccountInRange` returns correct per-account sums
- Verify `watchByCurrencyInRange` returns correct per-currency sums
- Verify `watchDailyTotalsInRange` returns correct per-day sums with proper day ordering
- Verify type filtering (expense vs income)
- Verify empty result for date range with no transactions
- Verify reactive re-emission on insert/delete

### Controller Tests (`test/unit/controllers/`)

- Mock repository streams, verify `ChartsState.data` emission
- Verify `previousPeriod()` / `nextPeriod()` changes anchor and re-subscribes
- Verify `toggleType()` switches between expense/income data
- Verify `toggleDimension()` switches between category/account/currency data
- Verify conversion logic: rates available → converted amounts; rates missing → original + `mixedCurrencies: true`
- Verify rate fetch trigger when rates are stale
- Verify `nextPeriod()` disabled at current month/year

### Widget Tests (`test/widget/features/analysis/`)

- Render `ChartsSection` with mocked `ChartsController` states
- Verify pie chart renders correct number of segments
- Verify bar chart renders correct number of bars
- Verify period/type/dimension toggles call correct controller commands
- Verify empty state renders when no data
- Verify legend displays correct labels and amounts
- Verify `mixedCurrencies` banner appears when flag is true

### Integration Test (`test/integration/`)

- Insert transactions → open Analysis → verify charts display correct data
- Switch months → verify charts update
- Switch year view → verify 12 monthly bars
- Toggle expense/income → verify data changes
- Toggle dimension → verify pie changes between category/account/currency views

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
- `lib/data/models/daily_slice.dart` + `.freezed.dart`
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
- `lib/features/analysis/analysis_screen.dart` — integrate ChartsSection above search
- `l10n/app_en.arb`, `l10n/app_zh_TW.arb`, `l10n/app_zh_CN.arb` — new chart labels

### Test files
- `test/unit/repositories/chart_aggregation_test.dart`
- `test/unit/controllers/charts_controller_test.dart`
- `test/widget/features/analysis/charts_section_test.dart`
- `test/integration/chart_display_flow_test.dart`
