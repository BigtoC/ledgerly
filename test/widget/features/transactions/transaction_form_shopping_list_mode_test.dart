// TransactionFormScreen shopping-list mode widget tests — Task 5.
//
// Tests IDs: TFSLM01–TFSLM03
//
// Covers:
//   - EditShoppingListDraftMode title matches shoppingListEditDraftTitle l10n key
//   - AddTransactionMode title matches existing txAddTitle l10n key
//   - route pop with ShoppingListEditResult.savedDraft is distinct from null

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
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/l10n/app_localizations_en.dart';

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
const _expenseCategory = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

ShoppingListItem _draft({
  int id = 1,
  int? draftAmountMinorUnits,
  String? draftCurrencyCode,
}) => ShoppingListItem(
  id: id,
  categoryId: _expenseCategory.id,
  accountId: _account.id,
  draftAmountMinorUnits: draftAmountMinorUnits,
  draftCurrencyCode: draftCurrencyCode,
  draftDate: DateTime(2026, 5, 1),
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

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
      () => accountRepo.watchAll(includeArchived: false),
    ).thenAnswer((_) => Stream.value(const [_account]));
    when(
      () => categoryRepo.getById(10),
    ).thenAnswer((_) async => _expenseCategory);
    when(
      () => currencyRepo.watchAll(includeTokens: false),
    ).thenAnswer((_) => Stream.value(const [_usd]));
    when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
  });

  Widget mountWithMode(TransactionFormMode mode) {
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
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets(
    'TFSLM01: EditShoppingListDraftMode title matches shoppingListEditDraftTitle l10n key',
    (tester) async {
      final draft = _draft(
        id: 11,
        draftAmountMinorUnits: 500,
        draftCurrencyCode: 'USD',
      );
      when(() => slRepo.getById(11)).thenAnswer((_) async => draft);

      await tester.pumpWidget(
        mountWithMode(const EditShoppingListDraftMode(shoppingListItemId: 11)),
      );
      await tester.pumpAndSettle();

      // The expected title comes from the English l10n.
      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.shoppingListEditDraftTitle), findsOneWidget);
    },
  );

  testWidgets('TFSLM02: AddTransactionMode title matches txAddTitle l10n key', (
    tester,
  ) async {
    await tester.pumpWidget(mountWithMode(const AddTransactionMode()));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.txAddTitle), findsOneWidget);
  });

  testWidgets(
    'TFSLM03: ShoppingListEditResultSavedDraft is a distinct result from null',
    (tester) async {
      // This is a unit-level invariant test — ShoppingListEditResultSavedDraft
      // is not null and not a ShoppingListEditResultMissingDraft.
      const saved = ShoppingListEditResultSavedDraft();
      expect(saved, isNotNull);
      expect(saved, isA<ShoppingListEditResult>());
      expect(saved, isNot(isA<ShoppingListEditResultMissingDraft>()));
      expect(saved, isNot(isA<ShoppingListEditResultSavedTransaction>()));

      // Also verify that the enum hierarchy is correct.
      const missing = ShoppingListEditResultMissingDraft();
      expect(missing, isNot(equals(saved)));
    },
  );
}
