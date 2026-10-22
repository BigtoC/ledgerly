// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slice_drilldown_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SliceDrilldownController)
final sliceDrilldownControllerProvider = SliceDrilldownControllerProvider._();

final class SliceDrilldownControllerProvider
    extends
        $StreamNotifierProvider<SliceDrilldownController, SliceDrilldownData> {
  SliceDrilldownControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sliceDrilldownControllerProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          chartsFxStatusProvider,
          chartsSelectionControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          SliceDrilldownControllerProvider.$allTransitiveDependencies0,
          SliceDrilldownControllerProvider.$allTransitiveDependencies1,
          SliceDrilldownControllerProvider.$allTransitiveDependencies2,
          SliceDrilldownControllerProvider.$allTransitiveDependencies3,
          SliceDrilldownControllerProvider.$allTransitiveDependencies4,
          SliceDrilldownControllerProvider.$allTransitiveDependencies5,
          SliceDrilldownControllerProvider.$allTransitiveDependencies6,
          SliceDrilldownControllerProvider.$allTransitiveDependencies7,
          SliceDrilldownControllerProvider.$allTransitiveDependencies8,
        },
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = chartsFxStatusProvider;
  static final $allTransitiveDependencies3 =
      ChartsFxStatusProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies4 =
      ChartsFxStatusProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies5 =
      ChartsFxStatusProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies6 =
      ChartsFxStatusProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies7 =
      ChartsFxStatusProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies8 = chartsSelectionControllerProvider;

  @override
  String debugGetCreateSourceHash() => _$sliceDrilldownControllerHash();

  @$internal
  @override
  SliceDrilldownController create() => SliceDrilldownController();
}

String _$sliceDrilldownControllerHash() =>
    r'164ac42d1b90a15c92e9dba863f41135c33c2df3';

abstract class _$SliceDrilldownController
    extends $StreamNotifier<SliceDrilldownData> {
  Stream<SliceDrilldownData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SliceDrilldownData>, SliceDrilldownData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SliceDrilldownData>, SliceDrilldownData>,
              AsyncValue<SliceDrilldownData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
