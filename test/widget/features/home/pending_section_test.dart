// PendingSection widget tests.
//
// Covers loading / empty / data / error rendering using the _FakeController
// pattern from recurring_rules_screen_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/pending_transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/features/home/pending_controller.dart';
import 'package:ledgerly/features/home/pending_state.dart';
import 'package:ledgerly/features/home/widgets/pending_section.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockPendingRepo extends Mock implements PendingTransactionRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockAccountRepo extends Mock implements AccountRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

PendingTransaction _pending({
  required int id,
  String memo = 'Netflix',
  int amount = 1599,
}) => PendingTransaction(
  id: id,
  source: 'recurring',
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  memo: memo,
  date: DateTime(2026, 5, 8),
  fetchedAt: DateTime(2026, 5, 8),
  recurringRuleId: 1,
);

class _FakeController extends PendingController {
  _FakeController(this._fixed);
  final PendingState _fixed;

  @override
  Stream<PendingState> build() async* {
    yield _fixed;
  }
}

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CustomScrollView(slivers: [PendingSection()])),
    ),
  );
}

ProviderContainer _makeContainer(PendingState fixed) {
  final repo = _MockPendingRepo();
  final catRepo = _MockCategoryRepo();
  final accRepo = _MockAccountRepo();
  when(() => repo.watchAll()).thenAnswer((_) => const Stream.empty());
  when(
    () => repo.approve(any()),
  ).thenAnswer((_) async => throw UnimplementedError());
  when(() => repo.reject(any())).thenAnswer((_) async {});
  when(
    () => catRepo.watchAll(includeArchived: any(named: 'includeArchived')),
  ).thenAnswer(
    (_) => Stream.value(<Category>[
      const Category(
        id: 1,
        icon: 'restaurant',
        color: 0,
        type: CategoryType.expense,
        l10nKey: 'category.food',
      ),
    ]),
  );
  when(
    () => accRepo.watchAll(includeArchived: any(named: 'includeArchived')),
  ).thenAnswer(
    (_) => Stream.value(<Account>[
      const Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd),
    ]),
  );
  return ProviderContainer(
    overrides: [
      pendingTransactionRepositoryProvider.overrideWithValue(repo),
      categoryRepositoryProvider.overrideWithValue(catRepo),
      accountRepositoryProvider.overrideWithValue(accRepo),
      pendingControllerProvider.overrideWith(() => _FakeController(fixed)),
    ],
  );
}

void main() {
  testWidgets('PS01: PendingLoading renders SizedBox.shrink', (tester) async {
    final container = _makeContainer(const PendingState.loading());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('PS02: PendingEmpty renders SizedBox.shrink', (tester) async {
    final container = _makeContainer(const PendingState.empty());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('PS03: PendingData with N items shows header + N tiles', (
    tester,
  ) async {
    final items = [
      _pending(id: 1),
      _pending(id: 2, memo: 'Rent', amount: 200000),
    ];
    final container = _makeContainer(
      PendingState.data(items: items, skipScheduled: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
  });

  testWidgets('PS04: tap on row body does nothing', (tester) async {
    final container = _makeContainer(
      PendingState.data(items: [_pending(id: 1)], skipScheduled: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Netflix'));
    await tester.pump();
  });

  testWidgets('PS05: error variant renders inline banner', (tester) async {
    final container = _makeContainer(
      PendingState.error(StateError('boom'), StackTrace.current),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load pending items."), findsOneWidget);
  });
}
