// PendingController unit tests.
//
// Mirrors the RecurringRulesController pattern: stream driven by a
// mocked repository, skip-undo via fake-async timers and Mocktail.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/pending_transaction.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/features/home/pending_controller.dart';
import 'package:ledgerly/features/home/pending_state.dart';

class _MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

PendingTransaction _pending({
  required int id,
  String memo = 'Netflix',
  int amount = 1599,
  int categoryId = 1,
  int accountId = 1,
}) => PendingTransaction(
  id: id,
  source: 'recurring',
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  date: DateTime(2026, 5, 8),
  fetchedAt: DateTime(2026, 5, 8),
  recurringRuleId: 1,
);

Transaction _tx({
  required int id,
  int amount = 1599,
  int categoryId = 1,
  int accountId = 1,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: categoryId,
  accountId: accountId,
  date: DateTime(2026, 5, 8),
  memo: 'Netflix',
  createdAt: DateTime(2026, 5, 8),
  updatedAt: DateTime(2026, 5, 8),
);

void main() {
  group('PendingController', () {
    late _MockPendingTransactionRepository repo;
    late StreamController<List<PendingTransaction>> pendingCtrl;

    setUp(() {
      repo = _MockPendingTransactionRepository();
      pendingCtrl = StreamController<List<PendingTransaction>>.broadcast();
      when(() => repo.watchAll()).thenAnswer((_) => pendingCtrl.stream);
      when(() => repo.approve(any())).thenAnswer((_) async => _tx(id: 1));
      when(() => repo.reject(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await pendingCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWithValue(repo),
        ],
      );
    }

    Future<PendingState> waitFor(
      ProviderContainer c,
      bool Function(PendingState) accept,
    ) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(pendingControllerProvider);
        if (s is AsyncData<PendingState> && accept(s.value)) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('PendingController never produced expected state');
    }

    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('PC01: loading → data when stream emits items', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      expect(
        container.read(pendingControllerProvider),
        isA<AsyncLoading<PendingState>>(),
      );

      await Future<void>.delayed(Duration.zero);
      pendingCtrl.add([_pending(id: 1)]);

      final state = await waitFor(container, (s) => s is PendingData);
      final data = state as PendingData;
      expect(data.items, hasLength(1));
      expect(data.skipScheduled, isNull);
    });

    test('PC02: loading → empty when stream emits empty list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      pendingCtrl.add(const []);

      final state = await waitFor(container, (s) => s is PendingEmpty);
      expect(state, isA<PendingEmpty>());
    });

    test('PC03: stream error becomes PendingError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      pendingCtrl.addError(StateError('boom'), StackTrace.current);

      final state = await waitFor(container, (s) => s is PendingError);
      expect((state as PendingError).error, isA<StateError>());
    });

    test(
      'PC04: approve calls repo.approve; no failure effect on success',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(pendingControllerProvider, (_, _) {});

        pendingCtrl.add([_pending(id: 1)]);
        await waitFor(container, (s) => s is PendingData);

        final notifier = container.read(pendingControllerProvider.notifier);
        final captured = <PendingEffect>[];
        notifier.setEffectListener(captured.add);

        await notifier.approve(1);
        await pump();

        verify(() => repo.approve(1)).called(1);
        expect(captured.whereType<PendingApproveFailedEffect>(), isEmpty);
        expect(
          captured.whereType<PendingApproveSucceededEffect>(),
          hasLength(1),
        );
      },
    );

    test('PC05: approve failure fires PendingApproveFailedEffect', () async {
      when(
        () => repo.approve(any()),
      ).thenThrow(const PendingTransactionRepositoryException('archived'));

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1)]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      PendingEffect? effectCaptured;
      notifier.setEffectListener((effect) => effectCaptured = effect);

      await notifier.approve(1);
      await pump();

      expect(effectCaptured, isA<PendingApproveFailedEffect>());
      final data = await waitFor(container, (s) => s is PendingData);
      expect((data as PendingData).items, hasLength(1));
    });

    test('PC06: skip hides row immediately and starts undo window', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1), _pending(id: 2, memo: 'Rent')]);
      await waitFor(container, (s) => s is PendingData);

      // ignore: unawaited_futures
      container.read(pendingControllerProvider.notifier).skip(1);

      final state = await waitFor(
        container,
        (s) =>
            s is PendingData && s.skipScheduled != null && s.items.length == 2,
      );
      expect((state as PendingData).skipScheduled?.pendingId, 1);
      verifyNever(() => repo.reject(any()));
    });

    test('PC07: undoSkip cancels timer; repo.reject never called', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1)]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      // ignore: unawaited_futures
      notifier.skip(1);
      await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled != null,
      );

      await notifier.undoSkip();
      await pump();

      final restored = await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled == null,
      );
      expect((restored as PendingData).items, hasLength(1));
      verifyNever(() => repo.reject(any()));
    });

    test('PC08: timer expiry calls repo.reject', () {
      fakeAsync((async) {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(pendingControllerProvider, (_, _) {});

        pendingCtrl.add([_pending(id: 1)]);
        async.flushMicrotasks();

        // ignore: unawaited_futures
        container.read(pendingControllerProvider.notifier).skip(1);
        async.flushMicrotasks();

        async.elapse(kUndoWindow + const Duration(seconds: 1));
        async.flushMicrotasks();

        verify(() => repo.reject(1)).called(1);
      });
    });

    test(
      'PC09: failed reject fires PendingSkipFailedEffect and restores row',
      () {
        fakeAsync((async) {
          when(() => repo.reject(any())).thenThrow(StateError('disk full'));

          final container = makeContainer();
          addTearDown(container.dispose);
          container.listen(pendingControllerProvider, (_, _) {});

          pendingCtrl.add([_pending(id: 1)]);
          async.flushMicrotasks();

          final notifier = container.read(pendingControllerProvider.notifier);
          final captured = <PendingEffect>[];
          notifier.setEffectListener(captured.add);

          // ignore: unawaited_futures
          notifier.skip(1);
          async.flushMicrotasks();

          var state = container.read(pendingControllerProvider).valueOrNull;
          expect(state, isA<PendingData>());
          expect((state as PendingData).skipScheduled?.pendingId, 1);

          async.elapse(kUndoWindow + const Duration(seconds: 1));
          async.flushMicrotasks();

          verify(() => repo.reject(1)).called(1);
          expect(captured.whereType<PendingSkipFailedEffect>(), hasLength(1));

          state = container.read(pendingControllerProvider).valueOrNull;
          expect(state, isA<PendingData>());
          expect(
            (state as PendingData).skipScheduled?.pendingId,
            1,
            reason: 'failed commit should restore skipScheduled',
          );
          expect(state.items.any((p) => p.id == 1), isTrue);
        });
      },
    );

    test('PC10: second skip during pending undo commits the prior', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(pendingControllerProvider, (_, _) {});

      pendingCtrl.add([_pending(id: 1), _pending(id: 2, memo: 'Rent')]);
      await waitFor(container, (s) => s is PendingData);

      final notifier = container.read(pendingControllerProvider.notifier);
      // ignore: unawaited_futures
      notifier.skip(1);
      await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled?.pendingId == 1,
      );

      // ignore: unawaited_futures
      notifier.skip(2);
      await pump();

      verify(() => repo.reject(1)).called(1);
      final state = await waitFor(
        container,
        (s) => s is PendingData && s.skipScheduled?.pendingId == 2,
      );
      expect(state, isA<PendingData>());
    });

    test(
      'PC11: dispose during pending skip does not throw on closed stream',
      () async {
        final container = makeContainer();
        container.listen(pendingControllerProvider, (_, _) {});

        pendingCtrl.add([_pending(id: 1)]);
        await waitFor(container, (s) => s is PendingData);

        final notifier = container.read(pendingControllerProvider.notifier);
        // ignore: unawaited_futures
        notifier.skip(1);

        container.dispose();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final fresh = makeContainer();
        addTearDown(fresh.dispose);
        fresh.listen(pendingControllerProvider, (_, _) {});
        expect(
          fresh.read(pendingControllerProvider),
          isA<AsyncLoading<PendingState>>(),
        );
      },
    );
  });
}
