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
          chartsRangeProvider,
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
          SliceDrilldownControllerProvider.$allTransitiveDependencies9,
          SliceDrilldownControllerProvider.$allTransitiveDependencies10,
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
  static final $allTransitiveDependencies8 = chartsRangeProvider;
  static final $allTransitiveDependencies9 =
      ChartsRangeProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies10 =
      ChartsRangeProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$sliceDrilldownControllerHash();

  @$internal
  @override
  SliceDrilldownController create() => SliceDrilldownController();
}

String _$sliceDrilldownControllerHash() =>
    r'b7159134bb5305b0c1a718832a7c22f0d1a7a885';

abstract class _$SliceDrilldownController
    extends $StreamNotifier<SliceDrilldownData> {
  Stream<SliceDrilldownData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
