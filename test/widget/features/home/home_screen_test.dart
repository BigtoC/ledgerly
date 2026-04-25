// HomeScreen widget tests — Wave 3 §4.3.
//
// Covers:
//   - First-run empty state renders `homeEmptyTitle` + `homeEmptyCta`.
//   - Per-day list renders rows + summary strip per currency.
//   - Per-day empty state after navigating to a gap day.
//   - >=600dp tablet renders the two-pane layout.
//   - Archived category/account metadata still resolve on historical
//     rows.
//
// Repositories are mocked via `mocktail`; no live DB. The form route
// is short-circuited so we don't need a real router.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockAccountRepo extends Mock implements AccountRepository {}

class _MockCurrencyRepo extends Mock implements CurrencyRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Transaction _tx({
  required int id,
  required DateTime date,
  int amount = 100,
  int categoryId = 1,
  int accountId = 1,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: _usd,
  categoryId: categoryId,
  accountId: accountId,
  date: date,
  createdAt: DateTime.utc(0),
  updatedAt: DateTime.utc(0),
);

Category _cat({
  required int id,
  CategoryType type = CategoryType.expense,
  String? customName,
  String? l10nKey,
  bool isArchived = false,
}) => Category(
  id: id,
  icon: 'restaurant',
  color: 0,
  type: type,
  l10nKey: l10nKey,
  customName: customName,
  isArchived: isArchived,
);

Account _acc({
  required int id,
  String name = 'Cash',
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: 1,
  currency: _usd,
  isArchived: isArchived,
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  late _MockTxRepo txRepo;
  late _MockCategoryRepo catRepo;
  late _MockAccountRepo accRepo;
  late _MockCurrencyRepo curRepo;

  late StreamController<List<Transaction>> dayCtrl;
  late StreamController<List<DateTime>> activityCtrl;
  late StreamController<Map<String, ({int expense, int income})>>
  todayTotalsCtrl;
  late StreamController<Map<String, int>> monthNetCtrl;
  late StreamController<List<Category>> categoriesCtrl;
  late StreamController<List<Account>> accountsCtrl;
  late StreamController<List<Currency>> currenciesCtrl;

  setUp(() {
    txRepo = _MockTxRepo();
    catRepo = _MockCategoryRepo();
    accRepo = _MockAccountRepo();
    curRepo = _MockCurrencyRepo();
    dayCtrl = StreamController.broadcast();
    activityCtrl = StreamController.broadcast();
    todayTotalsCtrl = StreamController.broadcast();
    monthNetCtrl = StreamController.broadcast();
    categoriesCtrl = StreamController.broadcast();
    accountsCtrl = StreamController.broadcast();
    currenciesCtrl = StreamController.broadcast();

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
    ).thenAnswer((_) => categoriesCtrl.stream);
    when(
      () => accRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => accountsCtrl.stream);
    when(
      () => curRepo.watchAll(includeTokens: true),
    ).thenAnswer((_) => currenciesCtrl.stream);
  });

  tearDown(() async {
    await dayCtrl.close();
    await activityCtrl.close();
    await todayTotalsCtrl.close();
    await monthNetCtrl.close();
    await categoriesCtrl.close();
    await accountsCtrl.close();
    await currenciesCtrl.close();
  });

  Widget makeApp({Size size = const Size(400, 800)}) {
    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
        currencyRepositoryProvider.overrideWithValue(curRepo),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, _) => const _StubFormScreen(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (_, _) => const _StubFormScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> seedAll(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
    currenciesCtrl.add([_usd]);
    categoriesCtrl.add([_cat(id: 1)]);
    accountsCtrl.add([_acc(id: 1)]);
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'WH01: first-run empty state shows homeEmptyTitle + homeEmptyCta',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await seedAll(tester);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Log first transaction'), findsOneWidget);
    },
  );

  testWidgets(
    'WH02: per-day list renders rows + summary strip with USD chips',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      dayCtrl.add([
        _tx(id: 1, date: todayMidnight.add(const Duration(hours: 9))),
      ]);
      activityCtrl.add([todayMidnight]);
      todayTotalsCtrl.add(const {'USD': (expense: 100, income: 0)});
      monthNetCtrl.add(const {'USD': -100});
      await tester.pump(const Duration(milliseconds: 200));

      // Summary strip USD chip group present.
      expect(find.text('USD'), findsOneWidget);
      // Today expense chip rendered.
      expect(find.text('Today expense: '), findsOneWidget);
    },
  );

  testWidgets('WH03: gap-day with prior history shows per-day empty title', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await seedAll(tester);

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final yesterday = todayMidnight.subtract(const Duration(days: 1));

    // History exists, but nothing today.
    dayCtrl.add(const []);
    activityCtrl.add([yesterday]);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No transactions on this day'), findsOneWidget);
  });

  testWidgets(
    'WH04: archived category metadata still renders on historical row',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pump(const Duration(milliseconds: 50));

      // Emit transaction streams FIRST so the controller produces Data
      // and the screen builds — that subscribes the autoDispose lookup
      // providers, which then receive the lookup-stream emissions.
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      dayCtrl.add([
        _tx(id: 1, date: todayMidnight, categoryId: 7, accountId: 7),
      ]);
      activityCtrl.add([todayMidnight]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 100));

      // Now emit lookups. Archived category + archived account, still
      // resolved by `watchAll(includeArchived: true)`.
      currenciesCtrl.add([_usd]);
      categoriesCtrl.add([
        _cat(id: 7, customName: 'Old food', isArchived: true),
      ]);
      accountsCtrl.add([_acc(id: 7, name: 'Old wallet', isArchived: true)]);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Old food'), findsOneWidget);
      expect(find.textContaining('Old wallet'), findsOneWidget);
    },
  );

  testWidgets('WH05: >=600dp tablet renders the two-pane layout', (
    tester,
  ) async {
    // Set a wide media size so LayoutBuilder picks the >=600dp branch.
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp());
    await seedAll(tester);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
    activityCtrl.add([todayMidnight]);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 200));

    // The two-pane layout uses a VerticalDivider; the single-pane
    // version doesn't.
    expect(find.byType(VerticalDivider), findsOneWidget);
  });
}

class _StubFormScreen extends StatelessWidget {
  const _StubFormScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
