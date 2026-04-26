// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$splashClockHash() => r'78c74264e29b3ae487f323f8014e45605d6e0c59';

/// Injectable `DateTime.now()` for deterministic day-count tests.
/// Production reads the real clock; tests override via
/// `splashClockProvider.overrideWithValue(() => fixedNow)`.
///
/// Copied from [splashClock].
@ProviderFor(splashClock)
final splashClockProvider = Provider<DateTime Function()>.internal(
  splashClock,
  name: r'splashClockProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$splashClockHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SplashClockRef = ProviderRef<DateTime Function()>;
String _$splashControllerHash() => r'c2a035a38dcb6e85b5665e1eab615f2ea9e21e96';

/// See also [SplashController].
@ProviderFor(SplashController)
final splashControllerProvider =
    AutoDisposeStreamNotifierProvider<SplashController, SplashState>.internal(
      SplashController.new,
      name: r'splashControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$splashControllerHash,
      dependencies: <ProviderOrFamily>{
        userPreferencesRepositoryProvider,
        splashClockProvider,
        userLocalePreferenceProvider,
        splashGateSnapshotProvider,
      },
      allTransitiveDependencies: <ProviderOrFamily>{
        userPreferencesRepositoryProvider,
        ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
        splashClockProvider,
        ...?splashClockProvider.allTransitiveDependencies,
        userLocalePreferenceProvider,
        ...?userLocalePreferenceProvider.allTransitiveDependencies,
        splashGateSnapshotProvider,
        ...?splashGateSnapshotProvider.allTransitiveDependencies,
      },
    );

typedef _$SplashController = AutoDisposeStreamNotifier<SplashState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
