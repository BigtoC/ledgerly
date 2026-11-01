// ManageAccountsBody widget tests.
//
// Exercises the body widget directly with a fake `AccountsController` and
// mocked repositories. No live DB.
//
// Covers:
//   MAB01 - active rows render with default badge on the correct tile
//   MAB02 - archived section renders under "Archived" header
//   MAB03 - empty-state text renders when both active AND archived are empty
//   MAB04 - archive action via overflow menu shows undo snackbar
//   MAB05 - balance renders in native currency (USD, JPY, TWD)
//   MAB06 - 2× text scale survives
//   MAB07 - Undo after the archived row was deleted is a silent no-op
//   MAB08 - Undo restores the bottom row of the Active card after it moved
//   MAB09 - archive blocked by an active recurring rule shows its message
//   MAB10 - delete blocked because the account is in use shows its message
//   MAB11 - a failed Undo shows the generic error snackbar
//   MAB12 - a later snackbar shows while an Undo snackbar is up

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/exchange_rates_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/accounts/accounts_controller.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/accounts/widgets/manage_accounts_body.dart';
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

const _allTestCurrencies = [_usd, _jpy, _twd];

Account _a({
  required int id,
  required String name,
  Currency currency = _usd,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: 1,
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

class _FakeAccountsController extends AccountsController {
  _FakeAccountsController(this._fixed, [this._updates]);
  final AccountsState _fixed;
  final Stream<AccountsState>? _updates;

  @override
  Stream<AccountsState> build() async* {
    yield _fixed;
    if (_updates != null) yield* _updates;
  }
}

/// Renders [ManageAccountsBody] from the controller's live state, the way
/// ManageAccountsSheet does, so rows move when the state changes.
@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class _LiveBody extends ConsumerWidget {
  const _LiveBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsControllerProvider).value;
    return state is AccountsData
        ? ManageAccountsBody(data: state)
        : const SizedBox.shrink();
  }
}

@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class _StubRouter {
  static GoRouter build(AccountsData data, {bool live = false}) {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: live ? const _LiveBody() : ManageAccountsBody(data: data),
          ),
        ),
        GoRoute(
          path: '/settings/manage-accounts/new',
          builder: (_, _) => const Scaffold(body: Text('ADD_ACCOUNT')),
        ),
        GoRoute(
          path: '/settings/manage-accounts/:id',
          builder: (ctx, state) => Scaffold(
            body: Text('EDIT_ACCOUNT_${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  }
}

@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
Widget _wrap({
  required ProviderContainer container,
  required AccountsData data,
  double textScale = 1.0,
  bool live = false,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      routerConfig: _StubRouter.build(data, live: live),
    ),
  );
}

@Dependencies([AccountsController])
ProviderContainer _makeContainer({
  required AccountRepository accountRepo,
  required AccountTypeRepository typeRepo,
  required UserPreferencesRepository prefs,
  required AccountsState fixed,
  Stream<AccountsState>? updates,
}) {
  final currencyRepo = _MockCurrencyRepository();
  when(() => currencyRepo.watchAll())
      .thenAnswer((_) => Stream.value(_allTestCurrencies));
  when(() => currencyRepo.watchAll(includeTokens: any(named: 'includeTokens')))
      .thenAnswer((_) => Stream.value(_allTestCurrencies));

  final container = ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(accountRepo),
      accountTypeRepositoryProvider.overrideWithValue(typeRepo),
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      accountsControllerProvider.overrideWith(
        () => _FakeAccountsController(fixed, updates),
      ),
    ],
  );
  // In the app, ManageAccountsSheet watches accountsControllerProvider
  // while it shows this body. Mirror that so the auto-dispose controller
  // stays alive across the async gaps in its commands; since Riverpod 3.4
  // an unlistened auto-dispose provider is disposed on the next microtask.
  container.listen(accountsControllerProvider, (_, _) {});
  return container;
}

