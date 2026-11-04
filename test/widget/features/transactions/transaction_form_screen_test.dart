// TransactionFormScreen widget tests — Wave 2 §4.3.
//
// Covers:
//   - Add mode renders with default account and no expense/income toggle;
//     the category picker lists income categories below expense ones.
//   - Save button disabled while form is invalid.
//   - Save button enables once amount + account + category are all set
//     (account is auto-resolved by hydrateForAdd → fallback chain).
//   - Edit mode hydrates from `getById` and renders memo + amount.
//   - Duplicate mode prefills amount + memo and resets date to today.
//   - Discard confirm dialog fires on back-nav when state is dirty;
//     does not fire on clean back.
//   - A failed save or delete shows its snackbar and keeps the form open;
//     deleting a row that is already gone says so and pops; a failed
//     category check shows the generic error with no uncaught error.
//   - Closing the form while it is still loading leaves no uncaught
//     error.
//
// Repositories mocked via mocktail; the screen is mounted under a
// minimal GoRouter so the form's `context.pop` calls work.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/ui/features/categories/view_models/categories_controller.dart';
import 'package:ledgerly/ui/features/transactions/view_models/transaction_form_controller.dart';
import 'package:ledgerly/ui/features/transactions/view_models/transaction_form_state.dart';
import 'package:ledgerly/ui/features/transactions/views/transaction_form_screen.dart';
import 'package:ledgerly/ui/features/transactions/views/account_selector_tile.dart';
import 'package:ledgerly/ui/features/transactions/views/amount_display.dart';
import 'package:ledgerly/ui/features/transactions/views/calculator_keypad.dart';
import 'package:ledgerly/ui/features/transactions/views/category_chip.dart';
import 'package:ledgerly/ui/features/transactions/views/currency_selector_tile.dart';
import 'package:ledgerly/ui/features/transactions/views/date_field.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/l10n/app_localizations_en.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(
  code: 'JPY',
  decimals: 0,
  symbol: '¥',
  nameL10nKey: 'currency.jpy',
);
const _eur = Currency(
  code: 'EUR',
  decimals: 2,
  symbol: '€',
  nameL10nKey: 'currency.eur',
);

const _account = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd);
const _yenAccount = Account(
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
  id: 20,
  icon: 'category',
  color: 0,
  type: CategoryType.income,
  customName: 'Salary',
);

Transaction _persistedTx({
  int id = 99,
  int amountMinorUnits = 500,
  String? memo,
  String? amountFormula,
  DateTime? date,
}) {
  final d = date ?? DateTime(2026, 4, 25);
  return Transaction(
    id: id,
    amountMinorUnits: amountMinorUnits,
    currency: _usd,
    categoryId: 10,
    accountId: 1,
    memo: memo,
    amountFormula: amountFormula,
    date: d,
    createdAt: d,
    updatedAt: d,
  );
}

