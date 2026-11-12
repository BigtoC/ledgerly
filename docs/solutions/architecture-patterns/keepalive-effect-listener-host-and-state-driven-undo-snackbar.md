---
title: A keepAlive controller's single effect listener belongs to one always-mounted host, and its Undo snackbar follows controller state
date: 2026-11-11
last_updated: 2026-11-12
category: architecture-patterns
module: home
problem_type: architecture_pattern
component: frontend_stimulus
severity: high
applies_when:
  - "A keepAlive Riverpod controller has one effect-listener slot (setEffectListener) and more than one screen shows its rows"
  - "A widget binds a controller callback during build() or clears it in dispose(), and can unmount or sit offstage under StatefulShellRoute.indexedStack"
  - "A snackbar such as Undo must open and close with a controller window (skippingId), or a widget bool mirrors whether it is visible"
  - "A success or failure snackbar calls clearSnackBars() while another row's Undo may still be live"
  - "A ListView.builder builds keyed stateful rows (in-flight buttons, Slidable) and rows above them can be removed"
symptoms:
  - "With a second screen bound to PendingController, swiping Skip on Home would show no Undo and the row was rejected after 4 s with no way back"
  - "Skipping the selected day's only pending row unmounted PendingSection, so a later reject failure went to a null listener and no error showed (WH02f)"
  - "Skipping A then B within 4 s let A's closed.then reset _skipUndoVisible, so approving C cleared B's live Undo (PTS09)"
  - "Undo stayed tappable about 0.25-0.75 s after reject() committed, because a SnackBar's duration starts after its entrance animation (PTS10)"
  - "On the all-pending list, removing a row above reset a row's approve debounce, so a second tap failed with Unexpected calls: approve(2) (PTS08)"
root_cause: scope_issue
resolution_type: code_fix
related_components:
  - pending_controller
  - pending_snack_bars
  - pending_section
  - pending_transactions_screen
  - router
  - undo_snack_bar
tags: [riverpod, keepalive, effect-listener, widget-lifecycle, stateful-shell-route, snackbar-undo, find-child-index-callback, pending-transactions]
---

# A keepAlive controller's single effect listener belongs to one always-mounted host, and its Undo snackbar follows controller state

## Context

Issue #71 (PR #149) added Settings › Pending transactions (`/settings/pending`), a page that lists every pending recurring row. Home's pending section shows only the selected day's rows. Both screens reuse `PendingTile` and the same `PendingController`.

`PendingController` (`lib/ui/features/home/view_models/pending_controller.dart`) is a `keepAlive` Riverpod notifier with one effect-listener slot, `_effectListener`, set through `setEffectListener`. Before the PR, Home's `PendingSection` handled the slot like this:
- it bound the slot from `build` (`_buildData` → `_bindController`);
- it skipped binding again when the notifier was the same object (`if (_controller == controller) return;`);
- it cleared the slot in `dispose` with `setEffectListener(null)`.

So which widget received the controller's effects depended on which widget happened to be mounted.

This caused, or would have caused, the following:

- **A second screen breaks Home** (found while planning, before any code). The new page binds the slot and clears it when it is popped. Meanwhile Home is still mounted, offstage, under `StatefulShellRoute.indexedStack`. When Home becomes visible again, `_bindController`'s identity check skips binding. Home is left with no listener: Skip shows no Undo, and the row is rejected 4 s later.
- **A lost error, already on `main`.** Skipping the selected day's only row makes Home swap `_PendingOnlyBody` for its empty state. `PendingSection` unmounts and clears the slot. If `reject` then throws in `_commitSkip`, `PendingSkipFailedEffect` goes to a null listener (WH02f).
- **A side effect in `build`.** Binding during `build` breaks AGENTS.md's rule against side effects in `build()`.

The PR's code review then found three more problems in the first fix:
- the Undo snackbar was opened from an effect and tracked by a mirrored `_skipUndoVisible` bool, which drifted from the controller's 4 s window;
- a host being disposed could clear the binding of its replacement;
- the new page's keyed `ListView.builder` threw away row state when a row above it left the list.

**Rejected alternatives:**
- **A stack of listeners, newest one wins.** It changes the controller's API, keeps binding as a side effect of `build`, and still loses the error when Home unmounts, because the stack is then empty.
- **A mixin shared by Home and the page.** Once a single host exists, the mixin has one user.
- **The host inside `HomeScreen`.** go_router builds branches lazily, so `/settings/pending` can be reached before Home is ever built.
- **The host inside `lib/ui/core/adaptive_shell.dart`.** `ui/core` must not import a feature slice.
- **Undo opened from the effect and closed from `ref.listen`.** The two paths reorder and trip `assert(_snackBars.first == controller)`; see *Why This Matters*.

