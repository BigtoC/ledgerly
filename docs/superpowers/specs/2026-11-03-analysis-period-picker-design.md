# Analysis Period Picker — Design Spec

**Status:** Draft, awaiting review
**Date:** 2026-11-03
**Issue:** [#73 — Difficult to select a longer time range in the Analysis page](https://github.com/BigtoC/ledgerly/issues/73)
**Feature:** Analysis tab — tap the period label to pick a day, week, month or year from a calendar that matches the selected period
**Builds on:** [`2026-11-02-analysis-redesign-design.md`](2026-11-02-analysis-redesign-design.md) § 4 Period navigator, § Theme tokens
**Visual source of truth:** [`docs/design/analysis-redesign/Main.dc.html`](../../design/analysis-redesign/Main.dc.html) — the picker lives in the same prototype (`picker`, `pickerView`, `anchor` props; artboards listed in that folder's README)

---

## How to use this spec

- Same rules as the redesign spec: **behaviour** comes from this file, **exact
  visual values** come from `Main.dc.html` (`pk*` values in `renderVals()` and
  the `pkShow` sheet markup). If they disagree, `Main.dc.html` wins for visuals
  and this file wins for behaviour.
- `PRD.md` still wins on architecture, layering and dependencies.
- Do not "improve" the design while implementing. If something cannot be built
  as drawn, stop and list it as a proposed deviation with a reason first.
- The prototype's fixed "today" (Sat, Oct 31, 2026), first record (Jan 6, 2025)
  and amounts are mock data. Picking a period in the prototype changes the
  labels only.

## Problem

The period navigator moves one period per tap (or swipe). Reaching a week a
year ago takes about 52 taps; a day two months ago, about 60. The issue asks
for a calendar behind the date label whose type follows the selected period:
Day picks a day, Week picks a week, and so on.

## Overview

1. On Day, Week, Month and Year, the navigator's label becomes a button with a
   caret. Tapping it opens a **period picker**.
2. The picker opens on the selected period and shows the unit of that period:
   days, weeks, months or years.
3. Its browse title drills **up** (days/weeks → months → years) so any period
   since the first record is a few taps away. Picking at a higher level drills
   back **down**.
4. Picking a cell of the period's own unit applies it and closes the picker.

### Scope

- `lib/ui/features/analysis/charts/views/period_selector.dart` (label button,
  caret).
- New `period_picker_sheet.dart` in the same `views/` folder.
- `ChartsSelectionController.setAnchor` (+ regenerated `.g.dart`).
- An ISO week-number helper in `lib/core/utils/date_helpers.dart`.
- New l10n strings in all four ARB files.

### Out of scope

- Custom ranges (arbitrary start–end). The picker only chooses one period of
  the current type.
- ‹ › chevrons and the swipe gesture: unchanged, including that they have no
  lower bound.
- The All period: no picker.
- Marking days or weeks that have transactions.
- Repository or schema changes: the picker reuses `chartsDateBoundsProvider`.

---

## Behaviour

### 1. Entry point — the period label

- **Day / Week / Month / Year:** the centre column of `PeriodNavigator` is one
  button (min height 48, padding 4 12, radius 16, column gap 2).
  - Line 1: the period label (unchanged text and style) + gap 4 +
    `Icons.expand_more` 18 `fg2`.
  - Line 2: the caption, unchanged ("Today" / "This week" / … only at the
    current period).
  - While the picker is open the button has a `sel` fill and the caret
    **rotates 180° to point up** (200 ms, standard curve). It rotates back
    when the picker closes, however it closes.
  - Semantics: button, expanded/collapsed, label "<picker title>. Selected:
    <period label>" (e.g. "Choose a week. Selected: Oct 26–Nov 1, 2026").
- **All:** unchanged — plain text, no caret, not tappable; chevrons stay hidden.
- The ‹ › buttons keep their 48 px slots and behaviour.

### 2. Presentation

Follow `showAccountFilterSheet` exactly:

- Width < 600: `showModalBottomSheet` (`isScrollControlled`, `useSafeArea`),
  `card` surface, top radius 28, shadow `0 -2px 16px rgba(0,0,0,.12)`, scrim
  32% black, drag handle 32×4 (`outline`, padding 16 0 8), bottom padding 24.
- Width ≥ 600: `Dialog`, radius 28, max width 480, same scrim, no drag handle.

### 3. Picker layout (top → bottom)

1. **Header** (padding 8 16 8 24, gap 8):
   - Title 20/28 w500 `fg`: "Choose a day" / "Choose a week" / "Choose a
     month" / "Choose a year".
   - Subtitle 14/20 `fg2`, tabular: "Selected: <period label>".
   - Trailing **Now** text button (height 40, padding 0 12, radius 20, 14 w500
     `expText`): "Today" / "This week" / "This month" / "This year" (reuse
     `chartsCaption*`). Applies the current period and closes.
2. **Browse bar** (padding 4 8 4 12): a title button (16/22 w500 `fg` +
   `Icons.expand_more` 18 `fg2`, height 40, radius 20) on the left; 48×48
   previous / next icon buttons (`chevron_left` / `chevron_right` 24, `fg`,
   disabled `off`) on the right.
3. **Body** — one of the four views below.
4. **Footnote** 12/16 `fg3`, margin 12 24 0: "Records start <MMM d, yyyy>."
   (date of the earliest transaction). Omitted when there are no transactions.

### 4. Views and drilling

The picker has four views. It opens on the view for the period's unit:

| Period | Opens on | Browse title | ‹ › step | Tapping the title |
|---|---|---|---|---|
| Day | Days | `MMMM yyyy` of the browsed month | 1 month | → Months |
| Week | Weeks | `MMMM yyyy` of the browsed month | 1 month | → Months |
| Month | Months | `yyyy` of the browsed year | 1 year | → Years |
| Year | Years | "<first year> – <current year>" (plain text) | hidden | — |

In the Months view reached from Day/Week, tapping the title goes to Years.

- **Picking a cell of the period's own unit** applies it (§ 6).
- **Picking a higher-level cell drills down:** a year opens Months for that
  year; a month (on Day/Week) opens Days/Weeks for that month.
- View and browsed month/year are local picker state, dropped on close. The
  next open starts again from the selected period.
- The picker opens on the selected period: Days/Weeks show the month that
  contains the anchor (for Week, the month of the anchor's Monday); Months
  shows the anchor's year.

#### Days view

- Weekday header row, height 32, 12/16 w500 `fg3`: narrow weekday names
  (`DateFormat('EEEEE', locale)`), **Monday first** to match
  `DateHelpers.startOfWeek`.
- 7 equal columns, row gap 2. Blank cells before the 1st (not focusable).
- Cell: 44 high, a 40×40 circle centred, 14/20 tabular.
  - Selected (the anchor day): `onBg` fill, `onFg` text, w500.
  - Today, not selected: 1px `fg` ring.
  - Disabled (§ 5): `off` text.

#### Weeks view

- Header row as Days, with a leading 40-wide "Wk" column.
- One button row per **Monday-start week that touches the browsed month**
  (4–6 rows), gap 4. Row: 44 high, radius 22, columns `40 + 7×1fr`.
  - Week column: "W<n>" 11/16 w500 `fg3`, `n` = ISO 8601 week number of the
    row's Monday.
  - Day numbers 14/20 tabular: `fg` in the browsed month, `fg3` outside it,
    `off` after today.
  - Selected (the anchor week): `onBg` fill, **every** label `onFg` (no
    fading).
  - Current week, not selected: 1px `fg` ring.
  - Disabled (§ 5): `off` text.
- The whole row is the tap target; picking it applies its Monday.

#### Months view

- 3 columns, gap 8, padding 8 16 0. Cell: 52 high, radius 26, 1px `line`
  border, abbreviated month name (`DateFormat.MMM(locale)`) 15/20.
- Selected (the anchor's month in the browsed year): `onBg` fill and border,
  `onFg` text, w500. Current month, not selected: `fg` border. Disabled:
  `off` text.

#### Years view

- Same cells and grid as Months, one per year from the lower bound's year to
  the current year, ascending. Selected = the anchor's year; current year has
  the `fg` border. No disabled cells.

### 5. Range limits

- **Upper bound — today.** Days after today, weeks that start after today,
  months after the current month and years after the current year are
  disabled. The browse bar's › is disabled on the current month (Days/Weeks)
  or current year (Months).
- **Lower bound `L`** = the first day of the **earlier** of:
  - the month of the earliest transaction (`chartsDateBoundsProvider`), and
  - the month of the current anchor.

  Cells that end before `L` are disabled; the browse bar's ‹ is disabled on
  `L`'s month (Days/Weeks) or year (Months); Years starts at `L`'s year.
  Including the anchor matters because ‹ and swipe have no lower bound: after
  stepping back past the first record, the picker must still open on an
  enabled, selected cell rather than a page of disabled ones.
- No transactions, or bounds still loading / failed: `L` = the anchor's month,
  and the footnote is omitted.
- Disabled cells: not tappable, excluded from focus traversal, semantics
  `enabled: false`.

### 6. Applying a pick

- New controller method:

  ```dart
  /// Jump to the period containing [date]. No-op on All or when it is already
  /// the selected period.
  void setAnchor(DateTime date)
  ```

  It sets `anchorDate: normalizeAnchor(date, state.period)` and clears
  `selectedSlice` (same as `previousPeriod` / `nextPeriod`). Type, dimension
  and account filter are kept. The picker only offers dates up to today, so no
  future check is needed beyond the existing `isAtCurrentPeriod` for ›.
- Picking a cell of the period's unit, or **Now**, calls `setAnchor` and
  closes the picker. There is no confirm button.
- Dismissing (scrim, drag down, back, Esc) changes nothing.
- The chart body swaps **without** the swipe slide animation: the slide stays
  reserved for ‹ ›, swipes and their direction queue.

---

## Architecture

- **`charts_selection_controller.dart`** — add `setAnchor`; run
  `build_runner` and commit the regenerated `.g.dart`.
- **`period_picker_sheet.dart`** (new, `charts/views/`):
  - `showPeriodPicker(BuildContext context)` — the adaptive sheet / dialog
    helper, shaped like `showAccountFilterSheet`, annotated with
    `@Dependencies` for what it reads.
  - A `ConsumerStatefulWidget` that reads the selection (`period`,
    `anchorDate`) and `chartsDateBoundsProvider`, holds the view and browsed
    month/year as widget state, and calls `setAnchor` + `Navigator.pop`.
  - Grids are fixed-size (≤ 42 day cells, ≤ 6 week rows, 12 months, a handful
    of years): build them eagerly; the sheet body scrolls for large text.
- **`period_selector.dart`** — `PeriodNavigator` takes an `onPick` callback
  (null on All) and an `open` flag for the caret; `PeriodSelector` passes them
  through. The caller tracks `open` around the `await showPeriodPicker(...)`.
- **`date_helpers.dart`** — `isoWeekNumber(DateTime)`.
- **Formatting** — reuse the cached `_dateFormat` in `period_selector.dart`
  (or move it next to the picker); never build a `DateFormat` per cell
  (Performance rules).
- No repository, provider or schema changes.

## Strings (all four ARB files)

Reuse `chartsCaptionToday` / `ThisWeek` / `ThisMonth` / `ThisYear` for the
Now button. New keys (follow the `@key` description convention):

| Key | en | zh_TW | zh_CN |
|---|---|---|---|
| `chartsPickDay` / `Week` / `Month` / `Year` | Choose a day / Choose a week / Choose a month / Choose a year | 選擇日期 / 選擇週 / 選擇月份 / 選擇年份 | 选择日期 / 选择周 / 选择月份 / 选择年份 |
| `chartsPickerSelected` (`{period}`) | Selected: {period} | 已選：{period} | 已选：{period} |
| `chartsPickerOpenLabel` (`{title}`, `{period}`) | {title}. Selected: {period} | {title}，已選：{period} | {title}，已选：{period} |
| `chartsPickerWeekColumn` | Wk | 週 | 周 |
| `chartsPickerWeekNumber` (`{week}`) | W{week} | {week}週 | {week}周 |
| `chartsPickerWeekRow` (`{week}`, `{range}`) | Week {week}, {range} | 第 {week} 週，{range} | 第 {week} 周，{range} |
| `chartsPickerChooseMonth` (`{month}`) | Choose month, showing {month} | 選擇月份，目前為 {month} | 选择月份，当前为 {month} |
| `chartsPickerChooseYear` (`{year}`) | Choose year, showing {year} | 選擇年份，目前為 {year} | 选择年份，当前为 {year} |
| `chartsPickerPreviousMonth` / `NextMonth` | Previous month / Next month | 上個月 / 下個月 | 上个月 / 下个月 |
| `chartsPickerPreviousYear` / `NextYear` | Previous year / Next year | 上一年 / 下一年 | 上一年 / 下一年 |
| `chartsPickerRecordsStart` (`{date}`) | Records start {date}. | 記錄始於 {date}。 | 记录始于 {date}。 |

`app_zh.arb` mirrors whichever variant it mirrors for the existing chart keys.

## Accessibility

- Every tap target is ≥ 44 high; day cells are about 51 wide at 390.
- Day cells announce the full date ("October 21, 2026"), week rows "Week 43,
  Oct 19–Oct 25, 2026", month and year cells their full names; all expose
  selected state.
- 2× text scale: the sheet body scrolls; the day circle grows to fit (min
  40), rows grow (min 44). No shrink-only `FittedBox` on numbers.
- Text contrast follows the redesign tokens. `off` is used only for disabled
  cells; selected rows never fade their text.

## Acceptance criteria (write these as tests first)

Widget tests under `test/widget/features/analysis/`, unit tests under
`test/unit/` as `docs/architecture/testing.md` § Charts describes.

1. The label is a button on Day / Week / Month / Year and not on All. Its
   caret points down; up while the picker is open; down again after a pick
   and after a dismiss.
2. Day: the picker opens on the anchor's month with the anchor selected;
   tapping another day sets the anchor to that day, closes the picker,
   updates the label, clears the slice, and keeps type, dimension and account
   filter.
3. Week: rows cover every Monday-start week touching the month, with
   neighbouring-month days; tapping a row sets the anchor to its Monday. Week
   numbers are ISO 8601 (Dec 29, 2025 → W1; Dec 28, 2020 → W53).
4. Month picks a month; Year lists years from `L` to now and picks one.
5. Drilling on Week: title → Months → title → Years → pick a year → Months of
   that year → pick a month → Weeks of that month.
6. Now applies the current period; scrim / back changes nothing.
7. Bounds: future cells and › at the current month are disabled; cells before
   `L` are disabled. With the anchor stepped back before the first record
   (via ‹), the picker opens with the anchor enabled and selected.
8. Width ≥ 600 opens a `Dialog`; < 600 a bottom sheet.
9. No overflow at 2× text scale, light and dark.
10. `zh_TW` shows localized weekday, month and picker strings.
11. Unit: `setAnchor` normalizes, is a no-op on All and on the same period,
    and clears the slice; `isoWeekNumber` across year boundaries.

## Suggested order (one PR-sized slice each)

1. `isoWeekNumber` + `setAnchor` (unit tests 3 and 11).
2. Picker widget: views, drilling, bounds, Now (widget tests 2–7).
3. Navigator label button + caret + adaptive presentation (tests 1, 8, 9).
4. Strings in all four ARB files (test 10).
5. Docs: PRD § Analysis Screen (mention the picker), `docs/architecture/testing.md`
   § Charts coverage.
