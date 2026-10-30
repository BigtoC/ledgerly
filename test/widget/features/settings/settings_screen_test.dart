// SettingsScreen widget tests (plan §3.3).
//
// Covers:
//   - Data state renders all sections (Appearance, General, Splash)
//     with their labels localized via AppLocalizations.
//   - Theme segmented control exercises the `setThemeMode` command.
//   - ManageAccountsTile shows "Add an account" when there are no active accounts.
//   - ManageAccountsTile shows account name when there is 1 active account.
//   - ManageAccountsTile uses the accounts slice default for multi-account subtitles.
//   - ManageAccountsTile falls back to the first active account when the default is absent.
//   - "Manage Categories" tile navigates to `/settings/categories`.
//   - "Import from CSV" tile navigates to `/settings/import`.
//   - Locale change via `setLocale` writes through the repo; a manual
//     MaterialApp locale swap then verifies visible strings change
//     without re-navigating.
//   - 2× text scale survives.
//   - "new version" badge appears beside the app version only when an
//     update URL is available, and survives 2× text scale.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/app_update_provider.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/accounts/accounts_controller.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/settings/settings_controller.dart';
import 'package:ledgerly/features/settings/settings_screen.dart';
import 'package:ledgerly/features/settings/widgets/new_version_badge.dart';
import 'package:ledgerly/features/settings/settings_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController(this._fixed);
  final SettingsState _fixed;

  @override
  Stream<SettingsState> build() async* {
    yield _fixed;
  }
}

class _FakeAccountsController extends AccountsController {
  _FakeAccountsController(this._fixed);
  final AccountsState _fixed;

  @override
  Stream<AccountsState> build() async* {
    yield _fixed;
  }
}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Account _a({required int id, required String name}) =>
    Account(id: id, name: name, accountTypeId: 1, currency: _usd);

class _StubRouter {
  static GoRouter build(Widget home) {
    return GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/settings/manage-accounts/new',
          builder: (_, _) => const Scaffold(body: Text('ADD_ACCOUNT')),
        ),
        GoRoute(
          path: '/settings/categories',
          builder: (_, _) => const Scaffold(body: Text('MANAGE_CATEGORIES')),
        ),
        GoRoute(
          path: '/settings/import',
          builder: (_, _) => const Scaffold(body: Text('CSV_IMPORT')),
        ),
      ],
    );
  }
}

