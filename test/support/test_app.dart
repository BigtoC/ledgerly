// Shared test helpers for M4+ widget and integration tests.
//
// `buildTestApp` is the canonical starting point for every widget/integration
// test that exercises the full app shell. It uses `UncontrolledProviderScope`
// so the caller owns the `ProviderContainer` lifecycle and can dispose it via
// `addTearDown(container.dispose)`. This ensures Drift's stream-query timers
// fire inside `addTearDown` (which is flushed before `_verifyInvariants`) and
// not during the implicit widget-tree teardown, which would leave pending
// timers and fail the test assertion.
//
// Typical usage:
//
//   final db = newTestAppDatabase();
//   addTearDown(db.close);
//   final container = makeTestContainer(db: db);
//   addTearDown(container.dispose);
//   await tester.pumpWidget(buildTestApp(container: container));
//
// Do NOT add seed logic here — callers that need a seeded DB call
// `runTestSeed(db)` explicitly so the "no data" state is also testable.

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/app_database_provider.dart';
import 'package:ledgerly/app/providers/locale_service_provider.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/data/seed/first_run_seed.dart';
import 'package:ledgerly/data/services/locale_service.dart';

/// Returns a fresh in-memory `AppDatabase` with no data.
/// Caller MUST `await db.close()` in an `addTearDown` block.
AppDatabase newTestAppDatabase() => AppDatabase(NativeDatabase.memory());

/// Runs the first-run seed against [db] using a fixed `en_US` locale stub.
/// Pass [locale] to simulate a different device locale.
Future<void> runTestSeed(AppDatabase db, {String locale = 'en_US'}) {
  final currencies = DriftCurrencyRepository(db);
  final currenciesRepo = currencies;
  return runFirstRunSeed(
    db: db,
    currencies: currencies,
    categories: DriftCategoryRepository(db),
    accountTypes: DriftAccountTypeRepository(db, currenciesRepo),
    accounts: DriftAccountRepository(db, currenciesRepo),
    preferences: DriftUserPreferencesRepository(db),
    localeService: _FixedLocaleService(locale),
  );
}

/// Creates a `ProviderContainer` whose provider overrides match what the full
/// app shell needs. Caller MUST register `addTearDown(container.dispose)`.
///
/// Pass [localeService] to simulate a non-`en_US` device locale.
/// Pass [extraOverrides] to override additional providers (e.g. to inject a
/// pre-seeded `SplashGateSnapshot` without involving a live DB call).
ProviderContainer makeTestContainer({
  required AppDatabase db,
  LocaleService? localeService,
  List<Override> extraOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (localeService != null)
        localeServiceProvider.overrideWithValue(localeService),
      ...extraOverrides,
    ],
  );
}

/// Builds the full `App` widget wrapped in an `UncontrolledProviderScope`
/// backed by [container]. The caller owns [container]'s lifecycle and must
/// dispose it via `addTearDown(container.dispose)`.
Widget buildTestApp({required ProviderContainer container}) {
  return UncontrolledProviderScope(container: container, child: const App());
}

/// Launches the app through the real `bootstrapFor(...)` flow and captures the
/// widget passed to `runApp`. This exercises bootstrap ordering and Provider
/// overrides the same way production startup does, while still letting tests
/// pump the launched widget manually.
Future<Widget> buildBootstrappedTestApp({
  required AppDatabase db,
  String locale = 'en_US',
  List<Override> extraOverrides = const [],
}) async {
  Widget? launched;
  await bootstrapFor(
    openDatabase: () async => db,
    localeService: _FixedLocaleService(locale),
    runAppFn: (widget) => launched = widget,
    extraOverrides: extraOverrides,
  );

  if (launched == null) {
    throw StateError('bootstrapFor did not call runApp');
  }

  return launched!;
}

/// Deterministic [LocaleService] stub — returns a fixed locale string so
/// tests are not affected by the host machine's OS locale.
class _FixedLocaleService implements LocaleService {
  const _FixedLocaleService(this._locale);
  final String _locale;

  @override
  String get deviceLocale => _locale;
}
