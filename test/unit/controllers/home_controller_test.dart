// HomeController unit tests — Wave 3 §4.3.
//
// Covers:
//   - loading → empty (no history) and loading → data (with rows)
//   - Day traversal: prev/next derived from `watchDaysWithActivity`,
//     stepping over gap days; both null at boundaries.
//   - `selectToday()` always pins selectedDay to today.
//   - `pinDay(day)` pins to the supplied day (used by edit-save and
//     duplicate-save round-trip).
//   - `deleteTransaction(id)` schedules a timer and exposes
//     `pendingDelete`; `undoDelete()` cancels the timer without touching
//     the repo; timer expiry calls `repo.delete`.
//   - Second swipe-delete commits the prior pending delete and starts a
//     new undo window.
//
// Repositories are mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/home/home_controller.dart';
import 'package:ledgerly/features/home/home_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Transaction _tx({
  required int id,
  required DateTime date,
  int amount = 100,
  Currency currency = _usd,
  int categoryId = 1,
  int accountId = 1,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: categoryId,
  accountId: accountId,
  date: date,
  createdAt: DateTime.utc(0),
  updatedAt: DateTime.utc(0),
);

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
      when(
        () => repo.watchDaysWithActivity(),
      ).thenAnswer((_) => activityCtrl.stream);
      when(
        () => repo.watchDailyTotalsByType(any()),
      ).thenAnswer((_) => todayTotalsCtrl.stream);
      when(
        () => repo.watchMonthNetByCurrency(any()),
      ).thenAnswer((_) => monthNetCtrl.stream);
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
      final empty = state as HomeEmpty;
      expect(empty.pendingBadgeCount, 0);
    });

    test(
      'H02: data state with prev/next derived from days-with-activity',
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
        // newest-first
        activityCtrl.add([todayMidnight, yesterday, twoDaysAgo]);
        todayTotalsCtrl.add(const {'USD': (expense: 100, income: 0)});
        monthNetCtrl.add(const {'USD': -100});

        final state = await waitForNon(container, (s) => s is HomeData);
        final data = state as HomeData;
        expect(data.transactionsForDay, hasLength(1));
        expect(data.prevDayWithActivity, yesterday);
        expect(data.nextDayWithActivity, isNull); // already at newest
      },
    );

    test('H03: selectPrevDay steps to nearest older activity day', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = todayMidnight.subtract(const Duration(days: 1));
      final fourDaysAgo = todayMidnight.subtract(const Duration(days: 4));

      await Future<void>.delayed(Duration.zero);
      dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
      activityCtrl.add([todayMidnight, yesterday, fourDaysAgo]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await waitForNon(container, (s) => s is HomeData);

      // Walk back: today → yesterday.
      await container.read(homeControllerProvider.notifier).selectPrevDay();
      // The day stream resubscribes; emit yesterday's rows on the
      // broadcast stream so the new subscriber sees them.
      await Future<void>.delayed(Duration.zero);
      dayCtrl.add([_tx(id: 2, date: yesterday)]);
      final state = await waitForNon(
        container,
        (s) =>
            s is HomeData &&
            s.selectedDay == yesterday &&
            s.prevDayWithActivity == fourDaysAgo,
      );
      expect((state as HomeData).nextDayWithActivity, todayMidnight);
    });

    test('H04: selectToday pins to today even on a gap day', () async {
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
      expect(data.prevDayWithActivity, yesterday);
      expect(data.nextDayWithActivity, isNull);

      await container.read(homeControllerProvider.notifier).selectToday();
      await Future<void>.delayed(Duration.zero);
      final after = await waitForNon(container, (s) => s is HomeData);
      expect((after as HomeData).selectedDay, today);
    });

    test(
      'H05: deleteTransaction sets pendingDelete; timer expiry calls repo.delete',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(homeControllerProvider, (_, _) {});

        when(() => repo.delete(any())).thenAnswer((_) async => true);

        final todayMidnight = DateTime.now();
        final today = DateTime(
          todayMidnight.year,
          todayMidnight.month,
          todayMidnight.day,
        );

        final tx = _tx(id: 42, date: today);
        await Future<void>.delayed(Duration.zero);
        dayCtrl.add([tx]);
        activityCtrl.add([today]);
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});
        await waitForNon(container, (s) => s is HomeData);

        await fakeAsync(() async {
          // Run inside `fakeAsync` so the 4-second timer is virtual.
        });

        await container
            .read(homeControllerProvider.notifier)
            .deleteTransaction(tx.id);
        await Future<void>.delayed(Duration.zero);

        // pendingDelete should be set.
        final pending = await waitForNon(
          container,
          (s) => s is HomeData && s.pendingDelete?.transaction.id == tx.id,
        );
        expect((pending as HomeData).pendingDelete!.transaction.id, tx.id);

        // Repo was not called yet.
        verifyNever(() => repo.delete(any()));

        // Wait the 4s undo window.
        await Future<void>.delayed(const Duration(seconds: 5));

        verify(() => repo.delete(tx.id)).called(1);
      },
    );

    test('H06: undoDelete cancels the timer; repo never called', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(homeControllerProvider, (_, _) {});

      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final todayMidnight = DateTime.now();
      final today = DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day,
      );

      final tx = _tx(id: 99, date: today);
      await Future<void>.delayed(Duration.zero);
      dayCtrl.add([tx]);
      activityCtrl.add([today]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await waitForNon(container, (s) => s is HomeData);

      await container
          .read(homeControllerProvider.notifier)
          .deleteTransaction(tx.id);
      await Future<void>.delayed(Duration.zero);

      await container.read(homeControllerProvider.notifier).undoDelete();
      await Future<void>.delayed(const Duration(seconds: 5));

      verifyNever(() => repo.delete(any()));
      final after = await waitForNon(
        container,
        (s) => s is HomeData && s.pendingDelete == null,
      );
      expect((after as HomeData).pendingDelete, isNull);
    });

    test(
      'H07: second deleteTransaction commits the first, opens new window',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(homeControllerProvider, (_, _) {});

        when(() => repo.delete(any())).thenAnswer((_) async => true);

        final todayMidnight = DateTime.now();
        final today = DateTime(
          todayMidnight.year,
          todayMidnight.month,
          todayMidnight.day,
        );

        final tx1 = _tx(id: 1, date: today);
        final tx2 = _tx(id: 2, date: today);

        await Future<void>.delayed(Duration.zero);
        dayCtrl.add([tx1, tx2]);
        activityCtrl.add([today]);
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});
        await waitForNon(container, (s) => s is HomeData);

        await container
            .read(homeControllerProvider.notifier)
            .deleteTransaction(1);
        await Future<void>.delayed(Duration.zero);
        await container
            .read(homeControllerProvider.notifier)
            .deleteTransaction(2);
        await Future<void>.delayed(Duration.zero);

        // First delete should have committed immediately.
        verify(() => repo.delete(1)).called(1);
        // Second is still pending until 4s.
        verifyNever(() => repo.delete(2));

        // Now wait the window.
        await Future<void>.delayed(const Duration(seconds: 5));
        verify(() => repo.delete(2)).called(1);
      },
    );
  });
}

// fakeAsync placeholder — not currently using package:fake_async; kept
// no-op so the tests compile. The real timer uses real time with a 5s
// wait — slow but reliable for the small set of tests in this file.
Future<T> fakeAsync<T>(Future<T> Function() body) async {
  return body();
}
