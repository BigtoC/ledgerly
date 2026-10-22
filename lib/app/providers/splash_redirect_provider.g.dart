// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_redirect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(splashGateSnapshot)
final splashGateSnapshotProvider = SplashGateSnapshotProvider._();

final class SplashGateSnapshotProvider
    extends
        $FunctionalProvider<
          Raw<SplashGateSnapshot>,
          Raw<SplashGateSnapshot>,
          Raw<SplashGateSnapshot>
        >
    with $Provider<Raw<SplashGateSnapshot>> {
  SplashGateSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashGateSnapshotProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SplashGateSnapshotProvider.$allTransitiveDependencies0,
          SplashGateSnapshotProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      UserPreferencesRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$splashGateSnapshotHash();

  @$internal
  @override
  $ProviderElement<Raw<SplashGateSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<SplashGateSnapshot> create(Ref ref) {
    return splashGateSnapshot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<SplashGateSnapshot> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<SplashGateSnapshot>>(value),
    );
  }
}

String _$splashGateSnapshotHash() =>
    r'355664651509c3555b9c3228fe20d62c9116f16a';

/// Stream of `splash_start_date` for reactive UI (e.g. `SplashScreen`).

@ProviderFor(splashStartDate)
final splashStartDateProvider = SplashStartDateProvider._();

/// Stream of `splash_start_date` for reactive UI (e.g. `SplashScreen`).

final class SplashStartDateProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime?>, DateTime?, Stream<DateTime?>>
    with $FutureModifier<DateTime?>, $StreamProvider<DateTime?> {
  /// Stream of `splash_start_date` for reactive UI (e.g. `SplashScreen`).
  SplashStartDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashStartDateProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SplashStartDateProvider.$allTransitiveDependencies0,
          SplashStartDateProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      UserPreferencesRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$splashStartDateHash();

  @$internal
  @override
  $StreamProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime?> create(Ref ref) {
    return splashStartDate(ref);
  }
}

String _$splashStartDateHash() => r'155a89a3b957efe426da2ea46b13d1bd5cbbb9f0';
