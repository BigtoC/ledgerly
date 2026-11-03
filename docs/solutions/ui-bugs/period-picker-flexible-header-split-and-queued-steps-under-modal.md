---
title: Period picker header split in half by Flexible beside Expanded, and queued period steps applied under the modal picker
date: 2026-11-03
category: ui-bugs
module: analysis
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - "At 1x the picker title was capped at 171dp of 342, so the subtitle wrapped and the Now button sat mid-sheet (right edge 353 instead of 374)"
  - "At 2x text scale the title broke mid-word, and the fixed 40dp ISO week column broke 'W38' mid-word (44.4 > 40)"
  - "The 2x widget test stayed green because RenderParagraph.didExceedMaxLines is never true without maxLines"
  - "After quick taps on the previous-period arrow, opening the picker and tapping Now landed on 2026-10-19 instead of the current week 2026-11-02"
  - "The first regression test passed falsely because pumpAndSettle after opening the sheet drained the direction queue before the pick"
root_cause: wrong_api
resolution_type: code_fix
severity: medium
related_components:
  - ui/features/analysis/charts/views/period_picker_sheet
  - ui/features/analysis/charts/views/charts_section
  - testing_framework
tags: [flexible-expanded, flex-free-space, text-scale, intrinsic-width, did-exceed-max-lines, direction-queue, modal-route-race, period-picker]
---

# Period picker header split in half by Flexible beside Expanded, and queued period steps applied under the modal picker

## Problem

