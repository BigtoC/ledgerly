// HomeScreen widget tests — Wave 3 §4.3.
//
// Covers:
//   - First-run empty state renders `homeEmptyTitle` + `homeEmptyCta`.
//   - Per-day list renders rows + summary strip per currency.
//   - Per-day empty state after navigating to a gap day.
//   - >=600dp tablet stays single-pane (WH10).
//   - Archived category metadata still resolves on historical rows.
//   - A horizontal fling over a transaction row steps the selected day.
//
// Repositories are mocked via `mocktail`; no live DB. The form route
// is short-circuited so we don't need a real router.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/exchange_rates_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/utils/date_helpers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/pending_transaction.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/ui/features/home/views/home_screen.dart';
import 'package:ledgerly/ui/features/home/views/pending_snack_bars.dart';
import 'package:ledgerly/ui/features/home/views/day_navigation_header.dart';
import 'package:ledgerly/ui/features/home/views/summary_strip.dart';
import 'package:ledgerly/ui/features/home/views/transaction_tile.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

import '../../../support/text_scale.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockAccountRepo extends Mock implements AccountRepository {}

class _MockCurrencyRepo extends Mock implements CurrencyRepository {}

class _MockShoppingListRepo extends Mock implements ShoppingListRepository {}

class _MockPendingRepo extends Mock implements PendingTransactionRepository {}

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

