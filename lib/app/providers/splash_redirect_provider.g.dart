// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_redirect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$splashGateSnapshotHash() =>
    r'281035d9bdb515023036bd97227870ce5be9ecb5';

/// See also [splashGateSnapshot].
@ProviderFor(splashGateSnapshot)
final splashGateSnapshotProvider = Provider<SplashGateSnapshot>.internal(
  splashGateSnapshot,
  name: r'splashGateSnapshotProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$splashGateSnapshotHash,
  dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    userPreferencesRepositoryProvider,
    ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SplashGateSnapshotRef = ProviderRef<SplashGateSnapshot>;
String _$splashEnabledHash() => r'5d023f161ca598447425b44eba53ab1067969e57';

/// Stream of `splash_enabled` for reactive UI (e.g. `SettingsScreen`).
///
/// Copied from [splashEnabled].
@ProviderFor(splashEnabled)
final splashEnabledProvider = StreamProvider<bool>.internal(
  splashEnabled,
  name: r'splashEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$splashEnabledHash,
  dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    userPreferencesRepositoryProvider,
    ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SplashEnabledRef = StreamProviderRef<bool>;
String _$splashStartDateHash() => r'155a89a3b957efe426da2ea46b13d1bd5cbbb9f0';

/// Stream of `splash_start_date` for reactive UI (e.g. `SplashScreen`).
///
/// Copied from [splashStartDate].
@ProviderFor(splashStartDate)
final splashStartDateProvider = StreamProvider<DateTime?>.internal(
  splashStartDate,
  name: r'splashStartDateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$splashStartDateHash,
  dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    userPreferencesRepositoryProvider,
    ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SplashStartDateRef = StreamProviderRef<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
