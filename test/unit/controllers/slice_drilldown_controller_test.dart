import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_controller.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_data.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

Transaction _tx(int id) => Transaction(
  id: id,
  amountMinorUnits: 100 * id,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: DateTime(2026, 5, 18),
  createdAt: DateTime(2026, 5, 18),
  updatedAt: DateTime(2026, 5, 18),
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
    );
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(const SelectedSlice.category(1));
  });
  tearDown(() => container.dispose());

  Future<SliceDrilldownData> _readData() async {
    // Drain initial emission via a listener (mirrors the pattern used in
    // charts_controller_slice_test.dart since `.stream` on a
    // StreamNotifierProvider behaves differently across Riverpod versions).
    container.listen(sliceDrilldownControllerProvider, (_, _) {});
    SliceDrilldownData? data;
    while (data == null) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      data = container.read(sliceDrilldownControllerProvider).valueOrNull;
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

    final state = await _readData();
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

      await _readData();
      container.read(sliceDrilldownControllerProvider.notifier).delete(1);

      await Future<void>.delayed(Duration.zero);
      final pending = container
          .read(sliceDrilldownControllerProvider)
          .valueOrNull!;
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

    await _readData();
    final notifier = container.read(sliceDrilldownControllerProvider.notifier);
    notifier.delete(1);
    await Future<void>.delayed(Duration.zero);
    notifier.delete(2);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(() => repo.delete(1)).called(1);
    expect(
      container
          .read(sliceDrilldownControllerProvider)
          .valueOrNull!
          .pendingDeleteId,
      2,
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

    await _readData();
    container.read(sliceDrilldownControllerProvider.notifier).delete(1);
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

    await _readData();
    container.read(sliceDrilldownControllerProvider.notifier).delete(1);
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

    await _readData();
    final notifier = container.read(sliceDrilldownControllerProvider.notifier);
    notifier.delete(1);
    await Future<void>.delayed(Duration.zero);

    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.currency);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sliceDrilldownControllerProvider).isLoading, isTrue);
    verifyNever(() => repo.delete(any()));
  });
}
