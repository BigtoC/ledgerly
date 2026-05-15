import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/account_type_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/repositories/exchange_rate_repository.dart';
import '../../data/repositories/pending_transaction_repository.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../data/use_cases/recurring_generation_use_case.dart';
import 'app_database_provider.dart';
import 'default_currency_provider.dart';

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

/// Exchange-rate HTTP service. Constructs its own `Dio` with conservative
/// timeouts — there is no standalone `dioProvider`, since the rate service
/// is the only consumer of Dio in the codebase. If a second HTTP consumer
/// appears later, extract `dioProvider` at that point.
@Riverpod(keepAlive: true, dependencies: [])
ExchangeRateService exchangeRateService(Ref ref) {
  return ExchangeRateService(
    Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    ),
  );
}

/// Exchange-rate repository. The constructor subscribes to DAO changes
/// and default-currency changes immediately — so simply reading this
/// provider is enough to start the cache pipeline.
@Riverpod(
  keepAlive: true,
  dependencies: [appDatabase, exchangeRateService, defaultCurrency],
)
ExchangeRateRepository exchangeRateRepository(Ref ref) {
  final repo = ExchangeRateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exchangeRateServiceProvider),
    // Riverpod 2.x still exposes `.stream`; the repository's constructor
    // takes a real Stream for subscription. `.future` is wrong here
    // (single-shot) and AsyncValue listening doesn't fit the API.
    // ignore: deprecated_member_use
    ref.watch(defaultCurrencyProvider.stream),
  );
  ref.onDispose(repo.dispose);
  return repo;
}

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
@Riverpod(keepAlive: true, dependencies: [exchangeRateRepository])
Stream<Map<String, int>> exchangeRates(Ref ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
}
