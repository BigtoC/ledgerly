# Analysis Redesign — Design Spec

**Status:** Approved design, not yet implemented
**Date:** 2026-11-02
**Feature:** Analysis tab — visual + UX redesign, hide the bar chart on Day, account filter for the breakdown
**Visual source of truth:** [`docs/design/analysis-redesign/Main.dc.html`](../../design/analysis-redesign/Main.dc.html) (see that folder's README for how to read it)

---

## How to use this spec

- **Behaviour** comes from this file. **Exact visual values** (sizes, paddings,
  radii, font sizes, colours, per-state styles) come from `Main.dc.html`. When a
  value is listed here it was copied from that file; if the two ever disagree,
  `Main.dc.html` wins for visuals and this file wins for behaviour.
- `PRD.md` still wins on architecture, layering, and dependencies. Update the
  PRD Analysis entry (§ "Analysis Screen", ~line 976) when this ships.
- Do not "improve" the design while implementing. If something cannot be built
  as drawn (missing data, Flutter limitation, a11y conflict), stop and list it as
  a proposed deviation with a reason before writing code for it.
- Mock data in the design file is not app data.

## Overview

The current Analysis tab stacks three full-width `SegmentedButton` rows
(period, type, dimension) and an unlabeled net pill above the charts. The
redesign:

1. Collapses the controls: one period track + a period navigator.
2. Replaces the type toggle and the net pill with a **summary card** whose two
   tiles (Expense / Income) are the type toggle and show both totals.
3. Restyles the pie + legend into a **breakdown card** (donut + ranked rows with
   share bars) and moves the dimension toggle into it as chips.
4. Adds a page-wide **account filter** in the app bar ("show me everything,
   including the categories, for one account") and an **All** period that
   covers every record.
5. Restyles the bar chart into a **trend card** with an average line, and
   **hides it entirely when the period is Day**.
6. Restyles the drill-down list into a **transactions card**.

### Scope

- Analysis tab charts area (`lib/ui/features/analysis/charts/**`), plus the
  search field styling in `analysis_screen.dart`.
- New repository filters needed by the account filter and the summary totals.
- New l10n strings in all four ARB files.

### Out of scope

- Search results UI and memo-search behaviour (unchanged).
- Period swipe gesture and slide animation (keep as is).
- Drill-down delete + undo, tap-to-edit, stale-rate notice, row paging (keep the
  logic; restyle only).
- FX banners (`chartsRatesRequired`, `chartsAutoSwitchedToCurrency`,
  `chartsExcludedCurrencies`, mixed-currency note): keep the behaviour and
  their position above the breakdown card.
- Category palette values (append-only; do not change `kCategoryColorPalette`).

---

## Theme tokens

Add one `ThemeExtension` (e.g. `AnalysisColors` in `lib/ui/core/theme/`),
registered in `app_theme.dart` for light and dark, so the screen uses these
exact values instead of approximating with `ColorScheme` roles.

| Token | Light | Dark | Used for |
|---|---|---|---|
| `bg` | `#F3F3F3` | `#131313` | Page background behind cards |
| `card` | `#FFFFFF` | `#1E1E1E` | Cards, search field, bottom sheet |
| `line` | `#E3E3E3` | `#2E2E2E` | Card borders (1px), dividers, unselected tile border |
| `outline` | `#C4C4C4` | `#4A4A4A` | Unselected chip/pill border, sheet drag handle |
| `track` | `#EAEAEA` | `#2A2A2A` | Period track, share-bar track, ratio-bar track, future-bucket stubs |
| `thumb` | `#FFFFFF` | `#3D3D3D` | Selected period segment |
| `fg` | `#1B1B1B` | `#E6E6E6` | Primary text |
| `fg2` | `#474747` | `#C6C6C6` | Secondary text, unselected labels |
| `fg3` | `#5E5E5E` | `#A3A3A3` | Captions, percentages, axis labels, avg line |
| `off` | `#BDBDBD` | `#555555` | Disabled icon (next-period at current period) |
| `sel` | `#F0F0F0` | `#2C2C2C` | Selected row / active filter pill / filter chip background |
| `onBg` / `onFg` | `#1B1B1B` / `#FFFFFF` | `#E6E6E6` / `#1B1B1B` | Selected dimension chip fill / text |
| `exp` | `#FF4081` | `#FF4081` | Expense fill: bars, dot, ratio bar, selected tile border |
| `expText` | `#C2185B` | `#FF79A3` | Expense text, negative net, primary text button, radio accent |
| `expTint` | `#FFF0F5` | `#35161F` | Selected Expense tile background |
| `inc` | `#43A047` | `#66BB6A` | Income fill |
| `incText` | `#1B5E20` | `#81C784` | Income text, positive net |
| `incTint` | `#EFF7EF` | `#16271A` | Selected Income tile background |
| `nav` / `navIndicator` | `#EBEBEB` / `#D6D6D6` | `#1E1E1E` / `#3A3A3A` | Reference only — the shell's NavigationBar is not part of this change |

Thumb shadow (light): `0 1px 3px rgba(0,0,0,.12), 0 1px 1px rgba(0,0,0,.06)`;
dark: `0 1px 2px rgba(0,0,0,.5)`.

Typography: platform default font (no new font package). Weights used: 400,
500, 700. Amounts use tabular figures (`FontFeature.tabularFigures()`).

Motion: standard curve `Cubic(0.2, 0.6, 0.2, 1)` at 200 ms for state colour
changes; `Cubic(0.16, 1, 0.3, 1)` at 360 ms for bar heights and share-bar widths.

---

## Page structure (top → bottom)

All cards: margin 16 horizontal, radius 20, `card` fill, 1px `line` border, no
shadow. Vertical gap between blocks as in the design (16 above the summary card,
12 between cards, 24 bottom padding).

### 1. App bar (title, account filter, collapsible search)

There is no permanent search field any more. Height 64, padding 0 8 0 20,
gap 12. Title "Analysis" 24/32 w500 `fg` on the left (never hidden). On the
right, a row aligned to the end with gap 4:

- **Collapsed (default):** the **account filter button** (§ Account filter)
  followed by a 48×48 search icon button (`Icons.search` 24 `fg`, semantics
  "Search memos", collapsed).
- **Expanded:** tapping the search button grows a search field **leftwards**
  from the button's position until it fills the space to the right of the
  title (width 48 → 100% of the right-hand area, 280 ms, `Cubic(0.16, 1, 0.3, 1)`;
  right edge fixed). The account filter button is **hidden** while expanded.
  - Field: height 48, radius 24, `card` fill + 1px `line` border (transparent
    border/fill while collapsed), gap 10.
  - Contents: `Icons.search` 20 `fg2` (left inset 14) · input (15/20 `fg`;
    hint "Search memos" `fg2`; semantics label `analysisSearchPrompt`) ·
    44×44 close button (`Icons.close` 20 `fg2`, "Close search").
  - Opening focuses the input. Close collapses the field, clears the query
    (same as today's clear) and brings the account button back.
  - Keep the IME composing guard, the 300 ms debounce, and the search results
    / empty / loading states that replace the charts while a query is active.
  - At large text scales the hint may ellipsize; the row height stays 64 and
    the field clamps at 1.5× like the old search bar.

### 2. (removed — the search field now lives in the app bar)

### 3. Period track (replaces the 4-way `SegmentedButton`)

Five options: **Day · Week · Month · Year · All** (All is new — see § All
time). Padding 8 16 0. Track: `track` fill, radius 25, padding 3, 5 equal
columns, gap 2. Segment: height 44, radius 22, label 14 w500. Selected: `thumb` fill +
thumb shadow, `fg` text. Unselected: transparent, `fg2` text. Each segment is a
button with selected semantics. The label stays on one line: 1:1 when it fits,
scaled down only when it would not (large text scales on a phone).
(2026-11-03, plan D23.)

### 4. Period navigator

Padding 8 8 0. Row: 48×48 icon button (`Icons.chevron_left`, 24, `fg`), centred
column, 48×48 icon button (`Icons.chevron_right`; disabled with `off` colour at
the current period — existing rule).

- Line 1: period label 18/24 w500 `fg` (existing `_formatLabel` output).
- Line 2: caption 12/16 `fg3` — "Today" / "This week" / "This month" / "This
  year" **only when at the current period**; otherwise omit the line (no new
  behaviour beyond that).
- **All:** label "All time"; caption = the covered range, "<MMM yyyy of the
  first transaction> – <MMM yyyy now>" (e.g. "Jan 2025 – Oct 2026"). Both
  chevron buttons are hidden (keep their 48 px slots so the label stays
  centred) and the period swipe gesture does nothing.

### All time (new period)

- Add `PeriodType.all`. Range = `[first day of the month of the earliest
  transaction, start of next month)`, using `getDateBounds()`; with no
  transactions it behaves like an empty period.
- Every surface uses that range: summary card, breakdown, trend, transactions.
- Trend uses **monthly** buckets across the whole range (like Year), title
  "Monthly spending/income", average per month over elapsed months.
- X labels: the year ("2025", "2026") under each January, plus the current
  month's short name ("Oct") under the last bar; everything else blank. Bar
  gap 4, top radius 3.
- `previousPeriod` / `nextPeriod` / swipe are no-ops on All; switching to All
  ignores `anchorDate`.

### 5. Summary card (replaces `TypeToggle` and `ChartsNetTotalCard`)

Padding 12, column gap 12.

**Tiles** — 2 equal columns, gap 8. Each tile is the type toggle for its type.
- Padding 12 14, radius 14, border 1.5px, column gap 4, align start.
- Selected Expense: border `exp`, fill `expTint`, label `expText`.
  Selected Income: border `inc`, fill `incTint`, label `incText`.
  Unselected: border `line`, transparent fill, label `fg2`.
- Label row: 8×8 dot (`exp` / `inc`, always coloured) + gap 6 + label 13/18
  w500 (`chartsTypeExpense` / `chartsTypeIncome`).
- Amount: 18/24 w500 `fg`, tabular, no wrap. Converted total of that type for
  the period in the default currency.
- Tapping a tile sets the chart type (and clears the slice selection, as
  `toggleType` does today). Semantics: button, selected.

**Ratio bar** — height 6, radius 3, `track` background, two segments with gap
3: expense (`exp`) and income (`inc`) whose widths are proportional to the two
totals. Decorative (exclude from semantics).

**Net row** — horizontal padding 4, space-between, baseline aligned.
- Label 14/20 `fg2`: "Net today" / "Net this week" / "Net this month" / "Net
  this year" / "Net all time" by period.
- Amount 16/24 w500 tabular, signed (`MoneyFormatter.formatSigned`):
  `incText` when > 0, `expText` when < 0, `fg` at 0, "—" when unavailable.
- Keep the existing excluded-currencies line under it (bodySmall) when non-empty.

The summary card **follows the account filter**: with an account selected,
both tiles, the ratio bar and the net show only that account's transactions.

### 6. Breakdown card (restyles pie + legend; hosts dimension + account filter)

Padding 16 0 8.

**Header** (padding 0 16, column gap 4)
- Title 16/24 w500 `fg`: "Expense breakdown" / "Income breakdown". (The
  account filter button moved to the app bar.)
- Dimension chips (replaces `DimensionToggle`): wrap row, gap 8. Each chip is a
  44-high button containing a 32-high pill: padding 0 14, radius 16, 14/20 w500,
  1px border. Selected: `onBg` fill + border, `onFg` text. Unselected:
  transparent, `outline` border, `fg2` text.

**Donut** (replaces `CategoryPieChart` styling)
- 200×200, centred, margin 12 vertical. Ring thickness 26 (inner diameter 148).
- No text on sections (remove the % titles). Thin gaps between sections
  (≈0.6% of the circle, in `card` colour).
- When a slice is selected: non-selected sections at 30% alpha; the selected
  section keeps full colour and does **not** grow.
- Centre (padding 0 10, column gap 2, centred):
  - Line 1, 12/16, max width 128, ellipsis:
    no selection → "Total expense" / "Total income" (`fg2`, w400);
    account filter active → "<Account> expense" / "<Account> income" (`fg2`);
    slice selected → slice label (`fg`, w500).
  - Line 2, amount 17/24 w500 `fg`, tabular: grand total, filtered total, or
    slice total.
  - Line 3, 12/16 `fg3`: "7 categories" / "3 accounts" / "2 currencies"
    (pluralised by dimension), or "42.0% of expense" when a slice is selected.
- Keep tap-to-select / tap-centre-to-clear and the semantics label.

**Ranked rows** (replaces the `Card` legend)
- List padding 0 8. Rows sorted by amount desc (existing).
- Row: full-width button, padding 10 8, radius 14, row gap 12, align centre.
  Selected row: `sel` fill; others transparent.
- Leading: 36×36 circle filled with the slice colour; icon 18 inside. Icon
  colour: `#1B1B1B` when the fill's relative luminance > 0.35, else `#FFFFFF`.
  Currency slices (no icon key) show the currency code text, 10 w700,
  letter-spacing 0.3, in whichever of `#1B1B1B` and `#FFFFFF` has the higher
  WCAG contrast with the fill, computed rather than a fixed threshold (small
  text needs 4.5:1; icons need only 3:1). (2026-11-03, plan D24.)
- Middle column (gap 6):
  - Top line, space-between, baseline: label 15/20 (w500; w700 when selected),
    `fg`, ellipsis | amount 15/20 w500 `fg` tabular.
  - Bottom line, gap 8: share bar (flex, height 4, radius 2, `track`; fill =
    `fraction` width in the slice colour) | percentage 12/16 `fg3`, min width
    40, right-aligned, one decimal ("42.0%").
  - When `fraction` is null (mixed currencies) hide both the bar and the %.
- Trailing `Icons.chevron_right` 18 `fg3`.
- When a selection exists, **unselected rows fade only the leading circle and
  the share-bar fill to 35% opacity — text is never faded** (keeps 4.5:1).
- Tap toggles the slice selection (existing).

**Empty state** (inside the card, replaces the chart when there is no data)
- Padding 32 24, centred column, gap 8: 48×48 `track` circle with a chart icon
  (22, `fg2`); title 15/20 w500 `fg`; subtitle 13/18 `fg2`.
- Title: "No expense in this period" / "No income in this period"; with an
  account filter: "No expense on <Account> in this period".
- Subtitle: "Switch to Income or pick another period." (type swapped
  accordingly); with an account filter: "Pick another account or period."

### 7. Trend card (restyles `DailyBarChart`)

**Hidden entirely when the period is Day.** Otherwise shown under the same
conditions as the bar chart today (has buckets, not currency-dimension with
mixed currencies).

Padding 16, column gap 12.

- **Header** (min height 44, space-between, align start):
  - Title 16/24 w500 `fg`: "Daily spending" (week, month), "Monthly spending"
    (year); "Daily income" / "Monthly income" for income.
  - Subtitle 13/18 `fg2`, tabular, preceded by a 14-wide 1.5px dashed `fg3`
    line (legend for the average line): "Avg <amount> / day" (week, month) or
    "Avg <amount> / month" (year). Prefix "<Account> · " when the account
    filter is active.
  - Average = sum of known buckets ÷ number of elapsed buckets (exclude future
    buckets).
  - When a slice is selected: a filter chip on the right — 44 hit target, pill
    32 high, padding 0 8 0 10, radius 16, `sel` fill, 8px dot in the slice
    colour + label 13 w500 `fg` + `Icons.close` 16 `fg2`. Tapping clears the
    slice selection. Semantics label "Showing <label> only. Clear filter".
- **Chart** 140 high, 1px `line` baseline. Bars bottom-aligned, equal width,
  gaps: week 10, month 3, year 6. Top radius 3 (month) / 6 (week, year), bottom
  radius 1/2. Colour: the selected slice's colour when a slice is selected,
  else `exp` / `inc` by type — **solid, no gradient**. Elapsed zero buckets have
  no bar. Future buckets: 3-high `track` stub. Y max = max bucket × 1.12.
- **Average line**: 1.5px dashed `fg3`, full width, at the average's height;
  hidden when the average is 0.
- **X labels** (row with the same gaps, margin-top −4): 11/14 `fg3`; the
  current bucket's label 700 `fg`. Week: Mon…Sun. Month: day numbers for days
  1, 8, 15, 22, 29 and today only. Year: Jan…Dec. Labels are centred under
  their bar and may overflow it, but never overlap a neighbour: they are
  placed by priority (the current bucket, then All's year labels, then the
  fixed labels left to right), and a label whose rect would come within 2 dp
  of one already placed is skipped, measured at the current text scale.
  (2026-11-03, plan D22.)
- Keep touch tooltips and the chart semantics label.

### 8. Transactions card (restyles `SelectedSliceItemsList`)

Shown only when a slice is selected (existing). Padding 8 0.

- **Header** (padding 8 8 8 16, gap 12): 12×12 dot in the slice colour; column
  with title 16/24 w500 (slice label) and subtitle 13/18 `fg2` tabular
  "<N> transactions · <slice total>" (`analysisTransactionCount`); 48×48 close
  button (`Icons.close` 20 `fg2`, tooltip/semantics "Close transactions") →
  clears the slice selection.
- **Bridge button** — only in the Account dimension: below the header,
  padding 0 16 8, outlined pill 44 high, radius 22, padding 0 12 0 14, 1px
  `outline` border, 14 w500 `fg`, trailing chevron 16: "See categories in
  <Account>". Tap → account filter = that account, dimension = Category, slice
  cleared.
- **Rows**: 1px `line` top divider each; padding 12 16, gap 12.
  - Title 15/20 `fg`, ellipsis: the transaction **memo** (fall back to the
    category display name when the memo is empty).
  - Subtitle 13/18 `fg2`, ellipsis: "<MMM d> · <account name>", plus
    " · <original amount>" for foreign-currency rows (replaces the separate
    "Original amount" label).
  - Amount 15/20 w500 tabular, signed, `expText` / `incText` by type.
  - Keep tap-to-edit, Slidable delete + undo snackbar, pending-delete dimming.
- **Empty**: 1px top divider, padding 16, centred 14/20 `fg2`
  `analysisDrilldownEmpty`.
- **Show more**: top divider, padding 4 8 0, centred text button 44 high,
  14 w500 `expText` (`analysisDrilldownShowMore`, existing paging).

---

## Account filter (new)

**Goal:** pick one account and see the whole page — totals, categories,
trend, transactions — for that account only.

### State

- Add `int? accountFilterId` to `ChartsSelection`. `null` = all accounts.
- Kept across period changes, type changes, and swipes. When the type changes
  and the account has no transactions of the new type, keep the filter (the
  empty state explains it).
- Choosing the **Account** dimension chip clears the filter.
- Picking an account while the dimension is **Account** switches the dimension
  to **Category**.
- Setting or clearing the filter clears the slice selection.

### What it affects

| Area | Filtered? |
|---|---|
| Summary card (both tiles, ratio bar, net) | Yes |
| Breakdown slices — Category, Currency dimensions | Yes |
| Donut centre text | Yes ("<Account> expense") |
| Trend buckets + average | Yes (`watchTimeBucketsInRange(accountId:)` already exists) |
| Transactions card | Yes (`watchTransactionsForSliceInRange(accountId:)` already exists; combine with the slice's own filter) |

`selectionFilters` (or its caller) must merge the account filter with the
selected slice so a category slice under an account filter queries
`categoryId` **and** `accountId`.

### Data layer

- `watchByCategoryInRange` and `watchByCurrencyInRange` gain an optional
  `int? accountId` filter (null = today's behaviour, regression-protected like
  the time-bucket filters).
- Summary tiles need converted **expense and income totals** for the period
  (today only the net is available). Extend the net-total provider path to
  expose per-currency expense and income totals (one query grouped by
  type + currency, with the same optional `accountId` filter), and derive net
  from them so the card stays consistent.
- Account sheet rows need each account's converted total for the period and
  type (reuse `watchByAccountInRange`).

### Filter button (app bar, left of the search button)

- Lives in the app bar (§ 1), immediately left of the search icon button;
  hidden while search is expanded.
- 44-high hit target; pill 32 high, padding 0 8 0 12, radius 16, gap 4, 13/18
  w500, max width 150, label ellipsis. Content: label + `Icons.expand_more` 16.
  **No wallet icon.**
- Inactive: label "All accounts", transparent, `outline` border, `fg2`.
- Active: label = account name, `sel` fill, `fg2` border, `fg` text.
- Semantics: button, "Account filter: <label>", opens a dialog.

### Account sheet

Modal bottom sheet (`showModalBottomSheet`, matching the app's other picker
sheets), `card` fill, top radius 28, bottom padding 24, scrim at 32% black.

- Drag handle: 32×4, radius 2, `outline`, padding 16 0 8.
- Header (padding 8 24 12, gap 2): "Filter by account" 20/28 w500 `fg`;
  subtitle 14/20 `fg2` "Filters the whole page · <period label>".
- Rows (list padding 0 12, gap 2), one radio group:
  - First row "All accounts" (icon `Icons.layers_outlined` on a `track`
    circle, `fg2`), then **every active account** (expense and income
    accounts alike), sorted by the current type's amount desc; accounts with
    0 in the period come last and stay selectable. Row amounts and shares
    are for the current chart type. When the page is filtered by an archived
    account (through the bridge, or archived while filtered), that account is
    listed too, sorted the same way, so the sheet shows the current filter
    checked. (2026-11-03, plan D25.)
  - Row: min height 64, padding 8 12, radius 16, gap 16; selected row `sel`
    fill. 40×40 circle (account type colour + account type icon 20, ink by the
    same luminance rule). Column: name 16/22 (w700 when selected, else w400)
    `fg`; subtitle 13/18 `fg2` tabular "<amount> · <share>%" of the type total.
    Trailing `Radio` (active colour `expText`).
  - Tapping a row applies the filter and closes the sheet.

---

## Strings (all four ARB files)

Reuse existing keys where possible (`chartsTypeExpense`, `chartsTypeIncome`,
`chartsDimension*`, `chartsPeriod*`, `analysisTransactionCount`,
`analysisDrilldownEmpty`, `analysisDrilldownShowMore`). New keys (names are a
suggestion; follow the file's existing `@key` description convention):

| Key | en | zh_TW | zh_CN |
|---|---|---|---|
| `chartsNetToday` / `ThisWeek` / `ThisMonth` / `ThisYear` | Net today / Net this week / Net this month / Net this year | 今日淨額 / 本週淨額 / 本月淨額 / 今年淨額 | 今日净额 / 本周净额 / 本月净额 / 今年净额 |
| `chartsCaptionToday` / `ThisWeek` / `ThisMonth` / `ThisYear` | Today / This week / This month / This year | 今天 / 本週 / 本月 / 今年 | 今天 / 本周 / 本月 / 今年 |
| `chartsBreakdownExpense` / `Income` | Expense breakdown / Income breakdown | 支出分佈 / 收入分佈 | 支出分布 / 收入分布 |
| `chartsTotalExpense` / `Income` | Total expense / Total income | 總支出 / 總收入 | 总支出 / 总收入 |
| `chartsAccountExpense` / `Income` (`{account}`) | {account} expense / {account} income | {account} 支出 / {account} 收入 | {account} 支出 / {account} 收入 |
| `chartsShareOfExpense` / `Income` (`{percent}`) | {percent} of expense / {percent} of income | 佔支出 {percent} / 佔收入 {percent} | 占支出 {percent} / 占收入 {percent} |
| `chartsCategoryCount` / `AccountCount` / `CurrencyCount` (plural) | {count} categories… | {count} 個類別 / 帳戶 / 幣別 | {count} 个类别 / 账户 / 币种 |
| `chartsTrendDailySpending` / `MonthlySpending` / `DailyIncome` / `MonthlyIncome` | Daily spending / Monthly spending / Daily income / Monthly income | 每日支出 / 每月支出 / 每日收入 / 每月收入 | 每日支出 / 每月支出 / 每日收入 / 每月收入 |
| `chartsAvgPerDay` / `PerMonth` (`{amount}`) | Avg {amount} / day · Avg {amount} / month | 平均每日 {amount} / 平均每月 {amount} | 平均每日 {amount} / 平均每月 {amount} |
| `analysisSearchHint` | Search memos | 搜尋備註 | 搜索备注 |
| `analysisSearchOpen` / `analysisSearchClose` | Search memos / Close search | 搜尋備註 / 關閉搜尋 | 搜索备注 / 关闭搜索 |
| `chartsAllAccounts` | All accounts | 所有帳戶 | 所有账户 |
| `chartsAccountFilterLabel` (`{label}`) | Account filter: {label} | 帳戶篩選：{label} | 账户筛选：{label} |
| `chartsFilterByAccount` | Filter by account | 依帳戶篩選 | 按账户筛选 |
| `chartsFilterSheetSubtitle` (`{period}`) | Filters the whole page · {period} | 套用到整個頁面 · {period} | 应用到整个页面 · {period} |
| `chartsPeriodAll` | All | 全部 | 全部 |
| `chartsAllTime` | All time | 全部時間 | 全部时间 |
| `chartsNetAllTime` | Net all time | 累計淨額 | 累计净额 |
| `chartsSeeCategoriesIn` (`{account}`) | See categories in {account} | 查看 {account} 的類別 | 查看 {account} 的类别 |
| `chartsClearSliceFilter` (`{label}`) | Showing {label} only. Clear filter | 只顯示 {label}，清除篩選 | 只显示 {label}，清除筛选 |
| `chartsCloseTransactions` | Close transactions | 關閉交易列表 | 关闭交易列表 |
| `chartsEmptyTitleExpense` / `Income` | No expense in this period / No income in this period | 此期間沒有支出 / 此期間沒有收入 | 此期间没有支出 / 此期间没有收入 |
| `chartsEmptyTitleAccount` (`{type}`, `{account}`) | No {type} on {account} in this period | {account} 此期間沒有{type} | {account} 此期间没有{type} |
| `chartsEmptySwitchType` (`{type}`) | Switch to {type} or pick another period. | 切換到{type}或選擇其他期間。 | 切换到{type}或选择其他期间。 |
| `chartsEmptyPickAnother` | Pick another account or period. | 請選擇其他帳戶或期間。 | 请选择其他账户或期间。 |

`app_zh.arb` (base `zh`) mirrors whichever variant it currently mirrors for
existing chart keys. Remove `chartsNetTotal` only if nothing references it.

---

## Accessibility

- Every tappable element is ≥ 44×44 (visual pills sit inside 44 hit targets).
- Text contrast ≥ 4.5:1 in both themes with the tokens above; never fade text
  to show de-emphasis.
- Survive 2× text scale with no overflow (scrollable page); fixed-height
  elements (search row) keep the existing 1.5× clamp.
- Tiles, tabs and chips expose selected state; the donut and trend chart keep
  their summary semantics labels.

## Acceptance criteria (write these as tests first)

Widget tests under `test/widget/features/analysis/`, overriding providers the
way `docs/architecture/testing.md` § Charts describes. The project does not
use golden tests.

1. Period Day → no trend card (`DailyBarChart` absent); Week / Month / Year
   with data → present.
2. Tapping the Income tile switches the chart type; tiles show both converted
   totals; the selected tile reports selected semantics.
3. Net row label matches the period; colour follows the sign.
4. Dimension chips switch the dimension; choosing Account clears the account
   filter.
5. Account sheet: picking an account (a) updates the filter button label,
   (b) limits breakdown rows to that account's categories, (c) changes the
   donut centre line to "<Account> expense", (d) queries buckets and the
   drill-down with that `accountId`. "All accounts" clears it.
6. Picking an account while in the Account dimension switches to Category.
7. Bridge button in an account drill-down applies the filter, switches to
   Category and clears the slice.
8. With a slice selected, unselected rows keep full-opacity text; the trend
   header shows the filter chip and tapping it clears the selection.
9. Mixed-currency slices hide share bars and percentages.
10. No overflow at 2× text scale (light and dark).
11. Search: the app bar shows the account button + a search icon; tapping the
    icon expands the field (input focused) and hides the account button;
    close collapses it, clears the query and shows the account button again;
    typing still shows search results in place of the charts.
12. Account filter also changes the summary tiles and net (e.g. Visa card →
    Expense = Visa card's expense, Income = Visa card's income).
13. All: five period options; All shows "All time" with the covered range,
    hides both chevrons, ignores swipes, and the trend shows one bar per
    month from the first transaction's month to now.
14. Repository: `watchByCategoryInRange` / `watchByCurrencyInRange` with
    `accountId` return only that account's rows; null keeps current output.

## Suggested order (one PR-sized slice each)

1. Hide the trend card on Day (+ test 1).
2. `AnalysisColors` theme extension; app bar (collapsible search); period
   track + navigator.
3. Summary card (data: per-type totals) — replaces TypeToggle + net card.
4. Breakdown card: chips, donut, ranked rows, empty state.
5. Trend card restyle + average line + filter chip; then the All period.
6. Transactions card restyle.
7. Account filter: repository filters → selection state → button + sheet →
   bridge button.
8. Docs: PRD § Analysis Screen, `docs/architecture/testing.md` § Charts.
