// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$analysisControllerHash() =>
    r'791b43afb0335644a7db102347f13a33d2e2ba6d';

/// See also [AnalysisController].
@ProviderFor(AnalysisController)
final analysisControllerProvider =
    StreamNotifierProvider<AnalysisController, AnalysisState>.internal(
      AnalysisController.new,
      name: r'analysisControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$analysisControllerHash,
      dependencies: <ProviderOrFamily>[transactionRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$AnalysisController = StreamNotifier<AnalysisState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
