// TransactionFormController unit tests — Wave 2 §4.3.
//
// Covers:
//   - Hydration paths (Add / Edit / Duplicate) including the
//     default-account fallback chain and not-found recoveries.
//   - Keypad commands (digit / decimal / backspace / clear) propagate to
//     `amountMinorUnits` and `isDirty`.
//   - Type derivation: selectCategory updates pendingType; switching
//     pendingType while a category is selected of the opposite type is
//     refused (the screen handles the confirm-then-clear flow).
//   - Account swap with currency change refuses without
//     `clearAmountOnCurrencyChange`; accepts and clears when allowed.
//   - Save success returns the persisted Transaction; failure rethrows
//     and clears `isSaving` (state stays `.data`).
//   - Delete returns false on missing rows, true on actual deletion;
//     rethrows on repository error.
//   - `canSave` getter is false outside `.data` and false until amount,
//     category, and account are all present.
//
// Repositories mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:ledgerly/features/transactions/transaction_form_controller.dart';
import 'package:ledgerly/features/transactions/transaction_form_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

const _account = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd);
const _accountJpy = Account(
  id: 2,
  name: 'Yen',
  accountTypeId: 1,
  currency: _jpy,
);

const _expenseCategory = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

const _incomeCategory = Category(
  id: 11,
  icon: 'work',
  color: 1,
  type: CategoryType.income,
  l10nKey: 'category.income.salary',
);

