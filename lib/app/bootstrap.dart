import 'dart:async';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../data/database/app_database.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/account_type_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/currency_repository.dart';
import '../data/repositories/pending_transaction_repository.dart';
import '../data/repositories/recurring_rules_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../data/seed/first_run_seed.dart';
import '../data/services/locale_service.dart';
import '../data/use_cases/recurring_generation_use_case.dart';
import 'app.dart';
import 'providers/app_database_provider.dart';
import 'providers/default_currency_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/splash_redirect_provider.dart';
import 'providers/theme_provider.dart';

typedef InitializeDateFormattingFn = Future<void> Function(String locale);
typedef ReadSplashEnabledFn = Future<bool> Function(
  UserPreferencesRepository preferences,
);
typedef ReadSplashStartDateFn = Future<DateTime?> Function(
  UserPreferencesRepository preferences,
);
typedef RunFirstRunSeedFn = Future<void> Function({
  required AppDatabase db,
  required CurrencyRepository currencies,
  required CategoryRepository categories,
  required AccountTypeRepository accountTypes,
  required AccountRepository accounts,
  required UserPreferencesRepository preferences,
  required LocaleService localeService,
});
typedef RunRecurringGenerationFn = Future<RecurringGenerationResult> Function(
  AppDatabase db,
);

/// Retry policy for every provider in the app: never retry.
///
/// Riverpod 3 retries failing providers by default (exponential backoff,
/// up to 10 attempts) and reports them as loading while it does. Ledgerly
/// relies on errors surfacing immediately, as they did on Riverpod 2: the
/// screens render their error states, and callers awaiting `.future` fail
/// fast instead of waiting through the backoff. The root `ProviderScope`
/// in [bootstrap] and the shared test harness (`test/support/test_app.dart`)
/// pass this as `retry:`; containers built directly in tests keep
/// Riverpod's default retry.
Duration? noProviderRetry(int retryCount, Object error) => null;

Future<bool> _readSplashEnabled(UserPreferencesRepository preferences) =>
    preferences.getSplashEnabled();

Future<DateTime?> _readSplashStartDate(UserPreferencesRepository preferences) =>
    preferences.getSplashStartDate();

Future<RecurringGenerationResult> _runRecurringGeneration(AppDatabase db) {
  final useCase = RecurringGenerationUseCase(
    recurringRepo: DriftRecurringRulesRepository(db),
    pendingRepo: DriftPendingTransactionRepository(
      db,
      txRepo: DriftTransactionRepository(db),
    ),
    db: db,
  );
  return useCase.execute();
}

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
      initializeDateFormatting,
  ReadSplashEnabledFn getSplashEnabledFn = _readSplashEnabled,
  ReadSplashStartDateFn getSplashStartDateFn = _readSplashStartDate,
  RunFirstRunSeedFn runFirstRunSeedFn = runFirstRunSeed,
  RunRecurringGenerationFn runRecurringGenerationFn = _runRecurringGeneration,
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
  final initialThemeMode = await preferencesRepo.getThemeMode();
  final initialLocale = await preferencesRepo.getLocale();
  final splashEnabled = await getSplashEnabledFn(preferencesRepo);
  final splashStartDate = await getSplashStartDateFn(preferencesRepo);
  var initialDefaultCurrency = await preferencesRepo.getDefaultCurrency();

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
  initialDefaultCurrency = await preferencesRepo.getDefaultCurrency();

  // Step 7 — ProviderScope with DB override + pre-seeded splash gate.
  // Recurring generation is scheduled from the App's first-frame callback
  // so startup is not blocked by due-rule processing.
  (runAppFn ?? runApp)(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialPreferredLocaleProvider.overrideWithValue(initialLocale),
        initialDefaultCurrencyProvider.overrideWithValue(
          initialDefaultCurrency,
        ),
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
      ],
      child: App(
        onFirstFrame: () {
          unawaited(() async {
            try {
              await runRecurringGenerationFn(db);
            } on Object {
              // Generation failures must not crash or block startup.
            }
          }());
        },
      ),
    ),
  );
}
