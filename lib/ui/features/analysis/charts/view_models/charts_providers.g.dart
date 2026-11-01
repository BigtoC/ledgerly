// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` listen to it for their whole lifetime.

@ProviderFor(chartsFxStatus)
final chartsFxStatusProvider = ChartsFxStatusProvider._();

/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` listen to it for their whole lifetime.

final class ChartsFxStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChartsFxStatus>,
          ChartsFxStatus,
          Stream<ChartsFxStatus>
        >
    with $FutureModifier<ChartsFxStatus>, $StreamProvider<ChartsFxStatus> {
  /// Stream of the joined FX status. Re-emits whenever either the default
  /// currency or the per-pair rate metadata changes. Uses an internal
  /// `StreamController` so both inputs feed the same output without
  /// dropping events from whichever input wasn't last awaited.
  ///
  /// `keepAlive` because the kept-alive `ChartsController` and
  /// `SliceDrilldownController` listen to it for their whole lifetime.
  ChartsFxStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsFxStatusProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          initialDefaultCurrencyProvider,
          defaultCurrencyProvider,
          exchangeRateRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsFxStatusProvider.$allTransitiveDependencies0,
          ChartsFxStatusProvider.$allTransitiveDependencies1,
          ChartsFxStatusProvider.$allTransitiveDependencies2,
          ChartsFxStatusProvider.$allTransitiveDependencies3,
          ChartsFxStatusProvider.$allTransitiveDependencies4,
          ChartsFxStatusProvider.$allTransitiveDependencies5,
        },
      );

  static final $allTransitiveDependencies0 = initialDefaultCurrencyProvider;
  static final $allTransitiveDependencies1 = defaultCurrencyProvider;
  static final $allTransitiveDependencies2 =
      DefaultCurrencyProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      DefaultCurrencyProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 = exchangeRateRepositoryProvider;
  static final $allTransitiveDependencies5 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$chartsFxStatusHash();

  @$internal
  @override
  $StreamProviderElement<ChartsFxStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ChartsFxStatus> create(Ref ref) {
    return chartsFxStatus(ref);
  }
}

String _$chartsFxStatusHash() => r'b38f6109218c058a2c457b03887cd9af6b819641';

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.
///
/// `keepAlive` because the kept-alive `ChartsController` listens to it.

@ProviderFor(chartsCurrenciesByCode)
final chartsCurrenciesByCodeProvider = ChartsCurrenciesByCodeProvider._();

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.
///
/// `keepAlive` because the kept-alive `ChartsController` listens to it.

final class ChartsCurrenciesByCodeProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Currency>>,
          Map<String, Currency>,
          Stream<Map<String, Currency>>
        >
    with
        $FutureModifier<Map<String, Currency>>,
        $StreamProvider<Map<String, Currency>> {
  /// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
  /// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
  /// amounts identically to the Home summary strip.
  ///
  /// `keepAlive` because the kept-alive `ChartsController` listens to it.
  ChartsCurrenciesByCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsCurrenciesByCodeProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[currencyRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChartsCurrenciesByCodeProvider.$allTransitiveDependencies0,
          ChartsCurrenciesByCodeProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = currencyRepositoryProvider;
  static final $allTransitiveDependencies1 =
      CurrencyRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$chartsCurrenciesByCodeHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, Currency>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Currency>> create(Ref ref) {
    return chartsCurrenciesByCode(ref);
  }
}

String _$chartsCurrenciesByCodeHash() =>
    r'2fa2bea4b065264c8a0a5f0b5837e6444fe1446d';
