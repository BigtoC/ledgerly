---
title: fl_chart tooltips and edge x labels are clipped when the bar chart scrolls horizontally
date: 2026-11-03
category: ui-bugs
module: analysis
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - "A tooltip for a bar near the edge of the visible window is clipped by the scroll viewport, even with fitInsideHorizontally set"
  - "fitInsideHorizontally clamps the tooltip to the chart canvas, which inside a SingleChildScrollView is the full content width"
  - "Centring the first and last x labels under their bars gets them clipped by the viewport at either scroll end"
  - "The earlier workaround aligned the end labels to the outer edge, which did not match the design"
root_cause: wrong_api
resolution_type: code_fix
severity: medium
related_components:
  - testing_framework
tags: [fl-chart, tooltip-horizontal-offset, horizontal-scroll, overflow-box, edge-labels, text-painter, text-scale, analysis-charts]
---

# fl_chart tooltips and edge x labels are clipped when the bar chart scrolls horizontally

## Problem

Past 24 months (plan D14), the All trend chart in `lib/ui/features/analysis/charts/views/daily_bar_chart.dart` scrolls horizontally. The widget tree is `SingleChildScrollView(reverse: true)` → `SizedBox(width: n*rod + (n-1)*gap)` → `Stack(BarChart + x-label Row)`. Two problems came from the scroll viewport.

1. **Tooltips were clipped.** `BarTouchTooltipData.fitInsideHorizontally` keeps a tooltip inside the chart canvas. Inside a scroll view, the canvas is the full content width, not the part you can see. A tooltip on a bar near the edge of the visible window was cut off by the viewport.
2. **Edge labels were clipped or off-design.** If the first or last x label is centred under its bar, the viewport cuts it off. The earlier workaround aligned those two labels to their bar's outer edge, which does not match the design.

## Symptoms

- On the scrolling All trend, touching the last bar (the chart opens at the right end) or the first bar (after scrolling to the left end) shows a tooltip that is half hidden at the viewport edge.
- The first and last x labels were not centred under their bars (`Alignment.centerLeft` / `Alignment.centerRight`). Centring them instead got them clipped by the viewport, and the clipping was worse at 2× text scale.

## What Didn't Work

- **Relying on `fitInsideHorizontally: true`.** fl_chart 1.3.0's `bar_chart_painter.dart` only shifts the tooltip rect against the canvas bounds:
  ```dart
  if (tooltipData.fitInsideHorizontally) {
    if (rect.left < 0) { /* shift right */ }
    if (rect.right > viewSize.width) { /* shift left */ }
  }
  ```
  `viewSize` is the whole scrolled content, so a tooltip that fits the canvas but not the visible window is never moved.
- **Aligning the edge labels to the bar's outer edge** (the removed `keepEndsInside` flag on `_labels`). It avoided the clipping but broke the design, which centres every label under its bar.
- **Rejected alternative: fl_chart's own pan (`transformationConfig`).** With it the canvas would be the viewport, so the built-in fit would work. But the custom label `Row` sits outside fl_chart and would have to follow fl_chart's transform, which is a much bigger change.

## Solution