@Dependencies([TransactionFormController, categoriesByType])
void main() {
  setUpAll(() {
    registerFallbackValue(_persistedTx());
  });

  late _MockTransactionRepository txRepo;
  late _MockAccountRepository accountRepo;
  late _MockCategoryRepository categoryRepo;
  late _MockUserPreferencesRepository prefs;
  late _MockCurrencyRepository currencyRepo;

  setUp(() {
    txRepo = _MockTransactionRepository();
    accountRepo = _MockAccountRepository();
    categoryRepo = _MockCategoryRepository();
    prefs = _MockUserPreferencesRepository();
    currencyRepo = _MockCurrencyRepository();

    when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
    when(() => accountRepo.getLastUsedActiveAccount())
        .thenAnswer((_) async => null);
    when(() => accountRepo.getById(1)).thenAnswer((_) async => _account);
    when(() => accountRepo.watchAll(includeArchived: false))
        .thenAnswer((_) => Stream.value(const [_account]));
    when(() => categoryRepo.getById(10))
        .thenAnswer((_) async => _expenseCategory);
    // The category picker also lists income categories.
    when(
      () => categoryRepo.watchAll(
        type: CategoryType.income,
        includeArchived: false,
      ),
    ).thenAnswer((_) => Stream.value(const <Category>[]));
    when(() => currencyRepo.watchAll(includeTokens: false))
        .thenAnswer((_) => Stream.value(const [_usd, _jpy, _eur]));
  });

  @Dependencies([TransactionFormController, categoriesByType])
  Widget mountAdd({
    TransactionFormMode mode = const AddTransactionMode(),
    List<Override> extraOverrides = const [],
    double? textScale,
    Duration? Function(int retryCount, Object error)? retry,
  }) {
    final router = GoRouter(
      initialLocation: '/home/add',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const _HomeStub(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => TransactionFormScreen(mode: mode),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (_, state) => TransactionFormScreen(
                mode: EditTransactionMode(
                  transactionId: int.parse(state.pathParameters['id']!),
                ),
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
      retry: retry,
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        accountRepositoryProvider.overrideWithValue(accountRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
        currencyRepositoryProvider.overrideWithValue(currencyRepo),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: textScale == null
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
      ),
    );
  }

  @Dependencies([TransactionFormController, categoriesByType])
  Widget mountEdit(int id, {double? textScale}) {
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
                mode: EditTransactionMode(
                  transactionId: int.parse(state.pathParameters['id']!),
                ),
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
        currencyRepositoryProvider.overrideWithValue(currencyRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: textScale == null
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
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
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(const [_expenseCategory])),
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
      await tester.pumpWidget(
        mountAdd(mode: const DuplicateTransactionMode(sourceTransactionId: 99)),
      );
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
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(const <Category>[])),
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

  testWidgets('WS08b: Add mode has no expense/income toggle', (tester) async {
    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<CategoryType>), findsNothing);
  });

  testWidgets('WS08c: an income category can be picked straight away', (
    tester,
  ) async {
    await tester.pumpWidget(
      mountAdd(
        extraOverrides: [
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(const [_expenseCategory])),
          categoriesByTypeProvider(CategoryType.income)
              .overrideWith((ref) => Stream.value(const [_incomeCategory])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();
    expect(find.text('Pick income category'), findsOneWidget);
    await tester.tap(find.text('Salary'));
    await tester.pumpAndSettle();

    expect(find.text('Salary · Income'), findsOneWidget);
    expect(find.text('Select a category'), findsNothing);
  });

  testWidgets('WS08d: income-only categories open the picker, not Settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      mountAdd(
        extraOverrides: [
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(const <Category>[])),
          categoriesByTypeProvider(CategoryType.income)
              .overrideWith((ref) => Stream.value(const [_incomeCategory])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();

    expect(find.text('categories-stub'), findsNothing);
    expect(find.text('Salary'), findsOneWidget);
  });

  testWidgets('WS09: historical edit dates still open the date picker', (
    tester,
  ) async {
    when(() => txRepo.getById(99))
        .thenAnswer((_) async => _persistedTx(date: DateTime(2000, 1, 1)));
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
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(const [_expenseCategory])),
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

  // M6 Unit 8 — accessibility: PRD a11y requirement that the form
  // (with its fixed-height keypad above the soft keyboard) survives
  // 2× text scale. The form's scrollable Column is `Expanded` above
  // the keypad, so growing every text by 2× must not produce overflow
  // exceptions.
  testWidgets('WS12: 2× text scale survives in Add mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(mountAdd(textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Save button + AppBar title still render at 2× scale.
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('WS13: 2× text scale survives in Edit mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => txRepo.getById(99)).thenAnswer(
      (_) async => _persistedTx(memo: 'A long memo that pushes the form a bit'),
    );

    await tester.pumpWidget(mountEdit(99, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('WS14: memo keyboard does not move the fixed keypad', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.resetViewInsets());

    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    final keypadBefore = tester.getRect(find.byType(CalculatorKeypad));
    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();
    final keypadAfter = tester.getRect(find.byType(CalculatorKeypad));

    expect(keypadAfter.top, keypadBefore.top);
    expect(keypadAfter.bottom, keypadBefore.bottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WS14b: memo field is single-line and done closes keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    final memoFieldFinder = find.widgetWithText(TextField, 'Memo');
    final memoField = tester.widget<TextField>(memoFieldFinder);

    expect(memoField.maxLines, 1);
    expect(memoField.textInputAction, TextInputAction.done);

    await tester.showKeyboard(memoFieldFinder);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('WS15: account picker lists active accounts only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const archivedAccount = Account(
      id: 2,
      name: 'Archived Cash',
      accountTypeId: 1,
      currency: _usd,
      isArchived: true,
    );
    when(() => accountRepo.watchAll(includeArchived: false))
        .thenAnswer((_) => Stream.value(const [_account]));
    when(() => accountRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const [_account, archivedAccount]));

    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AccountSelectorTile));
    await tester.pumpAndSettle();

    expect(find.text('Pick account'), findsOneWidget);
    expect(find.text('Cash'), findsAtLeastNWidgets(1));
    expect(find.text('Archived Cash'), findsNothing);
    verify(() => accountRepo.watchAll(includeArchived: false)).called(1);
    verifyNever(() => accountRepo.watchAll(includeArchived: true));
  });

  testWidgets('WS16: currency row renders current displayCurrency code', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    // The CurrencySelectorTile should be visible in the form
    expect(find.byType(CurrencySelectorTile), findsOneWidget);
    // USD is seeded from the default account
    expect(find.text('USD'), findsAtLeastNWidgets(1));
  });

  testWidgets('WS17b: currency picker search filters by code and full name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CurrencySelectorTile));
    await tester.pumpAndSettle();

    // All currencies should be visible initially
    expect(find.text('USD'), findsAtLeastNWidgets(1));
    expect(find.text('JPY'), findsAtLeastNWidgets(1));
    expect(find.text('EUR'), findsAtLeastNWidgets(1));

    // Search by code — use the controller directly to avoid
    // multiple-EditableText conflicts in the test framework.
    final searchField = find.widgetWithText(TextField, 'Search currencies');
    final textField = tester.widget<TextField>(searchField);
    final controller = textField.controller!;
    controller.text = 'JP';
    controller.selection = const TextSelection.collapsed(offset: 2);
    textField.onChanged?.call('JP');
    await tester.pumpAndSettle();

    // JPY should be visible, USD and EUR should be filtered out.
    expect(find.text('JPY'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('txCurrencyPicker:USD')), findsNothing);
    expect(find.byKey(const ValueKey('txCurrencyPicker:EUR')), findsNothing);

    // Search by full name
    controller.text = 'Euro';
    controller.selection = const TextSelection.collapsed(offset: 4);
    textField.onChanged?.call('Euro');
    await tester.pumpAndSettle();

    expect(find.text('EUR'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('txCurrencyPicker:USD')), findsNothing);
    expect(find.byKey(const ValueKey('txCurrencyPicker:JPY')), findsNothing);
  });

  testWidgets(
    'WS17c: currency picker shows no-results message for unmatched search',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CurrencySelectorTile));
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(TextField, 'Search currencies');
      final textField = tester.widget<TextField>(searchField);
      final controller = textField.controller!;
      controller.text = 'ZZZZZ';
      controller.selection = const TextSelection.collapsed(offset: 5);
      textField.onChanged?.call('ZZZZZ');
      await tester.pumpAndSettle();

      expect(find.text('No currencies found'), findsOneWidget);
    },
  );

  testWidgets(
    'WS18: changing currency with non-zero amount shows Change and Clear dialog',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      // Enter an amount
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Open currency picker
      await tester.tap(find.byType(CurrencySelectorTile));
      await tester.pumpAndSettle();

      // Tap a different currency
      await tester.tap(find.text('JPY').first);
      await tester.pumpAndSettle();

      // Confirm dialog should appear
      expect(
        find.text(
          'Changing the currency will clear the current amount or calculation.',
        ),
        findsOneWidget,
      );
      expect(find.text('Change and Clear'), findsOneWidget);
    },
  );

  testWidgets('WS19: cancel keeps old currency and amount', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(mountAdd());
    await tester.pumpAndSettle();

    // Enter an amount
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    // Open currency picker
    await tester.tap(find.byType(CurrencySelectorTile));
    await tester.pumpAndSettle();

    // Tap JPY
    await tester.tap(find.text('JPY').first);
    await tester.pumpAndSettle();

    // Dismiss dialog via cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Currency tile should still show USD
    final tile = tester.widget<CurrencySelectorTile>(
      find.byType(CurrencySelectorTile),
    );
    expect(tile.currency?.code, 'USD');
  });

  testWidgets(
    'WS21: account switch after manual currency pick does not show destructive dialog',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      // Enter an amount
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Manually pick EUR (sets currencyTouched=true)
      await tester.tap(find.byType(CurrencySelectorTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change and Clear'));
      await tester.pumpAndSettle();

      // Verify currency is now EUR
      final currencyTile = tester.widget<CurrencySelectorTile>(
        find.byType(CurrencySelectorTile),
      );
      expect(currencyTile.currency?.code, 'EUR');

      // Now switch account — the destructive dialog should NOT appear
      // because currencyTouched=true means account changes leave
      // displayCurrency unchanged.
      await tester.tap(find.byType(AccountSelectorTile));
      await tester.pumpAndSettle();

      // The account picker should be open, not a confirmation dialog
      expect(find.text('Pick account'), findsOneWidget);
      expect(find.text('Switch currency?'), findsNothing);
    },
  );

  testWidgets(
    'WS22: operator flow shows expression history and a fixed-precision result',
    (tester) async {
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Equals'));
      await tester.pumpAndSettle();

      final display = find.byType(AmountDisplay);
      expect(
        find.descendant(of: display, matching: find.textContaining('12 + 5 =')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: display, matching: find.text('17.00')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'WS23: changing currency during an active expression still shows the Change and Clear dialog even when the visible amount is zero',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CurrencySelectorTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JPY').first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Changing the currency will clear the current amount or calculation.',
        ),
        findsOneWidget,
      );
      expect(find.text('Change and Clear'), findsOneWidget);
    },
  );

  testWidgets(
    'WS23b: changing account during an active expression shows the destructive dialog even when the visible amount is zero',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => accountRepo.watchAll(includeArchived: false))
          .thenAnswer((_) => Stream.value(const [_account, _yenAccount]));

      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AccountSelectorTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yen').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('amount or calculation'), findsOneWidget);
      expect(find.textContaining('Clear'), findsOneWidget);
    },
  );

  testWidgets(
    'WS24: confirming the destructive dialog clears the active expression and updates currency',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      final display = find.byType(AmountDisplay);
      final pendingExpression = find.descendant(
        of: display,
        matching: find.text('1 +'),
      );
      expect(pendingExpression, findsOneWidget);

      await tester.tap(find.byType(CurrencySelectorTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JPY').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change and Clear'));
      await tester.pumpAndSettle();

      final tile = tester.widget<CurrencySelectorTile>(
        find.byType(CurrencySelectorTile),
      );
      expect(tile.currency?.code, 'JPY');
      expect(pendingExpression, findsNothing);
    },
  );

  testWidgets(
    'WS25: divide-by-zero leaves the form unsaveable and keeps the expression visible',
    (tester) async {
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('÷'));
      await tester.pumpAndSettle();
      // '0' appears both on the keypad and in the amount display — tap
      // the keypad button specifically via its position in the keypad.
      await tester.tap(find.text('0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Equals'));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);

      final display = find.byType(AmountDisplay);
      expect(
        find.descendant(of: display, matching: find.textContaining('7 ÷ 0 =')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'WS26: 2x text scale still shows the expression history and result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(mountAdd(textScale: 2.0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Equals'));
      await tester.pumpAndSettle();

      expect(find.text('+'), findsOneWidget);
      expect(find.textContaining('1 + 5 ='), findsOneWidget);
      expect(find.text('6.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'WS27: chained operators keep the running total (1 + 2 + 4 = 7)',
    (tester) async {
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      for (final key in ['1', '+', '2', '+', '4']) {
        await tester.tap(find.text(key).last);
        await tester.pumpAndSettle();
      }

      final display = find.byType(AmountDisplay);
      expect(
        find.descendant(of: display, matching: find.text('1 + 2 +')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Equals'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: display,
          matching: find.textContaining('1 + 2 + 4 ='),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: display, matching: find.text('7.00')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'WS28: Save without pressing = persists the finished calculation',
    (tester) async {
      Transaction? capturedTx;
      when(() => txRepo.save(any())).thenAnswer((inv) async {
        capturedTx = inv.positionalArguments.first as Transaction;
        return capturedTx!;
      });

      await tester.pumpWidget(
        mountAdd(
          extraOverrides: [
            categoriesByTypeProvider(CategoryType.expense)
                .overrideWith((ref) => Stream.value(const [_expenseCategory])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      for (final key in ['1', '+', '2']) {
        await tester.tap(find.text(key).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(capturedTx?.amountMinorUnits, 300);
    },
  );

  testWidgets(
    'WS29: a saved formula reloads, recalculates, and saves after editing',
    (tester) async {
      when(() => txRepo.getById(99)).thenAnswer(
        (_) async => _persistedTx(
          amountMinorUnits: 2800,
          amountFormula: '3.5+10.5+11+3',
        ),
      );
      Transaction? capturedTx;
      when(() => txRepo.save(any())).thenAnswer((inv) async {
        capturedTx = inv.positionalArguments.first as Transaction;
        return capturedTx!;
      });

      await tester.pumpWidget(mountEdit(99));
      await tester.pumpAndSettle();

      final display = find.byType(AmountDisplay);
      expect(
        find.descendant(
          of: display,
          matching: find.text('3.5 + 10.5 + 11 + 3 ='),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: display, matching: find.text('28.00')),
        findsOneWidget,
      );

      // Backspace the trailing 3 and type 5: 3.5 + 10.5 + 11 + 5.
      await tester.tap(find.byTooltip('Backspace'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: display, matching: find.text('3.5 + 10.5 + 11 +')),
        findsOneWidget,
      );
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(capturedTx?.id, 99);
      expect(capturedTx?.amountMinorUnits, 3000);
      expect(capturedTx?.amountFormula, '3.5+10.5+11+5');
    },
  );

  testWidgets('WS30: a failed save shows the save-failed snackbar', (
    tester,
  ) async {
    when(() => txRepo.getById(99)).thenAnswer((_) async => _persistedTx());
    when(() => txRepo.save(any())).thenThrow(Exception('db down'));

    await tester.pumpWidget(mountEdit(99));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().txSaveFailedSnackbar),
      findsOneWidget,
    );
    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('home-stub'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WS31: a failed delete shows the delete-failed snackbar', (
    tester,
  ) async {
    when(() => txRepo.getById(99)).thenAnswer((_) async => _persistedTx());
    when(() => txRepo.delete(99)).thenThrow(Exception('db down'));

    await tester.pumpWidget(mountEdit(99));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().txDeleteFailedSnackbar),
      findsOneWidget,
    );
    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('home-stub'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WS32: deleting a row that is already gone says so and pops', (
    tester,
  ) async {
    when(() => txRepo.getById(99)).thenAnswer((_) async => _persistedTx());
    when(() => txRepo.delete(99)).thenAnswer((_) async => false);

    await tester.pumpWidget(mountEdit(99));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().txTransactionNotFound),
      findsOneWidget,
    );
    expect(find.text('home-stub'), findsOneWidget);
    expect(find.text('Edit transaction'), findsNothing);
  });

  testWidgets(
    'WS33: a failed category check shows the generic error, uncaught-free',
    (tester) async {
      await tester.pumpWidget(
        mountAdd(
          // Production never retries a failed provider (bootstrap.dart).
          retry: noProviderRetry,
          extraOverrides: [
            categoriesByTypeProvider(CategoryType.expense)
                .overrideWith((ref) => Stream.error(Exception('db down'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().errorSnackbarGeneric),
        findsOneWidget,
      );
      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.text('categories-stub'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WS34: closing the form while it is still loading is uncaught-free',
    (tester) async {
      final read = Completer<Transaction?>();
      when(() => txRepo.getById(99)).thenAnswer((_) => read.future);

      await tester.pumpWidget(mountEdit(99));
      await tester.pump();
      verify(() => txRepo.getById(99)).called(1);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('home-stub'), findsOneWidget);

      read.complete(_persistedTx());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  // Issue #100 — on a normal phone the form fits above the keypad
  // without scrolling: two selector tiles per row and a shorter amount
  // box. On a shorter screen the keypad's keys shrink, down to the 48dp
  // tap target; only past that does the form scroll, never the keypad.
  group('compact form (issue #100)', () {
    // The reporter's Android phone (1220×2656 px at ~3.2 dpr) without its
    // status and gesture bars.
    const phone = Size(381, 760);
    // An iPhone SE (375×667) without its status bar.
    const shortPhone = Size(375, 647);

    // The test font's glyphs are 1em wide, about twice Roboto's, so every
    // half-width tile value would wrap. Measure with the font phones use.
    // Fonts stay loaded for the rest of the file, so keep this group last.
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final roboto = File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(roboto)))).load();
    });

    Future<void> setSurface(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    double keyHeight(WidgetTester tester) => tester
        .getSize(
          find
              .ancestor(of: find.text('7'), matching: find.byType(Material))
              .first,
        )
        .height;

    @Dependencies([TransactionFormController, categoriesByType])
    ScrollPosition formScroll(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(TransactionFormScreen),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  axisDirectionToAxis(w.axisDirection) == Axis.vertical,
            ),
          ),
        )
        .position;

    /// The tallest Add form: a category picked (memo chips showing), an
    /// expression in progress (formula line showing) and the "Add to
    /// shopping list" action.
    @Dependencies([TransactionFormController, categoriesByType])
    Future<void> pumpTallestAddForm(
      WidgetTester tester, {
      double? textScale,
    }) async {
      when(
        () =>
            txRepo.watchRecentMemosForCategory(10, limit: any(named: 'limit')),
      ).thenAnswer((_) => Stream.value(const ['lunch', 'coffee']));
      await tester.pumpWidget(
        mountAdd(
          textScale: textScale,
          extraOverrides: [
            categoriesByTypeProvider(CategoryType.expense)
                .overrideWith((ref) => Stream.value(const [_expenseCategory])),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      for (final key in ['1', '+', '2']) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'coffee'), findsOneWidget);
      expect(find.text('1 +'), findsOneWidget);
    }

    /// The whole keypad is on screen with keys of at least 48dp, and the
    /// form above it reaches its last control by scrolling.
    @Dependencies([TransactionFormController, categoriesByType])
    Future<void> expectKeypadWholeAndFormScrolls(
      WidgetTester tester,
      Size surface,
    ) async {
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(CalculatorKeypad)).bottom,
        surface.height,
      );
      expect(keyHeight(tester), 48);
      expect(formScroll(tester).maxScrollExtent, greaterThan(0));

      final action = find.byKey(const Key('addToShoppingListButton'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(CalculatorKeypad)).top),
      );
    }

    testWidgets('WS40: category and account share the first row', (
      tester,
    ) async {
      await setSurface(tester, phone);
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      final category = tester.getRect(find.byType(CategoryChip));
      final account = tester.getRect(find.byType(AccountSelectorTile));
      expect(account.top, category.top);
      expect(account.left, greaterThanOrEqualTo(category.right));
    });

    testWidgets('WS41: currency and date share the row below', (tester) async {
      await setSurface(tester, phone);
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();

      final category = tester.getRect(find.byType(CategoryChip));
      final currency = tester.getRect(find.byType(CurrencySelectorTile));
      final date = tester.getRect(find.byType(DateField));
      expect(date.top, currency.top);
      expect(date.left, greaterThanOrEqualTo(currency.right));
      expect(currency.top, greaterThanOrEqualTo(category.bottom));
    });

    testWidgets('WS42: half-width tiles drop the chevron', (tester) async {
      await setSurface(tester, phone);
      await tester.pumpWidget(mountAdd());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('WS42b: a picked category drops the chevron too', (
      tester,
    ) async {
      await setSurface(tester, phone);
      await pumpTallestAddForm(tester);

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('WS43: the tallest Add form fits the phone unscrolled', (
      tester,
    ) async {
      await setSurface(tester, phone);
      await pumpTallestAddForm(tester);

      expect(tester.takeException(), isNull);
      expect(formScroll(tester).maxScrollExtent, 0);
      expect(keyHeight(tester), 56);
      final action = find.byKey(const Key('addToShoppingListButton'));
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(CalculatorKeypad)).top),
      );
    });

    testWidgets('WS44: on a short phone the keys shrink so Edit fits', (
      tester,
    ) async {
      await setSurface(tester, shortPhone);
      when(
        () =>
            txRepo.watchRecentMemosForCategory(10, limit: any(named: 'limit')),
      ).thenAnswer((_) => Stream.value(const ['lunch', 'coffee']));
      when(() => txRepo.getById(99))
          .thenAnswer((_) async => _persistedTx(memo: 'lunch'));
      await tester.pumpWidget(mountEdit(99));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ActionChip, 'coffee'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(formScroll(tester).maxScrollExtent, 0);
      expect(keyHeight(tester), allOf(greaterThanOrEqualTo(48), lessThan(56)));
    });

    testWidgets('WS45: past 48dp keys, the form scrolls, not the keypad', (
      tester,
    ) async {
      await setSurface(tester, shortPhone);
      await pumpTallestAddForm(tester);

      await expectKeypadWholeAndFormScrolls(tester, shortPhone);
    });

    testWidgets('WS46: at 2× text the form scrolls above a whole keypad', (
      tester,
    ) async {
      await setSurface(tester, phone);
      await pumpTallestAddForm(tester, textScale: 2);

      await expectKeypadWholeAndFormScrolls(tester, phone);
    });

    /// Whether [text] rendered in full rather than cut off by an ellipsis.
    bool shownInFull(WidgetTester tester, String text) => !tester
        .renderObject<RenderParagraph>(find.text(text))
        .didExceedMaxLines;

    @Dependencies([TransactionFormController, categoriesByType])
    Future<void> pumpInvestmentEdit(
      WidgetTester tester, {
      double? textScale,
    }) async {
      when(() => categoryRepo.getById(10)).thenAnswer(
        (_) async => const Category(
          id: 10,
          icon: 'category',
          color: 0,
          type: CategoryType.expense,
          l10nKey: 'category.investment',
        ),
      );
      when(() => txRepo.getById(99)).thenAnswer((_) async => _persistedTx());
      await tester.pumpWidget(mountEdit(99, textScale: textScale));
      await tester.pumpAndSettle();
    }

    testWidgets('WS47: a half-width tile wraps rather than cut its value', (
      tester,
    ) async {
      // The type is the form's only expense/income hint, and two seeded
      // categories are both called "Investment".
      await setSurface(tester, phone);
      await pumpInvestmentEdit(tester);

      expect(tester.takeException(), isNull);
      expect(shownInFull(tester, 'Investment · Expense'), isTrue);
    });

    testWidgets('WS48: at 2× text the tile values still show in full', (
      tester,
    ) async {
      await setSurface(tester, phone);
      await pumpInvestmentEdit(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      for (final text in ['Investment · Expense', 'Cash', 'Apr 25, 2026']) {
        expect(shownInFull(tester, text), isTrue, reason: text);
      }
    });
  });
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('home-stub')));
}
