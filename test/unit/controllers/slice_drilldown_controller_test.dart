import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _ManualTransactionsStream extends Stream<List<Transaction>> {
  void Function(List<Transaction>)? _onData;
  void Function(Object, StackTrace)? _onError;

  @override
  StreamSubscription<List<Transaction>> listen(
    void Function(List<Transaction>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    if (onError is void Function(Object, StackTrace)) {
      _onError = onError;
    } else if (onError is void Function(Object)) {
      _onError = (error, _) => onError(error);
    } else {
      _onError = null;
    }
    return _NoopSubscription<List<Transaction>>();
  }

  void emit(List<Transaction> rows) => _onData?.call(rows);

  void emitError(Object error, StackTrace stackTrace) =>
      _onError?.call(error, stackTrace);
}

class _ManualFxStatusStream extends Stream<ChartsFxStatus> {
  void Function(ChartsFxStatus)? _onData;

  @override
  StreamSubscription<ChartsFxStatus> listen(
    void Function(ChartsFxStatus)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    return _NoopSubscription<ChartsFxStatus>();
  }

  void emit(ChartsFxStatus status) => _onData?.call(status);
}

class _NoopSubscription<T> implements StreamSubscription<T> {
  @override
  Future<void> cancel() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _usd = Currency(code: 'USD', decimals: 2);

Transaction _tx(int id, {Currency currency = _usd}) => Transaction(
  id: id,
  amountMinorUnits: 100 * id,
  currency: currency,
  categoryId: 1,
  accountId: 1,
  date: DateTime(2026, 5, 18),
  createdAt: DateTime(2026, 5, 18),
  updatedAt: DateTime(2026, 5, 18),
);

@Dependencies([
  ChartsSelectionController,
  chartsFxStatus,
  SliceDrilldownController,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  late _MockRepo repo;
  late ProviderContainer container;
  late _ManualFxStatusStream fxStream;

  setUp(() {
    repo = _MockRepo();
    fxStream = _ManualFxStatusStream();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        chartsFxStatusProvider.overrideWith((ref) => fxStream),
      ],
    );
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(1));
    container.listen(chartsFxStatusProvider, (_, _) {}, fireImmediately: true);
    fxStream.emit(const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}));
  });
  tearDown(() => container.dispose());

  @Dependencies([SliceDrilldownController])
  Future<SliceDrilldownData> readData() async {
    // Drain initial emission via a listener (mirrors the pattern used in
    // charts_controller_slice_test.dart since `.stream` on a
    // StreamNotifierProvider behaves differently across Riverpod versions).
    container.listen(sliceDrilldownControllerProvider, (_, _) {});
    SliceDrilldownData? data;
    while (data == null) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      data = container.read(sliceDrilldownControllerProvider).value;
    }
    return data;
  }

  test('emits SliceDrilldownData with rows from the repo stream', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));

    final state = await readData();
    expect(state.rows, hasLength(2));
  });

  test(
    'no selection leaves provider in loading without touching the repo',
    () async {
      container.read(chartsSelectionControllerProvider.notifier).clearSlice();
      // Force a read so the provider is built.
      container.listen(sliceDrilldownControllerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(
        container.read(sliceDrilldownControllerProvider).isLoading,
        isTrue,
      );
      verifyNever(
        () => repo.watchTransactionsForSliceInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      );
    },
  );

  test(
    'delete records pendingDeleteId, keeps row in list until commit',
    () async {
      when(
        () => repo.watchTransactionsForSliceInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));
      when(() => repo.delete(any())).thenAnswer((_) async => true);

      await readData();
      await container.read(sliceDrilldownControllerProvider.notifier).delete(1);

      await Future<void>.delayed(Duration.zero);
      final pending = container.read(sliceDrilldownControllerProvider).value!;
      expect(pending.pendingDeleteId, equals(1));
      expect(pending.rows.map((t) => t.id), contains(1));
    },
  );

  test('second delete commits the prior pending row immediately', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));
    when(() => repo.delete(any())).thenAnswer((_) async => true);

    await readData();
    final notifier = container.read(sliceDrilldownControllerProvider.notifier);
    await notifier.delete(1);
    await Future<void>.delayed(Duration.zero);
    await notifier.delete(2);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => repo.delete(1)).called(1);
    expect(
      container.read(sliceDrilldownControllerProvider).value!.pendingDeleteId,
      2,
    );
    expect(
      container
          .read(sliceDrilldownControllerProvider)
          .value!
          .rows
          .map((t) => t.id),
      [2],
    );
  });

  test('commit fires repo.delete after kUndoWindow', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1)]));
    when(() => repo.delete(any())).thenAnswer((_) async => true);

    await readData();
    await container.read(sliceDrilldownControllerProvider.notifier).delete(1);
    await Future<void>.delayed(kUndoWindow + const Duration(milliseconds: 200));
    verify(() => repo.delete(1)).called(1);
  });

  test('undoDelete cancels commit — repo.delete never called', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1)]));
    when(() => repo.delete(any())).thenAnswer((_) async => true);

    await readData();
    await container.read(sliceDrilldownControllerProvider.notifier).delete(1);
    container.read(sliceDrilldownControllerProvider.notifier).undoDelete();
    await Future<void>.delayed(kUndoWindow + const Duration(milliseconds: 200));
    verifyNever(() => repo.delete(any()));
  });

  test('selection change clears pending delete before resubscribe', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1)]));

    await readData();
    final notifier = container.read(sliceDrilldownControllerProvider.notifier);
    await notifier.delete(1);
    await Future<void>.delayed(Duration.zero);

    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.currency);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sliceDrilldownControllerProvider).isLoading, isTrue);
    verifyNever(() => repo.delete(any()));
  });

  test('failed forced commit aborts starting a new pending delete', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));
    when(() => repo.delete(1)).thenThrow(StateError('boom'));

    final effects = <SliceDrilldownEffect>[];
    final notifier = container.read(sliceDrilldownControllerProvider.notifier);
    notifier.setEffectListener(effects.add);

    await readData();
    await notifier.delete(1);
    await Future<void>.delayed(Duration.zero);
    await notifier.delete(2);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => repo.delete(1)).called(1);
    expect(
      container.read(sliceDrilldownControllerProvider).value!.pendingDeleteId,
      isNull,
    );
    expect(effects.single, isA<SliceDrilldownDeleteFailedEffect>());
  });

  test('ignores stale emissions from a canceled prior subscription', () async {
    final first = _ManualTransactionsStream();
    final second = _ManualTransactionsStream();
    var calls = 0;
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => calls++ == 0 ? first : second);

    container.listen(sliceDrilldownControllerProvider, (_, _) {});
    first.emit([_tx(1)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(sliceDrilldownControllerProvider).value!.rows.single.id,
      1,
    );

    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    second.emit([_tx(2)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(sliceDrilldownControllerProvider).value!.rows.single.id,
      2,
    );

    // Simulate a late callback from the prior generation landing after the
    // selection already moved to category 2.
    first.emit([_tx(1)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(sliceDrilldownControllerProvider).value!.rows.single.id,
      2,
    );
  });

  test('ignores stale errors from a canceled prior subscription', () async {
    final first = _ManualTransactionsStream();
    final second = _ManualTransactionsStream();
    var calls = 0;
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => calls++ == 0 ? first : second);

    container.listen(sliceDrilldownControllerProvider, (_, _) {});
    first.emit([_tx(1)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    second.emit([_tx(2)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    first.emitError(StateError('stale'), StackTrace.current);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = container.read(sliceDrilldownControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.value!.rows.single.id, 2);
  });

  test('re-emits cached rows when FX availability changes', () async {
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value([
        _tx(1),
        _tx(2, currency: const Currency(code: 'EUR', decimals: 2)),
      ]),
    );

    final stateLog = <SliceDrilldownData>[];
    container.listen(sliceDrilldownControllerProvider, (_, next) {
      final value = next.value;
      if (value != null) {
        stateLog.add(value);
      }
    }, fireImmediately: true);

    final initial = await readData();
    expect(initial.rows.map((t) => t.id), [1]);

    fxStream.emit(
      ChartsFxStatus(
        defaultCurrencyCode: 'USD',
        rates: {
          'EUR→USD': ExchangeRateMetadata(
            rateScaledE9: 1100000000,
            fetchedAt: DateTime.now(),
          ),
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(stateLog.last.rows.map((t) => t.id), [1, 2]);
  });

  group('account filter', () {
    void stubRows() {
      when(
        () => repo.watchTransactionsForSliceInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
        ),
      ).thenAnswer((_) => Stream.value([_tx(1)]));
    }

    /// `(categoryId, accountId, currencyCode)` of the latest rows query.
    (Object?, Object?, Object?) lastFilters() {
      final captured = verify(
        () => repo.watchTransactionsForSliceInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
          categoryId: captureAny(named: 'categoryId'),
          accountId: captureAny(named: 'accountId'),
          currencyCode: captureAny(named: 'currencyCode'),
        ),
      ).captured;
      final n = captured.length;
      return (captured[n - 3], captured[n - 2], captured[n - 1]);
    }

    test(
      'a category slice without a filter queries by category only',
      () async {
        stubRows();

        await readData();

        expect(lastFilters(), (1, null, null));
      },
    );

    test('a category slice under the filter queries by category AND '
        'account', () async {
      stubRows();
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );
      selection.setAccountFilter(3);
      selection.toggleSlice(const SelectedSlice.category(1));

      await readData();

      expect(lastFilters(), (1, 3, null));
    });

    test('a currency slice under the filter queries by currency AND '
        'account', () async {
      stubRows();
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );
      selection.setDimension(ChartDimension.currency);
      selection.setAccountFilter(3);
      selection.toggleSlice(const SelectedSlice.currency('USD'));

      await readData();

      expect(lastFilters(), (null, 3, 'USD'));
    });

    test('an account slice queries by its own account', () async {
      stubRows();
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );
      selection.setDimension(ChartDimension.account);
      selection.toggleSlice(const SelectedSlice.account(4));

      await readData();

      expect(lastFilters(), (null, 4, null));
    });
  });
}
