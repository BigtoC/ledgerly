// AccountFormScreen widget tests (plan §3.3, §5).
//
// Exercises the form directly with mocked repositories. Covers:
//   - Add mode hydrates the currency default from `userPreferences`.
//   - Save is disabled until name + type + currency are present.
//   - Save on Add mode creates via `accountRepository.save(id=0)` and
//     pops with the returned id.
//   - Inline account-type creation returns the new AccountType and
//     propagates into the outer form without blowing outer state away.
//   - Edit mode hydrates from `accountRepository.getById(id)`.
//   - Missing edit-mode row renders the recoverable not-found surface
//     and either pops back to the caller or falls back to `/settings`.
//   - Opening balance respects `currency.decimals` — "100.5" into a JPY
//     field (`decimals = 0`) is rejected (Save remains disabled).

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
import 'package:ledgerly/features/accounts/account_form_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockAccountTypeRepository extends Mock
    implements AccountTypeRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _twd = Currency(code: 'TWD', decimals: 2, symbol: r'NT$');

const _cashType = AccountType(
  id: 1,
  l10nKey: 'accountType.cash',
  icon: 'wallet',
  color: 10,
  defaultCurrency: _usd,
);

GoRouter _router({
  int? accountId,
  required VoidCallback? onPopped,
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open-form'),
                onPressed: () async {
                  final path = accountId == null
                      ? '/settings/manage-accounts/new'
                      : '/settings/manage-accounts/$accountId';
                  await ctx.push<Object?>(path);
                  onPopped?.call();
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('SETTINGS_SCREEN')),
      ),
      GoRoute(
        path: '/settings/manage-accounts/new',
        builder: (_, _) => const AccountFormScreen(),
      ),
      GoRoute(
        path: '/settings/manage-accounts/:id',
        builder: (ctx, state) => AccountFormScreen(
          accountId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
}

Widget _hostApp({
  required ProviderContainer container,
  required GoRouter router,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

ProviderContainer _makeContainer({
  required AccountRepository accountRepo,
  required AccountTypeRepository typeRepo,
  required CurrencyRepository currencyRepo,
  required UserPreferencesRepository prefs,
}) {
  return ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(accountRepo),
      accountTypeRepositoryProvider.overrideWithValue(typeRepo),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Account(id: 0, name: '_', accountTypeId: 1, currency: _usd),
    );
    registerFallbackValue(const AccountType(id: 0, icon: 'wallet', color: 10));
  });

  testWidgets(
    'AF01: Add mode — Save disabled until name + type + currency are set',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final currencyRepo = _MockCurrencyRepository();
      final prefs = _MockUserPreferencesRepository();

      when(() => prefs.getDefaultCurrency()).thenAnswer((_) async => 'USD');
      when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
      when(
        () => typeRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_cashType]));
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd, _jpy, _twd]));

      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        currencyRepo: currencyRepo,
        prefs: prefs,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _hostApp(container: container, router: _router(onPopped: null)),
      );
      await tester.tap(find.byKey(const ValueKey('open-form')));
      await tester.pumpAndSettle();

      // The save button exists but is disabled — its onPressed is null.
      final save = tester.widget<FilledButton>(
        find.byKey(const ValueKey('accountForm:save')),
      );
      expect(save.onPressed, isNull);
    },
  );

  testWidgets(
    'AF02: Add mode — full happy path creates account with id=0 and pops',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final currencyRepo = _MockCurrencyRepository();
      final prefs = _MockUserPreferencesRepository();

      when(() => prefs.getDefaultCurrency()).thenAnswer((_) async => 'USD');
      when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
      when(
        () => typeRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_cashType]));
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd, _jpy, _twd]));
      when(() => accountRepo.save(any())).thenAnswer((_) async => 42);

      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        currencyRepo: currencyRepo,
        prefs: prefs,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _hostApp(container: container, router: _router(onPopped: null)),
      );
      await tester.tap(find.byKey(const ValueKey('open-form')));
      await tester.pumpAndSettle();

      // Enter a name.
      await tester.enterText(
        find.byKey(const ValueKey('accountForm:name')),
        'Wallet',
      );
      await tester.pump();

      // Pick the seeded Cash type from the picker sheet.
      await tester.tap(find.byKey(const ValueKey('accountForm:type')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('accountTypePicker:${_cashType.id}')),
      );
      await tester.pumpAndSettle();

      // Scroll the save button into view (form is long on the test
      // viewport) and submit.
      await tester.ensureVisible(
        find.byKey(const ValueKey('accountForm:save')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('accountForm:save')));
      await tester.pumpAndSettle();

      final savedArg =
          verify(() => accountRepo.save(captureAny())).captured.single
              as Account;
      expect(savedArg.id, 0);
      expect(savedArg.name, 'Wallet');
      expect(savedArg.accountTypeId, 1);
      expect(savedArg.currency.code, 'USD');
      // The form popped — list screen should now be visible.
      expect(find.byKey(const ValueKey('accountForm:save')), findsNothing);
    },
  );

  testWidgets('AF03: Edit mode — hydrates from accountRepository.getById', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final currencyRepo = _MockCurrencyRepository();
    final prefs = _MockUserPreferencesRepository();

    const stored = Account(
      id: 7,
      name: 'Checking',
      accountTypeId: 1,
      currency: _twd,
      openingBalanceMinorUnits: 10000,
      icon: 'wallet',
      color: 3,
    );
    when(() => accountRepo.getById(7)).thenAnswer((_) async => stored);
    when(() => typeRepo.getById(1)).thenAnswer((_) async => _cashType);
    when(
      () => typeRepo.watchAll(),
    ).thenAnswer((_) => Stream.value([_cashType]));
    when(
      () => currencyRepo.watchAll(),
    ).thenAnswer((_) => Stream.value([_usd, _jpy, _twd]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      currencyRepo: currencyRepo,
      prefs: prefs,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _hostApp(
        container: container,
        router: _router(accountId: 7, onPopped: null),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-form')));
    await tester.pumpAndSettle();

    // Name text field is pre-populated.
    expect(find.widgetWithText(TextField, 'Checking'), findsOneWidget);
    // Edit-mode title shown.
    expect(find.text('Edit account'), findsOneWidget);
  });

  testWidgets('AF04: Edit mode — missing row auto-pops back to caller', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final currencyRepo = _MockCurrencyRepository();
    final prefs = _MockUserPreferencesRepository();

    when(() => accountRepo.getById(999)).thenAnswer((_) async => null);
    when(
      () => typeRepo.watchAll(),
    ).thenAnswer((_) => Stream.value([_cashType]));
    when(() => currencyRepo.watchAll()).thenAnswer((_) => Stream.value([_usd]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      currencyRepo: currencyRepo,
      prefs: prefs,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _hostApp(
        container: container,
        router: _router(accountId: 999, onPopped: null),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-form')));
    await tester.pumpAndSettle();

    // The recoverable surface auto-dismisses; after the post-frame
    // pop we should be back at the root '/'.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets(
    'AF04b: Edit mode — missing row falls back to /settings when there is no stack to pop',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final currencyRepo = _MockCurrencyRepository();
      final prefs = _MockUserPreferencesRepository();

      when(() => accountRepo.getById(999)).thenAnswer((_) async => null);
      when(
        () => typeRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_cashType]));
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd]));

      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        currencyRepo: currencyRepo,
        prefs: prefs,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _hostApp(
          container: container,
          router: _router(
            onPopped: null,
            initialLocation: '/settings/manage-accounts/999',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS_SCREEN'), findsOneWidget);
    },
  );

  testWidgets(
    'AF04c: Add mode cancel falls back to /settings when there is no stack to pop',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final currencyRepo = _MockCurrencyRepository();
      final prefs = _MockUserPreferencesRepository();

      when(() => prefs.getDefaultCurrency()).thenAnswer((_) async => 'USD');
      when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
      when(
        () => typeRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_cashType]));
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd, _jpy, _twd]));

      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        currencyRepo: currencyRepo,
        prefs: prefs,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _hostApp(
          container: container,
          router: _router(
            onPopped: null,
            initialLocation: '/settings/manage-accounts/new',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS_SCREEN'), findsOneWidget);
    },
  );

  testWidgets('AF05: JPY opening-balance rejects fractional input', (
    tester,
  ) async {
    final accountRepo = _MockAccountRepository();
    final typeRepo = _MockAccountTypeRepository();
    final currencyRepo = _MockCurrencyRepository();
    final prefs = _MockUserPreferencesRepository();

    when(() => prefs.getDefaultCurrency()).thenAnswer((_) async => 'JPY');
    when(() => currencyRepo.getByCode('JPY')).thenAnswer((_) async => _jpy);
    when(
      () => typeRepo.watchAll(),
    ).thenAnswer((_) => Stream.value([_cashType]));
    when(
      () => currencyRepo.watchAll(),
    ).thenAnswer((_) => Stream.value([_usd, _jpy]));

    final container = _makeContainer(
      accountRepo: accountRepo,
      typeRepo: typeRepo,
      currencyRepo: currencyRepo,
      prefs: prefs,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _hostApp(container: container, router: _router(onPopped: null)),
    );
    await tester.tap(find.byKey(const ValueKey('open-form')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('accountForm:name')),
      'JPY Cash',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('accountForm:type')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('accountTypePicker:${_cashType.id}')));
    await tester.pumpAndSettle();

    // Enter "100.5" into JPY (decimals = 0) — this must be rejected
    // so the Save button stays disabled.
    await tester.enterText(
      find.byKey(ValueKey('accountForm:openingBalance:${_jpy.code}')),
      '100.5',
    );
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('accountForm:save')),
    );
    expect(save.onPressed, isNull);
    expect(find.text('Whole numbers only'), findsOneWidget);
  });

  testWidgets(
    'AF06: inline account-type creation returns a newly-created type',
    (tester) async {
      final accountRepo = _MockAccountRepository();
      final typeRepo = _MockAccountTypeRepository();
      final currencyRepo = _MockCurrencyRepository();
      final prefs = _MockUserPreferencesRepository();

      when(() => prefs.getDefaultCurrency()).thenAnswer((_) async => 'USD');
      when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
      when(
        () => typeRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_cashType]));
      when(
        () => currencyRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([_usd, _jpy, _twd]));

      const created = AccountType(
        id: 99,
        customName: 'Crypto',
        icon: 'wallet',
        color: 10,
      );
      when(() => typeRepo.save(any())).thenAnswer((_) async => 99);
      when(() => typeRepo.getById(99)).thenAnswer((_) async => created);

      final container = _makeContainer(
        accountRepo: accountRepo,
        typeRepo: typeRepo,
        currencyRepo: currencyRepo,
        prefs: prefs,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _hostApp(container: container, router: _router(onPopped: null)),
      );
      await tester.tap(find.byKey(const ValueKey('open-form')));
      await tester.pumpAndSettle();

      // Set a name first so outer state is non-empty; verify it survives
      // the inline create.
      await tester.enterText(
        find.byKey(const ValueKey('accountForm:name')),
        'OuterName',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('accountForm:type')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('accountTypePicker:createInline')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('accountTypeForm:name')),
        'Crypto',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('accountTypeForm:save')));
      await tester.pumpAndSettle();

      // Outer form still shows the name we typed.
      expect(find.widgetWithText(TextField, 'OuterName'), findsOneWidget);
      // The type button now shows the new type label.
      expect(find.text('Crypto'), findsWidgets);
      verify(() => typeRepo.save(any())).called(1);
    },
  );
}
