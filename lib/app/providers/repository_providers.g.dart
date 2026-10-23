// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currencyRepository)
final currencyRepositoryProvider = CurrencyRepositoryProvider._();

final class CurrencyRepositoryProvider
    extends
        $FunctionalProvider<
          CurrencyRepository,
          CurrencyRepository,
          CurrencyRepository
        >
    with $Provider<CurrencyRepository> {
  CurrencyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currencyRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[appDatabaseProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CurrencyRepositoryProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;

  @override
  String debugGetCreateSourceHash() => _$currencyRepositoryHash();

  @$internal
  @override
  $ProviderElement<CurrencyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CurrencyRepository create(Ref ref) {
    return currencyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrencyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrencyRepository>(value),
    );
  }
}

String _$currencyRepositoryHash() =>
    r'bf8c858bb3918d954d76ab2669ec63d33a17836b';

@ProviderFor(categoryRepository)
final categoryRepositoryProvider = CategoryRepositoryProvider._();

final class CategoryRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryRepository,
          CategoryRepository,
          CategoryRepository
        >
    with $Provider<CategoryRepository> {
  CategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[appDatabaseProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CategoryRepositoryProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;

  @override
  String debugGetCreateSourceHash() => _$categoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryRepository create(Ref ref) {
    return categoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryRepository>(value),
    );
  }
}

String _$categoryRepositoryHash() =>
    r'1e4610381fc04292a17b40245adf139c4e16875e';

@ProviderFor(accountTypeRepository)
final accountTypeRepositoryProvider = AccountTypeRepositoryProvider._();

final class AccountTypeRepositoryProvider
    extends
        $FunctionalProvider<
          AccountTypeRepository,
          AccountTypeRepository,
          AccountTypeRepository
        >
    with $Provider<AccountTypeRepository> {
  AccountTypeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountTypeRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          appDatabaseProvider,
          currencyRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          AccountTypeRepositoryProvider.$allTransitiveDependencies0,
          AccountTypeRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;
  static final $allTransitiveDependencies1 = currencyRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$accountTypeRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountTypeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountTypeRepository create(Ref ref) {
    return accountTypeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountTypeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountTypeRepository>(value),
    );
  }
}

String _$accountTypeRepositoryHash() =>
    r'1ca0b598d36c528f555f227489fa67ddf028893f';

@ProviderFor(accountRepository)
final accountRepositoryProvider = AccountRepositoryProvider._();

final class AccountRepositoryProvider
    extends
        $FunctionalProvider<
          AccountRepository,
          AccountRepository,
          AccountRepository
        >
    with $Provider<AccountRepository> {
  AccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          appDatabaseProvider,
          currencyRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          AccountRepositoryProvider.$allTransitiveDependencies0,
          AccountRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;
  static final $allTransitiveDependencies1 = currencyRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$accountRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountRepository create(Ref ref) {
    return accountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountRepository>(value),
    );
  }
}

String _$accountRepositoryHash() => r'ac65599370448fd726a90beac26dadfa8c9cdc0e';

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