Transaction _persistedTx({
  int id = 99,
  int amountMinorUnits = 500,
  Currency currency = _usd,
  int categoryId = 10,
  int accountId = 1,
  String? memo,
  DateTime? date,
  DateTime? createdAt,
}) {
  final d = date ?? DateTime(2026, 4, 25);
  return Transaction(
    id: id,
    amountMinorUnits: amountMinorUnits,
    currency: currency,
    categoryId: categoryId,
    accountId: accountId,
    memo: memo,
    date: d,
    createdAt: createdAt ?? d,
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

    // Fallback-chain stubs: no preference, no last-used, single active.
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
      if (id == _accountJpy.id) return _accountJpy;
      return null;
    });
    when(() => categoryRepo.getById(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as int;
      if (id == _expenseCategory.id) return _expenseCategory;
      if (id == _incomeCategory.id) return _incomeCategory;
      return null;
    });
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
      ],
    );
  }

  group('hydrateForAdd — fallback chain', () {
    test('TC01: defaultAccountId set → uses preferred account', () async {
      when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(transactionFormControllerProvider.notifier).hydrateForAdd();
      final s = c.read(transactionFormControllerProvider);
      expect(s, isA<TransactionFormData>());
      expect((s as TransactionFormData).selectedAccount?.id, 1);
      expect(s.displayCurrency?.code, 'USD');
      expect(s.pendingType, CategoryType.expense);
    });

    test(
      'TC02: defaultAccountId unset → falls back to last-used active',
      () async {
        const lastUsed = Account(
          id: 7,
          name: 'Last',
          accountTypeId: 1,
          currency: _usd,
        );
        when(
          () => accountRepo.getLastUsedActiveAccount(),
        ).thenAnswer((_) async => lastUsed);
        when(() => accountRepo.getById(7)).thenAnswer((_) async => lastUsed);
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForAdd();
        final s = c.read(transactionFormControllerProvider);
        expect((s as TransactionFormData).selectedAccount?.id, 7);
      },
    );

    test(
      'TC03: no preference, no last-used → first active by sortOrder',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForAdd();
        final s = c.read(transactionFormControllerProvider);
        expect((s as TransactionFormData).selectedAccount?.id, 1);
      },
    );

    test('TC04: zero active accounts → empty(noActiveAccount)', () async {
      when(
        () => accountRepo.watchAll(includeArchived: false),
      ).thenAnswer((_) => Stream.value(const <Account>[]));
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(transactionFormControllerProvider.notifier).hydrateForAdd();
      final s = c.read(transactionFormControllerProvider);
      expect(s, isA<TransactionFormEmpty>());
      expect(
        (s as TransactionFormEmpty).reason,
        TransactionFormEmptyReason.noActiveAccount,
      );
    });
  });

  group('hydrateForEdit', () {
    test('TC10: hydrates from getById', () async {
      final tx = _persistedTx(memo: 'lunch');
      when(() => txRepo.getById(99)).thenAnswer((_) async => tx);
      final c = makeContainer();
      addTearDown(c.dispose);
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForEdit(99);
      final s = c.read(transactionFormControllerProvider);
      expect(s, isA<TransactionFormData>());
      final data = s as TransactionFormData;
      expect(data.editingId, 99);
      expect(data.amountMinorUnits, 500);
      expect(data.memo, 'lunch');
      expect(data.selectedCategory?.id, _expenseCategory.id);
      expect(data.selectedAccount?.id, _account.id);
      expect(data.originalCreatedAt, tx.createdAt);
      expect(data.isDirty, isFalse);
    });

    test('TC11: missing row → empty(notFound)', () async {
      when(() => txRepo.getById(123)).thenAnswer((_) async => null);
      final c = makeContainer();
      addTearDown(c.dispose);
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForEdit(123);
      final s = c.read(transactionFormControllerProvider);
      expect(s, isA<TransactionFormEmpty>());
      expect(
        (s as TransactionFormEmpty).reason,
        TransactionFormEmptyReason.notFound,
      );
    });
  });

  group('hydrateForDuplicate', () {
    test(
      'TC20: prefills amount/category/memo and resets date to today',
      () async {
        final source = _persistedTx(memo: 'lunch', date: DateTime(2025, 1, 1));
        when(() => txRepo.getById(99)).thenAnswer((_) async => source);
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForDuplicate(99);
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.amountMinorUnits, source.amountMinorUnits);
        expect(s.memo, 'lunch');
        expect(s.duplicateSourceId, 99);
        expect(s.editingId, isNull);
        // Date defaults to today (Wave 2 risk #7).
        final today = DateTime.now();
        expect(s.date.year, today.year);
        expect(s.date.month, today.month);
        expect(s.date.day, today.day);
      },
    );

    test('TC21: missing source → empty(notFound)', () async {
      when(() => txRepo.getById(123)).thenAnswer((_) async => null);
      final c = makeContainer();
      addTearDown(c.dispose);
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForDuplicate(123);
      final s = c.read(transactionFormControllerProvider);
      expect(s, isA<TransactionFormEmpty>());
      expect(
        (s as TransactionFormEmpty).reason,
        TransactionFormEmptyReason.notFound,
      );
    });

    test(
      'TC22: fallback to different-currency account clears duplicated amount',
      () async {
        final source = _persistedTx(
          amountMinorUnits: 500,
          currency: _usd,
          accountId: 99,
          memo: 'lunch',
        );
        when(() => txRepo.getById(99)).thenAnswer((_) async => source);
        when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 2);
        when(() => accountRepo.getById(99)).thenAnswer((_) async => null);
        when(() => accountRepo.getById(2)).thenAnswer((_) async => _accountJpy);

        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForDuplicate(99);

        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.selectedAccount?.id, _accountJpy.id);
        expect(s.displayCurrency?.code, 'JPY');
        expect(s.amountMinorUnits, 0);
        expect(s.memo, 'lunch');
        expect(s.duplicateSourceId, 99);
      },
    );

    test(
      'TC23: retryHydration preserves duplicate mode after account creation',
      () async {
        final source = _persistedTx(
          amountMinorUnits: 700,
          accountId: 99,
          memo: 'retry me',
        );
        when(() => txRepo.getById(99)).thenAnswer((_) async => source);
        when(() => accountRepo.getById(99)).thenAnswer((_) async => null);
        when(
          () => accountRepo.watchAll(includeArchived: false),
        ).thenAnswer((_) => Stream.value(const <Account>[]));

        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);

        await controller.hydrateForDuplicate(99);
        TransactionFormState s = c.read(transactionFormControllerProvider);
        expect(s, isA<TransactionFormEmpty>());
        expect(
          (s as TransactionFormEmpty).reason,
          TransactionFormEmptyReason.noActiveAccount,
        );

        when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
        when(
          () => accountRepo.watchAll(includeArchived: false),
        ).thenAnswer((_) => Stream.value(const [_account]));

        await controller.retryHydration();
        s = c.read<TransactionFormState>(transactionFormControllerProvider);
        expect(s, isA<TransactionFormData>());
        final data = s as TransactionFormData;
        expect(data.duplicateSourceId, 99);
        expect(data.memo, 'retry me');
        expect(data.amountMinorUnits, 700);
      },
    );
  });

  group('keypad commands', () {
    test('TC30: appendDigit USD shifts to 100 / 1200', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.appendDigit(1);
      controller.appendDigit(2);
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.amountMinorUnits, 1200);
      expect(s.isDirty, isTrue);
    });

    test('TC31: appendDecimal disabled on JPY (decimals=0)', () async {
      when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 2);
      when(() => accountRepo.getById(2)).thenAnswer((_) async => _accountJpy);
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller
        ..appendDigit(1)
        ..appendDigit(2)
        ..appendDigit(3)
        ..appendDecimal()
        ..appendDigit(4);
      // The 4 should append as a regular integer digit because decimal
      // mode never engaged on a zero-decimals currency.
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.amountMinorUnits, 1234);
      expect(s.displayCurrency?.code, 'JPY');
    });

    test('TC32: backspace and clear walk back amount', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller
        ..appendDigit(1)
        ..appendDigit(2)
        ..backspace();
      var s = c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.amountMinorUnits, 100);
      controller.clearAmount();
      s = c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.amountMinorUnits, 0);
    });
  });

  group('type and category coordination', () {
    test('TC40: selectCategory derives pendingType', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.selectCategory(_incomeCategory);
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.pendingType, CategoryType.income);
      expect(s.selectedCategory?.id, _incomeCategory.id);
    });

    test(
      'TC41: setPendingType refuses a swap when category is the opposite type',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.selectCategory(_expenseCategory);
        controller.setPendingType(CategoryType.income);
        // The screen owns the confirm-then-clear flow; the controller
        // alone must not silently drop the category.
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.selectedCategory?.id, _expenseCategory.id);
        expect(s.pendingType, CategoryType.expense);
      },
    );

    test(
      'TC42: clearCategoryForTypeChange drops category and switches type',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.selectCategory(_expenseCategory);
        controller.clearCategoryForTypeChange(CategoryType.income);
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.selectedCategory, isNull);
        expect(s.pendingType, CategoryType.income);
      },
    );
  });

  group('account swap with currency change', () {
    test(
      'TC50: refuses a currency-changing swap when an amount is entered',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.appendDigit(5); // amount = 500 minor units
        controller.selectAccount(_accountJpy);
        // Without the explicit clear flag, the swap is rejected so the
        // screen-level confirm dialog stays the gating step.
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.selectedAccount?.id, _account.id);
        expect(s.amountMinorUnits, 500);
      },
    );

    test(
      'TC51: clearAmountOnCurrencyChange=true clears amount and swaps',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.appendDigit(5);
        controller.selectAccount(
          _accountJpy,
          clearAmountOnCurrencyChange: true,
        );
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.selectedAccount?.id, _accountJpy.id);
        expect(s.displayCurrency?.code, 'JPY');
        expect(s.amountMinorUnits, 0);
      },
    );

    test('TC52: same-currency swap does not require the clear flag', () async {
      const otherUsd = Account(
        id: 3,
        name: 'Other USD',
        accountTypeId: 1,
        currency: _usd,
      );
      when(() => accountRepo.getById(3)).thenAnswer((_) async => otherUsd);
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.appendDigit(5);
      controller.selectAccount(otherUsd);
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.selectedAccount?.id, 3);
      expect(s.amountMinorUnits, 500);
    });
  });

  group('save / delete', () {
    test('TC60: save returns persisted transaction on success', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller
        ..appendDigit(1)
        ..selectCategory(_expenseCategory);
      // Predict the persisted row.
      final saved = _persistedTx(amountMinorUnits: 100, id: 5);
      when(() => txRepo.save(any())).thenAnswer((_) async => saved);
      final result = await controller.save();
      expect(result, saved);
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.isSaving, isFalse);
    });

    test(
      'TC61: save rethrows on repository failure and clears isSaving',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller
          ..appendDigit(1)
          ..selectCategory(_expenseCategory);
        when(() => txRepo.save(any())).thenThrow(Exception('repo offline'));
        await expectLater(controller.save(), throwsA(isA<Exception>()));
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.isSaving, isFalse);
        expect(s, isA<TransactionFormData>()); // not pushed into .error
      },
    );

    test('TC62: save returns null when canSave is false', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd(); // amount=0, category=null
      final result = await controller.save();
      expect(result, isNull);
      verifyNever(() => txRepo.save(any()));
    });

    test('TC63: deleteExisting in Edit mode returns repo result', () async {
      final tx = _persistedTx();
      when(() => txRepo.getById(99)).thenAnswer((_) async => tx);
      when(() => txRepo.delete(99)).thenAnswer((_) async => true);
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForEdit(99);
      final removed = await controller.deleteExisting();
      expect(removed, isTrue);
    });

    test(
      'TC64: deleteExisting returns false when repo returns false',
      () async {
        final tx = _persistedTx();
        when(() => txRepo.getById(99)).thenAnswer((_) async => tx);
        when(() => txRepo.delete(99)).thenAnswer((_) async => false);
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForEdit(99);
        expect(await controller.deleteExisting(), isFalse);
      },
    );

    test(
      'TC65: deleteExisting in Add mode is a no-op (returns false)',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        expect(await controller.deleteExisting(), isFalse);
        verifyNever(() => txRepo.delete(any()));
      },
    );

    test(
      'TC66: mutating commands are ignored while save is in flight',
      () async {
        final completer = Completer<Transaction>();
        when(() => txRepo.save(any())).thenAnswer((_) => completer.future);

        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller
          ..appendDigit(1)
          ..selectCategory(_expenseCategory);

        final saveFuture = controller.save();
        var s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.isSaving, isTrue);

        controller
          ..appendDigit(9)
          ..setMemo('ignored');
        s = c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.amountMinorUnits, 100);
        expect(s.memo, isEmpty);

        completer.complete(_persistedTx(amountMinorUnits: 100, id: 5));
        await saveFuture;
      },
    );

    test(
      'TC67: delete mode disables save and ignores edits until it completes',
      () async {
        final tx = _persistedTx(memo: 'before');
        final completer = Completer<bool>();
        when(() => txRepo.getById(99)).thenAnswer((_) async => tx);
        when(() => txRepo.delete(99)).thenAnswer((_) => completer.future);

        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForEdit(99);

        final deleteFuture = controller.deleteExisting();
        var s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.isDeleting, isTrue);
        expect(s.canSave, isFalse);

        controller
          ..appendDigit(9)
          ..setMemo('ignored');
        s = c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.amountMinorUnits, tx.amountMinorUnits);
        expect(s.memo, 'before');

        completer.complete(true);
        await deleteFuture;
      },
    );
  });

  group('canSave', () {
    test('TC70: false on loading / empty / error', () async {
      const loading = TransactionFormState.loading();
      expect(loading.canSave, isFalse);
      const empty = TransactionFormState.empty(
        reason: TransactionFormEmptyReason.notFound,
      );
      expect(empty.canSave, isFalse);
      final error = TransactionFormState.error(
        Exception('x'),
        StackTrace.current,
      );
      expect(error.canSave, isFalse);
    });

    test(
      'TC71: data: true only when amount + account + category present',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        expect(c.read(transactionFormControllerProvider).canSave, isFalse);
        controller.appendDigit(1);
        expect(c.read(transactionFormControllerProvider).canSave, isFalse);
        controller.selectCategory(_expenseCategory);
        expect(c.read(transactionFormControllerProvider).canSave, isTrue);
      },
    );
  });

  group('currencyTouched', () {
    test('TC80: hydrateForAdd starts with currencyTouched=false', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.currencyTouched, isFalse);
    });

    test('TC81: hydrateForEdit starts with currencyTouched=true', () async {
      final tx = _persistedTx();
      when(() => txRepo.getById(99)).thenAnswer((_) async => tx);
      final c = makeContainer();
      addTearDown(c.dispose);
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForEdit(99);
      final s =
          c.read(transactionFormControllerProvider) as TransactionFormData;
      expect(s.currencyTouched, isTrue);
    });

    test(
      'TC82: account change re-seeds displayCurrency when currencyTouched is false',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller
            .hydrateForAdd(); // starts with USD, currencyTouched=false
        controller.selectAccount(_accountJpy);
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'JPY');
        expect(s.currencyTouched, isFalse);
      },
    );

    test(
      'TC83: account change leaves displayCurrency unchanged when currencyTouched is true',
      () async {
        const eur = Currency(
          code: 'EUR',
          decimals: 2,
          symbol: '€',
          nameL10nKey: 'currency.eur',
        );
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        // User manually picks EUR — sets currencyTouched=true
        controller.selectCurrency(eur);
        var s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'EUR');
        expect(s.currencyTouched, isTrue);
        // Switching account should NOT re-seed currency
        controller.selectAccount(_accountJpy);
        s = c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'EUR');
        expect(s.selectedAccount?.id, _accountJpy.id);
      },
    );

    test(
      'TC84: selectCurrency with non-zero amount refuses without clearAmountOnChange',
      () async {
        const eur = Currency(
          code: 'EUR',
          decimals: 2,
          symbol: '€',
          nameL10nKey: 'currency.eur',
        );
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.appendDigit(5); // amount = 500 minor units
        controller.selectCurrency(eur); // no clearAmountOnChange flag
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        // Currency change should be refused
        expect(s.displayCurrency?.code, 'USD');
        expect(s.amountMinorUnits, 500);
        expect(s.currencyTouched, isFalse);
      },
    );

    test(
      'TC85: selectCurrency with clearAmountOnChange clears amount and sets currencyTouched',
      () async {
        const eur = Currency(
          code: 'EUR',
          decimals: 2,
          symbol: '€',
          nameL10nKey: 'currency.eur',
        );
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.appendDigit(5);
        controller.selectCurrency(eur, clearAmountOnChange: true);
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'EUR');
        expect(s.amountMinorUnits, 0);
        expect(s.currencyTouched, isTrue);
      },
    );

    test(
      'TC86: selectCurrency with zero amount succeeds without clearAmountOnChange',
      () async {
        const eur = Currency(
          code: 'EUR',
          decimals: 2,
          symbol: '€',
          nameL10nKey: 'currency.eur',
        );
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        // amount is 0, no need for clearAmountOnChange flag
        controller.selectCurrency(eur);
        final s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'EUR');
        expect(s.currencyTouched, isTrue);
      },
    );

    test(
      'TC86b: re-selecting the current currency keeps automatic account-driven currency behavior',
      () async {
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();

        var s =
            c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'USD');
        expect(s.currencyTouched, isFalse);

        controller.selectCurrency(_usd);
        s = c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.displayCurrency?.code, 'USD');
        expect(s.currencyTouched, isFalse);

        controller.selectAccount(_accountJpy);
        s = c.read(transactionFormControllerProvider) as TransactionFormData;
        expect(s.selectedAccount?.id, _accountJpy.id);
        expect(s.displayCurrency?.code, 'JPY');
      },
    );

    test(
      'TC87: save persists displayCurrency rather than selectedAccount.currency',
      () async {
        const eur = Currency(
          code: 'EUR',
          decimals: 2,
          symbol: '€',
          nameL10nKey: 'currency.eur',
        );
        final c = makeContainer();
        addTearDown(c.dispose);
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForAdd();
        controller.selectCurrency(eur); // user picks EUR on a USD account
        controller.appendDigit(1);
        controller.selectCategory(_expenseCategory);
        Transaction? capturedTx;
        when(() => txRepo.save(any())).thenAnswer((inv) async {
          capturedTx = inv.positionalArguments.first as Transaction;
          return capturedTx!;
        });
        await controller.save();
        expect(capturedTx?.currency.code, 'EUR');
      },
    );
  });
}
