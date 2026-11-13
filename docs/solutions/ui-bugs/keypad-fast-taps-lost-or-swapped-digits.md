---
title: Fast taps on the calculator keypad lost or swapped digits
date: 2026-11-13
category: ui-bugs
module: transactions
problem_type: ui_bug
component: frontend_stimulus
symptoms:
  - "Tapping digits quickly on the keypad sometimes dropped one or more presses (issue #159)"
  - "A fast tap that slid a few dp before lifting entered nothing"
  - "A press in the gap between two keys, or on a key's clipped corner, entered nothing"
  - "Drumming 00 with two fingers on one key entered a single 0"
  - "Press 1, press 2, lift 2, lift 1 entered 21 instead of 12"
root_cause: wrong_api
resolution_type: code_fix
severity: high
related_components:
  - ui/core/widgets/redirect_to_center
  - ui/features/transactions/views/calculator_keypad
  - testing_framework
tags: [calculator-keypad, multi-tap-gesture-recognizer, touch-slop, gesture-arena, redirect-to-center, press-order, ink-splash, timer-still-pending]
---

# Fast taps on the calculator keypad lost or swapped digits

## Problem

Typing fast on the built-in calculator keypad lost digits, and two overlapping presses could enter in the wrong order (issue #159). The controller path (`appendDigit` and the rest) is synchronous and loses nothing: every lost press was dropped in gesture handling, before the key's `onTap` ran.

## Symptoms

Each one was reproduced by a failing widget test first (WK40–WK45 in `test/widget/features/transactions/calculator_keypad_test.dart`):

- A fast tap that slid a little before lifting entered nothing.
- A tap just off a key face entered nothing. That was the 8dp gaps between faces plus the faces' clipped rounded corners, about a quarter of the keypad. The 5 × 4 grid of v0.10.3 (#144) had shrunk faces to about 37–43dp, which made the gaps matter.
- Two fingers drumming the 0 key entered one 0.
- Press 1, press 2, lift 2, lift 1 entered `21`.

Ruled out: the controller and state path, slow frames dropping events, ancestor widgets and routes, haptics, and the double-tap and press timeouts.

## What Didn't Work

- **Raising the slop and filling the gutters only.** It fixes the first two causes and does nothing for a second finger or for lift order. Rejected once press order had to be fixed in the same branch.
- **A new `_KeyCell` / `_RenderKeyCell` render object** for the cell redirect. Review flagged it as a second copy of the charts' `RedirectToCenter`, which was moved to `lib/ui/core/widgets/redirect_to_center.dart` and reused (AGENTS.md, "A second copy").
- **A hand-rolled multi-pointer recognizer** to avoid `MultiTapGestureRecognizer`'s uncancellable 40ms timer. More code than one `pump` in the affected tests.
- **Excluding the stylus** from the new recognizer. WK46b showed a stylus press that drifted 20dp was then lost.
- **Keeping the InkWell's own splash.** A press held past 100ms drew two ripples, the InkWell's and the new one (WK47).

## Solution

Commits `946ce8ea` (cell-wide hit targets) and `ff7b0ce2` (a tap per finger, in press order), in `lib/ui/features/transactions/views/calculator_keypad.dart`.

**1. A key takes presses over its whole cell.** The 4dp padding moves inside each cell, and `RedirectToCenter` re-runs a missed hit test at the cell's centre, the way material_ui's `_RenderInputPadding` does:

```dart
// Before: Padding(vertical: 4) → SizedBox(keyHeight) → Row([Expanded(child: c)]),
// each key wrapped in Padding(horizontal: 4)
Widget _row(List<Widget> children, double keyHeight) {
  return SizedBox(
    height: keyHeight + 8,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in children)
          Expanded(
            child: RedirectToCenter(
              child: Padding(padding: const EdgeInsets.all(4), child: c),
            ),
          ),
      ],
    ),
  );
}
```

The icon keys' `Tooltip` moves inside the `Material`'s clip. Outside it, the tooltip's opaque listener swallowed corner presses before the redirect could reach the key.

**2. Every finger is its own tap, and keys enter in press order.** `_KeyTaps` sits inside each key's `InkWell` and holds a `MultiTapGestureRecognizer`. One top-level map, shared by every key, holds the press that is down and not yet entered; a new finger landing anywhere enters it first:

```dart
final _held = <int, VoidCallback>{}; // top level, shared by every key

GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
  () => MultiTapGestureRecognizer(
    supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus},
    allowedButtonsFilter: (buttons) => buttons == kPrimaryButton,
  ),
  (taps) => taps
    ..gestureSettings = const DeviceGestureSettings(
      touchSlop: kMinInteractiveDimension, // 48dp of drift
    )
    ..onTapDown = (pointer, details) {
      final older = _held.values.firstOrNull;
      _held
        ..clear()
        ..[pointer] = _enter;
      older?.call();
      _ripple(details.localPosition);
    }
    ..onTap = ((pointer) => _held.remove(pointer)?.call())
    ..onTapCancel = _held.remove,
)
```

Both filters matter: by default MultiTap accepts every device and every button, so a right-click entered a key (WK46). A mouse is left to the plain `InkWell` tap.

**3. The press commits through the InkWell.** `void _enter() => Actions.invoke(context, const ActivateIntent());` runs `InkWell.activateOnIntent`, which calls `Feedback.forTap` and `widget.onTap` (`_withHaptic(onTap)`). Haptics, screen-reader taps, keyboard activation and long-press ⌫ all stay on the InkWell's path (WK48, WK49, and WK12 pins that a long press enters no ⌫).

**4. The key draws its own ripple.** `_KeyTaps` creates one at touch-down with `theme.splashFactory.create(controller: Material.of(context), ...)..confirm()` (the `AccountSelectorTile._ripple` pattern), and the InkWell gets `splashFactory: NoSplash.splashFactory`. `_KeyTapsState.dispose` disposes the ripples still playing, because the `Material` does not remove ink features when a child goes.

**5. Tests.** 14 keypad tests and the recurring form's `tapKey` helper now pump `kDoubleTapMinTime` before ending (see Prevention; AGENTS.md → *Keypad taps*).

## Why This Works

Paths are in Flutter 3.50's `packages/flutter/lib/src/gestures/` unless noted.

- **Drift.** InkWell's tap is a `PrimaryPointerGestureRecognizer`, which rejects once a finger moves past `gestureSettings?.touchSlop ?? kTouchSlop` (`recognizer.dart`; `kTouchSlop` is 18). The Android embedder reports the platform's scaled touch slop (`FlutterView.java`), 8dp on stock Android; iOS reports none, so 18dp. MultiTap checks `computeHitSlop(kind, gestureSettings)` (`multitap.dart`, `events.dart`), so setting `gestureSettings` on the recognizer sets its drift tolerance. `RawGestureDetector` does not copy `MediaQuery`'s gesture settings onto recognizers (only `GestureDetector` does), so the 48dp holds on device.
- **Dead gutters.** Each `Expanded` cell holds the key plus its padding, and `RedirectToCenter` sends any miss inside the cell to the key, so no point between keys is left without one.
- **Second finger.** `PrimaryPointerGestureRecognizer` takes a primary pointer only while it is `ready`, so a second finger on a held key is tracked but never becomes a tap. MultiTap keeps a tap per pointer.
- **No double entry.** Hit-test entries are added deepest first, so `_KeyTaps`'s recognizer joins the arena before the InkWell's; on the sweep the first member wins and the rest are rejected (`arena.dart`). The InkWell's `onTap` never fires for a touch. A mouse never joins the MultiTap arena, so the InkWell still handles it.
- **Press order.** MultiTap alone still commits on pointer-up, in lift order. The shared `_held` map holds at most one pending press and enters it as soon as the next finger lands.
- **Ripple delay.** InkWell's tap recognizer has a 100ms `kPressTimeout` deadline (`tap.dart`). With MultiTap competing in the arena, InkWell's tap-down, and so its splash, now arrives only after that deadline. Hence the own ripple at touch-down.

## Prevention

- **Pump past MultiTap's timer.** Every MultiTap pointer starts a `_CountdownZoned` `Timer` of `kDoubleTapMinTime` (40ms) that is never stored, so nothing can cancel it (`multitap.dart`). A test that ends with it pending fails with "A Timer is still pending even after the widget tree was disposed". Run `await tester.pump(kDoubleTapMinTime);` (from `package:flutter/gestures.dart`) before the test ends.
- **Simulate real fingers in widget tests:**
  - Two fingers: two `tester.startGesture(...)` calls before any `up()`. Lift the second first to check press order (WK44).
  - Drift: `finger.moveBy(const Offset(20, 0))` before `up()` must still enter (WK42); `moveBy(const Offset(0, -60))` must cancel (WK43).
  - Stylus and mouse: `startGesture(pos, kind: PointerDeviceKind.stylus)` (WK46b); `kind: PointerDeviceKind.mouse, buttons: kSecondaryButton` plus `addTearDown(mouse.removePointer)` (WK46).
  - Gutters and corners: `tester.tapAt` 3dp outside the key's `Material` rect, and 1dp inside its corners (WK41, WK45).
  - Ripple: `Material.debugInkFeatures` is null, not empty, until the first feature, so read it as `as List<Object>? ?? const []` (WK47).
- **Test slop is not device slop** (18dp in tests, 8dp on Android). Use drift values above 18dp, and try fast typing on a real phone: the fix has not yet been checked on a device.
- **New keys** must wrap their content in `_KeyTaps` and give their `InkWell` `NoSplash`, or they bring back the single-finger, slop and lift-order losses, or a double ripple.
- **Known limits before changing the keypad:**
  - A held Save, AC or ⌫ is entered as soon as another finger lands.
  - 48dp of drift is more than the compact row pitch (about 44.8dp), so sliding onto the key above still enters the pressed key.
  - Mouse clicks enter but no longer ripple.
  - The keypad's outer 8dp margin still takes no presses.
  - A key that is disabled when the finger lands (rolling from the first digit onto Save or `=`) is not tracked. This predates the fix.

## Related Issues

- #159: the bug. #144: the fifth keypad row that shrank key faces to 37–43dp.
- [`docs/solutions/design-patterns/keypad-formula-replay-verified-persistence.md`](../design-patterns/keypad-formula-replay-verified-persistence.md): the same keypad's formula state, not its gestures.
- [`docs/solutions/developer-experience/flutter-widget-test-and-device-verification-gotchas.md`](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md): another source of "A Timer is still pending" (two `ProviderScope` apps in one test).
- [`docs/solutions/ui-bugs/fl-chart-tooltip-and-edge-label-clipping-in-horizontal-scroll.md`](fl-chart-tooltip-and-edge-label-clipping-in-horizontal-scroll.md): the same hit-test limit, a touch outside a `RenderBox`'s size misses it.
- PRD.md → *Calculator keypad* (**Presses**) and *Accessibility*; AGENTS.md → *Keypad taps*.