Commit `5803ac8`, "fix(analysis): keep the scrolling All trend's edge labels centred" (plan deviation D20, on `main` via #127). `DailyBarChart` became a `StatefulWidget`.

**Before (stateless, scroll view clipped at the plot edge, end labels edge-aligned):**
```dart
return SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  reverse: true,
  child: SizedBox(width: n * rodWidth + (n - 1) * gap, child: chart),
);
// ...
alignment: !keepEndsInside
    ? Alignment.center
    : i == buckets.length - 1
    ? Alignment.centerRight
    : i == 0
    ? Alignment.centerLeft
    : Alignment.center,
```

**After, part 1: the viewport reaches into the card padding, and the content is padded by the same amount.** `DailyBarChart.edgeInset` is the parent card's horizontal padding. `charts_trend_card.dart` passes `edgeInset: 16`.
```dart
final viewport = width + 2 * widget.edgeInset;
return OverflowBox(
  fit: OverflowBoxFit.deferToChild,
  minWidth: viewport,
  maxWidth: viewport,
  child: SingleChildScrollView(
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    reverse: true, // opens at the right end, on the current month
    padding: EdgeInsets.only(left: insets.left, right: insets.right),
    child: SizedBox(width: n * rodWidth + (n - 1) * gap, child: chart),
  ),
);
```
Each end's inset is `max(edgeInset, overhang of that end's label)`. A label wider than the padding, as at large text scales, pads the content further instead of being clipped:
```dart
double inset(int i) {
  final labelWidth = placed[i];
  if (labelWidth == null) return widget.edgeInset;
  final overhang = (labelWidth - rodWidth) / 2;
  return overhang > widget.edgeInset ? overhang : widget.edgeInset;
}
return (left: inset(0), right: inset(last));
```

**After, part 2: the tooltip is fitted to the viewport.** A `ScrollController` is a state field and is disposed in `dispose()`. `touchCallback` is set only when the chart scrolls. `tooltipHorizontalOffset` is `scrolls ? _tooltipOffset : 0`.
```dart
touchCallback: scrolls
    ? (event, response) => _fitTooltip(
        response?.spot?.touchedBarGroupIndex, rodWidth, gap, insets, scheme, currency)
    : null,
```
`_fitTooltip` builds the same `BarTooltipItem` and measures it the way fl_chart does. Then it computes the visible window in plot coordinates and applies the smallest shift that fits:
```dart
final painter = TextPainter(
  text: TextSpan(
    style: _tooltipTextStyle(item.textStyle), // DefaultTextStyle.merge + bold if MediaQuery.boldTextOf
    text: item.text,
    children: item.children,
  ),
  textAlign: item.textAlign,
  textDirection: item.textDirection,
  textScaler: MediaQuery.textScalerOf(context),
)..layout(maxWidth: _kTooltipMaxContentWidth); // 120, fl_chart's default
final tooltipWidth = painter.width + _kTooltipPadding.horizontal;
painter.dispose();

// Reversed: offset 0 is the right end.
final contentWidth = insets.left + plotWidth + insets.right;
final visibleLeft =
    contentWidth - position.viewportDimension - position.pixels - insets.left;
final visibleRight = visibleLeft + position.viewportDimension;

final centre = index * (rodWidth + gap) + rodWidth / 2;
final left = centre - tooltipWidth / 2;
final right = centre + tooltipWidth / 2;
final offset = left < visibleLeft
    ? visibleLeft - left
    : right > visibleRight
    ? visibleRight - right
    : 0.0;
