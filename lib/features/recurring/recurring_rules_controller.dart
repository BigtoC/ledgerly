// Recurring-rules slice controller.
//
// Composes `recurringRulesRepository.watchActive()` into a single
// [RecurringRulesState]. Mirrors `ShoppingListController`'s delete-with-
// undo pattern: swipe-delete hides the row immediately and starts a
// 4-second timer; `undoDelete` cancels without touching the repository;
// timer fires → `repo.archive(id)`.
//
// Pause/resume calls `repo.setActive(id, active: ...)`. The repository
// handles next_due_date recomputation on resume.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import 'recurring_rules_state.dart';

part 'recurring_rules_controller.g.dart';

typedef RecurringRulesEffectListener =
    void Function(RecurringRulesEffect effect);

sealed class RecurringRulesEffect {
  const RecurringRulesEffect();
}

final class RecurringRulesDeleteFailedEffect extends RecurringRulesEffect {
  const RecurringRulesDeleteFailedEffect(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

@Riverpod(dependencies: [recurringRulesRepository])
class RecurringRulesController extends _$RecurringRulesController {
  RecurringRulesPendingDelete? _pendingDelete;
  Timer? _undoTimer;
  _Composer? _composer;
  RecurringRulesEffectListener? _effectListener;

  @override
  Stream<RecurringRulesState> build() {
    final repo = ref.watch(recurringRulesRepositoryProvider);
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

  Future<void> pauseRule(int id) async {
    await ref
        .read(recurringRulesRepositoryProvider)
        .setActive(id, active: false);
  }

  Future<void> resumeRule(int id) async {
    await ref
        .read(recurringRulesRepositoryProvider)
        .setActive(id, active: true);
  }

  Future<void> deleteRule(int id) async {
    if (_pendingDelete != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _pendingDelete!;
      final committed = await _commitDelete(prior.ruleId);
      if (!committed) return;
    }

    _pendingDelete = RecurringRulesPendingDelete(ruleId: id);
    _composer?.notifyPendingDeleteChanged();

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _pendingDelete;
      if (pending == null) return;
      await _commitDelete(pending.ruleId);
    });
  }

  Future<void> undoDelete() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDelete = null;
    _composer?.notifyPendingDeleteChanged();
  }

  void setEffectListener(RecurringRulesEffectListener? listener) {
    _effectListener = listener;
  }

  Future<bool> _commitDelete(int id) async {
    _composer?.notifyPendingDeleteChanged();
    try {
      await ref.read(recurringRulesRepositoryProvider).archive(id);
      if (_pendingDelete?.ruleId == id) {
        _pendingDelete = null;
        _composer?.notifyPendingDeleteChanged();
      }
      return true;
    } catch (error, stackTrace) {
      if (_pendingDelete?.ruleId == id) {
        _pendingDelete = null;
      }
      _composer?.notifyPendingDeleteChanged();
      _effectListener?.call(
        RecurringRulesDeleteFailedEffect(error, stackTrace),
      );
      return false;
    }
  }
}

// ---------- Internal stream composition ----------

class _Composer {
  _Composer({
    required RecurringRulesRepository repo,
    required RecurringRulesPendingDelete? Function() pendingDeleteGetter,
  }) : _repo = repo,
       _pendingDeleteGetter = pendingDeleteGetter {
    _out = StreamController<RecurringRulesState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final RecurringRulesRepository _repo;
  final RecurringRulesPendingDelete? Function() _pendingDeleteGetter;
  late final StreamController<RecurringRulesState> _out;
  StreamSubscription<List<RecurringRule>>? _sub;
  List<RecurringRule>? _rules;
  bool _emitScheduled = false;

  Stream<RecurringRulesState> get stream => _out.stream;

  void _start() {
    _out.add(const RecurringRulesState.loading());
    _sub = _repo.watchActive().listen((rows) {
      _rules = rows;
      _scheduleEmit();
    }, onError: _onError);
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await _stop();
    if (!_out.isClosed) await _out.close();
  }

  void notifyPendingDeleteChanged() => _scheduleEmit();

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(RecurringRulesState.error(error, stack));
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
    final rules = _rules;
    if (rules == null) return;

    final pending = _pendingDeleteGetter();
    final visible = pending == null
        ? rules
        : rules.where((r) => r.id != pending.ruleId).toList(growable: false);

    if (visible.isEmpty && pending == null) {
      _out.add(const RecurringRulesState.empty());
    } else {
      _out.add(
        RecurringRulesState.data(rules: visible, pendingDelete: pending),
      );
    }
  }
}
