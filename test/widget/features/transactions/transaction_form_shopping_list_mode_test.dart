// TransactionFormScreen shopping-list mode and button widget tests — Task 5.
//
// Tests IDs: TFSLW02–TFSLW05, TFSLM01, TFSLM04–TFSLM09
//
// Covers:
//   - "Add to shopping list" is disabled when canSaveDraft is false
//   - EditShoppingListDraftMode shows "Save to transaction" and "Save draft"
//     in inline row; no app-bar Save button
//   - Archived account/category warning text appears in
//     EditShoppingListDraftMode when refs are archived
//   - EditShoppingListDraftMode title matches shoppingListEditDraftTitle l10n key
//   - An ignored draft save / conversion does not pop the form
//   - A failed draft save, draft conversion or "Add to shopping list" shows
//     its failure snackbar and keeps the form open

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/shopping_list_item.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/ui/features/categories/view_models/categories_controller.dart';
import 'package:ledgerly/ui/features/transactions/view_models/keypad_state.dart';
import 'package:ledgerly/ui/features/transactions/view_models/transaction_form_controller.dart';
import 'package:ledgerly/ui/features/transactions/views/transaction_form_screen.dart';
import 'package:ledgerly/ui/features/transactions/view_models/transaction_form_state.dart';
import 'package:ledgerly/ui/features/transactions/views/account_selector_tile.dart';
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

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home-stub'));
}

class _FakeTransactionFormController extends TransactionFormController {
  _FakeTransactionFormController({
    required this._fixed,
    this._saveDraftOutcome = const DraftSubmissionOutcome.ignored(),
    this._convertDraftOutcome = const DraftSubmissionOutcome.ignored(),
  });

  final TransactionFormState _fixed;
  final DraftSubmissionOutcome _saveDraftOutcome;
  final DraftSubmissionOutcome _convertDraftOutcome;

  @override
  TransactionFormState build() => _fixed;

  @override
  Future<void> hydrateForShoppingListDraft(int shoppingListItemId) async {
    state = _fixed;
  }

  @override
  Future<DraftSubmissionOutcome> saveDraft() async => _saveDraftOutcome;

  @override
  Future<DraftSubmissionOutcome> convertDraft() async => _convertDraftOutcome;
}

TransactionFormState _editableDraftState() => TransactionFormState.data(
  formMode: const EditShoppingListDraftMode(shoppingListItemId: 77),
  amountMinorUnits: 500,
  keypad: KeypadState(
    amountMinorUnits: 500,
    fractionalDigitsEntered: 0,
    isFractionalMode: false,
    hasCurrentInput: true,
  ),
  selectedAccount: _account,
  displayCurrency: _usd,
  currencyTouched: false,
  selectedCategory: _expenseCategory,
  date: DateTime(2026, 5, 1),
  memo: 'Milk',
  shoppingListItemId: 77,
);

