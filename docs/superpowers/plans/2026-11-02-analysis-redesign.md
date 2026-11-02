# Analysis Redesign — Implementation Plan

**Spec:** [`docs/superpowers/specs/2026-11-02-analysis-redesign-design.md`](../specs/2026-11-02-analysis-redesign-design.md) (revision `36207a9`)
**Visual source:** [`docs/design/analysis-redesign/Main.dc.html`](../../design/analysis-redesign/Main.dc.html) (identical to the design canvas, checked byte for byte)
**Branch:** `feat/analysis-redesign-impl` (on `main` @ `8c0fe07`)
**Status:** Draft — waiting for the deviation list (§ 4) to be confirmed before any code is written.

## 0. Ground rules

- Every visual value is copied from `Main.dc.html` (sizes, paddings, radii,
  font sizes / line heights, weights, colours, per-state styles, motion). No
  rounding, no Material defaults. Where the spec and the design file disagree on
  a *visual*, the design file wins; on *behaviour*, the spec wins (§ 4 lists
  every such case).
- Mock data in `Main.dc.html` (`CAT`, `ACCTS`, `ALL_ACCTS`, `MONTH_EXP`,
  `MATRIX`, `JPY`, `SERIES`, `TX`, `regMonth`, `PL`) never enters `lib/` or `test/`.
- Line height is applied as `TextStyle(fontSize: s, height: lh / s)` with
  `leadingDistribution: TextLeadingDistribution.even` (CSS half-leading).
  Tabular amounts use `fontFeatures: [FontFeature.tabularFigures()]`.
- A design height that holds text and sits in a scrollable region (`44px`
  segment, `32px` pill, `min-height: 64px` row) becomes a **minimum** height, so
  it renders exactly at 1× and grows instead of clipping at 2×. Fixed-size
  boxes (app bar row, donut centre) clamp text at 1.5×.
- TDD per step: failing test(s) from the spec's acceptance criteria first, watch
  them fail, implement the minimum, then `dart format`, `dart analyze --fatal-infos`
  (the CI equivalent of `flutter analyze`; it also reports missing `@Dependencies`)
  and the affected tests. `build_runner` whenever a `@riverpod`/`@freezed` file changes.
- Each commit analyzes and tests on its own (AGENTS.md). One branch and one PR
  per step (§ 5), each with one or more commits.

## 1. Element → widget / provider map

