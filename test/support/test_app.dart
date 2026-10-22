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
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/app_database_provider.dart';
import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/data/seed/first_run_seed.dart';
import 'package:ledgerly/data/services/locale_service.dart';

/// Returns a fresh in-memory `AppDatabase` with no data.
/// Caller MUST `await db.close()` in an `addTearDown` block.
AppDatabase newTestAppDatabase() => AppDatabase(NativeDatabase.memory());

/// Runs the first-run seed against [db] using a fixed `en_US` locale stub.
Future<void> runTestSeed(AppDatabase db) {
  final currencies = DriftCurrencyRepository(db);
  final currenciesRepo = currencies;
  return runFirstRunSeed(
    db: db,
    currencies: currencies,
    categories: DriftCategoryRepository(db),
    accountTypes: DriftAccountTypeRepository(db, currenciesRepo),
    accounts: DriftAccountRepository(db, currenciesRepo),
    preferences: DriftUserPreferencesRepository(db),
    localeService: const _FixedLocaleService('en_US'),
  );
}

/// Creates a `ProviderContainer` whose provider overrides match what the full
/// app shell needs, with the same no-retry policy as production
/// (`noProviderRetry`). Caller MUST register `addTearDown(container.dispose)`.
///
/// Pass [extraOverrides] to override additional providers (e.g. to inject a
/// pre-seeded `SplashGateSnapshot` without involving a live DB call).
ProviderContainer makeTestContainer({
  required AppDatabase db,
  List<Override> extraOverrides = const [],
}) {
  return ProviderContainer(
    retry: noProviderRetry,
    overrides: [appDatabaseProvider.overrideWithValue(db), ...extraOverrides],
  );
}

/// Builds the full `App` widget wrapped in an `UncontrolledProviderScope`
/// backed by [container]. The caller owns [container]'s lifecycle and must
/// dispose it via `addTearDown(container.dispose)`.
@Dependencies([router, themeMode, userLocalePreference, exchangeRateRepository])
Widget buildTestApp({required ProviderContainer container}) {
  return UncontrolledProviderScope(container: container, child: const App());
}

/// Launches the app through the real `bootstrapFor(...)` flow and captures the
/// widget passed to `runApp`. This exercises bootstrap ordering and Provider
/// overrides the same way production startup does, while still letting tests
/// pump the launched widget manually.
///
/// If the captured widget is a `ProviderScope`, this returns an
/// `UncontrolledProviderScope` backed by the same overrides and retry policy
/// so tests can own container disposal via `addTearDown`. That mirrors
/// [buildTestApp] and avoids Drift cleanup timers being scheduled during
/// implicit widget-tree teardown.
@Dependencies([router, exchangeRateRepository])
Future<Widget> buildBootstrappedTestApp({required AppDatabase db}) async {
  Widget? launched;
  ProviderContainer? container;
  final overrides = <Override>[];
  await bootstrapFor(
    openDatabase: () async => db,
    localeService: const _FixedLocaleService('en_US'),
    runAppFn: (widget) {
      launched = widget;
      if (widget is ProviderScope) {
        overrides.addAll(widget.overrides);
        container = ProviderContainer(
          overrides: overrides,
          retry: widget.retry,
        );
        launched = UncontrolledProviderScope(
          container: container!,
          child: widget.child,
        );
      }
    },
  );

  if (launched == null) {
    throw StateError('bootstrapFor did not call runApp');
  }

  if (container != null) addTearDown(container!.dispose);
  return launched!;
}

// ---------------------------------------------------------------------------
// Integration test helpers (Unit 1 — M6 plan)
// ---------------------------------------------------------------------------

/// Inserts a transaction directly into [db] via [DriftTransactionRepository].
///
/// Caller MUST wrap in `tester.runAsync` because Drift uses real timers.
/// [currencyCode] must already be seeded (e.g. `'USD'`, `'JPY'`).
/// [createdAt] / [updatedAt] are repository-populated on save; the values
/// passed here are placeholder stubs overwritten by the repository.
Future<Transaction> insertTestTransaction(
  AppDatabase db, {
  required int accountId,
  required int categoryId,
  required String currencyCode,
  required int amountMinorUnits,
  DateTime? date,
  String? memo,
}) async {
  final currencies = DriftCurrencyRepository(db);
  final currency = await currencies.getByCode(currencyCode);
  if (currency == null) throw StateError('Currency $currencyCode not seeded');
  final now = DateTime.now();
  return DriftTransactionRepository(db).save(
    Transaction(
      id: 0,
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      categoryId: categoryId,
      accountId: accountId,
      date: date ?? now,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

/// Creates an account directly in [db] via [DriftAccountRepository].
///
/// Caller MUST wrap in `tester.runAsync`.
Future<Account> createTestAccount(
  AppDatabase db, {
  required String name,
  required String currencyCode,
  required int accountTypeId,
}) async {
  final currencies = DriftCurrencyRepository(db);
  final currency = await currencies.getByCode(currencyCode);
  if (currency == null) throw StateError('Currency $currencyCode not seeded');
  final repo = DriftAccountRepository(db, currencies);
  final id = await repo.save(
    Account(
      id: 0,
      name: name,
      accountTypeId: accountTypeId,
      currency: currency,
    ),
  );
  final saved = await repo.getById(id);
  if (saved == null) throw StateError('Account $id vanished after insert');
  return saved;
}

/// Returns the id of the seeded account type whose [l10nKey] matches.
/// Throws [StateError] when not found. Caller MUST wrap in `tester.runAsync`.
///
/// Seeded keys: `'accountType.cash'`, `'accountType.investment'`.
Future<int> getAccountTypeId(AppDatabase db, String l10nKey) async {
  final currencies = DriftCurrencyRepository(db);
  final types = DriftAccountTypeRepository(db, currencies);
  final type = await types.getByL10nKey(l10nKey);
  if (type == null) throw StateError('AccountType $l10nKey not seeded');
  return type.id;
}

/// Returns the id of the seeded category whose [l10nKey] matches.
/// Throws [StateError] when not found. Caller MUST wrap in `tester.runAsync`.
///
/// Example seeded keys: `'category.food'`, `'category.income.salary'`.
Future<int> getSeededCategoryId(AppDatabase db, String l10nKey) async {
  final cat = await DriftCategoryRepository(db).getByL10nKey(l10nKey);
  if (cat == null) throw StateError('Category $l10nKey not seeded');
  return cat.id;
}

/// Returns the account currently pointed to by
/// `user_preferences.default_account_id`. This avoids the
/// stream-subscription cleanup timer that `watchAll().first` would schedule
/// under FakeAsync. Caller MUST wrap in `tester.runAsync`.
Future<Account> getDefaultAccount(AppDatabase db) async {
  final currencies = DriftCurrencyRepository(db);
  final defaultId = await DriftUserPreferencesRepository(db)
      .getDefaultAccountId();
  if (defaultId == null) {
    throw StateError('default_account_id not set; seed did not run');
  }
  final account = await DriftAccountRepository(
    db,
    currencies,
  ).getById(defaultId);
  if (account == null) {
    throw StateError('Default account $defaultId vanished after seed');
  }
  return account;
}

/// Deterministic [LocaleService] stub — returns a fixed locale string so
/// tests are not affected by the host machine's OS locale.
class _FixedLocaleService implements LocaleService {
  const _FixedLocaleService(this._locale);
  final String _locale;

  @override
  String get deviceLocale => _locale;
}
