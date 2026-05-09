// AnalysisController unit tests — debounce, cancellation, grouping,
// sort key. Repositories mocked via `mocktail`; categories via a
// `StreamController` overridden onto `analysisCategoriesByIdProvider`.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/analysis_controller.dart';
import 'package:ledgerly/features/analysis/analysis_providers.dart';
import 'package:ledgerly/features/analysis/analysis_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Category _cat({required int id, String name = 'Coffee'}) => Category(
  id: id,
  type: CategoryType.expense,
  l10nKey: 'cat.coffee',
  customName: name,
  icon: 'coffee',
  color: 1,
  sortOrder: id,
  isArchived: false,
);

Transaction _tx({
  required int id,
  required DateTime date,
  required int categoryId,
  Currency currency = _usd,
  int amount = 1000,
  String? memo = 'coffee',
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: categoryId,
  accountId: 1,
  date: date,
  memo: memo,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

ProviderContainer _makeContainer({
  required TransactionRepository repo,
  required Stream<Map<int, Category>> categoriesStream,
}) {
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      analysisCategoriesByIdProvider.overrideWith((ref) => categoriesStream),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('AnalysisController', () {
    late _MockTransactionRepository repo;
    late StreamController<List<Transaction>> txCtrl;

    setUp(() {
      repo = _MockTransactionRepository();
      txCtrl = StreamController<List<Transaction>>.broadcast();
      when(() => repo.watchByMemo(any())).thenAnswer((_) => txCtrl.stream);
    });

    tearDown(() async {
      await txCtrl.close();
    });

    test('starts in AnalysisIdle and stays there for empty query', () async {
      final container = _makeContainer(
        repo: repo,
        categoriesStream: Stream.value(const <int, Category>{}),
      );
      addTearDown(container.dispose);

      final state = await container.read(analysisControllerProvider.future);
      expect(state, isA<AnalysisIdle>());

      container.read(analysisControllerProvider.notifier).updateQuery('   ');
      final next = await container.read(analysisControllerProvider.future);
      expect(next, isA<AnalysisIdle>());

      verifyNever(() => repo.watchByMemo(any()));
    });

    test('debounces to 300ms then groups by (category, currency)', () {
      fakeAsync((async) {
        final container = _makeContainer(
          repo: repo,
          categoriesStream: Stream.value({1: _cat(id: 1)}),
        );
        addTearDown(container.dispose);
        container.listen(analysisControllerProvider, (_, _) {});

        container.read(analysisControllerProvider.notifier).updateQuery('co');
        container.read(analysisControllerProvider.notifier).updateQuery('cof');
        container
            .read(analysisControllerProvider.notifier)
            .updateQuery('coffee');
        async.elapse(const Duration(milliseconds: 250));
        verifyNever(() => repo.watchByMemo(any()));

        async.elapse(const Duration(milliseconds: 100));
        verify(() => repo.watchByMemo('coffee')).called(1);

        txCtrl.add([
          _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1),
          _tx(id: 2, date: DateTime.utc(2026, 5, 3), categoryId: 1),
        ]);
        async.flushMicrotasks();

        final state = container.read(analysisControllerProvider).valueOrNull;
        expect(state, isA<AnalysisResults>());
        final results = (state as AnalysisResults).categories;
        expect(results, hasLength(1));
        expect(results.first.category.id, 1);
        expect(results.first.transactionCount, 2);
        expect(results.first.mostRecentDate, DateTime.utc(2026, 5, 3));
      });
    });

    test('sorts by mostRecentDate desc; tiebreak by categoryId asc', () {
      fakeAsync((async) {
        final container = _makeContainer(
          repo: repo,
          categoriesStream: Stream.value({
            1: _cat(id: 1, name: 'Cat-1'),
            2: _cat(id: 2, name: 'Cat-2'),
            3: _cat(id: 3, name: 'Cat-3'),
          }),
        );
        addTearDown(container.dispose);
        container.listen(analysisControllerProvider, (_, _) {});

        container
            .read(analysisControllerProvider.notifier)
            .updateQuery('coffee');
        async.elapse(const Duration(milliseconds: 350));

        txCtrl.add([
          _tx(id: 10, date: DateTime.utc(2026, 5, 5), categoryId: 3),
          _tx(id: 11, date: DateTime.utc(2026, 5, 1), categoryId: 1),
          _tx(id: 12, date: DateTime.utc(2026, 5, 1), categoryId: 2),
        ]);
        async.flushMicrotasks();

        final results =
            (container.read(analysisControllerProvider).valueOrNull
                    as AnalysisResults)
                .categories;

        expect(results.map((r) => r.category.id).toList(), [3, 1, 2]);
      });
    });

    test('cancels prior watchByMemo subscription on new query', () {
      fakeAsync((async) {
        var coCancelled = false;
        final coCtrl = StreamController<List<Transaction>>(
          onCancel: () => coCancelled = true,
        );
        final coffeeCtrl = StreamController<List<Transaction>>.broadcast();

        when(() => repo.watchByMemo('co')).thenAnswer((_) => coCtrl.stream);
        when(
          () => repo.watchByMemo('coffee'),
        ).thenAnswer((_) => coffeeCtrl.stream);

        final container = _makeContainer(
          repo: repo,
          categoriesStream: Stream.value({1: _cat(id: 1)}),
        );
        addTearDown(container.dispose);
        addTearDown(() async {
          await coCtrl.close();
          await coffeeCtrl.close();
        });
        container.listen(analysisControllerProvider, (_, _) {});

        container.read(analysisControllerProvider.notifier).updateQuery('co');
        async.elapse(const Duration(milliseconds: 350));
        verify(() => repo.watchByMemo('co')).called(1);

        container
            .read(analysisControllerProvider.notifier)
            .updateQuery('coffee');
        async.elapse(const Duration(milliseconds: 350));
        verify(() => repo.watchByMemo('coffee')).called(1);

        expect(coCancelled, isTrue);
      });
    });

    test('loading carries previous results on follow-up query', () {
      fakeAsync((async) {
        final container = _makeContainer(
          repo: repo,
          categoriesStream: Stream.value({1: _cat(id: 1)}),
        );
        addTearDown(container.dispose);
        container.listen(analysisControllerProvider, (_, _) {});

        container
            .read(analysisControllerProvider.notifier)
            .updateQuery('coffee');
        async.elapse(const Duration(milliseconds: 350));
        txCtrl.add([_tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1)]);
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        expect(
          container.read(analysisControllerProvider).valueOrNull,
          isA<AnalysisResults>(),
        );

        container.read(analysisControllerProvider.notifier).updateQuery('xyz');
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        verifyNever(() => repo.watchByMemo('xyz'));
        final loading =
            container.read(analysisControllerProvider).valueOrNull
                as AnalysisLoading;
        expect(loading.query, 'xyz');
        expect(loading.previous, isNotNull);
        expect(loading.previous!.first.category.id, 1);
      });
    });

    test(
      'clear → retype emits loading with previous=null (lastResults cleared on idle)',
      () {
        fakeAsync((async) {
          final container = _makeContainer(
            repo: repo,
            categoriesStream: Stream.value({1: _cat(id: 1)}),
          );
          addTearDown(container.dispose);
          container.listen(analysisControllerProvider, (_, _) {});

          container
              .read(analysisControllerProvider.notifier)
              .updateQuery('coffee');
          async.elapse(const Duration(milliseconds: 350));
          txCtrl.add([
            _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1),
          ]);
          async.flushMicrotasks();
          async.elapse(Duration.zero);

          container.read(analysisControllerProvider.notifier).updateQuery('');
          async.flushMicrotasks();
          async.elapse(Duration.zero);
          expect(
            container.read(analysisControllerProvider).valueOrNull,
            isA<AnalysisIdle>(),
          );

          container
              .read(analysisControllerProvider.notifier)
              .updateQuery('latte');
          async.flushMicrotasks();
          async.elapse(Duration.zero);
          final loading =
              container.read(analysisControllerProvider).valueOrNull
                  as AnalysisLoading;
          expect(loading.previous, isNull);
        });
      },
    );

    test(
      'category-map emission re-emits results without a new transactions emission',
      () {
        fakeAsync((async) {
          final cats = StreamController<Map<int, Category>>.broadcast();
          addTearDown(cats.close);
          final container = _makeContainer(
            repo: repo,
            categoriesStream: cats.stream,
          );
          addTearDown(container.dispose);
          container.listen(analysisControllerProvider, (_, _) {});

          cats.add({1: _cat(id: 1, name: 'Coffee')});
          async.flushMicrotasks();

          container
              .read(analysisControllerProvider.notifier)
              .updateQuery('coffee');
          async.elapse(const Duration(milliseconds: 350));
          txCtrl.add([
            _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1),
          ]);
          async.flushMicrotasks();

          var results =
              (container.read(analysisControllerProvider).valueOrNull
                      as AnalysisResults)
                  .categories;
          expect(results.first.category.customName, 'Coffee');

          cats.add({1: _cat(id: 1, name: 'Espresso')});
          async.flushMicrotasks();

          results =
              (container.read(analysisControllerProvider).valueOrNull
                      as AnalysisResults)
                  .categories;
          expect(results.first.category.customName, 'Espresso');
        });
      },
    );

    test('Drift stream errors are forwarded to AsyncValue.error', () {
      fakeAsync((async) {
        final errCtrl = StreamController<List<Transaction>>.broadcast();
        when(() => repo.watchByMemo('boom')).thenAnswer((_) => errCtrl.stream);
        addTearDown(errCtrl.close);

        final container = _makeContainer(
          repo: repo,
          categoriesStream: Stream.value({1: _cat(id: 1)}),
        );
        addTearDown(container.dispose);
        container.listen(analysisControllerProvider, (_, _) {});

        container.read(analysisControllerProvider.notifier).updateQuery('boom');
        async.elapse(const Duration(milliseconds: 350));
        errCtrl.addError(StateError('db locked'));
        async.flushMicrotasks();

        expect(container.read(analysisControllerProvider).hasError, isTrue);
      });
    });

    test('empty result emits AnalysisEmpty', () {
      fakeAsync((async) {
        final container = _makeContainer(
          repo: repo,
          categoriesStream: Stream.value({1: _cat(id: 1)}),
        );
        addTearDown(container.dispose);
        container.listen(analysisControllerProvider, (_, _) {});

        container.read(analysisControllerProvider.notifier).updateQuery('zzz');
        async.elapse(const Duration(milliseconds: 350));
        txCtrl.add(const []);
        async.flushMicrotasks();

        expect(
          container.read(analysisControllerProvider).valueOrNull,
          isA<AnalysisEmpty>(),
        );
      });
    });
  });
}
