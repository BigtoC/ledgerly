// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$splashClockHash() => r'f34a3bb2e726f6c0fcf3354cc82cf413ad5f80a9';

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
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SplashClockRef = ProviderRef<DateTime Function()>;
String _$splashControllerHash() => r'47c9d627d1bf88b3ada41df394659d37ba9aee2a';

/// See also [SplashController].
@ProviderFor(SplashController)
final splashControllerProvider =
    AutoDisposeStreamNotifierProvider<SplashController, SplashState>.internal(
      SplashController.new,
      name: r'splashControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$splashControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SplashController = AutoDisposeStreamNotifier<SplashState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
