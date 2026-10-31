// Shopping-list slice controller — Task 4.
//
// `ShoppingListController` composes one stream into a single
// [ShoppingListState]:
//   1. `shoppingListRepository.watchAll()` — all draft items, newest first.
//
// `@riverpod` (autoDispose) means the controller disposes when the route
// is popped. StatefulShellRoute.indexedStack keeps it alive during tab
// switches because autoDispose only triggers when there are no listeners.
//
// Delete/undo pattern:
//   - `deleteItem(id)` hides the row immediately (pendingDelete) and starts a
//     4-second timer.
//   - `undoDelete()` cancels the timer without touching the repository.
//   - Timer fires → `_commitDelete(id)` → `repo.delete(id)`.
//   - On failure: restore the hidden row, fire
//     [ShoppingListDeleteFailedEffect].

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../data/models/shopping_list_item.dart';
import '../../data/repositories/shopping_list_repository.dart';
import 'shopping_list_state.dart';

part 'shopping_list_controller.g.dart';

typedef ShoppingListEffectListener = void Function(ShoppingListEffect effect);

sealed class ShoppingListEffect {
  const ShoppingListEffect();
}

final class ShoppingListDeleteFailedEffect extends ShoppingListEffect {
  const ShoppingListDeleteFailedEffect();
}

@Riverpod(dependencies: [shoppingListRepository])
class ShoppingListController extends _$ShoppingListController {
  ShoppingListPendingDelete? _pendingDelete;
  Timer? _undoTimer;
  _Composer? _composer;
  ShoppingListEffectListener? _effectListener;

  @override
  Stream<ShoppingListState> build() {
    final repo = ref.watch(shoppingListRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      pendingDeleteGetter: () => _pendingDelete,
    );
    _composer = composer;
    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _pendingDelete = null;
      composer.dispose();
    });
    return composer.stream;
  }

  // ---------- Commands ----------

  /// Visually hide the item and start the 4-second undo window.
  /// If another delete is pending, commit it first, then start a fresh
  /// window for the new id.
  Future<void> deleteItem(int id) async {
    if (_pendingDelete != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _pendingDelete!;
      final committed = await _commitDelete(prior.itemId);
      if (!committed) return;
    }

    _pendingDelete = ShoppingListPendingDelete(itemId: id);
    _composer?.notifyPendingDeleteChanged();

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _pendingDelete;
      if (pending == null) return;
      await _commitDelete(pending.itemId);
    });
  }

  /// Cancel the undo window; the original row reappears on the next emission.
  /// Repository is never touched.
  Future<void> undoDelete() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDelete = null;
    _composer?.notifyPendingDeleteChanged();
  }

  void setEffectListener(ShoppingListEffectListener? listener) {
    _effectListener = listener;
  }

  Future<bool> _commitDelete(int id) async {
    _composer?.notifyPendingDeleteChanged();
    try {
      await ref.read(shoppingListRepositoryProvider).delete(id);
      if (_pendingDelete?.itemId == id) {
        _pendingDelete = null;
        _composer?.notifyPendingDeleteChanged();
      }
      return true;
    } catch (_) {
      if (_pendingDelete?.itemId == id) {
        _pendingDelete = null;
      }
      // Re-emit even when a second delete is already pending so the failed
      // item's restored row becomes visible.
      _composer?.notifyPendingDeleteChanged();
      _effectListener?.call(const ShoppingListDeleteFailedEffect());
      return false;
    }
  }
}

// ---------- Internal stream composition ----------

/// Owns the upstream subscription and maps it into a single
/// [ShoppingListState] broadcast stream.
class _Composer {
  _Composer({required this._repo, required this._pendingDeleteGetter}) {
    _out = StreamController<ShoppingListState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final ShoppingListRepository _repo;
  final ShoppingListPendingDelete? Function() _pendingDeleteGetter;
  late final StreamController<ShoppingListState> _out;

  StreamSubscription<List<ShoppingListItem>>? _itemsSub;
  List<ShoppingListItem>? _items;
  bool _emitScheduled = false;

  Stream<ShoppingListState> get stream => _out.stream;

  void _start() {
    _out.add(const ShoppingListState.loading());
    _itemsSub = _repo.watchAll().listen((List<ShoppingListItem> rows) {
      _items = rows;
      _scheduleEmit();
    }, onError: _onError);
  }

  Future<void> _stop() async {
    await _itemsSub?.cancel();
    _itemsSub = null;
  }

  Future<void> dispose() async {
    await _stop();
    await _out.close();
  }

  void notifyPendingDeleteChanged() {
    _scheduleEmit();
  }

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(ShoppingListState.error(error, stack));
  }

  void _scheduleEmit() {
    if (_emitScheduled || _out.isClosed) return;
    _emitScheduled = true;
    scheduleMicrotask(() {
      _emitScheduled = false;
      _emitIfReady();
    });
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    final items = _items;
    if (items == null) return;

    final pending = _pendingDeleteGetter();

    // Filter out the pending-delete item visually.
    final visible = pending == null
        ? items
        : items
              .where((item) => item.id != pending.itemId)
              .toList(growable: false);

    if (visible.isEmpty && pending == null) {
      _out.add(const ShoppingListState.empty());
    } else {
      _out.add(ShoppingListState.data(items: visible, pendingDelete: pending));
    }
  }
}
