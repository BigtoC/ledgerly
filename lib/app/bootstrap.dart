import 'package:drift_flutter/drift_flutter.dart';
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
import 'providers/splash_redirect_provider.dart';

Future<void> bootstrap() => bootstrapFor(
  openDatabase: () async => AppDatabase(driftDatabase(name: 'ledgerly')),
  localeService: const LocaleService(),
);

@visibleForTesting
Future<void> bootstrapFor({
  required Future<AppDatabase> Function() openDatabase,
  required LocaleService localeService,
  void Function(Widget)? runAppFn,
  List<Override> extraOverrides = const [],
}) async {
  // Step 1 — Framework binding.
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2 — Open AppDatabase (runs migrations).
  final db = await openDatabase();

  // Step 3 — LocaleService (synchronous; dedicated step for PRD ordering).

  // Step 4 — intl locale data (must precede first DateFormat call).
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('zh_TW');
  await initializeDateFormatting('zh_CN');

  // Step 5 — Eager preference read. Pre-seeds SplashGateSnapshot so the
  // router's first redirect sees real values on the first frame, not defaults.
  final preferencesRepo = DriftUserPreferencesRepository(db);
  final splashEnabled = await preferencesRepo.getSplashEnabled();
  final splashStartDate = await preferencesRepo.getSplashStartDate();

  // Step 6 — First-run seed (idempotent; short-circuits if already run).
  final currenciesRepo = DriftCurrencyRepository(db);
  await runFirstRunSeed(
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
