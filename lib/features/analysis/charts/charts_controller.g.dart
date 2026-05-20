// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chartsControllerHash() => r'a82c3ac9ab508de22158cd55d5159fc844500383';

/// See also [ChartsController].
@ProviderFor(ChartsController)
final chartsControllerProvider =
    StreamNotifierProvider<ChartsController, ChartsState>.internal(
      ChartsController.new,
      name: r'chartsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chartsControllerHash,
      dependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        exchangeRateRepositoryProvider,
        chartsFxStatusProvider,
        chartsCurrenciesByCodeProvider,
        analysisCategoriesByIdProvider,
        analysisAccountsByIdProvider,
      },
      allTransitiveDependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
        exchangeRateRepositoryProvider,
        ...?exchangeRateRepositoryProvider.allTransitiveDependencies,
        chartsFxStatusProvider,
        ...?chartsFxStatusProvider.allTransitiveDependencies,
        chartsCurrenciesByCodeProvider,
        ...?chartsCurrenciesByCodeProvider.allTransitiveDependencies,
        analysisCategoriesByIdProvider,
        ...?analysisCategoriesByIdProvider.allTransitiveDependencies,
        analysisAccountsByIdProvider,
        ...?analysisAccountsByIdProvider.allTransitiveDependencies,
      },
    );

typedef _$ChartsController = StreamNotifier<ChartsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
