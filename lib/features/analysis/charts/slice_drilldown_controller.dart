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
import 'charts_selection_controller.dart';
import 'slice_drilldown_data.dart';

part 'slice_drilldown_controller.g.dart';

typedef SliceDrilldownEffectListener =
    void Function(SliceDrilldownEffect effect);

sealed class SliceDrilldownEffect {
  const SliceDrilldownEffect();
}

final class SliceDrilldownDeleteFailedEffect extends SliceDrilldownEffect {
  const SliceDrilldownDeleteFailedEffect(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

@Riverpod(
  keepAlive: true,
  dependencies: [transactionRepository, ChartsSelectionController],
)
class SliceDrilldownController extends _$SliceDrilldownController {
  StreamController<SliceDrilldownData>? _emitter;
  StreamSubscription<List<Transaction>>? _subscription;
  Timer? _undoTimer;
  int? _pendingDeleteId;
  List<Transaction> _lastRows = const [];
  SliceDrilldownEffectListener? _effectListener;

  @override
  Stream<SliceDrilldownData> build() {
    _emitter?.close();
    _subscription?.cancel();
    _subscription = null;
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDeleteId = null;
    _lastRows = const [];

    final controller = StreamController<SliceDrilldownData>();
    _emitter = controller;

    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _subscription?.cancel();
      _subscription = null;
      _pendingDeleteId = null;
      controller.close();
    });

    final selection = ref.watch(chartsSelectionControllerProvider);
    final selected = selection.selectedSlice;
    if (selected == null) {
      return controller.stream;
    }

    final start = normalizeAnchor(selection.anchorDate, selection.period);
    final end = shiftAnchor(start, selection.period, 1);
    final (categoryId, accountId, currencyCode) = _selectionFilters(selected);
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
            _lastRows = rows;
            _emitFromCache();
          },
          onError: (Object e, StackTrace st) {
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
  void delete(int id) {
    if (_pendingDeleteId != null) {
      _undoTimer?.cancel();
      final prior = _pendingDeleteId!;
      unawaited(_commit(prior));
    }
    _pendingDeleteId = id;
    _emitFromCache();
    _undoTimer = Timer(kUndoWindow, () async {
      final p = _pendingDeleteId;
      if (p == null) return;
      await _commit(p);
    });
  }

  /// Cancel the undo window. The repository is never touched.
  void undoDelete() {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDeleteId = null;
    _emitFromCache();
  }

  Future<void> _commit(int id) async {
    try {
      await ref.read(transactionRepositoryProvider).delete(id);
    } catch (e, st) {
      debugPrint('[SliceDrilldown] commit failed: $e');
      _effectListener?.call(SliceDrilldownDeleteFailedEffect(e, st));
    } finally {
      if (_pendingDeleteId == id) {
        _pendingDeleteId = null;
        _undoTimer = null;
      }
      _emitFromCache();
    }
  }

  void _emitFromCache() {
    _emitter?.add(
      SliceDrilldownData(rows: _lastRows, pendingDeleteId: _pendingDeleteId),
    );
  }

  (int?, int?, String?) _selectionFilters(SelectedSlice selection) {
    return switch (selection) {
      SelectedCategorySlice(:final categoryId, :final currencyCode) => (
        categoryId,
        null,
        currencyCode,
      ),
      SelectedAccountSlice(:final accountId) => (null, accountId, null),
      SelectedCurrencySlice(:final currencyCode) => (null, null, currencyCode),
    };
  }
}
