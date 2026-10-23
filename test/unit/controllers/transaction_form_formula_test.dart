// TransactionFormController — keypad formula persistence.
//
// Covers saving the typed expression alongside the amount, rebuilding a
// working (recalculating, editable) keypad from the stored formula on
// Edit and Duplicate, and the fallbacks when a stored formula cannot be
// trusted.
//
// Repositories mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';
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

const _expenseCategory = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

Transaction _persistedTx({
  int id = 99,
  int amountMinorUnits = 2800,
  Currency currency = _usd,
  String? amountFormula,
}) {
  final d = DateTime(2026, 4, 25);
  return Transaction(
    id: id,
    amountMinorUnits: amountMinorUnits,
    currency: currency,
    categoryId: 10,
    accountId: 1,
    amountFormula: amountFormula,
    date: d,
    createdAt: d,
    updatedAt: d,
  );
}

@Dependencies([TransactionFormController])
void main() {
  setUpAll(() {
    registerFallbackValue(_persistedTx());
  });

  late _MockTransactionRepository txRepo;
  late _MockAccountRepository accountRepo;
  late _MockCategoryRepository categoryRepo;
  late _MockUserPreferencesRepository prefs;
  late StreamController<String> defaultCurrencyCtrl;

  setUp(() {
    txRepo = _MockTransactionRepository();
    accountRepo = _MockAccountRepository();
    categoryRepo = _MockCategoryRepository();
    prefs = _MockUserPreferencesRepository();
    defaultCurrencyCtrl = StreamController<String>.broadcast();

    when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => null);
    when(() => prefs.watchDefaultCurrency())
        .thenAnswer((_) => defaultCurrencyCtrl.stream);
    when(() => accountRepo.getLastUsedActiveAccount())
        .thenAnswer((_) async => null);
    when(() => accountRepo.watchAll(includeArchived: false))
        .thenAnswer((_) => Stream.value(const [_account]));
    when(() => accountRepo.getById(any())).thenAnswer((_) async => _account);
    when(() => categoryRepo.getById(any()))
        .thenAnswer((_) async => _expenseCategory);
    // Echo the saved row back so assertions can read what was persisted.
    when(
      () => txRepo.save(any()),
    ).thenAnswer((inv) async => inv.positionalArguments.first as Transaction);
  });

  tearDown(() async {
    await defaultCurrencyCtrl.close();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Types [keys] on the controller: digits, `.`, `+ - * /`, `=`, `<`
  /// (backspace) and `C` (clear).
  void type(TransactionFormController controller, String keys) {
    for (final key in keys.split('')) {
      switch (key) {
        case '.':
          controller.appendDecimal();
        case '+':
          controller.applyOperator(CalcOperator.add);
        case '-':
          controller.applyOperator(CalcOperator.subtract);
        case '*':
          controller.applyOperator(CalcOperator.multiply);
        case '/':
          controller.applyOperator(CalcOperator.divide);
        case '=':
          controller.equals();
        case '<':
          controller.backspace();
        case 'C':
          controller.clearAmount();
        default:
          controller.appendDigit(int.parse(key));
      }
    }
  }

  @Dependencies([TransactionFormController])
  TransactionFormData data(ProviderContainer c) =>
      c.read(transactionFormControllerProvider) as TransactionFormData;

  group('save', () {
    test('TF01: stores the typed formula and its result', () async {
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.selectCategory(_expenseCategory);
      type(controller, '3.5+10.5+11+3');

      final saved = await controller.save();

      expect(saved!.amountMinorUnits, 2800);
      expect(saved.amountFormula, '3.5+10.5+11+3');
    });

    test('TF02: stores the same formula after pressing =', () async {
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.selectCategory(_expenseCategory);
      type(controller, '3.5+10.5+11+3=');

      final saved = await controller.save();

      expect(saved!.amountMinorUnits, 2800);
      expect(saved.amountFormula, '3.5+10.5+11+3');
    });

    test('TF03: a plain amount stores no formula', () async {
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.selectCategory(_expenseCategory);
      type(controller, '28');

      final saved = await controller.save();

      expect(saved!.amountMinorUnits, 2800);
      expect(saved.amountFormula, isNull);
    });

    test('TF04: a dangling operator is not stored', () async {
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForAdd();
      controller.selectCategory(_expenseCategory);
      type(controller, '1+2+');

      final saved = await controller.save();

      expect(saved!.amountMinorUnits, 300);
      expect(saved.amountFormula, '1+2');
    });
  });

  group('hydrateForEdit', () {
    test(
      'TF10: rebuilds a recalculating keypad from the stored formula',
      () async {
        when(
          () => txRepo.getById(99),
        ).thenAnswer((_) async => _persistedTx(amountFormula: '3.5+10.5+11+3'));
        final c = makeContainer();
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForEdit(99);

        final s = data(c);
        expect(s.amountMinorUnits, 2800);
        expect(s.keypad.showingResult, isTrue);
        expect(s.keypad.amountMinorUnits, 2800);
        expect(s.keypad.formula(decimals: 2), '3.5+10.5+11+3');
        expect(s.isDirty, isFalse);
      },
    );

    test(
      'TF11: editing the loaded formula recalculates and saves it',
      () async {
        when(
          () => txRepo.getById(99),
        ).thenAnswer((_) async => _persistedTx(amountFormula: '3.5+10.5+11+3'));
        final c = makeContainer();
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForEdit(99);

        // Backspace the trailing "3", type "5": 3.5+10.5+11+5 = 30.
        type(controller, '<5');
        expect(data(c).amountMinorUnits, 3000);
        expect(data(c).keypad.formula(decimals: 2), '3.5+10.5+11+5');

        final saved = await controller.save();
        expect(saved!.id, 99);
        expect(saved.amountMinorUnits, 3000);
        expect(saved.amountFormula, '3.5+10.5+11+5');
      },
    );

    test('TF12: extending the loaded formula with an operator', () async {
      when(
        () => txRepo.getById(99),
      ).thenAnswer((_) async => _persistedTx(amountFormula: '3.5+10.5+11+3'));
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForEdit(99);

      type(controller, '*2');
      final saved = await controller.save();

      expect(saved!.amountMinorUnits, 5600);
      expect(saved.amountFormula, '(3.5+10.5+11+3)*2');
    });

    test(
      'TF13: replacing the amount with a plain number clears the formula',
      () async {
        when(
          () => txRepo.getById(99),
        ).thenAnswer((_) async => _persistedTx(amountFormula: '3.5+10.5+11+3'));
        final c = makeContainer();
        final controller = c.read(transactionFormControllerProvider.notifier);
        await controller.hydrateForEdit(99);

        type(controller, 'C42');
        final saved = await controller.save();

        expect(saved!.amountMinorUnits, 4200);
        expect(saved.amountFormula, isNull);
      },
    );

    test('TF14: saving untouched keeps both amount and formula', () async {
      when(
        () => txRepo.getById(99),
      ).thenAnswer((_) async => _persistedTx(amountFormula: '3.5+10.5+11+3'));
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForEdit(99);

      final saved = await controller.save();

      expect(saved!.amountMinorUnits, 2800);
      expect(saved.amountFormula, '3.5+10.5+11+3');
    });

    test('TF15: zero-decimal currency formula', () async {
      when(() => txRepo.getById(99)).thenAnswer(
        (_) async => _persistedTx(
          amountMinorUnits: 4500,
          currency: _jpy,
          amountFormula: '1500*3',
        ),
      );
      final c = makeContainer();
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForEdit(99);

      expect(data(c).amountMinorUnits, 4500);
      expect(data(c).keypad.formula(decimals: 0), '1500*3');
    });

    test(
      'TF16: a formula that no longer gives the stored amount is dropped',
      () async {
        when(() => txRepo.getById(99))
            .thenAnswer((_) async => _persistedTx(amountFormula: '1+2'));
        final c = makeContainer();
        await c
            .read(transactionFormControllerProvider.notifier)
            .hydrateForEdit(99);

        final s = data(c);
        expect(s.amountMinorUnits, 2800);
        expect(s.keypad.amountMinorUnits, 2800);
        expect(s.keypad.formula(decimals: 2), isNull);
      },
    );

    test('TF17: an unparsable formula is dropped', () async {
      when(() => txRepo.getById(99))
          .thenAnswer((_) async => _persistedTx(amountFormula: '3.5+abc'));
      final c = makeContainer();
      await c
          .read(transactionFormControllerProvider.notifier)
          .hydrateForEdit(99);

      final s = data(c);
      expect(s.amountMinorUnits, 2800);
      expect(s.keypad.formula(decimals: 2), isNull);
    });
  });

  group('hydrateForDuplicate', () {
    test('TF20: copies the formula with the amount', () async {
      when(
        () => txRepo.getById(99),
      ).thenAnswer((_) async => _persistedTx(amountFormula: '3.5+10.5+11+3'));
      final c = makeContainer();
      final controller = c.read(transactionFormControllerProvider.notifier);
      await controller.hydrateForDuplicate(99);

      expect(data(c).amountMinorUnits, 2800);
      expect(data(c).keypad.formula(decimals: 2), '3.5+10.5+11+3');

      final saved = await controller.save();
      expect(saved!.id, 0);
      expect(saved.amountFormula, '3.5+10.5+11+3');
    });
  });
}