## Guidance

### 1. One owner for the slot: a host above the shell that binds in `initState`

`lib/app/router.dart` wraps the shell:

```dart
StatefulShellRoute.indexedStack(
  pageBuilder: (ctx, state, shell) => _materialPage(
    state,
    PendingSnackBars(child: AdaptiveShell(/* ... */ child: shell)),
  ),
```

`lib/ui/features/home/views/pending_snack_bars.dart`:

```dart
@override
void initState() {
  super.initState();
  _controller = ref.read(pendingControllerProvider.notifier)
    ..setEffectListener(_onEffect);
}

@override
void dispose() {
  _controller.removeEffectListener(_onEffect);
  super.dispose();
}
```

`PendingSection` now binds nothing, and `PendingTransactionsScreen` has no listener code. Snackbars still go to the root `ScaffoldMessenger`, so a pending snackbar shows on whichever tab is open, as it already did while Home sat offstage.

### 2. Remove only your own binding

```dart
void setEffectListener(PendingEffectListener listener) {
  _effectListener = listener;
}

/// Clears the listener only while [listener] still holds it, so a host
/// disposed after its replacement bound does not unbind the replacement.
void removeEffectListener(PendingEffectListener listener) {
  if (_effectListener == listener) _effectListener = null;
}
```

`setEffectListener` no longer accepts `null`. Tear-offs of the same instance method on the same receiver compare equal with `==`, though they need not be `identical`. So `removeEffectListener(_onEffect)` matches only this `State`'s own binding.

### 3. Drive the Undo from controller state, and derive "undo pending"

`PendingSkipStartedEffect` was deleted, and the mirrored `_skipUndoVisible` flag is gone. The host opens and closes the Undo from ordered `(previous, next)` state pairs:

```dart
void _onSkipWindow(int? ended, int? started) {
  if (ended == started) return;
  if (ended != null) _undo?.close();
  if (started == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final l10n = AppLocalizations.of(context);
  final undo = _undo = messenger.showUndoSnackBar(
    message: l10n.homePendingSkippedSnack,
    undoLabel: l10n.commonUndo,
    onUndo: () => unawaited(_controller.undoSkip()),
  );
  // Once it is gone, close() would hide whichever snackbar is current.
  undo.closed.then((_) {
    if (_undo == undo) _undo = null;
  });
}

@override
Widget build(BuildContext context) {
  ref.listen(
    pendingControllerProvider,
    (previous, next) =>
        _onSkipWindow(_skippingId(previous), _skippingId(next)),
  );
  return widget.child;
}

// Top-level helper (not the controller's private field of the same name).
int? _skippingId(AsyncValue<PendingState>? state) => switch (state?.value) {
  PendingData(:final skippingId) => skippingId,
  _ => null,
};
```

The remaining effects read "undo pending" from the controller, `_skippingId(ref.read(pendingControllerProvider)) != null`:
- Approve success is suppressed while an Undo is pending.
- Approve and skip failures queue their error behind a live Undo instead of clearing it:

  ```dart
  case PendingApproveFailedEffect():
  case PendingSkipFailedEffect():
    // Queued behind a live Undo rather than clearing it.
    if (!undoPending) messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
  ```

The controller's 4 s timer is unchanged.

### 4. Keyed stateful rows in `ListView.builder` need `findChildIndexCallback`

In `lib/ui/features/home/views/pending_transactions_screen.dart`:

```dart
ListView.builder(
  itemCount: rows.length,
  findChildIndexCallback: (key) {
    final i = rows.indexWhere((r) => ValueKey(r.id) == key);
    return i < 0 ? null : i;
  },
  itemBuilder: (_, i) => PendingTile(key: ValueKey(rows[i].id), /* ... */),
)
```

In the pinned Flutter 3.47.9, `findChildIndexCallback` is deprecated only on `ListView.separated`, not on `.builder`.

## Why This Matters

These mechanics were checked against Flutter 3.47.9 and flutter_riverpod 3.4.3:

- **Offstage branches are paused, but a callback slot is not.**
  - `ConsumerStatefulWidget` pauses its `ref.watch` subscriptions (not `ref.listen`) while `TickerMode` is off, and replays the last missed change on resume (`_updateTickerMode` loops over `_dependencies` only). `StatefulShellRoute.indexedStack` keeps inactive branches mounted with `TickerMode` off.
  - The effect callback is a plain closure, so pausing never blocked it. The bug was who owned the slot: an offstage Home rebuilt on resume, but its identity check skipped binding again.
