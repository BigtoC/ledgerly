// Recurring-rules slice controller.
//
// Composes `recurringRulesRepository.watchActive()` into a single
// [RecurringRulesState]. Mirrors `ShoppingListController`'s delete-with-
// undo pattern: swipe-delete hides the row immediately and starts a
// 4-second timer; `undoDelete(id)` cancels that rule's pending delete
// without touching the repository; timer fires → `repo.archive(id)`.
//
// Pause/resume calls `repo.setActive(id, active: ...)`. The repository
// handles next_due_date recomputation on resume.
//
// Commands never throw. Each returns an outcome from
// `recurring_rules_state.dart` that the screen switches on. Only the
// timer-driven delete commit, which fails after `deleteRule` has
// returned, reports through [RecurringRulesDeleteFailedEffect].

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../domain/models/recurring_rule.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import 'recurring_rules_state.dart';

part 'recurring_rules_controller.g.dart';

typedef RecurringRulesEffectListener = void Function(
  RecurringRulesEffect effect,
);

sealed class RecurringRulesEffect {
  const RecurringRulesEffect();
}

final class RecurringRulesDeleteFailedEffect extends RecurringRulesEffect {
  const RecurringRulesDeleteFailedEffect();
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

  Future<PauseRecurringRuleOutcome> pauseRule(int id) async {
    try {
      await ref
          .read(recurringRulesRepositoryProvider)
          .setActive(id, active: false);
      return const PauseRecurringRuleOutcome.ok();
    } catch (e) {
      debugPrint(
        '[RecurringRulesController] pauseRule failed: ${e.runtimeType}',
      );
      return const PauseRecurringRuleOutcome.failed();
    }
  }

  Future<ResumeRecurringRuleOutcome> resumeRule(int id) async {
    final RecurringRulesRepository repo;
    try {
      repo = ref.read(recurringRulesRepositoryProvider);
      await repo.setActive(id, active: true);
    } catch (e) {
      debugPrint(
        '[RecurringRulesController] resumeRule failed: ${e.runtimeType}',
      );
      return const ResumeRecurringRuleOutcome.failed();
    }
    // The rule is resumed now, so a failed re-read only loses the date.
    try {
      final updated = await repo.getById(id);
      return ResumeRecurringRuleOutcome.ok(updated?.nextDueDate);
    } catch (e) {
      debugPrint(
        '[RecurringRulesController] resumeRule re-read failed: '
        '${e.runtimeType}',
      );
      return const ResumeRecurringRuleOutcome.ok(null);
    }
  }

  /// Hides the row and opens its undo window. A pending delete for another
  /// rule commits first; if that commit fails, this delete does not start
  /// and the result is [DeleteRecurringRuleNotStarted].
  ///
  /// Needs no catch-all: nothing here throws, because `_commitDelete`
  /// catches its own failures and reports them as `false`.
  Future<DeleteRecurringRuleOutcome> deleteRule(int id) async {
    if (_pendingDelete != null) {
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _pendingDelete!;
      final committed = await _commitDelete(prior.ruleId);
      // A screen that closed during the commit has disposed this
      // controller, and a timer started now would never be cancelled.
      if (!committed || !ref.mounted) {
        return const DeleteRecurringRuleOutcome.notStarted();
      }
    }

    _pendingDelete = RecurringRulesPendingDelete(ruleId: id);
    _composer?.notifyPendingDeleteChanged();

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _pendingDelete;
      if (pending == null) return;
      final committed = await _commitDelete(pending.ruleId);
      if (!committed) {
        _effectListener?.call(const RecurringRulesDeleteFailedEffect());
      }
    });
    return const DeleteRecurringRuleOutcome.pending();
  }

  /// Cancels the pending delete of rule [id]. A no-op when the pending
  /// delete is for another rule, so a stale Undo snackbar cannot cancel a
  /// newer delete.
  void undoDelete(int id) {
    if (_pendingDelete?.ruleId != id) return;
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
    } catch (_) {
      if (_pendingDelete?.ruleId == id) {
        _pendingDelete = null;
      }
      _composer?.notifyPendingDeleteChanged();
      return false;
    }
  }
}

// ---------- Internal stream composition ----------

class _Composer {
  _Composer({required this._repo, required this._pendingDeleteGetter}) {
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
    await _out.close();
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
