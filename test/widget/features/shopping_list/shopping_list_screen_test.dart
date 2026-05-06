// ShoppingListScreen widget tests — Task 4.
//
// Covers:
//   - loading indicator in loading state
//   - empty state CTA to /home/add
//   - list of rows in data state
//   - row tap navigates to /home/shopping-list/:id
//   - row tap is disabled while pending delete is active
//   - delete action shows undo snackbar
//   - undo snackbar action cancels delete
//   - error state shows retry button
//   - rows have non-swipe delete affordance (overflow/trailing icon)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/shopping_list_item.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_controller.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_screen.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

const _seededFoodCategory = Category(
  id: 2,
  icon: 'food',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

ShoppingListItem _item({
  required int id,
  int categoryId = 1,
  int accountId = 1,
  String? memo,
}) => ShoppingListItem(
  id: id,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo ?? 'Item $id',
  draftDate: DateTime(2026, 5, 1),
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

/// A fake controller that returns a fixed state.
class _FakeShoppingListController extends ShoppingListController {
  _FakeShoppingListController(this._fixed);
  final ShoppingListState _fixed;

  @override
  Stream<ShoppingListState> build() async* {
    yield _fixed;
  }
}

class _StubRouter {
  static GoRouter build(Widget home) {
    return GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/home/add',
          builder: (_, _) => const Scaffold(body: Text('ADD_TRANSACTION')),
        ),
        GoRoute(
          path: '/home/shopping-list/:id',
          builder: (ctx, state) => Scaffold(
            body: Text('SHOPPING_ITEM_${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/settings/manage-accounts/new',
          builder: (_, _) => const Scaffold(body: Text('ADD_ACCOUNT')),
        ),
      ],
    );
  }
}

Widget _wrap({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _StubRouter.build(const ShoppingListScreen()),
    ),
  );
}

ProviderContainer _makeContainer({
  required ShoppingListState fixed,
  _MockShoppingListRepository? repo,
  Category? category,
}) {
  final r = repo ?? _MockShoppingListRepository();
  when(() => r.watchAll()).thenAnswer((_) => const Stream.empty());
  when(() => r.watchCount()).thenAnswer((_) => const Stream.empty());

  // _ShoppingListRow is a ConsumerWidget that watches category/account/currency
  // providers. Provide stub repositories so those providers don't throw.
  final categoryRepo = _MockCategoryRepository();
  when(() => categoryRepo.getById(any())).thenAnswer(
    (_) async =>
        category ??
        const Category(
          id: 1,
          icon: 'food',
          color: 0,
          type: CategoryType.expense,
          customName: 'Groceries',
        ),
  );

  final accountRepo = _MockAccountRepository();
  when(() => accountRepo.getById(any())).thenAnswer((_) async => null);

  final currencyRepo = _MockCurrencyRepository();
  when(() => currencyRepo.getByCode(any())).thenAnswer((_) async => null);

  return ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(r),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      shoppingListControllerProvider.overrideWith(
        () => _FakeShoppingListController(fixed),
      ),
    ],
  );
}

