import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/search/category_search_detail_controller.dart';
import 'package:ledgerly/features/analysis/search/category_search_detail_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);
const _jpy = Currency(
  code: 'JPY',
  decimals: 0,
  symbol: '¥',
  nameL10nKey: 'currency.jpy',
);

Transaction _tx({
  required int id,
  required DateTime date,
  required int categoryId,
  Currency currency = _usd,
  int amount = 1000,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: categoryId,
  accountId: 1,
  date: date,
  memo: 'coffee',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('CategorySearchDetailController', () {
    late _MockTransactionRepository repo;

    setUp(() {
      repo = _MockTransactionRepository();
    });

    test('empty query emits DetailEmpty without subscribing', () async {
      when(
        () => repo.watchByMemo(any()),
      ).thenAnswer((_) => const Stream.empty());

      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        categorySearchDetailControllerProvider(
          categoryId: 1,
          query: '   ',
          currencyCode: 'USD',
        ).future,
      );
      expect(state, isA<DetailEmpty>());
      verifyNever(() => repo.watchByMemo(any()));
    });

    test('filters by categoryId AND currency.code', () async {
      when(() => repo.watchByMemo('coffee')).thenAnswer(
        (_) => Stream.value([
          _tx(
            id: 1,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 1,
            currency: _usd,
          ),
          _tx(
            id: 2,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 1,
            currency: _jpy,
          ),
          _tx(
            id: 3,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 2,
            currency: _usd,
          ),
        ]),
      );

      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        ).future,
      );
      final data = state as DetailData;
      expect(data.days, hasLength(1));
      expect(data.days.first.transactions.map((t) => t.id), [1]);
      expect(data.currency.code, 'USD');
    });

    test('groups by local-midnight day and sums', () async {
      when(() => repo.watchByMemo('coffee')).thenAnswer(
        (_) => Stream.value([
          _tx(
            id: 1,
            date: DateTime.utc(2026, 5, 1, 23, 59),
            categoryId: 1,
            amount: 100,
          ),
          _tx(
            id: 2,
            date: DateTime.utc(2026, 5, 2, 0, 1),
            categoryId: 1,
            amount: 200,
          ),
          _tx(
            id: 3,
            date: DateTime.utc(2026, 5, 2, 12, 0),
            categoryId: 1,
            amount: 300,
          ),
        ]),
      );

      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        ).future,
      );
      final data = state as DetailData;
      expect(data.days.map((d) => d.daySumMinorUnits).toList(), [500, 100]);
      expect(data.overallSumMinorUnits, 600);
    });
  });

  group('CategorySearchDetailController.deleteTransaction', () {
    late _MockTransactionRepository repo;
    late StreamController<List<Transaction>> txCtrl;

    setUp(() {
      repo = _MockTransactionRepository();
      txCtrl = StreamController<List<Transaction>>.broadcast();
      when(() => repo.watchByMemo('coffee')).thenAnswer((_) => txCtrl.stream);
    });

    tearDown(() async {
      await txCtrl.close();
    });

    ProviderContainer makeContainer() => ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
    );

    Future<DetailData> waitForData(ProviderContainer c) async {
      final provider = categorySearchDetailControllerProvider(
        categoryId: 1,
        query: 'coffee',
        currencyCode: 'USD',
      );
      for (var i = 0; i < 200; i++) {
        final s = c.read(provider);
        if (s is AsyncData<CategorySearchDetailState> &&
            s.value is DetailData) {
          return s.value as DetailData;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('controller never produced DetailData');
    }

    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test(
      'optimistic hide: row drops out immediately and repo.delete is not called yet',
      () async {
        when(() => repo.delete(any())).thenAnswer((_) async => true);

        final container = makeContainer();
        addTearDown(container.dispose);
        final provider = categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        );
        container.listen(provider, (_, _) {});

        await Future<void>.delayed(Duration.zero);
        txCtrl.add([
          _tx(
            id: 1,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 1,
            amount: 100,
          ),
          _tx(
            id: 2,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 1,
            amount: 200,
          ),
        ]);
        final before = await waitForData(container);
        expect(
          before.days.first.transactions.map((t) => t.id),
          containsAll(<int>[1, 2]),
        );
        expect(before.overallSumMinorUnits, 300);
        expect(before.pendingDelete, isNull);

        fakeAsync((async) {
          container.read(provider.notifier).deleteTransaction(1);
          async.flushMicrotasks();

          final hiding = container.read(provider).requireValue as DetailData;
          expect(hiding.pendingDelete?.transaction.id, 1);
          expect(hiding.days.first.transactions.map((t) => t.id), [2]);
          // Sum excludes the pending row so the header stays consistent.
          expect(hiding.overallSumMinorUnits, 200);
          verifyNever(() => repo.delete(any()));
        });
      },
    );

    test('undoDelete cancels timer and repo.delete is never called', () async {
      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);
      final provider = categorySearchDetailControllerProvider(
        categoryId: 1,
        query: 'coffee',
        currencyCode: 'USD',
      );
      container.listen(provider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      txCtrl.add([
        _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1, amount: 100),
      ]);
      await waitForData(container);

      fakeAsync((async) {
        container.read(provider.notifier).deleteTransaction(1);
        async.flushMicrotasks();
        container.read(provider.notifier).undoDelete();
        async.flushMicrotasks();
        async.elapse(kUndoWindow + const Duration(milliseconds: 1));
        async.flushMicrotasks();

        final after = container.read(provider).requireValue as DetailData;
        expect(after.pendingDelete, isNull);
        expect(after.days.first.transactions.map((t) => t.id), [1]);
        expect(after.overallSumMinorUnits, 100);
      });

      verifyNever(() => repo.delete(any()));
    });

    test('timer expiry calls repo.delete exactly once', () async {
      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);
      final provider = categorySearchDetailControllerProvider(
        categoryId: 1,
        query: 'coffee',
        currencyCode: 'USD',
      );
      container.listen(provider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      txCtrl.add([_tx(id: 7, date: DateTime.utc(2026, 5, 1), categoryId: 1)]);
      await waitForData(container);

      fakeAsync((async) {
        container.read(provider.notifier).deleteTransaction(7);
        async.flushMicrotasks();
        async.elapse(kUndoWindow + const Duration(milliseconds: 1));
        async.flushMicrotasks();
      });

      await pump();
      verify(() => repo.delete(7)).called(1);
    });

    test(
      'commit failure surfaces CategorySearchDetailDeleteFailedEffect and restores row',
      () async {
        when(
          () => repo.delete(any()),
        ).thenAnswer((_) async => throw StateError('db error'));

        final container = makeContainer();
        addTearDown(container.dispose);
        final provider = categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        );
        container.listen(provider, (_, _) {});

        final effects = <CategorySearchDetailEffect>[];
        container.read(provider.notifier).setEffectListener(effects.add);

        await Future<void>.delayed(Duration.zero);
        // Two rows so the state stays DetailData while #9 is hidden — a
        // single-row filter would briefly emit DetailEmpty during the
        // pending window, which is a separate UI concern not under test
        // here.
        txCtrl.add([
          _tx(
            id: 9,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 1,
            amount: 500,
          ),
          _tx(
            id: 10,
            date: DateTime.utc(2026, 5, 1),
            categoryId: 1,
            amount: 700,
          ),
        ]);
        await waitForData(container);

        fakeAsync((async) {
          container.read(provider.notifier).deleteTransaction(9);
          async.flushMicrotasks();

          final hiding = container.read(provider).requireValue as DetailData;
          expect(hiding.pendingDelete?.transaction.id, 9);
          expect(hiding.days.first.transactions.map((t) => t.id), [10]);

          // Past the undo window → repo.delete fires, throws, effect fires.
          async.elapse(kUndoWindow + const Duration(milliseconds: 1));
          async.flushMicrotasks();
        });

        await pump();

        // Row is restored after the failed commit.
        final after = container.read(provider).requireValue as DetailData;
        expect(after.pendingDelete, isNull);
        expect(
          after.days.first.transactions.map((t) => t.id),
          containsAll(<int>[9, 10]),
        );

        expect(effects, hasLength(1));
        expect(effects.single, isA<CategorySearchDetailDeleteFailedEffect>());
        verify(() => repo.delete(9)).called(1);
      },
    );

    test(
      'second deleteTransaction commits the prior pending delete immediately',
      () async {
        when(() => repo.delete(any())).thenAnswer((_) async => true);

        final container = makeContainer();
        addTearDown(container.dispose);
        final provider = categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        );
        container.listen(provider, (_, _) {});

        await Future<void>.delayed(Duration.zero);
        txCtrl.add([
          _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1),
          _tx(id: 2, date: DateTime.utc(2026, 5, 1), categoryId: 1),
        ]);
        await waitForData(container);

        fakeAsync((async) {
          container.read(provider.notifier).deleteTransaction(1);
          async.flushMicrotasks();

          container.read(provider.notifier).deleteTransaction(2);
          async.flushMicrotasks();

          // First delete commits immediately, second is still pending.
          verify(() => repo.delete(1)).called(1);
          verifyNever(() => repo.delete(2));

          async.elapse(kUndoWindow + const Duration(milliseconds: 1));
          async.flushMicrotasks();
        });

        await pump();
        verify(() => repo.delete(2)).called(1);
      },
    );
  });
}