final class TransactionRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionRepository,
          TransactionRepository,
          TransactionRepository
        >
    with $Provider<TransactionRepository> {
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[appDatabaseProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          TransactionRepositoryProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'a0ac84b0ff8a6e5a134d1d1aa8b85236160c19b9';

@ProviderFor(userPreferencesRepository)
final userPreferencesRepositoryProvider = UserPreferencesRepositoryProvider._();

final class UserPreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          UserPreferencesRepository,
          UserPreferencesRepository,
          UserPreferencesRepository
        >
    with $Provider<UserPreferencesRepository> {
  UserPreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPreferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[appDatabaseProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          UserPreferencesRepositoryProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;

  @override
  String debugGetCreateSourceHash() => _$userPreferencesRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserPreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserPreferencesRepository create(Ref ref) {
    return userPreferencesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserPreferencesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserPreferencesRepository>(value),
    );
  }
}

String _$userPreferencesRepositoryHash() =>
    r'd7e19749c987c8646e12acb561edc219946b58b0';

@ProviderFor(shoppingListRepository)
final shoppingListRepositoryProvider = ShoppingListRepositoryProvider._();

final class ShoppingListRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingListRepository,
          ShoppingListRepository,
          ShoppingListRepository
        >
    with $Provider<ShoppingListRepository> {
  ShoppingListRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          appDatabaseProvider,
          transactionRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingListRepositoryProvider.$allTransitiveDependencies0,
          ShoppingListRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;
  static final $allTransitiveDependencies1 = transactionRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$shoppingListRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingListRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingListRepository create(Ref ref) {
    return shoppingListRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListRepository>(value),
    );
  }
}

String _$shoppingListRepositoryHash() =>
    r'69361fef60701fd753fc8c7caff896f376bdf1de';

@ProviderFor(pendingTransactionRepository)
final pendingTransactionRepositoryProvider =
    PendingTransactionRepositoryProvider._();

final class PendingTransactionRepositoryProvider
    extends
        $FunctionalProvider<
          PendingTransactionRepository,
          PendingTransactionRepository,
          PendingTransactionRepository
        >
    with $Provider<PendingTransactionRepository> {
  PendingTransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingTransactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          appDatabaseProvider,
          transactionRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          PendingTransactionRepositoryProvider.$allTransitiveDependencies0,
          PendingTransactionRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;
  static final $allTransitiveDependencies1 = transactionRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$pendingTransactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<PendingTransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingTransactionRepository create(Ref ref) {
    return pendingTransactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingTransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingTransactionRepository>(value),
    );
  }
}

String _$pendingTransactionRepositoryHash() =>
    r'5875072a19c741255f8c4b202cc39121822fdc82';

@ProviderFor(recurringRulesRepository)
final recurringRulesRepositoryProvider = RecurringRulesRepositoryProvider._();

final class RecurringRulesRepositoryProvider
    extends
        $FunctionalProvider<
          RecurringRulesRepository,
          RecurringRulesRepository,
          RecurringRulesRepository
        >
    with $Provider<RecurringRulesRepository> {
  RecurringRulesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringRulesRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[appDatabaseProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          RecurringRulesRepositoryProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;

  @override
  String debugGetCreateSourceHash() => _$recurringRulesRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecurringRulesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecurringRulesRepository create(Ref ref) {
    return recurringRulesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringRulesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringRulesRepository>(value),
    );
  }
}

String _$recurringRulesRepositoryHash() =>
    r'f297f662435691a5d8d42b616551967de2993046';

/// Use-case provider. Lives here so that controllers in
/// `lib/features/.../*_controller.dart` can `ref.read` the use case
/// without importing `data/database/...` (forbidden by
/// `controllers_forbid_db_and_services` in import_analysis_options.yaml).

@ProviderFor(recurringGenerationUseCase)
final recurringGenerationUseCaseProvider =
    RecurringGenerationUseCaseProvider._();

/// Use-case provider. Lives here so that controllers in
/// `lib/features/.../*_controller.dart` can `ref.read` the use case
/// without importing `data/database/...` (forbidden by
/// `controllers_forbid_db_and_services` in import_analysis_options.yaml).

final class RecurringGenerationUseCaseProvider
    extends
        $FunctionalProvider<
          RecurringGenerationUseCase,
          RecurringGenerationUseCase,
          RecurringGenerationUseCase
        >
    with $Provider<RecurringGenerationUseCase> {
  /// Use-case provider. Lives here so that controllers in
  /// `lib/features/.../*_controller.dart` can `ref.read` the use case
  /// without importing `data/database/...` (forbidden by
  /// `controllers_forbid_db_and_services` in import_analysis_options.yaml).
  RecurringGenerationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringGenerationUseCaseProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          appDatabaseProvider,
          recurringRulesRepositoryProvider,
          pendingTransactionRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          RecurringGenerationUseCaseProvider.$allTransitiveDependencies0,
          RecurringGenerationUseCaseProvider.$allTransitiveDependencies1,
          RecurringGenerationUseCaseProvider.$allTransitiveDependencies2,
          RecurringGenerationUseCaseProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;
  static final $allTransitiveDependencies1 = recurringRulesRepositoryProvider;
  static final $allTransitiveDependencies2 =
      pendingTransactionRepositoryProvider;
  static final $allTransitiveDependencies3 =
      PendingTransactionRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$recurringGenerationUseCaseHash();

  @$internal
  @override
  $ProviderElement<RecurringGenerationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecurringGenerationUseCase create(Ref ref) {
    return recurringGenerationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringGenerationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringGenerationUseCase>(value),
    );
  }
}

