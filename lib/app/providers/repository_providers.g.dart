// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currencyRepositoryHash() =>
    r'bf8c858bb3918d954d76ab2669ec63d33a17836b';

/// See also [currencyRepository].
@ProviderFor(currencyRepository)
final currencyRepositoryProvider = Provider<CurrencyRepository>.internal(
  currencyRepository,
  name: r'currencyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currencyRepositoryHash,
  dependencies: <ProviderOrFamily>[appDatabaseProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    appDatabaseProvider,
    ...?appDatabaseProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrencyRepositoryRef = ProviderRef<CurrencyRepository>;
String _$categoryRepositoryHash() =>
    r'1e4610381fc04292a17b40245adf139c4e16875e';

/// See also [categoryRepository].
@ProviderFor(categoryRepository)
final categoryRepositoryProvider = Provider<CategoryRepository>.internal(
  categoryRepository,
  name: r'categoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryRepositoryHash,
  dependencies: <ProviderOrFamily>[appDatabaseProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    appDatabaseProvider,
    ...?appDatabaseProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryRepositoryRef = ProviderRef<CategoryRepository>;
String _$accountTypeRepositoryHash() =>
    r'1ca0b598d36c528f555f227489fa67ddf028893f';

/// See also [accountTypeRepository].
@ProviderFor(accountTypeRepository)
final accountTypeRepositoryProvider = Provider<AccountTypeRepository>.internal(
  accountTypeRepository,
  name: r'accountTypeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountTypeRepositoryHash,
  dependencies: <ProviderOrFamily>[
    appDatabaseProvider,
    currencyRepositoryProvider,
  ],
  allTransitiveDependencies: <ProviderOrFamily>{
    appDatabaseProvider,
    ...?appDatabaseProvider.allTransitiveDependencies,
    currencyRepositoryProvider,
    ...?currencyRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AccountTypeRepositoryRef = ProviderRef<AccountTypeRepository>;
String _$accountRepositoryHash() => r'ac65599370448fd726a90beac26dadfa8c9cdc0e';

/// See also [accountRepository].
@ProviderFor(accountRepository)
final accountRepositoryProvider = Provider<AccountRepository>.internal(
  accountRepository,
  name: r'accountRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountRepositoryHash,
  dependencies: <ProviderOrFamily>[
    appDatabaseProvider,
    currencyRepositoryProvider,
  ],
  allTransitiveDependencies: <ProviderOrFamily>{
    appDatabaseProvider,
    ...?appDatabaseProvider.allTransitiveDependencies,
    currencyRepositoryProvider,
    ...?currencyRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AccountRepositoryRef = ProviderRef<AccountRepository>;
String _$transactionRepositoryHash() =>
    r'a0ac84b0ff8a6e5a134d1d1aa8b85236160c19b9';

/// See also [transactionRepository].
@ProviderFor(transactionRepository)
final transactionRepositoryProvider = Provider<TransactionRepository>.internal(
  transactionRepository,
  name: r'transactionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionRepositoryHash,
  dependencies: <ProviderOrFamily>[appDatabaseProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    appDatabaseProvider,
    ...?appDatabaseProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionRepositoryRef = ProviderRef<TransactionRepository>;
String _$userPreferencesRepositoryHash() =>
    r'd7e19749c987c8646e12acb561edc219946b58b0';

/// See also [userPreferencesRepository].
@ProviderFor(userPreferencesRepository)
final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>.internal(
      userPreferencesRepository,
      name: r'userPreferencesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userPreferencesRepositoryHash,
      dependencies: <ProviderOrFamily>[appDatabaseProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        appDatabaseProvider,
        ...?appDatabaseProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserPreferencesRepositoryRef = ProviderRef<UserPreferencesRepository>;
String _$shoppingListRepositoryHash() =>
    r'69361fef60701fd753fc8c7caff896f376bdf1de';

/// See also [shoppingListRepository].
@ProviderFor(shoppingListRepository)
final shoppingListRepositoryProvider =
    Provider<ShoppingListRepository>.internal(
      shoppingListRepository,
      name: r'shoppingListRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shoppingListRepositoryHash,
      dependencies: <ProviderOrFamily>[
        appDatabaseProvider,
        transactionRepositoryProvider,
      ],
      allTransitiveDependencies: <ProviderOrFamily>{
        appDatabaseProvider,
        ...?appDatabaseProvider.allTransitiveDependencies,
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShoppingListRepositoryRef = ProviderRef<ShoppingListRepository>;
String _$pendingTransactionRepositoryHash() =>
    r'800478b460c3c65248a0a6b23188c1672be5f3b8';

/// See also [pendingTransactionRepository].
@ProviderFor(pendingTransactionRepository)
final pendingTransactionRepositoryProvider =
    Provider<PendingTransactionRepository>.internal(
      pendingTransactionRepository,
      name: r'pendingTransactionRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingTransactionRepositoryHash,
      dependencies: <ProviderOrFamily>[appDatabaseProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        appDatabaseProvider,
        ...?appDatabaseProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingTransactionRepositoryRef =
    ProviderRef<PendingTransactionRepository>;
String _$recurringRulesRepositoryHash() =>
    r'f297f662435691a5d8d42b616551967de2993046';

/// See also [recurringRulesRepository].
@ProviderFor(recurringRulesRepository)
final recurringRulesRepositoryProvider =
    Provider<RecurringRulesRepository>.internal(
      recurringRulesRepository,
      name: r'recurringRulesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recurringRulesRepositoryHash,
      dependencies: <ProviderOrFamily>[appDatabaseProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        appDatabaseProvider,
        ...?appDatabaseProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecurringRulesRepositoryRef = ProviderRef<RecurringRulesRepository>;
String _$recurringGenerationUseCaseHash() =>
    r'350e388f51b864c88329360e1078cac008904655';

/// Use-case provider. Lives here so that controllers in
/// `lib/features/.../*_controller.dart` can `ref.read` the use case
/// without importing `data/database/...` (forbidden by
/// `controllers_forbid_db_and_services` in import_analysis_options.yaml).
///
/// Copied from [recurringGenerationUseCase].
@ProviderFor(recurringGenerationUseCase)
final recurringGenerationUseCaseProvider =
    Provider<RecurringGenerationUseCase>.internal(
      recurringGenerationUseCase,
      name: r'recurringGenerationUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recurringGenerationUseCaseHash,
      dependencies: <ProviderOrFamily>[
        appDatabaseProvider,
        recurringRulesRepositoryProvider,
        pendingTransactionRepositoryProvider,
      ],
      allTransitiveDependencies: <ProviderOrFamily>{
        appDatabaseProvider,
        ...?appDatabaseProvider.allTransitiveDependencies,
        recurringRulesRepositoryProvider,
        ...?recurringRulesRepositoryProvider.allTransitiveDependencies,
        pendingTransactionRepositoryProvider,
        ...?pendingTransactionRepositoryProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecurringGenerationUseCaseRef = ProviderRef<RecurringGenerationUseCase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
