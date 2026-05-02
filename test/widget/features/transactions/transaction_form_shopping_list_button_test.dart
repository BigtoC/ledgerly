// TransactionFormScreen shopping-list button widget tests — Task 5.
//
// Tests IDs: TFSLW01–TFSLW04
//
// Covers:
//   - AddTransactionMode shows "Add to shopping list" inline action below
//     MemoField
//   - "Add to shopping list" is disabled when canSaveDraft is false
//   - EditShoppingListDraftMode shows "Save to transaction" and "Save draft"
//     in inline row; no app-bar Save button
//   - Archived account/category warning text appears in
//     EditShoppingListDraftMode when refs are archived

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/shopping_list_item.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/transactions/transaction_form_screen.dart';
import 'package:ledgerly/features/transactions/transaction_form_state.dart';
import 'package:ledgerly/features/transactions/widgets/account_selector_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

// ---------- Mocks ----------

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

class _MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

// ---------- Fixtures ----------

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

const _account = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd);
const _archivedAccount = Account(
  id: 5,
  name: 'Old Cash',
  accountTypeId: 1,
  currency: _usd,
  isArchived: true,
);

const _expenseCategory = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

const _archivedCategory = Category(
  id: 11,
  icon: 'shopping_cart',
  color: 1,
  type: CategoryType.expense,
  l10nKey: 'category.shopping',
  isArchived: true,
);

ShoppingListItem _draft({
  int id = 1,
  int categoryId = 10,
  int accountId = 1,
  int? draftAmountMinorUnits,
  String? draftCurrencyCode,
}) => ShoppingListItem(
  id: id,
  categoryId: categoryId,
  accountId: accountId,
  draftAmountMinorUnits: draftAmountMinorUnits,
  draftCurrencyCode: draftCurrencyCode,
  draftDate: DateTime(2026, 5, 1),
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

// ---------- Test harness helpers ----------

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home-stub'));
}

