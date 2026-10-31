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
// Per-row balance / per-account streams are NOT used here — Home only
// reads transactions. Category metadata for the row tile is resolved by
// the widget against `categoryRepositoryProvider` (Wave 3 §2 input
// table) using archived-safe `watchAll(includeArchived: true)`.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

@Riverpod(dependencies: [transactionRepository])
class HomeController extends _$HomeController {
  // Fields persist across rebuilds. They are reset on `ref.onDispose`.
  DateTime _selectedDay = DateHelpers.startOfDay(DateTime.now());
  DateTime _todayAnchor = DateHelpers.startOfDay(DateTime.now());
  _Composer? _composer;

  @override
  Stream<HomeState> build() {
    final repo = ref.watch(transactionRepositoryProvider);
    final composer = _Composer(
      repo: repo,
      selectedDayGetter: () => _selectedDay,
      todayGetter: () => _todayAnchor,
    );
    _composer = composer;
    ref.onDispose(composer.dispose);
    return composer.stream;
  }

  // ---------- Commands ----------

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
    if (!_selectedDay.isAfter(_minSelectableDay)) return;
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
    required this._repo,
    required this._selectedDayGetter,
    required this._todayGetter,
  }) {
    _out = StreamController<HomeState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final TransactionRepository _repo;
  final DateTime Function() _selectedDayGetter;
  final DateTime Function() _todayGetter;
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
    await _out.close();
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

    // Empty CTA fires only when there is no transaction history at all.
    // Any non-empty activity list means at least one past-or-today
    // transaction exists → HomeData (even if transactionsForDay is empty
    // for the selected gap day).
    if (activity.isEmpty) {
      _out.add(HomeState.empty(selectedDay: selectedDay));
      return;
    }

    // Calendar-based chevron flags (not activity-day based).
    final canGoPrev = selectedDay.isAfter(DateTime(1900));
    final canGoNext = selectedDay.isBefore(today);

    _out.add(
      HomeState.data(
        selectedDay: selectedDay,
        today: today,
        transactionsForDay: _txForDay!,
        todayTotalsByCurrency: _todayTotals!,
        monthNetByCurrency: _monthNet!,
        canGoPrev: canGoPrev,
        canGoNext: canGoNext,
      ),
    );
  }
}
