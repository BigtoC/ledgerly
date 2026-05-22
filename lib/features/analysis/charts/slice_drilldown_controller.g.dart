// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slice_drilldown_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sliceDrilldownControllerHash() =>
    r'8641c82f2b15c0e3456298e92a03830001ba440c';

/// See also [SliceDrilldownController].
@ProviderFor(SliceDrilldownController)
final sliceDrilldownControllerProvider =
    StreamNotifierProvider<
      SliceDrilldownController,
      SliceDrilldownData
    >.internal(
      SliceDrilldownController.new,
      name: r'sliceDrilldownControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sliceDrilldownControllerHash,
      dependencies: <ProviderOrFamily>[
        transactionRepositoryProvider,
        chartsFxStatusProvider,
        chartsSelectionControllerProvider,
      ],
      allTransitiveDependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
        chartsFxStatusProvider,
        ...?chartsFxStatusProvider.allTransitiveDependencies,
        chartsSelectionControllerProvider,
        ...?chartsSelectionControllerProvider.allTransitiveDependencies,
      },
    );

typedef _$SliceDrilldownController = StreamNotifier<SliceDrilldownData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
