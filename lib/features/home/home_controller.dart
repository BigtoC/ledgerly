// Home slice controller — Wave 3 §4.1, §6, §8.
//
// `HomeController` composes four streams into a single [HomeState]:
//   1. `transactionRepository.watchByDay(selectedDay)` — rows for the
//      selected calendar day.
//   2. `transactionRepository.watchDaysWithActivity()` — newest-first
//      list of days that have transactions; used only for first-run
//      detection (isEmpty → HomeEmpty).
//   3. `transactionRepository.watchDailyTotalsByType(selectedDay)` —
//      the selected day's expense/income split per currency for the
//      summary strip. Re-subscribes when selectedDay changes.
//   4. `transactionRepository.watchMonthNetByCurrency(selectedDay)` —
//      the selected day's month net per currency. Re-subscribes when
//      selectedDay changes.
//
// Navigation uses true calendar-day stepping (prev/next subtract/add
// 1 day), not activity-day jumping. The chevron state is determined
// by whether selectedDay is after 1900 (canGoPrev) and before today
// (canGoNext).
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

typedef HomeEffectListener = void Function(HomeEffect effect);

/// Length of the undo window. PRD: snackbar with `commonUndo` action;
/// 4 s matches the Material `SnackBar` default duration.
const Duration kUndoWindow = Duration(seconds: 4);

sealed class HomeEffect {
  const HomeEffect();
}