- **The replacement's `initState` runs before the old state's `dispose`.** When an element is replaced, the new state inflates during the build, and the old one is unmounted when the frame finalizes. A replaced route also stays mounted through its exit transition. So an unconditional `setEffectListener(null)` in `dispose` wipes the binding its replacement just made.
- **A SnackBar's `duration` starts after its entrance.**
  - `ScaffoldMessengerState` starts its timer only once the 250 ms entrance animation completes. If another snackbar is current, that one's exit animation runs first.
  - The controller's `Timer(kUndoWindow)` starts at `skip()`. So with `duration: kUndoWindow`, Undo stayed tappable about 0.25–0.75 s after `reject()` committed, and a tap then silently did nothing.
  - Closing the Undo at the `skippingId → null` transition starts its exit at the commit. `persist: false` keeps the snackbar's own timer as a fallback.
- **Any flag that mirrors a snackbar's visibility goes stale.** `showUndoSnackBar` (`lib/ui/core/widgets/undo_snack_bar.dart`) calls `clearSnackBars()`, which completes the `.closed` future of the previous Undo while the new one is live. Reading `PendingData.skippingId` derives the answer from the one source of truth (AGENTS.md, *State you can derive*).
- **Opening from one delivery path and closing from another lets the two reorder.**
  - Effects are called synchronously inside the command.
  - State arrives later: a microtask emit, then the broadcast stream, then the notifier, then `ref.listen`.
  - `ScaffoldFeatureController.close()` asserts that it closes the current snackbar, and in release it would hide whichever snackbar is current.
  - Example: skipping B commits A. B's effect showed B's snackbar before A's `skippingId → null` arrived and closed it while it was still queued.
  - Driving both from the same state pairs keeps them in order. Nulling `_undo` on `.closed` keeps `close()` aimed at this host's Undo only.
- **Keyed rows in a builder list lose state without the callback.**
  - Without `findChildIndexCallback`, `SliverMultiBoxAdaptorElement` keeps each element at its old index and gives it the widget now built there.
  - When a row above is removed, that widget has a different key, so the element is recreated. That loses `_ApproveCircleButton`'s `_approving` debounce, its animation, and the `Slidable` state.
  - Home's keyed `Column` never had this problem, because multi-child elements match children by key.

## When to Apply

- **Adding a screen or sheet that uses a controller with a single effect slot.** This includes adding a second consumer to one that has a single owner today. Other single-slot controllers each have one owning screen:
  - `recurring_rules_controller.dart` with `recurring_rules_screen.dart`, and `shopping_list_controller.dart` with `shopping_list_screen.dart` (which has the same identity short-circuit), still clear in `dispose`. Both are auto-dispose and drop the pending delete in `onDispose`, so nothing can fail after their screen is gone.
  - `slice_drilldown_controller.dart` (`keepAlive`) with `selected_slice_items_list.dart`, and `category_search_detail_controller.dart` (a `KeepAliveLink` during the undo window) with `category_search_detail_screen.dart`, outlive their screen and still commit. A host above the shell cannot watch them: the search controller is a family, and the drill-down is scoped under Analysis. Since #150 each screen binds, in `didChangeDependencies`, a listener that captures only the messenger and the message, and leaves it bound after `dispose`. It holds no `State`, so running after unmount is safe, and the next screen's bind replaces it. Tests: `a delete that fails after the screen pops still shows the error` and `a delete that fails after the list unmounts still shows the error`.
- **Any widget that binds a controller callback in `build`, or clears shared state unconditionally in `dispose`.**
- **Any snackbar whose life should match a controller timer or window,** and any bool that mirrors a snackbar's visibility.
- **Any `ListView.builder` / `SliverList.builder` with keyed stateful children whose rows can be removed above others.** Unchecked candidates:
  - `recurring_rules_screen.dart` (`_RuleTile`)
  - `shopping_list_screen.dart` (the keyed `Slidable`)

**Review checklist:**
- Bind callbacks in `initState`, or use `ref.listen` in `build`. Never call a bind method from `build`.
- Remove with "only if it is still mine".
- Open and close a snackbar from the same ordered source.
- Never assume a SnackBar's `duration` lines up with a controller `Timer`.
- Don't `clearSnackBars()` before an error while another row's Undo may be live.

## Examples

These tests failed before their fix and pass after:

