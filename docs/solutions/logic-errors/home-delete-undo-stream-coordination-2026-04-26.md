---
title: Home delete-undo coordination across timers, stream lag, and overlapping deletes
date: 2026-04-26
category: logic-errors
module: home
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Timed delete failures could leave Home with no visible feedback beyond a hidden row.
  - A second delete could briefly resurrect the first row before `watchByDay()` caught up.
  - Overlapping deletes could replace a failure snackbar with a new undo snackbar.
  - A controller test expected an inner `HomeLoading` emission that Riverpod never guaranteed.
root_cause: async_timing
resolution_type: code_fix
severity: high
related_components:
  - home_controller
  - home_screen
  - transaction_tile
  - transaction_repository
tags:
  - flutter
  - riverpod
  - home
  - delete-undo
  - timer
  - stream-lag
  - async-state
  - regression-test
---

# Home delete-undo coordination across timers, stream lag, and overlapping deletes

## Problem

The Home slice relied on a timer-based undo window while still rendering from live Drift streams. That was fine for the happy path, but once delete commits failed or two deletes overlapped, the controller could hide rows locally without a consistent way to recover visibility or preserve the right snackbar signal.

## Symptoms

- A timed delete failure could keep the row hidden until another stream emission happened.
- Starting delete B while delete A was still pending could make row A reappear briefly before Drift emitted the updated day list.
- If commit A failed while delete B started, the generic failure feedback could be replaced immediately by B's undo snackbar.
- `H01b` was failing with `Bad state: No element` because it asserted a provider contract that Riverpod's `AsyncLoading` already covered.

## What Didn't Work

- Treating `HomeState.loading()` as a guaranteed first `AsyncData` value. The provider exposes outer `AsyncLoading` before any inner `HomeState` emission, so the test was checking the wrong contract.
- Clearing `pendingDelete` alone after commit attempts. That only handled the currently pending row and did nothing for already-committed rows still present in stale `_txForDay` snapshots.
- Using state-only snackbar inference for all delete paths. Timed commit failures happen after the original widget action returns, so they need an explicit effect path instead of widget-local `try/catch`.

## Solution

Keep two separate local concepts in the Home controller:

1. `pendingDelete` for the active undo window.
2. `_committedDeleteIds` for rows whose delete has already been committed locally but may still be present in the latest `watchByDay()` snapshot.

Add a tiny controller-to-screen effect callback for delayed delete failures:

```dart
typedef HomeEffectListener = void Function(HomeEffect effect);

sealed class HomeEffect {
  const HomeEffect();
}

final class HomeDeleteFailedEffect extends HomeEffect {
  const HomeDeleteFailedEffect(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
```

Track locally committed deletes until the day stream stops returning those IDs:

```dart
Future<bool> _commitDelete(int id) async {
  _committedDeleteIds.add(id);
  _composer?.setPendingDelete(_pendingDelete);
  try {
    await ref.read(transactionRepositoryProvider).delete(id);
    if (_pendingDelete?.transaction.id == id) {
      _pendingDelete = null;
      _composer?.setPendingDelete(null);
    }
    return true;
  } catch (error, stackTrace) {
    _committedDeleteIds.remove(id);
    if (_pendingDelete?.transaction.id == id) {
      _pendingDelete = null;
      _composer?.setPendingDelete(null);
    } else {
      _composer?.setPendingDelete(_pendingDelete);
    }
    _effectListener?.call(HomeDeleteFailedEffect(error, stackTrace));
    return false;
  }
}
```

Compose visible rows by filtering both the active pending row and any locally committed IDs:

```dart
final hiddenIds = <int>{...committedDeleteIds};
if (pending != null) hiddenIds.add(pending.transaction.id);

final visible = hiddenIds.isEmpty
    ? _txForDay!
    : _txForDay!
          .where((t) => !hiddenIds.contains(t.id))
          .toList(growable: false);
```

When a second delete arrives while the first is still pending, abort the new delete if committing the first one fails:

```dart
if (_pendingDelete != null) {
  _undoTimer?.cancel();
  _undoTimer = null;
  final prior = _pendingDelete!;
  final committed = await _commitDelete(prior.transaction.id);
  if (!committed) return;
}
```

The screen registers one effect listener in `initState()` and shows `errorSnackbarGeneric` for `HomeDeleteFailedEffect`, while the existing state listener continues to own the undo snackbar path.

## Why This Works

The core bug was a timing mismatch between local intent and eventual stream truth. The UI needs immediate optimistic hiding for the undo window, but Drift updates arrive later and can lag behind controller actions. `_committedDeleteIds` bridges that gap without mutating repository contracts or manually rewriting transaction lists in widgets.

The effect callback solves the other half of the problem: timer-driven failures happen after the original UI action has finished, so the screen needs a side channel for one-shot feedback. Keeping that channel tiny and Home-specific avoids pushing delete-failure semantics into the main `HomeState` union.

## Prevention

- For timer-driven optimistic UI, separate “currently pending” state from “already committed locally but not yet reflected by the stream” state.
- When a controller action can fail after the originating widget callback has returned, use an explicit effect channel instead of trying to overload steady-state view models.
- Cover overlap paths, not just single-action paths. This fix added:
  - `H05c` for timed delete failure recovery
  - `H07b` for stale-stream overlap after rapid double delete
  - `H07c` for failed first-commit aborting the second delete
  - `WH12b` for widget-level delete failure recovery
  - `WH12c` for widget-level overlap visibility
- For `StreamNotifierProvider` tests, assert Riverpod's outer `AsyncLoading` contract instead of assuming an inner loading value will always be emitted as `AsyncData`.

## Related Issues

- `docs/solutions/logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md` — another case where async stream timing needed a synchronous bridge.
- `docs/solutions/logic-errors/transaction-form-workflow-integrity-2026-04-25.md` — related async mutation guardrails for transaction flows.
