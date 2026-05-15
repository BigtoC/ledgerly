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
    r'5875072a19c741255f8c4b202cc39121822fdc82';

/// See also [pendingTransactionRepository].
@ProviderFor(pendingTransactionRepository)
final pendingTransactionRepositoryProvider =
    Provider<PendingTransactionRepository>.internal(
      pendingTransactionRepository,
      name: r'pendingTransactionRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingTransactionRepositoryHash,
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
String _$exchangeRateServiceHash() =>
    r'01da3d2facd8c002cace687fbd6691d79a961325';

/// Exchange-rate HTTP service. Constructs its own `Dio` with conservative
/// timeouts — there is no standalone `dioProvider`, since the rate service
/// is the only consumer of Dio in the codebase. If a second HTTP consumer
/// appears later, extract `dioProvider` at that point.
///
/// Copied from [exchangeRateService].
@ProviderFor(exchangeRateService)
final exchangeRateServiceProvider = Provider<ExchangeRateService>.internal(
  exchangeRateService,
  name: r'exchangeRateServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exchangeRateServiceHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExchangeRateServiceRef = ProviderRef<ExchangeRateService>;
String _$exchangeRateRepositoryHash() =>
    r'7a8676191b0d14d7795671a782b9c6ccd28b7d6f';

/// Exchange-rate repository. The constructor subscribes to DAO changes
/// and default-currency changes immediately — so simply reading this
/// provider is enough to start the cache pipeline.
///
/// Copied from [exchangeRateRepository].
@ProviderFor(exchangeRateRepository)
final exchangeRateRepositoryProvider =
    Provider<ExchangeRateRepository>.internal(
      exchangeRateRepository,
      name: r'exchangeRateRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$exchangeRateRepositoryHash,
      dependencies: <ProviderOrFamily>[
        appDatabaseProvider,
        exchangeRateServiceProvider,
        defaultCurrencyProvider,
      ],
      allTransitiveDependencies: <ProviderOrFamily>{
        appDatabaseProvider,
        ...?appDatabaseProvider.allTransitiveDependencies,
        exchangeRateServiceProvider,
        ...?exchangeRateServiceProvider.allTransitiveDependencies,
        defaultCurrencyProvider,
        ...?defaultCurrencyProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExchangeRateRepositoryRef = ProviderRef<ExchangeRateRepository>;
String _$exchangeRatesHash() => r'90a7e84860a077c637713b43a1bcc7e8c461ea09';

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
///
/// Copied from [exchangeRates].
@ProviderFor(exchangeRates)
final exchangeRatesProvider = StreamProvider<Map<String, int>>.internal(
  exchangeRates,
  name: r'exchangeRatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exchangeRatesHash,
  dependencies: <ProviderOrFamily>[exchangeRateRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    exchangeRateRepositoryProvider,
    ...?exchangeRateRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExchangeRatesRef = StreamProviderRef<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