| Design element (`Main.dc.html` line)                                                 | Widget (file)                                                                       | Data / provider                                                                                        | Replaces                                                        |
|--------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| Page background `--bg`                                                               | `AnalysisScreen` `Scaffold.backgroundColor`                                         | `AnalysisColors.bg` (new `ThemeExtension`)                                                             | M3 `surface`                                                    |
| App bar row 64, padding 0 8 0 20, gap 12; title 24/32 w500 (:17-19)                  | `AnalysisScreen` `AppBar` (custom `title` row, `toolbarHeight: 64`)                 | —                                                                                                      | `AppBar` + `SearchBar` in `bottom`                              |
| Account filter pill in app bar (:20-27, accPillStyle :710-715)                       | `AccountFilterButton` (new `account_filter_button.dart`)                            | selection `accountFilterId`; `analysisAccountsById`                                                    | —                                                               |
| Collapsible search (:28-48, searchBoxStyle :769-777)                                 | `AnalysisSearchField` (new `analysis_search_field.dart` in `analysis/views/`)       | `AnalysisController.updateQuery` (unchanged)                                                           | M3 `SearchBar`                                                  |
| Period track, 5 columns, gap 2 (:50-56, tabs :737-748)                               | `PeriodTrack` in `period_selector.dart`                                             | `ChartsSelectionController.setPeriod`                                                                  | `SegmentedButton<PeriodType>`                                   |
| Period navigator + caption, hidden chevrons on All (:58-69, prev/nextStyle :729-736) | `PeriodNavigator` in `period_selector.dart`                                         | `isAtCurrentPeriod()`; `formatPeriodLabel()`; `chartsRange`                                            | label row of `PeriodSelector`                                   |
| Summary card: tiles, ratio bar, net row (:71-88)                                     | `ChartsSummaryCard` (new `charts_summary_card.dart`)                                | `chartsNetTotal` extended with expense + income, account-filtered                                      | `TypeToggle`, `ChartsNetTotalCard` (deleted)                    |
| FX banners                                                                           | unchanged, between summary and breakdown cards                                      | `ChartsData` flags                                                                                     | —                                                               |
| Breakdown title + dimension chips (:90-101)                                          | `ChartsBreakdownCard` (new) + `DimensionChips` (rewrite of `dimension_toggle.dart`) | `setDimension`                                                                                         | `SegmentedButton<ChartDimension>`                               |
| Donut + centre (:103-111)                                                            | `CategoryPieChart` (restyled)                                                       | `ChartsData.slices`, `grandTotalMinorUnits`                                                            | 1.4-aspect pie with % titles                                    |
| Ranked rows (:113-147)                                                               | `ChartLegend` → ranked rows (restyled, same file)                                   | `ChartsData.slices`                                                                                    | `Card` legend                                                   |
| Empty state (:150-158)                                                               | `_BreakdownEmptyState` in `charts_breakdown_card.dart`                              | `ChartsEmpty`                                                                                          | `chartsNoData` text                                             |
| Trend header, avg legend, filter chip (:161-176)                                     | `ChartsTrendCard` (new `charts_trend_card.dart`)                                    | `ChartsData.bucketTotals`; `trendSeries()` (new pure helper)                                           | —                                                               |
| Trend bars, avg line, x labels (:177-189)                                            | `DailyBarChart` (restyled) + x-label `Row`                                          | `trendSeries()`                                                                                        | gradient `AspectRatio(1.6)` chart                               |
| Transactions card header, close, bridge (:193-211)                                   | `SelectedSliceItemsList` (restyled)                                                 | `SliceDrilldownController`; `setAccountFilter`                                                         | `_ListHeader`                                                   |
| Transaction rows (:212-226)                                                          | `SliceTransactionRow` (new `slice_transaction_row.dart`)                            | `Transaction` + `analysisAccountsById`                                                                 | `TransactionSearchRow` in the drill-down only (search keeps it) |
| Empty / show more (:227-234)                                                         | `SelectedSliceItemsList`                                                            | existing paging                                                                                        | —                                                               |
| Account sheet (:263-291, sheetItems :688-709)                                        | `showAccountFilterSheet()` (new `account_filter_sheet.dart`)                        | new `chartsAccountFilterOptions`                                                                       | —                                                               |
| All period range (spec § All time)                                                   | —                                                                                   | new `chartsRange` provider (one place resolving `[start, end)` for every period, All from date bounds) | three copies of `normalizeAnchor`/`shiftAnchor` range math      |

## 2. Files

**New**
- `lib/ui/core/theme/analysis_colors.dart` — `AnalysisColors extends ThemeExtension` (spec tokens + `thumbShadow`), `light` / `dark`, `lerp`, `copyWith`.
- `lib/ui/features/analysis/views/analysis_search_field.dart`
- `lib/ui/features/analysis/charts/views/account_filter_button.dart`, `account_filter_sheet.dart`, `charts_summary_card.dart`, `charts_breakdown_card.dart`, `charts_trend_card.dart`, `slice_transaction_row.dart`
- `lib/ui/features/analysis/charts/view_models/trend_series.dart` — pure: zero-fill per period (incl. All), elapsed/future flags, average, current index, label set.
- `lib/ui/features/analysis/charts/view_models/charts_range_providers.dart` — `chartsRange` (+ date-bounds stream for All).
- `lib/ui/features/analysis/charts/view_models/account_filter_providers.dart` — `chartsAccountFilterOptions`, `analysisAccountTypesById` (if D4 is accepted).

**Changed**
- `lib/ui/core/theme/app_theme.dart` — register `AnalysisColors` per brightness.
- `lib/ui/features/analysis/views/analysis_screen.dart` — bg, app bar row.
- `charts_section.dart` — card layout, Day rule, banners position, swipe no-op on All.
- `period_selector.dart`, `dimension_toggle.dart`, `category_pie_chart.dart`, `chart_legend.dart`, `daily_bar_chart.dart`, `selected_slice_items_list.dart` — restyle.
- `charts_state.dart` (+ `.freezed`) — `PeriodType.all`.
- `charts_selection_controller.dart` (+ `.freezed/.g`) — `accountFilterId`, `setAccountFilter`, `setDimension` clears the filter, All no-ops.
- `charts_controller.dart`, `slice_drilldown_controller.dart`, `charts_net_total_providers.dart` (+ `.g`) — read the range from `chartsRange`; pass `accountId`.
- `transaction_dao.dart`, `transaction_repository.dart` — `accountId` on category / currency totals; per-type-per-currency totals (with `accountId`) replacing `watchNetByCurrencyInRange`; `watchDateBounds()` if D13 is accepted.
- `l10n/app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb` (+ generated); `app_zh.arb` untouched (audit test 3 pins it to `{appTitle}`).
- `test/unit/l10n/arb_audit_test.dart` — `_expectedEnKeys`.
- `PRD.md` § Analysis Screen, `docs/architecture/testing.md` § Charts.

