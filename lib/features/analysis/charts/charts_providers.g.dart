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

@ProviderFor(chartsFxStatus)
final chartsFxStatusProvider = ChartsFxStatusProvider._();

/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.

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
  ChartsFxStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsFxStatusProvider',
        isAutoDispose: true,
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

String _$chartsFxStatusHash() => r'18956a2abd662947eb3fe7b5760a9c1902345f85';

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.

@ProviderFor(chartsCurrenciesByCode)
final chartsCurrenciesByCodeProvider = ChartsCurrenciesByCodeProvider._();

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.

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
  ChartsCurrenciesByCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsCurrenciesByCodeProvider',
        isAutoDispose: true,
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
    r'ae84501d9a92885aada4b05495e9defb148f667f';