- **WH02f** (`test/widget/features/home/home_screen_test.dart`): the binder unmounts during the window. Stub `pendingRepo.reject(1)` to throw. Swipe the only row for today, tap "Skip once", and assert the empty state shows. Then `pump(seconds: 5)` and expect the generic error snackbar.
- **PC12** (`test/unit/controllers/pending_controller_test.dart`): bind A, bind B, `removeEffectListener(A)`, run a command. A gets nothing and B gets one effect.
- **PTS08** (`test/widget/features/home/pending_transactions_screen_test.dart`): row state survives a row above leaving. With `watchAll` on a `StreamController` and `approve(2)` returning a never-completing `Completer().future`, tap approve on row 2, push `[row2]` and pump twice, tap again, and `verifyNever(() => repo.approve(2))`. mocktail's earlier `verify` marked the first call, so only new calls count.
- **PTS09:** skip A, skip B, approve C. B's `SnackBarAction` is still shown, and "Approved — C" is not.
- **PTS10:** skip, then pump to 4.1 s and `verify(reject(1))`. Pump 300 ms more and expect `findsNothing` for `SnackBarAction`, before the snackbar's own (late-starting) timer would close it.
- **PTS11:** skip, then an approve that throws. The Undo stays, and the error shows after the window ends.
- **router_test:** `PendingSnackBars` is an ancestor of `AdaptiveShell`.

**Harness rules learned here:**
- Test skip and undo with the real `PendingController` and a mocked repo. A fake controller that overrides `build` leaves `_composer` null, so `skip()` never emits again.
- Every harness that asserts a pending snackbar must wrap its screen in `PendingSnackBars`: the `_wrap` helpers in `pending_section_test` and `pending_transactions_screen_test`, and `makeApp` in `home_screen_test`.
- After removing an open `Slidable`, pump one extra frame. The other rows release their tap barrier in a post-frame callback.
- Never use `pumpAndSettle` inside the 4 s window. In the integration flow, pump `500ms` a second time after "Skip once", because the previous "Approved" snackbar is still leaving.
- Use one `testWidgets` per swapped `ProviderContainer` state. Swapping containers inside one test left a Riverpod dispose timer pending.
- Adding `PendingController` to `SettingsScreen`'s `@Dependencies` spread to `test/integration/csv_import_flow_test.dart`, which finds that screen by type. Only `dart analyze --fatal-infos` reports these.

**Known gaps, accepted:**
- **A leaving Undo is still tappable (unverified).** `close()` starts a 250 ms exit, and `undoSkip()` takes no id. Tapping A's Undo while it leaves, within 250 ms of skipping B, would cancel B's skip instead.
- **A commit error can be lost.** If skipping B commits A and A's reject fails, B's `showUndoSnackBar` clears A's queued error. This was already true before the PR.
- **Possible debug assertion (unverified).** `_undo?.close()` on an Undo that is still queued behind a leaving snackbar, within about 250 ms, could trip the `_snackBars.first` assertion in debug builds. That needs two full swipe-and-Skip gestures inside 250 ms.

## Related

- [`../logic-errors/home-pending-recurring-approval-visibility-and-undo-coordination-2026-05-09.md`](../logic-errors/home-pending-recurring-approval-visibility-and-undo-coordination-2026-05-09.md). This doc supersedes its §3 skip-undo/approve coordination, because `PendingSkipStartedEffect` and `_skipUndoVisible` in `pending_section.dart` no longer exist. Its §1 `keepAlive` fix still stands.
- [`controller-command-outcomes-and-snackbar-actions-outliving-widgets.md`](controller-command-outcomes-and-snackbar-actions-outliving-widgets.md). Exception to its rule (e) "clear before every snackbar": while an Undo is live, `PendingSnackBars` queues errors behind it instead.
- [`../ui-bugs/pending-section-cross-day-rendering-2026-05-09.md`](../ui-bugs/pending-section-cross-day-rendering-2026-05-09.md). Its day-scoping is why the all-days page exists, and that page deliberately does not call `pinDay`.
- [`../logic-errors/home-delete-undo-stream-coordination-2026-04-26.md`](../logic-errors/home-delete-undo-stream-coordination-2026-04-26.md). An earlier form of "bind once in `initState`, Undo from state".
- [`../developer-experience/flutter-widget-test-and-device-verification-gotchas.md`](../developer-experience/flutter-widget-test-and-device-verification-gotchas.md). Gotcha #3 is the same trap as two containers in one test.
- [`../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`](../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md). Its note that Undo hides about 250 ms after commit predates closing from state.
- GitHub: BigtoC/ledgerly#71, BigtoC/ledgerly#149, BigtoC/ledgerly#86.