**Deleted**
- `type_toggle.dart`, `charts_net_total_card.dart` (+ its test, replaced by summary-card tests).
- ARB keys left unreferenced after the change (`chartsNetTotal`, `chartsNoData`, maybe `analysisSearchPrompt` if only the semantics label keeps it — it stays as the input's semantics label per spec).

## 3. Steps (spec "Suggested order")

Each step: tests first (AC = spec acceptance criterion), then code, then
`dart format` + `dart analyze --fatal-infos` + affected tests; commit.

### Step 1 — Hide the trend card on Day (AC 1)
- Test (`charts_section_test.dart`): Day → no `DailyBarChart`; Week / Month / Year with buckets → present.
- Code: `showBar` also requires `data.period != PeriodType.day`. The controller keeps subscribing to buckets on Day (`_emitIfReady` waits for both streams).

### Step 2 — `AnalysisColors`; app bar with collapsible search; period track + navigator (AC 11)
- Tests: `AnalysisColors` light/dark values equal the spec table; `lightTheme`/`darkTheme` carry it. App bar shows title + search icon (account button arrives in step 7); tapping search expands the field leftwards, focuses the input; close collapses, clears the query; typing still shows results in place of the charts; IME guard and 1.5× clamp kept. Period track (4 options until step 5) exposes selected semantics; caption only at the current period; next chevron disabled in `off`.
- Code: `analysis_colors.dart`, `app_theme.dart`, `analysis_screen.dart`, `analysis_search_field.dart`, `period_selector.dart`; strings `analysisSearch{Hint,Open,Close}`, `chartsCaption*`.

### Step 3 — Summary card (AC 2, AC 3)
- Repo test: per-type-per-currency totals for the range; net derived = income − expense matches the old net cases.
- Provider tests: `chartsNetTotal` exposes converted expense, income, net; missing-rate currencies excluded.
- Widget tests: tapping Income switches type and clears slice; tiles show both converted totals; selected tile reports `isSelected`; net label by period; net colour `incText` / `expText` / `fg`; `—` when unavailable; ratio bar widths proportional.
- Code: DAO/repo query, provider, `charts_summary_card.dart`; remove `TypeToggle`, `ChartsNetTotalCard`; strings `chartsNet*`.

### Step 4 — Breakdown card: chips, donut, ranked rows, empty state (AC 4 partial, AC 8 rows, AC 9)
- Tests: chips switch dimension + selected semantics; donut 200×200, ring 26, no titles, unselected sections at alpha `0x4D`, selected does not grow; centre lines; rows: selected `sel` fill + w700, unselected rows keep full-opacity text while circle and bar fill fade to 0.35; mixed currencies hide bars + %; empty-state copy; icon ink by luminance > 0.35.
- Code: `charts_breakdown_card.dart`, `dimension_toggle.dart`, `category_pie_chart.dart`, `chart_legend.dart`, `charts_section.dart`; strings `chartsBreakdown*`, `chartsTotal{Expense,Income}`, `charts*Count`, `chartsShareOf*`, `chartsEmpty*`. Update the legend auto-scroll tests (they find the old `Card`).

### Step 5 — Trend card, then the All period (AC 8 chip, AC 13)
- 5a Trend. Unit tests (`trend_series.dart`): zero-fill per period, elapsed vs future, average = sum of elapsed ÷ elapsed count, current index only at the current period, month label set {1, 8, 15, 22, 29, today}. Widget tests: titles; "Avg … / day|month"; filter chip appears with a slice, tap clears, semantics label; bar colour = slice colour or `exp`/`inc`; no gradient; avg line hidden at 0.
- 5b All. Tests: five period options; `chartsRange` for All = `[first-of-month(earliest), start of next month)`; label "All time", caption "<MMM yyyy> – <MMM yyyy>"; chevrons hidden with slots kept; swipe and prev/next no-op; trend monthly from the first month to now, labels = year under each January + current month under the last bar, gap 4, radius 3/1; "Net all time"; no transactions → empty state.
- Code: `charts_trend_card.dart`, `daily_bar_chart.dart`, `trend_series.dart`, `charts_range_providers.dart`, `charts_state.dart`, selection controller, the three range consumers; strings `chartsTrend*`, `chartsAvgPer*`, `chartsClearSliceFilter`, `chartsPeriodAll`, `chartsAllTime`, `chartsNetAllTime`.

### Step 6 — Transactions card
- Tests: header dot / title / "N transactions · total"; close clears the slice (`chartsCloseTransactions`); row title = memo, falls back to category name; subtitle "MMM d · account" (+ " · original" for foreign rows); amount colour `expText` / `incText`; empty; show more; tap-to-edit, Slidable delete + undo, pending dimming still work.
- Code: `selected_slice_items_list.dart`, `slice_transaction_row.dart`.

### Step 7 — Account filter (AC 4, 5, 6, 7, 12, 14)
1. Repo (AC 14): `watchByCategoryInRange` / `watchByCurrencyInRange` (and the step-3 totals query) take `int? accountId`; tests with the two-account fixture; null = current output.
2. Selection: `accountFilterId`; `setAccountFilter(id)` clears the slice and switches Account → Category; `setDimension(account)` clears the filter; survives period / type / swipe.
3. Consumers (AC 5d, AC 12): category / currency / bucket / drill-down / summary totals carry `accountId` (captured with mocktail).
4. App-bar button + sheet (AC 5a-c): label, pill states, hidden while search is expanded, "Account filter: <label>" semantics; sheet lists every active account sorted by the current type's amount desc, zeros last, radio, tap applies + closes; donut centre "<Account> expense"; empty-state copy with account.
5. Bridge (AC 7): "See categories in <Account>" in the Account-dimension drill-down.

### Step 8 — Docs + whole-page check (AC 10)
- Whole-page widget test at 2× text scale, light and dark, Roboto loaded through `FontLoader`, asserting no overflow and rendered sizes.
- `PRD.md` § Analysis Screen; `docs/architecture/testing.md` § Charts.

### After step 8
`/code-review high` → fix → `/ce:compound`.

## 4. Deviation list

See the chat summary; confirmed decisions are recorded here once answered.

- **D14 (confirmed):** All's trend chart keeps one bar per month and scrolls
  horizontally instead of squeezing bars. Proposed detail (pending): up to 24
  months fill the width exactly as drawn (gap 4); beyond 24, each bar keeps the
  24-month width and the chart scrolls, opening at the right end (current
  month); the y scale and the average line use every month, not only the visible
  ones; the x labels scroll with the bars.

## 5. PRs and parallel work (confirmed: one PR per step)

Two shared hotspots decide the order: every step adds ARB strings (plus
`arb_audit_test.dart` and the generated `lib/l10n/`), and every UI step needs
`AnalysisColors`. Both go into one small foundation PR first, so later PRs touch
neither. `charts_section.dart` is still edited by several steps, but each edits
a different block, so the conflicts are small rebases.

| Wave | PRs (run in parallel within a wave)                                                                                                                                                                                                                                          | Needs merged first |
|------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------|
| 0    | **A** `AnalysisColors` + every new ARB key + audit · **Step 1** Day hides the trend                                                                                                                                                                                          | —                  |
| 1    | **Step 2** app bar, search, period track · **Step 3** summary card + totals query · **Step 4** breakdown card · **Step 5a** trend card · **Step 6** transactions card · **Step 7a** account-filter data layer (repo `accountId`, selection state, controller merging; no UI) | A                  |
| 2    | **Step 5b** All period (needs 2, 3, 5a, 7a) · **Step 7b** account-filter UI: app-bar button, sheet, summary filtering, centre text, empty-state copy, trend prefix, bridge (needs 2–6, 7a)                                                                                   | wave 1             |
| 3    | **Step 8** docs + whole-page 2× test                                                                                                                                                                                                                                         | wave 2             |
