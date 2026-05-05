// ManageAccountsSheet widget tests.
//
// Opens the sheet via showManageAccountsSheet(context) from a test scaffold
// with a button. Uses fake controllers and mocked repositories. No live DB.
//
// Covers:
//   MAS01 - loading state renders CircularProgressIndicator
//   MAS02 - error state renders error placeholder with "Retry" button
//   MAS03 - data state renders account list (ManageAccountsBody visible)
//   MAS04 - "Create account" CTA button navigates to /settings/manage-accounts/new
//   MAS05 - close button dismisses the sheet
//   MAS06 - row-tap routes to /settings/manage-accounts/:id
//   MAS07 - narrow layout opens a bottom sheet instead of a dialog
//   MAS08 - wide layout keeps the dialog mounted across create-account flow
//   MAS09 - wide layout keeps the dialog mounted across edit-account flow

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
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/settings/settings_controller.dart';
import 'package:ledgerly/features/settings/settings_state.dart';
import 'package:ledgerly/features/settings/widgets/manage_accounts_sheet.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockAccountTypeRepository extends Mock
    implements AccountTypeRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

class _FakeAccountsController extends AccountsController {
  _FakeAccountsController(this._fixed);
  final AccountsState _fixed;

  @override
  Stream<AccountsState> build() async* {
    yield _fixed;
  }
}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController(this._fixed);
  final SettingsState _fixed;

  @override
  Stream<SettingsState> build() async* {
    yield _fixed;
  }
}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _allTestCurrencies = [_usd];

Account _a({
  required int id,
  required String name,
  int accountTypeId = 1,
  Currency currency = _usd,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: accountTypeId,
  currency: currency,
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

const _cashType = AccountType(
  id: 1,
  l10nKey: 'accountType.cash',
  icon: 'wallet',
  color: 10,
  defaultCurrency: _usd,
);

ProviderContainer _makeContainer({
  required AccountsState accountsFixed,
  SettingsState? settingsFixed,
  List<Currency> currencies = _allTestCurrencies,
}) {
  final accountRepo = _MockAccountRepository();
  final typeRepo = _MockAccountTypeRepository();
  final prefs = _MockUserPreferencesRepository();
  final currencyRepo = _MockCurrencyRepository();

  when(
    () => typeRepo.watchAll(includeArchived: true),
  ).thenAnswer((_) => Stream.value([_cashType]));
  when(
    () => currencyRepo.watchAll(),
  ).thenAnswer((_) => Stream.value(currencies));
  when(
    () => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')),
  ).thenAnswer((_) => Stream.value(currencies));

  final overrides = <Override>[
    accountRepositoryProvider.overrideWithValue(accountRepo),
    accountTypeRepositoryProvider.overrideWithValue(typeRepo),
    userPreferencesRepositoryProvider.overrideWithValue(prefs),
    currencyRepositoryProvider.overrideWithValue(currencyRepo),
    accountsControllerProvider.overrideWith(
      () => _FakeAccountsController(accountsFixed),
    ),
  ];

  if (settingsFixed != null) {
    overrides.add(
      settingsControllerProvider.overrideWith(
        () => _FakeSettingsController(settingsFixed),
      ),
    );
  }

  return ProviderContainer(overrides: overrides);
}

Widget _wrapWithOpener({
  required ProviderContainer container,
  Size size = const Size(400, 800),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (ctx, _) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showManageAccountsSheet(context),
                    child: const Text('OPEN'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/settings/manage-accounts/new',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ADD_ACCOUNT'),
                      FilledButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        child: const Text('finish-create-account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/settings/manage-accounts/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('EDIT_ACCOUNT_${state.pathParameters['id']}'),
                      FilledButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        child: const Text('finish-edit-account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_a(id: 0, name: '_'));
  });

  testWidgets('MAS01: loading state renders CircularProgressIndicator', (
    tester,
  ) async {
    final container = _makeContainer(accountsFixed: AccountsState.loading());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapWithOpener(container: container));
    // Use pump instead of pumpAndSettle — the CircularProgressIndicator
    // animates indefinitely when the controller stream never settles, so
    // pumpAndSettle would time out.
    await tester.pump();

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'MAS02: error state renders error placeholder with Retry button',
    (tester) async {
      final container = _makeContainer(
        accountsFixed: AccountsState.error(Exception('test'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapWithOpener(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't load accounts."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets('MAS03: data state renders account list', (tester) async {
    final container = _makeContainer(
      accountsFixed: AccountsState.data(
        active: [
          _wb(_a(id: 1, name: 'Cash')),
          _wb(_a(id: 2, name: 'Savings')),
        ],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapWithOpener(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('Savings'), findsOneWidget);
  });

  testWidgets(
    "MAS04: 'Create account' CTA navigates to /settings/manage-accounts/new",
    (tester) async {
      final container = _makeContainer(
        accountsFixed: AccountsState.data(
          active: [_wb(_a(id: 1, name: 'Cash'))],
          archived: const [],
          defaultAccountId: 1,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapWithOpener(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('ADD_ACCOUNT'), findsOneWidget);
    },
  );

  testWidgets('MAS05: close button dismisses the sheet', (tester) async {
    final container = _makeContainer(
      accountsFixed: AccountsState.data(
        active: [_wb(_a(id: 1, name: 'Cash'))],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapWithOpener(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    // Verify sheet is visible
    expect(find.text('Manage accounts'), findsOneWidget);

    // Tap the close icon button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Sheet should be dismissed
    expect(find.text('Manage accounts'), findsNothing);
  });

  testWidgets('MAS06: row-tap routes to /settings/manage-accounts/:id', (
    tester,
  ) async {
    final container = _makeContainer(
      accountsFixed: AccountsState.data(
        active: [_wb(_a(id: 42, name: 'My Wallet'))],
        archived: const [],
        defaultAccountId: 42,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapWithOpener(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT_ACCOUNT_42'), findsOneWidget);
  });

  testWidgets('MAS07: narrow layout opens a bottom sheet', (tester) async {
    final container = _makeContainer(
      accountsFixed: AccountsState.data(
        active: [_wb(_a(id: 1, name: 'Cash'))],
        archived: const [],
        defaultAccountId: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrapWithOpener(container: container, size: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FractionallySizedBox && widget.heightFactor == 0.75,
      ),
      findsOneWidget,
    );
    expect(find.text('Manage accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'MAS08: wide layout keeps the dialog mounted across create-account flow',
    (tester) async {
      final container = _makeContainer(
        accountsFixed: AccountsState.data(
          active: [_wb(_a(id: 1, name: 'Cash'))],
          archived: const [],
          defaultAccountId: 1,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithOpener(container: container, size: const Size(1000, 800)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('ADD_ACCOUNT'), findsOneWidget);

      await tester.tap(find.text('finish-create-account'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Manage accounts'), findsOneWidget);
    },
  );

  testWidgets(
    'MAS09: wide layout keeps the dialog mounted across edit-account flow',
    (tester) async {
      final container = _makeContainer(
        accountsFixed: AccountsState.data(
          active: [_wb(_a(id: 42, name: 'My Wallet'))],
          archived: const [],
          defaultAccountId: 42,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithOpener(container: container, size: const Size(1000, 800)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('My Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('EDIT_ACCOUNT_42'), findsOneWidget);

      await tester.tap(find.text('finish-edit-account'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Manage accounts'), findsOneWidget);
    },
  );
}
