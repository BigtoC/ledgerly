// PendingTile + _ApproveCircleButton widget tests.
//
// Covers tile rendering, approve animation, debounce, swipe-skip,
// and localized subtitle formatting.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/pending_transaction.dart';
import 'package:ledgerly/data/models/transaction.dart';
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

void _stubLookups(_MockCategoryRepo catRepo, _MockAccountRepo accRepo) {
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
}

ProviderContainer _makeFixedContainer(PendingState fixed) {
  final repo = _MockPendingRepo();
  final catRepo = _MockCategoryRepo();
  final accRepo = _MockAccountRepo();
  when(() => repo.watchAll()).thenAnswer((_) => const Stream.empty());
  when(
    () => repo.approve(any()),
  ).thenAnswer((_) async => throw UnimplementedError());
  when(() => repo.reject(any())).thenAnswer((_) async {});
  _stubLookups(catRepo, accRepo);
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
  testWidgets('PT01: default circle is grey with check icon', (tester) async {
    final container = _makeFixedContainer(
      PendingState.data(items: [_pending(id: 1)], skipScheduled: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('PT02: tapping circle calls controller.approve once', (
    tester,
  ) async {
    final repo = _MockPendingRepo();
    final catRepo = _MockCategoryRepo();
    final accRepo = _MockAccountRepo();
    when(
      () => repo.watchAll(),
    ).thenAnswer((_) => Stream.value([_pending(id: 1)]));
    when(() => repo.approve(1)).thenAnswer(
      (_) async => Transaction(
        id: 99,
        amountMinorUnits: 1599,
        currency: _usd,
        categoryId: 1,
        accountId: 1,
        date: DateTime(2026, 5, 8),
        memo: 'Netflix',
        createdAt: DateTime(2026, 5, 8, 12),
        updatedAt: DateTime(2026, 5, 8, 12),
      ),
    );
    when(() => repo.reject(any())).thenAnswer((_) async {});
    _stubLookups(catRepo, accRepo);

    final container = ProviderContainer(
      overrides: [
        pendingTransactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    verify(() => repo.approve(1)).called(1);
  });

  testWidgets(
    'PT03: rapid double-tap on circle still calls approve only once',
    (tester) async {
      final repo = _MockPendingRepo();
      final catRepo = _MockCategoryRepo();
      final accRepo = _MockAccountRepo();
      when(
        () => repo.watchAll(),
      ).thenAnswer((_) => Stream.value([_pending(id: 1)]));
      final approveCompleter = Completer<Transaction>();
      when(() => repo.approve(1)).thenAnswer((_) => approveCompleter.future);
      when(() => repo.reject(any())).thenAnswer((_) async {});
      _stubLookups(catRepo, accRepo);

      final container = ProviderContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWithValue(repo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          accountRepositoryProvider.overrideWithValue(accRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byIcon(Icons.check));
      // Pump past the 200ms forward animation so approve() actually fires.
      // The `_approving` debounce flag has already absorbed the second tap
      // synchronously by this point.
      await tester.pump(const Duration(milliseconds: 250));

      verify(() => repo.approve(1)).called(1);

      approveCompleter.complete(
        Transaction(
          id: 99,
          amountMinorUnits: 1599,
          currency: _usd,
          categoryId: 1,
          accountId: 1,
          date: DateTime(2026, 5, 8),
          memo: 'Netflix',
          createdAt: DateTime(2026, 5, 8, 12),
          updatedAt: DateTime(2026, 5, 8, 12),
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('PT04: PendingApproveFailedEffect surfaces error snackbar', (
    tester,
  ) async {
    final repo = _MockPendingRepo();
    final catRepo = _MockCategoryRepo();
    final accRepo = _MockAccountRepo();
    when(
      () => repo.watchAll(),
    ).thenAnswer((_) => Stream.value([_pending(id: 1)]));
    when(
      () => repo.approve(1),
    ).thenThrow(const PendingTransactionRepositoryException('archived'));
    when(() => repo.reject(any())).thenAnswer((_) async {});
    _stubLookups(catRepo, accRepo);

    final container = ProviderContainer(
      overrides: [
        pendingTransactionRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('PT05: swipe-left reveals Skip action', (tester) async {
    final container = _makeFixedContainer(
      PendingState.data(items: [_pending(id: 1)], skipScheduled: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Netflix'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Skip once'), findsOneWidget);
  });

  testWidgets('PT06: subtitle renders category · account · date', (
    tester,
  ) async {
    final container = _makeFixedContainer(
      PendingState.data(items: [_pending(id: 1)], skipScheduled: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.textContaining('Food'), findsOneWidget);
    expect(find.textContaining('Cash'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('PT07: 2x text scale does not overflow trailing slot', (
    tester,
  ) async {
    final container = _makeFixedContainer(
      PendingState.data(items: [_pending(id: 1)], skipScheduled: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _wrap(container),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