@Dependencies([
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
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

  testWidgets('MAB01: active rows render with default badge', (tester) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));

    final fixed = AccountsState.data(
      active: [
        _wb(_a(id: 1, name: 'Cash')),
        _wb(_a(id: 2, name: 'Savings')),
      ],
      archived: const [],
      defaultAccountId: 1,
    );
    final data = fixed as AccountsData;

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: fixed,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, data: data));
    await tester.pumpAndSettle();

    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('MAB02: archived section renders under "Archived" header', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));

    final fixed = AccountsState.data(
      active: [_wb(_a(id: 1, name: 'Cash'))],
      archived: [_wb(_a(id: 2, name: 'OldCard', isArchived: true))],
      defaultAccountId: 1,
    );
    final data = fixed as AccountsData;

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: fixed,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, data: data));
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('OldCard'), findsOneWidget);
  });

  testWidgets(
    'MAB03: empty-state text renders when both active AND archived are empty',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final prefs = _MockUserPreferencesRepository();
      when(() => typeRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value([cashType]));

      const data = AccountsData(
        active: [],
        archived: [],
        defaultAccountId: null,
      );

      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        prefs: prefs,
        fixed: data,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container, data: data));
      await tester.pumpAndSettle();

      expect(
        find.text('No accounts yet. Create one to get started.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('MAB04: archive action via overflow menu shows undo snackbar', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));
    when(() => accountRepo.archive(2)).thenAnswer((_) async {});
    // Stub fallback used by archive() when state is not yet AsyncData.
    when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);

    final fixed = AccountsState.data(
      active: [
        _wb(
          _a(id: 1, name: 'Cash'),
          affordance: AccountRowAffordance.archiveBlocked,
        ),
        _wb(_a(id: 2, name: 'Spare'), affordance: AccountRowAffordance.archive),
      ],
      archived: const [],
      defaultAccountId: 1,
    );
    final data = fixed as AccountsData;

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: fixed,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, data: data));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accountTile:2:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();

    expect(find.text('Account archived'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    verify(() => accountRepo.archive(2)).called(1);
  });

  testWidgets('MAB05: balance renders in native currency (USD + JPY + TWD)', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));

    final fixed = AccountsState.data(
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
    );
    final data = fixed as AccountsData;

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: fixed,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, data: data));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$123.45'), findsOneWidget);
    expect(find.textContaining('¥9,999'), findsOneWidget);
    expect(find.textContaining(r'NT$50.00'), findsOneWidget);
  });

  testWidgets('MAB06: 2x text scale survives', (tester) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));

    final fixed = AccountsState.data(
      active: [
        _wb(
          _a(id: 1, name: 'An exceedingly long account name for the list row'),
          balances: {'USD': 1000},
        ),
      ],
      archived: const [],
      defaultAccountId: 1,
    );
    final data = fixed as AccountsData;

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: fixed,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(container: container, data: data, textScale: 2.0),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // Two active rows; Spare (id 2) is the bottom row and can be archived.
  AccountsData twoActive({
    AccountRowAffordance spareAffordance = AccountRowAffordance.archive,
  }) => AccountsData(
    active: [
      _wb(
        _a(id: 1, name: 'Cash'),
        affordance: AccountRowAffordance.archiveBlocked,
      ),
      _wb(_a(id: 2, name: 'Spare'), affordance: spareAffordance),
    ],
    archived: const [],
    defaultAccountId: 1,
  );

  Future<void> archiveSpareViaMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('accountTile:2:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'MAB07: Undo after the archived account was deleted saves nothing',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final prefs = _MockUserPreferencesRepository();
      when(() => typeRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value([cashType]));
      when(() => accountRepo.archive(2)).thenAnswer((_) async {});
      // The row is gone by the time Undo runs.
      when(() => accountRepo.getById(2)).thenAnswer((_) async => null);

      final data = twoActive();
      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        prefs: prefs,
        fixed: data,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container, data: data));
      await tester.pumpAndSettle();
      await archiveSpareViaMenu(tester);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      verifyNever(() => accountRepo.save(any()));
      expect(
        find.text('Something went wrong. Please try again.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'MAB08: Undo restores the bottom row of the Active card after it moved',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final prefs = _MockUserPreferencesRepository();
      when(() => typeRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value([cashType]));

      final archivedSpare = _a(id: 2, name: 'Spare', isArchived: true);
      final updates = StreamController<AccountsState>();
      addTearDown(updates.close);
      // Archiving moves Spare out of the Active card, which unmounts the
      // tile that showed the Undo snackbar.
      when(() => accountRepo.archive(2)).thenAnswer((_) async {
        updates.add(
          AccountsData(
            active: [
              _wb(
                _a(id: 1, name: 'Cash'),
                affordance: AccountRowAffordance.archiveBlocked,
              ),
            ],
            archived: [_wb(archivedSpare)],
            defaultAccountId: 1,
          ),
        );
      });
      when(() => accountRepo.getById(2)).thenAnswer((_) async => archivedSpare);
      when(() => accountRepo.save(any())).thenAnswer((_) async => 2);

      final data = twoActive();
      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        prefs: prefs,
        fixed: data,
        updates: updates.stream,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, data: data, live: true),
      );
      await tester.pumpAndSettle();
      await archiveSpareViaMenu(tester);
      expect(find.text('Archived'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final restored =
          verify(() => accountRepo.save(captureAny())).captured.single
              as Account;
      expect(restored.id, 2);
      expect(restored.isArchived, isFalse);
    },
  );

  testWidgets(
    'MAB09: archive blocked by an active recurring rule shows its message',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final prefs = _MockUserPreferencesRepository();
      when(() => typeRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value([cashType]));
      when(() => accountRepo.archive(2))
          .thenThrow(const AccountHasRecurringRuleException(2));

      final data = twoActive();
      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        prefs: prefs,
        fixed: data,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container, data: data));
      await tester.pumpAndSettle();
      await archiveSpareViaMenu(tester);

      expect(
        find.text(
          "An active recurring transaction uses this account, so it can't be "
          'archived.',
        ),
        findsOneWidget,
      );
      expect(find.text('Undo'), findsNothing);
    },
  );

  testWidgets(
    'MAB10: delete blocked because the account is in use shows its message',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final prefs = _MockUserPreferencesRepository();
      when(() => typeRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value([cashType]));
      when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
      when(() => accountRepo.delete(2))
          .thenThrow(const AccountInUseException(2));

      final data = twoActive(spareAffordance: AccountRowAffordance.delete);
      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        prefs: prefs,
        fixed: data,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container, data: data));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('accountTile:2:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      // Confirm dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text("This account is still in use, so it can't be deleted."),
        findsOneWidget,
      );
    },
  );

  testWidgets('MAB11: a failed Undo shows the generic error snackbar', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));
    when(() => accountRepo.archive(2)).thenAnswer((_) async {});
    when(() => accountRepo.getById(2))
        .thenAnswer((_) async => _a(id: 2, name: 'Spare', isArchived: true));
    when(() => accountRepo.save(any()))
        .thenThrow(const CurrencyNotFoundException('USD'));

    final data = twoActive();
    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: data,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, data: data));
    await tester.pumpAndSettle();
    await archiveSpareViaMenu(tester);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('MAB12: a later snackbar shows while an Undo snackbar is up', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final prefs = _MockUserPreferencesRepository();
    when(() => typeRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([cashType]));
    when(() => accountRepo.archive(2)).thenAnswer((_) async {});
    when(() => prefs.setDefaultAccountId(2)).thenAnswer((_) async {});

    final data = twoActive();
    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      prefs: prefs,
      fixed: data,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, data: data));
    await tester.pumpAndSettle();
    await archiveSpareViaMenu(tester);
    // A SnackBar with an action stays until dismissed.
    expect(find.text('Account archived'), findsOneWidget);

    // The fixed state still lists Spare as active, so its menu is there.
    await tester.tap(find.byKey(const ValueKey('accountTile:2:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set as default').last);
    await tester.pumpAndSettle();

    expect(find.text('Spare is now the default account.'), findsOneWidget);
  });
}
