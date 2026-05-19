// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionFormControllerHash() =>
    r'f61b2a0a03b0d8d19b50311e768d885dd3dd036b';

/// See also [TransactionFormController].
@ProviderFor(TransactionFormController)
final transactionFormControllerProvider =
    AutoDisposeNotifierProvider<
      TransactionFormController,
      TransactionFormState
    >.internal(
      TransactionFormController.new,
      name: r'transactionFormControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionFormControllerHash,
      dependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        accountRepositoryProvider,
        categoryRepositoryProvider,
        userPreferencesRepositoryProvider,
        currencyRepositoryProvider,
        shoppingListRepositoryProvider,
        defaultCurrencyProvider,
        exchangeRateRepositoryProvider,
        initialDefaultCurrencyProvider,
      },
      allTransitiveDependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
        accountRepositoryProvider,
        ...?accountRepositoryProvider.allTransitiveDependencies,
        categoryRepositoryProvider,
        ...?categoryRepositoryProvider.allTransitiveDependencies,
        userPreferencesRepositoryProvider,
        ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
        currencyRepositoryProvider,
        ...?currencyRepositoryProvider.allTransitiveDependencies,
        shoppingListRepositoryProvider,
        ...?shoppingListRepositoryProvider.allTransitiveDependencies,
        defaultCurrencyProvider,
        ...?defaultCurrencyProvider.allTransitiveDependencies,
        exchangeRateRepositoryProvider,
        ...?exchangeRateRepositoryProvider.allTransitiveDependencies,
        initialDefaultCurrencyProvider,
        ...?initialDefaultCurrencyProvider.allTransitiveDependencies,
      },
    );

typedef _$TransactionFormController = AutoDisposeNotifier<TransactionFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