final class HomeDeleteFailedEffect extends HomeEffect {
  const HomeDeleteFailedEffect(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

@Riverpod(keepAlive: true, dependencies: [transactionRepository])
class HomeController extends _$HomeController {
  // Fields persist across rebuilds. They are reset on `ref.onDispose`.
  DateTime _selectedDay = DateHelpers.startOfDay(DateTime.now());
  DateTime _todayAnchor = DateHelpers.startOfDay(DateTime.now());
  PendingDelete? _pendingDelete;
  final Set<int> _committedDeleteIds = <int>{};
  Timer? _undoTimer;
  _Composer? _composer;
  HomeEffectListener? _effectListener;

  @override
  Stream<HomeState> build() {
    final repo = ref.watch(transactionRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      selectedDayGetter: () => _selectedDay,
      todayGetter: () => _todayAnchor,
      pendingDeleteGetter: () => _pendingDelete,
      committedDeleteIdsGetter: () => _committedDeleteIds,
    );
    _composer = composer;
    ref.onDispose(() {
      _undoTimer?.cancel();
      _undoTimer = null;
      _pendingDelete = null;
      _committedDeleteIds.clear();
      composer.dispose();
    });
    return composer.stream;
  }

  // ---------- Commands ----------

  /// Pin the selected day to today. Always succeeds, even when today has
  /// no activity (renders gap-day empty inside [HomeData]).
  Future<void> selectToday() async {
    _syncTodayAnchor();
    _selectedDay = DateHelpers.startOfDay(DateTime.now());
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// Pin the selected day to the supplied [day]. Used by the form save
  /// round-trip — Home pins to `savedTx.date` so the new row lands in
  /// view even if the user picked a date other than today.
  Future<void> pinDay(DateTime day) async {
    _syncTodayAnchor();
    _selectedDay = DateHelpers.startOfDay(day);
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// The earliest selectable day. Matches the Home date-picker floor.
  static final DateTime _minSelectableDay = DateTime(1900);

  /// Step back by one calendar day. No-op when already at [_minSelectableDay].
  Future<void> selectPrevDay() async {
    _syncTodayAnchor();
    if (_selectedDay.isAtSameMomentAs(_minSelectableDay)) return;
    if (_selectedDay.isBefore(_minSelectableDay)) return;
    _selectedDay = _selectedDay.subtract(const Duration(days: 1));
    _composer?.changeSelectedDay(_selectedDay);
  }

  /// Step forward by one calendar day. No-op when already at today.
  Future<void> selectNextDay() async {
    _syncTodayAnchor();
    if (DateHelpers.isSameDay(_selectedDay, _todayAnchor)) return;
    _selectedDay = _selectedDay.add(const Duration(days: 1));
    if (_selectedDay.isAfter(_todayAnchor)) _selectedDay = _todayAnchor;
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
      final committed = await _commitDelete(prior.transaction.id);
      if (!committed) return;
    }

    final tx = _composer?.transactionById(id);
    if (tx == null) return;

    final scheduledFor = DateTime.now().add(kUndoWindow);
    _pendingDelete = PendingDelete(transaction: tx, scheduledFor: scheduledFor);
    _composer?.setPendingDelete(_pendingDelete);

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
    _composer?.setPendingDelete(null);
  }

  void setEffectListener(HomeEffectListener? listener) {
    _effectListener = listener;
  }

  Future<bool> _commitDelete(int id) async {
    _committedDeleteIds.add(id);
    _composer?.setPendingDelete(_pendingDelete);
    try {
      await ref.read(transactionRepositoryProvider).delete(id);
      if (_pendingDelete?.transaction.id == id) {
        _pendingDelete = null;
        _composer?.setPendingDelete(null);
      }
      return true;
    } catch (error, stackTrace) {
      _committedDeleteIds.remove(id);
      if (_pendingDelete?.transaction.id == id) {
        _pendingDelete = null;
        _composer?.setPendingDelete(null);
      } else {
        _composer?.setPendingDelete(_pendingDelete);
      }
      _effectListener?.call(HomeDeleteFailedEffect(error, stackTrace));
      return false;
    }
  }

  // Re-anchors `today` if the wall clock has crossed midnight since the
  // last command. Called by every command path so the summary strip and
  // month-net stream re-subscribe with the correct day boundary. We do
  // not schedule a midnight Timer — a long-lived timer leaks past widget
  // disposal in tests, and on mobile a sleeping device would not fire it
  // reliably anyway. Idle-overnight rollover is corrected on next interaction.
  void _syncTodayAnchor() {
    final today = DateHelpers.startOfDay(DateTime.now());
    if (DateHelpers.isSameDay(today, _todayAnchor)) return;
    _todayAnchor = today;
    _composer?.changeToday(_todayAnchor);
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
    required DateTime Function() todayGetter,
    required PendingDelete? Function() pendingDeleteGetter,
    required Set<int> Function() committedDeleteIdsGetter,
  }) : _repo = repo,
       _selectedDayGetter = selectedDayGetter,
       _todayGetter = todayGetter,
       _pendingDeleteGetter = pendingDeleteGetter,
       _committedDeleteIdsGetter = committedDeleteIdsGetter {
    _out = StreamController<HomeState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final TransactionRepository _repo;
  final DateTime Function() _selectedDayGetter;
  final DateTime Function() _todayGetter;
  final PendingDelete? Function() _pendingDeleteGetter;
  final Set<int> Function() _committedDeleteIdsGetter;
  late final StreamController<HomeState> _out;

  StreamSubscription<List<Transaction>>? _daySub;
  StreamSubscription<List<DateTime>>? _activitySub;
  StreamSubscription<Map<String, ({int expense, int income})>>? _totalsSub;
  StreamSubscription<Map<String, int>>? _monthNetSub;
  DateTime? _subscribedDay;
  DateTime? _subscribedSummaryDay;

  // Latest values; null until first emit.
  List<Transaction>? _txForDay;
  List<DateTime>? _activityDays;
  Map<String, ({int expense, int income})>? _todayTotals;
  Map<String, int>? _monthNet;
  int _dayGeneration = 0;
  bool _emitScheduled = false;

  Stream<HomeState> get stream => _out.stream;

  void _start() {
    _out.add(const HomeState.loading());
    _subscribeDay(_selectedDayGetter());
    _activitySub = _repo.watchDaysWithActivity().listen((days) {
      _activityDays = days;
      _scheduleEmit();
    }, onError: _onError);
    _subscribeSummaryStreams(_todayGetter());
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
    final targetDay = DateHelpers.startOfDay(day);
    if (_subscribedDay != null &&
        DateHelpers.isSameDay(_subscribedDay!, targetDay)) {
      return;
    }
    _dayGeneration++;
    final generation = _dayGeneration;
    _subscribedDay = targetDay;
    _daySub?.cancel();
    _txForDay = null;
    _daySub = _repo.watchByDay(targetDay).listen((rows) {
      if (generation != _dayGeneration) return;
      final isStale = rows.any(
        (row) => !DateHelpers.isSameDay(row.date, targetDay),
      );
      if (isStale) return;
      final committedDeleteIds = _committedDeleteIdsGetter();
      if (committedDeleteIds.isNotEmpty) {
        final visibleIds = rows.map((row) => row.id).toSet();
        committedDeleteIds.removeWhere((id) => !visibleIds.contains(id));
      }
      _txForDay = rows;
      _scheduleEmit();
    }, onError: _onError);
  }

  void _subscribeSummaryStreams(DateTime today) {
    final targetDay = DateHelpers.startOfDay(today);
    if (_subscribedSummaryDay != null &&
        DateHelpers.isSameDay(_subscribedSummaryDay!, targetDay)) {
      return;
    }
    _subscribedSummaryDay = targetDay;
    _totalsSub?.cancel();
    _monthNetSub?.cancel();
    _todayTotals = null;
    _monthNet = null;
    _totalsSub = _repo.watchDailyTotalsByType(targetDay).listen((totals) {
      _todayTotals = totals;
      _scheduleEmit();
    }, onError: _onError);
    _monthNetSub = _repo.watchMonthNetByCurrency(targetDay).listen((net) {
      _monthNet = net;
      _scheduleEmit();
    }, onError: _onError);
  }

  void changeSelectedDay(DateTime day) {
    _subscribeDay(day);
    _subscribeSummaryStreams(day);
  }

  void changeToday(DateTime today) {
    _subscribeSummaryStreams(today);
  }

  void setPendingDelete(PendingDelete? pending) {
    _scheduleEmit();
  }

  Transaction? transactionById(int id) {
    final rows = _txForDay;
    if (rows == null) return null;
    for (final t in rows) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(HomeState.error(error, stack));
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
    if (_txForDay == null ||
        _activityDays == null ||
        _todayTotals == null ||
        _monthNet == null) {
      return;
    }

    final selectedDay = _selectedDayGetter();
    final today = _todayGetter();
    final activity = _activityDays!;
    final pending = _pendingDeleteGetter();
    final committedDeleteIds = _committedDeleteIdsGetter();

    // Empty CTA fires only when there is no transaction history at all.
    // Any non-empty activity list means at least one past-or-today
    // transaction exists → HomeData (even if transactionsForDay is empty
    // for the selected gap day).
    if (activity.isEmpty) {
      _out.add(HomeState.empty(selectedDay: selectedDay, pendingBadgeCount: 0));
      return;
    }

    // Calendar-based chevron flags (not activity-day based).
    final canGoPrev = selectedDay.isAfter(DateTime(1900));
    final canGoNext = selectedDay.isBefore(today);

    // Hide the pending row visually so the user sees it disappear during
    // the undo window. Re-appears on undo because pendingDelete clears.
    final hiddenIds = <int>{...committedDeleteIds};
    if (pending != null) hiddenIds.add(pending.transaction.id);

    final visible = hiddenIds.isEmpty
        ? _txForDay!
        : _txForDay!
              .where((t) => !hiddenIds.contains(t.id))
              .toList(growable: false);

    _out.add(
      HomeState.data(
        selectedDay: selectedDay,
        today: today,
        transactionsForDay: visible,
        todayTotalsByCurrency: _todayTotals!,
        monthNetByCurrency: _monthNet!,
        canGoPrev: canGoPrev,
        canGoNext: canGoNext,
        pendingBadgeCount: 0,
        pendingDelete: pending,
      ),
    );
  }
}
