import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/account_type_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import 'app_database_provider.dart';

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
