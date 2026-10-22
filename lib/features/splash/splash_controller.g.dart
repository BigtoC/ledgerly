// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injectable `DateTime.now()` for deterministic day-count tests.
/// Production reads the real clock; tests override via
/// `splashClockProvider.overrideWithValue(() => fixedNow)`.

@ProviderFor(splashClock)
final splashClockProvider = SplashClockProvider._();

/// Injectable `DateTime.now()` for deterministic day-count tests.
/// Production reads the real clock; tests override via
/// `splashClockProvider.overrideWithValue(() => fixedNow)`.

final class SplashClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Injectable `DateTime.now()` for deterministic day-count tests.
  /// Production reads the real clock; tests override via
  /// `splashClockProvider.overrideWithValue(() => fixedNow)`.
  SplashClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashClockProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$splashClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return splashClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$splashClockHash() => r'78c74264e29b3ae487f323f8014e45605d6e0c59';

@ProviderFor(SplashController)
final splashControllerProvider = SplashControllerProvider._();

final class SplashControllerProvider
    extends $StreamNotifierProvider<SplashController, SplashState> {
  SplashControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          userPreferencesRepositoryProvider,
          splashClockProvider,
          userLocalePreferenceProvider,
          splashGateSnapshotProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          SplashControllerProvider.$allTransitiveDependencies0,
          SplashControllerProvider.$allTransitiveDependencies1,
          SplashControllerProvider.$allTransitiveDependencies2,
          SplashControllerProvider.$allTransitiveDependencies3,
          SplashControllerProvider.$allTransitiveDependencies4,
          SplashControllerProvider.$allTransitiveDependencies5,
          SplashControllerProvider.$allTransitiveDependencies6,
        },
      );

  static final $allTransitiveDependencies0 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      UserPreferencesRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = splashClockProvider;
  static final $allTransitiveDependencies3 = userLocalePreferenceProvider;
  static final $allTransitiveDependencies4 =
      UserLocalePreferenceProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies5 =
      UserLocalePreferenceProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies6 = splashGateSnapshotProvider;

  @override
  String debugGetCreateSourceHash() => _$splashControllerHash();

  @$internal
  @override
  SplashController create() => SplashController();
}

String _$splashControllerHash() => r'21f242e37ac5391bc6078fc9d24335faea325e5a';

abstract class _$SplashController extends $StreamNotifier<SplashState> {
  Stream<SplashState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SplashState>, SplashState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SplashState>, SplashState>,
              AsyncValue<SplashState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
