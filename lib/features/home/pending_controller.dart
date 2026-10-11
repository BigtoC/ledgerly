// Pending approval slice controller — spec 2026-05-08.
//
// `PendingController` composes `pendingTransactionRepository.watchAll()`
// into a single [PendingState]. Mirrors `RecurringRulesController`'s
// delete-with-undo pattern: swipe-skip hides the row immediately and
// starts a 4-second timer; `undoSkip` cancels without touching the
// repository; timer fires → `repo.reject(id)`.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../data/models/pending_transaction.dart';
import '../../data/repositories/pending_transaction_repository.dart';
import 'pending_state.dart';

part 'pending_controller.g.dart';

typedef PendingEffectListener = void Function(PendingEffect effect);

sealed class PendingEffect {
  const PendingEffect();
}

/// Fired immediately when the user swipes a row to skip. The widget shows
/// a SnackBar with `homePendingSkippedSnack` text and an Undo action that
/// calls `notifier.undoSkip()`.
final class PendingSkipStartedEffect extends PendingEffect {
  const PendingSkipStartedEffect();
}

/// Fired after a successful approve. The widget shows a SnackBar with
/// `homePendingApprovedSnack(ruleName)`.
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
  PendingSkipScheduled? _skipScheduled;
  Timer? _undoTimer;
  _Composer? _composer;
  PendingEffectListener? _effectListener;

  @override
  Stream<PendingState> build() {
    final repo = ref.watch(pendingTransactionRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      skipScheduledGetter: () => _skipScheduled,
    );
    _composer = composer;
    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _skipScheduled = null;
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
    if (_skipScheduled != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      await _commitSkip(_skipScheduled!.pendingId);
    }

    _skipScheduled = PendingSkipScheduled(pendingId: pendingId);
    _composer?.notifySkipChanged();

    _effectListener?.call(const PendingSkipStartedEffect());

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _skipScheduled;
      if (pending == null) return;
      await _commitSkip(pending.pendingId);
    });
  }

  /// Best-effort lookup of the rule name from the latest data state.
  String? _findRuleName(int pendingId) {
    final value = state.valueOrNull;
    if (value is! PendingData) return null;
    for (final item in value.items) {
      if (item.id == pendingId) return item.memo;
    }
    return null;
  }

  Future<void> undoSkip() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _skipScheduled = null;
    _composer?.notifySkipChanged();
  }

  void setEffectListener(PendingEffectListener? listener) {
    _effectListener = listener;
  }

  Future<void> _commitSkip(int pendingId) async {
    _skipScheduled = null;
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
  _Composer({
    required PendingTransactionRepository repo,
    required PendingSkipScheduled? Function() skipScheduledGetter,
  }) : _repo = repo,
       _skipScheduledGetter = skipScheduledGetter {
    _out = StreamController<PendingState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final PendingTransactionRepository _repo;
  final PendingSkipScheduled? Function() _skipScheduledGetter;
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
      // dispose() may have closed the controller between schedule and
      // microtask fire; adding to a closed StreamController throws.
      if (_out.isClosed) return;
      _emitIfReady();
    });
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    final items = _items;
    if (items == null) return;

    final skip = _skipScheduledGetter();

    if (items.isEmpty && skip == null) {
      _out.add(const PendingState.empty());
    } else {
      _out.add(PendingState.data(items: items, skipScheduled: skip));
    }
  }
}
