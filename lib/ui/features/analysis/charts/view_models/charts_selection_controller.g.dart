// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChartsSelectionController)
final chartsSelectionControllerProvider = ChartsSelectionControllerProvider._();

final class ChartsSelectionControllerProvider
    extends $NotifierProvider<ChartsSelectionController, ChartsSelection> {
  ChartsSelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsSelectionControllerProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$chartsSelectionControllerHash();

  @$internal
  @override
  ChartsSelectionController create() => ChartsSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChartsSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChartsSelection>(value),
    );
  }
}

String _$chartsSelectionControllerHash() =>
    r'd7e10d1fa2ed216a13451091fb5a7a8848fa9c1f';

abstract class _$ChartsSelectionController extends $Notifier<ChartsSelection> {
  ChartsSelection build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChartsSelection, ChartsSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChartsSelection, ChartsSelection>,
              ChartsSelection,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
