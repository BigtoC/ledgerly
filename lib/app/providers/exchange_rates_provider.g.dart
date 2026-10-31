// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
///
/// Lives outside `repository_providers.dart` so that widgets can read the
/// rates without importing the repository providers, which the layer
/// rules in `import_analysis_options.yaml` forbid them.

@ProviderFor(exchangeRates)
final exchangeRatesProvider = ExchangeRatesProvider._();

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
///
/// Lives outside `repository_providers.dart` so that widgets can read the
/// rates without importing the repository providers, which the layer
/// rules in `import_analysis_options.yaml` forbid them.

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
  ///
  /// Lives outside `repository_providers.dart` so that widgets can read the
  /// rates without importing the repository providers, which the layer
  /// rules in `import_analysis_options.yaml` forbid them.
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
