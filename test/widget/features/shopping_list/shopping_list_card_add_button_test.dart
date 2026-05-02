// ShoppingListCard "Add" icon button widget tests — Task 8.
//
// Test IDs: SLA01–SLA04
//
// Covers:
//   - SLA01: Add button present in card header when state is loading
//   - SLA02: Add button present in card header when drafts exist (non-empty)
//   - SLA03: Add button present in card header when state is empty
//   - SLA04: Tapping Add button in non-empty state pushes /home/add

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
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_providers.dart';
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

// ── Fixtures ──────────────────────────────────────────────────────────────

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

final _now = DateTime(2026, 5, 2);

ShoppingListItem _item({int id = 1, String? memo}) => ShoppingListItem(
  id: id,
  categoryId: 10,
  accountId: 20,
  memo: memo,
  draftDate: _now,
  createdAt: _now,
  updatedAt: _now,
);

const _category = Category(
  id: 10,
  icon: 'food',
  color: 1,
  type: CategoryType.expense,
  l10nKey: 'category.food',
  customName: 'Groceries',
);

const _account = Account(id: 20, name: 'Cash', accountTypeId: 1, currency: _usd);

// ── Helpers ───────────────────────────────────────────────────────────────

GoRouter _buildRouter(Widget home) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/accounts/shopping-list',
        builder: (_, _) => const Scaffold(body: Text('SHOPPING_LIST')),
      ),
      GoRoute(
        path: '/home/add',
        builder: (_, _) => const Scaffold(body: Text('ADD_TRANSACTION')),
      ),
    ],
  );
}

ProviderContainer _makeContainer({
  required ShoppingListRepository slRepo,
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
      shoppingListRepositoryProvider.overrideWithValue(slRepo),
      shoppingListPreviewProvider.overrideWith((ref) {
        return slRepo.watchAll().map(
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

Widget _wrap({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _buildRouter(const ShoppingListCard()),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_item());
    registerFallbackValue(_category);
    registerFallbackValue(_account);
  });

  testWidgets(
    'SLA01: Add icon button is present in card header during loading state',
    (tester) async {
      final slRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      // Never-completing stream → loading state.
      when(() => slRepo.watchAll()).thenAnswer((_) => const Stream.empty());

      final container = _makeContainer(
        slRepo: slRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pump();

      expect(find.byKey(const Key('shoppingListCardAddButton')), findsOneWidget);
    },
  );

  testWidgets(
    'SLA02: Add icon button is present in card header when drafts exist',
    (tester) async {
      final slRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => slRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_item(memo: 'Milk')]));
      when(() => categoryRepo.getById(any())).thenAnswer((_) async => _category);
      when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

      final container = _makeContainer(
        slRepo: slRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      // Row is visible.
      expect(find.text('Milk'), findsOneWidget);
      // Add button is still in the header.
      expect(find.byKey(const Key('shoppingListCardAddButton')), findsOneWidget);
    },
  );

  testWidgets(
    'SLA03: Add icon button is present in card header in empty state',
    (tester) async {
      final slRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(() => slRepo.watchAll()).thenAnswer((_) => Stream.value([]));

      final container = _makeContainer(
        slRepo: slRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      // Empty-state body CTA is shown.
      expect(find.text('Add to shopping list'), findsAtLeast(1));
      // Header add button is also present.
      expect(find.byKey(const Key('shoppingListCardAddButton')), findsOneWidget);
    },
  );

  testWidgets(
    'SLA04: tapping Add button in non-empty state pushes /home/add',
    (tester) async {
      final slRepo = _MockShoppingListRepository();
      final categoryRepo = _MockCategoryRepository();
      final accountRepo = _MockAccountRepository();

      when(
        () => slRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_item(memo: 'Bread')]));
      when(() => categoryRepo.getById(any())).thenAnswer((_) async => _category);
      when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);

      final container = _makeContainer(
        slRepo: slRepo,
        categoryRepo: categoryRepo,
        accountRepo: accountRepo,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shoppingListCardAddButton')));
      await tester.pumpAndSettle();

      expect(find.text('ADD_TRANSACTION'), findsOneWidget);
    },
  );
}