if (offset != _tooltipOffset) setState(() => _tooltipOffset = offset);
```

## Why This Works

- **Tooltip position.** fl_chart's `getTooltipLeft` adds the offset before its own canvas fit runs. For the centre alignment used here it returns `dx - w/2 + offset`. For `right` it returns `dx + offset`, and for `left` it returns `dx - w + offset`. An offset that keeps `[centre - w/2, centre + w/2]` inside the visible window therefore lands the tooltip inside the viewport, and the canvas fit then has nothing left to do.
- **Measured width matches the drawn width.** fl_chart measures with `Utils().getThemeAwareTextStyle` (merges onto `DefaultTextStyle` when the style is null or `inherit`, and adds bold when `MediaQuery.boldTextOf`). It also uses the holder's `textScaler` and `layout(maxWidth: tooltipData.maxContentWidth)`, then adds `tooltipPadding.horizontal`. `_tooltipTextStyle` copies that resolution, and both constants are named, so the two widths agree.
- **No one-frame lag.** fl_chart's internal `setState` for the touch and our `setState` for the offset run in the same pointer event, so the tooltip appears in its final place.
- **`setState` only on change.** `touchCallback` is a high-frequency callback, so the offset is compared first (the performance rule).
- **Edge labels.** Widening the viewport by `edgeInset` on each side and padding the content by the same amount puts the bars, at either scroll end, exactly where an unscrolled chart's bars would be. The end label then has room in the card padding and stays centred.
- **Caveat:** touches in the overhang area do not reach the chart, because a `RenderBox` hit test only checks its own size. The `edgeInset` doc comment says so.

## Prevention

- Inside a scroll view, fl_chart's `fitInsideHorizontally` / `fitInsideVertically` protect only against the canvas edge, never the viewport edge. Any fl_chart inside a scrollable needs its own viewport fit through `tooltipHorizontalOffset`, or needs fl_chart's own pan instead.
- If you measure a widget to mirror a library's layout, use the library's exact inputs: style resolution including bold text, `textScaler`, `maxContentWidth`, padding. Name the library defaults as constants (`_kTooltipMaxContentWidth = 120`, `_kTooltipPadding`) so the measurement and the configuration cannot drift apart.
- Follow-up from Step 8 (D22, commit `20df4ab`): x labels are placed by priority with collision skipping, measured with `TextPainter`. Two rules came out of that work:
  - Pass `locale: Localizations.maybeLocaleOf(context)` (plus `DefaultTextStyle`, bold text, `textScaler` and `Directionality`). The locale can pick a different font face, and the code review found it missing.
  - Cache the placement on what the labels are (the joined `index:text` strings, current index, rod width, gap, style, bold, scaler, direction, locale). Do not key it on the `TrendSeries` instance: the card rebuilds the series on every build, and it has identity equality, so the cache would never hit.
- Tests live in `test/widget/features/analysis/widgets/daily_bar_chart_test.dart`, group `'All (D14, D15)'`, with a phone plot width of `324` and `rod24 = (324 - 23*4)/24`.
  - A helper `_tooltipWidth(tester, index)` mirrors fl_chart's measurement, reading `getTooltipItem`, `maxContentWidth` and `tooltipPadding` from the built `BarTouchTooltipData`.
  - To trigger fl_chart's tap-down after the press timeout, start a gesture on the bar and pump 200 ms:
    ```dart
    var gesture = await tester.startGesture(Offset(plot.right - rod24 / 2, plot.top + 120));
    await tester.pump(const Duration(milliseconds: 200));
    final right = _data(tester).barTouchData.touchTooltipData;
    expect(right.tooltipHorizontalOffset, lessThan(0));
    expect(
      centre - width / 2 + right.tooltipHorizontalOffset + width,
      closeTo(viewport.right, 0.01),
    );
    ```
    After scrolling to the left end, touching the first bar gives `tooltipHorizontalOffset > 0`, and `plot.left + rod24/2 - _tooltipWidth(tester, 0)/2 + offset` is `closeTo(viewport.left, 0.01)`.
  - `'a tooltip with room keeps its centre on the bar'`: touching index 21 mid-viewport expects `tooltipHorizontalOffset == 0`.
  - `'at 2× an edge label wider than the padding moves the bars in rather than being clipped'`: after dragging to the left end and `pumpAndSettle` (so the overscroll stretch recedes), `find.text('2024')` has `left` `closeTo(viewport.left)` and `center.dx` `closeTo(plot.left + rod24/2)`.
  - The Roboto-loaded group `'All edge labels in Roboto'` asserts `plot.left` `closeTo(box.left)` at the left end, so the bars sit where an unscrolled chart's would. It also checks the year label is centred under the first bar and its `left >= viewport.left`. Keep Roboto groups last in the file, because the loaded font persists.

## Related Issues
- PR #127 (plan D14, D20), commit `5803ac8`; Step 8 follow-ups in PR #128 (D22 label collisions, commit `20df4ab`).
- [Widget-test getRect is skewed by the stretch overscroll](../test-failures/widget-test-getrect-skewed-by-stretch-overscroll-after-drag.md) — the test trap hit while writing these tests.
- [Flutter performance audit](../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md) — the `RepaintBoundary` around `DailyBarChart` and the setState-only-on-change rule for `touchCallback`.
- [Category picker: fixed extent + FittedBox cancels text scale](category-picker-fixed-extent-fittedbox-cancels-text-scale.md) — measure at 2× and assert rendered size, never hide clipping.
