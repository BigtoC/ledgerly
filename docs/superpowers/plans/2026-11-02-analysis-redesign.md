# Analysis Redesign — Implementation Plan

**Spec:** [`docs/superpowers/specs/2026-11-02-analysis-redesign-design.md`](../specs/2026-11-02-analysis-redesign-design.md) (revision `36207a9`)
**Visual source:** [`docs/design/analysis-redesign/Main.dc.html`](../../design/analysis-redesign/Main.dc.html) (identical to the design canvas, checked byte for byte)
**Branches:** one per PR, each cut from the latest `main` (§ 5)
**Status:** Approved 2026-11-02 — every deviation in § 4 is confirmed by the owner.

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
- Tests: chips switch dimension + selected semantics; donut 200×200, ring 26, no titles, unselected sections at alpha `0x4D`, selected does not grow; centre lines; rows: selected `sel` fill + w700, unselected rows keep full-opacity text while circle and bar fill fade to 0.35; mixed currencies hide bars + %; empty-state copy; icon ink by luminance > 0.35; currency-code ink by higher contrast (D24).
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

### Step 8 — Whole-page code review, whole-page check (AC 10), docs
Starts on the latest `main` once wave 2 has merged, so the page is reviewed as
users will get it. The per-PR reviews only saw one step's diff at a time.

1. **Whole-page code review.** Review every file that makes up the Analysis
   page as it stands now: not a diff, but `lib/ui/features/analysis/**`,
   `lib/ui/core/theme/analysis_colors.dart`, the repository / DAO methods the
   redesign added or changed, and their tests. Run it as parallel reviewers, one
   per lens below. Each finding is then checked by an independent agent trying
   to refute it, and only findings that survive are kept.
   - **Design fidelity, end to end:** every element against `Main.dc.html` in
     light and dark, state by state, following the artboard list in
     `docs/design/analysis-redesign/README.md` (default, Day, slice selected,
     dark, account sheet, account filtered, search expanded, All time).
     Deviations are allowed only as written in § 4.
   - **Behaviour across cards:** the account filter on every surface (summary,
     breakdown, trend, transactions, sheet, bridge); the All period on every
     surface; Day hiding the trend; every way to select and clear a slice (row,
     donut, donut centre, trend chip, close button); the stale-slice self-heal;
     scroll-to-rows; search replacing the charts.
   - **Consistency between the step PRs:** one way to read tokens, text styles
     (`analysisText`, `letterSpacing: 0`) and motion; the ripple policy the owner
     chose applied everywhere; no duplicated helpers, formatters or providers;
     consistent naming.
   - **Leftovers:** orphaned widgets, providers, ARB keys, tests, generated
     files and comments that still name removed pieces (`TypeToggle`,
     `ChartsNetTotalCard`, the `SegmentedButton`s, `chartsNoData`,
     `chartsNetTotal`, `watchNetByCurrencyInRange`, …).
   - **Architecture and performance** (AGENTS.md): layer boundaries,
     `@Dependencies`, no `keepAlive` on a family, no per-row `DateFormat` /
     `NumberFormat`, `setState` only on change, one `RepaintBoundary` per
     animated chart, no financial data in logs.
   - **Accessibility:** tap targets of at least 44 dp, semantics labels and
     selected states, text contrast with the tokens, 1.5× clamps only on
     fixed-size boxes.
   - **Test coverage:** each acceptance criterion (1–14) maps to at least one
     test that would fail without the behaviour; list any gaps.

   Fix the confirmed findings with TDD in the Step 8 PR. Anything that changes
   the design or the spec goes to the owner first.
2. **Whole-page check (AC 10).** A whole-page widget test at 2× text scale, in
   light and dark, with Roboto loaded through `FontLoader`. It asserts no
   overflow and checks rendered sizes, with the account filter on and the All
   period selected.
3. **Docs.** Update `PRD.md` § Analysis Screen and its folder tree, and
   `docs/architecture/testing.md` § Charts.

### After step 8
`/code-review high` on the Step 8 PR → fix → `/ce:compound`.

## 4. Deviation list

All items below are **confirmed**. They are the only places where the build
departs from `Main.dc.html` or fills a gap in the spec; anything else that
cannot be built as drawn must be raised before coding it.

- **D1 App bar stays pinned.** The design scrolls the header with the page.
  The app keeps a pinned `AppBar` because search results replace the charts and
  the search field must stay reachable. No scroll-under tint
  (`scrolledUnderElevation: 0`, `surfaceTintColor: transparent`). The app bar is
  fixed at 64, so its title, pill and field clamp text at 1.5×.
