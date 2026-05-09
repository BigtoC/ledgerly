import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/category_search_detail_controller.dart';
import 'package:ledgerly/features/analysis/category_search_detail_state.dart';

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
}
