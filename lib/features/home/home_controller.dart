// Home slice controller — Wave 3 §4.1, §6, §8.
//
// `HomeController` composes four streams into a single [HomeState]:
//   1. `transactionRepository.watchByDay(selectedDay)` — rows for the
//      selected calendar day.
//   2. `transactionRepository.watchDaysWithActivity()` — newest-first
//      list of days that have transactions; used to derive `prev` /
//      `next` chevron targets.
//   3. `transactionRepository.watchDailyTotalsByType(today)` — today's
//      expense/income split per currency for the summary strip.
//   4. `transactionRepository.watchMonthNetByCurrency(today)` — current
//      month's signed net per currency.
//
// `keepAlive: true` because the delete-undo timer must survive trivial
// rebuilds and off-screen navigation during the 4-second window
// (Wave 3 §8 / §16 risk #3).
//
// Per-row balance / per-account streams are NOT used here — Home only
// reads transactions. Account/category metadata for the row tile is
// resolved by the widget against `accountRepositoryProvider` /
// `categoryRepositoryProvider` (Wave 3 §2 input table) using
// archived-safe `watchAll(includeArchived: true)`.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

/// Length of the undo window. PRD: snackbar with `commonUndo` action;
/// 4 s matches the Material `SnackBar` default duration.
const Duration kUndoWindow = Duration(seconds: 4);

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  // Fields persist across rebuilds. They are reset on `ref.onDispose`.
  DateTime _selectedDay = DateHelpers.startOfDay(DateTime.now());
  PendingDelete? _pendingDelete;
  Timer? _undoTimer;
  _Composer? _composer;

  @override
  Stream<HomeState> build() {
    final repo = ref.watch(transactionRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      selectedDayGetter: () => _selectedDay,
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

  /// Pin the selected day to today. Always succeeds, even when today has
  /// no activity (renders gap-day empty inside [HomeData]).
  Future<void> selectToday() async {
    _selectedDay = DateHelpers.startOfDay(DateTime.now());
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// Pin the selected day to the supplied [day]. Used by the form save
  /// round-trip — Home pins to `savedTx.date` so the new row lands in
  /// view even if the user picked a date other than today.
  Future<void> pinDay(DateTime day) async {
    _selectedDay = DateHelpers.startOfDay(day);
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// Step to the nearest older day with activity. No-op when at oldest.
  Future<void> selectPrevDay() async {
    final prev = _composer?.prevDayWithActivity();
    if (prev == null) return;
    _selectedDay = prev;
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// Step to the nearest newer day with activity. No-op when at newest.
  Future<void> selectNextDay() async {
    final next = _composer?.nextDayWithActivity();
    if (next == null) return;
    _selectedDay = next;
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// Visually delete a transaction and start the 4-second undo window.
  /// Calls `repo.delete` only when the timer expires. A second call
  /// while a delete is already pending commits the prior one immediately
  /// (Wave 3 §8 / §16 risk #4) and starts a fresh timer for the new id.
  Future<void> deleteTransaction(int id) async {
    if (_pendingDelete != null) {
      // Commit prior pending delete now.
      _undoTimer?.cancel();
      _undoTimer = null;
      final prior = _pendingDelete!;
      _pendingDelete = null;
      _composer?.setPendingDelete(null);
      await ref
          .read(transactionRepositoryProvider)
          .delete(prior.transaction.id);
    }

    final tx = _composer?.transactionById(id);
    if (tx == null) return;

    final scheduledFor = DateTime.now().add(kUndoWindow);
    _pendingDelete = PendingDelete(transaction: tx, scheduledFor: scheduledFor);
    _composer?.setPendingDelete(_pendingDelete);

    _undoTimer = Timer(kUndoWindow, () async {
      final pending = _pendingDelete;
      if (pending == null) return;
      _pendingDelete = null;
      _composer?.setPendingDelete(null);
      await ref
          .read(transactionRepositoryProvider)
          .delete(pending.transaction.id);
    });
  }

  /// Cancel the undo window; the original row reappears on the next
  /// emission. Repository is never touched.
  Future<void> undoDelete() async {
    _undoTimer?.cancel();
    _undoTimer = null;
    _pendingDelete = null;
    _composer?.setPendingDelete(null);
  }
}

// ---------- Internal stream composition ----------

/// Owns the four upstream subscriptions and merges them into a single
/// [HomeState] broadcast stream. Plain class so `ref.onDispose` can
/// cancel everything deterministically.
class _Composer {
  _Composer({
    required TransactionRepository repo,
    required DateTime Function() selectedDayGetter,
    required PendingDelete? Function() pendingDeleteGetter,
  }) : _repo = repo,
       _selectedDayGetter = selectedDayGetter,
       _pendingDeleteGetter = pendingDeleteGetter {
    _out = StreamController<HomeState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final TransactionRepository _repo;
  final DateTime Function() _selectedDayGetter;
  final PendingDelete? Function() _pendingDeleteGetter;
  late final StreamController<HomeState> _out;

  StreamSubscription<List<Transaction>>? _daySub;
  StreamSubscription<List<DateTime>>? _activitySub;
  StreamSubscription<Map<String, ({int expense, int income})>>? _totalsSub;
  StreamSubscription<Map<String, int>>? _monthNetSub;

  // Latest values; null until first emit.
  List<Transaction>? _txForDay;
  List<DateTime>? _activityDays;
  Map<String, ({int expense, int income})>? _todayTotals;
  Map<String, int>? _monthNet;

  // Cache of "today" pinned at composer creation. Today shifts only
  // across midnight; the controller does not auto-pin past midnight in
  // MVP — restart the app or interact with the day-nav to pull a fresh
  // today reading.
  late final DateTime _today = DateHelpers.startOfDay(DateTime.now());

  Stream<HomeState> get stream => _out.stream;

  void _start() {
    _subscribeDay(_selectedDayGetter());
    _activitySub = _repo.watchDaysWithActivity().listen((days) {
      _activityDays = days;
      _emitIfReady();
    }, onError: _onError);
    _totalsSub = _repo.watchDailyTotalsByType(_today).listen((totals) {
      _todayTotals = totals;
      _emitIfReady();
    }, onError: _onError);
    _monthNetSub = _repo.watchMonthNetByCurrency(_today).listen((net) {
      _monthNet = net;
      _emitIfReady();
    }, onError: _onError);
  }

  Future<void> _stop() async {
    await _daySub?.cancel();
    _daySub = null;
    await _activitySub?.cancel();
    _activitySub = null;
    await _totalsSub?.cancel();
    _totalsSub = null;
    await _monthNetSub?.cancel();
    _monthNetSub = null;
  }

  Future<void> dispose() async {
    await _stop();
    if (!_out.isClosed) await _out.close();
  }

  void _subscribeDay(DateTime day) {
    _daySub?.cancel();
    _txForDay = null;
    _daySub = _repo.watchByDay(day).listen((rows) {
      _txForDay = rows;
      _emitIfReady();
    }, onError: _onError);
  }

  void changeSelectedDay(DateTime day) {
    _subscribeDay(day);
  }

  void setPendingDelete(PendingDelete? pending) {
    _emitIfReady();
  }

  Transaction? transactionById(int id) {
    final rows = _txForDay;
    if (rows == null) return null;
    for (final t in rows) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Newest-first activity list lookup: largest date strictly older than
  /// the selected day.
  DateTime? prevDayWithActivity() {
    final days = _activityDays;
    if (days == null) return null;
    final sel = _selectedDayGetter();
    for (final d in days) {
      if (d.isBefore(sel)) return d;
    }
    return null;
  }

  /// Smallest date strictly newer than the selected day.
  DateTime? nextDayWithActivity() {
    final days = _activityDays;
    if (days == null) return null;
    final sel = _selectedDayGetter();
    DateTime? best;
    for (final d in days) {
      if (d.isAfter(sel)) {
        if (best == null || d.isBefore(best)) best = d;
      }
    }
    return best;
  }

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(HomeState.error(error, stack));
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    if (_txForDay == null ||
        _activityDays == null ||
        _todayTotals == null ||
        _monthNet == null) {
      return;
    }

    final selectedDay = _selectedDayGetter();
    final activity = _activityDays!;
    final pending = _pendingDeleteGetter();

    // Empty CTA fires only when there is no history at all AND today
    // has nothing pinned (selectedDay == today). Per Wave 3 §6, a
    // pinned future / past gap-day with no history at all still emits
    // empty (the chevrons are disabled — no other signal to differentiate).
    if (activity.isEmpty) {
      _out.add(HomeState.empty(selectedDay: selectedDay, pendingBadgeCount: 0));
      return;
    }

    // Hide the pending row visually so the user sees it disappear during
    // the undo window. Re-appears on undo because pendingDelete clears.
    final visible = pending == null
        ? _txForDay!
        : _txForDay!
              .where((t) => t.id != pending.transaction.id)
              .toList(growable: false);

    _out.add(
      HomeState.data(
        selectedDay: selectedDay,
        transactionsForDay: visible,
        todayTotalsByCurrency: _todayTotals!,
        monthNetByCurrency: _monthNet!,
        prevDayWithActivity: prevDayWithActivity(),
        nextDayWithActivity: nextDayWithActivity(),
        pendingBadgeCount: 0,
        pendingDelete: pending,
      ),
    );
  }
}
