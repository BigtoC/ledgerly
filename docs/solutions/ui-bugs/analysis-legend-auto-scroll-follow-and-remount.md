---
title: Analysis legend auto-scroll stops short, chases resizes, and misses the pie after a period change
date: 2026-10-31
category: docs/solutions/ui-bugs/
module: analysis
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - "Scrollable.ensureVisible on the legend card stops short of the top because the drill-down list loads after the scroll and grows in through an AnimatedSize"
  - "A card that can never reach the top keeps following, so a later resize (keyboard, rotation) pulls the page back down"
  - "After a period change clears the selection, the top of the pie stays hidden by the height of a banner that is gone"
  - "Scrolling to the very top instead cuts off the bottom of the pie on short screens"
  - "pumpAndSettle in widget tests waits out the delayed drill-down load while a CircularProgressIndicator spins, hiding the stop-short bug"
root_cause: async_timing
resolution_type: code_fix
severity: medium
tags: [flutter-scroll, ensure-visible, scroll-notification-observer, keyed-subtree-remount, analysis-legend, auto-scroll, widget-test-pump]
---

# Analysis legend auto-scroll stops short, chases resizes, and misses the pie after a period change

## Problem
On the Analysis page, tapping a category should scroll the legend card to the top of the page. Clearing the selection should scroll back up until the whole pie shows.

A single `Scrollable.ensureVisible` call managed neither reliably. The drill-down list below the card loads after the tap, and a period change remounts the whole chart body under a new key.

The code is `_ChartBodyState` in `lib/features/analysis/charts/charts_section.dart`.

## Symptoms
- **Selecting stopped short.** The card stopped about 100px below the top (card top 231 against viewport top 128). `ensureVisible` clamps to the scroll extent as it is when it runs, and the drill-down rows weren't there yet.
- **Late resizes moved the page.** When the card could never reach the top (a short drill-down list on a tall screen), the "keep lifting" flag stayed on, so every later resize pulled the page down. A test that shrinks the viewport from 360x700 to 360x600 saw the page jump 100px.
- **A period change hid the top of the pie.** Stepping to a period without the excluded-currency banner left the pie top 66px above the viewport, which is the banner's height.
- **A→B switches didn't scroll.** Going straight from one category to another left the scroll where it was. The handler only reacted to changes to or from null.

## What Didn't Work
- **One `ensureVisible` after the frame.**
  - At that point the drill-down list is still a spinner.
  - It grows in through a 220ms `AnimatedSize` after the async load.
  - So the target is clamped to the old, shorter extent.
- **A 360x640 test viewport.** There isn't enough content below the card for it to ever reach the top. 360x560 works.
- **Measuring the pie before the frame on deselect.** After a period change the measurement belongs to the old layout. The new period's banners differ, so the offset is wrong by a banner's height.
- **Scrolling to `minScrollExtent` (the very top) when the State was remounted.** The period selector and toggles sit above the pie, so on a 560px screen the pie bottom ended up at 630–696px, below the viewport.
- **`pumpAndSettle` in the late-load test.**
  - While the drill-down `CircularProgressIndicator` spins, `pumpAndSettle` keeps pumping, so it waits out the artificial delay.
  - As a result the test passed even with the follow logic removed.

## Solution
**1. Follow the extent while the drill-down list grows.**
- `_ChartBodyState` subscribes to the Scaffold's `ScrollNotificationObserver`.
- A content-size change reaches observers as a `ScrollUpdateNotification` with `scrollDelta == null`. `ScrollMetricsNotification.asScrollUpdate` does that conversion.

```dart
void _onScrollNotification(ScrollNotification notification) {
  if (!_followLegend || notification.depth != 0) return;
  if (notification is UserScrollNotification ||
      (notification is ScrollStartNotification &&
          notification.dragDetails != null)) {
    _followLegend = false;
    return;
  }
  // A content-size change reaches observers as an update with no delta.
  if (notification is ScrollUpdateNotification &&
      notification.scrollDelta == null &&
      !Scrollable.of(context).position.isScrollingNotifier.value) {
    unawaited(_revealLegend(animate: false));
  }
}
```

**2. Stop following once the job is done or the user takes over.** Following stops when any of these happens:
- the card reaches the top;
- the user drags;
- a touch interrupts the animation, so `pixels` doesn't land on the target;
- the follow window runs out.

```dart
static const _kFollowWindow = Duration(seconds: 2);
// on select:
_followTimer = Timer(_kFollowWindow, () => _followLegend = false);

// after ensureVisible in _revealLegend:
if (_legendAtTop(position) || (position.pixels - target).abs() > 0.5) {
  // At the top, or a touch interrupted the animation: stop following.
  _followLegend = false;
} else if (animate) {
  // The extent may have grown while the animation ran.
  await _revealLegend(animate: false);
}
```

