// SettingsScreen widget tests (plan §3.3).
//
// Covers:
//   - Data state renders all sections (Appearance, General, Splash)
//     with their labels localized via AppLocalizations.
//   - Theme segmented control exercises the `setThemeMode` command.
//   - Default-account tile shows the "Not set" placeholder when no
//     default is configured.
//   - "Manage Categories" tile navigates to `/settings/categories`.
//   - Locale change via `setLocale` writes through the repo; a manual
//     MaterialApp locale swap then verifies visible strings change
//     without re-navigating.
//   - 2× text scale survives.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/settings/settings_controller.dart';
import 'package:ledgerly/features/settings/settings_screen.dart';
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

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Account _a({required int id, required String name}) =>
    Account(id: id, name: name, accountTypeId: 1, currency: _usd);

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
          path: '/settings/categories',
          builder: (_, _) => const Scaffold(body: Text('MANAGE_CATEGORIES')),
        ),
      ],
    );
  }
}

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
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
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
}) {
  return ProviderContainer(
    overrides: [
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      currencyRepositoryProvider.overrideWithValue(currencyRepo),
      settingsControllerProvider.overrideWith(
        () => _FakeSettingsController(fixed),
      ),
    ],
  );
}

SettingsData _data({
  ThemeMode themeMode = ThemeMode.light,
  Locale? locale,
  String defaultCurrency = 'USD',
  int? defaultAccountId,
  bool splashEnabled = true,
  DateTime? splashStartDate,
  String? splashDisplayText,
  String? splashButtonLabel,
}) => SettingsData(
  themeMode: themeMode,
  locale: locale,
  defaultCurrency: defaultCurrency,
  defaultAccountId: defaultAccountId,
  splashEnabled: splashEnabled,
  splashStartDate: splashStartDate,
  splashDisplayText: splashDisplayText,
  splashButtonLabel: splashButtonLabel,
);

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

  testWidgets('SS02: default-account tile shows "Not set" when id is null', (
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

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('SS03: default-account tile shows account name when set', (
    tester,
  ) async {
    final prefs = _MockUserPreferencesRepository();
    final accountRepo = _MockAccountRepository();
    final currencyRepo = _MockCurrencyRepository();
    when(
      () => accountRepo.getById(7),
    ).thenAnswer((_) async => _a(id: 7, name: 'Main Cash'));
    when(
      () => accountRepo.watchById(7),
    ).thenAnswer((_) => Stream.value(_a(id: 7, name: 'Main Cash')));

    final container = _makeContainer(
      prefs: prefs,
      accountRepo: accountRepo,
      currencyRepo: currencyRepo,
      fixed: _data(defaultAccountId: 7),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    expect(find.text('Main Cash'), findsOneWidget);
  });

  testWidgets(
    'SS03b: default-account subtitle updates when the account name changes',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final accountRepo = _MockAccountRepository();
      final currencyRepo = _MockCurrencyRepository();
      final accountCtrl = StreamController<Account?>.broadcast();
      addTearDown(accountCtrl.close);

      when(
        () => accountRepo.watchById(7),
      ).thenAnswer((_) => accountCtrl.stream);

      final container = _makeContainer(
        prefs: prefs,
        accountRepo: accountRepo,
        currencyRepo: currencyRepo,
        fixed: _data(defaultAccountId: 7),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      accountCtrl.add(_a(id: 7, name: 'Main Cash'));
      await tester.pumpAndSettle();

      expect(find.text('Main Cash'), findsOneWidget);

      accountCtrl.add(_a(id: 7, name: 'Renamed Cash'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed Cash'), findsOneWidget);
      expect(find.text('Main Cash'), findsNothing);
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
      when(
        () => prefs.setLocale(const Locale('zh', 'TW')),
      ).thenAnswer((_) async {});

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
}
