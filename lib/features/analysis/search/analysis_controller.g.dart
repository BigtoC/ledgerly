// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalysisController)
final analysisControllerProvider = AnalysisControllerProvider._();

final class AnalysisControllerProvider
    extends $StreamNotifierProvider<AnalysisController, AnalysisState> {
  AnalysisControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisControllerProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          analysisCategoriesByIdProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          AnalysisControllerProvider.$allTransitiveDependencies0,
          AnalysisControllerProvider.$allTransitiveDependencies1,
          AnalysisControllerProvider.$allTransitiveDependencies2,
          AnalysisControllerProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = analysisCategoriesByIdProvider;
  static final $allTransitiveDependencies3 =
      AnalysisCategoriesByIdProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$analysisControllerHash();

  @$internal
  @override
  AnalysisController create() => AnalysisController();
}

String _$analysisControllerHash() =>
    r'62e1080a53812f0e2f8e268205cc2456c7fbff6d';

abstract class _$AnalysisController extends $StreamNotifier<AnalysisState> {
  Stream<AnalysisState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AnalysisState>, AnalysisState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AnalysisState>, AnalysisState>,
              AsyncValue<AnalysisState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
