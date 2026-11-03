---
title: Home calendar-day navigation, queued transitions, and selected-day summary priority
date: 2026-04-29
last_refreshed: 2026-11-03
category: logic-errors
module: home
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Jump-to-today could bypass the animated transition path used by prev/next navigation.
  - Rapid prev/next taps were silently dropped after five queued inputs.
  - Queued day transitions could appear to be skipped because stream resubscriptions depended on stale provider reads.
  - "The summary strip could hide the selected day's active currency when month-only currencies sorted earlier (superseded: the strip now shows one converted total)"
root_cause: logic_error
resolution_type: code_fix
severity: high
related_components:
  - home_screen
  - home_controller
  - summary_strip
  - transaction_repository
tags:
  - flutter
  - riverpod
  - home
  - navigation
  - animation
  - stream-subscription
  - summary-strip
  - regression-test
---

# Home calendar-day navigation, queued transitions, and selected-day summary priority

## Problem

Home's calendar-day browsing mixed three different responsibilities: UI transition timing, controller command execution, and repository-backed stream subscriptions. That made the screen fragile in different ways:

- Jump-to-today could update controller state without going through the same transition machinery as the prev/next buttons.
- Rapid navigation was handled through a queue, but the queue was artificially capped and could silently ignore later inputs.
- The widget attempted to detect whether the selected day actually changed by comparing provider state immediately after issuing the controller command, but the controller's stream resubscriptions could lag behind the requested day.
- The currency summary strip prioritized all currencies identically, so month-only currencies could displace the selected day's active currencies under the UI cap.

## Symptoms

- Jump-to-today changed the visible day with no queued slide transition, even though the rest of day navigation was supposed to animate.
- More than five rapid prev/next inputs were silently discarded, so the final selected day depended on animation timing rather than user intent.
- Home day transitions could appear not to animate even when the requested navigation was not a boundary no-op.
- A selected day that had only one active currency could be summarized as zeroed groups because the strip preferred alphabetically earlier month-only currencies.

## What Didn't Work

- Checking `HomeData.selectedDay` immediately after issuing `selectPrevDay()` / `selectNextDay()` was unreliable under broadcast stream resubscription. The controller could already know the new internal day while the visible widget state had not re-emitted.
- Capping the direction queue at five was an attempt to prevent long drains, but it created a silent input-dropping contract that did not match user intent.
- Sorting all summary currencies alphabetically was correct for determinism, but wrong for UX: it could bury the only currency with activity on the selected day.

## Solution

Drive the screen transition from the requested navigation action, not from a synchronous read of provider state after the command completes.

In `lib/ui/features/home/views/home_screen.dart`:

```dart
void _enqueueDayStep(int delta) {
  _directionQueue.add(delta > 0 ? 1 : -1);
  if (!_daySwitchController.isAnimating) {
    unawaited(_runQueuedTransitions());
  }
}

Future<void> _runQueuedTransitions() async {
  while (_directionQueue.isNotEmpty) {
    final direction = _directionQueue.removeFirst();

    if (direction > 0) {
      await ref.read(homeControllerProvider.notifier).selectNextDay();
    } else {
      await ref.read(homeControllerProvider.notifier).selectPrevDay();
    }

    _incomingOffset = _buildOffsetAnimation(direction);
    _daySwitchController.reset();
    await _daySwitchController.forward();
  }
}
```

### Absolute jumps and the queue (2026-11-03)

Jump-to-today and the date picker call `pinDay` and then `reset()` the shared `_daySwitchController`. That cancels the queue's in-flight slide, and a cancelled `TickerFuture` never completes, so two things went wrong:
- the loop hung with steps left in the queue, and the next ‹ › started a fresh loop that drained them all, moving several days at once;
- `_enqueueDayStep` started a loop only when nothing was animating, so a swipe made during the jump's own slide sat in the queue until the next tap.

Both jumps now clear the queue first (`_dropQueuedSteps`). The drain loop tracks its own `_draining` flag and awaits `forward().orCancel`, treating `TickerCanceled` as done:

```dart
void _enqueueDayStep(int delta) {
  _directionQueue.add(delta > 0 ? 1 : -1);
  if (!_draining) unawaited(_runQueuedTransitions());
}

// In _runQueuedTransitions, inside `while (mounted && ...)`:
try {
  await _daySwitchController.forward().orCancel;
} on TickerCanceled {
  // Superseded by a jump, or the screen was disposed.
}
```