String _$recurringGenerationUseCaseHash() =>
    r'350e388f51b864c88329360e1078cac008904655';

/// Shared HTTP client for every HTTP service. Conservative timeouts; the
/// client is closed when the owning container is disposed.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Shared HTTP client for every HTTP service. Conservative timeouts; the
/// client is closed when the owning container is disposed.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Shared HTTP client for every HTTP service. Conservative timeouts; the
  /// client is closed when the owning container is disposed.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'609f409fd9322951631485f1281f0561805462f7';

/// Exchange-rate HTTP service. Uses the shared [dioProvider] client.

@ProviderFor(exchangeRateService)
final exchangeRateServiceProvider = ExchangeRateServiceProvider._();

/// Exchange-rate HTTP service. Uses the shared [dioProvider] client.

final class ExchangeRateServiceProvider
    extends
        $FunctionalProvider<
          ExchangeRateService,
          ExchangeRateService,
          ExchangeRateService
        >
    with $Provider<ExchangeRateService> {
  /// Exchange-rate HTTP service. Uses the shared [dioProvider] client.
  ExchangeRateServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRateServiceProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$exchangeRateServiceHash();

  @$internal
  @override
  $ProviderElement<ExchangeRateService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExchangeRateService create(Ref ref) {
    return exchangeRateService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExchangeRateService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExchangeRateService>(value),
    );
  }
}

String _$exchangeRateServiceHash() =>
    r'54cac23382bca3bc90ff6bca49f4643fc47a093d';

/// Exchange-rate repository. The constructor subscribes to DAO changes
/// and default-currency changes immediately — so simply reading this
/// provider is enough to start the cache pipeline.

@ProviderFor(exchangeRateRepository)
final exchangeRateRepositoryProvider = ExchangeRateRepositoryProvider._();

/// Exchange-rate repository. The constructor subscribes to DAO changes
/// and default-currency changes immediately — so simply reading this
/// provider is enough to start the cache pipeline.

final class ExchangeRateRepositoryProvider
    extends
        $FunctionalProvider<
          ExchangeRateRepository,
          ExchangeRateRepository,
          ExchangeRateRepository
        >
    with $Provider<ExchangeRateRepository> {
  /// Exchange-rate repository. The constructor subscribes to DAO changes
  /// and default-currency changes immediately — so simply reading this
  /// provider is enough to start the cache pipeline.
  ExchangeRateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRateRepositoryProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          appDatabaseProvider,
          exchangeRateServiceProvider,
          defaultCurrencyProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ExchangeRateRepositoryProvider.$allTransitiveDependencies0,
          ExchangeRateRepositoryProvider.$allTransitiveDependencies1,
          ExchangeRateRepositoryProvider.$allTransitiveDependencies2,
          ExchangeRateRepositoryProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = appDatabaseProvider;
  static final $allTransitiveDependencies1 = exchangeRateServiceProvider;
  static final $allTransitiveDependencies2 = defaultCurrencyProvider;
  static final $allTransitiveDependencies3 =
      DefaultCurrencyProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$exchangeRateRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExchangeRateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExchangeRateRepository create(Ref ref) {
    return exchangeRateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExchangeRateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExchangeRateRepository>(value),
    );
  }
}

String _$exchangeRateRepositoryHash() =>
    r'4b623ad800a14ff6ac4fd8e7555ba2552f1a8ebd';

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.

@ProviderFor(exchangeRates)
final exchangeRatesProvider = ExchangeRatesProvider._();

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.

final class ExchangeRatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// Stream of the exchange-rate snapshot map (scaled-e9 integer values
  /// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
  ExchangeRatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRatesProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[exchangeRateRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ExchangeRatesProvider.$allTransitiveDependencies0,
          ExchangeRatesProvider.$allTransitiveDependencies1,
          ExchangeRatesProvider.$allTransitiveDependencies2,
          ExchangeRatesProvider.$allTransitiveDependencies3,
          ExchangeRatesProvider.$allTransitiveDependencies4,
        },
      );

  static final $allTransitiveDependencies0 = exchangeRateRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$exchangeRatesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return exchangeRates(ref);
  }
}

String _$exchangeRatesHash() => r'90a7e84860a077c637713b43a1bcc7e8c461ea09';
