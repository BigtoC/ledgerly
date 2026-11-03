// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_range_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The selected period's range: the anchor snapped to its period.
///
/// Watches only `(period, anchorDate)`, so a type, dimension, slice or
/// account change does not re-query its consumers.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` watch it.

@ProviderFor(chartsRange)
final chartsRangeProvider = ChartsRangeProvider._();

/// The selected period's range: the anchor snapped to its period.
///
/// Watches only `(period, anchorDate)`, so a type, dimension, slice or
/// account change does not re-query its consumers.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` watch it.

final class ChartsRangeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChartsRange>,
          AsyncValue<ChartsRange>,
          AsyncValue<ChartsRange>
        >
    with $Provider<AsyncValue<ChartsRange>> {
  /// The selected period's range: the anchor snapped to its period.
  ///
  /// Watches only `(period, anchorDate)`, so a type, dimension, slice or
  /// account change does not re-query its consumers.
  ///
  /// `keepAlive` because the kept-alive `ChartsController` and
  /// `SliceDrilldownController` watch it.
  ChartsRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsRangeProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[chartsSelectionControllerProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChartsRangeProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = chartsSelectionControllerProvider;

  @override
  String debugGetCreateSourceHash() => _$chartsRangeHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<ChartsRange>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ChartsRange> create(Ref ref) {
    return chartsRange(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ChartsRange> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ChartsRange>>(value),
    );
  }
}

String _$chartsRangeHash() => r'0415d2267f3e137ead8e9d1cb5b6bd9b3b81b5c3';
