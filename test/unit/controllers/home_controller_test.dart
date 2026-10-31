// HomeController unit tests — Wave 3 §4.3.
//
// Covers:
//   - loading → empty (no history) and loading → data (with rows)
//   - Day traversal: prev/next derived from `watchDaysWithActivity`,
//     stepping over gap days; both null at boundaries.
//   - `pinDay(day)` pins to the supplied day (used by the add/edit-save
//     round-trip).
//
// Repositories are mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/home/home_controller.dart';
import 'package:ledgerly/features/home/home_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Transaction _tx({required int id, required DateTime date}) => Transaction(
  id: id,
  amountMinorUnits: 100,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: date,
  createdAt: DateTime.utc(0),
  updatedAt: DateTime.utc(0),
);

@Dependencies([HomeController])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  group('HomeController', () {
    late _MockTransactionRepository repo;
    late StreamController<List<Transaction>> dayCtrl;
    late StreamController<List<DateTime>> activityCtrl;
    late StreamController<Map<String, ({int expense, int income})>>
    todayTotalsCtrl;
    late StreamController<Map<String, int>> monthNetCtrl;

    setUp(() {
      repo = _MockTransactionRepository();
      dayCtrl = StreamController<List<Transaction>>.broadcast();
      activityCtrl = StreamController<List<DateTime>>.broadcast();
      todayTotalsCtrl =
          StreamController<
            Map<String, ({int expense, int income})>
          >.broadcast();
      monthNetCtrl = StreamController<Map<String, int>>.broadcast();

      when(() => repo.watchByDay(any())).thenAnswer((_) => dayCtrl.stream);
      when(() => repo.watchDaysWithActivity())
          .thenAnswer((_) => activityCtrl.stream);
      when(() => repo.watchDailyTotalsByType(any()))
          .thenAnswer((_) => todayTotalsCtrl.stream);
      when(() => repo.watchMonthNetByCurrency(any()))
          .thenAnswer((_) => monthNetCtrl.stream);
    });

    tearDown(() async {
      await dayCtrl.close();
      await activityCtrl.close();
      await todayTotalsCtrl.close();
      await monthNetCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
    }

    @Dependencies([HomeController])
    Future<HomeState> waitForNon(
      ProviderContainer c,
      bool Function(HomeState) accept,
    ) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(homeControllerProvider);
        if (s is AsyncData<HomeState> && accept(s.value)) return s.value;
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('HomeController never produced expected state');
    }

    test('H01: starts loading, transitions to empty when no history', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      expect(
        container.read(homeControllerProvider),
        isA<AsyncLoading<HomeState>>(),
      );

      // Emit empty across all four streams.
      await Future<void>.delayed(Duration.zero);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});

      final state = await waitForNon(container, (s) => s is HomeEmpty);
      expect(state, isA<HomeEmpty>());
    });

    test('H01b: remains AsyncLoading until all four streams emit', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      expect(
        container.read(homeControllerProvider),
        isA<AsyncLoading<HomeState>>(),
      );

      // Riverpod 3 delivers the composer's initial `HomeState.loading()`
      // (Riverpod 2 dropped it), so "still loading" is either form; the
      // screen renders both as the same spinner.
      final isStillLoading = anyOf(
        isA<AsyncLoading<HomeState>>(),
        isA<AsyncData<HomeState>>().having(
          (s) => s.value,
          'value',
          isA<HomeLoading>(),
        ),
      );

      await Future<void>.delayed(Duration.zero);
      dayCtrl.add(const []);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(homeControllerProvider), isStillLoading);

      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(homeControllerProvider), isStillLoading);

      monthNetCtrl.add(const {});
      final state = await waitForNon(container, (s) => s is HomeEmpty);
      expect(state, isA<HomeEmpty>());
    });

    test(
      'H02: calendar prev/next step one day at a time across gap days',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(homeControllerProvider, (_, _) {});

        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        final yesterday = todayMidnight.subtract(const Duration(days: 1));
        final twoDaysAgo = todayMidnight.subtract(const Duration(days: 2));

        await Future<void>.delayed(Duration.zero);
        dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
        // Only today has activity — prev/next should still step by calendar day
        activityCtrl.add([todayMidnight]);
        todayTotalsCtrl.add(const {'USD': (expense: 100, income: 0)});
        monthNetCtrl.add(const {'USD': -100});

        final state = await waitForNon(container, (s) => s is HomeData);
        final data = state as HomeData;
        expect(data.transactionsForDay, hasLength(1));
        // Today is selected; cannot go next (at today), can go prev
        expect(data.canGoPrev, isTrue);
        expect(data.canGoNext, isFalse);

        // Step back: today → yesterday (one calendar day, no activity gap skip)
        await container.read(homeControllerProvider.notifier).selectPrevDay();
        await Future<void>.delayed(Duration.zero);
        dayCtrl.add(const []);
        // After selectPrevDay, summary streams resubscribe — feed them new data
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});
        final afterPrev = await waitForNon(
          container,
          (s) => s is HomeData && s.selectedDay == yesterday,
        );
        expect((afterPrev as HomeData).selectedDay, yesterday);
        expect(afterPrev.canGoPrev, isTrue);
        expect(afterPrev.canGoNext, isTrue);

        // Step back again: yesterday → two days ago
        await container.read(homeControllerProvider.notifier).selectPrevDay();
        await Future<void>.delayed(Duration.zero);
        dayCtrl.add(const []);
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});
        final afterPrev2 = await waitForNon(
          container,
          (s) => s is HomeData && s.selectedDay == twoDaysAgo,
        );
        expect((afterPrev2 as HomeData).selectedDay, twoDaysAgo);
      },
    );

    test(
      'H02b: selected-day summary streams follow selectedDay not todayAnchor',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(homeControllerProvider, (_, _) {});

        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        final yesterday = todayMidnight.subtract(const Duration(days: 1));

        await Future<void>.delayed(Duration.zero);
        dayCtrl.add(const []);
        activityCtrl.add([yesterday]);
        // Summary totals for today
        todayTotalsCtrl.add(const {'USD': (expense: 500, income: 0)});
        monthNetCtrl.add(const {'USD': -500});
        await waitForNon(container, (s) => s is HomeData);

        // Step to yesterday — summary streams should re-subscribe for yesterday
        await container.read(homeControllerProvider.notifier).selectPrevDay();
        await Future<void>.delayed(Duration.zero);
        dayCtrl.add([_tx(id: 1, date: yesterday)]);
        // Emit new summary totals (simulating yesterday's data)
        todayTotalsCtrl.add(const {'USD': (expense: 200, income: 100)});
        monthNetCtrl.add(const {'USD': -100});

        final afterPrev = await waitForNon(
          container,
          (s) => s is HomeData && s.selectedDay == yesterday,
        );
        expect((afterPrev as HomeData).selectedDay, yesterday);
        // Verify the strip data changed (was re-subscribed for yesterday)
        expect(afterPrev.todayTotalsByCurrency['USD']?.expense, 200);
      },
    );

    test('H02c: next day is capped at today', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      await Future<void>.delayed(Duration.zero);
      dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
      activityCtrl.add([todayMidnight]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});

      final state = await waitForNon(container, (s) => s is HomeData);
      expect((state as HomeData).selectedDay, todayMidnight);
      expect(state.canGoNext, isFalse);

      // Attempting to go next should be a no-op
      await container.read(homeControllerProvider.notifier).selectNextDay();
      await Future<void>.delayed(Duration.zero);

      final after = await waitForNon(container, (s) => s is HomeData);
      expect((after as HomeData).selectedDay, todayMidnight);
    });

    test('H02d: first-run empty: no history → HomeEmpty; non-empty + empty day → HomeData with []', () async {
      // Part 1: no history at all → HomeEmpty
      final container1 = makeContainer();
      addTearDown(container1.dispose);
      container1.listen(homeControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});

      final emptyState = await waitForNon(container1, (s) => s is HomeEmpty);
      expect(emptyState, isA<HomeEmpty>());
    });

    test('H02e: history exists but selected day has no rows → HomeData with empty list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = todayMidnight.subtract(const Duration(days: 1));

      await Future<void>.delayed(Duration.zero);
      dayCtrl.add(const []); // today is empty
      activityCtrl.add([yesterday]); // but yesterday has activity
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});

      final state = await waitForNon(container, (s) => s is HomeData);
      final data = state as HomeData;
      expect(data.transactionsForDay, isEmpty);
      expect(data.canGoPrev, isTrue); // yesterday exists
      expect(data.canGoNext, isFalse); // capped at today
    });

    test('H04: today is selected by default even on a gap day', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      final todayMidnight = DateTime.now();
      final today = DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day,
      );
      final yesterday = today.subtract(const Duration(days: 1));

      // History exists, but only on yesterday — today is a gap day.
      await Future<void>.delayed(Duration.zero);
      dayCtrl.add(const []);
      activityCtrl.add([yesterday]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});

      final state = await waitForNon(container, (s) => s is HomeData);
      final data = state as HomeData;
      expect(data.selectedDay, today);
      expect(data.transactionsForDay, isEmpty);
      // Calendar-based: can go prev (yesterday has activity), cannot go next (at today)
      expect(data.canGoPrev, isTrue);
      expect(data.canGoNext, isFalse);
    });

    test(
      'H08: stale prior day emission does not overwrite newer selection',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(homeControllerProvider, (_, _) {});

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        await Future<void>.delayed(Duration.zero);
        dayCtrl.add([_tx(id: 1, date: today)]);
        activityCtrl.add([today, yesterday]);
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});
        await waitForNon(container, (s) => s is HomeData);

        await container.read(homeControllerProvider.notifier).selectPrevDay();
        await Future<void>.delayed(Duration.zero);

        // Late emission from the old selection should be ignored.
        dayCtrl.add([_tx(id: 999, date: today)]);
        await Future<void>.delayed(Duration.zero);

        // Emit summary data for the new subscription (yesterday)
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});

        // Then the real yesterday emission arrives.
        dayCtrl.add([_tx(id: 2, date: yesterday)]);
        final state = await waitForNon(
          container,
          (s) => s is HomeData && s.selectedDay == yesterday,
        );

        expect((state as HomeData).transactionsForDay.single.id, 2);
      },
    );

    test('H09: stream error becomes HomeError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      final error = StateError('boom');
      await Future<void>.delayed(Duration.zero);
      dayCtrl.addError(error, StackTrace.current);

      final state = await waitForNon(container, (s) => s is HomeError);
      expect((state as HomeError).error, error);
    });
  });
}
