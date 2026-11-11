// Pending approval slice controller — spec 2026-05-08.
//
// `PendingController` composes `pendingTransactionRepository.watchAll()`
// into a single [PendingState]. Mirrors `RecurringRulesController`'s
// delete-with-undo pattern: swipe-skip hides the row immediately and
// starts a 4-second timer; `undoSkip` cancels without touching the
// repository; timer fires → `repo.reject(id)`.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/constants.dart';
import '../../../../data/repositories/pending_transaction_repository.dart';
import '../../../../domain/models/pending_transaction.dart';
import 'pending_state.dart';

part 'pending_controller.g.dart';

typedef PendingEffectListener = void Function(PendingEffect effect);

sealed class PendingEffect {
  const PendingEffect();
}

/// Fired after a successful approve. PendingSnackBars shows a SnackBar
/// with `homePendingApprovedSnack(ruleName)`.
final class PendingApproveSucceededEffect extends PendingEffect {
  const PendingApproveSucceededEffect({required this.ruleName});
  final String ruleName;
}

final class PendingApproveFailedEffect extends PendingEffect {
  const PendingApproveFailedEffect();
}

final class PendingSkipFailedEffect extends PendingEffect {
  const PendingSkipFailedEffect();
}

@Riverpod(keepAlive: true, dependencies: [pendingTransactionRepository])
class PendingController extends _$PendingController {
  int? _skippingId;
  Timer? _undoTimer;
  _Composer? _composer;
  PendingEffectListener? _effectListener;

  @override
  Stream<PendingState> build() {
    final repo = ref.watch(pendingTransactionRepositoryProvider);
    final composer = _Composer(repo: repo, skippingIdGetter: () => _skippingId);
    _composer = composer;
    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _skippingId = null;
      composer.dispose();
    });
    return composer.stream;
  }

  // ---------- Commands ----------

  /// Approve. Returns true on success, false on failure. Returning a bool
  /// (rather than throwing) lets `_ApproveCircleButton` reverse its
  /// success animation when the underlying call fails.
  Future<bool> approve(int pendingId) async {
    final ruleName = _findRuleName(pendingId);
    try {
      await ref.read(pendingTransactionRepositoryProvider).approve(pendingId);
      _effectListener?.call(
        PendingApproveSucceededEffect(ruleName: ruleName ?? ''),
      );
      return true;
    } catch (_) {
      _effectListener?.call(const PendingApproveFailedEffect());
      return false;
    }
  }

  Future<void> skip(int pendingId) async {
    final prior = _skippingId;
    if (prior != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      await _commitSkip(prior);
    }

    _skippingId = pendingId;
    _composer?.notifySkipChanged();

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _skippingId;
      if (pending == null) return;
      await _commitSkip(pending);
    });
  }

  /// Best-effort lookup of the rule name from the latest data state.
  String? _findRuleName(int pendingId) {
    final value = state.value;
    if (value is! PendingData) return null;
    for (final item in value.items) {
      if (item.id == pendingId) return item.memo;
    }
    return null;
  }

  Future<void> undoSkip() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _skippingId = null;
    _composer?.notifySkipChanged();
  }

  void setEffectListener(PendingEffectListener listener) {
    _effectListener = listener;
  }

  /// Clears the listener only while [listener] still holds it, so a host
  /// disposed after its replacement bound does not unbind the replacement.
  void removeEffectListener(PendingEffectListener listener) {
    if (_effectListener == listener) _effectListener = null;
  }

  Future<void> _commitSkip(int pendingId) async {
    _skippingId = null;
    _composer?.notifySkipChanged();
    try {
      await ref.read(pendingTransactionRepositoryProvider).reject(pendingId);
    } catch (_) {
      _effectListener?.call(const PendingSkipFailedEffect());
    }
  }
}

// ---------- Internal stream composition ----------

class _Composer {
  _Composer({required this._repo, required this._skippingIdGetter}) {
    _out = StreamController<PendingState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final PendingTransactionRepository _repo;
  final int? Function() _skippingIdGetter;
  late final StreamController<PendingState> _out;
  StreamSubscription<List<PendingTransaction>>? _sub;
  List<PendingTransaction>? _items;
  bool _emitScheduled = false;

  Stream<PendingState> get stream => _out.stream;

  void _start() {
    _out.add(const PendingState.loading());
    _sub = _repo.watchAll().listen((rows) {
      _items = rows;
      _scheduleEmit();
    }, onError: _onError);
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await _stop();
    await _out.close();
  }

  void notifySkipChanged() => _scheduleEmit();

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(PendingState.error(error, stack));
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

    final skippingId = _skippingIdGetter();

    if (items.isEmpty && skippingId == null) {
      _out.add(const PendingState.empty());
    } else {
      _out.add(PendingState.data(items: items, skippingId: skippingId));
    }
  }
}
