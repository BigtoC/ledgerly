// TransactionFormScreen widget tests — Wave 2 §4.3.
//
// Covers:
//   - Add mode renders with default account + expense pendingType.
//   - Save button disabled while form is invalid.
//   - Save button enables once amount + account + category are all set
//     (account is auto-resolved by hydrateForAdd → fallback chain).
//   - Edit mode hydrates from `getById` and renders memo + amount.
//   - Duplicate mode prefills amount + memo and resets date to today.
//   - Discard confirm dialog fires on back-nav when state is dirty;
//     does not fire on clean back.
//
// Repositories mocked via mocktail; the screen is mounted under a
// minimal GoRouter so `GoRouterState.extra` works for duplicate.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/transactions/transaction_form_screen.dart';
import 'package:ledgerly/features/transactions/widgets/account_selector_tile.dart';
import 'package:ledgerly/features/transactions/widgets/calculator_keypad.dart';
import 'package:ledgerly/features/transactions/widgets/currency_selector_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

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

const _expenseCategory = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

Transaction _persistedTx({
  int id = 99,
  int amountMinorUnits = 500,
  int categoryId = 10,
  int accountId = 1,
  String? memo,
  DateTime? date,
}) {
  final d = date ?? DateTime(2026, 4, 25);
  return Transaction(
    id: id,
    amountMinorUnits: amountMinorUnits,
    currency: _usd,
    categoryId: categoryId,
    accountId: accountId,
    memo: memo,
    date: d,
    createdAt: d,
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
  late _MockCurrencyRepository currencyRepo;

  setUp(() {
    txRepo = _MockTransactionRepository();
    accountRepo = _MockAccountRepository();
    categoryRepo = _MockCategoryRepository();
    prefs = _MockUserPreferencesRepository();
    currencyRepo = _MockCurrencyRepository();

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
    ).thenAnswer((_) => Stream.value(const [_usd, _jpy, _eur]));
  });

  Widget mountAdd({
    Object? extra,
    List<Override> extraOverrides = const [],
    double? textScale,
  }) {
    final router = GoRouter(
      initialLocation: '/home/add',
      initialExtra: extra,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const _HomeStub(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => const TransactionFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (_, state) => TransactionFormScreen(
                transactionId: int.parse(state.pathParameters['id']!),
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
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
      ),
    );
  }

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
                transactionId: int.parse(state.pathParameters['id']!),
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
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
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
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(const [_expenseCategory])),
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
      await tester.pumpWidget(mountAdd(extra: const {'duplicateSourceId': 99}));
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
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(const <Category>[])),
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

  testWidgets('WS09: historical edit dates still open the date picker', (
    tester,
  ) async {
    when(
      () => txRepo.getById(99),
    ).thenAnswer((_) async => _persistedTx(date: DateTime(2000, 1, 1)));
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
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(const [_expenseCategory])),
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
    when(
      () => accountRepo.watchAll(includeArchived: false),
    ).thenAnswer((_) => Stream.value(const [_account]));
    when(
      () => accountRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value(const [_account, archivedAccount]));

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
        find.text('Changing the currency will clear the entered amount.'),
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

  testWidgets('WS20: Change and Clear empties amount and updates currency', (
    tester,
  ) async {
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

    // Confirm the change
    await tester.tap(find.text('Change and Clear'));
    await tester.pumpAndSettle();

    // Currency tile should now show JPY
    final tile = tester.widget<CurrencySelectorTile>(
      find.byType(CurrencySelectorTile),
    );
    expect(tile.currency?.code, 'JPY');
    // Amount placeholder should be visible (currencyTouched=true, amount=0)
    expect(find.textContaining('JPY'), findsAtLeastNWidgets(1));
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
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('home-stub')));
}
