---
title: Widget-test getRect is skewed by the stretch overscroll after a drag past the scroll end
date: 2026-11-03
category: test-failures
module: analysis
problem_type: test_failure
component: testing_framework
symptoms:
  - "After tester.drag(..., Offset(2000, 0)) and one pump(Duration(seconds: 1)), getRect geometry assertions were off by about 0.15-1.7 px"
  - "tester.getRect(find.text(...)) reported a label about 3% wider (ratio about 1.032) than the RenderParagraph's size.width"
  - "A year label's centre was not under its bar, although TextPainter and RenderParagraph measured the same width"
root_cause: async_timing
resolution_type: test_fix
severity: medium
related_components:
  - development_workflow
tags: [flutter-test, widget-test, overscroll, stretching-overscroll-indicator, getrect, pump-and-settle, horizontal-scroll, fl-chart]
---

# Widget-test getRect is skewed by the stretch overscroll after a drag past the scroll end

## Problem

In `test/widget/features/analysis/widgets/daily_bar_chart_test.dart`, the All-period trend scrolls horizontally: `SingleChildScrollView(reverse: true)` in `lib/ui/features/analysis/charts/views/daily_bar_chart.dart`, around line 241. Some tests drag that chart well past its scroll end to reach the left end. After the drag, assertions built on `tester.getRect(...)` were off by about 0.15 to 1.7 px. The layout itself was correct. The test read the geometry while the Android stretch overscroll was still scaling the scroll content.

## Symptoms

- After the drag below, label and plot rects did not match the expected layout within `closeTo(..., 0.01)`:
  ```dart
  await tester.drag(find.byType(BarChart), const Offset(2000, 0));
  await tester.pump(const Duration(seconds: 1));
  ```
- `tester.getRect(find.text('2024')).width` reported 90.8. The `RenderParagraph` for that text had a size of 88.0, a ratio of about 1.032.
- The label's centre was not under its bar (`year.center.dx` vs `plot.left + rod24 / 2`). The left edge did not line up with the viewport either.
- The errors were small, sub-pixel to under 2 px, so they looked like a measurement or rounding problem rather than a transform.

## What Didn't Work

- **Suspecting text measurement.** The first theory was that `TextPainter` (which the chart uses to size edge labels) measured differently from the `Text` widget. Suspected causes were locale, `DefaultTextStyle` or font fallback. Debug prints compared three values for the same label:
  - `TextPainter` width: 88.0
  - `RenderParagraph.size.width`: 88.0
  - `tester.getRect(...)` width: 90.8

  The measurement was exact. Only `getRect` disagreed, so the problem was in how the rect was read, not in how the text was laid out.
- **A single timed pump** (`pump(const Duration(seconds: 1))`) after the drag. This is not enough time for the stretch to recede.

## Solution

**Root cause:** the test platform defaults to Android. On Android, dragging past the scroll extent triggers `StretchingOverscrollIndicator`, the Material 3 / Android 12+ overscroll. It applies a scale `Transform` to the scroll content. One `pump(1s)` does not finish the recede animation. `tester.getRect` maps through the global transform, so it includes the stretch scale. `tester.getSize` returns `RenderBox.size`, so it does not.

Before:

```dart
await tester.drag(find.byType(BarChart), const Offset(2000, 0));
await tester.pump(const Duration(seconds: 1));

final viewport = tester.getRect(horizontalScrollable());
final plot = tester.getRect(find.byType(BarChart));
final year = tester.getRect(find.text('2024'));
expect(year.left, closeTo(viewport.left, 0.01));          // off by ~px
expect(year.center.dx, closeTo(plot.left + rod24 / 2, 0.01));
```

After (as shipped in 5803ac8 at all three drag sites: the 2× edge-label test, the tooltip-at-viewport-edge test and the Roboto group test):

```dart
await tester.drag(find.byType(BarChart), const Offset(2000, 0));
// Let the overscroll stretch, which scales the content, recede.
await tester.pumpAndSettle();

final viewport = tester.getRect(horizontalScrollable());
final plot = tester.getRect(find.byType(BarChart));
final year = tester.getRect(find.text('2024'));
expect(year.left, closeTo(viewport.left, 0.01));
expect(year.center.dx, closeTo(plot.left + rod24 / 2, 0.01));
```

`pumpAndSettle` is allowed here. AGENTS.md bans it only while a loading spinner is on screen, and none is showing in these tests. The chart has already rendered, and the only animations left are the overscroll recede and the scroll settle.

## Why This Works

`pumpAndSettle` keeps pumping frames until no frames are scheduled. That lets the `StretchingOverscrollIndicator` recede animation finish, so its scale transform returns to identity. After that, global rects from `getRect` match the laid-out sizes and offsets again. The layout was always correct. Only the paint-time transform distorted what `getRect` reported. A fixed `pump(Duration)` stops at an arbitrary point in that animation and can leave some scale behind.

**Diagnostic rule:** if `tester.getRect(f).size` differs from `tester.getSize(f)` for the same finder, a transform is active above that widget. In a scroll view that was just dragged, suspect the stretch overscroll. A ratio near 1.0x (here about 1.032) is typical of a stretch that has not finished receding.

## Prevention

- After any `tester.drag` / `fling` that can hit a scroll extent (for example an oversized `Offset(2000, 0)` used to reach an end), settle before reading geometry. Leave a comment so the reason stays visible:
  ```dart
  await tester.drag(find.byType(BarChart), const Offset(2000, 0));
  // Let the overscroll stretch, which scales the content, recede.
  await tester.pumpAndSettle();
  ```
  If a spinner might be on screen, don't use `pumpAndSettle`. Pump explicit durations until the indicator is gone, and confirm it with the assertion below.
- When a `getRect`-based assertion is off by a small, non-round amount, first check that no transform is distorting the rect, before debugging text measurement:
  ```dart
  final f = find.text('2024');
  expect(tester.getRect(f).width, closeTo(tester.getSize(f).width, 0.01));
  ```
  It fails (90.8 vs 88.0) while the stretch is still applied and passes once it has settled.
- Remember that `flutter test` defaults to `TargetPlatform.android`. Android overscroll behaviour, which is stretch on Material 3 rather than the old glow, applies to every scrollable in widget tests unless the test overrides the platform or scroll behaviour.

**Also learned in the same file (font size, not overscroll):** the default test font draws "2024" at 11 px about 45 px wide. Roboto draws it about 24.5 px wide. A "label fits inside the 16 px padding" assertion therefore needs the real font. The file does this in a last group, `group('All edge labels in Roboto', ...)`. Its `setUpAll` loads `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf` with `FontLoader('Roboto')`, and the group stays last because the font remains loaded for the rest of the file. This matches the *Test font* note in AGENTS.md.

## Related Issues
- PR #127 (All period trend scrolling, plan D14/D20), commit `5803ac8`; the drag sites are in `test/widget/features/analysis/widgets/daily_bar_chart_test.dart`.
- [Flutter widget test and device verification gotchas](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md) — the other widget-test harness traps (test font, spinners and `pumpAndSettle`).
- [Category picker: fixed extent + FittedBox cancels text scale](../ui-bugs/category-picker-fixed-extent-fittedbox-cancels-text-scale.md) recommends `getRect` because it includes transforms; this doc is the other side: it also includes transient ones such as the overscroll stretch.
