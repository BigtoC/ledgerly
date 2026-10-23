// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChartsController)
final chartsControllerProvider = ChartsControllerProvider._();

final class ChartsControllerProvider
    extends $StreamNotifierProvider<ChartsController, ChartsState> {
  ChartsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsControllerProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          exchangeRateRepositoryProvider,
          chartsFxStatusProvider,
          chartsCurrenciesByCodeProvider,
          analysisCategoriesByIdProvider,
          analysisAccountsByIdProvider,
          chartsSelectionControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsControllerProvider.$allTransitiveDependencies0,
          ChartsControllerProvider.$allTransitiveDependencies1,
          ChartsControllerProvider.$allTransitiveDependencies2,
          ChartsControllerProvider.$allTransitiveDependencies3,
          ChartsControllerProvider.$allTransitiveDependencies4,
          ChartsControllerProvider.$allTransitiveDependencies5,
          ChartsControllerProvider.$allTransitiveDependencies6,
          ChartsControllerProvider.$allTransitiveDependencies7,
          ChartsControllerProvider.$allTransitiveDependencies8,
          ChartsControllerProvider.$allTransitiveDependencies9,
          ChartsControllerProvider.$allTransitiveDependencies10,
          ChartsControllerProvider.$allTransitiveDependencies11,
          ChartsControllerProvider.$allTransitiveDependencies12,
          ChartsControllerProvider.$allTransitiveDependencies13,
          ChartsControllerProvider.$allTransitiveDependencies14,
        },
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = exchangeRateRepositoryProvider;
  static final $allTransitiveDependencies3 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies5 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies6 = chartsFxStatusProvider;
  static final $allTransitiveDependencies7 =
      ChartsFxStatusProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies8 = chartsCurrenciesByCodeProvider;
  static final $allTransitiveDependencies9 =
      ChartsCurrenciesByCodeProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies10 = analysisCategoriesByIdProvider;
  static final $allTransitiveDependencies11 =
      AnalysisCategoriesByIdProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies12 = analysisAccountsByIdProvider;
  static final $allTransitiveDependencies13 =
      AnalysisAccountsByIdProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies14 = chartsSelectionControllerProvider;

  @override
  String debugGetCreateSourceHash() => _$chartsControllerHash();

  @$internal
  @override
  ChartsController create() => ChartsController();
}

String _$chartsControllerHash() => r'3f13ed9a79320c66efa04947395ba79c38353c29';

abstract class _$ChartsController extends $StreamNotifier<ChartsState> {
  Stream<ChartsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChartsState>, ChartsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChartsState>, ChartsState>,
              AsyncValue<ChartsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