@Dependencies([
  SettingsController,
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
Widget _wrap({
  required ProviderContainer container,
  double textScale = 1.0,
  Locale? locale,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      routerConfig: _StubRouter.build(const SettingsScreen()),
    ),
  );
}

ProviderContainer _makeContainer({
  required UserPreferencesRepository prefs,
  required AccountRepository accountRepo,
  required CurrencyRepository currencyRepo,
  required SettingsState fixed,
  AccountsState? accountsFixed,
  AppUpdate? update,
}) {
  final defaultAccountsState =
      accountsFixed ??
      const AccountsState.data(
        active: [],
        archived: [],
        defaultAccountId: null,
      );
  return ProviderContainer(
    overrides: [
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      settingsControllerProvider.overrideWith(
        () => _FakeSettingsController(fixed),
      ),
      accountsControllerProvider.overrideWith(
        () => _FakeAccountsController(defaultAccountsState),
      ),
      availableAppUpdateProvider.overrideWithBuild((ref, notifier) => update),
    ],
  );
}

final _update = AppUpdate(
  version: 'v0.7.2',
  fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
  apkUrl: Uri.parse('https://example.com/ledgerly-v0.7.2-arm64-v8a.apk'),
);

const _badgeKey = ValueKey('settingsNewVersionBadge');

SettingsData _data({int? defaultAccountId}) => SettingsData(
  themeMode: ThemeMode.light,
  locale: null,
  defaultCurrency: 'USD',
  defaultAccountId: defaultAccountId,
  splashEnabled: true,
  splashStartDate: null,
  splashDisplayText: null,
  splashButtonLabel: null,
);

@Dependencies([
  SettingsController,
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
void main() {
  setUpAll(() {
    registerFallbackValue(ThemeMode.light);
  });

  testWidgets('SS01: all section headers render on data', (tester) async {
    final prefs = _MockUserPreferencesRepository();
    final accountRepo = _MockAccountRepository();
    final currencyRepo = _MockCurrencyRepository();
    final container = _makeContainer(
      prefs: prefs,
      accountRepo: accountRepo,
      currencyRepo: currencyRepo,
      fixed: _data(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    // Section headers may be offscreen on the default test viewport;
    // `find.text` matches the element even if it has not laid out yet,
    // which is what we want here — the widget tree exists regardless of
    // scroll position.
    expect(find.text('Appearance', skipOffstage: false), findsOneWidget);
    expect(find.text('General', skipOffstage: false), findsOneWidget);
    expect(find.text('Splash screen', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'SS02: ManageAccountsTile shows "Add an account" when there are no active accounts',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(defaultAccountId: null),
        accountsFixed: const AccountsState.data(
          active: [],
          archived: [],
          defaultAccountId: null,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      // Scroll the ManageAccountsTile into view before asserting.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settingsManageAccountsTile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Add an account', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets(
    'SS03: ManageAccountsTile shows account name when there is 1 active account',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(defaultAccountId: 7),
        accountsFixed: AccountsState.data(
          active: [
            AccountWithBalance(
              account: _a(id: 7, name: 'Main Cash'),
              balancesByCurrency: const {},
              affordance: AccountRowAffordance.archive,
            ),
          ],
          archived: const [],
          defaultAccountId: 7,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      // Scroll the ManageAccountsTile into view before asserting.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settingsManageAccountsTile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // The tile subtitle shows the account name.
      expect(find.text('Main Cash', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets(
    'SS03b: ManageAccountsTile uses AccountsData.defaultAccountId for multi-account subtitle',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(defaultAccountId: 1),
        accountsFixed: AccountsState.data(
          active: [
            AccountWithBalance(
              account: _a(id: 1, name: 'Cash'),
              balancesByCurrency: const {},
              affordance: AccountRowAffordance.archive,
            ),
            AccountWithBalance(
              account: _a(id: 2, name: 'Savings'),
              balancesByCurrency: const {},
              affordance: AccountRowAffordance.archive,
            ),
          ],
          archived: const [],
          defaultAccountId: 2,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settingsManageAccountsTile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Savings +1 more', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets(
    'SS03c: ManageAccountsTile falls back to the first active account when default is missing',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(defaultAccountId: 99),
        accountsFixed: AccountsState.data(
          active: [
            AccountWithBalance(
              account: _a(id: 1, name: 'Cash'),
              balancesByCurrency: const {},
              affordance: AccountRowAffordance.archive,
            ),
            AccountWithBalance(
              account: _a(id: 2, name: 'Savings'),
              balancesByCurrency: const {},
              affordance: AccountRowAffordance.archive,
            ),
          ],
          archived: const [],
          defaultAccountId: 99,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settingsManageAccountsTile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cash +1 more', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets('SS04: theme segmented control writes via setThemeMode', (
    tester,
  ) async {
    final prefs = _MockUserPreferencesRepository();
    final accountRepo = _MockAccountRepository();
    final currencyRepo = _MockCurrencyRepository();
    when(() => prefs.setThemeMode(ThemeMode.dark)).thenAnswer((_) async {});

    final container = _makeContainer(
      prefs: prefs,
      accountRepo: accountRepo,
      currencyRepo: currencyRepo,
      fixed: _data(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    verify(() => prefs.setThemeMode(ThemeMode.dark)).called(1);
  });

  testWidgets(
    'SS05: Manage Categories tile navigates to /settings/categories',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      // Scroll the CustomScrollView until the tile is visible, then tap.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settingsManageCategoriesTile')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey('settingsManageCategoriesTile')),
      );
      await tester.pumpAndSettle();

      expect(find.text('MANAGE_CATEGORIES'), findsOneWidget);
    },
  );

  testWidgets('SS05b: Import from CSV tile navigates to /settings/import', (
    tester,
  ) async {
    final container = _makeContainer(
      prefs: _MockUserPreferencesRepository(),
      accountRepo: _MockAccountRepository(),
      currencyRepo: _MockCurrencyRepository(),
      fixed: _data(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    const tile = ValueKey('settingsImportCsvTile');
    await tester.scrollUntilVisible(
      find.byKey(tile),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(tile));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(tile),
        matching: find.text('Import from CSV'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(tile));
    await tester.pumpAndSettle();

    expect(find.text('CSV_IMPORT'), findsOneWidget);
  });

  testWidgets(
    'SS06: locale change propagates visible strings without manual nav',
    (tester) async {
      // Renders at en first, then swaps to zh_TW via MaterialApp.locale
      // — the same effect the M4 localePreferenceProvider drives in prod
      // when SettingsController.setLocale writes to prefs. We verify that
      // section headers update live without touching the router.
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(container: container, locale: const Locale('zh', 'TW')),
      );
      await tester.pumpAndSettle();
      expect(find.text('外觀'), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
    },
  );

  testWidgets(
    'SS06b: language selector writes via setLocale before the app repumps',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();
      when(() => prefs.setLocale(const Locale('zh', 'TW')))
          .thenAnswer((_) async {});

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('languageOption:zh_TW')));
      await tester.pumpAndSettle();

      verify(() => prefs.setLocale(const Locale('zh', 'TW'))).called(1);
    },
  );

  testWidgets('SS07: 2x text scale survives without layout overflow', (
    tester,
  ) async {
    final prefs = _MockUserPreferencesRepository();
    final accountRepo = _MockAccountRepository();
    final currencyRepo = _MockCurrencyRepository();

    final container = _makeContainer(
      prefs: prefs,
      accountRepo: accountRepo,
      currencyRepo: currencyRepo,
      fixed: _data(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, textScale: 2.0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('SS08: no new-version badge without an available update', (
    tester,
  ) async {
    final container = _makeContainer(
      prefs: _MockUserPreferencesRepository(),
      accountRepo: _MockAccountRepository(),
      currencyRepo: _MockCurrencyRepository(),
      fixed: _data(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.byKey(_badgeKey, skipOffstage: false), findsNothing);
  });

  testWidgets('SS09: new-version badge shows when an update is available', (
    tester,
  ) async {
    final container = _makeContainer(
      prefs: _MockUserPreferencesRepository(),
      accountRepo: _MockAccountRepository(),
      currencyRepo: _MockCurrencyRepository(),
      fixed: _data(),
      update: _update,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(_badgeKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.descendant(
        of: find.byKey(_badgeKey),
        matching: find.text('new version'),
      ),
      findsOneWidget,
    );
    // The badge opens the provider's ABI-specific APK URL.
    expect(
      tester
          .widget<NewVersionBadge>(find.byType(NewVersionBadge))
          .update
          .apkUrl,
      _update.apkUrl,
    );
  });

  testWidgets('SS10: new-version badge survives 2x text scale', (tester) async {
    final container = _makeContainer(
      prefs: _MockUserPreferencesRepository(),
      accountRepo: _MockAccountRepository(),
      currencyRepo: _MockCurrencyRepository(),
      fixed: _data(),
      update: _update,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, textScale: 2.0));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(_badgeKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(_badgeKey), findsOneWidget);
  });
}