Category _cat({required int id, String? customName, bool isArchived = false}) =>
    Category(
      id: id,
      icon: 'restaurant',
      color: 0,
      type: CategoryType.expense,
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

@Dependencies([initialDefaultCurrency, defaultCurrency, exchangeRates])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  late _MockTxRepo txRepo;
  late _MockCategoryRepo catRepo;
  late _MockAccountRepo accRepo;
  late _MockCurrencyRepo curRepo;
  late _MockShoppingListRepo slRepo;
  late _MockPendingRepo pendingRepo;

  late StreamController<List<Transaction>> dayCtrl;
  late StreamController<List<DateTime>> activityCtrl;
  late StreamController<DailyTotals> todayTotalsCtrl;
  late StreamController<Map<String, int>> monthNetCtrl;
  late StreamController<List<Category>> categoriesCtrl;
  late StreamController<List<Account>> accountsCtrl;
  late StreamController<List<Currency>> currenciesCtrl;

  setUp(() {
    txRepo = _MockTxRepo();
    catRepo = _MockCategoryRepo();
    accRepo = _MockAccountRepo();
    curRepo = _MockCurrencyRepo();
    slRepo = _MockShoppingListRepo();
    pendingRepo = _MockPendingRepo();
    when(() => slRepo.watchCount()).thenAnswer((_) => Stream.value(0));
    when(() => pendingRepo.watchAll())
        .thenAnswer((_) => Stream.value(const []));
    when(() => pendingRepo.approve(any()))
        .thenAnswer((_) async => throw UnimplementedError());
    when(() => pendingRepo.reject(any())).thenAnswer((_) async {});
    dayCtrl = StreamController.broadcast();
    activityCtrl = StreamController.broadcast();
    todayTotalsCtrl = StreamController.broadcast();
    monthNetCtrl = StreamController.broadcast();
    categoriesCtrl = StreamController.broadcast();
    accountsCtrl = StreamController.broadcast();
    currenciesCtrl = StreamController.broadcast();

    when(() => txRepo.watchByDay(any())).thenAnswer((_) => dayCtrl.stream);
    when(() => txRepo.watchDaysWithActivity())
        .thenAnswer((_) => activityCtrl.stream);
    when(() => txRepo.watchDailyTotalsByType(any()))
        .thenAnswer((_) => todayTotalsCtrl.stream);
    when(() => txRepo.watchMonthNetByCurrency(any()))
        .thenAnswer((_) => monthNetCtrl.stream);
    when(() => catRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => categoriesCtrl.stream);
    when(() => accRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => accountsCtrl.stream);
    when(() => curRepo.watchAll(includeTokens: true))
        .thenAnswer((_) => currenciesCtrl.stream);
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

  @Dependencies([initialDefaultCurrency, defaultCurrency, exchangeRates])
  Widget makeApp({double? textScale}) {
    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
        accountRepositoryProvider.overrideWithValue(accRepo),
        currencyRepositoryProvider.overrideWithValue(curRepo),
        shoppingListRepositoryProvider.overrideWithValue(slRepo),
        pendingTransactionRepositoryProvider.overrideWithValue(pendingRepo),
      ],
      child: MaterialApp.router(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: textScale == null ? null : textScaleBuilder(textScale),
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const PendingSnackBars(child: HomeScreen()),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, _) => const _StubFormScreen(label: 'ADD_ROUTE'),
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

      // Summary card renders the day net, month net and expense tile.
      expect(find.text('Day net'), findsOneWidget);
      expect(find.text('Month net'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    },
  );

  testWidgets('WH02c: transaction list card has no shadow', (tester) async {
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

    final card = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.byType(TransactionTile),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .single;
    expect(card.boxShadow, isNull);
  });

  testWidgets(
    'WH02b: no-history Home still shows pending section when rows exist',
    (tester) async {
      // Pending date must match today's view (PendingSection is day-scoped
      // since 2026-05-09); a past-dated row would correctly be hidden on
      // today's default Home view and break this test's intent.
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      when(() => pendingRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          PendingTransaction(
            id: 1,
            source: 'recurring',
            amountMinorUnits: 1599,
            currency: _usd,
            categoryId: 1,
            accountId: 1,
            memo: 'Netflix',
            date: todayMidnight,
            fetchedAt: todayMidnight,
            recurringRuleId: 1,
          ),
        ]),
      );

      await tester.pumpWidget(makeApp());
      await seedAll(tester);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('No transactions yet'), findsNothing);
    },
  );

  testWidgets(
    'WH02d: no-history Home with only a past-dated pending row shows the '
    'empty state',
    (tester) async {
      // Recurring catch-up inserts rows dated on missed due days. The
      // day-scoped PendingSection hides them on today's view, so Home must
      // not switch to the pending-only body for them (it would be blank).
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      when(() => pendingRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          PendingTransaction(
            id: 1,
            source: 'recurring',
            amountMinorUnits: 1599,
            currency: _usd,
            categoryId: 1,
            accountId: 1,
            memo: 'Netflix',
            date: yesterday,
            fetchedAt: yesterday,
            recurringRuleId: 1,
          ),
        ]),
      );

      await tester.pumpWidget(makeApp());
      await seedAll(tester);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Log first transaction'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
    },
  );

  testWidgets(
    'WH02e: Undo restores a skipped row after Home falls back to the empty '
    'state',
    (tester) async {
      // Skipping today's only visible row swaps the pending-only body for
      // the empty state, which unmounts PendingSection while its Undo
      // snackbar is still showing. Undo must still reach the controller.
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      PendingTransaction pending(int id, String memo, DateTime date) =>
          PendingTransaction(
            id: id,
            source: 'recurring',
            amountMinorUnits: 1599,
            currency: _usd,
            categoryId: 1,
            accountId: 1,
            memo: memo,
            date: date,
            fetchedAt: date,
            recurringRuleId: id,
          );
      when(() => pendingRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          pending(1, 'Netflix', todayMidnight),
          pending(2, 'Spotify', yesterday),
        ]),
      );

      await tester.pumpWidget(makeApp());
      await seedAll(tester);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Netflix'), findsOneWidget);

      await tester.drag(find.text('Netflix'), const Offset(-300, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Skip once'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('No transactions yet'), findsOneWidget);

      // Invoke the action directly: in the 800x600 test view the snackbar
      // sits below the FAB row, outside hit-testable bounds.
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Netflix'), findsOneWidget);

      // Let the undo window lapse: the skip must not commit.
      await tester.pump(const Duration(seconds: 5));
      verifyNever(() => pendingRepo.reject(1));
    },
  );

  testWidgets(
    'WH02f: a skip that fails after Home falls back to the empty state '
    'still shows the error',
    (tester) async {
      // Skipping today's only row unmounts PendingSection. The skip commits
      // after the undo window; its failure must still reach a snackbar.
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      when(() => pendingRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          PendingTransaction(
            id: 1,
            source: 'recurring',
            amountMinorUnits: 1599,
            currency: _usd,
            categoryId: 1,
            accountId: 1,
            memo: 'Netflix',
            date: todayMidnight,
            fetchedAt: todayMidnight,
            recurringRuleId: 1,
          ),
        ]),
      );
      when(() => pendingRepo.reject(1))
          .thenAnswer((_) async => throw StateError('reject failed'));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);
      dayCtrl.add(const []);
      activityCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Netflix'), findsOneWidget);

      await tester.drag(find.text('Netflix'), const Offset(-300, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Skip once'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('No transactions yet'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      verify(() => pendingRepo.reject(1)).called(1);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('WH03: gap-day with prior history shows homeEmptyDayMessage', (
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

    // Gap-day card uses homeEmptyDayMessage (localized "No transaction")
    expect(find.text('No transaction'), findsOneWidget);
  });

  testWidgets('WH03c: day-nav row sits above the summary card and owns the '
      'jump-to-today button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp());
    await seedAll(tester);

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    dayCtrl.add(const []);
    activityCtrl.add([todayMidnight]);
    todayTotalsCtrl.add(const {'USD': (expense: 100, income: 0)});
    monthNetCtrl.add(const {'USD': -100});
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.getRect(find.byType(DayNavigationHeader)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(SummaryStrip)).top),
    );
    expect(
      find.descendant(
        of: find.byType(DayNavigationHeader),
        matching: find.text('Today'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SummaryStrip),
        matching: find.byType(TextButton),
      ),
      findsNothing,
    );
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

      // A memo-less row is titled by its category; the account name is
      // no longer shown on Home rows.
      expect(find.text('Old food'), findsOneWidget);
      expect(find.textContaining('Old wallet'), findsNothing);
    },
  );

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

    await tester.tap(find.byType(TransactionTile).first);
    await tester.pumpAndSettle();

    expect(find.text('EDIT_ROUTE_1'), findsOneWidget);
  });

  testWidgets(
    'WH10: tablet single-pane layout renders without VerticalDivider',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      dayCtrl.add([_tx(id: 1, date: today)]);
      activityCtrl.add([today]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(VerticalDivider), findsNothing);
      expect(find.text('Today'), findsOneWidget);
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

  // M6 Unit 8 — accessibility: PRD a11y requirement that all Home
  // surfaces (empty state, summary strip, day-nav header, transaction
  // row) survive 2× text scale. Both the empty-state path and the
  // data-state path are exercised so the audit doc's follow-up #1
  // (RenderFlex overflows in `SummaryStrip` + `DayNavigationHeader`)
  // is closed by behaviour, not by inspection.
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

  testWidgets('WH15: Home data state survives 2× text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp(textScale: 2.0));
    await seedAll(tester);

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
    activityCtrl.add([todayMidnight]);
    // Long formatted amounts (large minor-unit values) stress the
    // summary card most: at 2× its net and tile pairs stack so
    // `-$12,345.67` keeps a full-width line.
    todayTotalsCtrl.add(const {'USD': (expense: 1234567, income: 0)});
    monthNetCtrl.add(const {'USD': -1234567});
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Add transaction'), findsOneWidget);
  });

  testWidgets(
    'WH16: boundary swipe at today does not animate when canGoNext is false',
    (tester) async {
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

      // Already on today — canGoNext is false. Swipe left (newer) should
      // be a no-op: no animation, no state change.
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(-900, 0),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // The day header should still show today's date — no navigation
      // occurred.
      expect(
        find.text(DateHelpers.formatDayHeader(todayMidnight, 'en')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WH17: jump-to-today button navigates back to today', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(makeApp());
    await seedAll(tester);

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final yesterday = todayMidnight.subtract(const Duration(days: 1));

    // Emit initial state with activity on today and yesterday
    dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
    activityCtrl.add([todayMidnight, yesterday]);
    todayTotalsCtrl.add(const {'USD': (expense: 100, income: 0)});
    monthNetCtrl.add(const {'USD': -100});
    await tester.pump(const Duration(milliseconds: 200));

    // Navigate to yesterday using prev button
    final prevButton = find.widgetWithIcon(IconButton, Icons.chevron_left);
    await tester.tap(prevButton);
    await tester.pump(const Duration(milliseconds: 50));
    dayCtrl.add([]);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 200));

    // Jump to today button should be visible
    expect(find.text('Jump to today'), findsOneWidget);

    // Tap it
    await tester.tap(find.text('Jump to today'));
    await tester.pump(const Duration(milliseconds: 50));
    dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
    todayTotalsCtrl.add(const {'USD': (expense: 100, income: 0)});
    monthNetCtrl.add(const {'USD': -100});
    await tester.pump(const Duration(milliseconds: 400));

    // After the transition, today's date should be the header label
    expect(
      find.text(DateHelpers.formatDayHeader(todayMidnight, 'en')),
      findsOneWidget,
    );
    // Button still renders, reads "Today" and is disabled when on today
    expect(find.text('Jump to today'), findsNothing);
    final jumpBtn = tester.widget<TextButton>(
      find.ancestor(of: find.text('Today'), matching: find.byType(TextButton)),
    );
    expect(jumpBtn.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'WH18: queued rapid prev taps land on later day after slow drain',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final activity = <DateTime>[
        for (var i = 7; i >= 0; i--) todayMidnight.subtract(Duration(days: i)),
      ];
      dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
      activityCtrl.add(activity);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      final prevButton = find.widgetWithIcon(IconButton, Icons.chevron_left);

      await tester.tap(prevButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(prevButton);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(prevButton);
      await tester.pump(const Duration(milliseconds: 10));

      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        dayCtrl.add([]);
        todayTotalsCtrl.add(const {});
        monthNetCtrl.add(const {});
        await tester.pump(const Duration(milliseconds: 350));
      }

      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNothing);
    },
  );

  testWidgets(
    'WH19: a right fling over a transaction row steps to the previous day',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = todayMidnight.subtract(const Duration(days: 1));
      dayCtrl.add([_tx(id: 1, date: todayMidnight)]);
      activityCtrl.add([todayMidnight, yesterday]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      await tester.fling(
        find.byType(TransactionTile),
        const Offset(300, 0),
        1000,
      );
      await tester.pump(const Duration(milliseconds: 50));
      dayCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pumpAndSettle();

      expect(
        find.text(DateHelpers.formatDayHeader(yesterday, 'en')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WH20: a left fling over a transaction row steps to the next day',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(makeApp());
      await seedAll(tester);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = todayMidnight.subtract(const Duration(days: 1));
      dayCtrl.add(const []);
      activityCtrl.add([todayMidnight, yesterday]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
      await tester.pump(const Duration(milliseconds: 50));
      dayCtrl.add([_tx(id: 2, date: yesterday)]);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pumpAndSettle();
      expect(find.byType(TransactionTile), findsOneWidget);

      await tester.fling(
        find.byType(TransactionTile),
        const Offset(-300, 0),
        1000,
      );
      await tester.pump(const Duration(milliseconds: 50));
      dayCtrl.add(const []);
      todayTotalsCtrl.add(const {});
      monthNetCtrl.add(const {});
      await tester.pumpAndSettle();

      expect(
        find.text(DateHelpers.formatDayHeader(todayMidnight, 'en')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  // Drift re-emits at once for each new selected day; the mocks need a feed.
  void feed() {
    dayCtrl.add(const []);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
  }

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      feed();
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  // Settles on yesterday, then queues back steps with three quick right
  // flings over the body: the swipe detector sits outside the slide, so they
  // queue mid-slide. Ends about 250 ms into the running slide, when the
  // sliding header is back in reach of a tap.
  @Dependencies([initialDefaultCurrency, defaultCurrency, exchangeRates])
  Future<DateTime> queueBackSteps(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(makeApp());
    await seedAll(tester);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    activityCtrl.add([today]);
    feed();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pump(const Duration(milliseconds: 50));
    feed();
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      // A fast fling from a fixed point: the body is sliding off-centre, and
      // flingFrom would pump frames until the running slide ends.
      final g = await tester.startGesture(const Offset(150, 500));
      for (var m = 1; m <= 5; m++) {
        await g.moveBy(
          const Offset(40, 0),
          timeStamp: Duration(milliseconds: 10 * m),
        );
      }
      await g.up(timeStamp: const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 20));
      feed();
    }
    await tester.pump(const Duration(milliseconds: 190));
    return today;
  }

  testWidgets('WH22: back steps still queued when jumping to today never run '
      'later', (tester) async {
    final today = await queueBackSteps(tester);

    await tester.tap(find.text('Jump to today'));
    await drain(tester);
    expect(find.text(DateHelpers.formatDayHeader(today, 'en')), findsOneWidget);

    // The next ‹ steps back exactly one day: no leftover steps run.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await drain(tester);
    expect(
      find.text(
        DateHelpers.formatDayHeader(
          DateTime(today.year, today.month, today.day - 1),
          'en',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'WH23: back steps still queued when picking a date never run later',
    (tester) async {
      await queueBackSteps(tester);

      await tester.tap(find.byKey(const ValueKey('homeDayHeader.pickDay')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Pick the 1st of the shown month, then confirm.
      final shown = tester
          .widget<DatePickerDialog>(find.byType(DatePickerDialog))
          .initialDate!;
      final picked = DateTime(shown.year, shown.month, 1);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('1'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('OK'));
      await drain(tester);
      expect(
        find.text(DateHelpers.formatDayHeader(picked, 'en')),
        findsOneWidget,
      );

      // The next ‹ steps back exactly one day: no leftover steps run.
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
      await drain(tester);
      expect(
        find.text(
          DateHelpers.formatDayHeader(
            DateTime(picked.year, picked.month, picked.day - 1),
            'en',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WH24: a swipe during the jump-to-today slide steps back on its '
      'own', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(makeApp());
    await seedAll(tester);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    activityCtrl.add([today]);
    feed();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pump(const Duration(milliseconds: 50));
    feed();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jump to today'));
    await tester.pump(const Duration(milliseconds: 50));
    feed();
    // Swipe right (back) while the jump's slide is still running.
    final g = await tester.startGesture(const Offset(150, 500));
    for (var m = 1; m <= 5; m++) {
      await g.moveBy(
        const Offset(40, 0),
        timeStamp: Duration(milliseconds: 10 * m),
      );
    }
    await g.up(timeStamp: const Duration(milliseconds: 60));
    await drain(tester);

    expect(
      find.text(
        DateHelpers.formatDayHeader(
          DateTime(today.year, today.month, today.day - 1),
          'en',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('WH21: transaction rows have no overflow menu or swipe pane', (
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

    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.byKey(const ValueKey('homeTile:1:menu')), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(
      find.descendant(
        of: find.byType(TransactionTile),
        matching: find.byType(Slidable),
      ),
      findsNothing,
    );
  });

  for (final reduceMotion in [false, true]) {
    testWidgets(
      'WH25: the day switch ${reduceMotion ? 'does not slide' : 'slides'}'
      ' with Reduce Motion ${reduceMotion ? 'on' : 'off'}',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(reduceMotion: reduceMotion);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(makeApp());
        await seedAll(tester);
        final now = DateTime.now();
        activityCtrl.add([DateTime(now.year, now.month, now.day)]);
        feed();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
        await tester.pump(const Duration(milliseconds: 50));
        feed();
        // About halfway through the 280 ms slide.
        await tester.pump(const Duration(milliseconds: 140));
        final dx = tester
            .widget<SlideTransition>(
              find
                  .ancestor(
                    of: find.byType(DayNavigationHeader),
                    matching: find.byType(SlideTransition),
                  )
                  .first,
            )
            .position
            .value
            .dx;
        expect(dx, reduceMotion ? 0 : lessThan(0));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('WH26: pulling the day list down at the top bounces', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await seedAll(tester);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    dayCtrl.add([for (var id = 1; id <= 20; id++) _tx(id: id, date: today)]);
    activityCtrl.add([today]);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 200));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 100));
    expect(
      Scrollable.of(tester.element(find.byType(DayNavigationHeader)))
          .position
          .pixels,
      lessThan(0),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('WH27: pulling a pending-only day down at the top bounces', (
    tester,
  ) async {
    // Short enough that one pending row overflows; a page that fits does
    // not scroll, so it cannot bounce.
    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    when(() => pendingRepo.watchAll()).thenAnswer(
      (_) => Stream.value([
        PendingTransaction(
          id: 1,
          source: 'recurring',
          amountMinorUnits: 1599,
          currency: _usd,
          categoryId: 1,
          accountId: 1,
          memo: 'Netflix',
          date: today,
          fetchedAt: today,
          recurringRuleId: 1,
        ),
      ]),
    );
    await tester.pumpWidget(makeApp());
    await seedAll(tester);
    dayCtrl.add(const []);
    activityCtrl.add(const []);
    todayTotalsCtrl.add(const {});
    monthNetCtrl.add(const {});
    await tester.pump(const Duration(milliseconds: 200));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 100));
    expect(
      Scrollable.of(tester.element(find.text('Netflix'))).position.pixels,
      lessThan(0),
    );
    await tester.pump(const Duration(seconds: 1));
  });
}

class const _StubFormScreen({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