void main() {
  late _MockTransactionRepository txRepo;
  late _MockAccountRepository accountRepo;
  late _MockCategoryRepository categoryRepo;
  late _MockUserPreferencesRepository prefs;
  late _MockCurrencyRepository currencyRepo;
  late _MockShoppingListRepository slRepo;

  setUp(() {
    txRepo = _MockTransactionRepository();
    accountRepo = _MockAccountRepository();
    categoryRepo = _MockCategoryRepository();
    prefs = _MockUserPreferencesRepository();
    currencyRepo = _MockCurrencyRepository();
    slRepo = _MockShoppingListRepository();

    when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
    when(
      () => accountRepo.getLastUsedActiveAccount(),
    ).thenAnswer((_) async => null);
    when(() => accountRepo.getById(1)).thenAnswer((_) async => _account);
    when(
      () => accountRepo.getById(5),
    ).thenAnswer((_) async => _archivedAccount);
    when(
      () => accountRepo.watchAll(includeArchived: false),
    ).thenAnswer((_) => Stream.value(const [_account]));
    when(
      () => categoryRepo.getById(10),
    ).thenAnswer((_) async => _expenseCategory);
    when(
      () => categoryRepo.getById(11),
    ).thenAnswer((_) async => _archivedCategory);
    when(
      () => currencyRepo.watchAll(includeTokens: false),
    ).thenAnswer((_) => Stream.value(const [_usd]));
    when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
  });

  /// Mount the form screen with a typed [mode] under a minimal GoRouter.
  Widget mountWithMode(
    TransactionFormMode mode, {
    List<Override> extra = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const _HomeStub()),
        GoRoute(
          path: '/form',
          builder: (_, _) => TransactionFormScreen(mode: mode),
        ),
        GoRoute(
          path: '/settings/categories',
          builder: (_, _) =>
              Scaffold(appBar: AppBar(title: const Text('categories-stub'))),
        ),
        GoRoute(
          path: '/accounts/new',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => GoRouter.of(context).pop(99),
                child: const Text('finish-create-account'),
              ),
            ),
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
        currencyRepositoryProvider.overrideWithValue(currencyRepo),
        shoppingListRepositoryProvider.overrideWithValue(slRepo),
        ...extra,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets(
    'TFSLW01: AddTransactionMode shows "Add to shopping list" inline action',
    (tester) async {
      await tester.pumpWidget(mountWithMode(const AddTransactionMode()));
      await tester.pumpAndSettle();

      // The "Add to shopping list" button should be visible.
      expect(find.byKey(const Key('addToShoppingListButton')), findsOneWidget);
    },
  );

  testWidgets(
    'TFSLW02: "Add to shopping list" is disabled when canSaveDraft is false',
    (tester) async {
      await tester.pumpWidget(mountWithMode(const AddTransactionMode()));
      await tester.pumpAndSettle();

      // No category selected yet → canSaveDraft is false → button is disabled.
      final btn = tester.widget<OutlinedButton>(
        find.byKey(const Key('addToShoppingListButton')),
      );
      expect(btn.onPressed, isNull);
    },
  );

  testWidgets(
    'TFSLW03: EditShoppingListDraftMode shows "Save to transaction" and "Save draft"; no app-bar Save',
    (tester) async {
      final draft = _draft(
        id: 77,
        categoryId: _expenseCategory.id,
        accountId: _account.id,
        draftAmountMinorUnits: 1000,
        draftCurrencyCode: 'USD',
      );
      when(() => slRepo.getById(77)).thenAnswer((_) async => draft);

      await tester.pumpWidget(
        mountWithMode(const EditShoppingListDraftMode(shoppingListItemId: 77)),
      );
      await tester.pumpAndSettle();

      // Inline action buttons should be visible.
      expect(find.byKey(const Key('saveToTransactionButton')), findsOneWidget);
      expect(find.byKey(const Key('saveDraftButton')), findsOneWidget);

      // No app-bar "Save" text button (common to Add/Edit modes).
      // The app bar actions list is empty for shopping-list draft mode.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isEmpty);
    },
  );

  testWidgets(
    'TFSLW04: archived account warning appears in EditShoppingListDraftMode',
    (tester) async {
      // Draft references an archived account.
      final draft = _draft(
        id: 88,
        categoryId: _expenseCategory.id,
        accountId: _archivedAccount.id,
        draftAmountMinorUnits: 500,
        draftCurrencyCode: 'USD',
      );
      when(() => slRepo.getById(88)).thenAnswer((_) async => draft);

      await tester.pumpWidget(
        mountWithMode(const EditShoppingListDraftMode(shoppingListItemId: 88)),
      );
      await tester.pumpAndSettle();

      // Archived account warning text should be visible.
      expect(find.byKey(const Key('archivedAccountWarning')), findsOneWidget);

      // canConvertDraft should be false — "Save to transaction" button disabled.
      final saveToTxBtn = tester.widget<FilledButton>(
        find.byKey(const Key('saveToTransactionButton')),
      );
      expect(saveToTxBtn.onPressed, isNull);
    },
  );

  testWidgets(
    'TFSLW05: archived draft with no active replacements can create account without losing edits',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final draft = _draft(
        id: 89,
        categoryId: _expenseCategory.id,
        accountId: _archivedAccount.id,
        draftAmountMinorUnits: 500,
        draftCurrencyCode: 'USD',
      );
      when(() => slRepo.getById(89)).thenAnswer((_) async => draft);
      when(
        () => accountRepo.watchAll(includeArchived: false),
      ).thenAnswer((_) => Stream.value(const <Account>[]));
      when(() => accountRepo.getById(99)).thenAnswer(
        (_) async => const Account(
          id: 99,
          name: 'Fresh Cash',
          accountTypeId: 1,
          currency: _usd,
        ),
      );

      await tester.pumpWidget(
        mountWithMode(const EditShoppingListDraftMode(shoppingListItemId: 89)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'keep this memo');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AccountSelectorTile));
      await tester.pumpAndSettle();

      expect(find.text('Pick account'), findsOneWidget);
      expect(
        find.text('No active accounts — create one first'),
        findsOneWidget,
      );
      expect(find.text('Create account'), findsOneWidget);

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('finish-create-account'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text('Fresh Cash'), findsOneWidget);
      expect(find.text('keep this memo'), findsOneWidget);

      final saveToTxBtn = tester.widget<FilledButton>(
        find.byKey(const Key('saveToTransactionButton')),
      );
      expect(saveToTxBtn.onPressed, isNotNull);
    },
  );
}
