---
title: Home calendar-day navigation, queued transitions, and selected-day summary priority
date: 2026-04-29
category: logic-errors
module: home
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Jump-to-today could bypass the animated transition path used by prev/next navigation.
  - Rapid prev/next taps were silently dropped after five queued inputs.
  - Queued day transitions could appear to be skipped because stream resubscriptions depended on stale provider reads.
  - The summary strip could hide the selected day's active currency when month-only currencies sorted earlier.
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

In `lib/features/home/home_screen.dart`:

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
    final beforeDay = _currentSelectedDay();

    if (direction > 0) {
      await ref.read(homeControllerProvider.notifier).selectNextDay();
    } else {
      await ref.read(homeControllerProvider.notifier).selectPrevDay();
    }

    final afterDay = _currentSelectedDay();
    final changed =
        beforeDay == null ||
        afterDay == null ||
        !DateHelpers.isSameDay(beforeDay, afterDay);

    if (changed) {
      _incomingOffset = _buildOffsetAnimation(direction);
      _daySwitchController.reset();
      await _daySwitchController.forward();
    }
  }
}
```

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

In `lib/features/home/home_controller.dart`:

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

Finally, prioritize selected-day currencies in the summary strip cap.

In `lib/features/home/widgets/summary_strip.dart`:

```dart
final todayCodes = todayTotalsByCurrency.keys.toSet();
final allCodes = <String>{
  ...todayCodes,
  ...monthNetByCurrency.keys,
}.toList()
  ..sort((a, b) {
    final aToday = todayCodes.contains(a);
    final bToday = todayCodes.contains(b);
    if (aToday && !bToday) return -1;
    if (!aToday && bToday) return 1;
    return a.compareTo(b);
  });
```

## Why This Works

- Transition logic now matches user intent: the queue drains in order, but the UI animates based on the requested step, not on whether a later provider read happened to return the new day synchronously.
- Removing the hard cap prevents silent input loss while still allowing the animation controller to process queued moves sequentially.
- The controller no longer tears down and recreates day/summary subscriptions when the subscribed day has not changed, which makes rapid navigation more predictable.
- The summary strip now shows the currencies that are actually active on the selected day before it shows month-only currencies.

## Prevention

- When a screen transition depends on a requested action, derive the transition from the action itself rather than from a post-hoc provider read.
- If a navigation system allows queued inputs, either honor all inputs or coalesce them deliberately—do not silently drop them.
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
