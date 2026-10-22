// Slice drill-down items list controller — mirrors the delete/undo
// contract from `CategorySearchDetailController` (Analysis-Search Level 2).
//
// `delete(id)` starts a `kUndoWindow` timer and stamps `pendingDeleteId`;
// the row stays visible until commit so the list/header stay in lockstep
// with the chart slice. A second `delete(id)` commits the prior pending
// row immediately, then starts a fresh timer for the new id.
// `undoDelete()` cancels the timer; the repository is never touched.
//
// The provider emits plain `SliceDrilldownData`; Riverpod wraps it in
// `AsyncValue` for widgets, so the UI gets loading/error handling without
// nesting a second sealed state type inside `AsyncValue`.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/constants.dart';
import 'selected_slice.dart';
import '../../../data/models/transaction.dart';
import 'charts_providers.dart';
import 'charts_selection_controller.dart';
import 'slice_drilldown_data.dart';

part 'slice_drilldown_controller.g.dart';

typedef SliceDrilldownEffectListener =
    void Function(SliceDrilldownEffect effect);

sealed class SliceDrilldownEffect {
  const SliceDrilldownEffect();
}

final class SliceDrilldownDeleteFailedEffect extends SliceDrilldownEffect {
  const SliceDrilldownDeleteFailedEffect();
}

@Riverpod(
  keepAlive: true,
  dependencies: [
    transactionRepository,
    chartsFxStatus,
    ChartsSelectionController,
  ],
)
class SliceDrilldownController extends _$SliceDrilldownController {
  int _generation = 0;
  StreamController<SliceDrilldownData>? _emitter;
  StreamSubscription<List<Transaction>>? _subscription;
  Timer? _undoTimer;
  int? _pendingDeleteId;
  final Set<int> _committedDeleteIds = <int>{};
  Future<bool>? _commitInFlight;
  int? _commitInFlightId;
  List<Transaction> _lastRows = const [];
  SliceDrilldownEffectListener? _effectListener;

  @override
  Stream<SliceDrilldownData> build() {
    final myGeneration = ++_generation;
    _emitter?.close();
    _subscription?.cancel();
    _subscription = null;
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDeleteId = null;
    _committedDeleteIds.clear();
    _commitInFlight = null;
    _commitInFlightId = null;
    _lastRows = const [];

    final controller = StreamController<SliceDrilldownData>();
    _emitter = controller;

    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _subscription?.cancel();
      _subscription = null;
      _pendingDeleteId = null;
      _committedDeleteIds.clear();
      _commitInFlight = null;
      _commitInFlightId = null;
      controller.close();
    });

    ref.listen(chartsFxStatusProvider, (_, _) {
      if (myGeneration != _generation) return;
      if (_lastRows.isEmpty && _pendingDeleteId == null) return;
      _emitFromCache();
    });

    final selection = ref.watch(chartsSelectionControllerProvider);
    final selected = selection.selectedSlice;
    if (selected == null) {
      return controller.stream;
    }

    final start = normalizeAnchor(selection.anchorDate, selection.period);
    final end = shiftAnchor(start, selection.period, 1);
    final (categoryId, accountId, currencyCode) = selectionFilters(selected);
    final repo = ref.read(transactionRepositoryProvider);

    _subscription = repo
        .watchTransactionsForSliceInRange(
          start: start,
          end: end,
          type: selection.type,
          categoryId: categoryId,
          accountId: accountId,
          currencyCode: currencyCode,
        )
        .listen(
          (rows) {
            if (myGeneration != _generation) return;
            if (_committedDeleteIds.isNotEmpty) {
              final visibleIds = rows.map((row) => row.id).toSet();
              _committedDeleteIds.removeWhere((id) => !visibleIds.contains(id));
            }
            _lastRows = rows;
            _emitFromCache();
          },
          onError: (Object e, StackTrace st) {
            if (myGeneration != _generation) return;
            debugPrint('[SliceDrilldown] stream error: $e');
            _emitter?.addError(e, st);
          },
        );

    return controller.stream;
  }

  void setEffectListener(SliceDrilldownEffectListener? listener) {
    _effectListener = listener;
  }

  /// Start the 4-second undo window for [id]. The row stays visible in
  /// the emitted list until either commit or undo fires; the count and
  /// header total remain consistent with the chart slice.
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
      final p = _pendingDeleteId;
      if (p == null) return;
      await _commit(p, generation: startedGeneration);
    });
  }

  /// Cancel the undo window. The repository is never touched.
  void undoDelete() {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDeleteId = null;
    _emitFromCache();
  }

  Future<bool> _commit(int id, {required int generation}) async {
    _committedDeleteIds.add(id);
    if (generation == _generation) {
      _emitFromCache();
    }
    try {
      await ref.read(transactionRepositoryProvider).delete(id);
      if (generation == _generation && _pendingDeleteId == id) {
        _pendingDeleteId = null;
        _undoTimer = null;
        _emitFromCache();
      }
      return true;
    } catch (e) {
      debugPrint('[SliceDrilldown] commit failed: $e');
      _committedDeleteIds.remove(id);
      if (generation == _generation && _pendingDeleteId == id) {
        _pendingDeleteId = null;
        _undoTimer = null;
        _emitFromCache();
      }
      if (generation == _generation) {
        _effectListener?.call(const SliceDrilldownDeleteFailedEffect());
      }
      return false;
    }
  }

  Future<bool> _commitOnce(int id, {required int generation}) {
    final active = _commitInFlight;
    if (_commitInFlightId == id && active != null) {
      return active;
    }

    final future = _commit(id, generation: generation);
    _commitInFlightId = id;
    _commitInFlight = future;
    future.whenComplete(() {
      if (identical(_commitInFlight, future)) {
        _commitInFlight = null;
        _commitInFlightId = null;
      }
    });
    return future;
  }

  void _emitFromCache() {
    final emitter = _emitter;
    if (emitter == null || emitter.isClosed) return;
    emitter.add(
      SliceDrilldownData(
        rows: _visibleRowsFromCache(),
        pendingDeleteId: _pendingDeleteId,
      ),
    );
  }

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
      final fxStatus = ref.read(chartsFxStatusProvider).value;
      if (fxStatus != null) {
        rows = rows
            .where((tx) => fxStatus.scaledRate(tx.currency.code) != null)
            .toList(growable: false);
      }
    }

    return rows;
  }
}
