import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/account_type_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import 'app_database_provider.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
CurrencyRepository currencyRepository(Ref ref) =>
    DriftCurrencyRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    DriftCategoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
AccountTypeRepository accountTypeRepository(Ref ref) =>
    DriftAccountTypeRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(currencyRepositoryProvider),
    );

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) => DriftAccountRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(currencyRepositoryProvider),
);

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    DriftTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
UserPreferencesRepository userPreferencesRepository(Ref ref) =>
    DriftUserPreferencesRepository(ref.watch(appDatabaseProvider));
