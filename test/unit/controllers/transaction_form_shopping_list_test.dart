// TransactionFormController shopping-list unit tests — Task 5.
//
// Tests IDs: TFSL01–TFSL10
//
// Covers:
//   - EditShoppingListDraftMode hydration (account, category, memo, amount,
//     currency, date)
//   - Null amount/currency seeds displayCurrency from selected account
//   - saveDraft() in add mode calls ShoppingListRepository.insert and pops null
//   - saveDraft() in edit mode calls ShoppingListRepository.update and pops
//     ShoppingListEditResultSavedDraft
//   - convertDraft() calls ShoppingListRepository.convertToTransaction and pops
//     ShoppingListEditResultSavedTransaction
//   - Missing draft id emits TransactionFormEmpty(draftNotFound)
//   - canSaveDraft / canConvertDraft rules
//   - submissionAction serializes in-flight state (double-tap protection)
//
// Repositories mocked via mocktail; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/shopping_list_item.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/transactions/transaction_form_controller.dart';
import 'package:ledgerly/features/transactions/transaction_form_state.dart';

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

// ---------- Test fixtures ----------

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

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

const _incomeCategory = Category(
  id: 12,
  icon: 'work',
  color: 2,
  type: CategoryType.income,
  l10nKey: 'category.income.salary',
);

