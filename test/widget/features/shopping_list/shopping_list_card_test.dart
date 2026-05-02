// ShoppingListCard widget tests (Task 3).
//
// Exercises the card directly with fake providers and mocked repositories.
// No live DB.
//
// Covers:
//   - Loading state shows inline CircularProgressIndicator.
//   - Error state shows inline error text.
//   - Empty state shows empty-body text and CTA to /home/add.
//   - Non-empty state shows up to 3 rows.
//   - Falls back to category name when memo is empty.
//   - Shows overflow CTA when more than 3 drafts exist.
//   - Row tap navigates to /accounts/shopping-list.
//   - Header View-all CTA navigates to /accounts/shopping-list.
//   - Empty-state CTA navigates to /home/add.
//   - AccountsScreen always renders shopping list card before account section.
//   - AccountsScreen renders shopping list card when accounts list is empty.
//   - Archived account/category still resolves names for preview rows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/shopping_list_item.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/accounts/accounts_controller.dart';
import 'package:ledgerly/features/accounts/accounts_screen.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_controller.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_providers.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_state.dart';
import 'package:ledgerly/features/shopping_list/widgets/shopping_list_card.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────

class _MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockAccountTypeRepository extends Mock
    implements AccountTypeRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

// ── Test fixtures ─────────────────────────────────────────────────────────

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

final _now = DateTime(2026, 5, 2);

ShoppingListItem _item({
  int id = 1,
  int categoryId = 10,
  int accountId = 20,
  String? memo,
  DateTime? draftDate,
}) => ShoppingListItem(
  id: id,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  draftDate: draftDate ?? _now,
  createdAt: _now,
  updatedAt: _now,
);

const _expenseCategory = Category(
  id: 10,
  icon: 'food',
  color: 1,
  type: CategoryType.expense,
  l10nKey: 'category.food',
  customName: 'Groceries',
);

const _seededExpenseCategory = Category(
  id: 11,
  icon: 'food',
  color: 1,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

const _account = Account(
  id: 20,
  name: 'Cash',
  accountTypeId: 1,
  currency: _usd,
);

const _cashType = AccountType(
  id: 1,
  l10nKey: 'accountType.cash',
  icon: 'wallet',
  color: 10,
  defaultCurrency: _usd,
);

Account _a({
  required int id,
  required String name,
  int accountTypeId = 1,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: accountTypeId,
  currency: _usd,
  isArchived: isArchived,
);

AccountWithBalance _wb(Account a) => AccountWithBalance(
  account: a,
  balancesByCurrency: const {},
  affordance: AccountRowAffordance.archive,
);

// ── GoRouter stubs ─────────────────────────────────────────────────────────

class _StubCardRouter {
  static GoRouter build(Widget home) {
    return GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/accounts/shopping-list',
          builder: (_, _) => const Scaffold(body: Text('SHOPPING_LIST_SCREEN')),
        ),
        GoRoute(
          path: '/home/add',
          builder: (_, _) => const Scaffold(body: Text('ADD_TRANSACTION')),
        ),
        GoRoute(
          path: '/accounts/new',
          builder: (_, _) => const Scaffold(body: Text('ADD_ACCOUNT')),
        ),
        GoRoute(
          path: '/accounts/:id',
          builder: (ctx, state) => Scaffold(
            body: Text('EDIT_ACCOUNT_${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  }
}

// ── Fake AccountsController ────────────────────────────────────────────────

class _FakeAccountsController extends AccountsController {
  _FakeAccountsController(this._fixed);
  final AccountsState _fixed;

  @override
  Stream<AccountsState> build() async* {
    yield _fixed;
  }
}

// ── Container helpers ──────────────────────────────────────────────────────

/// Builds a container for ShoppingListCard-only tests (no accounts controller).
ProviderContainer _makeCardContainer({
  required ShoppingListRepository shoppingListRepo,
  required CategoryRepository categoryRepo,
  required AccountRepository accountRepo,
}) {
  final typeRepo = _MockAccountTypeRepository();
  when(
    () => typeRepo.watchAll(includeArchived: any(named: 'includeArchived')),
  ).thenAnswer((_) => Stream.value([]));

  final prefs = _MockUserPreferencesRepository();
  final currencyRepo = _MockCurrencyRepository();
  when(() => currencyRepo.watchAll()).thenAnswer((_) => Stream.value([_usd]));
  when(
    () => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')),
  ).thenAnswer((_) => Stream.value([_usd]));

  return ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(shoppingListRepo),
      shoppingListPreviewProvider.overrideWith((ref) {
        return shoppingListRepo.watchAll().map(
          (items) => (
            preview: items.take(3).toList(growable: false),
            totalCount: items.length,
          ),
        );
      }),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      accountTypeRepositoryProvider.overrideWithValue(typeRepo),
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
    ],
  );
}

/// Builds a container for AccountsScreen tests (with accounts controller).
ProviderContainer _makeAccountsContainer({
  required ShoppingListRepository shoppingListRepo,
  required CategoryRepository categoryRepo,
  required AccountRepository accountRepo,
  required AccountsState fixed,
}) {
  final typeRepo = _MockAccountTypeRepository();
  when(
    () => typeRepo.watchAll(includeArchived: any(named: 'includeArchived')),
  ).thenAnswer((_) => Stream.value([_cashType]));

  final prefs = _MockUserPreferencesRepository();
  final currencyRepo = _MockCurrencyRepository();
  when(() => currencyRepo.watchAll()).thenAnswer((_) => Stream.value([_usd]));
  when(
    () => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')),
  ).thenAnswer((_) => Stream.value([_usd]));

  return ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(shoppingListRepo),
      shoppingListPreviewProvider.overrideWith((ref) {
        return shoppingListRepo.watchAll().map(
          (items) => (
            preview: items.take(3).toList(growable: false),
            totalCount: items.length,
          ),
        );
      }),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      accountTypeRepositoryProvider.overrideWithValue(typeRepo),
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      accountsControllerProvider.overrideWith(
        () => _FakeAccountsController(fixed),
      ),
    ],
  );
}

Widget _wrapCard({required ProviderContainer container, Widget? home}) {
  final widget = home ?? const ShoppingListCard();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _StubCardRouter.build(widget),
    ),
  );
}

