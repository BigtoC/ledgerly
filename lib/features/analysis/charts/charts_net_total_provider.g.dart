// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_net_total_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-currency net for the selected period's `[start, end)` range.

@ProviderFor(chartsNetByCurrency)
final chartsNetByCurrencyProvider = ChartsNetByCurrencyProvider._();

/// Per-currency net for the selected period's `[start, end)` range.

final class ChartsNetByCurrencyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// Per-currency net for the selected period's `[start, end)` range.
  ChartsNetByCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsNetByCurrencyProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          chartsSelectionControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChartsNetByCurrencyProvider.$allTransitiveDependencies0,
          ChartsNetByCurrencyProvider.$allTransitiveDependencies1,
          ChartsNetByCurrencyProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = chartsSelectionControllerProvider;

  @override
  String debugGetCreateSourceHash() => _$chartsNetByCurrencyHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return chartsNetByCurrency(ref);
  }
}

String _$chartsNetByCurrencyHash() =>
    r'd6848b7c6fab3c29f36d14a145c9273060082d95';

/// [chartsNetByCurrency] folded into the default currency. Null until the
/// net, FX status and currency metadata have all loaded, and while the
/// net query is in error so the previous period's net is not shown.

@ProviderFor(chartsNetTotal)
final chartsNetTotalProvider = ChartsNetTotalProvider._();

/// [chartsNetByCurrency] folded into the default currency. Null until the
/// net, FX status and currency metadata have all loaded, and while the
/// net query is in error so the previous period's net is not shown.

final class ChartsNetTotalProvider
    extends
        $FunctionalProvider<ChartsNetTotal?, ChartsNetTotal?, ChartsNetTotal?>
    with $Provider<ChartsNetTotal?> {
  /// [chartsNetByCurrency] folded into the default currency. Null until the
  /// net, FX status and currency metadata have all loaded, and while the
  /// net query is in error so the previous period's net is not shown.
  ChartsNetTotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsNetTotalProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          chartsNetByCurrencyProvider,
          chartsFxStatusProvider,
          chartsCurrenciesByCodeProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsNetTotalProvider.$allTransitiveDependencies0,
          ChartsNetTotalProvider.$allTransitiveDependencies1,
          ChartsNetTotalProvider.$allTransitiveDependencies2,
          ChartsNetTotalProvider.$allTransitiveDependencies3,
          ChartsNetTotalProvider.$allTransitiveDependencies4,
          ChartsNetTotalProvider.$allTransitiveDependencies5,
          ChartsNetTotalProvider.$allTransitiveDependencies6,
          ChartsNetTotalProvider.$allTransitiveDependencies7,
          ChartsNetTotalProvider.$allTransitiveDependencies8,
          ChartsNetTotalProvider.$allTransitiveDependencies9,
          ChartsNetTotalProvider.$allTransitiveDependencies10,
          ChartsNetTotalProvider.$allTransitiveDependencies11,
        },
      );

  static final $allTransitiveDependencies0 = chartsNetByCurrencyProvider;
  static final $allTransitiveDependencies1 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 = chartsFxStatusProvider;
  static final $allTransitiveDependencies5 =
      ChartsFxStatusProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies6 =
      ChartsFxStatusProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies7 =
      ChartsFxStatusProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies8 =
      ChartsFxStatusProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies9 =
      ChartsFxStatusProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies10 = chartsCurrenciesByCodeProvider;
  static final $allTransitiveDependencies11 =
      ChartsCurrenciesByCodeProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$chartsNetTotalHash();

  @$internal
  @override
  $ProviderElement<ChartsNetTotal?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChartsNetTotal? create(Ref ref) {
    return chartsNetTotal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChartsNetTotal? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChartsNetTotal?>(value),
    );
  }
}

String _$chartsNetTotalHash() => r'21d951289fe2b2e26ebe89e4c872af3fa4c40b3b';
