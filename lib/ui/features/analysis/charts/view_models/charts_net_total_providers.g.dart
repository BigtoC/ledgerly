// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_net_total_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-currency expense and income for the selected period's
/// `[start, end)` range, limited to the filtered account when one is set.

@ProviderFor(chartsNetByCurrency)
final chartsNetByCurrencyProvider = ChartsNetByCurrencyProvider._();

/// Per-currency expense and income for the selected period's
/// `[start, end)` range, limited to the filtered account when one is set.

final class ChartsNetByCurrencyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ({int expense, int income})>>,
          Map<String, ({int expense, int income})>,
          Stream<Map<String, ({int expense, int income})>>
        >
    with
        $FutureModifier<Map<String, ({int expense, int income})>>,
        $StreamProvider<Map<String, ({int expense, int income})>> {
  /// Per-currency expense and income for the selected period's
  /// `[start, end)` range, limited to the filtered account when one is set.
  ChartsNetByCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsNetByCurrencyProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          chartsRangeProvider,
          chartsSelectionControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsNetByCurrencyProvider.$allTransitiveDependencies0,
          ChartsNetByCurrencyProvider.$allTransitiveDependencies1,
          ChartsNetByCurrencyProvider.$allTransitiveDependencies2,
          ChartsNetByCurrencyProvider.$allTransitiveDependencies3,
          ChartsNetByCurrencyProvider.$allTransitiveDependencies4,
        },
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = chartsRangeProvider;
  static final $allTransitiveDependencies3 =
      ChartsRangeProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies4 =
      ChartsRangeProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$chartsNetByCurrencyHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, ({int expense, int income})>>
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, ({int expense, int income})>> create(Ref ref) {
    return chartsNetByCurrency(ref);
  }
}

String _$chartsNetByCurrencyHash() =>
    r'60d51df65a8d39b1227eabe86249794aa0757b7b';

/// [chartsNetByCurrency] folded into the default currency. Null until the
/// totals, FX status and currency metadata have all loaded, and while the
/// totals query is in error so the previous period's totals are not shown.

@ProviderFor(chartsNetTotal)
final chartsNetTotalProvider = ChartsNetTotalProvider._();

/// [chartsNetByCurrency] folded into the default currency. Null until the
/// totals, FX status and currency metadata have all loaded, and while the
/// totals query is in error so the previous period's totals are not shown.

final class ChartsNetTotalProvider
    extends
        $FunctionalProvider<ChartsNetTotal?, ChartsNetTotal?, ChartsNetTotal?>
    with $Provider<ChartsNetTotal?> {
  /// [chartsNetByCurrency] folded into the default currency. Null until the
  /// totals, FX status and currency metadata have all loaded, and while the
  /// totals query is in error so the previous period's totals are not shown.
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
          ChartsNetTotalProvider.$allTransitiveDependencies12,
          ChartsNetTotalProvider.$allTransitiveDependencies13,
        },
      );

  static final $allTransitiveDependencies0 = chartsNetByCurrencyProvider;
  static final $allTransitiveDependencies1 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      ChartsNetByCurrencyProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies6 = chartsFxStatusProvider;
  static final $allTransitiveDependencies7 =
      ChartsFxStatusProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies8 =
      ChartsFxStatusProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies9 =
      ChartsFxStatusProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies10 =
      ChartsFxStatusProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies11 =
      ChartsFxStatusProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies12 = chartsCurrenciesByCodeProvider;
  static final $allTransitiveDependencies13 =
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

String _$chartsNetTotalHash() => r'718a11885e1095de4dc527841ba7ba810b1baaf8';
