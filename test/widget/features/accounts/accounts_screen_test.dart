// AccountsScreen widget tests (plan §3.3, §4, §7).
//
// Exercises the screen directly with a fake `AccountsController` and
// mocked repositories. No live DB.
//
// Covers:
//   - Data state renders active rows, default badge on the correct tile,
//     and the archived section when archived rows exist.
//   - Empty-state CTA renders only when every account is archived.
//   - FAB is wired to the list's CTA (no route navigation in the test).
//   - Archive action surfaces the undo snackbar.
//   - Balance renders via `money_formatter` in the account's native
//     currency — verified for USD, JPY, and TWD.
//   - 2× text scale survives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/accounts/accounts_controller.dart';
import 'package:ledgerly/features/accounts/accounts_screen.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockAccountTypeRepository extends Mock
    implements AccountTypeRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _twd = Currency(code: 'TWD', decimals: 2, symbol: r'NT$');

/// All currencies available in the test suite.
const _allTestCurrencies = [_usd, _jpy, _twd];

Account _a({
  required int id,
  required String name,
  int accountTypeId = 1,
  Currency currency = _usd,
  int openingBalanceMinorUnits = 0,
  int? sortOrder,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: accountTypeId,
  currency: currency,
  openingBalanceMinorUnits: openingBalanceMinorUnits,
  sortOrder: sortOrder,
  isArchived: isArchived,
);

AccountWithBalance _wb(
  Account a, {
  Map<String, int> balances = const {},
  AccountRowAffordance affordance = AccountRowAffordance.archive,
}) => AccountWithBalance(
  account: a,
  balancesByCurrency: balances,
  affordance: affordance,
);

class _FakeAccountsController extends AccountsController {
  _FakeAccountsController(this._fixed);
  final AccountsState _fixed;

  @override
  Stream<AccountsState> build() async* {
    yield _fixed;
  }
}

class _StubRouter {
  static GoRouter build(Widget home) {
    return GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/accounts/new',
          builder: (_, _) => const Scaffold(body: Text('ADD_ACCOUNT')),
        ),
        GoRoute(
          path: '/accounts/:id',
          builder: (ctx, state) => Scaffold(
            body: Text('EDIT_ACCOUNT_${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  }
}

Widget _wrap({required ProviderContainer container, double textScale = 1.0}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      routerConfig: _StubRouter.build(const AccountsScreen()),
    ),
  );
}

ProviderContainer _makeContainer({
  required AccountRepository accountRepo,
  required AccountTypeRepository typeRepo,
  required UserPreferencesRepository prefs,
  required AccountsState fixed,
  List<Currency> currencies = _allTestCurrencies,
}) {
  final currencyRepo = _MockCurrencyRepository();
  when(
    () => currencyRepo.watchAll(),
  ).thenAnswer((_) => Stream.value(currencies));
  when(
    () => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')),
  ).thenAnswer((_) => Stream.value(currencies));

  return ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(accountRepo),
      accountTypeRepositoryProvider.overrideWithValue(typeRepo),
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      accountsControllerProvider.overrideWith(
        () => _FakeAccountsController(fixed),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_a(id: 0, name: '_'));
  });

  const cashType = AccountType(
    id: 1,
    l10nKey: 'accountType.cash',
    icon: 'wallet',
    color: 10,
    defaultCurrency: _usd,
  );

  testWidgets('AS01: data state renders active accounts with default badge', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(_a(id: 1, name: 'Cash')),
          _wb(_a(id: 2, name: 'Savings')),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    // 'Cash' appears twice per row (account name + account-type label
    // subtitle). Savings has a unique name.
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('AS02: empty-state CTA renders when every account is archived', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: const [],
        archived: [_wb(_a(id: 1, name: 'OldCard', isArchived: true))],
        defaultAccountId: null,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('No active accounts'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('AS03: FAB opens Add Account route', (tester) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [_wb(_a(id: 1, name: 'Cash'))],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('ADD_ACCOUNT'), findsOneWidget);
  });

  testWidgets('AS04: archive action via overflow menu shows undo snackbar', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));
    when(() => accountRepo.archive(2)).thenAnswer((_) async {});

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(
            _a(id: 1, name: 'Cash'),
            affordance: AccountRowAffordance.archiveBlocked,
          ),
          _wb(
            _a(id: 2, name: 'Spare'),
            affordance: AccountRowAffordance.archive,
          ),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accountTile:2:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();

    expect(find.text('Account archived'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    verify(() => accountRepo.archive(2)).called(1);
  });

  testWidgets('AS05: balance renders in native currency (USD + JPY + TWD)', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(
            _a(id: 1, name: 'US', currency: _usd),
            balances: {'USD': 12345},
          ),
          _wb(
            _a(id: 2, name: 'JP', currency: _jpy),
            balances: {'JPY': 9999},
          ),
          _wb(
            _a(id: 3, name: 'TW', currency: _twd),
            balances: {'TWD': 5000},
          ),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$123.45'), findsOneWidget);
    expect(find.textContaining('¥9,999'), findsOneWidget);
    expect(find.textContaining(r'NT$50.00'), findsOneWidget);
  });

  testWidgets('AS06: 2x text scale survives', (tester) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(
            _a(
              id: 1,
              name: 'An exceedingly long account name for the list row',
            ),
            balances: {'USD': 1000},
          ),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('AS07: archived section renders under Archived header', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [_wb(_a(id: 1, name: 'Cash'))],
        archived: [_wb(_a(id: 2, name: 'OldCard', isArchived: true))],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('OldCard'), findsOneWidget);
  });

  testWidgets('AS08: multi-currency tile renders grouped balance lines', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(
            _a(id: 1, name: 'Mixed', currency: _usd),
            balances: {'USD': 12345, 'JPY': 50000},
          ),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$123.45'), findsOneWidget);
    expect(find.textContaining('¥50,000'), findsOneWidget);
  });

  testWidgets('AS08b: exactly three currencies render all groups', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(
            _a(id: 1, name: 'Mixed', currency: _usd),
            balances: {'USD': 12345, 'JPY': 50000, 'TWD': 99900},
          ),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$123.45'), findsOneWidget);
    expect(find.textContaining('¥50,000'), findsOneWidget);
    expect(find.textContaining(r'NT$999.00'), findsOneWidget);
    expect(find.textContaining('+1 more'), findsNothing);
  });

  testWidgets('AS09: 2x text scale with multi-currency tile survives', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(
      () => typeRepo.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([cashType]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: AccountsState.data(
        active: [
          _wb(
            _a(id: 1, name: 'Mixed', currency: _usd),
            balances: {'USD': 12345, 'JPY': 50000, 'TWD': 99900},
          ),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