ShoppingListItem _draft({
  int id = 1,
  int categoryId = 10,
  int accountId = 1,
  String? memo,
  int? draftAmountMinorUnits,
  String? draftCurrencyCode,
  DateTime? draftDate,
}) => ShoppingListItem(
  id: id,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  draftAmountMinorUnits: draftAmountMinorUnits,
  draftCurrencyCode: draftCurrencyCode,
  draftDate: draftDate ?? DateTime(2026, 5, 1),
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

Transaction _persistedTx({
  int id = 99,
  int amountMinorUnits = 1000,
  Currency currency = _usd,
  int categoryId = 10,
  int accountId = 1,
}) {
  final d = DateTime(2026, 5, 1);
  return Transaction(
    id: id,
    amountMinorUnits: amountMinorUnits,
    currency: currency,
    categoryId: categoryId,
    accountId: accountId,
    date: d,
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail argument matching.
    registerFallbackValue(_draft());
    registerFallbackValue(_persistedTx());
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

    // Default fallback stubs.
    when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => null);
    when(
      () => accountRepo.getLastUsedActiveAccount(),
    ).thenAnswer((_) async => null);
    when(
      () => accountRepo.watchAll(includeArchived: false),
    ).thenAnswer((_) => Stream.value(const [_account]));
    when(() => accountRepo.getById(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as int;
      if (id == _account.id) return _account;
      if (id == _archivedAccount.id) return _archivedAccount;
      return null;
    });
    when(() => categoryRepo.getById(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as int;
      if (id == _expenseCategory.id) return _expenseCategory;
      if (id == _archivedCategory.id) return _archivedCategory;
      if (id == _incomeCategory.id) return _incomeCategory;
      return null;
    });
    when(() => currencyRepo.getByCode(any())).thenAnswer((inv) async {
      final code = inv.positionalArguments.first as String;
      if (code == 'USD') return _usd;
      if (code == 'JPY') return _jpy;
      return null;
    });
    when(
      () => currencyRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(const [_usd, _jpy]));
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
        currencyRepositoryProvider.overrideWithValue(currencyRepo),
        shoppingListRepositoryProvider.overrideWithValue(slRepo),
      ],
    );
  }

  group('TFSL01: EditShoppingListDraftMode hydrates all fields from draft', () {
    test(
      'account, category, memo, amount, currency, date are hydrated',
      () async {
        final draftDate = DateTime(2026, 4, 20);
        final draft = _draft(
          id: 42,
          categoryId: _expenseCategory.id,
          accountId: _account.id,
          memo: 'groceries',
          draftAmountMinorUnits: 1500,
          draftCurrencyCode: 'USD',
          draftDate: draftDate,
        );
        when(() => slRepo.getById(42)).thenAnswer((_) async => draft);

        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForShoppingListDraft(42);

        final s = c.read(transactionFormControllerProvider);
        expect(s, isA<TransactionFormData>());
        final data = s as TransactionFormData;

        expect(data.selectedAccount?.id, _account.id);
        expect(data.selectedCategory?.id, _expenseCategory.id);
        expect(data.memo, 'groceries');
        expect(data.amountMinorUnits, 1500);
        expect(data.displayCurrency?.code, 'USD');
        expect(data.date, draftDate);
        expect(data.shoppingListItemId, 42);
        expect(data.isDirty, isFalse);
      },
    );
  });

  group(
    'TFSL02: null amount/currency seeds displayCurrency from selected account',
    () {
      test('draft with null amount/currency uses account currency', () async {
        final draft = _draft(
          id: 7,
          categoryId: _expenseCategory.id,
          accountId: _account.id,
          draftAmountMinorUnits: null,
          draftCurrencyCode: null,
        );
        when(() => slRepo.getById(7)).thenAnswer((_) async => draft);

        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForShoppingListDraft(7);

        final data =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(data.amountMinorUnits, 0);
        expect(data.displayCurrency?.code, 'USD');
        // currencyTouched is false when seeded from account.
        expect(data.currencyTouched, isFalse);
      });
    },
  );

  group('TFSL03: saveDraft() in add mode calls insert and returns null', () {
    test('calls ShoppingListRepository.insert with form snapshot', () async {
      when(
        () => slRepo.insert(
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          draftAmountMinorUnits: any(named: 'draftAmountMinorUnits'),
          draftCurrencyCode: any(named: 'draftCurrencyCode'),
          draftDate: any(named: 'draftDate'),
        ),
      ).thenAnswer((_) async => _draft());

      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      // Add mode hydration (not shopping list draft mode).
      await controller.hydrateForAdd();
      controller.selectCategory(_expenseCategory);

      final result = await controller.saveDraft();

      // In add mode, saveDraft returns null (the screen pops with null).
      expect(result, isNull);
      verify(
        () => slRepo.insert(
          categoryId: _expenseCategory.id,
          accountId: _account.id,
          memo: null,
          draftAmountMinorUnits: null,
          draftCurrencyCode: null,
          draftDate: any(named: 'draftDate'),
        ),
      ).called(1);
      verifyNever(() => slRepo.update(any()));
    });

    test('saveDraft() returns null when canSaveDraft is false', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      // No category selected → canSaveDraft is false.
      final result = await controller.saveDraft();
      expect(result, isNull);
      verifyNever(
        () => slRepo.insert(
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          draftAmountMinorUnits: any(named: 'draftAmountMinorUnits'),
          draftCurrencyCode: any(named: 'draftCurrencyCode'),
          draftDate: any(named: 'draftDate'),
        ),
      );
    });
  });

  group(
    'TFSL04: saveDraft() in edit mode calls update and returns savedDraft',
    () {
      test(
        'updates existing draft and returns ShoppingListEditResultSavedDraft',
        () async {
          final draft = _draft(
            id: 55,
            categoryId: _expenseCategory.id,
            accountId: _account.id,
            memo: 'old memo',
          );
          when(() => slRepo.getById(55)).thenAnswer((_) async => draft);
          when(() => slRepo.update(any())).thenAnswer(
            (inv) async => inv.positionalArguments.first as ShoppingListItem,
          );

          final c = makeContainer();
          addTearDown(c.dispose);
          final controller = c.read(transactionFormControllerProvider.notifier);
          await controller.hydrateForShoppingListDraft(55);

          final result = await controller.saveDraft();

          expect(result, isA<ShoppingListEditResultSavedDraft>());
          verify(() => slRepo.update(any())).called(1);
          verifyNever(
            () => slRepo.insert(
              categoryId: any(named: 'categoryId'),
              accountId: any(named: 'accountId'),
              memo: any(named: 'memo'),
              draftAmountMinorUnits: any(named: 'draftAmountMinorUnits'),
              draftCurrencyCode: any(named: 'draftCurrencyCode'),
              draftDate: any(named: 'draftDate'),
            ),
          );
        },
      );
    },
  );

  group(
    'TFSL05: convertDraft() calls convertToTransaction and returns savedTransaction',
    () {
      test(
        'converts draft and returns ShoppingListEditResultSavedTransaction',
        () async {
          final draft = _draft(
            id: 33,
            categoryId: _expenseCategory.id,
            accountId: _account.id,
            draftAmountMinorUnits: 2000,
            draftCurrencyCode: 'USD',
          );
          when(() => slRepo.getById(33)).thenAnswer((_) async => draft);
          final savedTx = _persistedTx(id: 200, amountMinorUnits: 2000);
          when(
            () => slRepo.convertToTransaction(
              shoppingListItemId: any(named: 'shoppingListItemId'),
              categoryId: any(named: 'categoryId'),
              accountId: any(named: 'accountId'),
              currencyCode: any(named: 'currencyCode'),
              amountMinorUnits: any(named: 'amountMinorUnits'),
              date: any(named: 'date'),
              memo: any(named: 'memo'),
            ),
          ).thenAnswer((_) async => savedTx);

          final c = makeContainer();
          addTearDown(c.dispose);
          final controller = c.read(transactionFormControllerProvider.notifier);
          await controller.hydrateForShoppingListDraft(33);

          final result = await controller.convertDraft();

          expect(result, isA<ShoppingListEditResultSavedTransaction>());
          final typed = result as ShoppingListEditResultSavedTransaction;
          expect(typed.transaction, savedTx);
          verify(
            () => slRepo.convertToTransaction(
              shoppingListItemId: 33,
              categoryId: _expenseCategory.id,
              accountId: _account.id,
              currencyCode: 'USD',
              amountMinorUnits: 2000,
              date: any(named: 'date'),
              memo: null,
            ),
          ).called(1);
        },
      );
    },
  );

  group('TFSL06: missing draft id emits draftNotFound', () {
    test('getById returns null → empty(draftNotFound)', () async {
      when(() => slRepo.getById(999)).thenAnswer((_) async => null);

      final c = makeContainer();
      addTearDown(c.dispose);
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForShoppingListDraft(999);

      final s = c.read(transactionFormControllerProvider);
      expect(s, isA<TransactionFormEmpty>());
      expect(
        (s as TransactionFormEmpty).reason,
        TransactionFormEmptyReason.draftNotFound,
      );
    });

    test(
      'draftNotFound state transitions from loading → empty(draftNotFound)',
      () async {
        when(() => slRepo.getById(888)).thenAnswer((_) async => null);

        final c = makeContainer();
        addTearDown(c.dispose);

        // Collect state transitions.
        final states = <TransactionFormState>[];
        final sub = c.listen(
          transactionFormControllerProvider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForShoppingListDraft(888);

        // Should go: loading → loading (hydrate resets) → empty(draftNotFound).
        final lastState = c.read(transactionFormControllerProvider);
        expect(lastState, isA<TransactionFormEmpty>());
        expect(
          (lastState as TransactionFormEmpty).reason,
          TransactionFormEmptyReason.draftNotFound,
        );
        // Verify the draftNotFound reason is distinct from other reasons.
        expect(
          lastState.reason,
          isNot(TransactionFormEmptyReason.noActiveAccount),
        );
        expect(lastState.reason, isNot(TransactionFormEmptyReason.notFound));
      },
    );
  });

  group(
    'TFSL07: canSaveDraft is true when account + expense category are set',
    () {
      test('amount = 0 is allowed', () async {
        final draft = _draft(
          id: 8,
          categoryId: _expenseCategory.id,
          accountId: _account.id,
        );
        when(() => slRepo.getById(8)).thenAnswer((_) async => draft);

        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForShoppingListDraft(8);

        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        // Amount is 0 — canSaveDraft should still be true.
        expect(s.amountMinorUnits, 0);
        expect(s.canSaveDraft, isTrue);
      });

      test(
        'from add mode: canSaveDraft=true when account + expense category set',
        () async {
          final c = makeContainer();
          addTearDown(c.dispose);
          final controller = c.read(transactionFormControllerProvider.notifier);
          await controller.hydrateForAdd();
          expect(
            c.read(transactionFormControllerProvider).canSaveDraft,
            isFalse,
          );
          controller.selectCategory(_expenseCategory);
          expect(
            c.read(transactionFormControllerProvider).canSaveDraft,
            isTrue,
          );
        },
      );
    },
  );

  group('TFSL08: canSaveDraft is false when category is income type', () {
    test('income category blocks canSaveDraft', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.selectCategory(_incomeCategory);
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.selectedCategory?.type, CategoryType.income);
      expect(s.canSaveDraft, isFalse);
    });
  });

  group('TFSL09: canConvertDraft is false when amount = 0', () {
    test('zero amount blocks canConvertDraft', () async {
      final draft = _draft(
        id: 9,
        categoryId: _expenseCategory.id,
        accountId: _account.id,
        draftAmountMinorUnits: null,
      );
      when(() => slRepo.getById(9)).thenAnswer((_) async => draft);

      final c = makeContainer();
      addTearDown(c.dispose);
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForShoppingListDraft(9);

      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.amountMinorUnits, 0);
      expect(s.canSaveDraft, isTrue);
      expect(s.canConvertDraft, isFalse);
    });

    test('canConvertDraft is false when archived account', () async {
      final draft = _draft(
        id: 10,
        categoryId: _expenseCategory.id,
        accountId: _archivedAccount.id,
        draftAmountMinorUnits: 1000,
        draftCurrencyCode: 'USD',
      );
      when(() => slRepo.getById(10)).thenAnswer((_) async => draft);

      final c = makeContainer();
      addTearDown(c.dispose);
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForShoppingListDraft(10);

      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.selectedAccountIsArchived, isTrue);
      expect(s.canConvertDraft, isFalse);
      // But canSaveDraft should still be true.
      expect(s.canSaveDraft, isTrue);
    });
  });

  group(
    'TFSL10: submissionAction tracks in-flight state; repeat call is ignored',
    () {
      test('second saveDraft() call during in-flight is ignored', () async {
        final completer = Completer<ShoppingListItem>();
        when(
          () => slRepo.insert(
            categoryId: any(named: 'categoryId'),
            accountId: any(named: 'accountId'),
            memo: any(named: 'memo'),
            draftAmountMinorUnits: any(named: 'draftAmountMinorUnits'),
            draftCurrencyCode: any(named: 'draftCurrencyCode'),
            draftDate: any(named: 'draftDate'),
          ),
        ).thenAnswer((_) => completer.future);

        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.selectCategory(_expenseCategory);

        // Start first saveDraft — in-flight.
        final first = controller.saveDraft();
        var s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.submissionAction, TransactionFormSubmissionAction.saveDraft);

        // Second call during in-flight should return null without calling
        // insert again.
        final second = await controller.saveDraft();
        expect(second, isNull);
        // Only one insert was called.
        verify(
          () => slRepo.insert(
            categoryId: any(named: 'categoryId'),
            accountId: any(named: 'accountId'),
            memo: any(named: 'memo'),
            draftAmountMinorUnits: any(named: 'draftAmountMinorUnits'),
            draftCurrencyCode: any(named: 'draftCurrencyCode'),
            draftDate: any(named: 'draftDate'),
          ),
        ).called(1);

        // Complete the first.
        completer.complete(_draft());
        await first;

        s = c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.submissionAction, TransactionFormSubmissionAction.none);
      });
    },
  );
}
