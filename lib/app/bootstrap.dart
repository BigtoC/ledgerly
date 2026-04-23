import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../data/database/app_database.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/account_type_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/currency_repository.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../data/seed/first_run_seed.dart';
import '../data/services/locale_service.dart';
import 'app.dart';
import 'providers/app_database_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/splash_redirect_provider.dart';
import 'providers/theme_provider.dart';

typedef InitializeDateFormattingFn = Future<void> Function(String locale);
typedef ReadThemeModeFn =
    Future<ThemeMode> Function(UserPreferencesRepository preferences);
typedef ReadLocaleFn =
    Future<Locale?> Function(UserPreferencesRepository preferences);
typedef ReadSplashEnabledFn =
    Future<bool> Function(UserPreferencesRepository preferences);
typedef ReadSplashStartDateFn =
    Future<DateTime?> Function(UserPreferencesRepository preferences);
typedef RunFirstRunSeedFn =
    Future<void> Function({
      required AppDatabase db,
      required CurrencyRepository currencies,
      required CategoryRepository categories,
      required AccountTypeRepository accountTypes,
      required AccountRepository accounts,
      required UserPreferencesRepository preferences,
      required LocaleService localeService,
    });

Future<void> _initializeDateFormattingForLocale(String locale) =>
    initializeDateFormatting(locale);

Future<ThemeMode> _readThemeMode(UserPreferencesRepository preferences) =>
    preferences.getThemeMode();

Future<Locale?> _readLocale(UserPreferencesRepository preferences) =>
    preferences.getLocale();

Future<bool> _readSplashEnabled(UserPreferencesRepository preferences) =>
    preferences.getSplashEnabled();

Future<DateTime?> _readSplashStartDate(UserPreferencesRepository preferences) =>
    preferences.getSplashStartDate();

Future<void> _runSeed({
  required AppDatabase db,
  required CurrencyRepository currencies,
  required CategoryRepository categories,
  required AccountTypeRepository accountTypes,
  required AccountRepository accounts,
  required UserPreferencesRepository preferences,
  required LocaleService localeService,
}) => runFirstRunSeed(
  db: db,
  currencies: currencies,
  categories: categories,
  accountTypes: accountTypes,
  accounts: accounts,
  preferences: preferences,
  localeService: localeService,
);

Future<void> bootstrap() => bootstrapFor(
  openDatabase: () async => AppDatabase(driftDatabase(name: 'ledgerly')),
  localeService: const LocaleService(),
);

@visibleForTesting
Future<void> bootstrapFor({
  required Future<AppDatabase> Function() openDatabase,
  required LocaleService localeService,
  void Function(Widget)? runAppFn,
  InitializeDateFormattingFn initializeDateFormattingFn =
      _initializeDateFormattingForLocale,
  ReadThemeModeFn getThemeModeFn = _readThemeMode,
  ReadLocaleFn getLocaleFn = _readLocale,
  ReadSplashEnabledFn getSplashEnabledFn = _readSplashEnabled,
  ReadSplashStartDateFn getSplashStartDateFn = _readSplashStartDate,
  RunFirstRunSeedFn runFirstRunSeedFn = _runSeed,
  List<Override> extraOverrides = const [],
}) async {
  // Step 1 — Framework binding.
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2 — Open AppDatabase (runs migrations).
  final db = await openDatabase();

  // Step 3 — LocaleService (synchronous; dedicated step for PRD ordering).

  // Step 4 — intl locale data (must precede first DateFormat call).
  await initializeDateFormattingFn('en_US');
  await initializeDateFormattingFn('zh_TW');
  await initializeDateFormattingFn('zh_CN');

  // Step 5 — Eager preference read. Pre-seeds the first frame so the router,
  // splash UI, theme, and locale all see persisted values immediately.
  final preferencesRepo = DriftUserPreferencesRepository(db);
  final initialThemeMode = await getThemeModeFn(preferencesRepo);
  final initialLocale = await getLocaleFn(preferencesRepo);
  final splashEnabled = await getSplashEnabledFn(preferencesRepo);
  final splashStartDate = await getSplashStartDateFn(preferencesRepo);

  // Step 6 — First-run seed (idempotent; short-circuits if already run).
  final currenciesRepo = DriftCurrencyRepository(db);
  await runFirstRunSeedFn(
    db: db,
    currencies: currenciesRepo,
    categories: DriftCategoryRepository(db),
    accountTypes: DriftAccountTypeRepository(db, currenciesRepo),
    accounts: DriftAccountRepository(db, currenciesRepo),
    preferences: preferencesRepo,
    localeService: localeService,
  );

  // Step 7 — ProviderScope with DB override + pre-seeded splash gate.
  (runAppFn ?? runApp)(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialPreferredLocaleProvider.overrideWithValue(initialLocale),
        splashGateSnapshotProvider.overrideWith((ref) {
          final notifier = SplashGateSnapshot.withInitial(
            enabled: splashEnabled,
            startDate: splashStartDate,
          );
          final sub1 = preferencesRepo.watchSplashEnabled().listen(
            notifier.updateEnabled,
          );
          final sub2 = preferencesRepo.watchSplashStartDate().listen(
            notifier.updateStartDate,
          );
          ref.onDispose(() {
            sub1.cancel();
            sub2.cancel();
            notifier.dispose();
          });
          return notifier;
        }),
        ...extraOverrides,
      ],
      child: const App(),
    ),
  );
}