- **D2 An amount is never cut off** (widened 2026-11-02). Every money amount
  that is `nowrap` in the design and may not fit its space (summary tiles, net
  row, donut centre (max width 128), ranked rows, transaction rows, sheet rows,
  trend subtitle) is wrapped in `FittedBox(fit: BoxFit.scaleDown)`: 1:1 when it
  fits, shrunk only when it does not. An amount never ellipsizes or clips;
  the label next to it ellipsizes first. The donut centre also clamps text at
  1.5× (fixed-size box). Tests assert rendered sizes at 2× on a phone width.
- **D3 Minus glyph.** Use `MoneyFormatter.formatSigned` (intl's `-`), not the
  design's U+2212 `−`, everywhere a signed amount shows.
- **D4 Account icon and colour.** `account.icon ?? accountType.icon` and
  `account.color ?? accountType.color`, used by the Account-dimension rows and
  the account sheet (needs an analysis-local account-types lookup). The seeded
  Cash account therefore shows `#AEA9B4` + the wallet icon.
- **D5 Account sheet order.** Follow the spec: every active account, sorted by
  the current type's amount desc, zero-amount accounts last. Archived accounts
  are not listed, except the one the page is filtered by (D25). The "All
  accounts" row subtitle is `<type total> · 100.0%` (from the design).
- **D6 Donut gaps.** fl_chart draws a constant-width band, not the design's
  0.6 % wedge (2.79 → 3.77 px). Use `sectionsSpace: 3.28` (the wedge width at
  mid-ring), error ≤ 0.49 px; the gap is transparent, i.e. the card colour.
  Start at 12 o'clock (`startDegreeOffset: -90`, minus 1.08° so gaps sit where
  the CSS puts them).
- **D7 Dash pattern.** The design gives only `1.5px dashed`. Use `[3, 3]` for the
  average line and the 14 px legend dash.
- **D8 Future-dated transactions.** A future bucket with an amount draws a
  normal bar; an empty future bucket draws the 3 px `track` stub. The average
  counts elapsed buckets only. All's range ends at the start of next month, so
  transactions dated later are outside All (spec rule, accepted).
- **D9 Empty-state copy.** Use the spec strings ("No expense in this period"),
  also for All, not the design's "this month" / "yet". The account variant is
  two keys, `chartsEmptyTitleAccountExpense` / `chartsEmptyTitleAccountIncome`
  (`{account}`), because English needs a lowercase type word.
- **D10 Wide windows.** The account sheet opens as a `Dialog` (max width 480,
  radius 28, `card` fill) at width ≥ 600, per AGENTS.md; a bottom sheet below.
- **D12 Gaps the spec leaves open:**
  - A tile whose type has no convertible currency shows "—"; the excluded line
    lists both types' missing currencies; with both totals 0 the ratio bar is an
    empty track.
  - The summary card always renders (it is the type toggle); amounts show "—"
    while loading.
  - Mixed currencies (no grand total): donut-centre line 2 shows "—", line 3
    hides the percentage.
  - The stale-rate notice (`analysisRatesStale`) stays, as a line under the
    transactions-card subtitle, 13/18 `fg2`.
  - "Today" in the month x labels and the bold current-bucket label appear only
    at the current period.
  - Bar tooltips keep today's styling; the touched-bar width growth is removed.
  - All with no transactions: the navigator shows "All time" with no caption.
- **D13 All range source.** Add a reactive `watchDateBounds()` (the same MIN/MAX
  query as `getDateBounds()`, as a Drift stream) so adding or deleting the
  earliest transaction updates All. Bounds cover every transaction, unaffected
  by the type and account filters.
- **D14 All trend scrolls.** One bar per month, never squeezed. Up to 24 months
  fill the width exactly as drawn (gap 4). Beyond 24, each bar keeps the
  24-month width and the chart scrolls horizontally, opening at the right end
  (current month). The y scale and the average line use every month, not only
  the visible ones; the x labels scroll with the bars. The period swipe is
  already a no-op on All, so the gestures do not conflict.
- **D15 All x labels.** When the current month is January, the last bar shows
  the month name (bold), not the year. When the first month is not January, no
  year label is added for it (spec rule).

- **D16 Press and focus feedback.** The design draws no pressed, hover or
  focus states. Every tappable element keeps Material's default ink ripple and
  keyboard focus (`InkWell` / buttons, never a bare `GestureDetector`),
  including the period segments, chips, tiles, rows and the trend filter chip.
  The ripple is clipped to the element's visual shape (pill, tile, row radius).