`dispose` cancels `_followTimer` and removes the observer listener.

**3. Re-find the pie after a period-change remount.**
- `_frame` wraps the body in a `KeyedSubtree` keyed on the period name and anchor date. By the time the post-frame callback runs, the old State is unmounted.
- Capture the page's `ScrollableState`, which outlives the State.
- After the frame, find the pie of whichever `_ChartBody` is mounted now:

```dart
RenderObject? _currentPie(BuildContext scrollContext) {
  if (mounted) return _pieKey.currentContext?.findRenderObject();
  _ChartBodyState? body;
  void visit(Element element) {
    if (element is StatefulElement && element.state is _ChartBodyState) {
      body = element.state as _ChartBodyState;
    } else {
      element.visitChildren(visit);
    }
  }
  scrollContext.visitChildElements(visit);
  return body?._pieKey.currentContext?.findRenderObject();
}
```

The target is `max(pieTop, minScrollExtent)`. The page animates only when `pixels > target`, so deselecting never scrolls down.

**4. React to every selection change, not just changes to or from null.** This covers A→B switches.

```dart
ref.listen(
  chartsSelectionControllerProvider.select((s) => s.selectedSlice),
  (previous, next) {
    if (previous != next) _onSelectionChanged(selected: next != null);
  },
);
```

## Why This Works
- **The reveal follows the growth.** `ensureVisible` is only correct for the layout at the moment it runs, and here the layout keeps changing after the tap: first the async load, then the `AnimatedSize` growth. Re-running the reveal on each content-size notification keeps up with it.
- **The follow has an end.** Without stop conditions it fights the user and reacts to unrelated resizes. The 2s window is long enough for the load and the 220ms grow-in, and short enough that opening the keyboard or rotating later doesn't move the page.
- **The pie is measured against the current layout.** Measuring after the frame, against the pie of the body that is mounted now, includes whatever banners the new period shows. Driving the scroll through the surviving `ScrollableState` keeps it away from the unmounted State.

## Prevention
- **Assume the extent will change after a reveal** when you reveal content next to something that loads asynchronously or animates its size. Either follow the extent for a bounded time, or start the reveal after the load.
- **Don't let post-frame work use an old State after a remount.** If a subtree is keyed on period or anchor, post-frame work started by the old State must not use that State's keys or context. Go through an ancestor that survives the remount and re-find the new element.
- **Size test viewports so the target can actually reach the top.** Here that is 360x560 at DPR 1:
  ```dart
  tester.view.physicalSize = const Size(360, 560);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ```
- **Don't use `pumpAndSettle` while a spinner is on screen.** Step time with explicit pumps, or the test silently waits out the delay:
  ```dart
  Future<void> pumpPastReveal(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  ```
- **Simulate a late load by overriding the controller's `build()`.** `_SlowDrilldownController` does this to hold back the rows: `Stream<void>.fromFuture(Future.delayed(delay)).asyncExpand((_) => rows)`.
- **Regression tests.** The `legend auto-scroll` group in `test/integration/analysis_drilldown_test.dart` covers:

  | Test | What it pins down |
  | --- | --- |
  | Select, then clear | Card at the top, then the whole pie |
  | Late rows | The follow |
  | User drag | Stops the follow |
  | A→B switch | Scrolls to the card |
  | Period change | Shows the whole pie |
  | Step to a period without the banner | Pie top not hidden; seeds last week with USD-only rows |
  | Resize 5s after selecting at 360x700 | The follow window |

  The tests fail if the follow, the notification path or the drag-cancel is removed. The banner test (66px) and the resize test (100px) both failed before the fix.
- **Annotate test helpers for `riverpod_lint`.** Test helpers that pump scoped providers, including local functions such as `pumpPhone`, need the full `@Dependencies([...])` list. See `docs/architecture/testing.md`.

## Related Issues
- `docs/solutions/developer-experience/flutter-widget-test-and-device-verification-gotchas.md`: more widget-test viewport and lazy-list gotchas. It does not cover the `pumpAndSettle`-with-spinner trap described above.
- `docs/solutions/logic-errors/analysis-slice-drilldown-delete-guards-fx-alignment-2026-05-22.md`: same drill-down stack (`_ChartBody`, `SelectedSliceItemsList`, `analysis_drilldown_test.dart`).
- `docs/solutions/performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`: the drill-down list's row cap and the `RepaintBoundary` around each chart in `_ChartBody`.
- `docs/superpowers/plans/2026-05-22-chart-slice-drilldown.md`: historical plan. Its "View all" sheet and "Other" legend row were removed when the legend became a card listing every slice.
