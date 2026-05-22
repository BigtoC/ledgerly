---
title: Analysis slice drill-down async coordination and FX display parity
date: 2026-05-22
category: logic-errors
module: analysis
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Overlapping deletes could leave the drill-down list with the wrong pending-delete state or briefly re-show a row that should stay hidden.
  - Late `onData` or `onError` callbacks from canceled slice subscriptions could overwrite the active drill-down state.
  - A stale async delete failure could show an error snackbar after the user had already moved to a different slice.
  - Drill-down rows could include currencies that the chart had already excluded because FX rates were missing.
  - The stale-rate banner could reflect unrelated fresh rates instead of the FX pairs used by the displayed slice.
root_cause: async_timing
resolution_type: code_fix
severity: high
related_components:
  - charts_controller
  - charts_selection_controller
  - slice_drilldown_controller
  - selected_slice_items_list
  - analysis_drilldown_test
tags:
  - flutter
  - riverpod
  - analysis
  - slice-drilldown
  - delete-undo
  - stale-streams
  - fx-conversion
  - regression-test
---

# Analysis slice drill-down async coordination and FX display parity

## Problem

The Analysis chart drill-down items list sat on top of live repository and FX streams, but it did not mirror the stronger coordination rules already used by Home and Analysis search. That let overlapping deletes, canceled subscriptions, and missing-FX display exclusions push the list out of sync with the chart slice the user had actually selected.

## Symptoms

- Deleting one drill-down row and quickly deleting another could briefly re-show the first row or leave the wrong row pending deletion.
- A canceled or replaced slice selection could still deliver late `onData` or `onError` callbacks into the active drill-down controller.
- A slow failing delete from an older selection could surface an error snackbar after the user had already moved on.
- In category/account views with missing FX, the visible row list could be broader than the chart total or bar total the user tapped.
- The stale-rate banner could stay hidden because some unrelated pair had a fresh timestamp even though the displayed slice was using stale cached FX.

## What Didn't Work

- Treating drill-down delete as a single pending id without a committed-delete bridge. Once delete B started while delete A was being force-committed, row A could reappear until the repository stream caught up.
- Assuming subscription replacement alone was enough. Late callbacks from the old generation still needed explicit guards before mutating state or firing effects.
- Trusting the raw repository slice query for visible rows. In category/account views the chart projection can exclude currencies with missing FX, so the raw row set is broader than the displayed slice.
- An earlier design kept selection local to `_ChartBody`; that would have pushed pie/bar/list coordination back into widget state and made stale-selection recovery harder (session history).

## Solution

Make `SliceDrilldownController` follow the same async contract already proven in Home and Analysis search.

1. `delete(int id)` became `Future<void>` and now force-resolves an existing pending delete before starting another one.
2. If that forced commit fails, the new delete is aborted instead of proceeding into a corrupted state.
3. `_committedDeleteIds` keeps already-committed rows hidden until the repository stream stops returning them.
4. `_generation` and `_commitInFlight` guard stale `onData`, stale `onError`, and stale async delete failures from canceled selections.
5. `_visibleRowsFromCache()` now filters to the actually displayable slice under missing FX. This builds on the earlier `SelectedSlice.category(..., currencyCode)` design that was reserved for missing-FX split cases (session history).
6. `SelectedSliceItemsList` now checks exact pair freshness through `ChartsFxStatus.metadataForPair(...)` instead of reaching into the global FX snapshot and using unrelated fresh rates.

The two key controller changes were:

```dart
Future<void> delete(int id) async {
  final startedGeneration = _generation;
  if (_pendingDeleteId != null) {
    _undoTimer?.cancel();
    _undoTimer = null;
    final prior = _pendingDeleteId!;
    final committed = await _commitOnce(prior, generation: startedGeneration);
    if (!committed || startedGeneration != _generation) return;
  }

  _pendingDeleteId = id;
  _emitFromCache();
  _undoTimer = Timer(kUndoWindow, () async {
    if (startedGeneration != _generation) return;
    final pending = _pendingDeleteId;
    if (pending == null) return;
    await _commitOnce(pending, generation: startedGeneration);
  });
}
```

```dart
List<Transaction> _visibleRowsFromCache() {
  var rows = _lastRows;
  if (_committedDeleteIds.isNotEmpty) {
    rows = rows
        .where((tx) => !_committedDeleteIds.contains(tx.id))
        .toList(growable: false);
  }

  final selection = ref.read(chartsSelectionControllerProvider).selectedSlice;
  if (selection case SelectedCategorySlice(:final currencyCode?)) {
    rows = rows
        .where((tx) => tx.currency.code == currencyCode)
        .toList(growable: false);
  }

  if (selection is! SelectedCurrencySlice) {
    final fxStatus = ref.read(chartsFxStatusProvider).valueOrNull;
    if (fxStatus != null) {
      rows = rows
          .where((tx) => fxStatus.scaledRate(tx.currency.code) != null)
          .toList(growable: false);
    }
  }

  return rows;
}
```

## Why This Works

The root problem was a timing mismatch between local intent and reactive truth. The UI needs immediate optimistic feedback for delete/undo, but repository and FX streams arrive later and can continue emitting after the user has already changed slice selection. Separating pending state from committed-hidden state fixes the overlap gap, while generation/in-flight guards scope every async callback to the currently active selection. Filtering visible rows by the same FX-availability rules used by the chart projection keeps the item list aligned with the chart total the user actually sees.

## Prevention

- For timer-backed optimistic deletes on reactive lists, keep separate concepts for "currently pending" and "already committed locally but not yet reconciled by the stream."
- Any selection-driven `StreamNotifier` that resubscribes on state changes should guard both data and error callbacks with a generation token.
- If an async failure can arrive after the user has changed selection, guard the effect path too; stale snackbar feedback is still stale state.
- If an analysis surface can exclude currencies for missing FX, visible rows, displayed totals, and stale-rate copy must all derive from the same displayable subset.
- Keep regression coverage for overlapping delete visibility, failed forced commits, stale callbacks after selection changes, FX-status-driven re-emits, and integration parity between chart totals and row lists.

## Verification

- `dart format .`
- `flutter analyze`
- `flutter test test/unit/controllers/slice_drilldown_controller_test.dart`
- `flutter test test/widget/features/analysis/selected_slice_items_list_test.dart`
- `flutter test test/integration/analysis_drilldown_test.dart`

## Related Issues

- `docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md` — closest precedent for overlapping delete sequencing and committed-delete shielding.
- `docs/solutions/logic-errors/home-pending-recurring-approval-visibility-and-undo-coordination-2026-05-09.md` — related timer/undo lifetime and feedback-collision coordination.
- `docs/solutions/logic-errors/transaction-search-analysis-regressions-2026-05-10.md` — nearby Analysis-area async readiness and controller-coordination regression.
- `docs/solutions/runtime-errors/riverpod-cross-provider-dependencies-assertion-2026-05-10.md` — related provider-boundary discipline in the Analysis slice.
