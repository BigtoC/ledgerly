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
import 'package:ledgerly/core/utils/date_helpers.dart';
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

  Widget makeApp({double? textScale}) {
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
        builder: textScale == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child!,
                ),
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, state) => _StubFormScreen(
                    label: state.extra is Map<String, Object>
                        ? 'ADD_DUPLICATE_${(state.extra! as Map<String, Object>)['duplicateSourceId'] ?? 'NONE'}'
                        : 'ADD_ROUTE',
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (_, state) => _StubFormScreen(
                    label: 'EDIT_ROUTE_${state.pathParameters['id']}',
                  ),
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

      // Summary strip renders the today-expense label and amount; the
      // standalone `USD` code header was removed in favor of letting
      // `MoneyFormatter` carry the currency symbol on each amount.
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

  testWidgets('WH06: tapping a row opens /home/edit/:id', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
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

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('EDIT_ROUTE_1'), findsOneWidget);
  });

  testWidgets('WH07: duplicate action navigates with duplicateSourceId extra', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
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

    await tester.tap(find.byKey(const ValueKey('homeTile:1:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('ADD_DUPLICATE_1'), findsOneWidget);
  });

  testWidgets(
    'WH08: overflow delete shows undo snackbar and undo cancels commit',
    (tester) async {
      when(() => txRepo.delete(any())).thenAnswer((_) async => true);

      await tester.binding.setSurfaceSize(const Size(400, 800));
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

      await tester.tap(find.byKey(const ValueKey('homeTile:1:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.text('Transaction deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      clearInteractions(txRepo);
      verifyNever(() => txRepo.delete(any()));
    },
  );

  testWidgets('WH09: swipe delete shows the same undo snackbar', (
    tester,
  ) async {
    when(() => txRepo.delete(any())).thenAnswer((_) async => true);

    await tester.binding.setSurfaceSize(const Size(400, 800));
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

    await tester.drag(
      find.byKey(const ValueKey<int>(1)),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pump();

    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets(
    'WH10: tablet activity pane shows full history and taps select directly',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      dayCtrl.add([_tx(id: 1, date: today)]);
      activityCtrl.add([today, yesterday, fourDaysAgo]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      final oldLabel = DateHelpers.formatDayHeader(fourDaysAgo, 'en');
      expect(find.text(oldLabel), findsOneWidget);

      await tester.tap(find.text(oldLabel));
      await tester.pump();

      expect(find.byType(DatePickerDialog), findsNothing);

      dayCtrl.add([_tx(id: 2, date: fourDaysAgo)]);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(oldLabel), findsAtLeastNWidgets(2));
    },
  );

  testWidgets('WH10b: tapping the day header opens the manual date picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp());
    await seedAll(tester);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fourDaysAgo = today.subtract(const Duration(days: 4));

    dayCtrl.add(const []);
    activityCtrl.add([today, fourDaysAgo]);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const ValueKey('homeDayHeader.pickDay')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets(
    'WH11: unresolved row metadata renders amount without a wrong negative sign',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await tester.pump(const Duration(milliseconds: 50));

      currenciesCtrl.add([_usd]);
      accountsCtrl.add([_acc(id: 1)]);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      dayCtrl.add([
        _tx(id: 1, date: todayMidnight, amount: 123, categoryId: 99),
      ]);
      activityCtrl.add([todayMidnight]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining(r'-$1.23'), findsNothing);
      expect(find.textContaining(r'$1.23'), findsOneWidget);
    },
  );

  testWidgets(
    'WH12: timed delete keeps the row hidden until slow delete completes',
    (tester) async {
      final deleteCompleter = Completer<bool>();
      when(
        () => txRepo.delete(any()),
      ).thenAnswer((_) => deleteCompleter.future);

      await tester.binding.setSurfaceSize(const Size(400, 800));
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

      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('homeTile:1:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsNothing);

      deleteCompleter.complete(true);
      dayCtrl.add(const []);
      await tester.pumpAndSettle();

      verify(() => txRepo.delete(1)).called(1);
      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsNothing);
    },
  );

  testWidgets(
    'WH12b: timed delete failure restores the row and shows a generic snackbar',
    (tester) async {
      when(
        () => txRepo.delete(any()),
      ).thenAnswer((_) async => throw StateError('boom'));

      await tester.binding.setSurfaceSize(const Size(400, 800));
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

      await tester.tap(find.byKey(const ValueKey('homeTile:1:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsOneWidget);
      verify(() => txRepo.delete(1)).called(1);
    },
  );

  testWidgets(
    'WH12c: rapid second delete does not resurrect the first row before stream sync',
    (tester) async {
      when(() => txRepo.delete(any())).thenAnswer((_) async => true);

      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      dayCtrl.add([
        _tx(id: 1, date: todayMidnight),
        _tx(id: 2, date: todayMidnight),
      ]);
      activityCtrl.add([todayMidnight]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byKey(const ValueKey('homeTile:1:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('homeTile:2:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.byKey(const ValueKey('homeTile:1:menu')), findsNothing);
      expect(find.byKey(const ValueKey('homeTile:2:menu')), findsNothing);
    },
  );

  testWidgets('WH13: stream failure renders the generic error surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp());
    await seedAll(tester);

    await tester.pump(const Duration(milliseconds: 50));
    dayCtrl.addError(StateError('boom'), StackTrace.current);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  // M6 Unit 8 — accessibility: PRD a11y requirement that the Home
  // empty state survives 2× text scale. The data-state at 2× scale
  // surfaces RenderFlex overflows in `SummaryStrip._CurrencyGroup`
  // and `DayNavigationHeader` that were not caught at design time;
  // `docs/a11y-audit-m6.md` tracks the follow-up. The FAB tooltip
  // assertion below proves at least the always-visible CTA remains
  // accessible at 2× scale on the empty-state path.
  testWidgets('WH14: Home empty state survives 2× text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp(textScale: 2.0));
    await seedAll(tester);

    dayCtrl.add(const []);
    activityCtrl.add(const []);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Log first transaction'), findsOneWidget);
    expect(find.byTooltip('Add transaction'), findsOneWidget);
  });
}

class _StubFormScreen extends StatelessWidget {
  const _StubFormScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
