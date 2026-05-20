// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chartsFxStatusHash() => r'eeee812c08826ac460bcbf2bae81252601f963d7';

/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.
///
/// Copied from [chartsFxStatus].
@ProviderFor(chartsFxStatus)
final chartsFxStatusProvider =
    AutoDisposeStreamProvider<ChartsFxStatus>.internal(
      chartsFxStatus,
      name: r'chartsFxStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chartsFxStatusHash,
      dependencies: <ProviderOrFamily>[
        initialDefaultCurrencyProvider,
        defaultCurrencyProvider,
        exchangeRateRepositoryProvider,
      ],
      allTransitiveDependencies: <ProviderOrFamily>{
        initialDefaultCurrencyProvider,
        ...?initialDefaultCurrencyProvider.allTransitiveDependencies,
        defaultCurrencyProvider,
        ...?defaultCurrencyProvider.allTransitiveDependencies,
        exchangeRateRepositoryProvider,
        ...?exchangeRateRepositoryProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChartsFxStatusRef = AutoDisposeStreamProviderRef<ChartsFxStatus>;
String _$chartsCurrenciesByCodeHash() =>
    r'ae84501d9a92885aada4b05495e9defb148f667f';

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.
///
/// Copied from [chartsCurrenciesByCode].
@ProviderFor(chartsCurrenciesByCode)
final chartsCurrenciesByCodeProvider =
    AutoDisposeStreamProvider<Map<String, Currency>>.internal(
      chartsCurrenciesByCode,
      name: r'chartsCurrenciesByCodeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chartsCurrenciesByCodeHash,
      dependencies: <ProviderOrFamily>[currencyRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        currencyRepositoryProvider,
        ...?currencyRepositoryProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChartsCurrenciesByCodeRef =
    AutoDisposeStreamProviderRef<Map<String, Currency>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