Tests WH22–WH24 in `test/widget/features/home/home_screen_test.dart` cover this. They queue steps with quick hand-built flings (`startGesture` + timed `moveBy`), because `fling` / `flingFrom` pump frames until the running slide ends, so nothing would queue.

The original fix still compared the selected day before and after each step (`beforeDay` / `afterDay`) and animated only on a change. The current code dropped that read and animates every requested step, which takes the "derive the transition from the action" rule below one step further.

Route jump-to-today through the same transition path instead of mutating controller state directly:

```dart
onJumpToToday: () async {
  final current = _currentSelectedDay();
  if (current != null && DateHelpers.isSameDay(data.today, current)) return;
  await ref.read(homeControllerProvider.notifier).pinDay(data.today);
  _incomingOffset = _buildOffsetAnimation(1);
  _daySwitchController.reset();
  await _daySwitchController.forward();
},
```

Also make the controller avoid unnecessary stream resubscriptions when the subscribed day has not changed. That keeps rapid calendar steps from canceling and recreating streams unnecessarily.

In `lib/ui/features/home/view_models/home_controller.dart`:

```dart
void _subscribeDay(DateTime day) {
  final targetDay = DateHelpers.startOfDay(day);
  if (_subscribedDay != null &&
      DateHelpers.isSameDay(_subscribedDay!, targetDay)) {
    return;
  }
  // ... existing subscription logic
  _subscribedDay = targetDay;
}

void _subscribeSummaryStreams(DateTime today) {
  final targetDay = DateHelpers.startOfDay(today);
  if (_subscribedSummaryDay != null &&
      DateHelpers.isSameDay(_subscribedSummaryDay!, targetDay)) {
    return;
  }
  // ... existing summary subscription logic
  _subscribedSummaryDay = targetDay;
}
```

Finally, the original fix put the selected day's currencies first in the summary strip's capped list. **Superseded:** multi-currency conversion (`docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`) replaced the per-currency groups and their cap. `lib/ui/features/home/views/summary_strip.dart` now sums every currency into one total in the default currency and lists only currencies without a rate, alphabetically and uncapped. No currency can be hidden, so the priority sort is gone.

## Why This Works

- Transition logic now matches user intent: the queue drains in order, but the UI animates based on the requested step, not on whether a later provider read happened to return the new day synchronously.
- Removing the hard cap prevents silent input loss while still allowing the animation controller to process queued moves sequentially.
- The controller no longer tears down and recreates day/summary subscriptions when the subscribed day has not changed, which makes rapid navigation more predictable.
- (Historical) The summary strip showed the selected day's active currencies before month-only ones. Its converted total no longer caps currencies at all.

## Prevention

- When a screen transition depends on a requested action, derive the transition from the action itself rather than from a post-hoc provider read.
- If a navigation system allows queued inputs, either honor all inputs or coalesce them deliberately—do not silently drop them.
- An absolute jump (date pick, jump-to-today) clears queued relative steps. A loop that awaits an animation another path can reset should await `orCancel` and track its own running flag, not `isAnimating`.
- Avoid resubscribing to streams on every command when the subscription target has not changed, especially under broadcast-stream test helpers.
- When a UI cap hides data, prioritize the most relevant subset for the current context instead of using a purely static sort order.

## Verification that passed for this fix

- `flutter analyze`
- `flutter test test/widget/features/home/home_screen_test.dart`
- `flutter test test/widget/features/home/summary_strip_test.dart`

## Related Issues

- `docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md` — another Home stream-timing coordination fix.
- `docs/solutions/logic-errors/transaction-form-workflow-integrity-2026-04-25.md` — related async-mutation and UI contract patterns.
- `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md` — broader guidance on controller/state ownership of reactive feature flows.
- `docs/solutions/ui-bugs/period-picker-flexible-header-split-and-queued-steps-under-modal.md` — Analysis uses the same `_directionQueue` pattern. There, steps still queued when the period picker opened ran after the pick, and the fix clears the queue on the absolute jump. Home had the same race, fixed the same way (see *Absolute jumps and the queue* above).
