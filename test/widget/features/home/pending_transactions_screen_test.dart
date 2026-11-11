// PendingTransactionsScreen widget tests (issue #71).
//
// PTS01-03, 06-07: rendering with a fake controller (all days, empty,
// error, lazy list, 2x text scale).
// PTS04-05b: approve and swipe-skip through the real controller, with the
// snackbars coming from the PendingSnackBars host.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/pending_transaction.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/home/view_models/pending_controller.dart';
import 'package:ledgerly/ui/features/home/view_models/pending_state.dart';
import 'package:ledgerly/ui/features/home/views/pending_snack_bars.dart';
import 'package:ledgerly/ui/features/home/views/pending_transactions_screen.dart';

import '../../../support/text_scale.dart';

class _MockPendingRepo extends Mock implements PendingTransactionRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockAccountRepo extends Mock implements AccountRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

PendingTransaction _pending({
  required int id,
  String memo = 'Netflix',
  DateTime? date,
}) => PendingTransaction(
  id: id,
  source: 'recurring',
  amountMinorUnits: 1599,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  memo: memo,
  date: date ?? DateTime(2026, 5, 8),
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

@Dependencies([PendingController])
Widget _wrap(ProviderContainer container, {TransitionBuilder? builder}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: builder,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const PendingSnackBars(child: PendingTransactionsScreen()),
          ),
        ],
      ),
    ),
  );
}

/// Container over mocked repositories. Pass [fixed] to replace the
/// controller with a fake that emits it; otherwise the real controller
/// runs on [repo].
ProviderContainer _makeContainer({
  PendingState? fixed,
  _MockPendingRepo? repo,
}) {
  final pendingRepo = repo ?? _MockPendingRepo();
  if (repo == null) {
    when(() => pendingRepo.watchAll()).thenAnswer((_) => const Stream.empty());
  }
  final catRepo = _MockCategoryRepo();
  final accRepo = _MockAccountRepo();
  when(() => catRepo.watchAll(includeArchived: any(named: 'includeArchived')))
      .thenAnswer(
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
  when(() => accRepo.watchAll(includeArchived: any(named: 'includeArchived')))
      .thenAnswer(
        (_) => Stream.value(<Account>[
          const Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd),
        ]),
      );
  return ProviderContainer(
    overrides: [
      pendingTransactionRepositoryProvider.overrideWithValue(pendingRepo),
      categoryRepositoryProvider.overrideWithValue(catRepo),
      accountRepositoryProvider.overrideWithValue(accRepo),
      if (fixed != null)
        pendingControllerProvider.overrideWith(() => _FakeController(fixed)),
    ],
  );
}

_MockPendingRepo _repoWithOneRow() {
  final repo = _MockPendingRepo();
  when(() => repo.watchAll())
      .thenAnswer((_) => Stream.value([_pending(id: 1)]));
  when(() => repo.reject(any())).thenAnswer((_) async {});
  return repo;
}

@Dependencies([PendingController])
void main() {
  testWidgets('PTS01: rows from different days all render', (tester) async {
    final container = _makeContainer(
      fixed: PendingState.data(
        items: [
          _pending(id: 3, memo: 'Rent', date: DateTime(2026, 5, 10)),
          _pending(id: 2, memo: 'Gym', date: DateTime(2026, 5, 9)),
          _pending(id: 1, memo: 'Netflix', date: DateTime(2026, 5, 8)),
        ],
        skippingId: null,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.text('Pending transactions'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });

  for (final (label, state) in [
    ('no rows', const PendingState.empty()),
    (
      'only a row in the undo window',
      PendingState.data(items: [_pending(id: 1)], skippingId: 1),
    ),
  ]) {
    testWidgets('PTS02: $label shows the empty state', (tester) async {
      final container = _makeContainer(fixed: state);
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container));
      await tester.pump();

      expect(find.text('No pending transactions.'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
    });
  }

  testWidgets('PTS03: error state shows the load error', (tester) async {
    final container = _makeContainer(
      fixed: PendingState.error(StateError('boom'), StackTrace.current),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.text("Couldn't load pending items."), findsOneWidget);
  });

  testWidgets('PTS04: approve calls the repository and shows the snackbar', (
    tester,
  ) async {
    final repo = _repoWithOneRow();
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
    final container = _makeContainer(repo: repo);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => repo.approve(1)).called(1);
    expect(find.text('Approved — Netflix'), findsOneWidget);
  });

  testWidgets('PTS05: swipe-skip hides the row and Undo brings it back', (
    tester,
  ) async {
    final repo = _repoWithOneRow();
    final container = _makeContainer(repo: repo);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    await tester.pump();

    await tester.drag(find.text('Netflix'), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Skip once'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Netflix'), findsNothing);
    expect(find.text('No pending transactions.'), findsOneWidget);
    expect(find.text('Skipped this occurrence'), findsOneWidget);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Netflix'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    verifyNever(() => repo.reject(1));
  });

  testWidgets('PTS05b: the skip commits when the undo window lapses', (
    tester,
  ) async {
    final repo = _repoWithOneRow();
    final container = _makeContainer(repo: repo);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    await tester.pump();

    await tester.drag(find.text('Netflix'), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Skip once'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    verify(() => repo.reject(1)).called(1);
  });

  testWidgets('PTS06: a long list builds rows lazily', (tester) async {
    final container = _makeContainer(
      fixed: PendingState.data(
        items: [for (var i = 0; i < 40; i++) _pending(id: i, memo: 'Row $i')],
        skippingId: null,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.text('Row 0'), findsOneWidget);
    expect(find.text('Row 39'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Row 39'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Row 39'), findsOneWidget);
  });

  testWidgets('PTS07: 2x text scale renders without overflow', (tester) async {
    final container = _makeContainer(
      fixed: PendingState.data(items: [_pending(id: 1)], skippingId: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, builder: textScaleBuilder(2)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pending transactions'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