- **D17 Trend filter chip width.** The chip is capped at half the header width
  minus the 12 gap and its label ellipsizes past that, so a long category name
  cannot squeeze the title away or overflow at 2×.
- **D18 Tapping the selected summary tile** clears the slice selection, as the
  design's `pick` does (the spec does not cover it).
- **D19 Accepted small choices** (spec and design silent):
  - Breakdown card: the title ellipsizes at 2× on a phone width; the loading
    spinner gets 24 vertical padding inside the card; while an older chart is
    still shown, the title and chips follow the charted data; the empty-state
    icon is `Icons.bar_chart`; the currency code in the 36 circle clamps at
    1.5×; `analysisAccountTypesById` lives in
    `search/view_models/analysis_providers.dart` (Step 7b reuses it).
  - Transactions card: a row whose account is missing shows only the date; the
    error state is the plain `analysisErrorMessage` text inside the card; the
    stale-rate line has no tabular figures.
  - Trend card: the average is rounded to whole minor units before formatting;
    the empty future stub has radius 1.5 (CSS caps a 2 px radius on a 3 px box).
  - Account sheet (7b): a short spinner while the sheet loads its rows (they
    are watched only while it is open); its error state is the plain
    `analysisErrorMessage` text; the filter clears itself when its account is
    deleted; the button's semantics hint is "Filter by account"; the button
    hides when its slot is narrower than 46 dp; the bridge label has line
    height 20; the ≥600 Dialog has no handle and keeps a 16 top inset.
- **D20 Scrolling All trend: edges** (2026-11-03). The chart scrolls through
  the card's 16 px padding, so at either end its bars sit where an unscrolled
  chart's would and the edge labels stay centred under their bars, as drawn.
  An edge label wider than that (large text scales) moves the bars in rather
  than being clipped. A tooltip near the viewport edge shifts by the least
  amount that keeps it inside the viewport.
- **D21 All's end is fixed when it is computed** (2026-11-03, known
  limitation). All runs to the start of next month as of when its range is
  computed. Left open across a month boundary, it misses the new month until
  the period is changed. Fixing it needs a clock seam to test; Step 8's
  whole-page review can revisit it.
- **D22 Trend x labels skip collisions** (2026-11-03). A label is never drawn
  over a neighbour. Labels are placed by priority: the current bucket first,
  then All's year labels, then the fixed Week / Month / Year labels left to
  right. A label whose centred rect would come within 2 dp of one already
  placed is skipped. Each label is measured with a `TextPainter` in the
  style `Text` resolves (`DefaultTextStyle` merge, bold-text setting) and
  `MediaQuery.textScalerOf`, once per layout rather than on every touch
  rebuild. So Year thins out at 2× on a phone, All drops the year under
  January when February is the current month, and Month drops a fixed day
  next to today. D20's edge insets use the placed labels.
- **D23 Period segment labels scale down to fit** (2026-11-03). Each label is
  one line (`maxLines: 1`, no soft wrap) in `FittedBox(fit: BoxFit.scaleDown)`:
  1:1 when it fits, shrunk only when it would not ('Month' and 'Week' at 2× on
  a phone), instead of breaking mid-word. The 44 minimum height is unchanged.
- **D24 Currency-code ink** (2026-11-03). The currency code in a ranked row's
  circle takes whichever of `#FFFFFF` and `#1B1B1B` has the higher WCAG
  contrast with the fill, computed, not a fixed threshold (an equivalent
  cut-off is about 0.204; 0.18 would put Neutral Variant 50 at 3.78:1). Red 60
  therefore gets `#1B1B1B` (5.43:1, not 3.17:1). Icon-only circles (ranked-row
  icons, the account sheet) keep the luminance > 0.35 rule, since icons need
  only 3:1.
- **D25 Archived filtered account stays listed** (2026-11-03). The account
  sheet lists the active accounts and also the archived account that is the
  current `accountFilterId`, with its amount and share, sorted by the same
  rule, so the sheet shows it checked. It covers both ways to get there: the
  Account-dimension bridge (archived accounts with transactions still get
  slices) and archiving an account from the Accounts screen while it is
  filtered.

(D11 was dropped: the account button left the breakdown header.)

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
| 3    | **Step 8** whole-page code review + fixes, whole-page 2× test, docs                                                                                                                                                                                                          | wave 2             |
