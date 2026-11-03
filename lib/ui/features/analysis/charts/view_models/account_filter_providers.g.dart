// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_filter_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-account, per-currency totals of the selected type in the selected
/// period's `[start, end)` range.

@ProviderFor(chartsAccountTotals)
final chartsAccountTotalsProvider = ChartsAccountTotalsProvider._();

/// Per-account, per-currency totals of the selected type in the selected
/// period's `[start, end)` range.

final class ChartsAccountTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AccountSlice>>,
          List<AccountSlice>,
          Stream<List<AccountSlice>>
        >
    with
        $FutureModifier<List<AccountSlice>>,
        $StreamProvider<List<AccountSlice>> {
  /// Per-account, per-currency totals of the selected type in the selected
  /// period's `[start, end)` range.
  ChartsAccountTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsAccountTotalsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          chartsRangeProvider,
          chartsSelectionControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsAccountTotalsProvider.$allTransitiveDependencies0,
          ChartsAccountTotalsProvider.$allTransitiveDependencies1,
          ChartsAccountTotalsProvider.$allTransitiveDependencies2,
          ChartsAccountTotalsProvider.$allTransitiveDependencies3,
          ChartsAccountTotalsProvider.$allTransitiveDependencies4,
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
  String debugGetCreateSourceHash() => _$chartsAccountTotalsHash();

  @$internal
  @override
  $StreamProviderElement<List<AccountSlice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AccountSlice>> create(Ref ref) {
    return chartsAccountTotals(ref);
  }
}

String _$chartsAccountTotalsHash() =>
    r'df90a1723c9d33609a982457b5211c8bf00af175';

/// [chartsAccountTotals] converted into the default currency and joined
/// with the active accounts. Currencies without a rate are left out, like
/// the summary card. Loading until every input has loaded; an error when
/// any input is in error, so the sheet never shows stale rows.

@ProviderFor(chartsAccountFilterOptions)
final chartsAccountFilterOptionsProvider =
    ChartsAccountFilterOptionsProvider._();

/// [chartsAccountTotals] converted into the default currency and joined
/// with the active accounts. Currencies without a rate are left out, like
/// the summary card. Loading until every input has loaded; an error when
/// any input is in error, so the sheet never shows stale rows.

final class ChartsAccountFilterOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChartsAccountFilterOptions>,
          AsyncValue<ChartsAccountFilterOptions>,
          AsyncValue<ChartsAccountFilterOptions>
        >
    with $Provider<AsyncValue<ChartsAccountFilterOptions>> {
  /// [chartsAccountTotals] converted into the default currency and joined
  /// with the active accounts. Currencies without a rate are left out, like
  /// the summary card. Loading until every input has loaded; an error when
  /// any input is in error, so the sheet never shows stale rows.
  ChartsAccountFilterOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsAccountFilterOptionsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          chartsAccountTotalsProvider,
          chartsFxStatusProvider,
          chartsCurrenciesByCodeProvider,
          analysisAccountsByIdProvider,
          analysisAccountTypesByIdProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies0,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies1,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies2,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies3,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies4,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies5,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies6,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies7,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies8,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies9,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies10,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies11,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies12,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies13,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies14,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies15,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies16,
          ChartsAccountFilterOptionsProvider.$allTransitiveDependencies17,
        },
      );

  static final $allTransitiveDependencies0 = chartsAccountTotalsProvider;
  static final $allTransitiveDependencies1 =
      ChartsAccountTotalsProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ChartsAccountTotalsProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ChartsAccountTotalsProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      ChartsAccountTotalsProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      ChartsAccountTotalsProvider.$allTransitiveDependencies4;
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
  static final $allTransitiveDependencies14 = analysisAccountsByIdProvider;
  static final $allTransitiveDependencies15 =
      AnalysisAccountsByIdProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies16 = analysisAccountTypesByIdProvider;
  static final $allTransitiveDependencies17 =
      AnalysisAccountTypesByIdProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$chartsAccountFilterOptionsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<ChartsAccountFilterOptions>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ChartsAccountFilterOptions> create(Ref ref) {
    return chartsAccountFilterOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ChartsAccountFilterOptions> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<ChartsAccountFilterOptions>>(value),
    );
  }
}

String _$chartsAccountFilterOptionsHash() =>
    r'1407905615540bbfb4eff2f08fd3edb80340f32a';
