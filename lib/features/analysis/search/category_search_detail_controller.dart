// Detail-screen controller — see spec § Detail Screen State & Controller.
//
// Owns the 4-second undo window for swipe-to-delete. State emission is
// driven by an internal StreamController so `deleteTransaction` /
// `undoDelete` can re-emit synchronously from the cached
// `_lastTransactions` without waiting for the next repository emission.
//
// Lifecycle: auto-disposed once the screen stops listening, except that a
// pending delete holds a `KeepAliveLink` (`_undoLink`) until it is undone or
// committed, so Undo and the commit still work after the screen pops.
//
// Cleanup axes:
//   - `_subscription` — cancelled on dispose / rebuild.
//   - `_undoTimer`    — cancelled on dispose / before scheduling a new
//                       pending delete.
//   - `_emitter`      — closed at the top of `build()` so a rebuild
//                       does not leak the prior controller.

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/constants.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/transaction.dart';
import 'analysis_controller.dart';
import 'analysis_state.dart';
import 'category_search_detail_state.dart';

part 'category_search_detail_controller.g.dart';

typedef CategorySearchDetailEffectListener = void Function(
  CategorySearchDetailEffect effect,
);

sealed class CategorySearchDetailEffect {
  const CategorySearchDetailEffect();
}

final class CategorySearchDetailDeleteFailedEffect
    extends CategorySearchDetailEffect {
  const CategorySearchDetailDeleteFailedEffect();
}

@Riverpod(dependencies: [transactionRepository, AnalysisController])
class CategorySearchDetailController extends _$CategorySearchDetailController {
  StreamController<CategorySearchDetailState>? _emitter;
  StreamSubscription<List<Transaction>>? _subscription;
  Timer? _undoTimer;
  CategorySearchPendingDelete? _pendingDelete;
  KeepAliveLink? _undoLink;
  final Set<int> _committedDeleteIds = <int>{};
  List<Transaction>? _lastTransactions;
  CategorySearchDetailEffectListener? _effectListener;