An adversarial review of the new Analysis period picker (issue #73, PR #131) found layout and state bugs that the green test suite missed:

- **The header.** It broke at 2× text. The first fix, `Flexible`, then broke it at 1×.
- **The week numbers.** `W38` broke mid-word in the design's fixed 40dp column.
- **The weekday headers.** Their gap to the first row was wrong.
- **The step queue.** Chevron and swipe steps still waiting in `ChartsSection`'s queue ran after a pick and moved the period the user had picked.

## Symptoms

- **2×, 390dp phone, before any fix.** The Now `TextButton` took most of the header row. "Choose a month" laid out 38dp wide and broke mid-word.
- **1×, after the `Flexible` fix.** The title column stopped at 171 of 342dp, Now's right edge sat at 353 instead of 374, and "Selected: …" wrapped.
- **2×, week numbers.** `W38` measured 44.4dp inside a `SizedBox(width: 40)` and broke into two lines.
- **Days and Weeks views.** The first row sat 2dp (Days) or 4dp (Weeks) too low under the 32dp weekday header.
- **Queue race.** Repro: four quick ‹ taps, open the picker, tap "This week" 350 ms later. The anchor ended on 2026-10-19 instead of 2026-11-02. While the sheet was open, its selected cell also jumped as queued steps ran behind it.
- **The 2× test** passed through all of the layout bugs.

## What Didn't Work

- **`Flexible` around Now, next to an `Expanded` title column.**
  - `RenderFlex` gives each flex child `freeSpace / totalFlex * flex`, and a tight `Expanded` child gets exactly that share. Space the loose `Flexible` leaves unused is not handed back to the `Expanded` child.
  - At 1× the title therefore got half the row and the leftover space landed after the button.
  - The design (`Main.dc.html`) is title `flex: 1` plus button `flex: none`. `Flexible` is neither.
- **`expect(paragraph.didExceedMaxLines, isFalse)` in the 2× test.** It is only ever true when `maxLines` is set, so it can't see text that wraps freely. The test also ran only at 2×, so nothing would have caught the 1× regression.
- **The first queue regression test.** It called `pumpAndSettle()` right after opening the picker. That ran out the 360 ms slides and emptied the queue before the pick, so the test passed against the buggy code.

## Solution

**Header.** Give Now no flex, and cap it at half the row (`period_picker_sheet.dart`):

```dart
child: LayoutBuilder(
  builder: (context, constraints) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Expanded(child: Column(/* title + "Selected: …" */)),
      // flex: none like the design; capped at half the width so large
      // text cannot squeeze the title until it breaks inside a word.
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
        child: TextButton(
          // ...
          child: Text(nowLabel),
        ),
      ),
    ],
  ),
),
```

**Week number.** The design fixes the column at 40, so the label clamps its scale at 1.5×. AGENTS.md prescribes this for fixed-size regions:

```dart
SizedBox(
  width: 40,
  child: Text(
    weekLabel,
    textAlign: TextAlign.center,
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5),
    style: analysisText(size: 11, lineHeight: 16, /* ... */),
  ),
),
```

**Weekday header.** It moves outside the spaced `Column`, so the 2 / 4dp gap falls only between rows, as in the CSS:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _WeekdayHeader(locale: locale),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2, // 4 in the Weeks view
      children: [/* rows */],
    ),
  ],
),
```

**Queue.** Clear it when the picker opens (`charts_section.dart`):

```dart
Future<void> _openPeriodPicker() async {
  // Steps still queued would otherwise run after the pick and shift it.
  _directionQueue.clear();
  setState(() => _pickerOpen = true);
  await showPeriodPicker(context);
  if (mounted) setState(() => _pickerOpen = false);
}
```

## Why This Works

- **Header.**
  - A non-flex child is laid out first at its natural width, and the `Expanded` title then takes everything left. That matches the design's `flex: 1` and `flex: none`.
  - At 1×, Now sits flush right (width − 16), 8dp after the title column.
  - At 2× the `maxWidth / 2` cap leaves the title at least half the row, enough for its longest word.
  - `LayoutBuilder` makes the cap follow the real width, whether the picker shows as a phone sheet or as the 480-max dialog.
- **Week number.** At 11sp × 1.5, `W38` fits in 40dp. The day numbers in the same row still scale in full. Widening the column would change the design, and the rule is to follow its typography exactly (auto memory [claude]).
- **Weekday header.** `Column.spacing` puts the gap between every pair of children, header included. CSS `gap` and `row-gap` apply only inside the rows' own container.
- **Queue.**
  - A modal bottom sheet or dialog route is not opaque, so `ChartsSection` stays mounted and its `AnimationController` keeps ticking. `_runQueuedTransitions` kept calling `previousPeriod()` every 360 ms behind the sheet.
  - Clearing once at open is enough: nothing can be queued while the modal covers ‹ › and the swipe area. The slide already in flight finishes and then finds the queue empty.

## Prevention

- **Detect wraps with intrinsic widths, not `didExceedMaxLines`.** For each `RenderParagraph`:
  - `getMinIntrinsicWidth(double.infinity)` is the longest unbreakable word. If it is ≤ `size.width`, no word broke.
  - `getMaxIntrinsicWidth(double.infinity)` is the one-line width. If it is ≤ `size.width`, the label stayed on one line.

  The 2× group in `period_picker_sheet_test.dart` asserts both:

  ```dart
  final paragraph = element.renderObject! as RenderParagraph;
  final text = paragraph.text.toPlainText();
  expect(
    paragraph.size.width + 0.01,
    greaterThanOrEqualTo(paragraph.getMinIntrinsicWidth(double.infinity)),
    reason: '"$text" breaks inside a word',
  );
  if (cellLabel.hasMatch(text)) {
    expect(
      paragraph.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(paragraph.size.width + 0.01),
      reason: '"$text" wraps',
    );
  }
  ```

  The same loop with a `print` makes a quick probe: it is how the 38dp title and the 44.4dp `W38` were found. Load Roboto first, since the Ahem test font is about twice as wide.
- **Pin the 1× geometry when you fix large text.** The `Layout` group asserts Now's right edge at `390 - 16` and the 8dp gap to the title column. It also asserts the first row 24dp below the weekday letter, and the 2 / 4dp row gaps.
- **Never wrap a design `flex: none` element in `Flexible` beside an `Expanded`.** Leave it unflexed and cap it with a `ConstrainedBox` inside a `LayoutBuilder`.
- **Keep a header out of a `Column` or `Row` that uses `spacing`.** Put the rows in their own spaced container.
- **Clear step queues on absolute jumps.** A widget that runs queued async work (step queues, timers) under a route it opens should clear that work when the route opens. A non-opaque route doesn't pause the widget below it.
- **Race tests: act before the queue drains.** Pump explicit durations (`pump(350ms)`) between opening the sheet and the pick. `pumpAndSettle` drains queued animations and hides the race, not just waits out spinners.
- **Read `DateTime.now()` in the callback** that acts on it, not in `build()`. There is no regression test for the midnight case: the user ruled out a clock abstraction.

## Related Issues

- Issue #73 and PR #131 (the period picker).
- [`../logic-errors/home-calendar-day-navigation-2026-04-29.md`](../logic-errors/home-calendar-day-navigation-2026-04-29.md) documents the same `_directionQueue` / `_runQueuedTransitions` pattern on Home. Home had the same race on its date pick and jump-to-today, plus a loop that hung when a jump cancelled its slide; that doc covers the Home fix.
- [`category-picker-fixed-extent-fittedbox-cancels-text-scale.md`](category-picker-fixed-extent-fittedbox-cancels-text-scale.md) is an earlier fixed-size region whose 2× test stayed green. It fixes the problem by scaling the height with the text. The 1.5× clamp here is the other route AGENTS.md allows.
- [`../developer-experience/flutter-widget-test-and-device-verification-gotchas.md`](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md) covers the Ahem font and 2× test gotchas.
- [`analysis-legend-auto-scroll-follow-and-remount.md`](analysis-legend-auto-scroll-follow-and-remount.md) describes another `pumpAndSettle` false pass in `charts_section.dart`, there through a spinner delay.
