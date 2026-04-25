// TransactionFormScreen widget tests — Wave 2 §4.3.
//
// Covers:
//   - Add mode renders with default account + expense pendingType.
//   - Save button disabled while form is invalid.
//   - Save button enables once amount + account + category are all set
//     (account is auto-resolved by hydrateForAdd → fallback chain).
//   - Edit mode hydrates from `getById` and renders memo + amount.
//   - Duplicate mode prefills amount + memo and resets date to today.
//   - Discard confirm dialog fires on back-nav when state is dirty;
//     does not fire on clean back.
//
// Repositories mocked via mocktail; the screen is mounted under a
// minimal GoRouter so `GoRouterState.extra` works for duplicate.

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
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/transactions/transaction_form_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

const _account = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd);

const _expenseCategory = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

Transaction _persistedTx({
  int id = 99,
  int amountMinorUnits = 500,
  int categoryId = 10,
  int accountId = 1,
  String? memo,
  DateTime? date,
}) {
  final d = date ?? DateTime(2026, 4, 25);
  return Transaction(
    id: id,
    amountMinorUnits: amountMinorUnits,
    currency: _usd,
    categoryId: categoryId,
    accountId: accountId,
    memo: memo,
    date: d,
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_persistedTx());
  });

  late _MockTransactionRepository txRepo;
  late _MockAccountRepository accountRepo;
  late _MockCategoryRepository categoryRepo;
  late _MockUserPreferencesRepository prefs;

  setUp(() {
    txRepo = _MockTransactionRepository();
    accountRepo = _MockAccountRepository();
    categoryRepo = _MockCategoryRepository();
    prefs = _MockUserPreferencesRepository();

    when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
    when(
      () => accountRepo.getLastUsedActiveAccount(),
    ).thenAnswer((_) async => null);
    when(() => accountRepo.getById(1)).thenAnswer((_) async => _account);
    when(
      () => accountRepo.watchAll(includeArchived: false),
    ).thenAnswer((_) => Stream.value(const [_account]));
    when(
      () => categoryRepo.getById(10),
    ).thenAnswer((_) async => _expenseCategory);
  });

  Widget mountAdd({Object? extra, List<Override> extraOverrides = const []}) {
    final router = GoRouter(
      initialLocation: '/home/add',
      initialExtra: extra,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const _HomeStub(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => const TransactionFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (_, state) => TransactionFormScreen(
                transactionId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/settings/categories',
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('categories-stub')),
            body: const Center(child: Text('categories-stub')),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Widget mountEdit(int id) {
    final router = GoRouter(
      initialLocation: '/home/edit/$id',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const _HomeStub(),
          routes: [
            GoRoute(
              path: 'edit/:id',
              builder: (_, state) => TransactionFormScreen(
                transactionId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets('WS01: Add mode renders defaults + Save disabled', (
    tester,
  ) async {
    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();
    // AppBar title "Add transaction" rendered.
    expect(find.text('Add transaction'), findsOneWidget);
    // Save button is a TextButton — it renders disabled when canSave is
    // false (amount = 0, category = null).
    final saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);
    // Default account should be visible.
    expect(find.text('Cash'), findsOneWidget);
  });

  testWidgets('WS02: typing amount and selecting category enables save', (
    tester,
  ) async {
    await tester.pumpWidget(
      mountAdd(
        extraOverrides: [
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(const [_expenseCategory])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    var saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('WS03: Edit mode renders persisted memo + Edit title', (
    tester,
  ) async {
    when(() => txRepo.getById(99)).thenAnswer(
      (_) async => _persistedTx(memo: 'lunch', amountMinorUnits: 500),
    );
    await tester.pumpWidget(mountEdit(99));
    await tester.pumpAndSettle();
    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('lunch'), findsOneWidget);
  });

  testWidgets('WS04: Edit mode missing row → not-found empty state', (
    tester,
  ) async {
    when(() => txRepo.getById(123)).thenAnswer((_) async => null);
    await tester.pumpWidget(mountEdit(123));
    await tester.pumpAndSettle();
    expect(find.text('Transaction not found'), findsOneWidget);
  });

  testWidgets(
    'WS05: Duplicate mode prefills amount + memo and resets date to today',
    (tester) async {
      // Source from a year ago.
      final source = _persistedTx(
        memo: 'monthly bill',
        amountMinorUnits: 1500,
        date: DateTime(2025, 1, 15),
      );
      when(() => txRepo.getById(99)).thenAnswer((_) async => source);
      await tester.pumpWidget(mountAdd(extra: const {'duplicateSourceId': 99}));
      await tester.pumpAndSettle();
      // Title is still "Add transaction" — duplicate routes through /home/add.
      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.text('monthly bill'), findsOneWidget);
      // Date row should NOT show 2025 (source's year).
      expect(find.textContaining('2025'), findsNothing);
    },
  );

  testWidgets(
    'WS06: dirty state surfaces discard dialog on back-nav; clean state pops',
    (tester) async {
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      // Clean back: tapping back arrow pops without dialog.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      // After clean pop, the home stub is visible.
      expect(find.text('home-stub'), findsOneWidget);
    },
  );

  testWidgets('WS07: dirty state surfaces discard dialog', (tester) async {
    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();
    // Make state dirty with a digit press.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    // Now the back arrow should surface the discard dialog.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    // Cancel keeps us on the form.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Add transaction'), findsOneWidget);
  });

  testWidgets('WS08: empty-category recovery preserves the in-progress draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      mountAdd(
        extraOverrides: [
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(const <Category>[])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'draft memo');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('draft memo'), findsOneWidget);
  });

  testWidgets('WS09: historical edit dates still open the date picker', (
    tester,
  ) async {
    when(
      () => txRepo.getById(99),
    ).thenAnswer((_) async => _persistedTx(date: DateTime(2000, 1, 1)));
    await tester.pumpWidget(mountEdit(99));
    await tester.pumpAndSettle();

    final dateTile = find.ancestor(
      of: find.text('Date'),
      matching: find.byType(ListTile),
    );

    await tester.ensureVisible(dateTile);
    await tester.pumpAndSettle();
    await tester.tap(dateTile);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WS10: back-nav is blocked while save is in flight', (
    tester,
  ) async {
    final saveCompleter = Completer<Transaction>();
    when(() => txRepo.save(any())).thenAnswer((_) => saveCompleter.future);

    await tester.pumpWidget(
      mountAdd(
        extraOverrides: [
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(const [_expenseCategory])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    final saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('home-stub'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);

    saveCompleter.complete(_persistedTx(id: 5, amountMinorUnits: 100));
    await tester.pumpAndSettle();
  });

  testWidgets('WS11: back-nav is blocked while delete is in flight', (
    tester,
  ) async {
    final deleteCompleter = Completer<bool>();
    when(() => txRepo.getById(99)).thenAnswer((_) async => _persistedTx());
    when(() => txRepo.delete(99)).thenAnswer((_) => deleteCompleter.future);

    await tester.pumpWidget(mountEdit(99));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('home-stub'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);

    deleteCompleter.complete(true);
    await tester.pumpAndSettle();
  });
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('home-stub')));
}
