import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/account_type_repository.dart';
import '../../data/repositories/app_update_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/repositories/exchange_rate_repository.dart';
import '../../data/repositories/pending_transaction_repository.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../data/services/apk_installer_service.dart';
import '../../data/services/app_release_service.dart';
import '../../data/use_cases/csv_export_use_case.dart';
import '../../data/use_cases/csv_import_use_case.dart';
import '../../data/use_cases/recurring_generation_use_case.dart';
import 'app_database_provider.dart';
import 'default_currency_provider.dart';
import 'service_providers.dart';

part 'repository_providers.g.dart';

// Repositories transitively depend on `appDatabaseProvider`, which is
// scope-overridable by `bootstrap()` and by every test harness. Each one
// also gets overridden directly in widget tests with mock implementations,
// so they must declare `dependencies` to satisfy
// `scoped_providers_should_specify_dependencies` at every override site.
@Riverpod(keepAlive: true, dependencies: [appDatabase])
CurrencyRepository currencyRepository(Ref ref) =>
    DriftCurrencyRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true, dependencies: [appDatabase])
CategoryRepository categoryRepository(Ref ref) =>
    DriftCategoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true, dependencies: [appDatabase, currencyRepository])
AccountTypeRepository accountTypeRepository(Ref ref) =>
    DriftAccountTypeRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(currencyRepositoryProvider),
    );

@Riverpod(keepAlive: true, dependencies: [appDatabase, currencyRepository])
AccountRepository accountRepository(Ref ref) => DriftAccountRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(currencyRepositoryProvider),
);

@Riverpod(keepAlive: true, dependencies: [appDatabase])
TransactionRepository transactionRepository(Ref ref) =>
    DriftTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true, dependencies: [appDatabase])
UserPreferencesRepository userPreferencesRepository(Ref ref) =>
    DriftUserPreferencesRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true, dependencies: [appDatabase, transactionRepository])
ShoppingListRepository shoppingListRepository(Ref ref) =>
    DriftShoppingListRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(transactionRepositoryProvider),
    );

@Riverpod(keepAlive: true, dependencies: [appDatabase, transactionRepository])
PendingTransactionRepository pendingTransactionRepository(Ref ref) =>
    DriftPendingTransactionRepository(
      ref.watch(appDatabaseProvider),
      txRepo: ref.watch(transactionRepositoryProvider),
    );

@Riverpod(keepAlive: true, dependencies: [appDatabase])
RecurringRulesRepository recurringRulesRepository(Ref ref) =>
    DriftRecurringRulesRepository(ref.watch(appDatabaseProvider));

/// Use-case provider. Lives here so that controllers in
/// `lib/features/.../*_controller.dart` can `ref.read` the use case
/// without importing `data/database/...` (forbidden by
/// `controllers_forbid_db_and_services` in import_analysis_options.yaml).
@Riverpod(
  keepAlive: true,
  dependencies: [
    appDatabase,
    recurringRulesRepository,
    pendingTransactionRepository,
  ],
)
RecurringGenerationUseCase recurringGenerationUseCase(Ref ref) {
  return RecurringGenerationUseCase(
    recurringRepo: ref.watch(recurringRulesRepositoryProvider),
    pendingRepo: ref.watch(pendingTransactionRepositoryProvider),
    db: ref.watch(appDatabaseProvider),
  );
}

/// CSV import use case. Lives here for the same reason as
/// [recurringGenerationUseCase]: the controller reads it without importing
/// `data/services/` or `data/database/`.
@Riverpod(
  keepAlive: true,
  dependencies: [
    appDatabase,
    csvFileService,
    transactionRepository,
    categoryRepository,
    accountRepository,
    accountTypeRepository,
    currencyRepository,
  ],
)
CsvImportUseCase csvImportUseCase(Ref ref) => CsvImportUseCase(
  fileService: ref.watch(csvFileServiceProvider),
  transactionRepo: ref.watch(transactionRepositoryProvider),
  categoryRepo: ref.watch(categoryRepositoryProvider),
  accountRepo: ref.watch(accountRepositoryProvider),
  accountTypeRepo: ref.watch(accountTypeRepositoryProvider),
  currencyRepo: ref.watch(currencyRepositoryProvider),
  db: ref.watch(appDatabaseProvider),
);

/// CSV export use case. Lives here for the same reason as
/// [csvImportUseCase].
@Riverpod(
  keepAlive: true,
  dependencies: [
    csvFileService,
    transactionRepository,
    categoryRepository,
    accountRepository,
  ],
)
CsvExportUseCase csvExportUseCase(Ref ref) => CsvExportUseCase(
  fileService: ref.watch(csvFileServiceProvider),
  transactionRepo: ref.watch(transactionRepositoryProvider),
  categoryRepo: ref.watch(categoryRepositoryProvider),
  accountRepo: ref.watch(accountRepositoryProvider),
);

/// Exchange-rate repository. The constructor subscribes to DAO changes
/// and default-currency changes immediately — so simply reading this
/// provider is enough to start the cache pipeline.
@Riverpod(
  keepAlive: true,
  dependencies: [appDatabase, exchangeRateService, defaultCurrency],
)
ExchangeRateRepository exchangeRateRepository(Ref ref) {
  // The repository's constructor takes a real Stream for subscription.
  // Riverpod 3 removed `defaultCurrencyProvider.stream`, so bridge it the
  // way `.stream` behaved: forward later values without replaying the one
  // the provider already holds. Errors stay on `defaultCurrencyProvider`.
  final defaultCurrencies = StreamController<String>();
  ref.listen(defaultCurrencyProvider, (_, next) {
    if (next case AsyncData(:final value)) defaultCurrencies.add(value);
  });
  final repo = ExchangeRateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exchangeRateServiceProvider),
    defaultCurrencies.stream,
  );
  ref.onDispose(repo.dispose);
  ref.onDispose(defaultCurrencies.close);
  return repo;
}

/// GitHub release lookup, download and install for the app-update check.
/// Unscoped: it shares the app-wide [dioProvider] client and reads nothing
/// from the database. Lives here, not in `app_update_provider.dart`, so
/// that widgets importing that file for `availableAppUpdateProvider` cannot
/// reach the repository.
@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) {
  final packageInfo = ref.watch(packageInfoServiceProvider);
  return AppUpdateRepository(
    AppReleaseService(ref.watch(dioProvider)),
    installer: const ApkInstallerService(),
    updatesDir: () async =>
        Directory('${(await getTemporaryDirectory()).path}/updates')
            .create(recursive: true),
    installedVersion: () async => (await packageInfo.read()).version,
    abi: Abi.current(),
  );
}