  @override
  Stream<CategorySearchDetailState> build({
    required int categoryId,
    required String query,
    required String currencyCode,
  }) {
    // Close any prior emitter from a previous `build()` run — a rebuild
    // (e.g. on `ref.invalidate`, dependency churn, or hot-reload) reuses this
    // notifier. A rebuild also drops the old `Ref`'s keep-alive links, so
    // `_undoLink` is just forgotten here.
    _emitter?.close();
    _subscription?.cancel();
    _subscription = null;
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDelete = null;
    _undoLink = null;
    _committedDeleteIds.clear();
    _lastTransactions = null;

    final controller = StreamController<CategorySearchDetailState>();
    _emitter = controller;

    final trimmedQuery = query.trim();
    final trimmedCurrencyCode = currencyCode.trim();

    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _subscription?.cancel();
      _subscription = null;
      _pendingDelete = null;
      _undoLink = null;
      _committedDeleteIds.clear();
      // The Undo SnackBar can outlive this provider, so a late `undoDelete`
      // (or a failed in-flight commit) must find nothing to emit into.
      if (identical(_emitter, controller)) _emitter = null;
      _lastTransactions = null;
      controller.close();
    });

    if (trimmedQuery.isEmpty || trimmedCurrencyCode.isEmpty) {
      controller.add(const CategorySearchDetailState.empty());
      return controller.stream;
    }

    // Synchronous pre-fill from the parent's cache so the detail page
    // renders the row instantly without a frame of `DetailLoading` while
    // Drift fetches the same data we already have in memory. Drift's
    // first emission on the live subscription below replaces it.
    if (ref.exists(analysisControllerProvider)) {
      final settled = ref.read(analysisControllerProvider).value;
      if (settled is AnalysisResults && settled.query == trimmedQuery) {
        _lastTransactions = settled.transactions;
        controller.add(
          _buildState(
            all: settled.transactions,
            categoryId: categoryId,
            currencyCode: trimmedCurrencyCode,
          ),
        );
      }
    }

    // Always subscribe so live updates flow through after the user edits
    // or deletes a transaction in the modal edit screen and pops back.
    // Drift shares the underlying query execution across multiple
    // subscribers, so the second subscription on top of `AnalysisController`'s
    // own is cheap.
    final repo = ref.watch(transactionRepositoryProvider);
    _subscription = repo
        .watchByMemo(trimmedQuery)
        .listen(
          (txs) {
            _lastTransactions = txs;
            _emitter?.add(
              _buildState(
                all: txs,
                categoryId: categoryId,
                currencyCode: trimmedCurrencyCode,
              ),
            );
          },
          onError: (Object e, StackTrace st) {
            _emitter?.addError(e, st);
          },
        );

    return controller.stream;
  }

  // ---------- Commands ----------

  /// Optimistically hide [id] for [kUndoWindow]; if no Undo lands, commit
  /// to the repository. A second call while a delete is already pending
  /// commits the prior one immediately and starts a fresh timer for the
  /// new id (matches Home's behaviour).
  Future<void> deleteTransaction(int id) async {
    if (_pendingDelete != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _pendingDelete!;
      final committed = await _commitDelete(prior.transaction.id);
      if (!committed) return;
    }

    final tx = _findTransaction(id);
    if (tx == null) return;

    _pendingDelete = CategorySearchPendingDelete(transaction: tx);
    _undoLink ??= ref.keepAlive();
    _emitFromCache();

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _pendingDelete;
      if (pending == null) return;
      await _commitDelete(pending.transaction.id);
    });
  }

  /// Cancel the undo window; the original row reappears on the next
  /// emission. Repository is never touched.
  Future<void> undoDelete() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDelete = null;
    _releaseUndoLink();
    _emitFromCache();
  }

  void setEffectListener(CategorySearchDetailEffectListener? listener) {
    _effectListener = listener;
  }

  // ---------- Internals ----------

  void _releaseUndoLink() {
    _undoLink?.close();
    _undoLink = null;
  }

  Transaction? _findTransaction(int id) {
    final txs = _lastTransactions;
    if (txs == null) return null;
    for (final tx in txs) {
      if (tx.id == id) return tx;
    }
    return null;
  }

  void _emitFromCache() {
    final txs = _lastTransactions;
    if (txs == null) return;
    _emitter?.add(
      _buildState(
        all: txs,
        categoryId: categoryId,
        currencyCode: currencyCode.trim(),
      ),
    );
  }

  Future<bool> _commitDelete(int id) async {
    _committedDeleteIds.add(id);
    _emitFromCache();
    try {
      await ref.read(transactionRepositoryProvider).delete(id);
      if (_pendingDelete?.transaction.id == id) {
        _pendingDelete = null;
        _releaseUndoLink();
        _emitFromCache();
      }
      return true;
    } catch (_) {
      _committedDeleteIds.remove(id);
      if (_pendingDelete?.transaction.id == id) {
        _pendingDelete = null;
        _releaseUndoLink();
      }
      _emitFromCache();
      _effectListener?.call(const CategorySearchDetailDeleteFailedEffect());
      return false;
    }
  }

  CategorySearchDetailState _buildState({
    required List<Transaction> all,
    required int categoryId,
    required String currencyCode,
  }) {
    final pendingId = _pendingDelete?.transaction.id;
    final filtered = all
        .where(
          (t) =>
              t.categoryId == categoryId &&
              t.currency.code == currencyCode &&
              !_committedDeleteIds.contains(t.id) &&
              t.id != pendingId,
        )
        .toList();

    if (filtered.isEmpty) {
      // When the only matching row is the one being deleted, fall through
      // to a `DetailData` with empty days so the screen keeps its
      // `pendingDelete` signal (which drives the undo SnackBar). Going
      // straight to `DetailEmpty` here would silently drop the undo
      // affordance for a user deleting their last matching transaction.
      if (_pendingDelete != null) {
        return CategorySearchDetailState.data(
          days: const [],
          overallSumMinorUnits: 0,
          currency: _pendingDelete!.transaction.currency,
          pendingDelete: _pendingDelete,
        );
      }
      return const CategorySearchDetailState.empty();
    }

    final byDay = <DateTime, List<Transaction>>{};
    for (final tx in filtered) {
      final day = DateHelpers.startOfDay(tx.date);
      byDay.putIfAbsent(day, () => <Transaction>[]).add(tx);
    }

    final days =
        byDay.entries
            .map(
              (e) => DatedTransactionGroup(
                date: e.key,
                transactions: e.value,
                daySumMinorUnits: e.value.fold<int>(
                  0,
                  (sum, t) => sum + t.amountMinorUnits,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final overall = days.fold<int>(0, (sum, day) => sum + day.daySumMinorUnits);
    return CategorySearchDetailState.data(
      days: days,
      overallSumMinorUnits: overall,
      currency: filtered.first.currency,
      pendingDelete: _pendingDelete,
    );
  }
}
