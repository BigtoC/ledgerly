// HomeScreen shopping-list mini-FAB widget tests — Task 8.
//
// Test IDs: HSL01–HSL05
//
// Covers:
//   - HSL01: badge shows count when count > 0
//   - HSL02: no badge label when count == 0
//   - HSL03: badge shows "99+" when count > 99
//   - HSL04: tapping mini FAB navigates to /accounts/shopping-list
//   - HSL05: both mini FAB and extended FAB are visible simultaneously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockAccountRepo extends Mock implements AccountRepository {}

class _MockCurrencyRepo extends Mock implements CurrencyRepository {}

class _MockShoppingListRepo extends Mock implements ShoppingListRepository {}

// ── Fixtures ──────────────────────────────────────────────────────────────

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

// ── Helpers ───────────────────────────────────────────────────────────────

GoRouter _buildRouter({
  required Widget homeWidget,
  List<GoRoute> extra = const [],
}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => homeWidget,
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const Scaffold(body: Text('ADD_FORM')),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, _) => const Scaffold(body: Text('EDIT_FORM')),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts/shopping-list',
        builder: (_, _) => const Scaffold(body: Text('SHOPPING_LIST_SCREEN')),
      ),
      ...extra,
    ],
  );
}

Widget _makeApp({
  required _MockTxRepo txRepo,
  required _MockCategoryRepo catRepo,
  required _MockAccountRepo accRepo,
  required _MockCurrencyRepo curRepo,
  required _MockShoppingListRepo slRepo,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(txRepo),
      categoryRepositoryProvider.overrideWithValue(catRepo),
      accountRepositoryProvider.overrideWithValue(accRepo),
      currencyRepositoryProvider.overrideWithValue(curRepo),
      shoppingListRepositoryProvider.overrideWithValue(slRepo),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _buildRouter(homeWidget: const HomeScreen()),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  late _MockTxRepo txRepo;
  late _MockCategoryRepo catRepo;
  late _MockAccountRepo accRepo;
  late _MockCurrencyRepo curRepo;
  late _MockShoppingListRepo slRepo;

  late StreamController<List<Transaction>> dayCtrl;
  late StreamController<List<DateTime>> activityCtrl;
  late StreamController<Map<String, ({int expense, int income})>>
  todayTotalsCtrl;
  late StreamController<Map<String, int>> monthNetCtrl;

  setUp(() {
    txRepo = _MockTxRepo();
    catRepo = _MockCategoryRepo();
    accRepo = _MockAccountRepo();
    curRepo = _MockCurrencyRepo();
    slRepo = _MockShoppingListRepo();

    dayCtrl = StreamController.broadcast();
    activityCtrl = StreamController.broadcast();
    todayTotalsCtrl = StreamController.broadcast();
    monthNetCtrl = StreamController.broadcast();

    when(() => txRepo.watchByDay(any())).thenAnswer((_) => dayCtrl.stream);
    when(
      () => txRepo.watchDaysWithActivity(),
    ).thenAnswer((_) => activityCtrl.stream);
    when(
      () => txRepo.watchDailyTotalsByType(any()),
    ).thenAnswer((_) => todayTotalsCtrl.stream);
    when(
      () => txRepo.watchMonthNetByCurrency(any()),
    ).thenAnswer((_) => monthNetCtrl.stream);
    when(
      () => catRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => accRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => curRepo.watchAll(includeTokens: true),
    ).thenAnswer((_) => Stream.value([_usd]));
  });

  tearDown(() async {
    await dayCtrl.close();
    await activityCtrl.close();
    await todayTotalsCtrl.close();
    await monthNetCtrl.close();
  });

  testWidgets('HSL01: badge shows count "3" when shopping list has 3 items', (
    tester,
  ) async {
    when(() => slRepo.watchCount()).thenAnswer((_) => Stream.value(3));

    await tester.pumpWidget(
      _makeApp(
        txRepo: txRepo,
        catRepo: catRepo,
        accRepo: accRepo,
        curRepo: curRepo,
        slRepo: slRepo,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('homeShoppingListFab')), findsOneWidget);
    // Badge label text "3" is visible.
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('HSL02: no badge label shown when shopping list count is 0', (
    tester,
  ) async {
    when(() => slRepo.watchCount()).thenAnswer((_) => Stream.value(0));

    await tester.pumpWidget(
      _makeApp(
        txRepo: txRepo,
        catRepo: catRepo,
        accRepo: accRepo,
        curRepo: curRepo,
        slRepo: slRepo,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('homeShoppingListFab')), findsOneWidget);
    // No numeric badge label should be visible.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('HSL03: badge shows "99+" when shopping list count exceeds 99', (
    tester,
  ) async {
    when(() => slRepo.watchCount()).thenAnswer((_) => Stream.value(100));

    await tester.pumpWidget(
      _makeApp(
        txRepo: txRepo,
        catRepo: catRepo,
        accRepo: accRepo,
        curRepo: curRepo,
        slRepo: slRepo,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('homeShoppingListFab')), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('HSL04: tapping mini FAB navigates to /accounts/shopping-list', (
    tester,
  ) async {
    when(() => slRepo.watchCount()).thenAnswer((_) => Stream.value(2));

    await tester.pumpWidget(
      _makeApp(
        txRepo: txRepo,
        catRepo: catRepo,
        accRepo: accRepo,
        curRepo: curRepo,
        slRepo: slRepo,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('homeShoppingListFab')));
    await tester.pumpAndSettle();

    expect(find.text('SHOPPING_LIST_SCREEN'), findsOneWidget);
  });

  testWidgets(
    'HSL05: both shopping-list mini FAB and add-transaction FAB are visible',
    (tester) async {
      when(() => slRepo.watchCount()).thenAnswer((_) => Stream.value(0));

      await tester.pumpWidget(
        _makeApp(
          txRepo: txRepo,
          catRepo: catRepo,
          accRepo: accRepo,
          curRepo: curRepo,
          slRepo: slRepo,
        ),
      );
      await tester.pump();

      // Both FABs must be in the widget tree simultaneously.
      expect(find.byKey(const Key('homeShoppingListFab')), findsOneWidget);
      // The existing extended FAB with heroTag 'home_fab'.
      expect(find.text('Add transaction'), findsOneWidget);
    },
  );
}