void main() {
  testWidgets('SLS01: shows loading indicator in loading state', (
    tester,
  ) async {
    final container = _makeContainer(fixed: const ShoppingListState.loading());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SLS02: shows empty state CTA to /home/add', (tester) async {
    final container = _makeContainer(fixed: const ShoppingListState.empty());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('No upcoming expenses saved'), findsOneWidget);
    expect(find.text('Add to shopping list'), findsOneWidget);

    await tester.tap(find.text('Add to shopping list'));
    await tester.pumpAndSettle();

    expect(find.text('ADD_TRANSACTION'), findsOneWidget);
  });

  testWidgets('SLS03: shows list of rows in data state', (tester) async {
    final items = [_item(id: 1, memo: 'Apples'), _item(id: 2, memo: 'Bread')];
    final container = _makeContainer(
      fixed: ShoppingListState.data(items: items, pendingDelete: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('Apples'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets(
    'SLS03b: localizes seeded category fallback when row memo is empty',
    (tester) async {
      final items = [
        ShoppingListItem(
          id: 2,
          categoryId: 2,
          accountId: 1,
          memo: '',
          draftDate: DateTime(2026, 5, 1),
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
      ];
      final container = _makeContainer(
        fixed: ShoppingListState.data(items: items, pendingDelete: null),
        category: _seededFoodCategory,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsAtLeastNWidgets(1));
      expect(find.text('category.food'), findsNothing);
    },
  );

  testWidgets('SLS04: row tap navigates to /home/shopping-list/:id', (
    tester,
  ) async {
    final items = [_item(id: 42, memo: 'Milk')];
    final container = _makeContainer(
      fixed: ShoppingListState.data(items: items, pendingDelete: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(find.text('SHOPPING_ITEM_42'), findsOneWidget);
  });

  testWidgets('SLS05: row tap is disabled while pending delete is active', (
    tester,
  ) async {
    final items = [_item(id: 10, memo: 'Coffee')];
    const pending = ShoppingListPendingDelete(
      itemId: 99, // a different item is pending — taps on id:10 still disabled
    );
    final container = _makeContainer(
      fixed: ShoppingListState.data(items: items, pendingDelete: pending),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    // Row is present but tap should NOT navigate
    expect(find.text('Coffee'), findsOneWidget);

    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();

    // Should NOT have navigated to the detail page
    expect(find.text('SHOPPING_ITEM_10'), findsNothing);
  });

  testWidgets('SLS06: delete action shows undo snackbar', (tester) async {
    final mockRepo = _MockShoppingListRepository();
    // The controller in this test needs a live (not fixed) stream to work.
    // We use a stream that keeps open so the controller stays alive.
    final ctrl = StreamController<List<ShoppingListItem>>.broadcast();
    when(() => mockRepo.watchAll()).thenAnswer((_) => ctrl.stream);
    when(() => mockRepo.delete(any())).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);
    addTearDown(ctrl.close);

    final item = _item(id: 5, memo: 'Tea');
    await tester.pumpWidget(_wrap(container: container));
    await tester.pump();

    // Feed the items
    ctrl.add([item]);
    await tester.pumpAndSettle();

    expect(find.text('Tea'), findsOneWidget);

    // Slide item to reveal delete action
    await tester.drag(find.text('Tea'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Tap the delete action button
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    // Undo snackbar should appear
    expect(find.text('Draft deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Cancel the pending timer by tapping Undo so no timer leaks.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
  });

  testWidgets('SLS07: undo snackbar action cancels delete', (tester) async {
    final mockRepo = _MockShoppingListRepository();
    final ctrl = StreamController<List<ShoppingListItem>>.broadcast();
    when(() => mockRepo.watchAll()).thenAnswer((_) => ctrl.stream);
    when(() => mockRepo.delete(any())).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);
    addTearDown(ctrl.close);

    final item = _item(id: 6, memo: 'Sugar');
    await tester.pumpWidget(_wrap(container: container));
    await tester.pump();

    ctrl.add([item]);
    await tester.pumpAndSettle();

    // Slide and delete
    await tester.drag(find.text('Sugar'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Draft deleted'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Repo.delete should never have been called (timer cancelled)
    verifyNever(() => mockRepo.delete(any()));
  });

  testWidgets('SLS08: error state shows retry button', (tester) async {
    final container = _makeContainer(
      fixed: ShoppingListState.error(StateError('fail'), StackTrace.empty),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'SLS08b: retry recreates controller and delete still uses the active instance',
    (tester) async {
      final repo = _MockShoppingListRepository();
      final firstCtrl = StreamController<List<ShoppingListItem>>.broadcast();
      final secondCtrl = StreamController<List<ShoppingListItem>>.broadcast();
      var watchCount = 0;

      when(() => repo.watchAll()).thenAnswer((_) {
        watchCount += 1;
        return watchCount == 1 ? firstCtrl.stream : secondCtrl.stream;
      });
      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [shoppingListRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      addTearDown(firstCtrl.close);
      addTearDown(secondCtrl.close);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pump();

      firstCtrl.addError(StateError('fail'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      secondCtrl.add([_item(id: 12, memo: 'Recovered item')]);
      await tester.pumpAndSettle();

      expect(find.text('Recovered item'), findsOneWidget);

      await tester.drag(find.text('Recovered item'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Recovered item'), findsNothing);
      expect(find.text('Draft deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.delete(any()));
    },
  );

  testWidgets(
    'SLS08c: delete snackbar is not shown when committing prior delete fails',
    (tester) async {
      final repo = _MockShoppingListRepository();
      final ctrl = StreamController<List<ShoppingListItem>>.broadcast();
      when(() => repo.watchAll()).thenAnswer((_) => ctrl.stream);
      when(() => repo.delete(1)).thenThrow(StateError('delete failed'));

      final container = ProviderContainer(
        overrides: [shoppingListRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      addTearDown(ctrl.close);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pump();

      ctrl.add([_item(id: 1, memo: 'First'), _item(id: 2, memo: 'Second')]);
      await tester.pumpAndSettle();

      await tester.drag(find.text('First'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Draft deleted'), findsOneWidget);

      await tester.drag(find.text('Second'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Draft deleted'), findsNothing);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SLS09: rows have non-swipe delete affordance (overflow/trailing icon)',
    (tester) async {
      final items = [_item(id: 3, memo: 'Cheese')];
      final container = _makeContainer(
        fixed: ShoppingListState.data(items: items, pendingDelete: null),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Cheese'), findsOneWidget);
      // Should have a non-swipe delete affordance — look for popup menu or icon button
      // The key is shoppingListItem:3:delete
      expect(
        find.byKey(const ValueKey('shoppingListItem:3:delete')),
        findsOneWidget,
      );
    },
  );
}