@Dependencies([TransactionFormController, categoriesByType])
void main() {
  setUpAll(() {
    registerFallbackValue(_draft());
  });

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
    when(() => accountRepo.getLastUsedActiveAccount())
        .thenAnswer((_) async => null);
    when(() => accountRepo.getById(1)).thenAnswer((_) async => _account);
    when(() => accountRepo.getById(5))
        .thenAnswer((_) async => _archivedAccount);
    when(() => accountRepo.watchAll(includeArchived: false))
        .thenAnswer((_) => Stream.value(const [_account]));
    when(() => categoryRepo.getById(10))
        .thenAnswer((_) async => _expenseCategory);
    when(() => categoryRepo.getById(11))
        .thenAnswer((_) async => _archivedCategory);
    when(() => currencyRepo.watchAll(includeTokens: false))
        .thenAnswer((_) => Stream.value(const [_usd]));
    when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
  });

  Widget mountWithRouter(GoRouter router, {List<Override> extra = const []}) {
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

  @Dependencies([TransactionFormController, categoriesByType])
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
        GoRoute(
          path: '/settings/manage-accounts/new',
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
    return mountWithRouter(router);
  }

  @Dependencies([TransactionFormController, categoriesByType])
  GoRouter buildPushRouter(TransactionFormMode mode) {
    final router = GoRouter(
      initialLocation: '/',
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
    return router;
  }

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
      when(() => accountRepo.watchAll(includeArchived: false))
          .thenAnswer((_) => Stream.value(const <Account>[]));
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

  testWidgets(
    'TFSLM04: auto-pops with ShoppingListEditResultMissingDraft when draft not found',
    (tester) async {
      // Stub: draft id 99 does not exist.
      when(() => slRepo.getById(99)).thenAnswer((_) async => null);

      ShoppingListEditResult? poppedResult;

      // Build a router that captures the pop result from the form screen.
      final router = buildPushRouter(
        const EditShoppingListDraftMode(shoppingListItemId: 99),
      );

      await tester.pumpWidget(mountWithRouter(router));

      // Navigate to the form screen, capturing the pop result.
      unawaited(
        router.push<ShoppingListEditResult>('/form').then((result) {
          poppedResult = result;
        }),
      );
      await tester.pumpAndSettle();

      // After hydration finds the draft is missing, the screen should auto-pop
      // back to home-stub and supply ShoppingListEditResultMissingDraft.
      expect(find.text('home-stub'), findsOneWidget);
      expect(poppedResult, isA<ShoppingListEditResultMissingDraft>());
    },
  );

  testWidgets('TFSLM05: an ignored draft save does not pop edit-draft form', (
    tester,
  ) async {
    var didPop = false;
    ShoppingListEditResult? poppedResult;
    final router = buildPushRouter(
      const EditShoppingListDraftMode(shoppingListItemId: 77),
    );
    final fakeController = _FakeTransactionFormController(
      fixed: _editableDraftState(),
      saveDraftOutcome: const DraftSubmissionOutcome.ignored(),
    );

    await tester.pumpWidget(
      mountWithRouter(
        router,
        extra: [
          transactionFormControllerProvider.overrideWith(() => fakeController),
        ],
      ),
    );

    unawaited(
      router.push<ShoppingListEditResult?>('/form').then((result) {
        didPop = true;
        poppedResult = result;
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.byKey(const Key('saveDraftButton')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('saveDraftButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveDraftButton')));
    await tester.pumpAndSettle();

    expect(didPop, isFalse);
    expect(poppedResult, isNull);
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.byKey(const Key('saveDraftButton')), findsOneWidget);
  });

  testWidgets(
    'TFSLM06: an ignored draft conversion does not pop edit-draft form',
    (tester) async {
      var didPop = false;
      ShoppingListEditResult? poppedResult;
      final router = buildPushRouter(
        const EditShoppingListDraftMode(shoppingListItemId: 77),
      );
      final fakeController = _FakeTransactionFormController(
        fixed: _editableDraftState(),
        convertDraftOutcome: const DraftSubmissionOutcome.ignored(),
      );

      await tester.pumpWidget(
        mountWithRouter(
          router,
          extra: [
            transactionFormControllerProvider.overrideWith(
              () => fakeController,
            ),
          ],
        ),
      );

      unawaited(
        router.push<ShoppingListEditResult?>('/form').then((result) {
          didPop = true;
          poppedResult = result;
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.byKey(const Key('saveToTransactionButton')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('saveToTransactionButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saveToTransactionButton')));
      await tester.pumpAndSettle();

      expect(didPop, isFalse);
      expect(poppedResult, isNull);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.byKey(const Key('saveToTransactionButton')), findsOneWidget);
    },
  );

  testWidgets('TFSLM07: a failed draft save shows the save-failed snackbar', (
    tester,
  ) async {
    when(() => slRepo.getById(77)).thenAnswer(
      (_) async =>
          _draft(id: 77, draftAmountMinorUnits: 500, draftCurrencyCode: 'USD'),
    );
    when(() => slRepo.update(any())).thenThrow(Exception('db down'));

    await tester.pumpWidget(
      mountWithMode(const EditShoppingListDraftMode(shoppingListItemId: 77)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('saveDraftButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveDraftButton')));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.shoppingListSaveFailedSnackbar), findsOneWidget);
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TFSLM07b: the keypad Save saves the draft, not a transaction', (
    tester,
  ) async {
    final draft = _draft(
      id: 77,
      categoryId: _expenseCategory.id,
      accountId: _account.id,
      draftAmountMinorUnits: 500,
      draftCurrencyCode: 'USD',
    );
    when(() => slRepo.getById(77)).thenAnswer((_) async => draft);
    when(() => slRepo.update(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as ShoppingListItem,
    );
    ShoppingListEditResult? poppedResult;
    final router = buildPushRouter(
      const EditShoppingListDraftMode(shoppingListItemId: 77),
    );
    await tester.pumpWidget(mountWithRouter(router));
    unawaited(
      router
          .push<ShoppingListEditResult?>('/form')
          .then((result) => poppedResult = result),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    verify(() => slRepo.update(any())).called(1);
    verifyNever(
      () => slRepo.convertToTransaction(
        shoppingListItemId: any(named: 'shoppingListItemId'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
        amountMinorUnits: any(named: 'amountMinorUnits'),
        date: any(named: 'date'),
        memo: any(named: 'memo'),
        amountFormula: any(named: 'amountFormula'),
      ),
    );
    expect(find.byType(TransactionFormScreen), findsNothing);
    expect(poppedResult, isA<ShoppingListEditResultSavedDraft>());
  });

  testWidgets(
    'TFSLM07d: a zero-amount draft keeps the keypad Save enabled (canSaveDraft, not canSave)',
    (tester) async {
      final router = buildPushRouter(
        const EditShoppingListDraftMode(shoppingListItemId: 77),
      );
      final fakeController = _FakeTransactionFormController(
        fixed: (_editableDraftState() as TransactionFormData).copyWith(
          amountMinorUnits: 0,
          keypad: const KeypadState.initial(),
        ),
      );
      await tester.pumpWidget(
        mountWithRouter(
          router,
          extra: [
            transactionFormControllerProvider.overrideWith(
              () => fakeController,
            ),
          ],
        ),
      );
      unawaited(router.push<ShoppingListEditResult?>('/form'));
      await tester.pumpAndSettle();

      final keypadSave = find.descendant(
        of: find.byTooltip('Save'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(keypadSave).onTap, isNotNull);
    },
  );

  testWidgets(
    'TFSLM07c: the keypad Save is disabled while the draft cannot be saved',
    (tester) async {
      final router = buildPushRouter(
        const EditShoppingListDraftMode(shoppingListItemId: 77),
      );
      final fakeController = _FakeTransactionFormController(
        fixed: (_editableDraftState() as TransactionFormData).copyWith(
          selectedCategory: null,
        ),
      );
      await tester.pumpWidget(
        mountWithRouter(
          router,
          extra: [
            transactionFormControllerProvider.overrideWith(
              () => fakeController,
            ),
          ],
        ),
      );
      unawaited(router.push<ShoppingListEditResult?>('/form'));
      await tester.pumpAndSettle();

      final keypadSave = find.descendant(
        of: find.byTooltip('Save'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(keypadSave).onTap, isNull);
    },
  );

  testWidgets(
    'TFSLM08: a failed draft conversion shows the convert-failed snackbar',
    (tester) async {
      when(() => slRepo.getById(77)).thenAnswer(
        (_) async => _draft(
          id: 77,
          draftAmountMinorUnits: 500,
          draftCurrencyCode: 'USD',
        ),
      );
      when(
        () => slRepo.convertToTransaction(
          shoppingListItemId: any(named: 'shoppingListItemId'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          currencyCode: any(named: 'currencyCode'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          date: any(named: 'date'),
          memo: any(named: 'memo'),
          amountFormula: any(named: 'amountFormula'),
        ),
      ).thenThrow(Exception('db down'));

      await tester.pumpWidget(
        mountWithMode(const EditShoppingListDraftMode(shoppingListItemId: 77)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('saveToTransactionButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saveToTransactionButton')));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.shoppingListConvertFailedSnackbar), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'TFSLM09: a failed "Add to shopping list" shows the save-failed snackbar',
    (tester) async {
      when(
        () => slRepo.insert(
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          draftAmountMinorUnits: any(named: 'draftAmountMinorUnits'),
          draftCurrencyCode: any(named: 'draftCurrencyCode'),
          draftDate: any(named: 'draftDate'),
        ),
      ).thenThrow(Exception('db down'));
      final router = buildPushRouter(const AddTransactionMode());

      await tester.pumpWidget(
        mountWithRouter(
          router,
          extra: [
            categoriesByTypeProvider(CategoryType.expense)
                .overrideWith((ref) => Stream.value(const [_expenseCategory])),
            categoriesByTypeProvider(CategoryType.income)
                .overrideWith((ref) => Stream.value(const <Category>[])),
          ],
        ),
      );
      unawaited(router.push<Object?>('/form'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('addToShoppingListButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addToShoppingListButton')));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.shoppingListSaveFailedSnackbar), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