Widget _wrapScreen({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _StubCardRouter.build(const AccountsScreen()),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_item());
    registerFallbackValue(_expenseCategory);
    registerFallbackValue(_account);
  });

  // SL01
  testWidgets(
    'ShoppingListCard shows inline loading indicator while preview is loading',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      // Never-completing stream to hold loading state.
      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => const Stream.empty());

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pump(); // one frame to settle l10n

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Shopping list'), findsOneWidget);
    },
  );

  // SL02
  testWidgets(
    'ShoppingListCard shows inline error text on repository error and tapping navigates to /accounts/shopping-list',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.error(Exception('db failure')));

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Shopping list'), findsOneWidget);

      // Tapping the error body navigates to /accounts/shopping-list.
      await tester.tap(find.text('Something went wrong. Please try again.'));
      await tester.pumpAndSettle();

      expect(find.text('SHOPPING_LIST_SCREEN'), findsOneWidget);
    },
  );

  // SL03
  testWidgets(
    'ShoppingListCard shows empty state with CTA to /home/add when no drafts',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([]));

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      expect(find.text('No upcoming expenses saved'), findsOneWidget);
      expect(find.text('Add to shopping list'), findsOneWidget);
    },
  );

  // SL04
  testWidgets('ShoppingListCard shows up to 3 rows for drafts', (tester) async {
    final shoppingListRepo = _MockShoppingListRepository();
    final categoryRepo = _MockCategoryRepository();
    final accountRepo = _MockAccountRepository();

    when(() => shoppingListRepo.watchAll()).thenAnswer(
      (_) => Stream.value([
        _item(id: 1, memo: 'Apples'),
        _item(id: 2, memo: 'Bread'),
        _item(id: 3, memo: 'Milk'),
      ]),
    );
    when(
      () => categoryRepo.getById(any()),
    ).thenAnswer((_) async => _expenseCategory);
    when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

    final container = _makeCardContainer(
      shoppingListRepo: shoppingListRepo,
      categoryRepo: categoryRepo,
      accountRepo: accountRepo,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapCard(container: container));
    await tester.pumpAndSettle();

    expect(find.text('Apples'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
  });

  // SL05
  testWidgets(
    'ShoppingListCard falls back to category name when memo is empty',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_item(id: 1, memo: null)]));
      when(
        () => categoryRepo.getById(10),
      ).thenAnswer((_) async => _expenseCategory);
      when(() => accountRepo.getById(20)).thenAnswer((_) async => _account);

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      // Falls back to customName 'Groceries'
      expect(find.text('Groceries'), findsOneWidget);
    },
  );

  testWidgets(
    'ShoppingListCard localizes seeded category fallback when memo is empty',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(() => shoppingListRepo.watchAll()).thenAnswer(
        (_) => Stream.value([_item(id: 11, categoryId: 11, memo: '')]),
      );
      when(
        () => categoryRepo.getById(11),
      ).thenAnswer((_) async => _seededExpenseCategory);
      when(() => accountRepo.getById(20)).thenAnswer((_) async => _account);

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('category.food'), findsNothing);
    },
  );

  // SL06
  testWidgets(
    'ShoppingListCard shows overflow CTA when more than 3 drafts exist',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      // 5 items total — preview shows 3, overflow = 2.
      when(() => shoppingListRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          _item(id: 1, memo: 'Item 1'),
          _item(id: 2, memo: 'Item 2'),
          _item(id: 3, memo: 'Item 3'),
          _item(id: 4, memo: 'Item 4'),
          _item(id: 5, memo: 'Item 5'),
        ]),
      );
      when(
        () => categoryRepo.getById(any()),
      ).thenAnswer((_) async => _expenseCategory);
      when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      // Shows '2 more' overflow CTA.
      expect(find.textContaining('2 more'), findsOneWidget);
    },
  );

  // SL07
  testWidgets('ShoppingListCard row tap navigates to /accounts/shopping-list', (
    tester,
  ) async {
    final shoppingListRepo = _MockShoppingListRepository();
    final categoryRepo = _MockCategoryRepository();
    final accountRepo = _MockAccountRepository();

    when(
      () => shoppingListRepo.watchAll(),
    ).thenAnswer((_) => Stream.value([_item(id: 1, memo: 'Apples')]));
    when(
      () => categoryRepo.getById(any()),
    ).thenAnswer((_) async => _expenseCategory);
    when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

    final container = _makeCardContainer(
      shoppingListRepo: shoppingListRepo,
      categoryRepo: categoryRepo,
      accountRepo: accountRepo,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapCard(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apples'));
    await tester.pumpAndSettle();

    expect(find.text('SHOPPING_LIST_SCREEN'), findsOneWidget);
  });

  // SL08
  testWidgets(
    'ShoppingListCard header View-all CTA navigates to /accounts/shopping-list',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([]));

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();

      expect(find.text('SHOPPING_LIST_SCREEN'), findsOneWidget);
    },
  );

  // SL09
  testWidgets('ShoppingListCard empty-state CTA navigates to /home/add', (
    tester,
  ) async {
    final shoppingListRepo = _MockShoppingListRepository();
    final categoryRepo = _MockCategoryRepository();
    final accountRepo = _MockAccountRepository();

    when(() => shoppingListRepo.watchAll()).thenAnswer((_) => Stream.value([]));

    final container = _makeCardContainer(
      shoppingListRepo: shoppingListRepo,
      categoryRepo: categoryRepo,
      accountRepo: accountRepo,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapCard(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to shopping list'));
    await tester.pumpAndSettle();

    expect(find.text('ADD_TRANSACTION'), findsOneWidget);
  });

  // SL10
  testWidgets(
    'AccountsScreen always renders shopping list card before account section',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

      final container = _makeAccountsContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
        fixed: AccountsState.data(
          active: [_wb(_a(id: 1, name: 'Cash'))],
          archived: const [],
          defaultAccountId: 1,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapScreen(container: container));
      await tester.pumpAndSettle();

      // Shopping list card title must appear.
      expect(find.text('Shopping list'), findsOneWidget);
      // Account 'Cash' also renders.
      expect(find.text('Cash'), findsAtLeast(1));

      // The shopping list card must be ABOVE the account row in the widget
      // tree — verify by checking render order.
      final shoppingListOffset = tester
          .getTopLeft(find.text('Shopping list'))
          .dy;
      final cashOffset = tester.getTopLeft(find.text('Cash').first).dy;
      expect(shoppingListOffset, lessThan(cashOffset));
    },
  );

  // SL11
  testWidgets(
    'AccountsScreen renders shopping list card when accounts list is empty',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([]));

      final container = _makeAccountsContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
        fixed: const AccountsState.data(
          active: [],
          archived: [],
          defaultAccountId: null,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapScreen(container: container));
      await tester.pumpAndSettle();

      // Shopping list card must be visible even with no accounts.
      expect(find.text('Shopping list'), findsOneWidget);
      // Inline accounts empty state is also shown.
      expect(find.text('No active accounts'), findsOneWidget);
    },
  );

  // SL13
  testWidgets(
    'ShoppingListCard shows formatted amount in trailing text for amount-bearing draft',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      // Item with draftAmountMinorUnits=1200 (USD, decimals=2) → $12.00
      final amountItem = ShoppingListItem(
        id: 1,
        categoryId: 10,
        accountId: 20,
        memo: 'Coffee',
        draftDate: _now,
        draftAmountMinorUnits: 1200,
        draftCurrencyCode: 'USD',
        createdAt: _now,
        updatedAt: _now,
      );

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([amountItem]));
      when(
        () => categoryRepo.getById(10),
      ).thenAnswer((_) async => _expenseCategory);
      when(() => accountRepo.getById(20)).thenAnswer((_) async => _account);
      when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);

      // Override the currencyRepo used by shoppingListCurrencyByCodeProvider.
      final typeRepo = _MockAccountTypeRepository();
      when(
        () => typeRepo.watchAll(includeArchived: any(named: 'includeArchived')),
      ).thenAnswer((_) => Stream.value([]));
      final prefs = _MockUserPreferencesRepository();
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd]));
      when(
        () => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')),
      ).thenAnswer((_) => Stream.value([_usd]));

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingListRepo),
          shoppingListPreviewProvider.overrideWith((ref) {
            return shoppingListRepo.watchAll().map(
              (items) => (
                preview: items.take(3).toList(growable: false),
                totalCount: items.length,
              ),
            );
          }),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          accountRepositoryProvider.overrideWithValue(accountRepo),
          accountTypeRepositoryProvider.overrideWithValue(typeRepo),
          userPreferencesRepositoryProvider.overrideWithValue(prefs),
          currencyRepositoryProvider.overrideWithValue(currencyRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      // MoneyFormatter.format with USD (decimals=2, symbol='$') + 1200 minor
      // units + locale='en' → '$12.00'.
      expect(find.textContaining(r'$12.00'), findsOneWidget);
    },
  );

  // SL12
  testWidgets(
    'ShoppingListCard archived account/category still resolves names for preview rows',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      const archivedCategory = Category(
        id: 10,
        icon: 'food',
        color: 1,
        type: CategoryType.expense,
        customName: 'Old Category',
        isArchived: true,
      );
      const archivedAccount = Account(
        id: 20,
        name: 'Old Account',
        accountTypeId: 1,
        currency: _usd,
        isArchived: true,
      );

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_item(id: 1, memo: null)]));
      when(
        () => categoryRepo.getById(10),
      ).thenAnswer((_) async => archivedCategory);
      when(
        () => accountRepo.getById(20),
      ).thenAnswer((_) async => archivedAccount);

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapCard(container: container));
      await tester.pumpAndSettle();

      // Archived category's custom name is shown as primary label (memo is null).
      expect(find.text('Old Category'), findsOneWidget);
      // Archived account name appears in secondary line.
      expect(find.textContaining('Old Account'), findsOneWidget);
    },
  );

  // SL14 — Integration: preview rows do not subscribe to the controller.
  //
  // ShoppingListCard renders preview rows without ever reading from
  // shoppingListControllerProvider, which owns the delete/undo logic and
  // should only be instantiated by ShoppingListScreen.
  testWidgets(
    'ShoppingListCard never instantiates shoppingListControllerProvider',
    (tester) async {
      final shoppingListRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => shoppingListRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_item(id: 1, memo: 'Test')]));
      when(
        () => categoryRepo.getById(any()),
      ).thenAnswer((_) async => _expenseCategory);
      when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

      var controllerWasBuilt = false;

      final container = _makeCardContainer(
        shoppingListRepo: shoppingListRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );

      // Re-create the container with the controller override on top.
      container.dispose();

      final typeRepo = _MockAccountTypeRepository();
      when(
        () => typeRepo.watchAll(includeArchived: any(named: 'includeArchived')),
      ).thenAnswer((_) => Stream.value([]));
      final prefs = _MockUserPreferencesRepository();
      final currencyRepo = _MockCurrencyRepository();
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd]));
      when(
        () => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')),
      ).thenAnswer((_) => Stream.value([_usd]));

      final spyContainer = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingListRepo),
          shoppingListPreviewProvider.overrideWith((ref) {
            return shoppingListRepo.watchAll().map(
              (items) => (
                preview: items.take(3).toList(growable: false),
                totalCount: items.length,
              ),
            );
          }),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          accountRepositoryProvider.overrideWithValue(accountRepo),
          accountTypeRepositoryProvider.overrideWithValue(typeRepo),
          userPreferencesRepositoryProvider.overrideWithValue(prefs),
          currencyRepositoryProvider.overrideWithValue(currencyRepo),
          shoppingListControllerProvider.overrideWith(() {
            controllerWasBuilt = true;
            return _SpyShoppingListController();
          }),
        ],
      );
      addTearDown(spyContainer.dispose);

      await tester.pumpWidget(_wrapCard(container: spyContainer));
      await tester.pumpAndSettle();

      expect(
        controllerWasBuilt,
        isFalse,
        reason:
            'ShoppingListCard must not subscribe to shoppingListControllerProvider',
      );
    },
  );
}

// ── Spy controller used in SL14 ────────────────────────────────────────────

class _SpyShoppingListController extends ShoppingListController {
  @override
  Stream<ShoppingListState> build() async* {
    yield const ShoppingListState.empty();
  }
}
