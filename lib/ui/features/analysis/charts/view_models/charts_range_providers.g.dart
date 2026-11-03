// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_range_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Earliest and latest transaction dates, across every type and account.
/// Re-emits when the earliest transaction is added or deleted (plan D13).
///
/// `keepAlive` because the kept-alive [chartsRange] watches it on All.

@ProviderFor(chartsDateBounds)
final chartsDateBoundsProvider = ChartsDateBoundsProvider._();

/// Earliest and latest transaction dates, across every type and account.
/// Re-emits when the earliest transaction is added or deleted (plan D13).
///
/// `keepAlive` because the kept-alive [chartsRange] watches it on All.

final class ChartsDateBoundsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DateBounds?>,
          DateBounds?,
          Stream<DateBounds?>
        >
    with $FutureModifier<DateBounds?>, $StreamProvider<DateBounds?> {
  /// Earliest and latest transaction dates, across every type and account.
  /// Re-emits when the earliest transaction is added or deleted (plan D13).
  ///
  /// `keepAlive` because the kept-alive [chartsRange] watches it on All.
  ChartsDateBoundsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsDateBoundsProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[transactionRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChartsDateBoundsProvider.$allTransitiveDependencies0,
          ChartsDateBoundsProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$chartsDateBoundsHash();

  @$internal
  @override
  $StreamProviderElement<DateBounds?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DateBounds?> create(Ref ref) {
    return chartsDateBounds(ref);
  }
}

String _$chartsDateBoundsHash() => r'133da591c64dcd83ea98116195f031ae6935e7e8';

/// The selected period's range. Day, Week, Month and Year snap the anchor;
/// All runs from the first day of the earliest transaction's month to the
/// start of next month, and is empty (`start == end`) when there are no
/// transactions up to then. Loading or failed only while All's date
/// bounds are.
///
/// Watches only `(period, anchorDate)`, so a type, dimension, slice or
/// account change does not re-query its consumers.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` watch it.

@ProviderFor(chartsRange)
final chartsRangeProvider = ChartsRangeProvider._();

/// The selected period's range. Day, Week, Month and Year snap the anchor;
/// All runs from the first day of the earliest transaction's month to the
/// start of next month, and is empty (`start == end`) when there are no
/// transactions up to then. Loading or failed only while All's date
/// bounds are.
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
  /// The selected period's range. Day, Week, Month and Year snap the anchor;
  /// All runs from the first day of the earliest transaction's month to the
  /// start of next month, and is empty (`start == end`) when there are no
  /// transactions up to then. Loading or failed only while All's date
  /// bounds are.
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
        dependencies: <ProviderOrFamily>[
          chartsDateBoundsProvider,
          chartsSelectionControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ChartsRangeProvider.$allTransitiveDependencies0,
          ChartsRangeProvider.$allTransitiveDependencies1,
          ChartsRangeProvider.$allTransitiveDependencies2,
          ChartsRangeProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = chartsDateBoundsProvider;
  static final $allTransitiveDependencies1 =
      ChartsDateBoundsProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ChartsDateBoundsProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = chartsSelectionControllerProvider;

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

String _$chartsRangeHash() => r'e7fb8b68cdfbaf5c57a8769457e6fcb0058fa0ab';
